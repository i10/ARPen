//
//  Meshing.m
//  ARPen
//
//  Created by Jan Benscheid on 27.09.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "Meshing.h"

#include "Registry.h"

#include <occt/TopExp_Explorer.hxx>
#include <occt/TopoDS.hxx>
#include <occt/GCPnts_QuasiUniformDeflection.hxx>
#include <occt/BRepMesh_IncrementalMesh.hxx>
#include <occt/BRepBuilderAPI_Transform.hxx>
#include <occt/BRepAdaptor_Curve.hxx>
#include <occt/Poly.hxx>
#include <occt/StlAPI_Writer.hxx>


@implementation Meshing : NSObject

/// OpenCascade uses millimeters internally, while SceneKit uses meters. Objects are scaled by this factor for stl export.
static const double scalingFactor = 1000;

/// [Linear deflection](https://www.opencascade.com/doc/occt-7.1.0/overview/html/occt_user_guides__modeling_algos.html#occt_modalg_11) for mesh conversion in preview.
static const double meshDeflection = 0.0005;
/// [Linear deflection](https://www.opencascade.com/doc/occt-7.1.0/overview/html/occt_user_guides__modeling_algos.html#occt_modalg_11) for mesh conversion in export.
static const double meshDeflectionExport = 0.0002;
/// [Linear deflection](https://www.opencascade.com/doc/occt-7.1.0/overview/html/occt_user_guides__modeling_algos.html#occt_modalg_11) for line conversion in preview.
static const double lineDeflection = 0.0003;

/// Radius of cylinder tube for conversion of lines.
static const float tubeRadius = 0.0005;
/// Number of sides per tube segment.
static const int tubeSides = 3;

/// Returns a TopoDS_Shape (referenced by `label`), converted into an `SCNGeometry` object.
+ (SCNGeometry *) sceneKitMeshOf:(const char *)label {
    TCollection_AsciiString key = TCollection_AsciiString(label);
    TopoDS_Shape shape = [Registry retrieveFromRegistry:key];
    return [self triangulate:shape withDeflection:meshDeflection];
}

/// Returns all lines of a TopoDS_Shape (referenced by `label`), converted into an `SCNGeometry` object of primitive type "Lines".
+ (SCNGeometry *) sceneKitLinesOf:(const char *)label {
    TCollection_AsciiString key = TCollection_AsciiString(label);
    TopoDS_Shape shape = [Registry retrieveFromRegistry:key];
    return [self getEdges:shape withDeflection:lineDeflection];
}

/// Returns all lines of a TopoDS_Shape (referenced by `label`), converted into a  `SCNGeometry` object consisting of a series of cylinders.
+ (SCNGeometry *) sceneKitTubesOf:(const char *)label {
    TCollection_AsciiString key = TCollection_AsciiString(label);
    TopoDS_Shape shape = [Registry retrieveFromRegistry:key];
    return [self getTube:shape withDeflection:lineDeflection];
}

/// Returns all lines of a TopoDS_Shape, converted into a  `SCNGeometry` object consisting of a series of cylinders. For a detailed explaination, see documentation of function `triangulate`.
+ (SCNGeometry *) getTube:(TopoDS_Shape &)shape
           withDeflection:(const Standard_Real)deflection
{
    int noOfNodes = 0;
    int noOfSegments = 0;

    // Determine necessary amount of tube segements
    for (TopExp_Explorer exEdge(shape, TopAbs_EDGE); exEdge.More(); exEdge.Next())
    {
        BRepAdaptor_Curve curveAdaptor;
        curveAdaptor.Initialize(TopoDS::Edge(exEdge.Current()));
        
        GCPnts_QuasiUniformDeflection uniformAbscissa;
        uniformAbscissa.Initialize(curveAdaptor, deflection);
        
        if (uniformAbscissa.IsDone())
        {
            Standard_Integer nbr = uniformAbscissa.NbPoints();
            if (uniformAbscissa.NbPoints() >= 2) {
                noOfNodes += nbr;
                noOfSegments += nbr - 1;
            }
        }
    }
    
    int noOfVertices = noOfSegments*((tubeSides+1)*2);
    int noOfTriangles = noOfSegments * tubeSides * 2;
    SCNVector3 vertices[noOfVertices];
    SCNVector3 normals[noOfVertices];
    int indices[noOfTriangles * 3];
    
    int vertexIndex = 0;
    int triIndex = 0;
    
    for (TopExp_Explorer exEdge(shape, TopAbs_EDGE); exEdge.More(); exEdge.Next())
    {
        BRepAdaptor_Curve curveAdaptor;
        curveAdaptor.Initialize(TopoDS::Edge(exEdge.Current()));
        
        GCPnts_QuasiUniformDeflection uniformAbscissa;
        uniformAbscissa.Initialize(curveAdaptor, deflection);
        
        if (uniformAbscissa.IsDone())
        {
            Standard_Integer nbr = uniformAbscissa.NbPoints();
            gp_Pnt prev;
            for ( Standard_Integer i = 1 ; i <= nbr ; i++ )
            {
                gp_Pnt pt = curveAdaptor.Value(uniformAbscissa.Parameter(i));
                
                if (i >= 2) {
                    // Create cylinder
                    gp_Vec vec;
                    if (pt.IsEqual(prev, 0.00001)) {
                        // In rare occasions (we found it when subtracting spheres from each other), both points may be equal, which results in a crash. Use a default direction then.
                        vec = gp_Vec(0, 1, 0);
                    } else {
                        vec = gp_Vec(prev, pt).Normalized();
                    }
                    gp_Vec notParallel = gp_Vec(1, 0, 0);
                    if (abs(notParallel.Dot(vec)) >= 0.99) {
                        notParallel = gp_Vec(0, 1, 0);
                    }
                    gp_Vec perpendicular = vec.Crossed(notParallel).Normalized();
                    gp_Ax1 rotationAxis = gp_Ax1(pt, gp_Dir(vec));

                    for (int j = 0; j <= tubeSides; j++) {
                        float rotation = (M_PI*2) * (((float)j) / tubeSides);
                        gp_Vec dir = perpendicular.Rotated(rotationAxis, rotation);
                        
                        //IMPORTANT LINE
                        gp_Vec offset = dir.Scaled(tubeRadius);
                        gp_Pnt v1 = prev.Translated(offset);
                        gp_Pnt v2 =   pt.Translated(offset);
                        vertices[vertexIndex]  = {(float)v1.X(), (float)v1.Y(), (float)v1.Z()};
                        vertices[vertexIndex+1]= {(float)v2.X(), (float)v2.Y(), (float)v2.Z()};
                        normals[vertexIndex]   = {(float)dir.X(), (float)dir.Y(), (float)dir.Z()};
                        normals[vertexIndex+1] = {(float)dir.X(), (float)dir.Y(), (float)dir.Z()};
                        if (j >= 1) {
                            indices[(triIndex*3)+0] = vertexIndex;
                            indices[(triIndex*3)+1] = vertexIndex+1;
                            indices[(triIndex*3)+2] = vertexIndex-1;
                            triIndex ++;
                            indices[(triIndex*3)+0] = vertexIndex-1;
                            indices[(triIndex*3)+1] = vertexIndex-2;
                            indices[(triIndex*3)+2] = vertexIndex;
                            triIndex ++;
                        }
                        vertexIndex += 2;
                    }
                }
                prev = pt;
            }
        }
    }
    
    SCNGeometry *geometry = [self convertToSCNMesh:vertices withNormals:normals withIndices:indices vertexCount:noOfVertices primitiveCount:noOfTriangles];
    return geometry;
}

/// Returns all lines of a TopoDS_Shape, converted into an `SCNGeometry` object of primitive type "Lines".  For a detailed explaination, see documentation of function `triangulate`.
+ (SCNGeometry *) getEdges:(TopoDS_Shape &)shape
            withDeflection:(const Standard_Real)deflection
{
    int noOfNodes = 0;
    int noOfSegments = 0;
    
    // Determine necessary amount of tube segements
    for (TopExp_Explorer exEdge(shape, TopAbs_EDGE); exEdge.More(); exEdge.Next())
    {
        BRepAdaptor_Curve curveAdaptor;
        curveAdaptor.Initialize(TopoDS::Edge(exEdge.Current()));
        
        GCPnts_QuasiUniformDeflection uniformAbscissa;
        uniformAbscissa.Initialize(curveAdaptor, deflection);
        
        if(uniformAbscissa.IsDone())
        {
            Standard_Integer nbr = uniformAbscissa.NbPoints();
            noOfNodes += nbr;
            noOfSegments += nbr - 1;
        }
    }
    
    SCNVector3 vertices[noOfNodes];
    int indices[noOfSegments * 2];
    
    int vertexIndex = 0;
    int segmentIndex = 0;
    for (TopExp_Explorer exEdge(shape, TopAbs_EDGE); exEdge.More(); exEdge.Next())
    {
        BRepAdaptor_Curve curveAdaptor;
        curveAdaptor.Initialize(TopoDS::Edge(exEdge.Current()));
        
        GCPnts_QuasiUniformDeflection uniformAbscissa;
        uniformAbscissa.Initialize(curveAdaptor, deflection);
        
        if(uniformAbscissa.IsDone())
        {
            Standard_Integer nbr = uniformAbscissa.NbPoints();
            for ( Standard_Integer i = 1 ; i <= nbr ; i++ )
            {
                gp_Pnt pt = curveAdaptor.Value(uniformAbscissa.Parameter(i));
                vertices[vertexIndex] = {(float) pt.X(), (float) pt.Y(), (float) pt.Z()};
                
                if (i >= 2) {
                    indices[segmentIndex++] = vertexIndex-1;
                    indices[segmentIndex++] = vertexIndex;
                }
                
                vertexIndex ++;
            }
        }
    }
    
    SCNGeometry *geometry = [self convertToSCNLines:vertices withIndices:indices vertexCount:noOfNodes primitiveCount:noOfSegments];
    return geometry;
}

/// Convertes a TopoDS_Shape into a SceneKit compatible mesh. Inspired by https://github.com/openscenegraph/OpenSceneGraph/blob/master/src/osgPlugins/OpenCASCADE/ReaderWriterOpenCASCADE.cpp and StlAPI_Writer.cxx of OCCT Source.
+ (SCNGeometry *) triangulate:(TopoDS_Shape &)shape
               withDeflection:(const Standard_Real)deflection
{
    // Update the incremental mesh
    BRepMesh_IncrementalMesh mesh(shape, deflection);
    
    // First count the required nodes and triangles
    int noOfNodes = 0;
    int noOfTriangles = 0;
    
    // Iterate through the faces. BRepMesh_IncrementalMesh does not create a triangulation for the entire object, but rather associates one with each face.
    for (TopExp_Explorer ex(shape, TopAbs_FACE); ex.More(); ex.Next())
    {
        TopLoc_Location aLoc;
        // This method does not calculate a triangulation. It simply reads out the one calculated when calling BRepMesh_IncrementalMesh. Therefore this loop is fast.
        Handle(Poly_Triangulation) aTriangulation = BRep_Tool::Triangulation(TopoDS::Face (ex.Current()), aLoc);
        if (!aTriangulation.IsNull())
        {
            noOfNodes += aTriangulation->NbNodes();
            noOfTriangles += aTriangulation->NbTriangles();
        }
    }
    
    SCNVector3 vertices[noOfNodes];
    SCNVector3 normals[noOfNodes];
    int indices[noOfTriangles * 3];
    
    int vertexIndex = 0;
    int triangleIndex = 0;
    // Now loop over the faces again, populating the arrays
    for (TopExp_Explorer ex(shape, TopAbs_FACE); ex.More(); ex.Next())
    {
        TopoDS_Face face = TopoDS::Face(ex.Current());
        
        TopLoc_Location location;
        // Triangulate current face
        Handle (Poly_Triangulation) triangulation = BRep_Tool::Triangulation(face, location);
        
        if(triangulation.IsNull()){
            return nil;
        }
        
        Poly::ComputeNormals(triangulation);
        
        gp_Trsf transformation = location.Transformation();
        if (!triangulation.IsNull())
        {
            // Populate vertex and normal array
            int noOfNodes = triangulation->NbNodes();
            const TColgp_Array1OfPnt& nodes = triangulation->Nodes();
            for (Standard_Integer i = nodes.Lower(); i <= nodes.Upper(); ++i)
            {
                gp_Pnt pt = nodes(i);
                pt.Transform(transformation);
                
                gp_Dir normal = triangulation->Normal(i);
                normal.Transform(transformation);
                if (face.Orientation() == TopAbs_REVERSED)
                {
                    normal = normal.Reversed();
                }
                
                // nodes.Lower() will be 1, because in OCCT Arrays start at 1
                // In OCCT Z is up, while in SceneKit Y is up, so Z and Y have to be swapped
                vertices[vertexIndex + i - 1] = {(float) pt.X(), (float) pt.Y(), (float) pt.Z()};
                normals[vertexIndex + i - 1] = {(float) normal.X(), (float) normal.Y(), (float) normal.Z()};
            }
            
            // Populate index array
            const Poly_Array1OfTriangle& triangles = triangulation->Triangles();
            
            Standard_Integer v1, v2, v3;
            for (Standard_Integer i = triangles.Lower(); i <= triangles.Upper(); ++i)
            {
                if (face.Orientation() != TopAbs_REVERSED)
                {
                    triangles(i).Get(v1, v2, v3);
                } else
                {
                    triangles(i).Get(v1, v3, v2);
                }
                
                indices[triangleIndex++] = vertexIndex + v1 - 1;
                indices[triangleIndex++] = vertexIndex + v2 - 1;
                indices[triangleIndex++] = vertexIndex + v3 - 1;
            }
            
            vertexIndex += noOfNodes;
        }
    }

    SCNGeometry *geometry = [self convertToSCNMesh:vertices withNormals:normals withIndices:indices vertexCount:noOfNodes primitiveCount:noOfTriangles];
    
    return geometry;
}

/// Bundles line data into a SceneKit compatible geometry object. Inspired by https://github.com/matthewreagan/TerrainMesh3D/blob/master/TerrainMesh3D/TerrainMesh.m
+ (SCNGeometry *) convertToSCNLines:(nonnull const SCNVector3 *)vertices
                        withIndices:(nonnull const int *)indices
                        vertexCount:(int)noOfVertices
                     primitiveCount:(int)noOfPrimitives
{
    SCNGeometrySource *vertexSource =
    vertexSource = [SCNGeometrySource geometrySourceWithVertices:vertices count:noOfVertices];
    
    NSData *indexData = [NSData dataWithBytes:indices length:sizeof(int) * noOfPrimitives * 2];
    SCNGeometryElement *element =
    [SCNGeometryElement geometryElementWithData:indexData
                                  primitiveType:SCNGeometryPrimitiveTypeLine
                                 primitiveCount:noOfPrimitives
                                  bytesPerIndex:sizeof(int)];
    
    SCNGeometry *geometry;
    
    geometry = [SCNGeometry geometryWithSources:@[vertexSource]
                                       elements:@[element]];
    
    return geometry;
}

/// Bundles mesh data into a SceneKit compatible geometry object. Inspired by https://github.com/matthewreagan/TerrainMesh3D/blob/master/TerrainMesh3D/TerrainMesh.m
+ (SCNGeometry *) convertToSCNMesh:(nonnull const SCNVector3 *)vertices
                       withNormals:(nonnull const SCNVector3 *)normals
                       withIndices:(nonnull const int *)indices
                       vertexCount:(int)noOfVertices
                    primitiveCount:(int)noOfPrimitives
{
    SCNGeometrySource *vertexSource =
    vertexSource = [SCNGeometrySource geometrySourceWithVertices:vertices count:noOfVertices];
    
    SCNGeometrySource *normalSource =
    normalSource = [SCNGeometrySource geometrySourceWithNormals:normals count:noOfVertices];
    
    NSData *indexData = [NSData dataWithBytes:indices length:sizeof(int) * noOfPrimitives * 3];
    SCNGeometryElement *element =
    [SCNGeometryElement geometryElementWithData:indexData
                                  primitiveType:SCNGeometryPrimitiveTypeTriangles
                                 primitiveCount:noOfPrimitives
                                  bytesPerIndex:sizeof(int)];
    
    SCNGeometry *geometry;
    
    geometry = [SCNGeometry geometryWithSources:@[vertexSource, normalSource]
                                       elements:@[element]];
    
    return geometry;
}

/// Triangulates a TopoDS_Shape (referenced by `label`) and saves it as an stl at `filename`.
+ (void) stlOf:(const char *) label
        toFile:(const char *) filename
{
    TCollection_AsciiString key = TCollection_AsciiString(label);
    TopoDS_Shape shape = [Registry retrieveFromRegistry:key];
    
    // Scale shape, as OpenCascade uses millimeters internally
    gp_Trsf trans;
    trans.SetScaleFactor(scalingFactor);
    BRepBuilderAPI_Transform trsf(shape, trans);
    TopoDS_Shape newShape = trsf.Shape();
    
    BRepMesh_IncrementalMesh mesh(newShape, meshDeflectionExport*scalingFactor);
    StlAPI_Writer writer = StlAPI_Writer();
    writer.Write(newShape, filename);
}

@end

//
//  Builders.m
//  ARPen
//
//  Created by Jan Benscheid on 27.09.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//
#import <Foundation/Foundation.h>

#include "Builders.h"

#include "Registry.h"

#include <occt/BRepPrimAPI_MakeBox.hxx>
#include <occt/BRepPrimAPI_MakeCylinder.hxx>
#include <occt/BRepPrimAPI_MakeSphere.hxx>
#include <occt/BRepPrimAPI_MakeRevol.hxx>
#include <occt/BRepBuilderAPI_MakeVertex.hxx>
#include <occt/BRepBuilderAPI_MakeEdge.hxx>
#include <occt/BRepBuilderAPI_MakeWire.hxx>

#include <occt/ShapeExtend_WireData.hxx>

#include <occt/BRepBuilderAPI_MakeFace.hxx>
#include <occt/BRepBuilderAPI_Transform.hxx>
#include <occt/gp_Trsf.hxx>
#include <occt/gp_Pnt.hxx>
#include <occt/TopoDS.hxx>
#include <occt/TColgp_SequenceOfPnt.hxx>
#include <occt/TColgp_HArray1OfPnt.hxx>
#include <occt/Geom_BSplineCurve.hxx>
#include <occt/GeomAPI_Interpolate.hxx>
#include <occt/BRepOffsetAPI_MakePipe.hxx>
#include <occt/BRepOffsetAPI_ThruSections.hxx>
#include <occt/BRepAlgoAPI_Common.hxx>
#include <occt/BRepAlgoAPI_Fuse.hxx>
#include <occt/BRepAlgoAPI_Cut.hxx>
#include <occt/Standard_ErrorHandler.hxx>
#include <occt/BRepPrimAPI_MakeWedge.hxx>


@implementation Builders : NSObject

+ (const char *) createBox:(double) width
                    height:(double) height
                    length:(double) length
{
    gp_Pnt corner = gp_Pnt(-width/2, -height/2, -length/2);
    TopoDS_Shape aBox = BRepPrimAPI_MakeBox(corner, width, height, length);
    TCollection_AsciiString key = [Registry storeInRegistry:aBox];
    
    return [Registry toHeapCString:key];
}

+ (const char *) createPyramid:(double) width
                    height:(double) height
                    length:(double) length
{
    
    TopoDS_Shape aPyramid = BRepPrimAPI_MakeWedge(width, height, length, width/2, length/2, width/2, length/2);
    
    TCollection_AsciiString key = [Registry storeInRegistry:aPyramid];
    
    return [Registry toHeapCString:key];
    
}

+ (const char *) createCylinder:(double) radius
                         height:(double) height
{
    TopoDS_Shape aCylinder = BRepPrimAPI_MakeCylinder(radius, height);
    
    gp_Trsf rotate = gp_Trsf();
    rotate.SetRotation(gp_Ax1(gp_Pnt(0, 0, 0), gp_Dir(1, 0, 0)), M_PI/2);
    
    gp_Trsf shift = gp_Trsf();
    shift.SetTranslation(gp_Vec(0, 0, -height/2));
    
    BRepBuilderAPI_Transform shiftTransform = BRepBuilderAPI_Transform(aCylinder, shift, Standard_True);
    TopoDS_Shape aShiftedCylinder = shiftTransform.Shape();
    // Y and Z are swapped in OCCT, therefore we rotate the cylinder.
    BRepBuilderAPI_Transform rotateTransform = BRepBuilderAPI_Transform(aShiftedCylinder, rotate, Standard_True);
    TopoDS_Shape aRotatedCylinder = rotateTransform.Shape();
    TCollection_AsciiString key = [Registry storeInRegistry:aRotatedCylinder];
    
    return [Registry toHeapCString:key];
}

+ (const char *) createSphere:(double) radius
{
    TopoDS_Shape aSphere = BRepPrimAPI_MakeSphere(radius);
    TCollection_AsciiString key = [Registry storeInRegistry:aSphere];
    
    return [Registry toHeapCString:key];
}








+ (const char *) createPath:(const SCNVector3 []) points
                     length:(int) length
                    corners:(const int []) corners
                     closed:(bool) closed
{
    BRepBuilderAPI_MakeWire makeWire;

    TColgp_SequenceOfPnt curvePoints;
    
    int startAt = 0;
    bool onlyRoundCorners = true;
    
    if (closed) {
        // A little trick to make curvature continuity at the start/endpoint easier:
        // Find out if the path consists purely of round corners. In that case OCCT can handle this for us.
        // Otherwise, choose a sharp corner to start with, so that there is no round corner at the seam.
        for (int i = 0; i < length; i++) {
            if (corners[i] == 1) {
                onlyRoundCorners = false;
                startAt = i;
                break;
            }
        }
    }
    
    // If the path is closed and there is a sharp corner at the seam, we need to make one additional step to add the closing edge.
    // Remember that we always start/end at a sharp corner if there is one.
    int overshoot = (closed && !onlyRoundCorners) ? 1 : 0;

    bool curveMode = false;
    for (int i = 1; i < length + overshoot; i++) {
        
        int ci = (startAt + i) % length;
        int pi = (startAt + i-1) % length;
        gp_Pnt currPoint(points[ci].x, points[ci].y, points[ci].z);
        gp_Pnt prevPoint(points[pi].x, points[pi].y, points[pi].z);
        int currCorner = corners[ci];
        int prevCorner = corners[pi];

        if (currCorner == 1 && prevCorner == 1) {
            if (!prevPoint.IsEqual(currPoint, 0.0001)) {
                TopoDS_Edge edge = BRepBuilderAPI_MakeEdge(prevPoint, currPoint);
                makeWire.Add(edge);
            }
        }
        
        // A curve has started
        if (!curveMode && (prevCorner == 2 || currCorner == 2)) {
            curvePoints = TColgp_SequenceOfPnt();
            curvePoints.Append(prevPoint);
            curveMode = true;
        }
        
        // A curve continues
        if (curveMode) {
            curvePoints.Append(currPoint);
        }
        
        // A curve has ended
        if (curveMode && (currCorner != 2 || i == length+overshoot-1)) {
            curveMode = false;
            
            int segmentLength = curvePoints.Length();
            Handle(TColgp_HArray1OfPnt) segmentPoints = new TColgp_HArray1OfPnt(1, segmentLength);
            TColgp_SequenceOfPnt::Iterator iter = TColgp_SequenceOfPnt::Iterator(curvePoints);
            int j = 1;
            for (; iter.More(); iter.Next()) {
                segmentPoints->SetValue(j++, iter.Value());
            }
            
            try {
                OCC_CATCH_SIGNALS
                
                GeomAPI_Interpolate interpolate = GeomAPI_Interpolate(segmentPoints, closed && onlyRoundCorners, 0.001);
                interpolate.Perform();
                Handle(Geom_BSplineCurve) curve = interpolate.Curve();
                BRepBuilderAPI_MakeEdge makeEdge = BRepBuilderAPI_MakeEdge(curve);
                TopoDS_Edge edge = makeEdge.Edge();
                makeWire.Add(edge);
            } catch (...) {}
        }
    }
    
    TopoDS_Shape wire;
    
    try {
        OCC_CATCH_SIGNALS
        wire = makeWire.Wire();
    } catch (...) {
        if (length == 1) {
            gp_Pnt point(points[0].x, points[0].y, points[0].z);
            wire = BRepBuilderAPI_MakeVertex(point);
        } else {
            wire = TopoDS_Wire();
        }
    }

    TCollection_AsciiString key = [Registry storeInRegistry:wire];

    return [Registry toHeapCString:key];
}















+ (const char *) updatePath: (const char *)label
                        points: (const SCNVector3 []) points
                        length:(int) length
                        corners:(const int []) corners
                        closed:(bool) closed
{
    TCollection_AsciiString key = TCollection_AsciiString(label);
    TopoDS_Shape shape_wire = [Registry retrieveFromRegistry:key];
    
    [Registry freeShape:label];
    
    BRepBuilderAPI_MakeWire makeWire;

    TColgp_SequenceOfPnt curvePoints;
    
    int startAt = 0;
    bool onlyRoundCorners = true;
    
    if (closed) {
        // A little trick to make curvature continuity at the start/endpoint easier:
        // Find out if the path consists purely of round corners. In that case OCCT can handle this for us.
        // Otherwise, choose a sharp corner to start with, so that there is no round corner at the seam.
        for (int i = 0; i < length; i++) {
            if (corners[i] == 1) {
                onlyRoundCorners = false;
                startAt = i;
                break;
            }
        }
    }
    
    // If the path is closed and there is a sharp corner at the seam, we need to make one additional step to add the closing edge.
    // Remember that we always start/end at a sharp corner if there is one.
    int overshoot = (closed && !onlyRoundCorners) ? 1 : 0;

    bool curveMode = false;
    for (int i = 1; i < length + overshoot; i++) {
        
        int ci = (startAt + i) % length;
        int pi = (startAt + i-1) % length;
        gp_Pnt currPoint(points[ci].x, points[ci].y, points[ci].z);
        gp_Pnt prevPoint(points[pi].x, points[pi].y, points[pi].z);
        int currCorner = corners[ci];
        int prevCorner = corners[pi];

        if (currCorner == 1 && prevCorner == 1) {
            if (!prevPoint.IsEqual(currPoint, 0.0001)) {
                TopoDS_Edge edge = BRepBuilderAPI_MakeEdge(prevPoint, currPoint);
                makeWire.Add(edge);
            }
        }
        
        // A curve has started
        if (!curveMode && (prevCorner == 2 || currCorner == 2)) {
            curvePoints = TColgp_SequenceOfPnt();
            curvePoints.Append(prevPoint);
            curveMode = true;
        }
        
        // A curve continues
        if (curveMode) {
            curvePoints.Append(currPoint);
        }
        
        // A curve has ended
        if (curveMode && (currCorner != 2 || i == length+overshoot-1)) {
            curveMode = false;
            
            int segmentLength = curvePoints.Length();
            Handle(TColgp_HArray1OfPnt) segmentPoints = new TColgp_HArray1OfPnt(1, segmentLength);
            TColgp_SequenceOfPnt::Iterator iter = TColgp_SequenceOfPnt::Iterator(curvePoints);
            int j = 1;
            for (; iter.More(); iter.Next()) {
                segmentPoints->SetValue(j++, iter.Value());
            }
            
            try {
                OCC_CATCH_SIGNALS
                
                GeomAPI_Interpolate interpolate = GeomAPI_Interpolate(segmentPoints, closed && onlyRoundCorners, 0.001);
                interpolate.Perform();
                Handle(Geom_BSplineCurve) curve = interpolate.Curve();
                BRepBuilderAPI_MakeEdge makeEdge = BRepBuilderAPI_MakeEdge(curve);
                TopoDS_Edge edge = makeEdge.Edge();
                makeWire.Add(edge);
            } catch (...) {}
        }
    }
    
    TopoDS_Shape wire;
    
    try {
        OCC_CATCH_SIGNALS
        wire = makeWire.Wire();
    } catch (...) {
        if (length == 1) {
            gp_Pnt point(points[0].x, points[0].y, points[0].z);
            wire = BRepBuilderAPI_MakeVertex(point);
        } else {
            wire = TopoDS_Wire();
        }
    }
    

    [Registry storeInRegistry:wire withKey:key];
    
    return [Registry toHeapCString:key];
}








































+ (const char *) sweep:(NSString *) profile
                 along:(NSString *) path;
{
    TCollection_AsciiString keyProfile = TCollection_AsciiString(profile.UTF8String);
    TCollection_AsciiString keyPath = TCollection_AsciiString(path.UTF8String);
    
    TopoDS_Shape shapeProfile = [Registry retrieveFromRegistryTransformed: keyProfile];
    
   
    TopoDS_Shape shapePath = [Registry retrieveFromRegistryTransformed: keyPath];
    
    TopoDS_Face profileFace = BRepBuilderAPI_MakeFace(TopoDS::Wire(shapeProfile), Standard_True);
    
    TopoDS_Shape solid;
    
    try {
        OCC_CATCH_SIGNALS
        
        solid = BRepOffsetAPI_MakePipe(TopoDS::Wire(shapePath), profileFace);
    }
    
    catch (...) {
        printf("DIDNT WORK");
    }
    
    
    //gets lost here when updating profile
    //TopoDS_Shape solid = BRepOffsetAPI_MakePipe(TopoDS::Wire(shapePath), profileFace);

    return [Registry storeInRegistryWithCString:solid];
}





+ (const char *) revolve:(const char *) profile
              aroundAxis:(SCNVector3) axisPosition
           withDirection:(SCNVector3) axisDirection
{
    TCollection_AsciiString keyProfile = TCollection_AsciiString(profile);
    
    TopoDS_Shape shapeProfile = [Registry retrieveFromRegistryTransformed: keyProfile];
    TopoDS_Face profileFace = BRepBuilderAPI_MakeFace(TopoDS::Wire(shapeProfile));
    
    gp_Ax1 axis = gp_Ax1(gp_Pnt(axisPosition.x, axisPosition.y, axisPosition.z),
                         gp_Dir(axisDirection.x, axisDirection.y, axisDirection.z));
    
    
    BRepPrimAPI_MakeRevol makeRevol = BRepPrimAPI_MakeRevol(profileFace, axis);
    makeRevol.Build();
    TopoDS_Shape revolution = makeRevol.Shape();

    return [Registry storeInRegistryWithCString:revolution];
}








+ (const char *) loft:(NSArray *) profiles
               length:(int) length;
{
    BRepOffsetAPI_ThruSections thruSections = BRepOffsetAPI_ThruSections(Standard_True);
    
    for (int i = 0; i < length; i++) {
        NSString *profile = profiles[i];
        
        TCollection_AsciiString keyProfile = TCollection_AsciiString(profile.UTF8String);
        
        TopoDS_Shape shapeProfile = [Registry retrieveFromRegistryTransformed: keyProfile];
        
        if (shapeProfile.ShapeType() == TopAbs_WIRE) {
            thruSections.AddWire(TopoDS::Wire(shapeProfile));
            
        } else if (shapeProfile.ShapeType() == TopAbs_VERTEX) {
            thruSections.AddVertex(TopoDS::Vertex(shapeProfile));
        }
    }
    
    TopoDS_Shape loft = thruSections.Shape();
    
    return [Registry storeInRegistryWithCString:loft];
}










+ (const char *) booleanCut:(const char *) a
                   subtract:(const char *) b;
{
    TCollection_AsciiString keyA = TCollection_AsciiString(a);
    TCollection_AsciiString keyB = TCollection_AsciiString(b);
    
    TopoDS_Shape shapeA = [Registry retrieveFromRegistryTransformed: keyA];
    TopoDS_Shape shapeB = [Registry retrieveFromRegistryTransformed: keyB];

    TopoDS_Shape difference = BRepAlgoAPI_Cut(shapeA, shapeB);
    
    return [Registry storeInRegistryWithCString:difference];
}


+ (const char *) booleanJoin:(const char *) a
                        with:(const char *) b
{
    TCollection_AsciiString keyA = TCollection_AsciiString(a);
    TCollection_AsciiString keyB = TCollection_AsciiString(b);
    
    TopoDS_Shape shapeA = [Registry retrieveFromRegistryTransformed: keyA];
    TopoDS_Shape shapeB = [Registry retrieveFromRegistryTransformed: keyB];
    
    TopoDS_Shape sum = BRepAlgoAPI_Fuse(shapeA, shapeB);
    
    return [Registry storeInRegistryWithCString:sum];
}

+ (const char *) booleanIntersect:(const char *) a
                             with:(const char *) b
{
    TCollection_AsciiString keyA = TCollection_AsciiString(a);
    TCollection_AsciiString keyB = TCollection_AsciiString(b);
    
    TopoDS_Shape shapeA = [Registry retrieveFromRegistryTransformed: keyA];
    TopoDS_Shape shapeB = [Registry retrieveFromRegistryTransformed: keyB];
    
    TopoDS_Shape sum = BRepAlgoAPI_Common(shapeA, shapeB);
    
    return [Registry storeInRegistryWithCString:sum];
}

@end

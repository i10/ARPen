//
//  Registry.m
//  ARPen
//
//  Created by Jan Benscheid on 27.09.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "Registry.h"

#include <occt/TopoDS_Shape.hxx>
#include <occt/TopoDS_Wire.hxx>
#include <occt/TCollection_AsciiString.hxx>
#include <occt/NCollection_DataMap.hxx>
#include <occt/gp_Trsf.hxx>
#include <occt/BRepBuilderAPI_Transform.hxx>
#include <occt/Standard_ErrorHandler.hxx>

@implementation Registry : NSObject

// OCCT is weird when it comes to applying transformations. Sometimes they are idempotent, sometimes not. I therefore treat transformations separately from the objects and apply them when necessary.
// It might have been more "elegant" to use pointers instead of strings for identifierts, but this solution was easier for me in combination with Swift.
static NCollection_DataMap<TCollection_AsciiString, TopoDS_Shape> shapeRegistry = NCollection_DataMap<TCollection_AsciiString, TopoDS_Shape>();


static NCollection_DataMap<TCollection_AsciiString, gp_Trsf> transformRegistry = NCollection_DataMap<TCollection_AsciiString, gp_Trsf>();

/// Generates a random null-terminated alphanumeric string of lenghth 32 to be used as a key for objects
+ (TCollection_AsciiString) randomString {
    static int length = 32;
    char s[length + 1];
    
    static const char alphanum[] =
        "0123456789"
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        "abcdefghijklmnopqrstuvwxyz";
    
    for (int i = 0; i < length; ++i) {
        s[i] = alphanum[rand() % (sizeof(alphanum) - 1)];
    }
    
    s[length] = 0;
    TCollection_AsciiString res = TCollection_AsciiString(s);
    return res;
}

/// Converts a OCCT string to a C string and stores in the heap.
+ (const char *) toHeapCString:(TCollection_AsciiString) input {
    const char *conv = input.ToCString();
    char *res = new char[strlen(conv) + 1];
    std::copy(conv, conv + strlen(conv) + 1, res);
    return res;
}

/// Stores a TopoDS_Shape in the registry and returns the generated key as an OCCT string.
+ (TCollection_AsciiString) storeInRegistry:(TopoDS_Shape &) shape {
    TCollection_AsciiString key = [self randomString];
    shapeRegistry.Bind(key, shape);
    return key;
}

/// Stores a TopoDS_Shape in the registry under a predefined key as an OCCT string.
+ (void) storeInRegistry:(TopoDS_Shape &) shape
                 withKey:(TCollection_AsciiString) key {
    shapeRegistry.Bind(key, shape);
}

/// Stores a TopoDS_Shape in the registry and returns the generated key as a C string.
+ (const char *) storeInRegistryWithCString:(TopoDS_Shape &) shape {
    TCollection_AsciiString key = [self randomString];
    shapeRegistry.Bind(key, shape);
    return [self toHeapCString:key];
}

/// Stores a transform in the registry under a predefined key as an OCCT string.
+ (void) storeInTransformRegistry:(gp_Trsf &) transform
                          withKey:(TCollection_AsciiString) key {
    transformRegistry.Bind(key, transform);
}

/// Deletes the TopoDS_Shape with the given key from the registry.
+ (void) deleteFromRegistry:(TCollection_AsciiString) key {
    shapeRegistry.UnBind(key);
    // TODO: Maybe key needs to be free'd manually?
    transformRegistry.UnBind(key);
}

/// Returns a TopoDS_Shape from the registry using an OCCT string as key.
+ (TopoDS_Shape) retrieveFromRegistry:(TCollection_AsciiString) key {
    return shapeRegistry.Find(key);
}

/// Returns a TopoDS_Shape from the registry using a C string as key.
+ (TopoDS_Shape) retrieveFromRegistryWithCString:(const char *) label {
    TCollection_AsciiString key = TCollection_AsciiString(label);
    return [self retrieveFromRegistry:key];
}

/// Returns a TopoDS_Shape from the registry (with its transformations applied) using an OCCT string as key.
+ (TopoDS_Shape) retrieveFromRegistryTransformed:(TCollection_AsciiString) key {
    TopoDS_Shape shape = shapeRegistry.Find(key);
    gp_Trsf trans;
    try {
        OCC_CATCH_SIGNALS
        trans = transformRegistry.Find(key);
    } catch (...) {
        trans = gp_Trsf();
    }
    // May be dangerous! If undesired behaviour occurs, try changing to Standard_True
    BRepBuilderAPI_Transform builder(shape, trans, Standard_False);
    return builder.Shape();
}

/// Effectively deletes a shape
+ (void) freeShape:(const char *) handle {
    TopoDS_Shape shape = [self retrieveFromRegistryWithCString:handle];
    shape.Nullify();
    TCollection_AsciiString key = TCollection_AsciiString(handle);
    [self deleteFromRegistry:key];
}

@end

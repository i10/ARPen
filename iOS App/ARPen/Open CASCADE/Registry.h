//
//  Registry.h
//  ARPen
//
//  Created by Jan Benscheid on 27.09.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

#ifndef Registry_h
#define Registry_h

#include <occt/TopoDS_Shape.hxx>
#include <occt/TCollection_AsciiString.hxx>
#include <occt/gp_Trsf.hxx>

@interface Registry : NSObject

/// Generates a random null-terminated alphanumeric string of lenghth 32 to be used as a key for objects
+ (TCollection_AsciiString) randomString;
/// Converts a OCCT string to a C string and stores in the heap.
+ (const char *) toHeapCString:(TCollection_AsciiString) input;

/// Stores a TopoDS_Shape in the registry and returns the generated key as an OCCT string.
+ (TCollection_AsciiString) storeInRegistry:(TopoDS_Shape &) shape;
/// Stores a TopoDS_Shape in the registry under a predefined key as an OCCT string.
+ (void) storeInRegistry:(TopoDS_Shape &) shape
                 withKey:(TCollection_AsciiString) key;
/// Stores a TopoDS_Shape in the registry and returns the generated key as a C string.
+ (const char *) storeInRegistryWithCString:(TopoDS_Shape &) shape;
/// Stores a transform in the registry under a predefined key as an OCCT string.
+ (void) storeInTransformRegistry:(gp_Trsf &) transform
                          withKey:(TCollection_AsciiString) key;


/// Effectively deletes a shape
+ (void) freeShape:(const char *) label;
/// Deletes the TopoDS_Shape with the given key from the registry.
+ (void) deleteFromRegistry:(TCollection_AsciiString) key;

/// Returns a TopoDS_Shape from the registry using an OCCT string as key.
+ (TopoDS_Shape) retrieveFromRegistry:(TCollection_AsciiString) key;
/// Returns a TopoDS_Shape from the registry using a C string as key.
+ (TopoDS_Shape) retrieveFromRegistryWithCString:(const char *) label;
/// Returns a TopoDS_Shape from the registry (with its transformations applied) using an OCCT string as key.
+ (TopoDS_Shape) retrieveFromRegistryTransformed:(TCollection_AsciiString) key;

@end

#endif /* Registry_h */

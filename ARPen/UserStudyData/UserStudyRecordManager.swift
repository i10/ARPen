//
//  UserStudyRecordManager.swift
//  ARPen
//
//  Created by Philipp Wacker on 13.03.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import Foundation

//the record manager keeps track of all records stored for all participants. These information can be exported to plist and csv
class UserStudyRecordManager : NSObject{
    var userStudyData : [Int:[UserStudyRecord]]
    
    var currentActiveUserID : Int? = nil {
        //if a new userID is set, create an empty array for the records for this new userID (key)
        didSet{
            if let currentActiveUserID = currentActiveUserID, self.userStudyData[currentActiveUserID] == nil {
                self.userStudyData[currentActiveUserID] = []
            }
        }
    }
    
    override init() {
        userStudyData = [:]
        super.init()
        //set previous user study data, if a matching plist file exists in the home directory of the device
        userStudyData = loadFromFile() ?? [:]
    }
    
    //accessing userStudyData
    func getCurrentUserStudyData() -> [Int:[UserStudyRecord]] {
        return userStudyData
    }
    
    func getSortedListOfUserIDs() -> [Int] {
        return userStudyData.keys.sorted()
    }
    
    func getRecords(forID id: Int) -> [UserStudyRecord]? {
        return userStudyData[id]
    }
    
    func set(records : [UserStudyRecord], forID id: Int) {
        userStudyData[id] = records
    }
    
    //data storage methods
    func addNewRecord(withIdentifier identifier: String, andData data: [String:String]) {
        //only add a new record if currently a userID is set
        guard let currentActiveUserID = self.currentActiveUserID else {
            return
        }
        //create a new record with the current time and specified data (identifier & data dictionary)
        let newRecord = UserStudyRecord(creationTime: Date(), identifier: identifier, data: data)
        
        //add new record to records array of the current user
        var dataRecordsOfCurrentUser = self.userStudyData[currentActiveUserID]
        dataRecordsOfCurrentUser?.append(newRecord)
        self.userStudyData[currentActiveUserID] = dataRecordsOfCurrentUser
    }
    
    //deletion methods
    func deleteAllRecords() {
        self.userStudyData = [:]
        currentActiveUserID = nil
    }
    
    //delete all records for a specified userID
    func deleteRecords(forID id: Int) -> [UserStudyRecord]? {
        return self.userStudyData.removeValue(forKey: id)
    }
    
    //delete a specific record at a specified position in the records array from a specified userID
    func deleteRecord(atPosition position: Int, forID id: Int) {
        self.userStudyData[id]?.remove(at: position)
    }
    
    //data export methods
    
    //try to create and store a plist file of current user study data. If successfull, return url to the created file
    func urlToPlist() -> URL? {
        let filePath = URL(fileURLWithPath: NSTemporaryDirectory() + "/\(self.getCurrentDateString())-StudyData.plist")
        do {
            try savePlist(atURL: filePath)
        } catch {
            print("Error while saving plist: \(error)")
            return nil
        }
        
        return filePath
    }
    
    //save current state of the user study data to the home directory on the device
    func saveToFile() {
        //specify destination file path for the plist
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let archiveURL = documentsDirectory.appendingPathComponent("userStudyData").appendingPathExtension("plist")
        do {
            try savePlist(atURL: archiveURL)
        } catch {
            print("Error while saving plist: \(error)")
        }
    }
    
    //try to load existing user study data from home directory on the device. If successfull, return the created userStudy Dictionary
    func loadFromFile() -> [Int:[UserStudyRecord]]? {
        //get URL to location where existin user study data would be stored
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let archiveURL = documentsDirectory.appendingPathComponent("userStudyData").appendingPathExtension("plist")
        let propertyListDecoder = PropertyListDecoder()
        do {
            //try to get and decode data at the specified file path
            let retrievedUserStudyData = try Data(contentsOf: archiveURL)
            let decodedUserStudyData = try propertyListDecoder.decode(Dictionary<Int,Array<UserStudyRecord>>.self, from: retrievedUserStudyData)
            return decodedUserStudyData
        } catch {
            print("User study data not loaded: \(error)")
        }
        return nil
    }
    
    //helper method to save a plist of current user study data at a specified location
    func savePlist(atURL url:URL) throws {
        let propertyListEncoder = PropertyListEncoder()
        let data = try propertyListEncoder.encode(self.userStudyData)
        try data.write(to: url)
    }
    
    func shareCSV() -> URL? {
        let filePath = URL(fileURLWithPath: NSTemporaryDirectory() + "/\(self.getCurrentDateString())-StudyData.csv")
        return filePath
    }
    
    //helper method to get a string representation of the current date (used to name the exported plist/csv)
    func getCurrentDateString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd-HH:mm:ss"
        let returnString = dateFormatter.string(from: Date())
        return returnString
    }
}

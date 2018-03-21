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
    fileprivate var userStudyData : [Int:[UserStudyRecord]]
    
    var currentActiveUserID : Int? = nil {
        //if a new userID is set, create an empty array for the records for this new userID (key)
        didSet{
            if let currentActiveUserID = currentActiveUserID, self.userStudyData[currentActiveUserID] == nil {
                self.userStudyData[currentActiveUserID] = []
            }
        }
    }
    
    fileprivate var headerNames = ["CreationTime", "UserID", "Identifier"]
    
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
    
    func urlToCSV() -> URL? {
        let filePath = URL(fileURLWithPath: NSTemporaryDirectory() + "/\(self.getCurrentDateString())-StudyData.csv")
        do {
            let csvString = generateCSVStringOfCurrentData()
            try csvString.write(to: filePath, atomically: true, encoding: .utf8)
        } catch {
            print("Error while saving csv: \(error)")
            return nil
        }
        return filePath
    }
    
    //helper method to get a string representation of the current date (used to name the exported plist/csv)
    func getCurrentDateString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd-HH:mm:ss"
        let returnString = dateFormatter.string(from: Date())
        return returnString
    }
    
    func generateCSVStringOfCurrentData() -> String {
        let dictOfData = generateFullDictFromCurrentData()
        var csvString = ""
        //generate header row
        for key in headerNames {
            csvString.append("\(key),")
        }
        csvString.removeLast()
        csvString.append("\n")
        
        let totalNumberOfLines = totalNumberOfRecords()
        for currentLineNumber in 0..<totalNumberOfLines {
            for columnName in headerNames {
                guard let currentEntry = dictOfData[columnName]?[currentLineNumber] else {
                    csvString.append(",")
                    continue
                }
                csvString.append("\(currentEntry),")
            }
            csvString.removeLast()
            csvString.append("\n")
        }
        
        return csvString
    }
    
    //collect names of all header colums
    func generateHeaderNamesArray() {
        
        //iterate over all users in the user study dictionary
        for (_, records) in self.userStudyData {
            //iterate over all records for a particular user
            for record in records {
                //iterate over all keys in the data dictionary of a particular record
                for (key, _) in record.data {
                    //if the name of the key is not already in the headerNames array, add it
                    if !headerNames.contains(key) {
                        headerNames.append(key)
                    }
                }
            }
        }
    }
    func generateFullDictFromCurrentData() -> [String:[String]] {
        generateHeaderNamesArray()
        
        //define number of lines (elements in each array)
        let totalNumberOfLines = totalNumberOfRecords()
        
        var returnDictionary : [String:[String]] = [:]
        for columnName in headerNames {
            returnDictionary[columnName] = [String].init(repeating: "", count: totalNumberOfLines)
        }
        
        //fill returnDictionary
        var currentIndex = 0
        for (userID, records) in self.userStudyData {
            for record in records {
                returnDictionary["CreationTime"]?[currentIndex] = record.creationTime.description
                returnDictionary["UserID"]?[currentIndex] = String(userID)
                returnDictionary["Identifier"]?[currentIndex] = record.identifier
                for (key, value) in record.data {
                    returnDictionary[key]?[currentIndex] = value
                }
                currentIndex += 1
            }
        }
        
        return returnDictionary
    }
    
    func totalNumberOfRecords() -> Int {
        var numberOfRecords = 0
        for (_, recordsArray) in self.userStudyData {
            numberOfRecords += recordsArray.count
        }
        return numberOfRecords
    }
}

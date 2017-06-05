//
//  Entry+CoreDataProperties.swift
//  Writing App
//
//  Created by Sten Golds on 1/9/17.
//  Copyright © 2017 Sten Golds. All rights reserved.
//

import Foundation
import CoreData

//XCode generated Entry CoreData class
extension Entry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Entry> {
        return NSFetchRequest<Entry>(entityName: "Entry");
    }

    @NSManaged public var body: String?
    @NSManaged public var date: Date?
    @NSManaged public var dateString: String?
    @NSManaged public var timeLeft: Int32

}

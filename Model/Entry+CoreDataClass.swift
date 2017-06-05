//
//  Entry+CoreDataClass.swift
//  Writing App
//
//  Created by Sten Golds on 1/9/17.
//  Copyright © 2017 Sten Golds. All rights reserved.
//

import Foundation
import CoreData


public class Entry: NSManagedObject {
    
    /**
     * @name stringForCurrentDate
     * @desc gets current date, and returns it formatted as a string
     * @return String - date in format such as January 28, 2017
     */
    func stringForCurrentDate() -> String {
        let fmtr = DateFormatter()
        fmtr.dateFormat = "MMMM d, YYYY"
        
        return fmtr.string(from: Date())
    }

}

//
//  Users+CoreDataProperties.swift
//  Oneboyonegirl
//
//  Created by ganyi on 16/10/10.
//  Copyright © 2016年 YiGan. All rights reserved.
//

import Foundation
import CoreData


extension Users {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Users> {
        return NSFetchRequest<Users>(entityName: "Users");
    }

    @NSManaged public var boyimagepath: String?
    @NSManaged public var girlimagepath: String?
    @NSManaged public var score: Int64
    @NSManaged public var date: NSDate?

}

//
//  Arts+CoreDataProperties.swift
//  Artworks on Campus
//
//  Created by Ziwei.Lin on 09/12/2018.
//  Copyright © 2018 Ziwei.Lin. All rights reserved.
//
//

import Foundation
import CoreData


extension Arts {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Arts> {
        return NSFetchRequest<Arts>(entityName: "Arts")
    }

    @NSManaged public var id: String?

}

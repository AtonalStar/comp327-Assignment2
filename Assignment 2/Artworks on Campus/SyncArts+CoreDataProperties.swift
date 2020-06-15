//
//  SyncArts+CoreDataProperties.swift
//  Artworks on Campus
//
//  Created by Ziwei.Lin on 13/12/2018.
//  Copyright © 2018 Ziwei.Lin. All rights reserved.
//
//

import Foundation
import CoreData


extension SyncArts {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SyncArts> {
        return NSFetchRequest<SyncArts>(entityName: "SyncArts")
    }

    @NSManaged public var id: String?
    @NSManaged public var title: String?
    @NSManaged public var year: String?
    @NSManaged public var info: String?
    @NSManaged public var fileName: String?
    @NSManaged public var lat: String?
    @NSManaged public var long: String?
    @NSManaged public var artist: String?
    @NSManaged public var location: String?
    @NSManaged public var locNote: String?
    @NSManaged public var enabled: String?
    @NSManaged public var lastModified: String?

}

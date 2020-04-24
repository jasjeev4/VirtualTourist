//
//  DataController.swift
//  Job Search
//
//  Created by JASJEEV on 4/21/20.
//  Copyright © 2020 Lorgarithmic Science. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    let persistentContainer: NSPersistentContainer
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    let backgroundContext: NSManagedObjectContext!
    class func sharedInstance() -> DataController {
        struct Singleton {
            static var instance = DataController(modelName: "VirutalTourist")
        }
        return Singleton.instance
    }

    private init(modelName: String) {
        print("Initializing")
        persistentContainer = NSPersistentContainer(name: modelName)
        backgroundContext = persistentContainer.newBackgroundContext()
    }

    func configureContexts() {
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    }

    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { _, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            self.configureContexts()
            completion?()
        }
    }
}

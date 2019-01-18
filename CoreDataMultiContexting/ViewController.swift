//
//  ViewController.swift
//  CoreDataMultiContexting
//
//  Created by Hrayr Yeghiazaryan on 18/01/2019.
//  Copyright © 2019 Hrayr Yeghiazaryan. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {

    private var dogName = ["Cris", "Leo", "Ney"]
    private let persistentContainer = AppDelegate().persistentContainer

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchDogs()
        // Do any additional setup after loading the view, typically from a nib.
    }

    func storeDogsInMainContext() {
        self.dogName.forEach({ (name) in
            // Creates a new entry inside the context `context` and assign the array element `name` to the dog's name
            let dog = Dog(context: persistentContainer.viewContext)
            dog.name = name
        })

        do {
            // Saves the entries created in the `forEach`
            try persistentContainer.viewContext.save()
        } catch {
            fatalError("Failure to save context: \(error)")
        }
    }

    func storeDogsInBackgorundContext() {
        let persistentContainer = AppDelegate().persistentContainer
        persistentContainer.performBackgroundTask { (backgroundContext) in
            self.dogName.forEach({ (name) in
                // Creates a new entry inside the context `context` and assign the array element `name` to the dog's name
                let dog = Dog(context: backgroundContext)
                dog.name = name
            })

            do {
                // Saves the entries created in the `forEach`
                try backgroundContext.save()
            } catch {
                fatalError("Failure to save context: \(error)")
            }
        }
    }

    func fetchDogs() {
        storeDogsInMainContext()
        //storeDogsInBackgorundContext()
        let privateManagedObjectContext = persistentContainer.newBackgroundContext()
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Dog")

        // Creates `asynchronousFetchRequest` with the fetch request and the completion closure
        let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { asynchronousFetchResult in

            // Retrieves an array of dogs from the fetch result `finalResult`
            guard let result = asynchronousFetchResult.finalResult as? [Dog] else { return }

            // Dispatches to use the data in the main queue
            DispatchQueue.main.async {
                // Creates an array for the new dogs queue-safe
                var dogs = [Dog]()

                // Iterates the result of the private context
                for dog in result {
                    // Retrieves the ID of the entity
                    let objectID = dog.objectID

                    // Creates a new dog entity queue-safe
                    guard let queueSafeDog = self.persistentContainer.viewContext.object(with: objectID) as? Dog else { continue }
                    // Adds to the array
                    dogs.append(queueSafeDog)
                }
                // Do something with new queue-safe array `dogs`
            }
        }

        do {
            // Executes `asynchronousFetchRequest`
            try privateManagedObjectContext.execute(asynchronousFetchRequest)
        } catch let error {
            print("NSAsynchronousFetchRequest error: \(error)")
        }
    }
}

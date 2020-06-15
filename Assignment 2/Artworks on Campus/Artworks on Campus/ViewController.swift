//
//  ViewController.swift
//  Artworks on Campus
//
//  Created by Ziwei.Lin on 09/12/2018.
//  Copyright © 2018 Ziwei.Lin. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import CoreLocation

//Create the structure of artwork to make it an object type
struct artwork: Decodable {
    let yearOfWork: String
    let id: String
    let artist: String
    let title: String
    let Information: String?
    let lat: String
    let long: String
    let location: String
    let locationNotes: String?
    let fileName: String
    let lastModified: String
    let enabled: String
}

//Create the structure of artworks2 which is an Array for artwork. This is used to decode JSON file.
struct artworks: Decodable {
    let artworks2: [artwork]
}

//Create a dictionary for table grouping
var artDic: Dictionary<Double, [artwork]> = [:]//The distance and the list of artworks
var sortedKeys: [Double] = []
var building: Dictionary<String, Double> = [:] //The the location and the distance
var searchDic: Dictionary<Double, [artwork]> = [:] // The searched Dictionary

//Define the global values
var allArts: [artwork] = []     //All artworks retrieved from the JSON data
var favourArts: [String] = []   //The favourite artworks stored in the CoreData as Arts
var currentSec: Int?            //Current Section
var currentRow: Int?            //Current Row

//CoreData
let appDelegate = UIApplication.shared.delegate as! AppDelegate
var context: NSManagedObjectContext?

//Synchronisation
let defaults = UserDefaults.standard
//Check if SyncArts is not empty
var synArts = [SyncArts]() // The retrieved SyncArts
var newArts = [artwork]()// artwork in the new url
var synCount: Int?      //The number of CoreData stored synArts
var urlString: String?     //The url string


class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MKMapViewDelegate, CLLocationManagerDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var locationManager = CLLocationManager() //Create an instance to manage the user's location
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locationOfUser = locations[0] //get the first location (ignore any others)
        let latitude = locationOfUser.coordinate.latitude
        let longitude = locationOfUser.coordinate.longitude
        let latDelta: CLLocationDegrees = 0.002
        let lonDelta: CLLocationDegrees = 0.002
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(center: location, span: span)
        self.map.setRegion(region, animated: true)
    }
    
    //Fetch SyncArts from CoreData
    func fetchSync(){
        let req = NSFetchRequest<NSFetchRequestResult>(entityName: "SyncArts")
        req.predicate = NSPredicate(format: "id <> %@", "")
        req.sortDescriptors?.append(NSSortDescriptor(key: "id", ascending: true))
        req.returnsObjectsAsFaults = false
        do {
            guard let result = try context?.fetch(req) else {return}
            synCount = result.count
            if synCount == 0{
                urlString = "https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP327/artworksOnCampus/data.php?class=artworks2&lastUpdate=2017-11-01"
            }else{
                //Retrieve the saved date
                let savedDate = defaults.object(forKey: "myDate")!
                print(savedDate)
                urlString = "https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP327/artworksOnCampus/data.php?class=artworks2&lastUpdate=\(savedDate)"
                for item in result as! [SyncArts]{
                    synArts.append(item)
                }
                for item in synArts{
                    print(item.title!)
                }
            }
        } catch {
            print("Failed")
        }
    }
    
   //Save an item  in SyncArts
    func saveSync(item: artwork){
        let entity = NSEntityDescription.entity(forEntityName: "SyncArts", in: context!)!
        let obart = NSManagedObject(entity: entity, insertInto: context!)
        obart.setValue(item.id, forKey: "id")
        obart.setValue(item.title, forKey: "title")
        obart.setValue(item.artist, forKey: "artist")
        obart.setValue(item.location, forKey: "location")
        obart.setValue(item.locationNotes, forKey: "locNote")
        obart.setValue(item.Information, forKey: "info")
        obart.setValue(item.enabled, forKey: "enabled")
        obart.setValue(item.fileName, forKey: "fileName")
        obart.setValue(item.yearOfWork, forKey: "year")
        obart.setValue(item.lat, forKey: "lat")
        obart.setValue(item.long, forKey: "long")
        obart.setValue(item.lastModified, forKey: "lastModified")
        do{
            try context!.save()
        }catch let error as NSError{
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    //Delete an item from the CoreData Entity
    func delete(id: String, entity: String){
        //NSFetchRequest is used to fetch a set of objects meeting the criteria.
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entity)
        let idPredicate = NSPredicate(format: "id == %@",  id)
        let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [idPredicate])
        fetchRequest.predicate = andPredicate
        do{
            let obart = try context!.fetch(fetchRequest)
            for art in obart{
                context!.delete(art)
            }
            do{
                try context!.save()
            }catch{
                print(error)
            }
        }catch{
            let nserror = error as NSError
            print("Unresolved Error \(nserror), \(nserror.userInfo)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialisations
        self.searchBar.delegate = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        context = appDelegate.persistentContainer.viewContext
        
        //Map view
        locationManager.delegate = self as CLLocationManagerDelegate //Messages about location
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.requestWhenInUseAuthorization() //Ask the users for permission to get their location
        locationManager.startUpdatingLocation() //Start receiving the messages if we are allowed to do so
        
        //fetch SyncArts and get urlString
        fetchSync()
        
        //Decode json
        if let url = URL(string: urlString!){
            let session = URLSession.shared
            session.dataTask(with: url) { (data, response, err) in
                guard let jsonData = data else {
                    return }
                do{
                    let decoder = JSONDecoder()
                    let artworkList = try decoder.decode(artworks.self, from: jsonData)
                    var count = 0
                    print(synCount!)
                    if synCount! == 0 { //Retrieve data for the first time
                        for item in artworkList.artworks2 {
                            count += 1
                            print("\(count) " + item.title)
                            //Build the allArts Array
                            allArts.append(item)
                        }
                        
                        //Caching artwork information to CoreData
                        for item in allArts{
                            self.saveSync(item: item)
                        }
                            
                    }else{
                        var synId = [String]()
                        for item in artworkList.artworks2{
                            newArts.append(item)
                        }
                        allArts = []
                        //Store the object from CoreData first
                        for item in synArts{
                            let art = artwork(yearOfWork: item.year!, id: item.id!, artist: item.artist!, title: item.title!, Information: item.info!, lat: item.lat!, long: item.long!, location: item.location!, locationNotes: item.locNote!, fileName: item.fileName!, lastModified: item.lastModified!, enabled: item.enabled!)
                            allArts.append(art)
                        }
                        //Handle the modification from the synchronised new data
                        if newArts.count > 0{
                            for item in synArts{
                                synId.append(item.id!)
                            }
                            //If the id of the new artwork has been stored in CoreData, then update the information of that SyncArt with the same id. If the id has not been stored, then add the artwork to the artwork list and then add to SyncArt in CoreData.
                            for item in newArts{
                                if synId.contains(item.id){
                                    for x in 0...allArts.count-1{
                                        if allArts[x].id == item.id{
                                            allArts.remove(at: x)
                                        }
                                    }
                                    allArts.append(item)
                                }else{
                                    allArts.append(item)
                                }
                            }
                        }
                        
                        //Caching artwork information to CoreData
                        for item in newArts{
                            if synId.contains(item.id){
                                self.delete(id: item.id, entity: "SyncArts")
                            }
                            self.saveSync(item: item)
                        }
                        print("Artworks Cached!")
                    }
                    
                    //Save the current date to the UserDefaults
                    let today = NSDate()
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    let todayString = formatter.string(from: today as Date)
                    defaults.set(todayString, forKey: "myDate")
                    
                    //Construct building which relates the locationNote to its distance from the Ashton Building.
                    for item in allArts{
                        guard let latitude = Double(item.lat) else { return }
                        guard let longitude = Double(item.long) else { return }
                        let coordinate1 = CLLocation(latitude: 53.406566, longitude: -2.966531)
                        let coordinate2 = CLLocation(latitude: latitude, longitude: longitude)
                        let distance = coordinate1.distance(from: coordinate2)
                        if !building.keys.contains(item.location){
                            building.updateValue(distance, forKey: item.location)
                        }
                    }
                    building.updateValue(0, forKey: "")
                    
                    //Construct artDic which group the artworks by their distance from Ashton Building
                    for item in allArts{
                        if !artDic.keys.contains(building[item.location]!){
                            let arr = [item]
                            artDic.updateValue(arr, forKey: building[item.location]!)
                        }else{
                            artDic[building[item.location]!]?.append(item)
                        }
                    }
                    
                    //Map View
                    //set up an annotation (a pin on the map)
                    for item in allArts{
                        guard let latitude = Double(item.lat) else { return }
                        guard let longitude = Double(item.long) else { return }
                        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                        let annotation = MKPointAnnotation()
                        annotation.coordinate = coordinate
                        annotation.title = item.location
                        let count = artDic[building[item.location]!]?.count
                        if count! == 1{ //When the location has only one artwork, show the detailed information of the artwork
                            annotation.subtitle = "\(artDic[building[item.location]!]![0].title) \n\(artDic[building[item.location]!]![0].yearOfWork)\n\(artDic[building[item.location]!]![0].Information ?? "No Information")"
                        }else{  //When the location has multiple artworks, count the number and show
                            annotation.subtitle = "\(count!) artworks are located"
                        }
                        self.map.addAnnotation(annotation)
                        self.map.delegate = self
                    }
                    
                    //Define the searchDic
                    searchDic = artDic
                    
                    //Sort the searchDic keys
                    sortedKeys = Array(searchDic.keys).sorted(by:<)
                    
                    //Fetch favourite artworks from CoreData
                    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Arts")
                    request.predicate = NSPredicate(format: "id <> %@", "")
                    request.sortDescriptors?.append(NSSortDescriptor(key: "id", ascending: true))
                    request.returnsObjectsAsFaults = false
                    do {
                        guard let result = try context?.fetch(request) else {return}
                        for item in result as! [Arts] {
                            favourArts.append(item.id!)
                        }
                    } catch {
                        print("Failed")
                    }
                    //All preparations are done, run the JSON parsing part in the main thread
                    DispatchQueue.main.async {
                        self.table.reloadData()
                    }
                } catch let error {
                    print("Error", error)
                }
                }.resume()
        }
        }
    
    //Search Bar
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            print(searchText)
            //Show all items when searchText is empty
            //Else match the prefix of the items in dictionary with the searchText
            if searchText == ""{
                searchDic = artDic
            }else{
                searchDic = [:]
                for item in allArts{
                    if item.location.lowercased().hasPrefix(searchText.lowercased()){
                        if !searchDic.keys.contains(building[item.location]!){
                            let arr = [item]
                            searchDic.updateValue(arr, forKey: building[item.location]!)
                        }else{
                            searchDic[building[item.location]!]?.append(item)
                        }
                    }
                }
                //search for artwork title
                var arr = [artwork]()
                for item in allArts{
                    if item.title.lowercased().hasPrefix(searchText.lowercased()){
                        arr.append(item)
                    }
                }
                searchDic.updateValue(arr, forKey: 0)
            }
            //Sort the searchDic keys
            sortedKeys = Array(searchDic.keys).sorted(by:<)
            self.table.reloadData()
        }
        
        //Define a function to call the textDidChange function
        func searchBarChange(searchBar: UISearchBar){
            print(searchBar.text!)
            if searchBar.text == ""{
                searchDic = artDic
            }else{
                searchDic = [:]
                for item in allArts{
                    if item.location.lowercased().hasPrefix(searchBar.text!.lowercased()){
                        if !searchDic.keys.contains(building[item.location]!){
                            let arr = [item]
                            searchDic.updateValue(arr, forKey: building[item.location]!)
                        }else{
                            searchDic[building[item.location]!]?.append(item)
                        }
                    }
                }
                var arr = [artwork]()
                for item in allArts{
                    if item.title.lowercased().hasPrefix(searchBar.text!.lowercased()){
                        arr.append(item)
                    }
                }
                searchDic.updateValue(arr, forKey: 0)
            }
            //Sort the searchDic keys
            sortedKeys = Array(searchDic.keys).sorted(by:<)
            self.table.reloadData()
        }
        
        //Table
        func numberOfSections(in tableView: UITableView) -> Int {
            return searchDic.keys.count
        }
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            let key = sortedKeys[section]
            return searchDic[key]!.count
        }
    
        func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
            let label = UILabel()
            let distance = sortedKeys[section]
            var keys = [String]()
            for item in building{
                if item.value == distance{
                    keys.append(item.key)
                }
            }
            label.text = String("   \(keys[0])")
            label.backgroundColor = #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1)
            label.textColor = #colorLiteral(red: 0.9658980665, green: 1, blue: 0.09656455445, alpha: 1)
            return label
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "Cell")
            let key = sortedKeys[indexPath.section]
            cell.textLabel?.text = String(searchDic[key]![indexPath.row].title)
            cell.detailTextLabel?.text = String(searchDic[key]![indexPath.row].artist)
            cell.backgroundColor = #colorLiteral(red: 0.840182331, green: 1, blue: 0.6005202191, alpha: 1)
            //Mark favourite artworks
            if favourArts.contains (searchDic[key]![indexPath.row].id){
                cell.accessoryType = .checkmark
            }
            return cell
        }
    
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            print ("Perform Segue")
            currentSec = indexPath.section
            currentRow = indexPath.row
            performSegue(withIdentifier: "to Detail", sender: nil)
        }
    
    //Save the new item into CoreData Entity
    func save(id: String){
        context = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Arts", in: context!)!
        
        let obart = NSManagedObject(entity: entity, insertInto: context!)
        obart.setValue(id, forKey: "id")
        
        do{
            try context!.save()
        }catch let error as NSError{
            print("Could not save. \(error), \(error.userInfo)")
        }
        
    }
        
    //Table view delegate: Set swiping table cell for adding and deleting favourite artworks
        func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
            let favourite = addToFavour(at: indexPath)
            return UISwipeActionsConfiguration(actions: [favourite])
        }
        
        func addToFavour(at indexPath: IndexPath) -> UIContextualAction{
            let key = sortedKeys[indexPath.section]
            let art = artDic[key]![indexPath.row]
            let action = UIContextualAction(style: .normal, title: "Favourite"){ (action, view, completion) in
                if !favourArts.contains(art.id){
                    self.save(id: art.id)
                    favourArts.append(art.id)
                    print("item saved")
                }else{
                    self.delete(id: art.id, entity: "Arts")
                    let index = favourArts.index(of: art.id)
                    favourArts.remove(at: index!)
                    print("item deleted")
                }
                completion(true)
                self.table.reloadData()
            }
            
            action.title = favourArts.contains(art.id) ? "Delete" : "Favourite"
            action.backgroundColor = favourArts.contains(art.id) ? .red : .purple
            return action
        }
        
    //MapView: set the small box to show the number of artworks in a location OR the image and information of a single artwork
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation{
                return nil
            }
            let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "myAnnotation")
            annotationView.annotation = annotation
            annotationView.image = UIImage(named: "pin")
            
            let subtitleView = UILabel()
            subtitleView.font = subtitleView.font.withSize(12)
            subtitleView.numberOfLines = 0
            subtitleView.text = annotation.subtitle!
            annotationView.detailCalloutAccessoryView = subtitleView
            
            if artDic[building[((annotation.title)!)!]!]?.count == 1{
                //left image
                let img = artDic[building[((annotation.title)!)!]!]![0].fileName
                let originalUrl = "https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP327/artwork_images/\(img)"
                let urlString = originalUrl.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
                let url = URL(string: urlString!)
                let data = try? Data(contentsOf: url!)
                let leftIV = UIImageView(frame: CGRect(x: 0, y: 0, width: 55, height: 55))
                leftIV.image = UIImage(data: data!)
                annotationView.leftCalloutAccessoryView = leftIV
            }
            
            annotationView.canShowCallout = true
            return annotationView
        }
    
        //Actions when select a particular annotation
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if artDic[building[((view.annotation!.title)!)!]!]?.count != 1{
                searchBar.text = (view.annotation?.title)!
                self.searchBarChange(searchBar: searchBar)
            }
        }
        
        override func didReceiveMemoryWarning() {
            super.didReceiveMemoryWarning()
        }
}

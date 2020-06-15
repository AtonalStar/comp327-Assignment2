//
//  DetailViewController.swift
//  Artworks on Campus
//
//  Created by Ziwei.Lin on 09/12/2018.
//  Copyright © 2018 Ziwei.Lin. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    
    @IBOutlet weak var artTitle: UILabel!
    
    @IBOutlet weak var artImg: UIImageView!
    
    @IBOutlet weak var artistName: UILabel!
    
    @IBOutlet weak var year: UILabel!
    
    @IBOutlet weak var info: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let key = sortedKeys[currentSec!]
        
        artTitle.text = searchDic[key]![currentRow!].title
        artistName.text = searchDic[key]![currentRow!].artist
        year.text = searchDic[key]![currentRow!].yearOfWork
        info.text = searchDic[key]![currentRow!].Information
        
        let img = searchDic[key]![currentRow!].fileName
        let originalUrl = "https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP327/artwork_images/\(img)"
        var urlString = originalUrl.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        let url = URL(string: urlString!)
        let data = try? Data(contentsOf: url!)
        artImg.image = UIImage(data: data!)
        

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

//
//  DisplayFlowerViewController.swift
//  FlowerExpert
//
//  Created by Thao Doan on 9/22/18.
//  Copyright © 2018 Thao Doan. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage


class DisplayFlowerViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    @IBOutlet weak var flowerImageView: UIImageView!
    
    let wikiURL = "https://en.wikipedia.org/w/api.php"

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewWillAppear(_ animated: Bool) {
    }
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var wikiResultImageView: UIImageView!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBAction func carmeraButtonTapped(_ sender: UIBarButtonItem) {
        let imagePickerControler = UIImagePickerController()
        imagePickerControler.delegate = self
        let actionSheetController = UIAlertController(title: "Select Photo Location", message: nil, preferredStyle: .actionSheet)
        actionSheetController.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action : UIAlertAction) in
            imagePickerControler.sourceType = .camera
            self.present(imagePickerControler, animated: true, completion: nil)
        }))
        actionSheetController.addAction(UIAlertAction(title: "Photo library", style: .default, handler: { (action : UIAlertAction) in
            imagePickerControler.sourceType = .photoLibrary
            self.present(imagePickerControler, animated: true, completion: nil)
        }))
        actionSheetController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(actionSheetController, animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            guard let ciImage = CIImage(image: userPickedImage) else {fatalError("Can't not convert to CiImage")}
            flowerImageView.image = userPickedImage
             detect(image:ciImage )
        }
           picker.dismiss(animated: true, completion: nil)
    }
    
    func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Cannot import model")}
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let classification = request.results?.first as? VNClassificationObservation else {fatalError("Can't not classify image")}
            self.navigationItem.title = "Results"
            self.resultLabel.text = "Flower's name:\(classification.identifier.capitalized)"
            self.requestInfor(flowerName: classification.identifier.capitalized)
         
        }
        let handler = VNImageRequestHandler(ciImage: image)
        do {
          try handler.perform([request])
        } catch {
            print(error.localizedDescription)
        }
}
    
    func requestInfor(flowerName: String){
        let parameters : [String:String] = [
                "format" : "json",
                "action" : "query",
                "prop" : "extracts|pageimages",
                "exintro" : "",
                "explaintext" : "",
                "titles" : flowerName,
                "indexpageids" : "",
                "redirects" : "1",
                "pithumbsize": "300"
                ]
        Alamofire.request(wikiURL, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
                print(response.result)
                let flowerJson : JSON = JSON(response.result.value!)
                let pageId = flowerJson["query"]["pageids"][0].stringValue
                let flowerDescription = flowerJson["query"]["pages"][pageId]["extract"].stringValue
                let flowerImageUrl = flowerJson["query"]["pages"][pageId]["thumbnail"]["source"].stringValue
                self.wikiResultImageView.sd_setImage(with: URL(string: flowerImageUrl))
                self.descriptionTextView.text = flowerDescription.capitalized
            }
        }
    }
}



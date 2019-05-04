//
//  ImageClassificationViewController.swift
//  Hotdog Not Hotdog Final App
//
//  Created by Tom Kotopoulos
//  Copyright © 2019 Tom Kotopoulos. All rights reserved.
//

import UIKit
import CoreML
import Vision
import ImageIO
import AVFoundation

class ImageClassificationViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var classificationLabel: UILabel!
    @IBOutlet weak var answerImage: UIImageView!
    
    var audioPlayer = AVAudioPlayer()
    
    let hotDogModel = HotdogClassifier().model
    let bostonModel = Boston_Sports_Logos_1().model
    var activeModel: MLModel? = nil
    var modelName = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    
    //CORE ML Set Up
    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: activeModel!)
            
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            })
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    func updateClassifications(for image: UIImage) {
        classificationLabel.text = "Classifying..."
        
        //Preprocess image that came into this function
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        guard let ciImage = CIImage(image: image) else { fatalError("Unable to create \(CIImage.self) from \(image).") }
        
        //Set up a gueue so that the classification can run in the background while other actions can still be processed
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                try handler.perform([self.classificationRequest])
            } catch {
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
    }
    
    //
    func processClassifications(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            //Get results that were processed in above function
            guard let results = request.results else {
                self.classificationLabel.text = "Unable to classify image.\n\(error!.localizedDescription)"
                return
            }
            //Cast the results to the correct class
            let classifications = results as! [VNClassificationObservation]
            
            
            //Update the results label accordingly
            if classifications.isEmpty {
                self.classificationLabel.text = "Nothing recognized."
            } else {
                // Display top classifications ranked by confidence in the UI.
                let topClassifications = classifications.prefix(1)
                let descriptions = topClassifications.map { classification in
                    //Format the classification label correctly
                    return String(format: "  (%.2f) %@", classification.confidence, classification.identifier)
                }
                //                print("Classification: ***: \(topClassifications[0].identifier)")
                
                if self.modelName == "HotDog"{
                    self.answerImage.image = UIImage(named: topClassifications[0].identifier)
                    let previousY = self.answerImage.frame.origin.y
                    self.answerImage.frame.origin.y = -self.answerImage.frame.height
                    UIView.animate(withDuration: 1, animations:{ self.answerImage.frame.origin.y = previousY})
                    self.playSound(soundName: "\(topClassifications[0].identifier)_sound", audioPlayer: &self.audioPlayer)
                    self.classificationLabel.text = "Classification:\n" + descriptions.joined(separator: "\n")
                } else{
                    self.classificationLabel.text = "Classification:\n" + descriptions.joined(separator: "\n")
                    print("Segue to another VC")
                }
                
            }
        }
    }
    
    @IBAction func takePicture() {
        // Show options for the source picker only if the camera is available.
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            presentPhotoPicker(sourceType: .photoLibrary)
            return
        }
        
        let photoSourcePicker = UIAlertController()
        let takePhoto = UIAlertAction(title: "Take Photo", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .camera)
        }
        let choosePhoto = UIAlertAction(title: "Choose Photo", style: .default) { [unowned self] _ in
            self.presentPhotoPicker(sourceType: .photoLibrary)
        }
        
        photoSourcePicker.addAction(takePhoto)
        photoSourcePicker.addAction(choosePhoto)
        photoSourcePicker.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(photoSourcePicker, animated: true)
    }
    
    func presentPhotoPicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        present(picker, animated: true)
    }
    
    func playSound (soundName: String, audioPlayer: inout AVAudioPlayer){
        //can we load in the file soundName
        if let sound = NSDataAsset(name: soundName){
            
            //check to see if sound.data is actually a sound file and play
            do{
                try audioPlayer = AVAudioPlayer(data: sound.data)
                audioPlayer.play()
                // catch error if sound.data isn't a sound file
            } catch {
                print("ERROR: The data in \(soundName) couldn't be loaded")
            }
        }else{
            print("ERROR: The file \(soundName) didn't load")
        }
    }
}

extension ImageClassificationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]){
        picker.dismiss(animated: true)
        
        // We always expect `imagePickerController(:didFinishPickingMediaWithInfo:)` to supply the original image.
        guard let image = info[.originalImage] as? UIImage else {
        fatalError("Expected a dictionary containing an image, but was provided the following: \(info)")
        }
        imageView.image = image
        updateClassifications(for: image)
    }
}

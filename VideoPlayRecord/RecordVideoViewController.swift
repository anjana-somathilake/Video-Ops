//
//  RecordVideoViewController.swift
//  VideoPlayRecord
//
//  Created by Andy on 2/1/15.
//  Copyright (c) 2015 Ray Wenderlich. All rights reserved.
//

import UIKit
import MobileCoreServices

class RecordVideoViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
  
  
  
  @IBAction func record(sender: AnyObject) {
    startCameraFromViewController(self, withDelegate: self)
  }

  func startCameraFromViewController(viewController: UIViewController, withDelegate delegate: protocol<UIImagePickerControllerDelegate, UINavigationControllerDelegate>) -> Bool {
    if UIImagePickerController.isSourceTypeAvailable(.Camera) == false {
      return false
    }

    let cameraController = UIImagePickerController()
    cameraController.sourceType = .Camera
    cameraController.mediaTypes = [kUTTypeMovie as NSString as String]
    cameraController.allowsEditing = false
    cameraController.delegate = delegate

    presentViewController(cameraController, animated: true, completion: nil)
    return true
  }

  func video(videoPath: NSString, didFinishSavingWithError error: NSError?, contextInfo info: AnyObject) {
    var title = "Success"
    var message = "Video was saved"
    if let _ = error {
      title = "Error"
      message = "Video failed to save"
    }
    let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
    presentViewController(alert, animated: true, completion: nil)
  }
  
}

// MARK: - UIImagePickerControllerDelegate

extension RecordVideoViewController: UIImagePickerControllerDelegate {
  func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
    let mediaType = info[UIImagePickerControllerMediaType] as! NSString
    dismissViewControllerAnimated(true, completion: nil)
    // Handle a movie capture
    if mediaType == kUTTypeMovie {
      guard let path = (info[UIImagePickerControllerMediaURL] as! NSURL).path else { return }
      if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path) {
        UISaveVideoAtPathToSavedPhotosAlbum(path, self, #selector(RecordVideoViewController.video(_:didFinishSavingWithError:contextInfo:)), nil)
      }
    }
  }
}

// MARK: - UINavigationControllerDelegate

extension RecordVideoViewController: UINavigationControllerDelegate {
}

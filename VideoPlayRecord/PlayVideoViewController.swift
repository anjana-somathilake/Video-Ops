//
//  PlayVideoViewController.swift
//  VideoPlayRecord
//
//  Created by Andy on 2/1/15.
//  Copyright (c) 2015 Ray Wenderlich. All rights reserved.
//

import UIKit
import MediaPlayer
import MobileCoreServices

class PlayVideoViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  @IBAction func playVideo(sender: AnyObject) {
    startMediaBrowserFromViewController(self, usingDelegate: self)
  }

  func startMediaBrowserFromViewController(viewController: UIViewController, usingDelegate delegate: protocol<UINavigationControllerDelegate, UIImagePickerControllerDelegate>) -> Bool {
    // 1
    if UIImagePickerController.isSourceTypeAvailable(.SavedPhotosAlbum) == false {
      return false
    }

    // 2
    let mediaUI = UIImagePickerController()
    mediaUI.sourceType = .SavedPhotosAlbum
    mediaUI.mediaTypes = [kUTTypeMovie as NSString as String]
    mediaUI.allowsEditing = true
    mediaUI.delegate = delegate

    // 3
    presentViewController(mediaUI, animated: true, completion: nil)
    return true
  }

}

// MARK: - UIImagePickerControllerDelegate

extension PlayVideoViewController: UIImagePickerControllerDelegate {
  func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
    // 1
    let mediaType = info[UIImagePickerControllerMediaType] as! NSString

    // 2
    dismissViewControllerAnimated(true) {
      // 3
      if mediaType == kUTTypeMovie {
        let moviePlayer = MPMoviePlayerViewController(contentURL: info[UIImagePickerControllerMediaURL] as! NSURL)
        self.presentMoviePlayerViewControllerAnimated(moviePlayer)
      }
    }
  }
}

// MARK: - UINavigationControllerDelegate

extension PlayVideoViewController: UINavigationControllerDelegate {
}

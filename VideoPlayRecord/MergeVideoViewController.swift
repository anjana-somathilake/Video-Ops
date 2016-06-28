//
//  MergeVideoViewController.swift
//  VideoPlayRecord
//
//  Created by Andy on 2/1/15.
//  Copyright (c) 2015 Ray Wenderlich. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices
import AssetsLibrary
import MediaPlayer
import CoreMedia

class MergeVideoViewController: UIViewController {
  var firstAsset: AVAsset?
  var secondAsset: AVAsset?
  var audioAsset: AVAsset?
  var loadingAssetOne = false
  
  @IBOutlet var activityMonitor: UIActivityIndicatorView!
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func savedPhotosAvailable() -> Bool {
    if UIImagePickerController.isSourceTypeAvailable(.SavedPhotosAlbum) == false {
      let alert = UIAlertController(title: "Not Available", message: "No Saved Album found", preferredStyle: .Alert)
      alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
      presentViewController(alert, animated: true, completion: nil)
      return false
    }
    return true
  }
  
  func startMediaBrowserFromViewController(viewController: UIViewController!, usingDelegate delegate : protocol<UINavigationControllerDelegate, UIImagePickerControllerDelegate>!) -> Bool {
    
    if UIImagePickerController.isSourceTypeAvailable(.SavedPhotosAlbum) == false {
      return false
    }
    
    let mediaUI = UIImagePickerController()
    mediaUI.sourceType = .SavedPhotosAlbum
    mediaUI.mediaTypes = [kUTTypeMovie as NSString as String]
    mediaUI.allowsEditing = true
    mediaUI.delegate = delegate
    presentViewController(mediaUI, animated: true, completion: nil)
    return true
  }
  
  func exportDidFinish(session: AVAssetExportSession) {
//    if session.status == AVAssetExportSessionStatus.Completed {
      let outputURL = session.outputURL
      let library = ALAssetsLibrary()
      if library.videoAtPathIsCompatibleWithSavedPhotosAlbum(outputURL) {
        library.writeVideoAtPathToSavedPhotosAlbum(outputURL,
                                                   completionBlock: { (assetURL:NSURL!, error:NSError!) -> Void in
                                                    var title = ""
                                                    var message = ""
                                                    if error != nil {
                                                      title = "Error"
                                                      message = "Failed to save video"
                                                    } else {
                                                      title = "Success"
                                                      message = "Video saved"
                                                    }
                                                    let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
                                                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
                                                    self.presentViewController(alert, animated: true, completion: nil)

        })
      }
//    }
    
    activityMonitor.stopAnimating()
    firstAsset = nil
    secondAsset = nil
    audioAsset = nil
  }
  
  @IBAction func loadAssetOne(sender: AnyObject) {
    if savedPhotosAvailable() {
      loadingAssetOne = true
      startMediaBrowserFromViewController(self, usingDelegate: self)
    }
  }
  
  
  @IBAction func loadAssetTwo(sender: AnyObject) {
    if savedPhotosAvailable() {
      loadingAssetOne = false
      startMediaBrowserFromViewController(self, usingDelegate: self)
    }
  }
  
  
  @IBAction func loadAudio(sender: AnyObject) {
    let mediaPickerController = MPMediaPickerController(mediaTypes: .Any)
    mediaPickerController.delegate = self
    mediaPickerController.prompt = "Select Audio"
    presentViewController(mediaPickerController, animated: true, completion: nil)
  }
  
  func orientationFromTransform(transform: CGAffineTransform) -> (orientation: UIImageOrientation, isPortrait: Bool) {
    var assetOrientation = UIImageOrientation.Up
    var isPortrait = false
    if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
      assetOrientation = .Right
      isPortrait = true
    } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
      assetOrientation = .Left
      isPortrait = true
    } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
      assetOrientation = .Up
    } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
      assetOrientation = .Down
    }
    return (assetOrientation, isPortrait)
  }
  
  func videoCompositionInstructionForTrack(track: AVCompositionTrack, asset: AVAsset) -> AVMutableVideoCompositionLayerInstruction {
    let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
    let assetTrack = asset.tracksWithMediaType(AVMediaTypeVideo)[0]
    
    let transform = assetTrack.preferredTransform
    let assetInfo = orientationFromTransform(transform)
    
    var scaleToFitRatio = UIScreen.mainScreen().bounds.width / assetTrack.naturalSize.width
    if assetInfo.isPortrait {
      scaleToFitRatio = UIScreen.mainScreen().bounds.width / assetTrack.naturalSize.height
      let scaleFactor = CGAffineTransformMakeScale(scaleToFitRatio, scaleToFitRatio)
      instruction.setTransform(CGAffineTransformConcat(assetTrack.preferredTransform, scaleFactor),
                               atTime: kCMTimeZero)
    } else {
      let scaleFactor = CGAffineTransformMakeScale(scaleToFitRatio, scaleToFitRatio)
      var concat = CGAffineTransformConcat(CGAffineTransformConcat(assetTrack.preferredTransform, scaleFactor), CGAffineTransformMakeTranslation(0, UIScreen.mainScreen().bounds.width / 2))
      if assetInfo.orientation == .Down {
        let fixUpsideDown = CGAffineTransformMakeRotation(CGFloat(M_PI))
        let windowBounds = UIScreen.mainScreen().bounds
        let yFix = assetTrack.naturalSize.height + windowBounds.height
        let centerFix = CGAffineTransformMakeTranslation(assetTrack.naturalSize.width, yFix)
        concat = CGAffineTransformConcat(CGAffineTransformConcat(fixUpsideDown, centerFix), scaleFactor)
      }
      instruction.setTransform(concat, atTime: kCMTimeZero)
    }
    
    return instruction
  }
  
  
      @IBAction func merge(sender: AnyObject) {
        //    if let firstAsset = firstAsset, secondAsset = secondAsset {

        let firstAsset = AVURLAsset(URL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("1", ofType: "m4v")!))
        let secondAsset = AVURLAsset(URL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("2", ofType: "m4v")!))
        let thirdAsset = AVURLAsset(URL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("3", ofType: "m4v")!))
        let fourthAsset = AVURLAsset(URL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("4", ofType: "m4v")!))


        activityMonitor.startAnimating()

        // 1 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
        let mixComposition = AVMutableComposition()

        // 2 - Create two video tracks
        let firstTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        do {
        try firstTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, firstAsset.duration), ofTrack: firstAsset.tracksWithMediaType(AVMediaTypeVideo)[0], atTime: kCMTimeZero)

        } catch _ {
        print("Failed to load first track")
        }

        let firstTrackAudio = mixComposition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        do {
        try firstTrackAudio.insertTimeRange(CMTimeRangeMake(kCMTimeZero, firstAsset.duration), ofTrack: firstAsset.tracksWithMediaType(AVMediaTypeAudio)[0], atTime: kCMTimeZero)

        } catch _ {
        print("Failed to load first track audio")
        }
        //_____________

        let secondTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        do {
        try secondTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, secondAsset.duration), ofTrack: secondAsset.tracksWithMediaType(AVMediaTypeVideo)[0], atTime: firstAsset.duration)
        } catch _ {
        print("Failed to load second track")
        }
        
        let secondTrackAudio = mixComposition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        do {
            try secondTrackAudio.insertTimeRange(CMTimeRangeMake(kCMTimeZero, secondAsset.duration), ofTrack: secondAsset.tracksWithMediaType(AVMediaTypeAudio)[0], atTime: firstAsset.duration)
        } catch _ {
            print("Failed to load second track audio")
        }
        //_____________
        let thirdTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        do {
            try thirdTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, thirdAsset.duration), ofTrack: thirdAsset.tracksWithMediaType(AVMediaTypeVideo)[0], atTime: CMTimeAdd(firstAsset.duration, secondAsset.duration))
        } catch _ {
            print("Failed to load 3rd track")
        }
        
        let thirdTrackAudio = mixComposition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        do {
            try thirdTrackAudio.insertTimeRange(CMTimeRangeMake(kCMTimeZero, thirdAsset.duration), ofTrack: thirdAsset.tracksWithMediaType(AVMediaTypeAudio)[0], atTime: CMTimeAdd(firstAsset.duration, secondAsset.duration))
        } catch _ {
            print("Failed to load 3rd track audio")
        }
        //_____________
        let fourthTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        do {
            try fourthTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, fourthAsset.duration), ofTrack: fourthAsset.tracksWithMediaType(AVMediaTypeVideo)[0], atTime: CMTimeAdd(CMTimeAdd(firstAsset.duration, secondAsset.duration),thirdAsset.duration))
        } catch _ {
            print("Failed to load 4t track")
        }
        
        let fourthTrackAudio = mixComposition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        do {
            try fourthTrackAudio.insertTimeRange(CMTimeRangeMake(kCMTimeZero, fourthAsset.duration), ofTrack: fourthAsset.tracksWithMediaType(AVMediaTypeAudio)[0], atTime: CMTimeAdd(CMTimeAdd(firstAsset.duration, secondAsset.duration),thirdAsset.duration))
        } catch _ {
            print("Failed to load 4th track audio")
        }
        //_____________
        
        

        // 2.1
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeAdd(CMTimeAdd(firstAsset.duration, secondAsset.duration),CMTimeAdd(thirdAsset.duration, fourthAsset.duration)))
        

        // 2.2
        let firstInstruction = videoCompositionInstructionForTrack(firstTrack, asset: firstAsset)
        firstInstruction.setOpacity(0.0, atTime: firstAsset.duration)
        
        let secondInstruction = videoCompositionInstructionForTrack(secondTrack, asset: secondAsset)
        secondInstruction.setOpacity(0.0, atTime: CMTimeAdd(firstAsset.duration,secondAsset.duration))
        
        let thirdInstruction = videoCompositionInstructionForTrack(thirdTrack, asset: thirdAsset)
        thirdInstruction.setOpacity(0.0, atTime: CMTimeAdd(CMTimeAdd(firstAsset.duration,secondAsset.duration),thirdAsset.duration))
        
        let fourthInstruction = videoCompositionInstructionForTrack(fourthTrack, asset: fourthAsset)

        // 2.3
        mainInstruction.layerInstructions = [firstInstruction, secondInstruction,thirdInstruction,fourthInstruction]
        let mainComposition = AVMutableVideoComposition()
        mainComposition.instructions = [mainInstruction]
        mainComposition.frameDuration = CMTimeMake(1, 30)
        mainComposition.renderSize = CGSize(width: UIScreen.mainScreen().bounds.width, height: UIScreen.mainScreen().bounds.height)



        // 4 - Get path
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .LongStyle
        dateFormatter.timeStyle = .ShortStyle
        let date = dateFormatter.stringFromDate(NSDate())
        let savePath = (documentDirectory as NSString).stringByAppendingPathComponent("mergeVideo-\(date).mov")
        let url = NSURL(fileURLWithPath: savePath)

        // 5 - Create Exporter
        guard let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else { return }
        exporter.outputURL = url
        exporter.outputFileType = AVFileTypeQuickTimeMovie
        exporter.shouldOptimizeForNetworkUse = true
        exporter.videoComposition = mainComposition

        // 6 - Perform the Export
        exporter.exportAsynchronouslyWithCompletionHandler() {
        dispatch_async(dispatch_get_main_queue()) { _ in
        self.exportDidFinish(exporter)
        }
        }

      }
  
}

extension MergeVideoViewController: UIImagePickerControllerDelegate {
  func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
    let mediaType = info[UIImagePickerControllerMediaType] as! NSString
    dismissViewControllerAnimated(true, completion: nil)
    
    if mediaType == kUTTypeMovie {
      let avAsset = AVAsset(URL:info[UIImagePickerControllerMediaURL] as! NSURL)
      var message = ""
      if loadingAssetOne {
        message = "Video one loaded"
        firstAsset = avAsset
      } else {
        message = "Video two loaded"
        secondAsset = avAsset
      }
      let alert = UIAlertController(title: "Asset Loaded", message: message, preferredStyle: .Alert)
      alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
      presentViewController(alert, animated: true, completion: nil)
    }
  }
  
}

extension MergeVideoViewController: UINavigationControllerDelegate {
  
}

extension MergeVideoViewController: MPMediaPickerControllerDelegate {
  func mediaPicker(mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
    let selectedSongs = mediaItemCollection.items
    if selectedSongs.count > 0 {
      let song = selectedSongs[0]
      if let url = song.valueForProperty(MPMediaItemPropertyAssetURL) as? NSURL {
        audioAsset = (AVAsset(URL:url) )
        dismissViewControllerAnimated(true, completion: nil)
        let alert = UIAlertController(title: "Asset Loaded", message: "Audio Loaded", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler:nil))
        presentViewController(alert, animated: true, completion: nil)
      } else {
        dismissViewControllerAnimated(true, completion: nil)
        let alert = UIAlertController(title: "Asset Not Available", message: "Audio Not Loaded", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler:nil))
        presentViewController(alert, animated: true, completion: nil)
      }
    } else {
      dismissViewControllerAnimated(true, completion: nil)
    }
  }
  
  func mediaPickerDidCancel(mediaPicker: MPMediaPickerController) {
    dismissViewControllerAnimated(true, completion: nil)
  }
}

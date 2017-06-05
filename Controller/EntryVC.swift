//
//  EntryVC.swift
//  Writing App
//
//  Created by Sten Golds on 11/25/16.
//  Copyright © 2016 Sten Golds. All rights reserved.
//

import UIKit
import CoreData
import Speech

class EntryVC: UIViewController, UITextViewDelegate {
    
    //properties that connect text view and the text view's bottom constraint in code to storyboard view
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var bottomTVConstraint: NSLayoutConstraint!
    
    //var for label used to display time remaining
    var rightNavLabel: UILabel!
    
    //var for button above keyboard user can press to do text to speech
    var micBarButton: UIBarButtonItem!
    
    //the speech recognizer instance used to translate english speech to text
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))!
    
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    //variable for the entry, if the user has selected an entry to view
    var sentEntry: Entry?
    
    //timer instance, and time affected
    var timer = Timer()
    var time: Int!
    
    //variable used to tell Core Data if the text in text view is placeholder or not, do not save placeholder text
    var save = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set the current view controller to be the delegate of the TextView associated with it in storyboard
        textView.delegate = self
        
        //set up speech to text
        configureMicButton()
        
        //prepare timer and back button views
        navBarPrep()
        
        //update timer label
        initialTimeSetup()
        
        //load Entry data, or initialize new Entry
        sentEntryAndTexViewPrep()
        
        //add buttons for speech to text, and keyboard dismissal, to keyboard
        addDoneAndMicButtonToKB()
        
        //create the timer associated with decrement function (count down by seconds)
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(EntryVC.decreaseTime), userInfo: nil, repeats: true)
        
        //notification for when keyboard appears, used to update TextView size
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardNotification(notification:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        
        //notification for if the user changed the device orientation, needed for proper timer label display
        NotificationCenter.default.addObserver(self, selector: #selector(EntryVC.rotated), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        //automatic placement of text within text view
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    deinit {
        //this view controller no longer needs to observe notifications, as the user has left it, so remove it as an observer
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        //make text display from very top to bottom in TextView
        textView.setContentOffset(CGPoint.zero, animated: false)
    }
    
    /**
     * @name willMove toParentViewController
     * @desc called when back button is pressed
     * @return void
     */
    override func willMove(toParentViewController parent: UIViewController?) {
        //perform original code associated with function before overriding
        super.willMove(toParentViewController: parent)
        
        //if view is leaving (ie back button pressed), continue
        if parent == nil {
            
            //get the entry
            if let entry = sentEntry {
               
                //if there is not date associated with the entry, use current date
                if entry.date == nil {
                    entry.date = Date()
                    entry.dateString = entry.stringForCurrentDate()
                }
                
                //if the text in TextView is not placeholder text, save it to the entry, otherwise save an empty string
                if save {
                    entry.body = textView.text
                } else {
                    entry.body = ""
                }
                
                //update time left on current entry
                entry.timeLeft = Int32(time)
                
                //save the entry object to CoreData
                appDel.saveContext()
            }
            
            //remove the timer label from the navigation bar
            rightNavLabel.removeFromSuperview()
        }
    }
    
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        //call helper method function, letting it know the user is currently editing the TextView
        tvEditingHelper(editing: true)
    }
    
    
    func textViewDidEndEditing(_ textView: UITextView) {
        //call helper method function, letting it know the user is not currently editing the TextView
        tvEditingHelper(editing: false)
    }
    
    /**
     * @name configureMicButton
     * @desc creates microphone button for above keyboard, and requests microphone access
     * @return void
     */
    func configureMicButton() {
        //create microphone button with custom images, set button frame size, attach function to be called when button is pressed
        //then convert button to a BarButtonItem so it may go above the keyboard when the keyboard is displayed
        let micButton = UIButton(type: .custom)
        micButton.setImage(#imageLiteral(resourceName: "Mic Icon"), for: .normal)
        micButton.setImage(#imageLiteral(resourceName: "Mic Icon Highlight"), for: .highlighted)
        micButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        micButton.imageView?.contentMode = .scaleAspectFit
        micButton.addTarget(self, action: #selector(EntryVC.microphonePressed), for: .touchUpInside)
        micBarButton = UIBarButtonItem(customView: micButton)
        
        //initially the button is not enabled, as we do not have mic access
        micBarButton.isEnabled = false
        
        //ask user for mic access
        requestMicAuth()
    }
    
    /**
     * @name requestMicAuth
     * @desc asks user for speech recognizer authorization, sets microphone button to enabled if given, false if not given
     * @return void
     */
    func requestMicAuth() {
        //requests access
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            //default state is not authorized
            var isButtonEnabled = false
            
            //if user authorized use, enable the button for speech to text
            //if user did not authorize use, disable the button
            switch authStatus {
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            //enable or disable mic button based on user input
            self.micBarButton.isEnabled = isButtonEnabled
        }
    }
    
    /**
     * @name initialTimeSetup
     * @desc sets initial countdown clock to user's preference, if user has not set preference, sets to default 20 minutes
     * sets max time to 1000 minutes
     * @return void
     */
    func initialTimeSetup() {
        //gets user preference from defaults, then converts it to seconds for countdown, if user preference is over 1000 minutes, sets countdown to just 1000 minutes
        //if user preference cannot be gotten, sets countdown to 20 minutes
        if let timeGot = UserDefaults.standard.value(forKey: TIME_KEY) as? Int {
            time = min(timeGot * 60, 1000*60)
        } else {
            time = 20 * 60
        }
        
        //update label for displaying time
        updateTimeLabel()
    }
    
    /**
     * @name navBarPrep
     * @desc makes back button black, with no text attached, and initializes, configures, and places the time label in
     * navigation bar
     * @return void
     */
    func navBarPrep() {
        if let navBar = self.navigationController?.navigationBar {
            //set back button to black, and attached title to an empty string
            navBar.tintColor = UIColor.black
            navBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.done, target: nil, action: nil)
            
            //create frame for time label
            let rightFrame = CGRect(x: 0.8 * navBar.frame.width, y: 0, width: 0.3 * navBar.frame.width, height: navBar.frame.height)
            
            //set rightNavLabel to a UILabel with the created frame, set it's default text to the default time of countdown
            //and set the textColor to the green used throughout app
            rightNavLabel = UILabel(frame: rightFrame)
            rightNavLabel.text = "20:00"
            rightNavLabel.textColor = commonMaterialGreen
            
            //add the time label to navigation bar
            navBar.addSubview(rightNavLabel)
        }
    }
    
    /**
     * @name sentEntryAndTexViewPrep
     * @desc adjusts text view and timer based on if an entry was selected. If it is a new entry, initializes the entry object.
     * Gets user font preference, if user has one, capped at 40. Sets TextView attributes.
     * @return void
     */
    func sentEntryAndTexViewPrep() {
        //check if there is an entry to display, if so set TextView body to entry body, timer to the time associated with entry
        // and update the time label. If there is no entry, create one.
        if let entry = sentEntry {
            textView.text = entry.body
            
            time = Int(entry.timeLeft)
            
            updateTimeLabel()
        } else {
            sentEntry = Entry(context: context)
        }
        
        //if user has a font size preference, get it and set TextView font size to preference. Cap at size 40.
        if let fontGot = UserDefaults.standard.value(forKey: FONT_SIZE_KEY) as? Int {
            let fontSize = min(fontGot, 40)
            textView.font = UIFont(name: (textView.font?.fontName)!, size: CGFloat(fontSize))
        }
        
        //add line spacing, color, font, and text to the textView attributedText. Changed to attributed to allow further customization.
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 7
        let attributes = [NSParagraphStyleAttributeName : style, NSForegroundColorAttributeName: blueBlackFont, NSFontAttributeName: textView.font!]
        textView.attributedText = NSMutableAttributedString(string: textView.text, attributes:attributes)
        
        //tell helper method, the text is not currently being edited. Changes style, and possible content body, if it was empty.
        tvEditingHelper(editing: false)
    }
    
    /**
     * @name decreaseTime
     * @desc reduces timer by one second, and updates the label. Stops timer if it reaches 0.
     * @return void
     */
    func decreaseTime() {
        if time > 0 {
            time = time - 1
            
            updateTimeLabel()
        } else {
            timer.invalidate()
        }
    }
    
    /**
     * @name updateTimeLabel
     * @desc updates the time label to show user remaining time in minutes and seconds
     * @return void
     */
    func updateTimeLabel() {
        //convert time to minutes and seconds
        let min = time / 60
        let seconds = time % 60
        
        //checks if there is no remaining time. If time is up, show completed image in time label,
        //else update time label to show current remaining time
        if min == 0 && seconds == 0 {
            rightNavLabel.text = ""
            rightNavLabel.addImage(imageName: "greenCircleCheck.png")
        } else {
            let minString = (min < 10 ? "0\(min)" : "\(min)")
            let secondsString = (seconds < 10 ? "0\(seconds)" : "\(seconds)")
            
            rightNavLabel.text = minString + ":" + secondsString
        }
    }
    
    /**
     * @name addDoneAndMicButtonToKB
     * @desc creates area above keyboard to put done button and mic button
     * @return void
     */
    func addDoneAndMicButtonToKB() {
        
        //create keyboard toolbar, and set size
        let keyboardToolbar = UIToolbar()
        keyboardToolbar.sizeToFit()
        
        //creates spacing for toolbar, and the done button that will dismiss the keyboard
        let flexBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                            target: nil, action: nil)
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done,
                                            target: view, action: #selector(UIView.endEditing(_:)))
        
        
        //makes color of items the green used throughout app, and adds the buttons (mic, flex, done) to the toolbar
        doneBarButton.tintColor = commonMaterialGreen
        keyboardToolbar.items = [micBarButton, flexBarButton, doneBarButton]
        
        //set the toolbar to be part of the keyboard display
        textView.inputAccessoryView = keyboardToolbar
    }
    
    /**
     * @name keyboardNotification
     * @desc adjusts text view display based on whether the keyboard is hidden or not
     * @param NSNotification notification - notication that stores keyboard and user data
     * @return void
     */
    func keyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let duration:TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            
            if (endFrame?.origin.y)! >= UIScreen.main.bounds.size.height {
                self.bottomTVConstraint?.constant = 0.0
            } else {
                self.bottomTVConstraint?.constant = endFrame?.size.height ?? 0.0
                self.bottomTVConstraint?.constant += 18.0
            }
            
            UIView.animate(withDuration: duration,
                           delay: TimeInterval(0),
                           options: [],
                           animations: { self.view.layoutIfNeeded() },
                           completion: nil)
        }
    }

    /**
     * @name rotated
     * @desc if the user has turned device, update the time labels size to reflect new device height and width
     * @return void
     */
    func rotated() {
        if let navBar = self.navigationController?.navigationBar {
            let rightFrame = CGRect(x: 0.8 * navBar.frame.width, y: 0, width: 0.3 * navBar.frame.width, height: navBar.frame.height)
            
            rightNavLabel.frame = rightFrame
        }
    }
    
    /**
     * @name tvEditingHelper
     * @desc adjusts TextView colors based on if there is user inputed text in the TextView or not
     * @param Bool editing - used to tell function if the user is editing the TextView
     * @return void
     */
    func tvEditingHelper(editing: Bool) {
        
        //run block if user is currently editing the TextView
        if editing {
            //checks if text in text view is currently a placeholder, if so clears textview, sets font color to
            //non-placeholder color, and tells app that the text is to be saved to the entry object
            if textView.textColor == UIColor.lightGray {
                textView.text = nil
                textView.textColor = blueBlackFont
                save = true
            }
        } else {
            //checks if there is currently no text in the view
            if textView.text.isEmpty {
                
                //Sets line spacing of paragraphs to 7; makes text color the placeholder color of light gray; adds placeholder text
                let style = NSMutableParagraphStyle()
                style.lineSpacing = 7
                let attributes = [NSParagraphStyleAttributeName : style, NSForegroundColorAttributeName: UIColor.lightGray, NSFontAttributeName: textView.font!]
                textView.attributedText = NSMutableAttributedString(string: "Type Here...", attributes:attributes)
                
                //do not save placeholder text to the entry
                save = false
            }
        }
    }
    
    /**
     * @name microphonePressed
     * @desc function for if the speech to text microphone button is pressed
     * @return void
     */
    func microphonePressed() {
        
        //if speech conversion is running, stop it
        //else begin to record
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            micBarButton.isEnabled = false
        } else {
            record()
        }
    }
    /**
     * @name record
     * @desc record user's speech and convert it to text
     * @return void
     */
    func record() {
        
        //if there is already a recognition task running, cancel it, and deinit
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        //create audio session; set it to record, use as measurement, then activate. Those can throw errors so adjust them
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession property error")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        //get input node
        guard let inputNode = audioEngine.inputNode else {
            fatalError("No input node to audio engine")
        }
        
        //create recognition request
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create recognition request")
        }
        
        //print the non-final results of the recognition
        recognitionRequest.shouldReportPartialResults = true
        
        //string variables to store text before and after the cursor in TextView
        var tvUntilCurs = ""
        var tvAfterCurs = ""
        
        //cursor location
        var cursorIndex: String.Index
        
        //if there is a selected text range, get it (used for getting cursor location)
        if let selectedRange = self.textView.selectedTextRange {
            
            //get cursor location by adding range start, as range start is cursor, to beginning of text
            let cursorPosition = self.textView.offset(from: self.textView.beginningOfDocument, to: selectedRange.start)
            
            //create cursor location as an String.Index value
            cursorIndex = self.textView.text.index(self.textView.text.startIndex, offsetBy: cursorPosition)
            
            //split TextView text by cursor location
            tvUntilCurs = self.textView.text.substring(to: cursorIndex)
            tvAfterCurs = self.textView.text.substring(from: cursorIndex)
            
        }
        
        //begin to recognize speech and convert it to text
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            //variable used to store if this is the final text translation
            var isFinal = false
            
            //result of speech to text
            var resString = ""
            
            //if there is a result, continue adding it to TextView
            if result != nil {
                
                //get highest chance of accuracy string
                resString = (result?.bestTranscription.formattedString)!
                
                //add result of speech to text to cursor position in TextView
                self.textView.text = tvUntilCurs + " " + resString + " " + tvAfterCurs
                
                //get if the result is the final result
                isFinal = (result?.isFinal)!
            }
            
            //if there was an error, or this is the final call, continue to stop the recognition
            if error != nil || isFinal {
                
                //stop audio engine used to record, remove the input node
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                //clear recognition objects
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                //allow user to start a new recognition request by enabling mic button
                self.micBarButton.isEnabled = true
            }
        })
        
        //add audio input to the recognition request
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        //prepare and start the audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("error: audioEngine couldn't start.")
        }
    }
    
    /**
     * @name speechRecognizer
     * @desc displays a button on the keyboard toolbar that allows the user to use speech recognition, if they have given permission
     * @param SFSpeechRecognizer speechRecognizer - The speech recognizer object used for speech recognition
     * @param Bool available - boolean used to tell if speech recognition is permitted
     * @return void
     */
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        
        //called when user changes authorization: if authorized, enable mic button. Else, disable mic button.
        if available {
            micBarButton.isEnabled = true
        } else {
            micBarButton.isEnabled = false
        }
    }
}

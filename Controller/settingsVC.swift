//
//  settingsVC.swift
//  Writing App
//
//  Created by Sten Golds on 1/5/17.
//  Copyright © 2017 Sten Golds. All rights reserved.
//

import UIKit
import CoreData

class settingsVC: UIViewController {

    //properties that connect time text field and font text field in code to storyboard view
    @IBOutlet weak var timeTF: UITextField!
    @IBOutlet weak var fontTF: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //makes back button black, and with no text, only the arrow
        navBarPrep()
        
        //loads users defaults, if they are available, else, loads predeterimined defaults
        defaultsPrep()
    }
    

    // MARK: - Navigation
    
    /**
     * @name willMove toParentViewController
     * @desc called when back button is pressed
     * @return void
     */
    override func willMove(toParentViewController parent: UIViewController?) {
        super.willMove(toParentViewController: parent)
        
        //if view is leaving (ie back button pressed), continue
        if parent == nil {
            
            //update and save user's preferred timer length
            if let time = Int(self.timeTF.text!) {
                UserDefaults.standard.setValue(time, forKey: TIME_KEY)
            }
            
            //update and save user's preferred font size
            if let font = Int(self.fontTF.text!) {
                UserDefaults.standard.setValue(font, forKey: FONT_SIZE_KEY)
            }

        }
    }
    
    
    /**
     * @name touchesBegan
     * @desc overrides touchesBegan function in order to make the keyboard disappear if the user taps outside the keyboard
     * and TextField area
     * @param Set<UITouch> touches - set of touches by the user
     * @param UIEvent event - event associated with the touches
     * @return void
     */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        timeTF.resignFirstResponder()
        fontTF.resignFirstResponder()
    }
    
    /**
     * @name navBarPrep
     * @desc makes navigation bar tint black, and removes text from back button
     * @return void
     */
    func navBarPrep() {
        if let navBar = self.navigationController?.navigationBar {
            navBar.tintColor = UIColor.black
            navBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.done, target: nil, action: nil)
        }
    }
    
    /**
     * @name defaultsPrep
     * @desc gets user preferences, or loads deault preferences
     * @return void
     */
    func defaultsPrep() {
        
        //if user has a timer preference, retrieve and load it, else load default of 20 (minutes)
        if let time = UserDefaults.standard.value(forKey: TIME_KEY) as? Int {
            self.timeTF.text = "\(time)"
        } else {
            self.timeTF.text = "20"
        }
        
        //if user has a font size preference, retrieve and load it, else load default of 15
        if let font = UserDefaults.standard.value(forKey: FONT_SIZE_KEY) as? Int {
            self.fontTF.text = "\(font)"
        } else {
            self.fontTF.text = "15"
        }
    }

}

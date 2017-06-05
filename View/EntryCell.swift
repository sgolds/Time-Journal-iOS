//
//  EntryCell.swift
//  Writing App
//
//  Created by Sten Golds on 11/22/16.
//  Copyright © 2016 Sten Golds. All rights reserved.
//

import UIKit

class EntryCell: UITableViewCell {

    //properties that connect entry cell class to storyboard view
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLeftLabel: UILabel!
    @IBOutlet weak var textPreviewLabel: UILabel!
    @IBOutlet weak var isSelectedView: UIView!

    /**
     * @name awakeFromNib
     * @desc overrides awakeFromNib of UITableViewCell so that the EntryCell is manipulated by the code
     * @return void
     */
    override func awakeFromNib() {
        
        //clear selection style for cell, allows for custom styling
        self.selectionStyle = .none
    }
        
    /**
     * @name configCell
     * @desc configures the EntryCell to conform to the data in the passed in Entry
     * @param Entry
     * @return void
     */
    func configCell(entry: Entry) {
        dateLabel.text = entry.dateString
        
        if entry.timeLeft != 0 {
            entry.timeLeft > 60 ? (timeLeftLabel.text = "\(entry.timeLeft/60) min left") : (timeLeftLabel.text = "\(entry.timeLeft) sec left")
            timeLeftLabel.font = UIFont(name: timeLeftLabel.font.fontName, size: 14)
            timeLeftLabel.textColor = UIColor(red: 120.0/255.0, green: 144.0/255.0, blue: 156.0/255.0, alpha: 1.0)
        } else {
            timeLeftLabel.text = "✓"
            timeLeftLabel.font = UIFont(name: timeLeftLabel.font.fontName, size: 20)
            timeLeftLabel.textColor = commonMaterialGreen
        }
        
        textPreviewLabel.text = entry.body
    }
}



//
//  MaterialRoundButton.swift
//  Writing App
//
//  Created by Sten Golds on 11/23/16.
//  Copyright © 2016 Sten Golds. All rights reserved.
//

import UIKit

class MaterialRoundButton: UIButton {

    /**
     * @name isHighlighted
     * @desc overrides isHighlighted Bool of UIButton so custom background color is shown when highlighted
     */
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                backgroundColor = highlightGreen
                
            } else {
                backgroundColor = commonMaterialGreen
            }
        }
    }
    
    /**
     * @name awakeFromNib
     * @desc overrides awakeFromNib of UIButton so that the loginScreenButton is manipulated by the code
     * @return void
     */
    override func awakeFromNib() {
        
        //curves the corners of the button into a circle
        layer.cornerRadius = self.frame.width / 2
        
        
        //add shadow to button
        layer.shadowColor = UIColor(red: 117.0/255.0, green: 117.0/255.0, blue: 117.0/255.0, alpha: 1.0).cgColor
        layer.shadowOpacity = 0.75
        layer.shadowRadius = 1.5
        layer.shadowOffset = CGSize(width: 0.0, height: 2.5)
    }
    
    /**
     * @name updateConstraints
     * @desc overrides updateConstraints to set the corner radius based upon the changing frame.width
     * @return void
     */
    override func updateConstraints() {
        super.updateConstraints()
        
        //curves the corners of the button into a circle
        layer.cornerRadius = self.frame.width / 2
    }

}

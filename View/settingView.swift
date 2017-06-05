//
//  settingView.swift
//  Writing App
//
//  Created by Sten Golds on 1/5/17.
//  Copyright © 2017 Sten Golds. All rights reserved.
//

import UIKit


class settingView: UIView {
    
    /**
     * @name awakeFromNib
     * @desc overrides awakeFromNib of UIButton so that the loginScreenButton is manipulated by the code
     * @return void
     */
    override func awakeFromNib() {
        
        //set thin border to outline background of text input area in settings view controller
        self.layer.borderColor = UIColor(red: 189.0/255.0, green: 189.0/255.0, blue: 189.0/255.0, alpha: 0.7).cgColor
        self.layer.borderWidth = 0.5
    }
    
}

//
//  labelExt.swift
//  Writing App
//
//  Created by Sten Golds on 1/4/17.
//  Copyright © 2017 Sten Golds. All rights reserved.
//

import Foundation
import UIKit

extension UILabel
{
    /**
     * @name addImage
     * @desc adds an image to a UILabel, with accounting for label size and appropriate image size
     * @param String imageName - name of image file
     * @return void
     */
    func addImage(imageName: String)
    {
        //setup NSTextAttachment with desired image and a fixed size
        let attachment:NSTextAttachment = NSTextAttachment()
        attachment.image = UIImage(named: imageName)
        attachment.bounds = CGRect(x: self.frame.width/4, y: 0, width: self.frame.height/2, height: self.frame.height/2)
        
        //create attributed string that has labels text, but with the addition of the image at the end
        let attachmentString:NSAttributedString = NSAttributedString(attachment: attachment)
        let myString:NSMutableAttributedString = NSMutableAttributedString(string: self.text!)
        myString.append(attachmentString)
        
        //set label's text to attributed string with image
        self.attributedText = myString
    }
}

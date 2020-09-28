//
//  ARPenPluginTableViewCell.swift
//  ARPen
//
//  Created by Philipp Wacker on 25.09.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import UIKit

class ARPenPluginTableViewCell: UITableViewCell {

    @IBOutlet weak var cellImageView: UIImageView!
    @IBOutlet weak var cellLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func updateCellWithImage(_ theImage : UIImage?, andText theText : String) {
        if let image = theImage {
            self.cellImageView.image = image
        }
        self.cellLabel.text = theText
    }
    
}

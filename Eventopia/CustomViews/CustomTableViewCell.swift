//
//  CustomTableViewCell.swift
//  Eventopia
//
//  Created by Chadia Kaneza on 4/28/23.
//

import UIKit

class CustomTableViewCell: UITableViewCell {
    

    @IBOutlet weak var favoriteBtn: UIButton!
    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var eventTitleLbl: UILabel!
    @IBOutlet weak var eventDateLbl: UILabel!
    @IBOutlet weak var eventAddressLbl: UILabel!
    
   
    
    
    var favBtnTapped: ((UIButton) -> Void)?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func favoriteBtnTapped(_ sender: UIButton) {
        favBtnTapped?(sender)
    }
    

}

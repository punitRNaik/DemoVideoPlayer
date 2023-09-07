//
//  PageInfoTableViewCell.swift
//  VideoPlayerPOC
//
//  Created by PunitNaik on 05/09/23.
//

import UIKit

protocol PageInfoTableViewCellDelegate: AnyObject {
    func didTapChange(model: PageData?)
}

class PageInfoTableViewCell: UITableViewCell {
    @IBOutlet weak var pageIndexLabel: UILabel!
    @IBOutlet weak var startTimeTF: UITextField!
    @IBOutlet weak var endTimeTF: UITextField!
    weak var delegate: PageInfoTableViewCellDelegate?
    
    var cellModel: PageData?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configureCell(model: PageData) {
        self.cellModel = model
        pageIndexLabel.text = "page\(model.pageIndex)"
        startTimeTF.text = model.startTime
        endTimeTF.text = model.endTime
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    
    @IBAction func changeTapped(_ sender: Any) {
        cellModel?.startTime = startTimeTF.text ?? cellModel?.startTime ?? ""
        cellModel?.endTime = endTimeTF.text ?? cellModel?.endTime ?? ""
        delegate?.didTapChange(model: cellModel)
    }
    
}

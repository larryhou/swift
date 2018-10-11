//
//  ReviewController.swift
//  Hardware
//
//  Created by larryhou on 11/07/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import Foundation
import UIKit

class ReviewController: UIViewController {
    @IBOutlet weak var ib_title: UILabel!
    @IBOutlet weak var ib_content: UILabel!

    var data: ItemInfo?

    override func viewDidLoad() {
        super.viewDidLoad()
        if let data = self.data {
            ib_title.text = data.name
            ib_title.sizeToFit()

            ib_content.text = data.value
            ib_content.sizeToFit()
        }
    }
}

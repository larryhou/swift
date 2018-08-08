//
//  PlayerTableViewController.swift
//  TexasHoldem
//
//  Created by larryhou on 12/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation
import UIKit

class PlayerTableViewController: UITableViewController {
    var model: ViewModel!

    // MARK: segue
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "pattern" {
            let dst = segue.destinationViewController as! PatternTableViewController
            dst.model = model

            let indexPath = tableView.indexPathForSelectedRow!
            dst.id = indexPath.row
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model == nil ? 0 : model.stats.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerCell")!
        cell.textLabel?.text = String(format: "PLAYER #%02d", (indexPath as NSIndexPath).row + 1)
        return cell
    }

    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let alert = PatternStatsPrompt(title: "牌型分布#\((indexPath as NSIndexPath).row + 1)", message: nil, preferredStyle: .actionSheet)
        alert.setPromptSheet(model.stats[(indexPath as NSIndexPath).row]!)
        present(alert, animated: true, completion: nil)
    }
}

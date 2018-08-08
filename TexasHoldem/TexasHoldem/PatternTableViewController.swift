//
//  PatternTableViewController.swift
//  TexasHoldem
//
//  Created by larryhou on 12/3/2016.
//  Copyright © 2016 larryhou. All rights reserved.
//

import Foundation
import UIKit

class PatternTableViewController: UITableViewController, UISearchBarDelegate {
    private let background_queue = DispatchQueue(label: "TexasHoldem.background.search", attributes: DispatchQueueAttributes.concurrent)

    @IBOutlet weak var search: UISearchBar!
    var model: ViewModel!
    var id: Int = 0

    var history: [UniqueRound]!

    override func viewDidLoad() {
        super.viewDidLoad()
        history = model.data
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return history.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath as NSIndexPath).row < history.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PatternCell") as! PatternTableViewCell

            let data = history[(indexPath as NSIndexPath).row].list[id]
            cell.renderView(data)
            return cell
        } else {
            let identifier = "LoadingCell"

            let cell: UITableViewCell
            if let reuseCell = tableView.dequeueReusableCell(withIdentifier: identifier) {
                cell = reuseCell
            } else {
                cell = UITableViewCell(style: .default, reuseIdentifier: identifier)
                cell.textLabel?.font = UIFont(name: "Menlo", size: 18)
                cell.textLabel?.text = "..."
            }

            return cell
        }
    }

    @IBAction func showPatternStats(_ sender: UIBarButtonItem) {
        let alert = PatternStatsPrompt(title: "牌型分布", message: nil, preferredStyle: .actionSheet)
        alert.setPromptSheet(model.stats[id]!)

        present(alert, animated: true, completion: nil)
    }

    // MARK: search
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchByInput(searchText)
    }

    func searchByInput(_ searchText: String?) {
        if let text = searchText {
            var integer = NSString(string: text).integerValue
            integer = min(max(0, integer), 255)

            if let pattern = HandPattern(rawValue: UInt8(integer)) {
                background_queue.async {
                    self.history = []
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }

                    for i in 0..<self.model.data.count {
                        let hand = self.model.data[i].list[self.id]
                        if hand.data.0 == pattern.rawValue {
                            self.history.append(self.model.data[i])

                            if self.history.count < 10 {
                                DispatchQueue.main.async {
                                    self.tableView.reloadData()
                                }
                            }
                        }
                    }

                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            } else {
                history = model.data
            }
        } else {
            history = model.data
        }

        tableView.reloadData()
    }
}

//
//  HistoryController.swift
//  iap
//
//  Created by larryhou on 2018/5/23.
//  Copyright © 2018 larryhou. All rights reserved.
//

import Foundation
import UIKit
import StoreKit

class HistoryController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().restoreCompletedTransactions()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        SKPaymentQueue.default().remove(self)
    }
}

extension HistoryController: SKPaymentTransactionObserver {
    // MARK: Handling Transactions
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            if transaction.error == nil {
                if transaction.transactionState == .restored, let restore = transaction.original {
                    print(restore.payment.productIdentifier, restore.transactionIdentifier ?? "nil", restore.transactionDate ?? "nil")
                } else {
                    print(transaction.payment.productIdentifier, transaction.transactionState)
                }

                switch transaction.transactionState {
                    case .failed, .restored:
                        SKPaymentQueue.default().finishTransaction(transaction)
                    default:break
                }
            }
        }
    }

    func alertCompletion(with transaction: SKPaymentTransaction) {
        let productID = transaction.payment.productIdentifier
        let title = transaction.transactionState == .failed ? "failure" : "success"
        let message: String?
        if let transactionID = transaction.transactionIdentifier {
            message = String(format: "%@\n%@\n%@", productID, transactionID, transaction.transactionDate?.description ?? "")
        } else {
            message = transaction.error?.localizedDescription
        }

        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    // MARK: Handling Restored Transactions
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        print(error)
    }

    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        print("restore complete")
    }
}

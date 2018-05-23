//
//  BuyProductController.swift
//  iap
//
//  Created by larryhou on 2018/5/23.
//  Copyright © 2018 larryhou. All rights reserved.
//

import Foundation
import UIKit
import StoreKit

extension SKPaymentTransactionState:CustomStringConvertible
{
    public var description:String
    {
        switch self
        {
            case .purchased:return ".purchased"
            case .purchasing:return ".purchasing"
            case .failed:return ".failed"
            case .restored:return ".restored"
            case .deferred:return ".deferred"
        }
    }
}

class BuyProductController:UIViewController
{
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var priceView:UILabel!
    @IBOutlet weak var nameView:UILabel!
    
    var product:SKProduct!
    var formatter:NumberFormatter!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        nameView.text = product.localizedTitle
        priceView.text = formatter.string(from: NSNumber(value: product.price.doubleValue))
    }
    
    @IBAction func buy(_ sender:UIButton)
    {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().add(payment)
    }
    
    @IBAction func cancel(_ sender:UIButton)
    {
        self.dismiss(animated: true, completion: nil)
    }
}

extension BuyProductController:SKPaymentTransactionObserver
{
    //MARK: Handling Transactions
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction])
    {
        for transaction in transactions
        {
            if let error = transaction.error
            {
                print(transaction.payment.productIdentifier, transaction.transactionState, error)
            }
            else
            {
                if transaction.transactionState == .purchased
                {
                    print(transaction.payment.productIdentifier, transaction.transactionIdentifier ?? "nil", transaction.transactionDate ?? "nil")
                    self.alertCompletion(with: transaction)
                }
                else
                {
                    print(transaction.payment.productIdentifier, transaction.transactionState)
                }
                
                switch transaction.transactionState
                {
                    case .failed,.purchased:
                        SKPaymentQueue.default().finishTransaction(transaction)
                        SKPaymentQueue.default().remove(self)
                    default:break
                }
            }
        }
    }
    
    func alertCompletion(with transaction:SKPaymentTransaction)
    {
        let productID = transaction.payment.productIdentifier
        let title = transaction.transactionState == .failed ? "failure" : "success"
        let message:String?
        if let transactionID = transaction.transactionIdentifier
        {
            message = String(format: "%@\n%@\n%@", productID, transactionID, transaction.transactionDate?.description ?? "")
        }
        else
        {
            message = transaction.error?.localizedDescription
        }
        
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions:
        [SKPaymentTransaction])
    {
        print(transactions.count)
    }
    
    //MARK: Handling Restored Transactions
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error)
    {
        
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue)
    {
        
    }
    
    //MARK: Handling Download Actions
    func paymentQueue(_ queue: SKPaymentQueue, updatedDownloads downloads: [SKDownload])
    {
        
    }
    
    //MARK: Handling Purchases
    func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool
    {
        return true
    }
    
}

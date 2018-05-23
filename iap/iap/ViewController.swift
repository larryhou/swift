//
//  ViewController.swift
//  iap
//
//  Created by larryhou on 2018/5/21.
//  Copyright © 2018 larryhou. All rights reserved.
//

import UIKit
import StoreKit

class ProductItemCell:UITableViewCell
{
    @IBOutlet weak var itemName: UILabel!
    @IBOutlet weak var itemPrice: UILabel!
}

class ViewController: UITableViewController, SKProductsRequestDelegate
{
    var productIdentifiers:[String] = {
       return ["com.larryhou.samples.iap.coupons_10", "com.larryhou.samples.iap.coupons_100", "com.larryhou.samples.iap.coupons_500", "com.larryhou.samples.iap.coupons_1000", "com.larryhou.samples.iap.month_member", "com.larryhou.samples.iap.storm_blade"]
    }()
    
    var storeProducts:[SKProduct]?
    var formatter:NumberFormatter!
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse)
    {
        storeProducts = response.products
        tableView.reloadData()
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let request = SKProductsRequest(productIdentifiers:Set<String>(productIdentifiers))
        request.delegate = self
        request.start()
    }
    
    //MARK: segue
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool
    {
        guard tableView.indexPathForSelectedRow != nil,
        storeProducts != nil else {return false}
        return true
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        guard segue.identifier == "buy",
            let indexPath = tableView.indexPathForSelectedRow,
            let products = storeProducts else {return}
        
        tableView.deselectRow(at: indexPath, animated: false)
        
        let product = products[indexPath.row]
        if let buyController = segue.destination as? BuyProductController
        {
            buyController.product = product
            buyController.formatter = formatter
        }
    }
    
    //MARK: table view
    
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 80
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if let products = storeProducts
        {
            return products.count
        }
        
        return productIdentifiers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let name:String?
        let price:String?
        if let products = storeProducts
        {
            let data = products[indexPath.row]
            
            if formatter == nil
            {
                formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.locale = data.priceLocale
                formatter.usesGroupingSeparator = true
            }
            
            name = data.localizedTitle
            price = formatter.string(from: NSNumber(value: data.price.doubleValue))
        }
        else
        {
            name = productIdentifiers[indexPath.row]
            price = "--"
        }
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "ProductItemCell") as? ProductItemCell
        {
            cell.itemName.text = name
            cell.itemPrice.text = price
            return cell
        }
        
        return UITableViewCell()
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


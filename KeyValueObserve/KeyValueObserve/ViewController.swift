//
//  ViewController.swift
//  KeyValueObserve
//
//  Created by larryhou on 3/16/15.
//  Copyright (c) 2015 larryhou. All rights reserved.
//

import UIKit
import Foundation

extension UInt32
{
	var double:Double
	{
		return Double(self)
	}
}

class ViewController: UIViewController
{
	class Person:NSObject
	{
		var account:BankAccount?
		var name:String
		
		init(name:String)
		{
			self.name = name
		}
	}
	
	class BankAccount:NSObject
	{
		dynamic var balance:Double
		unowned let owner:Person
		
		init(owner:Person, balance:Double)
		{
			self.owner = owner
			self.balance = balance
		}
	}

	@IBOutlet weak var label: UILabel!
	private var person:Person!
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		person = Person(name: "larryhou")
		person.account = BankAccount(owner: person, balance: 100)
		
		person.account?.addObserver(self, forKeyPath: "balance", options: NSKeyValueObservingOptions.New, context: nil)
		
		var gesture = UITapGestureRecognizer()
		gesture.addTarget(self, action: "updateAccount")
		self.view.addGestureRecognizer(gesture)
		
		person.account?.balance = arc4random_uniform(100).double
	}
	
	func updateAccount()
	{
		person.account?.balance += arc4random_uniform(200).double
	}
	
	override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>)
	{
		label.text = NSString(format: "%.0f", change[NSKeyValueChangeNewKey]! as Double)
	}

	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
	}
}


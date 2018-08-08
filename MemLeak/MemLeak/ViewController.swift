//
//  ViewController.swift
//  MemLeak
//
//  Created by doudou on 10/3/14.
//  Copyright (c) 2014 larryhou. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

	class Client {
		var name: String
		var account: Account!

		init(name: String) {
			self.name = name
			self.account = Account(client: self)
		}

		deinit {
			println("Client::deinit")
		}
	}

	class Account {
		var client: Client
		var balance: Int

		init(client: Client) {
			self.client = client
			self.balance = 0
		}

		deinit {
			println("Account::deinit")
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		var client: Client! = Client(name: "larryhou")
		client = nil
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

}

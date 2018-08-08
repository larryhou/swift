//
//  TrackViewController.swift
//  LocateMe
//
//  Created by doudou on 8/17/14.
//  Copyright (c) 2014 larryhou. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

class TrackViewController: UITableViewController, SetupSettingReceiver, CLLocationManagerDelegate {
	enum TrackStatus: String {
		case Tracking = "Tracking"
		case Acquired = "Acquired Location"
		case Error = "Error"
	}

	enum SectionType: Int {
		case TrackStatus
		case Property
		case Measurements
	}

	enum CellIdentifier: String {
		case Status = "StatusCell"
		case Measurement = "MeasurementCell"
		case Property = "PropertyCell"
	}

	private var measurements: [CLLocation]!
	private var location: CLLocation!
	private var status: TrackStatus!

	private var dateFormatter: NSDateFormatter!

	private var locationManager: CLLocationManager!

    private var setting: LocateSettingInfo!

    func setupSetting(setting: LocateSettingInfo) {
        self.setting = setting
    }

	override func viewDidLoad() {
		measurements = []
		locationManager = CLLocationManager()

		dateFormatter = NSDateFormatter()
		dateFormatter.dateFormat = localizeString("DateFormat")
	}

	override func viewWillDisappear(animated: Bool) {
		stopTrackLocation()
	}

    override func viewWillAppear(animated: Bool) {
        println(setting)
		startTrackLocation()
    }

	@IBAction func refresh(sender: UIBarButtonItem) {
		startTrackLocation()
	}

	// MARK: 定位相关
	func locationManager(manager: CLLocationManager!, didUpdateToLocation newLocation: CLLocation!, fromLocation oldLocation: CLLocation!) {
		measurements.insert(newLocation, atIndex: 0)
		location = newLocation

		if location.horizontalAccuracy <= setting.accuracy {
			status = .Acquired
			navigationItem.rightBarButtonItem.enabled = true

			stopTrackLocation()
		}

		tableView.reloadData()
	}

	func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
		status = .Error
		navigationItem.rightBarButtonItem.enabled = true

		tableView.reloadData()
	}

	func startTrackLocation() {
		status = .Tracking
		navigationItem.rightBarButtonItem.enabled = false

		tableView.reloadData()

		locationManager.delegate = self
		locationManager.desiredAccuracy = setting.accuracy
		locationManager.distanceFilter = CLLocationDistance(setting.sliderValue)

		if CLLocationManager.authorizationStatus() != .AuthorizedWhenInUse {
			locationManager.requestWhenInUseAuthorization()
		}

		locationManager.startUpdatingLocation()
	}

	func stopTrackLocation() {
		locationManager.stopUpdatingLocation()
		locationManager.delegate = nil
	}

	// MARK: 列表相关
	override func numberOfSectionsInTableView(tableView: UITableView!) -> Int {
		return 3
	}

	override func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
		switch SectionType.fromRaw(indexPath.section)! {
			case .TrackStatus:return 44.0
			default:return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
		}
	}

	override func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
		switch SectionType.fromRaw(section)! {
			case .TrackStatus:return 1
			case .Property:return 4
			case .Measurements:return measurements.count
		}
	}

	override func tableView(tableView: UITableView!, titleForHeaderInSection section: Int) -> String! {
		switch SectionType.fromRaw(section)! {
			case .TrackStatus:return localizeString("Status")
			case .Property:return localizeString("RTStats")
			case .Measurements:return localizeString("All Measurements")
		}
	}

	override func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
		switch SectionType.fromRaw(indexPath.section)! {
			case .TrackStatus:
				var cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier.Status.toRaw()) as TrackStatusTableViewCell
				cell.label.text = localizeString(status.toRaw())
				if status == .Tracking {
					if !cell.indicator.isAnimating() {
						cell.indicator.startAnimating()
					}
				} else {
					if cell.indicator.isAnimating() {
						cell.indicator.stopAnimating()
					}
				}
				return cell

			case .Property:
				var cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier.Property.toRaw()) as UITableViewCell
				switch indexPath.row {
					case 0:
						cell.textLabel.text = localizeString("accuracy")
						cell.detailTextLabel.text = location != nil ? location.getHorizontalAccuracyString() : "-"
					case 1:
						cell.textLabel.text = localizeString("course")
						cell.detailTextLabel.text = location != nil ? location.getCourseString() : "-"
					case 2:
						cell.textLabel.text = localizeString("speed")
						cell.detailTextLabel.text = location != nil ? location.getSpeedString() : "-"
					case 3: fallthrough default:
						cell.textLabel.text = localizeString("time")
						cell.detailTextLabel.text = location != nil ? dateFormatter.stringFromDate(location.timestamp) : "-"
				}

				return cell

			case .Measurements:
				var location: CLLocation = measurements[indexPath.row]
				var cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier.Measurement.toRaw()) as UITableViewCell
				cell.textLabel.text = location.getCoordinateString()
				cell.detailTextLabel.text = dateFormatter.stringFromDate(location.timestamp)
				return cell
		}
	}

	// MARK: 数据透传
	override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
		if segue.identifier == "LocationDetailSegue" {
			var indexPath = tableView.indexPathForCell(sender as UITableViewCell)

			var destinationCtrl = segue.destinationViewController as LocationDetailViewController
			destinationCtrl.location = measurements[indexPath.row]
		}
	}
}

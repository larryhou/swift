//
//  ViewController.swift
//  MotionTracker
//
//  Created by larryhou on 13/8/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//

import UIKit
import CoreMotion

extension Double {
    var radian: Double { return self * M_PI / 180 }
    var angle: Double { return self * 180 / M_PI }
}

extension Int {
    var double: Double { return Double(self) }
}

class MotionValue {
    var value: Double
    let name: String, format: String

    init(name: String, value: Double, format: String) {
        self.name = name
        self.value = value
        self.format = format
    }
}

struct UpdateState {
    var timestamp: NSTimeInterval
    var recordCount = 0, sum = 0.0, average = 0.0
    var count = 0, fps = 0

    init(timestamp: NSTimeInterval) {
        self.timestamp = timestamp
    }
}

enum TableSection: Int {
    case Gyroscrope, OptGyroscope
    case Magnetometer, OptMagnetometer
    case Accelerometer
    case UserAccelerometer
    case Gravity
    case AttitudeEuler
    case AttitudeQuaternion

    static var count: Int { return TableSection.AttitudeQuaternion.rawValue + 1 }
}

class NavigationController: UINavigationController {
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return [UIInterfaceOrientationMask.Portrait, UIInterfaceOrientationMask.PortraitUpsideDown]
    }
}

class ViewController: UITableViewController {
    private var motionManager: CMMotionManager!
    private var model: [Int: [MotionValue]]!
    private var state: UpdateState!

    private var timestamp: NSTimeInterval = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        model = [:]
        state = UpdateState(timestamp: 0)

        motionManager = CMMotionManager()
        print(motionManager.gyroAvailable)
        print(motionManager.magnetometerAvailable)
        print(motionManager.deviceMotionAvailable)
        print(motionManager.accelerometerAvailable)

        startGyroUpdate()
        startMagnetometerUpdate()
        startAccelerometerUpdate()
        startDeviceMotionUpdate()

        NSTimer.scheduledTimerWithTimeInterval(0.001, target: self, selector: "scheduledTimerUpdate:", userInfo: nil, repeats: true)
    }

    func scheduledTimerUpdate(timer: NSTimer) {
        if timer.fireDate.timeIntervalSinceReferenceDate - state.timestamp >= 1.0 {
            state.timestamp = timer.fireDate.timeIntervalSinceReferenceDate
            state.fps = state.count
            state.count = 0

            state.sum += state.fps.double
            state.average = state.sum / (++state.recordCount).double

            print(String(format: "fps:%d, average:%.2f", state.fps, state.average))
        }

        if timer.fireDate.timeIntervalSinceReferenceDate - timestamp > 1.0 / 10 {
            timestamp = timer.fireDate.timeIntervalSinceReferenceDate
            tableView.reloadData()
        }
    }

    func startGyroUpdate() {
        motionManager.gyroUpdateInterval = 1/50
        motionManager.startGyroUpdatesToQueue(NSOperationQueue.mainQueue()) { (data: CMGyroData?, error: NSError?) -> Void in
            if error == nil {
//                self.state.count++

                self.updateGyroscope(data!.rotationRate, section: TableSection.Gyroscrope.rawValue)
            }
        }
    }

    func updateGyroscope(rate: CMRotationRate, section: Int) {
        let format = "%18.14f°/s"

        if model[section] == nil {
            var list = [MotionValue]()
            list.append(MotionValue(name: "X", value: rate.x.angle, format: format))
            list.append(MotionValue(name: "Y", value: rate.y.angle, format: format))
            list.append(MotionValue(name: "Z", value: rate.z.angle, format: format))
            model.updateValue(list, forKey: section)
        } else {
            let list = model[section]!
            list[0].value = rate.x
            list[1].value = rate.y
            list[2].value = rate.z
        }
    }

    func startMagnetometerUpdate() {
        motionManager.startMagnetometerUpdatesToQueue(NSOperationQueue.mainQueue()) { (data: CMMagnetometerData?, error: NSError?) -> Void in
            if error == nil {
//                self.state.count++

                self.updateMagnetometer(data!.magneticField, section: TableSection.Magnetometer.rawValue)
            }
        }
    }

    func updateMagnetometer(field: CMMagneticField, section: Int) {
        let format = "%18.12fμT"

        if model[section] == nil {
            var list = [MotionValue]()
            list.append(MotionValue(name: "X", value: field.x, format: format))
            list.append(MotionValue(name: "Y", value: field.y, format: format))
            list.append(MotionValue(name: "Z", value: field.z, format: format))
            model.updateValue(list, forKey: section)
        } else {
            let list = model[section]!
            list[0].value = field.x
            list[1].value = field.y
            list[2].value = field.z
        }
    }

    func startAccelerometerUpdate() {
        motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.mainQueue()) { (data: CMAccelerometerData?, error: NSError?) -> Void in
            if error == nil {
                self.state.count++
                self.updateAcceleration(data!.acceleration, section: TableSection.Accelerometer.rawValue)
            }
        }
    }

    func updateAcceleration(acceleration: CMAcceleration, section: Int) {
        let format = "%10.6f × 9.81m/s²"

        if model[section] == nil {
            var list = [MotionValue]()
            list.append(MotionValue(name: "X", value: acceleration.x, format: format))
            list.append(MotionValue(name: "Y", value: acceleration.y, format: format))
            list.append(MotionValue(name: "Z", value: acceleration.z, format: format))
            model.updateValue(list, forKey: section)
        } else {
            let list = model[section]!
            list[0].value = acceleration.x
            list[1].value = acceleration.y
            list[2].value = acceleration.z
        }
    }

    func startDeviceMotionUpdate() {
        motionManager.startDeviceMotionUpdatesUsingReferenceFrame(CMAttitudeReferenceFrame.XTrueNorthZVertical, toQueue: NSOperationQueue.mainQueue()) { (data: CMDeviceMotion?, error: NSError?) -> Void in
            if error == nil {
//                self.state.count++
                self.updateGyroscope(data!.rotationRate, section: TableSection.OptGyroscope.rawValue)
                self.updateMagnetometer(data!.magneticField.field, section: TableSection.OptMagnetometer.rawValue)
                self.updateAcceleration(data!.userAcceleration, section: TableSection.UserAccelerometer.rawValue)
                self.updateAcceleration(data!.gravity, section: TableSection.Gravity.rawValue)

                let attitude: CMAttitude = data!.attitude

                let quaternion = self.convertQuaternionToEuler(attitude.quaternion)
                self.updateAttitude(quaternion, section: TableSection.AttitudeQuaternion.rawValue)
                self.updateAttitude((attitude.pitch, attitude.roll, attitude.yaw), section: TableSection.AttitudeEuler.rawValue)
            }
        }
    }

    func updateAttitude(attitude:(pitch: Double, roll: Double, yaw: Double), section: Int) {
        let format = "%18.13f°"

        if model[section] == nil {
            var list = [MotionValue]()
            list.append(MotionValue(name: "Pitch", value: attitude.pitch.angle, format: format))
            list.append(MotionValue(name: "Roll", value: attitude.roll.angle, format: format))
            list.append(MotionValue(name: "Yaw", value: attitude.yaw.angle, format: format))
            model.updateValue(list, forKey: section)
        } else {
            let list = model[section]!
            list[0].value = attitude.pitch.angle
            list[1].value = attitude.roll.angle
            list[2].value = attitude.yaw.angle
        }
    }

    func convertQuaternionToEuler(quat: CMQuaternion) -> (pitch: Double, roll: Double, yaw: Double) {
        let x = atan2(2 * (quat.w * quat.x + quat.y * quat.z), 1 - 2 * (quat.x * quat.x + quat.y * quat.y))
        let y =  asin(2 * (quat.w * quat.y - quat.z * quat.x))
        let z = atan2(2 * (quat.w * quat.z + quat.x * quat.y), 1 - 2 * (quat.y * quat.y + quat.z * quat.z))
        return (x, y, z)
    }

    // MARK: table view
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return TableSection.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return model[section] == nil ? 0 : model[section]!.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let data = model[indexPath.section]![indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier("MotionValueCell")!
        cell.textLabel?.text = data.name + ":"
        cell.detailTextLabel?.text = String(format: data.format, data.value)
        return cell
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
            case TableSection.Gyroscrope.rawValue:return "Gyroscope"
            case TableSection.OptGyroscope.rawValue:return "Gyroscope Without Bias"
            case TableSection.Magnetometer.rawValue:return "Magnetometer"
            case TableSection.OptMagnetometer.rawValue:return "Magnetometer Without Bias"
            case TableSection.Accelerometer.rawValue:return "Acceleration"
            case TableSection.UserAccelerometer.rawValue:return "User Acceleration"
            case TableSection.AttitudeEuler.rawValue:return "Attitude Euler Angles"
            case TableSection.AttitudeQuaternion.rawValue:return "Attitude Quaternion Angles"
            case TableSection.Gravity.rawValue:return "Gravity"
            default:return "Unknown"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

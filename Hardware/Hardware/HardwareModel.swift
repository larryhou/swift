//
//  HardwareModel.swift
//  Hardware
//
//  Created by larryhou on 10/7/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import Foundation
import CoreTelephony
import AdSupport
import UIKit

enum CategoryType:Int
{
    case telephony = 0, process, device, screen
}

struct ItemInfo
{
    let name, value:String
}

class HardwareModel
{
    static private(set) var shared = HardwareModel()
    
    private var data:[CategoryType:[ItemInfo]] = [:]
    init()
    {
        
    }
    
    func get(reload:Bool = false)->[CategoryType:[ItemInfo]]
    {
        if !reload && self.data.count > 0
        {
            return self.data
        }
        
        var result:[CategoryType:[ItemInfo]] = [:]
        let categories:[CategoryType] = [.telephony, .process, .device, .screen]
        for cate in categories
        {
            result[cate] = get(category: cate, reload: reload)
        }
        
        return result
    }
    
    @discardableResult
    func get(category:CategoryType, reload:Bool = false)->[ItemInfo]
    {
        if !reload, let data = self.data[category]
        {
            return data
        }
        
        let data:[ItemInfo]
        switch category
        {
            case .telephony:
                data = getTelephony()
            case .process:
                data = getProcess()
            case .device:
                data = getDevice()
            case .screen:
                data = getScreen()
        }
        
        self.data[category] = data
        return data
    }
    
    private func getScreen()->[ItemInfo]
    {
        var result:[ItemInfo] = []
        let info = UIScreen.main
        result.append(ItemInfo(name: "width", value: "\(info.bounds.width)"))
        result.append(ItemInfo(name: "height", value: "\(info.bounds.height)"))
        result.append(ItemInfo(name: "nativeScale", value: "\(info.nativeScale)"))
        result.append(ItemInfo(name: "scale", value: "\(info.scale)"))
        result.append(ItemInfo(name: "brightness", value: String(format: "%.4f", info.brightness)))
        result.append(ItemInfo(name: "softwareDimming", value: "\(info.wantsSoftwareDimming)"))
        return result
    }
    
    private func getDevice()->[ItemInfo]
    {
        var result:[ItemInfo] = []
        let info = UIDevice.current
        result.append(ItemInfo(name: "name", value: info.name))
        result.append(ItemInfo(name: "systemName", value: info.systemName))
        result.append(ItemInfo(name: "systemVersion", value: info.systemVersion))
        result.append(ItemInfo(name: "model", value: info.model))
        result.append(ItemInfo(name: "localizedModel", value: info.localizedModel))
        result.append(ItemInfo(name: "idiom", value: format(of: info.userInterfaceIdiom)))
        if let uuid = info.identifierForVendor
        {
            result.append(ItemInfo(name: "IDFV", value: uuid.description))
        }
        result.append(ItemInfo(name: "IDFA", value: ASIdentifierManager.shared().advertisingIdentifier.description))
        info.isBatteryMonitoringEnabled = true
        result.append(ItemInfo(name: "batteryLevel", value: String(format: "%.4f", info.batteryLevel)))
        result.append(ItemInfo(name: "batterState", value: format(of: info.batteryState)))
        info.isProximityMonitoringEnabled = true
        result.append(ItemInfo(name: "proximityState", value: "\(info.proximityState)"))
        return result
    }
    
    private func getProcess()->[ItemInfo]
    {
        var result:[ItemInfo] = []
        let info = ProcessInfo.processInfo
        result.append(ItemInfo(name: "name", value: info.processName))
        result.append(ItemInfo(name: "guid", value: info.globallyUniqueString))
        result.append(ItemInfo(name: "id", value: "\(info.processIdentifier)"))
        result.append(ItemInfo(name: "hostName", value: info.hostName))
        result.append(ItemInfo(name: "osVersion", value: info.operatingSystemVersionString))
        result.append(ItemInfo(name: "coreCount", value: "\(info.processorCount)"))
        result.append(ItemInfo(name: "activeCoreCount", value: "\(info.activeProcessorCount)"))
        result.append(ItemInfo(name: "physicalMemory", value: format(memory: info.physicalMemory)))
        result.append(ItemInfo(name: "systemUptime", value: format(duration: info.systemUptime)))
        result.append(ItemInfo(name: "thermalState", value: format(of: info.thermalState)))
        result.append(ItemInfo(name: "lowPowerMode", value: "\(info.isLowPowerModeEnabled)"))
        return result
    }
    
    private func format(memory:UInt64)->String
    {
        var components:[String] = []
        var memory = memory
        while memory > 1024
        {
            memory /= 1024
            components.append("1024")
        }
        
        components.insert(memory.description, at: 0)
        return components.joined(separator: "x")
    }
    
    private func format(of type:UIDeviceBatteryState)->String
    {
        switch type
        {
            case .charging:
                return "charging"
            case .full:
                return "full"
            case .unplugged:
                return "unplugged"
            case .unknown:
                return "unknown"
        }
    }
    
    private func format(of type:ProcessInfo.ThermalState)->String
    {
        switch type
        {
            case .critical:
                return "critical"
            case .fair:
                return "fair"
            case .nominal:
                return "nominal"
            case .serious:
                return "serious"
        }
    }
    
    private func format(of type:UIUserInterfaceIdiom)->String
    {
        switch type
        {
            case .carPlay:
                return "carPlay"
            case .pad:
                return "pad"
            case .phone:
                return "phone"
            case .tv:
                return "tv"
            case .unspecified:
                return "unspecified"
        }
    }
    
    private func format(duration:TimeInterval)->String
    {
        var duration = duration
        let bases:[Double] = [60, 60, 24]
        var list:[Double] = []
        for value in bases
        {
            list.insert(fmod(duration, value), at: 0)
            duration = floor(duration / value)
        }
        if duration > 0
        {
            list.insert(duration, at: 0)
            return String(format: "%.0f %02.0f:%02.0f:%.3f", arguments: list)
        }
        else
        {
            return String(format: "%02.0f:%02.0f:%.3f", arguments: list)
        }
    }
    
    var ctinfo:CTTelephonyNetworkInfo?
    private func getTelephony()->[ItemInfo]
    {
        var result:[ItemInfo] = []
        if ctinfo == nil
        {
            ctinfo = CTTelephonyNetworkInfo()
        }
        
        if let telephony = ctinfo!.currentRadioAccessTechnology
        {
            switch telephony
            {
                case CTRadioAccessTechnologyLTE:
                    result.append(ItemInfo(name: "radio", value: "LTE"))
                case CTRadioAccessTechnologyEdge:
                    result.append(ItemInfo(name: "radio", value: "EDGE"))
                case CTRadioAccessTechnologyGPRS:
                    result.append(ItemInfo(name: "radio", value: "GPRS"))
                case CTRadioAccessTechnologyHSDPA:
                    result.append(ItemInfo(name: "radio", value: "HSDPA"))
                case CTRadioAccessTechnologyHSUPA:
                    result.append(ItemInfo(name: "radio", value: "HSUPA"))
                case CTRadioAccessTechnologyWCDMA:
                    result.append(ItemInfo(name: "radio", value: "WCDMA"))
                case CTRadioAccessTechnologyCDMA1x:
                    result.append(ItemInfo(name: "radio", value: "CDMA_1x"))
                case CTRadioAccessTechnologyCDMAEVDORev0:
                    result.append(ItemInfo(name: "radio", value: "CDMA_EVDO_0"))
                case CTRadioAccessTechnologyCDMAEVDORevA:
                    result.append(ItemInfo(name: "radio", value: "CDMA_EVDO_A"))
                case CTRadioAccessTechnologyCDMAEVDORevB:
                    result.append(ItemInfo(name: "radio", value: "CDMA_EVDO_B"))
                default:
                    result.append(ItemInfo(name: "radio", value: telephony))
            }
        }
        
        if let carrier = ctinfo!.subscriberCellularProvider
        {
            if let name = carrier.carrierName
            {
                result.append(ItemInfo(name: "carrier", value: name))
            }
            
            result.append(ItemInfo(name: "VOIP", value: "\(carrier.allowsVOIP)"))
            
            if let isoCode = carrier.isoCountryCode
            {
                result.append(ItemInfo(name: "isoCode", value: isoCode))
            }
            
            if let mobileCode = carrier.mobileCountryCode
            {
                result.append(ItemInfo(name: "mobileCode", value: mobileCode))
            }
            
            if let networkCode = carrier.mobileNetworkCode
            {
                result.append(ItemInfo(name: "networkCode", value: networkCode))
            }
        }
        
        return result
    }
}

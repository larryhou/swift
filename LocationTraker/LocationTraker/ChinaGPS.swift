//
//  ChinaGPS.swift
//  LocationTraker
//
//  Created by larryhou on 28/7/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//

import Foundation
import CoreLocation

class ChinaGPS
{
    struct GPSLocation
    {
        var lon, lat:Double
    }
    
    static private let pi = 3.14159265358979324
    static private let x_pi = pi * 3000.0 / 180.0
    
    //
    //  Krasovsky 1940
    //
    //  a = 6378245.0, 1/f = 298.3
    //  b = a * (1 - f)
    //  ee = (a^2 - b^2) / a^2;
    static private let a = 6378245.0
    static private let ee = 0.00669342162296594323
    
    private class func encrypt_lat(x:Double, y:Double) -> Double
    {
        var ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y
        ret += 0.2 * sqrt(abs(x))
        ret += (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0
        ret += (20.0 * sin(y * pi) + 40.0 * sin(y / 3.0 * pi)) * 2.0 / 3.0
        ret += (160.0 * sin(y / 12.0 * pi) + 320 * sin(y * pi / 30.0)) * 2.0 / 3.0
        return ret
    }
    
    private class func encrpyt_lon(x:Double, y:Double) -> Double
    {
        var ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y
        ret += 0.1 * sqrt(abs(x))
        ret += (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0
        ret += (20.0 * sin(x * pi) + 40.0 * sin(x / 3.0 * pi)) * 2.0 / 3.0
        ret += (150.0 * sin(x / 12.0 * pi) + 300.0 * sin(x / 30.0 * pi)) * 2.0 / 3.0
        return ret
    }
    
    private class func outOfChina(lat:Double, lon:Double) -> Bool
    {
        if lon < 72.004 || lon > 137.8347
        {
            return true
        }
        
        if lat < 0.8293 || lat > 55.8271
        {
            return true
        }
        
        return false
    }
    
    ///
    ///  WGS-84 到 GCJ-02 的转换
    ///
    class func encrpyt_WGS_2_GCJ(loc:GPSLocation) -> GPSLocation
    {
        if outOfChina(loc.lat, lon: loc.lon)
        {
            return loc
        }
        
        var lat = encrypt_lat(loc.lon - 105.0, y: loc.lat - 35.0)
        var lon = encrpyt_lon(loc.lon - 105.0, y: loc.lat - 35.0)
        
        let radian = loc.lat / 180.0 * pi
        let magic = 1 - ee * sin(radian) * sin(radian)
        let magic_2 = sqrt(magic)
        
        lat = (lat * 180.0) / ((a * (1 - ee)) / (magic * magic_2) * pi)
        lon = (lon * 180.0) / (a / magic_2 * cos(radian) * pi)
        
        return GPSLocation(lon: loc.lon + lon, lat: loc.lat + lat)
    }
    
    class func encrypt_WGS_2_GCJ(latitude latitude:Double, longitude:Double) -> CLLocation
    {
        let loc = GPSLocation(lon: longitude, lat: latitude)
        let ret = encrpyt_WGS_2_GCJ(loc)
        
        return CLLocation(latitude: ret.lat, longitude: ret.lon)
    }
    
    ///
    ///  GCJ-02 坐标转换成 BD-09 坐标
    ///
    class func baidu_encrypt(loc:GPSLocation) -> GPSLocation
    {
        let x = loc.lon, y = loc.lat
        let z = sqrt(x * x + y * y) + 0.00002 * sin(y * x_pi)
        let theta = atan2(y, x) + 0.000003 * cos(x * x_pi)
        return GPSLocation(lon:z * cos(theta) + 0.0065, lat:z * sin(theta) + 0.006)
    }
    
    class func baidu_encrypt(latitude latitude:Double, longitude:Double) -> CLLocation
    {
        let loc = GPSLocation(lon: longitude, lat: latitude)
        let ret = baidu_encrypt(loc)
        
        return CLLocation(latitude: ret.lat, longitude: ret.lon)
    }
    
    ///
    ///  BD-09 坐标转换成 GCJ-02坐标
    ///
    class func baidu_decrypt(loc:GPSLocation) -> GPSLocation
    {
        let x = loc.lon - 0.0065, y = loc.lat - 0.006
        let z = sqrt(x * x + y * y) - 0.00002 * sin(y * x_pi)
        let theta = atan2(y, x) - 0.000003 * cos(x * x_pi)
        return GPSLocation(lon:z * cos(theta), lat:z * sin(theta))
    }
    
    class func baidu_decrypt(latitude latitude:Double, longitude:Double) -> CLLocation
    {
        let loc = GPSLocation(lon: longitude, lat: latitude)
        let ret = baidu_decrypt(loc)
        
        return CLLocation(latitude: ret.lat, longitude: ret.lon)
    }

}
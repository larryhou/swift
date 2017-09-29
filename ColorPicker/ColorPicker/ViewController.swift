//
//  ViewController.swift
//  ColorPicker
//
//  Created by larryhou on 21/09/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import Cocoa

enum ColorCollection:Int
{
    case complementary = 2, triadic, tetradic, analogous, neutral_15, neutral_10, neutral_05
}

enum ColorTheme:Int
{
    case rgb = 0, traditional
}

enum ColorSpaceType:Int
{
    case sRGB = 1, genericRGB, deviceRGB, displayP3
}

var sharedColorSpace:NSColorSpace = .sRGB

class ViewController: NSViewController, NSWindowDelegate, ColorPickerDelegate
{
    @IBOutlet weak var platterView: ColorPlatterView!
    @IBOutlet weak var barView: ColorBarView!
    @IBOutlet weak var colorCollectionView: NSCollectionView!
    
    let id = NSUserInterfaceItemIdentifier("ColorCell")
    
    var size = NSSize(width: 100, height: 100)
    let spacing:CGFloat = 5, column:CGFloat = 2
    
    var assets:[CGColor] = []
    var collection:ColorCollection = .neutral_15
    var theme:ColorTheme = .rgb
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        colorCollectionView.register(ColorCell.self, forItemWithIdentifier: id)
        
        barView.restoreOrigin()
        colorPicker(barView, eventWith: barView.color(at: barView.position))
        NSEvent.addLocalMonitorForEvents(matching: .keyUp)
        {
            self.keyUp(with: $0)
            return $0
        }
    }
    
    override func keyUp(with event: NSEvent)
    {
        if event.keyCode == 123
        {
            let value = collection.rawValue - 1
            collection = ColorCollection(rawValue: value < 2 ? 8 : value)!
            synchronize()
        }
        else if event.keyCode == 124
        {
            let value = collection.rawValue + 1
            collection = ColorCollection(rawValue: value > 8 ? 2 : value)!
            synchronize()
        }
    }
    
    //MARK: memu
    @IBAction func setTheme(_ sender:NSMenuItem)
    {
        if let parent = sender.parent?.submenu
        {
            for item in parent.items
            {
                item.state = item == sender ? .on : .off
            }
        }
        
        theme = ColorTheme(rawValue: sender.tag)!
        
        barView.theme = theme
        colorPicker(barView, eventWith: barView.color(at: barView.position))
    }
    
    @IBAction func setCollection(_ sender:NSMenuItem)
    {
        collection = ColorCollection(rawValue: sender.tag)!
        synchronize()
    }
    
    @IBAction func setDisplayColorSpace(_ sender:NSMenuItem)
    {
        let type = ColorSpaceType(rawValue: sender.tag)!
        switch type
        {
            case .sRGB: sharedColorSpace = .sRGB
            case .genericRGB: sharedColorSpace = .genericRGB
            case .deviceRGB: sharedColorSpace = .deviceRGB
            case .displayP3: sharedColorSpace = .displayP3
        }
        
        if let parent = sender.parent?.submenu
        {
            for item in parent.items
            {
                item.state = item == sender ? .on : .off
            }
        }
        
        colorCollectionView.reloadData()
    }
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
        if menuItem.action == #selector(saveDocument(_:))
        {
            return false
        }
        return menuItem.isEnabled
    }
    
    @IBAction func saveDocument(_ sender:NSMenuItem)
    {
        
    }
    
    
    func reload()
    {
        size.width = (colorCollectionView.frame.width - (column - 1) * spacing) / column
        size.height = size.width / 16 * 9
        colorCollectionView.reloadData()
    }
    
    func windowDidResize(_ notification: Notification)
    {
        reload()
    }
    
    func colorPicker(_ sender: NSView, eventWith color: CGColor)
    {
        if sender == barView
        {
            platterView.setColor(color)
        }
        
        synchronize()
    }
    
    func synchronize()
    {
        assets.removeAll()
        switch collection
        {
            case .complementary:
                assets = barView.getComplementoryColors()
            case .triadic:
                assets = barView.getTriadicColors()
            case .tetradic:
                assets = barView.getTetradicColors()
            case .analogous:
                assets = barView.getAdjacentColors(angle: 30)
            case .neutral_15:
                assets = barView.getAdjacentColors(angle: 15)
            case .neutral_10:
                assets = barView.getAdjacentColors(angle: 10)
            case .neutral_05:
                assets = barView.getAdjacentColors(angle: 5)
        }
        
        if collection == .complementary
        {
            assets = [platterView.blendColor(assets[0])]
            assets.append(assets[0].opposite)
        }
        else
        {
            for i in 0..<assets.count
            {
                assets[i] = platterView.blendColor(assets[i])
            }
        }
        
        reload()
    }
    
    override var representedObject: Any?
    {
        didSet
        {
            // Update the view, if already loaded.
        }
    }
}

extension ViewController:NSCollectionViewDataSource
{
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return assets.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem
    {
        let item = collectionView.makeItem(withIdentifier: id, for: indexPath) as! ColorCell
        item.color = assets[indexPath.item]
        return item
    }
}

extension ViewController:NSCollectionViewDelegate
{
    
}

extension ViewController:NSCollectionViewDelegateFlowLayout
{
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, insetForSectionAt section: Int) -> NSEdgeInsets
    {
        return NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize
    {
        return size
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat
    {
        return spacing
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat
    {
        return spacing
    }
}


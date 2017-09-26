//
//  ViewController.swift
//  ColorPicker
//
//  Created by larryhou on 21/09/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import Cocoa

enum ColorTheme:Int
{
    case complementary = 2, triadic, tetradic, analogous, neutral, neutral_36, neutral_72
}

class ViewController: NSViewController, NSWindowDelegate, ColorPickerDelegate
{
    @IBOutlet weak var platterView: ColorPlatterView!
    @IBOutlet weak var barView: ColorBarView!
    @IBOutlet weak var colorCollection: NSCollectionView!
    
    let id = NSUserInterfaceItemIdentifier("ColorCell")
    
    var size = NSSize(width: 100, height: 100)
    let spacing:CGFloat = 5, column:CGFloat = 2
    
    var assets:[CGColor] = []
    var theme:ColorTheme = .neutral
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        colorCollection.register(ColorCell.self, forItemWithIdentifier: id)
        
        barView.position = CGPoint(x: 5, y: 0)
        colorPicker(barView, eventWith: NSColor.red.cgColor)
        
        reload()
    }
    
    //MARK: memu
    @IBAction func setColorTheme(_ sender:NSMenuItem)
    {
        theme = ColorTheme(rawValue: sender.tag)!
        synchronize()
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
        size.width = (colorCollection.frame.width - (column - 1) * spacing) / column
        size.height = size.width / 16 * 9
        colorCollection.reloadData()
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
        switch theme
        {
            case .complementary:
                assets = barView.seekComplementoryColors()
            case .triadic:
                assets = barView.seekTriadicColors()
            case .tetradic:
                assets = barView.seekTetradicColors()
            case .analogous:
                assets = barView.seekAnalogousColors()
            case .neutral:
                assets = barView.seekNeutralColors()
            case .neutral_36:
                assets = barView.seekNeutralColors(density: 36)
            case .neutral_72:
                assets = barView.seekNeutralColors(density: 72)
        }
        
        if theme == .complementary
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


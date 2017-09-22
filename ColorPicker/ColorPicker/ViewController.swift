//
//  ViewController.swift
//  ColorPicker
//
//  Created by larryhou on 21/09/2017.
//  Copyright © 2017 larryhou. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSWindowDelegate, ColorPickerDelegate
{
    @IBOutlet weak var themeOptionsButton: NSPopUpButton!
    @IBOutlet weak var infoView: ColorInfoView!
    @IBOutlet weak var platterView: ColorPlatterView!
    @IBOutlet weak var barView: ColorBarView!
    @IBOutlet weak var colorCollection: NSCollectionView!
    
    let id = NSUserInterfaceItemIdentifier("ColorCell")
    
    var size = NSSize(width: 100, height: 100)
    let spacing:CGFloat = 5, column:CGFloat = 2
    
    var assets:[CGColor] = []
    
    var themeOptions:[String] = []
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        themeOptions.append("互补色 COMPLEMENTARY-COLORS")
        themeOptions.append("三色系 TRIADIC-COLORS")
        themeOptions.append("四色系 TETRADIC-COLORS")
        themeOptions.append("类似色 ANALOGOUS-COLORS")
        themeOptions.append("中性色 NEUTRAL-COLORS")
        
        themeOptionsButton.removeAllItems()
        themeOptionsButton.addItems(withTitles: themeOptions)
        
        colorCollection.register(ColorCell.self, forItemWithIdentifier: id)
        
        barView.position = CGPoint(x: 5, y: 0)
        colorPicker(barView, eventWith: NSColor.red.cgColor)
        
        reload()
    }
    
    func reload()
    {
        size.width = (colorCollection.frame.width - (column + 1) * spacing) / column
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
            synchronize(render: false)
        }
        else
        {
            synchronize(render: true)
        }
        
        infoView.color = color
    }
    
    func synchronize(render:Bool)
    {
        assets.removeAll()
        switch themeOptionsButton.indexOfSelectedItem
        {
            case 0:
                assets = barView.seekComplementoryColors()
            case 1:
                assets = barView.seekTriadicColors()
            case 2:
                assets = barView.seekTetradicColors()
            case 3:
                assets = barView.seekAnalogousColors()
            case 4:
                assets = barView.seekNeutralColors()
            default:break
        }
        
        if render
        {
            if themeOptionsButton.indexOfSelectedItem > 0
            {
                for i in 0..<assets.count
                {
                    assets[i] = platterView.blendColor(assets[i])
                }
            }
            else
            {
                assets = [platterView.blendColor(assets[0])]
                assets.append(assets[0].opposite)
            }
        }
        
        reload()
    }

    @IBAction func themeUpdate(_ sender: NSPopUpButton)
    {
        synchronize(render: false)
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
        return NSEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
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


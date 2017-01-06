//
//  ViewController.swift
//  XZQRCode_Swift
//
//  Created by MYKJ on 17/1/6.
//  Copyright © 2017年 zhaoyongjie. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func scanClick(_ sender: Any) {
        let scan = XZQRCodeController.scanner { (result) in
            print("result = \(result)")
        }
        show(scan, sender: nil);
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


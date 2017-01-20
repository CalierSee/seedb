//
//  ViewController.swift
//  SEEDB
//
//  Created by 景彦铭 on 2016/12/11.
//  Copyright © 2016年 景彦铭. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    private let sqlite: SEESqliteManager = SEESqliteManager.share()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let person1: Person = Person()
        
        person1.name = "张三"
        person1.age = 18
        person1.gander = false
        let arr: [Person] = [person1]
        SEESqlite.test(objc: arr)
        
    }

    //MARK: - swift

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


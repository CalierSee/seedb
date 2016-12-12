//
//  SEESqlite.swift
//  SEEDB
//
//  Created by 景彦铭 on 2016/12/11.
//  Copyright © 2016年 景彦铭. All rights reserved.
//


class SEESqlite: NSObject {

    static let manager: SEESqlite = SEESqlite()
    
    private var db: OpaquePointer?
    
    override init() {
        super.init()
        sqlite3_open(self.sqlitePath(), &db)
    }
    
    class func test(objc: AnyObject) {
        let dict: [String: Any] = SEESqlite.manager.dictionary(withObj: objc)
        print(dict)
    }
    
    ///insert object to table 
    ///this method will create a table if designate table not exists
    /// 0 success
    class func insert(withObjs objs: AnyObject,toTable table: String) -> Int {
        if objs is [Any] {
            sqlite3_exec(SEESqlite.manager.db!, "begin transcation", nil, nil, nil)
            var flag: Int = 0
            for (index,obj) in (objs as! [Any]).enumerated()  {
                if index == 0 {
                    flag = SEESqlite.manager.create(withTableName: table, withClass: type(of: obj as AnyObject))?.insert(obj as AnyObject,toTable: table) ?? 1
                }else {
                    flag = SEESqlite.manager.insert(obj as AnyObject, toTable: table)
                }
                if flag != 0 {
                    sqlite3_exec(SEESqlite.manager.db!, "rollback transcation", nil, nil, nil)
                    return flag
                }
            }
            sqlite3_exec(SEESqlite.manager.db!, "commit transcation", nil, nil, nil)
            return flag
        }
        else {
            return SEESqlite.manager.create(withTableName: table, withClass: type(of: objs))?.insert(objs,toTable: table) ?? 1
        }
    }
    
    private func insert(_ obj: AnyObject,toTable table: String) -> Int {
        
        return 1
    }
    
    ///create table 
    ///0 success
    private func create(withTableName name: String, withClass cla: AnyClass) -> SEESqlite? {
        let propertys: [String] = array(withCla: cla)
        var say: String = "create table if not exists '\(name)'("
        for (index,name) in propertys.enumerated() {
            if index != propertys.count - 1{
                say = say + "\(name) text,"
            }
            else {
                say = say + "\(name) text);"
            }
        }
        if sqlite3_exec(db!, say, nil, nil, nil) == 0 {
            return self
        }
        else {
            return nil
        }
    }
    
    ///obj -> [String: Any]
    private func dictionary(withObj obj: AnyObject) -> [String: Any] {
        var dict: [String: Any] = [String: Any]()
        let propertys: [String] = array(withCla: type(of: obj))
        for i in 0..<propertys.count {
            dict.updateValue(obj.value(forKey: propertys[i]) ?? "", forKey: propertys[i])
        }
        return dict
    }
    
    ///obj property name array
    private func array(withCla cla: AnyClass) -> [String] {
        var outCount: UInt32 = 0
        let propertyList: UnsafeMutablePointer<objc_property_t?> = class_copyPropertyList(cla, &outCount)
        var propertyArray: [String] = [String]()
        for i in 0..<outCount {
            guard let name = property_getName(propertyList[Int(i)]) else {
                continue
            }
            let propertyName: String = NSString(utf8String: name) as! String
            propertyArray.append(propertyName)
        }
        return propertyArray
    }
    
    ///database path
    private func sqlitePath() -> String {
        let documentPath: NSString = (NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first)! as NSString
        return documentPath.appendingPathComponent("sqlite.db")
    }
    
}

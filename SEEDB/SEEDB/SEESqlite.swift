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
    
    class func test(objc: Any) {
        SEESqlite.insert(withObjs: objc, toTable: "abc")
        let obj = SEESqlite.getObjcs(fromTable: "abc", withClass: Person.self, nil)
        SEESqlite.delete(objc, fromTable: "abc", idField: "name")
        let objc = SEESqlite.getObjcs(fromTable: "abc", withClass: Person.self, nil)
    }
    
    
    
    //MARK: - insert
    ///insert object to table 
    ///this method will create a table if designate table not exists
    /// 0 success
    class func insert(withObjs objs: Any,toTable table: String) -> Int {
        if objs is [AnyObject] {
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
            let obj = objs as AnyObject
            return SEESqlite.manager.create(withTableName: table, withClass: type(of: obj))?.insert(obj,toTable: table) ?? 1
        }
    }
    
    private func insert(_ obj: AnyObject,toTable table: String) -> Int {
        let propertys = array(withCla: type(of: obj))
        var say: String = "insert or replace into '\(table)'("
        var say2: String = " values("
        for (index,propertyName) in propertys.enumerated() {
            if index == propertys.count - 1 {
                say.append("\(propertyName))")
                say2.append("'\((obj.value(forKey: propertyName))!)');")
                say = say + say2
                break
            }
            say.append("\(propertyName),")
            say2.append("'\((obj.value(forKey: propertyName))!)',")
        }
        return Int(sqlite3_exec(db!, say, nil, nil, nil))
    }
    
    //MARK: - delete
    ///delete objcet from table
    /// - Parameter objcs: delete objc from table
    ///   if this parameter is nil, delete all data in table
    ///   if this parameter is array, delete each of array objcs in table
    /// - Parameter table: table name
    /// - Parameter idField: id field
    /// - Returns: 0 success
    class func delete(_ objcs: Any?,fromTable table: String,idField: String) -> Int {
        if objcs is [AnyObject] {
            sqlite3_exec(SEESqlite.manager.db, "begin transcation", nil, nil, nil)
            for (_, obj) in (objcs as! [Any]).enumerated() {
                if SEESqlite.manager.delete(obj as AnyObject, fromTable: table, idField: idField) != 0 {
                    sqlite3_exec(SEESqlite.manager.db, "rollback transcation", nil, nil, nil)
                    return 1
                }
            }
            sqlite3_exec(SEESqlite.manager.db, "commit transcation", nil, nil, nil)
            return 0
        }
        else {
            let objc = objcs as AnyObject
            return Int(SEESqlite.manager.delete(objc, fromTable: table, idField: idField))
        }
    }
    
    private func delete(_ objc: AnyObject?,fromTable table: String,idField: String) -> Int {
        var say = "delete from \(table)"
        if let objc = objc {
            guard let value = objc.value(forKey: idField) else{
                return 1
            }
            say = say + " where \(idField)='\(value)';"
        }
        else {
            say = say + ";"
        }
        return Int(sqlite3_exec(db, say, nil, nil, nil))
    }
    
    //MARK: - get
    class func getObjcs(fromTable table: String,withClass cla: AnyClass,_ whereString: String?) -> [AnyObject]? {
        var say: String = "select * from \(table)"
        if let wheres = whereString {
            say = say + " where \(wheres)"
        }
        let dictionarys: [[String: Any]]? = SEESqlite.manager.dictionaryArray(fromTable: table, say)
        guard let array = dictionarys else {
            return nil
        }
        var objcs: [AnyObject] = [AnyObject]()
        for (_,obj) in array.enumerated() {
            let objc = cla.alloc()
            objc.setValuesForKeys(obj)
            objcs.append(objc)
        }
        return objcs
    }
    
    private func dictionaryArray(fromTable table: String,_ say: String) -> [[String: Any]]? {
        var ppStmt: OpaquePointer?
        if sqlite3_prepare_v2(db, say, -1, &ppStmt, nil) == SQLITE_OK {
            var dictionarys: [[String: Any]] = [[String: Any]]()
            //取结果集
            while sqlite3_step(ppStmt) == SQLITE_ROW {
                var dictionary: [String: Any] = [String: Any]()
                for i in 0..<sqlite3_column_count(ppStmt) {
                    let valueUInt8: UnsafePointer<UInt8>? = sqlite3_column_text(ppStmt, i)
                    guard let valueUInt = valueUInt8 else {
                        dictionary["\(String(cString: sqlite3_column_name(ppStmt, i)))"] = ""
                        continue
                    }
                    let value: String = String(cString: valueUInt)
                    dictionary["\(String(cString: sqlite3_column_name(ppStmt, i)))"] = value
                }
                dictionarys.append(dictionary)
            }
            return dictionarys
        }
        else {
            return nil
        }
    }
    
    //MARK: - create
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

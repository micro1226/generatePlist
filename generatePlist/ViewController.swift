//
//  ViewController.swift
//  generatePlist
//
//  Created by Mary Qian on 16/9/26.
//  Copyright © 2016年 User. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    var countryArray = ["中国": "10", "香港": "9", "日本": "8", "韩国": "7", "美国": "6", "新加坡": "5"]
    var fountName = 0
    var notFoundName = 0
    var compareArray: [String] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        generate()
//        addChinese()
        // Do any additional setup after loading the view, typically from a nib.
    }

    func generate() {
        let codeDict = getDataFromJson()
        print(codeDict.keys.count)
        let codeArray2 = addChinese()
        print(codeArray2.count)
        var CountryCodeArray = [[String: AnyObject]]()
        for (_, value) in codeDict {
            var dict = [String: AnyObject]()
            let country = value as! [String: AnyObject]
            let dialling = country["dialling"] as! [String: AnyObject]
            
            let diallingCode = dialling["calling_code"] as? [String]
            let national_number_lengths = dialling["national_number_lengths"]
            let name = country["name"] as! [String: AnyObject]
            let common_name = name["common"] as! String
            
            var chinese_spelling = ""
            var sortPriority = "0"
            
            if isValid(diallingCode as AnyObject?) && isValid(national_number_lengths) {
                if diallingCode!.count == 1 {
                    dict["calling_code"] = (diallingCode! as [String]).first!
                    dict["common_name"] = common_name as AnyObject?
                    dict["national_number_lengths"] = national_number_lengths
                    let chinese_name = getChineseName(common_name, diallingCode: diallingCode!.first!, codeArray2: codeArray2)

                    dict["chinese_spelling"] = transformChineseToPinyin(chinese_name)
                    if let priority = countryArray[chinese_name] {
                        sortPriority = priority
                    }
                    dict["sortPriority"] = sortPriority
                    dict["chinese_name"] = chinese_name as AnyObject?
                    CountryCodeArray.append(dict)
                } else if diallingCode!.count > 1 {
                    var count = diallingCode!.count
                    for index in 0..<count {
                        dict["calling_code"] = (diallingCode! as [String])[index]
                        dict["common_name"] = common_name as AnyObject?
                        dict["national_number_lengths"] = national_number_lengths
                        let chinese_name = getChineseName(common_name, diallingCode: diallingCode!.first!, codeArray2: codeArray2)
                        dict["chinese_spelling"] = transformChineseToPinyin(chinese_name)
                        if let priority = countryArray[chinese_name] {
                            sortPriority = priority
                        }
                        dict["sortPriority"] = sortPriority
                        dict["chinese_name"] = chinese_name as AnyObject?
                        CountryCodeArray.append(dict)
                    }
                }
            } else {
                print("+++++")
                print(common_name)
            }
        }
        print(fountName)
        print(notFoundName)
        print(CountryCodeArray.count)
        print("=====")
        for item in codeArray2 {
            if compareArray.indexOf(item["zhName"]!) == nil {
                print(item["zhName"])
            }
        }
        sortCodeArray(CountryCodeArray)
    }
    
    func transformChineseToPinyin(chineseName: String) -> String {
        var msString: CFMutableStringRef = NSMutableString(string: chineseName)
        CFStringTransform(msString, nil, kCFStringTransformMandarinLatin, false)
        CFStringTransform(msString, nil, kCFStringTransformStripDiacritics, false)
        let spaceString: String = msString as String
        let string = spaceString.stringByReplacingOccurrencesOfString(" ", withString: "")
        return string
    }
    
    func sortCodeArray(array: [[String: AnyObject]]) {
        let sortedArray = array.sort { (item1, item2) -> Bool in
            let name1 = item1["common_name"] as! String
            let name2 = item2["common_name"] as! String
            return name1 < name2
        }
        writeToPlist(sortedArray as NSArray)
        
        
        
    }
//    
//        func sortArray(array: [[String: AnyObject?]]) -> [[String: AnyObject?]]{
//            let arrayToSort = array as! NSArray
////            arrayToSort.sort
//    
//            let newArray = array.sorted { (item1, item2) -> Bool in
//                let name1 = item1["common_name"] as! String
//                let name2 = item2["common_name"] as! String
//                return name1 < name2
//            }
//            writeToPlist(fileArray: newArray as! NSArray)
//    
//    
//            return newArray
//        }
    
    func getChineseName(enName: String, diallingCode: String ,codeArray2: [[String: String]]) -> String {
        var chinese_name = ""
        var name2 = ""
        for item in codeArray2 {
            let code = item["code"]!
            if code == diallingCode {
                name2 = code
                chinese_name = item["zhName"]!
                compareArray.append(chinese_name)
                fountName += 1
                break
            }
        }
        if name2 == "" {
            notFoundName += 1
            print("\(enName) not found")
        }
        return chinese_name
    }
    
    func writeToPlist(fileArray: NSArray) {
        let countryCodePlistPath = NSBundle.mainBundle().pathForResource("CountryCode.plist", ofType: nil)
        print(countryCodePlistPath)
        fileArray.writeToFile(countryCodePlistPath!, atomically: true)
    }
    
    func isValid(obj: AnyObject?) -> Bool {
        if obj == nil {
            return false
        }
        if obj!.isKindOfClass(NSNull) {
            return false
        }
        if obj! as! NSObject == NSNull() {
            return false
        }
        return true
    }
    
    func getDataFromJson() -> [String: AnyObject] {
        let stringPath = NSBundle.mainBundle().pathForResource("Directions.geojson", ofType: nil)
        let data = NSData(contentsOfFile: stringPath!)
        
        var codeDict = [String: AnyObject]()
        
        do {
            let dict = try NSJSONSerialization.JSONObjectWithData(data!, options: [])
            codeDict = dict as! [String: AnyObject]
        } catch {}
        return codeDict
    }
    
    func addChinese() -> [[String: String]]{
        
        let chinesePath = NSBundle.mainBundle().pathForResource("CountryWithChinese", ofType: "geojson")
        let data = NSData(contentsOfFile: chinesePath!)
        var codeArray: [String] = []
        do {
            let temp = try NSJSONSerialization.JSONObjectWithData(data!, options: [])
            codeArray = temp as! [String]
        } catch {
            print("error")
        }
        var printArray = [[String: String]]()
        for item in codeArray {
            let array = item.componentsSeparatedByString(" ")
            let count = array.count
            var enName = ""
            for i in 0..<(count - 2) {
                enName.appendContentsOf(array[i])
            }
            let zhName = array[count - 2]
            let codeString = array.last!
            let code = codeString.substringFromIndex(codeString.startIndex.advancedBy(1))
            let dict = ["enName": enName, "zhName": zhName, "code": code]
            printArray.append(dict)
        }
        return printArray
    }
    
    func notFoundCountry() {
        
        //        Optional(Optional("阿森松"))
        //        Optional(Optional("多米尼加共和国"))
        //        Optional(Optional("哈萨克斯坦"))
        //        Optional(Optional("吉尔吉斯坦"))
        //        Optional(Optional("荷属安的列斯"))
        //        Optional(Optional("东萨摩亚(美)"))
        //        Optional(Optional("圣文森特"))
        //        Optional(Optional("特立尼达和多巴哥"))
        //        Optional(Optional("美国"))
        
        //        多米尼加联邦 DOMINICA(COMMOMWEALTHOF) 1767 -12
        //        多米尼加共和国 DOMINICAN REP 1809 -12
        
        //        Eritrea not found
        //        Palau not found
        //        Saint Martin not found
        //        Sint Maarten not found
        //        Bosnia and Herzegovina not found
        //        Timor-Leste not found
        //        Marshall Islands not found
        //        Kiribati not found
        //        Uzbekistan not found
        //        Anguilla not found
        //        Guinea-Bissau not found
        //        Turks and Caicos Islands not found
        //        Vanuatu not found
        //        Niue not found
        //        Saint Pierre and Miquelon not found
        //        Croatia not found
        //        Norfolk Island not found
        //        Dominica not found
        //        Macedonia not found
        //        Curaçao not found
        //        Trinidad and Tobago not found
        //        Kazakhstan not found
        //        Aruba not found
        //        Palestine not found
        //        Grenada not found
        //        United States Virgin Islands not found
        //        Greenland not found
        //        Zambia not found
        //        Tokelau not found
        //        American Samoa not found
        //        Svalbard and Jan Mayen not found
        //        Saint Barthélemy not found
        //        Montenegro not found
        //        Vatican City not found
        //        Bhutan not found
        //        Kyrgyzstan not found
        //        Mauritania not found
        //        British Virgin Islands not found
        //        New Caledonia not found
        //        South Sudan not found
        //        Comoros not found
        //        Tuvalu not found
        //        Cape Verde not found
        //        British Indian Ocean Territory not found
        //        Guadeloupe not found
        //        Albania not found
        //        Ivory Coast not found
        //        Rwanda not found
        //        Falkland Islands not found
        //        Saint Kitts and Nevis not found
        //        Wallis and Futuna not found
        //        Equatorial Guinea not found
        //        South Georgia not found
        //        Micronesia not found
        //        Faroe Islands not found
    }


}


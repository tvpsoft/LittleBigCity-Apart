//
//  Activity.swift
//  LittleBigCity
//
//  Created by Viet Phuong Tran on 12/30/15.
//  Copyright © 2015 Viet Phuong Tran. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftyJSON
import SwiftDate

class Activity: Object {
    
    dynamic var id:Int = 0
    dynamic var name:String = ""
    dynamic var dateStart:String = ""
    dynamic var dateEnd:String = ""
    dynamic var timeStart:String = ""
    dynamic var timeEnd:String = ""
    dynamic var timeType:Int = 0
    dynamic var regularTime:String = ""
    dynamic var descriptionText:String = ""
    dynamic var slug:String = ""
    dynamic var whatInPrice:String = ""
    dynamic var whatInPass:String = ""
    dynamic var categoryId:Int = 0
    dynamic var price:Float = 0
    dynamic var free:Bool = false
    dynamic var number:Int = 0
    dynamic var numberLeft:Int = 0
    dynamic var lastCallPrice:Bool = false
    dynamic var socialPrice:Bool = false
    dynamic var socialPriceValue:Float = 0
    dynamic var socialPriceCode:String = ""
    dynamic var passToLbc:Int = 0
    dynamic var externalLink:String = ""
    dynamic var photo:String = ""
    dynamic var facebookId:String = ""
    dynamic var highlight:Bool = false
    dynamic var choiceOfDay:Bool = false
    dynamic var choiceOfDayDate : String = ""
    dynamic var specialCase:Int = 0
    dynamic var specialCaseText:String = ""
    dynamic var buttonTextBefore:String = ""
    dynamic var buttonTextAfter:String = ""
    dynamic var concatStart : NSDate?
    dynamic var concatEnd : NSDate?
    dynamic var distance:Float = 0
    dynamic var totalParticipants:Int = 0

    dynamic var isImIn:Bool = false
    dynamic var iHaveTicket:Bool = false
    
    //Activty is belong to a Location
    dynamic var location : Location?
    //Activity has many participants
    let participants = List<Profile>()
    //Activity has many photo
    let photos = List<Photo>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    func saveValueFromJSON(_data: SwiftyJSON.JSON) -> Activity {

        
        let _a = Activity()
        //Only add
        if(_data["id"].intValue > 0){
            
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            _a.id = _data["id"].intValue
            _a.name = _data["name"].stringValue
            _a.dateStart = _data["date_start"].stringValue
            _a.dateEnd = _data["date_end"].stringValue
            _a.timeStart = _data["time_start"].stringValue
            _a.timeEnd = _data["time_end"].stringValue
            _a.timeType = _data["time_type"].intValue
            _a.regularTime = _data["regular_time"].stringValue
            _a.descriptionText = _data["description"].stringValue
            _a.categoryId = _data["category_id"].intValue
            _a.slug = _data["slug"].stringValue
            _a.whatInPrice = _data["what_in_price"].stringValue
            _a.whatInPass = _data["what_in_pass"].stringValue
            _a.price = _data["price"].floatValue
            _a.free = _data["free"].boolValue
            _a.number = _data["number"].intValue
            _a.numberLeft = _data["number_left"] == nil ? _data["number"].intValue : _data["number_left"].intValue
            _a.lastCallPrice = _data["last_call_price"].boolValue
            _a.socialPrice = _data["social_price"].boolValue
            _a.socialPriceValue = _data["social_price_value"].floatValue
            _a.socialPriceCode = _data["social_price_code"].stringValue
            _a.passToLbc = _data["pass_to_lbc"].intValue
            _a.externalLink = _data["external_link"].stringValue
            _a.photo = _data["photo"].stringValue
            _a.facebookId = _data["facebook_id"].stringValue
            _a.highlight = _data["highlight"].boolValue
            _a.choiceOfDay = _data["choice_of_day"].boolValue
            _a.choiceOfDayDate  = _data["choice_of_day_date"].stringValue
            _a.specialCase = _data["special_case"].intValue
            _a.specialCaseText = _data["special_case_text"].stringValue
            _a.buttonTextBefore = _data["button_text_before"].stringValue
            _a.buttonTextAfter = _data["button_text_after"].stringValue
            _a.concatStart  = dateFormatter.dateFromString(_data["concatStart"].stringValue)
            _a.concatEnd = dateFormatter.dateFromString(_data["concatEnd"].stringValue)
            _a.distance = _data["distance"].floatValue
            _a.totalParticipants = _data["Participants"]["total"].intValue
            
            let _location =  Location()
            _location.name = _data["Location"]["name"].stringValue
            _location.longitude = _data["Location"]["longitude"].floatValue
            _location.latitude = _data["Location"]["latitude"].floatValue
            _location.address  = _data["Location"]["address"].stringValue
            _location.street  = _data["Location"]["street"].stringValue
            _location.zip_code  = _data["Location"]["zip_code"].stringValue
            _location.id  = _data["Location"]["id"].intValue
            
            _a.location = _location
            
            if(_data["Participants"] != nil){
            
                for _participant:SwiftyJSON.JSON in _data["Participants"]["profiles"].arrayValue {
                    
                    let _profile = Profile()
                    _profile.id = _participant["id"].intValue
                    _profile.avatar = _participant["avatar"].stringValue
                    _profile.firstName = _participant["first_name"].stringValue
                    _profile.lastName = _participant["last_name"].stringValue
                    _profile.distanceKm = _participant["distance"].floatValue
                    _profile.canChat = _participant["device"].boolValue
                    
                    //Add profile to Activity
                    _a.participants.append(_profile)
                }
            }
            
            if(_data["Me"] != nil){
                _a.isImIn = _data["Me"]["In"].boolValue
                _a.iHaveTicket = _data["Me"]["Ticket"].boolValue
            }
            
            if(_data["Photos"] != nil){
                
                for _p: SwiftyJSON.JSON in _data["Photos"].arrayValue {
                    let _photo = Photo()
                    _photo.id = _p["id"].intValue
                    _photo.photo = _p["photo"].stringValue
                    //Add photo to Activity
                    _a.photos.append(_photo)
                }
            }
            
            let realm = try! Realm()
            try! realm.write {
                realm.add(_a, update: true)
            }
            
        }
        
        return _a
    }
    
    func getById(activityId:Int) -> Activity {
    
        let realm = try! Realm()
        var _activity = realm.objects(Activity).filter("id = %@", activityId).first
        if(_activity == nil){
            _activity = Activity()
            _activity?.id = activityId
            return _activity!
        }
        return _activity!
    }
    
    
    func getUrlForSharing() -> String{
    
        if(self.slug.length > 0 ){
            return lbcUrl + self.slug
        }else{
            let _slug:String = self.name.slugify()
            return  lbcUrl + String(id) + "-" +  _slug
        }
    
    }
    
    
    /**
    * Display time on the collection cell
    */
    func displayTime() -> String {
        var _output = ""
        
        switch (timeType){
        case ActivityTimeType.SPECIFIC:
            var _strExtra = ""
            if(dateStart.length > 0){
                let _dateStart = dateStart.toDateFromISO8601()
                if(_dateStart!.isInToday()){
                   _output = NSLocalizedString("Today", comment: "Today")
                }else if(_dateStart!.isInTomorrow()){
                    _output = NSLocalizedString("Tomorrow", comment: "Tomorrow")
                }else{
                    _output = _dateStart!.toString(DateFormat.Custom("EEE dd MMM"))!
                }
                if(dateEnd.length > 0){
                    let _dateEnd = dateEnd.toDateFromISO8601()
                    
                    let _interval = _dateEnd?.timeIntervalSinceDate(_dateStart!)
                    let _range = round(_interval! / 60 / 60 / 24)
                    if( _range > 1){
                        _output = _output + " " + NSLocalizedString("to_au", comment: "to") + " " + _dateEnd!.toString(DateFormat.Custom("EEE dd MMM"))!
                    }else if(_range == 1){
                        _strExtra = " " + _dateEnd!.toString(DateFormat.Custom("EEE dd MMM"))!
                    }
                }
            }
            
            if(timeStart.length > 0){
                let arrTimeStart = timeStart.characters.split{$0 == ":"}.map(String.init)
                var strFrom = NSLocalizedString("from", comment: "from")
                if(timeEnd.length == 0) {
                    strFrom = NSLocalizedString("StartFrom", comment: "from")
                }
                _output = _output + " " + strFrom  + " " + arrTimeStart[0] + ":" + arrTimeStart[1]
            }
            
            if(timeEnd.length > 0) {
                let arrTimeEnd = timeEnd.characters.split{$0 == ":"}.map(String.init)
                _output = _output + " " + NSLocalizedString("to", comment: "to") + " " + arrTimeEnd[0] + ":" + arrTimeEnd[1] + _strExtra
            }
            break;
            
        case ActivityTimeType.REGULAR:
            let arrRegularTime = regularTime.characters.split{$0 == ","}.map(String.init)
            for i:Int in 0...(arrRegularTime.count - 1){
                if (arrRegularTime[i].length > 0){
                    if(_output.length > 0){
                        _output = _output + ", " + arrRegularTime[i].toDayInWeek()
                    }else{
                        _output = NSLocalizedString("Every", comment: "Every") + " " + arrRegularTime[i].toDayInWeek()
                    }
                }
            }
            if(timeStart.length > 0){
                let arrTimeStart = timeStart.characters.split{$0 == ":"}.map(String.init)
                var strFrom = NSLocalizedString("from", comment: "from")
                if(timeEnd.length == 0) {
                    strFrom = NSLocalizedString("StartFrom", comment: "from")
                }
                _output = _output + " " + strFrom  + " " + arrTimeStart[0] + ":" + arrTimeStart[1]
            }
            if(timeEnd.length > 0){
                let arrTimeEnd = timeEnd.characters.split{$0 == ":"}.map(String.init)
                _output = _output + " " + NSLocalizedString("to", comment: "to") + " " + arrTimeEnd[0] + ":" + arrTimeEnd[1]
            }
            break;
        case ActivityTimeType.ANYTIME:
            
            let arrRegularTime = regularTime.characters.split{$0 == ","}.map(String.init)
            if(arrRegularTime.count > 0){
            
                for i:Int in 0...(arrRegularTime.count - 1){
                    if (arrRegularTime[i].length > 0){
                        if(_output.length > 0){
                            _output = _output + ", " + arrRegularTime[i].toDayInWeek()
                        }else{
                            _output = NSLocalizedString("Anytime", comment: "Anytime") + " " + arrRegularTime[i].toDayInWeek()
                        }
                    }
                }
            
            }else{
                _output = NSLocalizedString("Anytime", comment: "Anytime")
            }
            
            if(timeStart.length > 0){
                let arrTimeStart = timeStart.characters.split{$0 == ":"}.map(String.init)
                var strFrom = NSLocalizedString("from", comment: "from")
                if(timeEnd.length == 0) {
                    strFrom = NSLocalizedString("StartFrom", comment: "from")
                }
                _output = _output + " " + strFrom  + " " + arrTimeStart[0] + ":" + arrTimeStart[1]
            }
            
            if(timeEnd.length > 0){
                let arrTimeEnd = timeEnd.characters.split{$0 == ":"}.map(String.init)
                _output = _output + " " + NSLocalizedString("to", comment: "to") + " " + arrTimeEnd[0] + ":" + arrTimeEnd[1]
            }
            
            break;
        default:
            break
        }
        
        return _output
    }
    
    

    
    
}

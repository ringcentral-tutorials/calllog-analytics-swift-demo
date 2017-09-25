//
//  CallInfoViewController.swift
//  Call Analytics
//
//  Created by Phong Vu on 9/20/17.
//  Copyright © 2017 Phong Vu. All rights reserved.
//

import UIKit
import Foundation
import Darwin
import RingCentral

class CallInfoViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var inputsView: UIView!
    @IBOutlet weak var phoneNumber: UITextField!
    @IBOutlet weak var extensionNumber: UITextField!
    @IBOutlet weak var directionPicker: UIPickerView!
    @IBOutlet weak var typePicker: UIPickerView!
    @IBOutlet weak var transportPicker: UIPickerView!
    @IBOutlet weak var viewPicker: UIPickerView!
    @IBOutlet weak var showBlockedSwitch: UISwitch!
    @IBOutlet weak var withRecordingSwitch: UISwitch!
    @IBOutlet weak var fromDatePicker: UIDatePicker!
    @IBOutlet weak var toDatePicker: UIDatePicker!

    @IBOutlet weak var outputView: UIView!
    @IBOutlet weak var callLogResultCollectionView: UICollectionView!

    @IBOutlet weak var outcallsDuration: UILabel!
    @IBOutlet weak var incallsDuration: UILabel!
    @IBOutlet weak var totalCallsDuration: UILabel!
    @IBOutlet weak var count: UILabel!
    
    var directionArray: NSArray = ["Default", "Inbound", "Outbound"]
    var typeArray: NSArray = ["Default", "Voice", "Fax"]
    var transportArray: NSArray = ["Default", "PSTN", "VoIP"]
    var viewArray: NSArray = ["Simple", "Detailed"]
    
    var calllogReq = CallLogPath.ListParameters()
    var callLogRecords:NSMutableArray = []
    var queryDateFrom = ""
    var queryDateTo = ""
    
    var rc:RestClient!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        directionPicker.delegate = self
        directionPicker.dataSource = self
        typePicker.delegate = self
        typePicker.dataSource = self
        transportPicker.delegate = self
        transportPicker.dataSource = self
        viewPicker.delegate = self
        viewPicker.dataSource = self
        
        phoneNumber.delegate = self
        extensionNumber.delegate = self
        
        callLogResultCollectionView.delegate = self
        callLogResultCollectionView.dataSource = self
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        rc = appDelegate.createRingCentralClient()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if textField == phoneNumber {
            extensionNumber.becomeFirstResponder()
        }
        return true
    }
    
    // picker implementation
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1;
    }
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: NSInteger) -> Int {
        var c = 0
        if (pickerView == self.directionPicker) {
            c = directionArray.count
        }else if (pickerView == self.typePicker) {
            c = typeArray.count
        }else if (pickerView == self.transportPicker) {
            c = transportArray.count
        }else if (pickerView == self.viewPicker) {
            c = viewArray.count
        }
        return c
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: NSInteger, forComponent component: NSInteger) -> String? {
        var name = ""
        if (pickerView == self.directionPicker) {
            name = directionArray[row] as! String
        }else if (pickerView == self.typePicker) {
            name = typeArray[row] as! String
        }else if (pickerView == self.transportPicker) {
            name = transportArray[row] as! String
        }else if (pickerView == self.viewPicker) {
            name = viewArray[row] as! String
        }
        return name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: NSInteger, inComponent component: NSInteger)
    {
        if (pickerView == self.directionPicker) {
            if (row == 0) {
                calllogReq.direction = nil
            }else {
                calllogReq.direction = directionArray[row] as? String
            }
        }else if (pickerView == self.typePicker) {
            if (row == 0) {
                calllogReq.type = nil
            }else {
                calllogReq.type = typeArray[row] as? String
            }
        }else if (pickerView == self.transportPicker) {
            if (row == 0) {
                calllogReq.transport = nil
            }else {
                calllogReq.transport = transportArray[row] as? String
            }
            print(transportArray[row])
        }else if (pickerView == self.viewPicker) {
            calllogReq.view = viewArray[row] as? String
        }
    }
    
    @IBAction func fromDatePickerValueChanged(_ sender: UIDatePicker) {
        let date:String = String(describing: sender.date)
        let index = date.index(date.startIndex, offsetBy: 10)
        queryDateFrom = date.substring(to: index)
        calllogReq.dateFrom = queryDateFrom
    }
    
    @IBAction func toDatePickerValueChanged(_ sender: UIDatePicker) {
        let date:String = String(describing: sender.date)
        let index = date.index(date.startIndex, offsetBy: 10)
        queryDateTo = date.substring(to: index)
        calllogReq.dateTo = queryDateTo + "T23:59:59.999Z"
    }
    
    @IBAction func withRecordingSwitchValueChanged(_ sender: UISwitch) {
        calllogReq.withRecording = sender.isOn
    }
    
    @IBAction func showBlockedSwitchValueChanged(_ sender: UISwitch) {
        calllogReq.showBlocked = sender.isOn
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView
    {
        let pickerLabel = UILabel()
        if (pickerView == self.directionPicker) {
            pickerLabel.text = directionArray[row] as? String
        }else if (pickerView == self.typePicker) {
            pickerLabel.text = typeArray[row] as? String
        }else if (pickerView == self.transportPicker) {
            pickerLabel.text = transportArray[row] as? String
        }else if (pickerView == self.viewPicker) {
            pickerLabel.text = viewArray[row] as? String
        }
        pickerLabel.textColor = UIColor.darkGray
        pickerLabel.font = UIFont(name: pickerLabel.font.fontName, size: 12)
        pickerLabel.textAlignment = NSTextAlignment.center
        
        return pickerLabel
    }
    
    @IBAction func ReadBtnClicked(_ sender: UIBarButtonItem) {
        if (phoneNumber.text != "") {
            calllogReq.phoneNumber = phoneNumber.text
        }else{
            calllogReq.phoneNumber = nil
        }
        if (extensionNumber.text != "") {
            calllogReq.extensionNumber = extensionNumber.text
        }else{
            calllogReq.extensionNumber = nil
        }
        rc.restapi().account().callLog().list(parameters: calllogReq) { list, error in
            if (error == nil) {
                self.callLogRecords = list?.records as! NSMutableArray
                DispatchQueue.main.async(execute: {
                    self.inputsView.isHidden = true
                    self.outputView.isHidden = false
                    self.callLogResultCollectionView.reloadData()
                    self.setCallsValues()
                })
            }else{
                print(error?.message ?? "nil")
            }
        }
    }
    
    @IBAction func BackBtnClicked(_ sender: UIBarButtonItem) {
        if (inputsView.isHidden == false) {
            dismiss(animated: true, completion: nil)
        }else {
            outputView.isHidden = true
            inputsView.isHidden = false
        }
    }
    
    // list implementation
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        var returnVal = 0
        if (collectionView == self.callLogResultCollectionView) {
            returnVal = 1
        }
        return returnVal
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var returnVal = 0
        if (collectionView == self.callLogResultCollectionView) {
            returnVal = callLogRecords.count
        }
        return returnVal
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        var cell : UICollectionViewCell!
        
        if (collectionView == self.callLogResultCollectionView) {
            let identifier : NSString = "cell0Item";
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier as String, for: indexPath) as UICollectionViewCell
            
            if indexPath.row % 2 == 0 {
                cell.layer.backgroundColor = UIColor(red: 0.74, green: 0.23, blue: 0.12, alpha: 0.2).cgColor
            }else{
                cell.layer.backgroundColor = UIColor.white.cgColor
            }
            
            let record = callLogRecords[indexPath.row] as! CallLogRecord
            let fromNum:UILabel = cell.viewWithTag(1) as! UILabel
            fromNum.text = record.from?.phoneNumber
            let fromName:UILabel = cell.viewWithTag(2) as! UILabel
            fromName.text = record.from?.name
            let image:UIImageView = cell.viewWithTag(3) as! UIImageView
            if (record.type == "Fax") {
                if (record.direction == "Inbound") {
                    image.image = UIImage(named: "incomingFax")
                }else{
                    image.image = UIImage(named: "outgoingFax")
                }
            }else{
                if (record.direction == "Inbound") {
                    image.image = UIImage(named: "incomingCall")
                }else{
                    image.image = UIImage(named: "outgoingCall")
                }
            }
            
            let toNum:UILabel = cell.viewWithTag(4) as! UILabel
            toNum.text = record.to?.phoneNumber
            let toName:UILabel = cell.viewWithTag(5) as! UILabel
            toName.text = record.to?.name
            
            let duration:UILabel = cell.viewWithTag(6) as! UILabel
            let min = Int(floor(Double(record.duration! / 60)))
            let sec = record.duration! % 60
            duration.text = String(format: "%d:%02d", min, sec)
            let action:UILabel = cell.viewWithTag(7) as! UILabel
            action.text = record.action
            let result:UILabel = cell.viewWithTag(8) as! UILabel
            result.text = record.result
            
            if (record.message != nil) {
                let rec:UILabel = cell.viewWithTag(9) as! UILabel
                rec.text = "Has voice message"
                rec.isHidden = false
            }else if (record.recording != nil){
                let rec:UILabel = cell.viewWithTag(9) as! UILabel
                rec.text = "Has voice record"
                rec.isHidden = false
            }
        }
        return cell
    }
    
    func setCallsValues() {
        var incall = 0;
        var outcall = 0
        var voice = 0
        var infax = 0
        var outfax = 0
        var missed = 0
        var records = 0
        var totalIncallsDur = 0
        var totalOutcallsDur = 0
        
        for item in callLogRecords {
            let record = item as! CallLogRecord
            if (record.type == "Fax") {
                if (record.direction == "Inbound") {
                    infax += 1
                }else{
                    outfax += 1
                }
            }else{
                if (record.direction == "Inbound") {
                    incall += 1
                    totalIncallsDur += record.duration!
                }else{
                    outcall += 1
                    totalOutcallsDur += record.duration!
                }
            }
            if (record.message != nil || record.recording != nil) {
                voice += 1
            }else if (record.recording != nil){
                records += 1
            }
            if record.result == "Missed" {
                missed += 1
            }
        }
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .brief
        
        var formattedString = formatter.string(from: TimeInterval(totalIncallsDur))!
        incallsDuration.text = String(format: "Total incalls duration: %@", formattedString)
        
        formattedString = formatter.string(from: TimeInterval(totalOutcallsDur))!
        outcallsDuration.text = String(format: "Total outcalls duration: %@", formattedString)
        
        let totalDur = totalIncallsDur + totalOutcallsDur
        formattedString = formatter.string(from: TimeInterval(totalDur))!
        totalCallsDuration.text = String(format: "Total calls duration: %@", formattedString)
        
        count.text = String(format:"InCall: %d / OutCall: %d / Missed Call: %d / InFax: %d / OutFax: %d", incall, outcall, missed, infax, outfax)
    }
}


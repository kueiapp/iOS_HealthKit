//
//  ViewController.swift
//  Project: iku 行きます　
//
//  Created by Kueiapp.com on 2018/12/11.
//  Copyright © 2018 Kuei. All rights reserved,
//  Followed by GPLv3 license.

import UIKit
import SafariServices

// extension functions
extension UIImageView{
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}

class ViewController: UIViewController, UIScrollViewDelegate {
    
    
    // MARK: -- members --
    let health = HKHealthStore()
    var historyData = [NSDictionary]()
    var stepCount = 0, distancCount = 0
    
    @IBOutlet weak var tempView: UIView!
    @IBOutlet weak var stepView: UIView!
    @IBOutlet weak var distanceView: UIView!
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var humidLabel: UILabel!
    @IBOutlet weak var stepLable:UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var heartRateView: UIView!
    @IBOutlet weak var heartRateLabel: UILabel!
    
    // MARK: -- methods --
    // MARK: -- App lifecycle --
    override func viewDidLoad() {
        super.viewDidLoad()
		
        
        scrollView.delegate = self
        
        // Style views
        self.styleViewCard(setView: tempView, withColor: UIColor(red: 117/255, green: 64/255, blue: 118/255, alpha: 1.0).cgColor)
        self.styleViewCard(setView: stepView, withColor: UIColor(red: 137/255, green: 154/255, blue: 120/255, alpha: 1.0).cgColor)
        self.styleViewCard(setView: distanceView, withColor: UIColor(red: 73/255, green: 64/255, blue: 50/255, alpha: 1.0).cgColor)
        self.styleViewCard(setView: heartRateView, withColor: UIColor(red: 107/255, green: 46/255, blue: 118/255, alpha: 1.0).cgColor)
        
        
        print("history \(self.historyData.description)")
    }
    
    override func viewDidLayoutSubviews() {
        // ScrollView.contenSize is needed to be bigger than viewPort
        scrollView.contentSize = CGSize(width: self.view.frame.size.width, height: 880)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let nott = Notification.Name("myChecker")
        NotificationCenter.default.addObserver(self, selector: #selector(checker(notif:)), name: nott, object: nil)
        
        // Check if device supports HealthStore
        let writeTypes = self.dataTypesToShare()
        let readTypes = self.dataTypesToRead()
        
        // Request for auth
        if HKHealthStore.isHealthDataAvailable() {
            health.requestAuthorization(toShare: writeTypes, read: readTypes) { (success, error) in
                if success{
                    // 個人資料
                    self.readDataOfMe()
                    // 心跳數
                    self.getHeartRate(completion:{(results) in //closure
                        // 從callback function回傳的
                        if let results = results{
                            //設定單位
                            let unit = HKUnit.count().unitDivided(by: .minute())
                            var value:Double?
                            var avgValue:Double = 0
                            var count:Double = 0
                            for item in results as! [HKQuantitySample] {
                                count += 1
                                value = item.quantity.doubleValue(for: unit)
                                if value != nil{
                                    print("heart rate: \(value!)")
                                    avgValue = avgValue + value!
                                }
                                else{
                                    print("something wrong to get heart rate")
                                }
                            }
                            avgValue = avgValue / count
                            print("avg heart rate: \(avgValue)")
                            DispatchQueue.main.async {
                                self.heartRateLabel.text = String(lround(avgValue))
                            }
                        }
                    })
                    // 步數
                    // Date() is today
                    self.getStepCountWithDate(Date(), completion:{ (steps) in //closure
                        // 從callback function回傳的
                        print("today's steps = \(steps)")
                        DispatchQueue.main.async {
                            self.stepLable.text = String(lround(steps))
                        }
                    })
                    // 行走距離
                    self.getDistanceWithDate(Date(), completion:{ (distance) in //closure
                        // 從callback function回傳的
                        print("today's distance = \(distance)")
                        DispatchQueue.main.async {
                            self.distanceLabel.text = String(lround(distance))
                        }
                    })                    
                    
                }
                else{
                    print("something wrong when authorizing")
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func checker(notif:Notification){
        let userInfo = notif.userInfo
        if userInfo!["content"] as! String == "step"{
            stepCount += 1
        }
        if userInfo!["content"] as! String == "distance"{
            distancCount += 1
        }
        print("-----\(String(describing: userInfo!["content"]))--\(stepCount)-------\(distancCount)---")
        
        if stepCount == 6 && distancCount == 6{
            let dic:NSDictionary = ["step":stepCount, "distance":distancCount]
            self.historyData.append(dic)
            print(self.historyData.description)
        }
    }
    
    // MARK: -- Health Store delegate --
    // Writing type to HealthStore
    func dataTypesToShare() -> Set<HKSampleType>? {
        return nil
    }
    
    // Reading type from HealthStore
    func dataTypesToRead() -> Set<HKObjectType>?{
        var set = Set<HKObjectType>()
        //步數
        set.insert(HKQuantityType.quantityType(forIdentifier: .stepCount)!)
        //心跳
        set.insert(HKQuantityType.quantityType(forIdentifier: .heartRate)!)
        //Activity
        set.insert(HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!)
        //Distance
        set.insert(HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!)
        return set
    }
    // Insert for testing
    func insertHeartRateData(_ heartRate: Double, fromDate sDate:Date ){
        let type = HKQuantityType.quantityType(forIdentifier: .heartRate)
        let unit = HKUnit.count().unitDivided(by: HKUnit.minute() )
        let quantity = HKQuantity(unit: unit, doubleValue: heartRate)
        let sample = HKQuantitySample(type: type!, quantity: quantity, start: sDate, end: sDate )
        // save
        health.save(sample) { (success, error) in
            if success {
                print("OK")
            }
            else{
                print("writing failure")
            }
        }
    }
    func insertStepCountData(_ stepCount: Double, fromDate sDate:Date){
        let type = HKQuantityType.quantityType(forIdentifier: .stepCount)
        let quantity = HKQuantity(unit: HKUnit.count(), doubleValue: stepCount)
        let sample = HKQuantitySample(type: type!, quantity: quantity, start: sDate, end: sDate)
        // save
        health.save(sample) { (success, error) in
            if success {
                print("OK")
            }
            else{
                print("writing failure")
            }
        }
    }
    func insertDistanceData(_ dd: Double, fromDate sDate:Date){
        let type = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)
        let quantity = HKQuantity(unit: HKUnit.meterUnit(with: .kilo), doubleValue: dd)
        let sample = HKQuantitySample(type: type!, quantity: quantity, start: sDate, end: sDate)
        // save
        health.save(sample) { (success, error) in
            if success {
                print("OK")
            }
            else{
                print("writing failure")
            }
        }
    }
    // Insert for testing
	
	// Reading
    func readDataOfMe(){
        //性別
        if let sex = try? health.biologicalSex() {
            switch sex.biologicalSex{
                case .female:
                    print("female")
                case .male:
                    print("male")
                case .other:
                    print("other")
                case .notSet:
                    print("not setting yet")
            }
        }
        else{
            print("something wrong when reading sex")
        }
    }
    //closure
    //相當於obj-c function getHeartRate(completion: (void)^(results){} ){}
    func getHeartRate(completion: @escaping (_ results: [HKSample]?) -> Void){
        let type = HKQuantityType.quantityType(forIdentifier: .heartRate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let pred = HKQuery.predicateForSamples(
            withStart: Date().addingTimeInterval(-6*60*60),
            end: Date(),
            options: []
        )
        // Setting query from Health Storage
        // async
        let query = HKSampleQuery(
            sampleType: type!,
            predicate: pred, //查詢區間
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sort]
        ){ (query, results, error) in // closure寫法 { (param) in }
            if error == nil{
                // callback function
                completion(results)
            }
            else{
                print("getHeartRate err")
            }
        }
        // Do query
        health.execute(query)
    }
    
    func predicateForSamplesWithDate(_ date:Date) -> NSPredicate{
        let calendar = NSCalendar.current
        let set:Set<Calendar.Component> = [.year,.month,.day,.hour,.minute,.second]
        var dateComponent = Calendar.current.dateComponents(set, from: Date())
        dateComponent.hour = 0
        dateComponent.minute = 0
        dateComponent.second = 0
        
        let startDate = calendar.date(from: dateComponent)
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate!, wrappingComponents: false)
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: [])
        
        return predicate
    }
    
    func getStepCountWithDate(_ date:Date, completion: @escaping (Double) -> () ){
        let type = HKQuantityType.quantityType(forIdentifier: .stepCount)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        
        let pred:NSPredicate = self.predicateForSamplesWithDate(date)
        
        let timeSort:NSSortDescriptor = NSSortDescriptor.init(key: HKSampleSortIdentifierEndDate, ascending: false)
        // Setting query from Health Storage
        // async
        let query = HKSampleQuery(
            sampleType: type!,
            predicate: pred, //查詢區間
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [timeSort]
        
        ){ (query, results, error) in // closure
            
            var steps: Double = 0
            if error == nil && results!.count > 0 {
                // callback function
                for quantitySample in results as! [HKQuantitySample]{
                    steps += quantitySample.quantity.doubleValue(for: HKUnit.count())
                }
                print("當天步數: \(steps)")
                
                completion(steps)
            }
            else{
                print("getStepCount err")
            }
        }
        // Do query
        health.execute(query)
    }
    
    func getDistanceWithDate(_ date:Date, completion: @escaping (Double) -> () ){
        let type = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        
        let pred:NSPredicate = self.predicateForSamplesWithDate(date)
        
        let timeSort:NSSortDescriptor = NSSortDescriptor.init(key: HKSampleSortIdentifierEndDate, ascending: false)
        // Setting query from Health Storage
        // async
        let query = HKSampleQuery(
            sampleType: type!,
            predicate: pred, //查詢區間
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [timeSort]
            
        ){ (query, results, error) in // closure
            
            var distance: Double = 0
            if error == nil && results!.count > 0 {
                // callback function
                for quantitySample in results as! [HKQuantitySample]{
                    distance += quantitySample.quantity.doubleValue(for: HKUnit.meterUnit(with: .kilo) )
                }
                print("當天距離: \(distance)")
                completion(distance)
            }
            else{
                print("getDistance err")
            }
        }
        // Do query
        health.execute(query)
    }
    
    func styleViewCard(setView view:UIView, withColor color:CGColor){
        
        // set the shadow of the view's layer
        view.layer.backgroundColor = color
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 15, height: 15)
        view.layer.shadowOpacity = 0.8
        view.layer.shadowRadius = 4.0
        view.layer.borderColor = UIColor.black.cgColor
        // set the cornerRadius of the containerView's layer
        view.layer.cornerRadius = 7.0
        view.layer.masksToBounds = true
    }    
    
    @IBAction func aboutBtnClicked(_ sender: Any) {
        let vc = SFSafariViewController(url: URL(string: "https://kueiapp.com")!)
        show(vc, sender: self)
    }
    

}//class


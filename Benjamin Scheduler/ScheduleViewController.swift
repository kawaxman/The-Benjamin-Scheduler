//
//  ScheduleViewController.swift
//  Benjamin Scheduler
//
//  Created by Blake Henderson on 8/6/15.
//  Copyright © 2015 Blake Henderson. All rights reserved.
//

import Foundation
import UIKit

class ScheduleViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var className: NSMutableArray! = NSMutableArray()
    var times: NSMutableArray! = NSMutableArray()

    
    var genericSchedule: NSMutableArray! = NSMutableArray()
    var finalSchedule: NSMutableArray! = NSMutableArray();
    var refreshControl:UIRefreshControl!
    var statusCode: Int = 0
    
    override func viewDidLoad() {
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: "refresh:", forControlEvents: UIControlEvents.ValueChanged)
        self.tableView.addSubview(refreshControl)
        
        print("Get Schedule...")
        scheduleAPI(passUserID)
        print("Get Times...")
        timeAPI()
        print("Get Generic Schedule")
        genericScheduleAPI()
        print("Get Student Schedule")
        parseStudentSchedule()
        print(finalSchedule)
        print("Done")
    }
    
    func scheduleAPI(username: String){
        let semaphore = dispatch_semaphore_create(0);
        let urlPath = "https://benjaminscheduler.com/api/?getStudentScheduleKey=sh45Fd2sda2s&&benjaminID=\(username)" //Login URL (API)
        let url: NSURL = NSURL(string: urlPath)!
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithURL(url, completionHandler: {data, response, error -> Void in
            var error: NSError?
            if error != nil { //Check if there is a error in the network
                if error!.localizedDescription == networkError {
                    self.statusCode = 400
                    print("Network Error: Code -1009")
                    dispatch_semaphore_signal(semaphore)
                    return
                }
            }
            do {
                let jsonData = try NSJSONSerialization.JSONObjectWithData(data!, options:NSJSONReadingOptions.MutableContainers ) as! NSDictionary
                var scheduleData:NSMutableArray! = NSMutableArray()
                scheduleData.addObject(jsonData["data"]!)
                for(var i = 1; i <= scheduleData[0].count-1; i++){
                    self.className.addObject(scheduleData[0][i])
                }
                dispatch_semaphore_signal(semaphore)
            }
            catch {
                // report error
            }
        })
        task.resume()
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    }
    
    func timeAPI(){
        let semaphore = dispatch_semaphore_create(0);
        let urlPath = "https://benjaminscheduler.com/api/?getScheduleTimeKey=ksDvn391Zsg7" //Time URL (API)
        let url: NSURL = NSURL(string: urlPath)!
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithURL(url, completionHandler: {data, response, error -> Void in
            var error: NSError?
            if error != nil { //Check if there is a error in the network
                if error!.localizedDescription == networkError {
                    self.statusCode = 400
                    print("Network Error: Code -1009")
                    dispatch_semaphore_signal(semaphore)
                    return
                }
            }
            do {
                let jsonData = try NSJSONSerialization.JSONObjectWithData(data!, options:NSJSONReadingOptions.MutableContainers ) as! NSDictionary
                var timeData:NSMutableArray! = NSMutableArray()
                timeData.addObject(jsonData["data"]!)
                for(var i = 0; i < timeData[0].count; i++){
                   
                    self.times.addObject(timeData[0][i])
                }
                dispatch_semaphore_signal(semaphore)
            }
            catch {
                // report error
            }
        })
        task.resume()
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    }
    
    func genericScheduleAPI(){
        let semaphore = dispatch_semaphore_create(0);
        let urlPath = "http://benjaminscheduler.com/api/?getGenericScheduleKey=kyF4592Dcbfe" //Time URL (API)
        let url: NSURL = NSURL(string: urlPath)!
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithURL(url, completionHandler: {data, response, error -> Void in
            var error: NSError?
            if error != nil { //Check if there is a error in the network
                if error!.localizedDescription == networkError {
                    self.statusCode = 400
                    print("Network Error: Code -1009")
                    dispatch_semaphore_signal(semaphore)
                    return
                }
            }
            do {
                let jsonData = try NSJSONSerialization.JSONObjectWithData(data!, options:NSJSONReadingOptions.MutableContainers ) as! NSDictionary
                    self.genericSchedule.addObject(jsonData["data"]!)
                dispatch_semaphore_signal(semaphore)
            }
            catch {
                // report error
            }
        })
        task.resume()
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    }
    
    func parseStudentSchedule(){
        let periods = ["A", "B", "C", "D", "E", "F", "G"]
        var schedule = genericSchedule[0] as! String
        if schedule == "No School" {
            self.finalSchedule.addObject(schedule);
            self.times = [];
        }
        else{
            for(var j = 0; j < schedule.characters.count; j++){
                var selectedPeriod = schedule[schedule.startIndex.advancedBy(j)]
                print(selectedPeriod)
                for(var i = 0; i <= 6; i++){
                    if(periods[i].characters.contains(selectedPeriod)){
                        self.finalSchedule.addObject(className[i] as! String)
                    }
                }
            }
        }
    }
    
    func refresh(sender:AnyObject)
    {
        className.removeAllObjects()
        times.removeAllObjects()
        genericSchedule.removeAllObjects()
        finalSchedule.removeAllObjects()
        scheduleAPI(passUserID)
        timeAPI()
        genericScheduleAPI()
        parseStudentSchedule()
        self.tableView.reloadData()
        self.refreshControl.endRefreshing()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.finalSchedule.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        
        let cell = self.tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! TableViewCell
        
        cell.textLabel?.text = finalSchedule[indexPath.row] as? String
        
        if(times.count != 0){
            cell.detailTextLabel?.text = times[indexPath.row] as? String
        }
        else {
            cell.detailTextLabel?.text = "All-Day"
        }
        return cell
        
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        self.performSegueWithIdentifier("showView", sender: self)
        
    }

    
    
    
}
//
//  EntriesVC.swift
//  Writing App
//
//  Created by Sten Golds on 11/23/16.
//  Copyright © 2016 Sten Golds. All rights reserved.
//

import UIKit
import CoreData

class EntriesVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    //properties that connect table view and settings bar button items in code to storyboard view
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var settingsBarItem: UIBarButtonItem!
    
    //stores retrieved entry items from Core Data
    var entries = [Entry]()
    
    override func viewWillAppear(_ animated: Bool) {
        
        //gets saved entries, sorted by most recent to least
        fetchEntries()
        
        //sets proper size for settings icon on navigation bar
        navBarPrep()
        
        //reload tableView as entries array has been filled
        tableView.reloadData()
    }
    

    // MARK: - Navigation
    
    /**
     * @name prepare for segue
     * @desc prepares app to switch to a new view controller
     * @param UIStoryBoardSegue segue - transition segue to specific view
     * @param Any sender - sender item, used to send next storyboard an Entry
     * @return void
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        //if app is switching to the Entry ViewController
        if segue.identifier == "toEntry" {
            
            //cast destination viewController as EntryVC, used to set passed Entry
            if let destination = segue.destination as? EntryVC {
                
                //if an Entry was selected, set the destination ViewController's associated Entry to the selected entry
                if let entry = sender as? Entry {
                    destination.sentEntry = entry
                }
            }
        }
    }
    
    
    // MARK: - TableView methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        //only want one section
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //want one row per one post to display
        //return entries.count
        return entries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //get entry at given row
        let entry = entries[indexPath.row]
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "entryCell") as? EntryCell { //dequeue a reusable cell as EntryCell, continue on success
            
            //configure the dequeued EntryCell to conform to the data of the post associated with this row
            cell.configCell(entry: entry)
            
            //return the configured cell
            return cell
        } else { //if a dequeued cell couldn't be cast as a EntryCell, create a new EntryCell
            return EntryCell()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        //sets larger tableView cells if app is running on an iPad
        if(UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad) {
            return 150
        } else {
            return 100
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //store selected cell
        let cell = tableView.cellForRow(at: indexPath) as! EntryCell
        
        //cell has been completely selected, so highlighting of cell is stopped
        cell.isSelectedView.isHidden = true
        
        //get Entry associated with selected cell
        let toSendEntry = entries[indexPath.row]
        
        //transition to Entry ViewController
        performSegue(withIdentifier: "toEntry", sender: toSendEntry)
        
        //deselect cell as work has been done, and view is switching
        tableView.deselectRow(at: indexPath as IndexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        //get cell user is touching
        let cell = tableView.cellForRow(at: indexPath) as! EntryCell
        
        //show cell is currently being selected
        cell.isSelectedView.isHidden = false
    }
    
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        //get cell user was touching, but now released from
        let cell = tableView.cellForRow(at: indexPath) as! EntryCell
        
        //show that cell is no longer being selected
        cell.isSelectedView.isHidden = true
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        //allow users to edit their saved entries list
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        //allow user to delete an Entry from their saved list
        if editingStyle == .delete {
            
            //delete the selected Entry from Core Data
            context.delete(entries[indexPath.row])
            
            //remove the selected Entry from the entries array
            entries.remove(at: indexPath.row)
            
            //attempt to save changes to Core Data
            do {
                try context.save()
            } catch {
                _ = error as NSError
                print(error)
            }
            
            //reflect deletition in tableView
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    
    // MARK: - Helper Methods
    
    /**
     * @name fetchEntries
     * @desc gets saved Entry items from Core Data, and saved them to the entries array
     * @return void
     */
    func fetchEntries() {
        
        //create request for Entry items from Core Data
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        
        //sort by most recent
        let dateSort = NSSortDescriptor(key: "date", ascending: false)
        fetchRequest.sortDescriptors = [dateSort]

        
        //attempt to retrieve items, if retrieved, save them to entries array
        do {
            
            entries = try context.fetch(fetchRequest)
            
        } catch {
            
            _ = error as NSError
            
        }
    }
    
    /**
     * @name navBarPrep
     * @desc set width of the settings navigation item to be equal to the navigation bar's height, therefor making it a square
     * @return void
     */
    func navBarPrep() {
        if let navBar = self.navigationController?.navigationBar {
            settingsBarItem.width = navBar.frame.height
        }
    }

}

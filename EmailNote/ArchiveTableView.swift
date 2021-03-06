//
//  ArchiveTableView.swift
//  EmailNote
//
//  Created by Brett Meyer on 3/6/18.
//  Copyright © 2018 Brett Meyer. All rights reserved.
//

import UIKit

class ArchiveTableView: UITableView, UITableViewDelegate, UITableViewDataSource {

    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count: Int
        if let notes = Settings.archive {
            count = notes.count
        } else {
            count = 0
        }
        print(count)
        return count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        self.tableView.register(ArchiveTableViewCell.self, forCellReuseIdentifier: "noteCell")
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "noteCell", for: indexPath) as! ArchiveTableViewCell
        
        if let noteArray = Settings.archive {
            let count = noteArray.count
            cell.noteLabel?.text = noteArray[count - 1 - indexPath.row].message
            cell.subLabel?.text = noteArray[count - 1 - indexPath.row].time
        }
        
        return cell
    }
    
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */

}

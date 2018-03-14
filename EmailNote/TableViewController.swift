//
//  TableViewController.swift
//  EmailNote
//
//  Created by Brett Meyer on 12/30/17.
//  Copyright © 2017 Brett Meyer. All rights reserved.
//

import UIKit

//class ArchiveTableViewCell: UITableViewCell {
//    @IBOutlet weak var noteLabel: UILabel!
//    @IBOutlet weak var subLabel: UILabel!
//}

class TableViewController: UITableViewController {
    @IBOutlet weak var settingsButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

//        settingsButton.tintColor = UIColor.black
//        navigationController?.navigationBar.barTintColor = UIColor.white
//        navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.black]
//        navigationController?.navigationBar.tintColor = UIColor.black
//        UIApplication.shared.statusBarStyle = UIStatusBarStyle.default
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        settingsButton.isEnabled = false
        settingsButton.isEnabled = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count: Int
        if let notes = Settings.archive {
            count = notes.count
        } else {
            count = 0
        }
        return count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        self.tableView.register(ArchiveTableViewCell.self, forCellReuseIdentifier: "noteCell")

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

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        handleViewTransition()
    }
    @IBAction func backButtonPressed(_ sender: Any) {
        handleViewTransition()
        self.navigationController?.popViewController(animated: true)
    }
    
    func handleViewTransition() {
//        self.navigationController?.navigationBar.barTintColor = UIColor.black
//        self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
//        self.navigationController?.navigationBar.tintColor = UIColor.white
//        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
    }
}

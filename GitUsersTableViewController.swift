//
//  GitUsersTableViewController.swift
//  GithubUsers
//
//  Created by Alex on 27.09.16.
//  Copyright © 2016 Alex. All rights reserved.
//

import UIKit

class GitUsersTableViewController: UITableViewController {

    var visibleUsers = [[String:AnyObject]?]() {
        didSet {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadData()
            })
        }
    }
    
    var users = [[String:AnyObject]?]() {
        didSet {
            visibleUsers = users
            if users.count < Constants.minUsers {fetchUsers ()}
        }
    }
    
    let searchController = UISearchController(searchResultsController: nil)
    var session: NSURLSession!
    var cache:NSCache!
    
    let defaultSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
    var dataTask: NSURLSessionDataTask?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        session = NSURLSession.sharedSession()
        fetchUsers ()
        setUpSearchController ()
        cache = NSCache()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        searchController.searchBar.text = ""
    }
    
    private struct Constants {
        static let minUsers = 100
        static let firstId = 0
    }
    
    private func setUpSearchController () {
        searchController.searchBar.showsCancelButton = false
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.sizeToFit()
        searchController.searchBar.searchBarStyle = .Minimal
        searchController.searchBar.barTintColor = UIColor.blackColor()
        searchController.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
        let textFieldInsideSearchBar = searchController.searchBar.valueForKey("searchField") as? UITextField
        textFieldInsideSearchBar?.textColor = UIColor.blackColor()
        navigationItem.titleView = searchController.searchBar
    }
    
    func fetchUsers () {
        let requestURL = NSURL(string: "https://api.github.com/users?since=\(users.count == 0 ? Constants.firstId : users[users.count-1]!["id"]!)")! // Fetching from the last id in array.
        let urlRequest = NSMutableURLRequest(URL: requestURL)
        let task = session.dataTaskWithRequest(urlRequest) {
            (data, response, error) -> Void in
            
            let httpResponse = response as! NSHTTPURLResponse
            let statusCode = httpResponse.statusCode
            
            if statusCode == 200 {
                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options:.AllowFragments) as! NSArray
                    self.users.appendContentsOf(json.map{$0 as? [String:AnyObject]})
                }catch {
                    print("Error with Json: \(error)")
                }
            }
        }
        task.resume()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return visibleUsers.count
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return createUserCell (indexPath)
    }
    
    func createUserCell (indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! UserCell
        cell.nameLabel.text = visibleUsers[indexPath.row]?["login"] as? String
        cell.urlLabel.text = visibleUsers[indexPath.row]?["url"] as? String
        cell.urlLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        cell.urlLabel.numberOfLines = 2
        cell.logo.image = UIImage(named: "default-avatar")
        cell.logo.layer.cornerRadius = cell.logo.bounds.width/2
        cell.logo.layer.masksToBounds = true
        cell.cache = self.cache
        cell.session = self.session
        cell.dowloadImageFor(indexPath, from: visibleUsers[indexPath.row]?["avatar_url"] as! String)
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func searchUser(query: String) {
        NSObject.cancelPreviousPerformRequestsWithTarget(self)
        visibleUsers = query == "" ? users : users.filter{($0!["login"] as! String).lowercaseString.containsString (query.lowercaseString)}
        tableView.reloadData()
    }
   
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let imageVC = segue.destinationViewController as? LargeImageViewController {
            let indexPath = tableView.indexPathForSelectedRow
            let url = visibleUsers[indexPath!.row]!["avatar_url"] as! String
            imageVC.image = cache.objectForKey(url) as? UIImage
            imageVC.name = visibleUsers[indexPath!.row]?["login"] as? String
        }
    }
    
}

extension GitUsersTableViewController: UISearchResultsUpdating, UISearchControllerDelegate {
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        let query = (searchController.searchBar.text ?? "").stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        NSObject.cancelPreviousPerformRequestsWithTarget(self)
        performSelector(#selector(GitUsersTableViewController.searchUser(_:)), withObject: query, afterDelay: 0.5)
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        let query = (searchController.searchBar.text ?? "").stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        searchUser(query)
    }
}

class UserCell: UITableViewCell {
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    
    var cache: NSCache!
    var downloadTask = NSURLSessionDownloadTask()
    var session: NSURLSession!
    
    func dowloadImageFor (indexPath: NSIndexPath, from url: String) {
        if self.cache.objectForKey(url) != nil {
            logo?.image = self.cache.objectForKey(url) as? UIImage
        } else {
            
            let avatarUrl = NSURL(string: url)!
            downloadTask = session.downloadTaskWithURL(avatarUrl, completionHandler: { (location, response, error) -> Void in
                if let data = NSData(contentsOfURL: avatarUrl){
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        let img = UIImage(data: data) ?? UIImage(named: "default-avatar")!
                        self.logo?.image = img
                        self.cache.setObject(img, forKey: url)
                    })
                }
            })
            downloadTask.resume()
        }
    }
}

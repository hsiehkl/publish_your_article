//
//  UserArticlesController.swift
//  chatTogther
//
//  Created by Aries Yang on 2017/11/26.
//  Copyright © 2017年 Susu Liang. All rights reserved.
//

import UIKit
import Firebase

class UserArticlesController: UITableViewController {

    var articles: [Article] = []
    var articleKeys: [String] = []
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(sendNew))
        
        checkLoggedIn()
        
        tableView.register(PublishArticleCell.self, forCellReuseIdentifier: "articleCell")

        Database.database().reference().observe(.value) { (snapshot) in
            self.articles = []
            guard let userid = Auth.auth().currentUser?.uid else { return }
            
            if let objects = snapshot.children.allObjects as? [DataSnapshot] {
                for object in objects {
                    if let users = object.value as? [String: AnyObject],
                        let currentUser = users[userid],
                        let firstname = currentUser["firstName"] as? String,
                        let lastname = currentUser["lastName"] as? String,
                        let articles = currentUser["articles"] as? NSDictionary {
                        guard let keys = articles.allKeys as? [String] else { return }
                        self.articleKeys = keys
                        for key in keys {
                            guard
                                let theArticle = articles[key] as? [String: String],
                                let title = theArticle["title"],
                                let content = theArticle["content"],
                                let date = theArticle["date"]
                            else { return }
                            
                            let dateFormatter = DateFormatter()
                            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                            guard let trueDate = dateFormatter.date(from: date)
                            else {
                                return
                            }
                            self.articles.sort() { $0.date > $1.date }
                            self.articles.insert(Article(id: key, title: title, content: content, date: trueDate, author: firstname + " " + lastname), at: 0)
                        }
                        self.tableView.reloadData()
                        
                    }
                }
            }
        }
    }

    @objc func sendNew() {
        let publishViewController = PublishViewController()
        present(publishViewController, animated: true, completion: nil)
    }
    
    func checkLoggedIn() {
        if Auth.auth().currentUser?.uid == nil {
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
        } else {
            let uid = Auth.auth().currentUser?.uid
            Database.database().reference().child("users").child(uid!).observe(.value, with: { (snapshot) in
                if let dictionary = snapshot.value as? [String: Any],
                    let firstName = dictionary["firstName"] as? String,
                    let lastName = dictionary["lastName"] as? String {
                    self.navigationItem.title = firstName + " " + lastName
                }
            })
        }
    }
    
    @objc func handleLogout() {
        
        do {
            try Auth.auth().signOut()
        } catch let logoutError {
            print(logoutError)
        }
        
        let loginController = LoginController()
        present(loginController, animated: true, completion: nil)
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return articleKeys.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        cell.textLabel?.text = articles[indexPath.row].title
        cell.detailTextLabel?.text = articles[indexPath.row].author + "   " + "\(articles[indexPath.row].date)"
        return cell
    }
}
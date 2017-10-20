
import UIKit
import Cartography

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var addGroupView: UIView!
    @IBOutlet weak var addListButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var allTodoCountLabel: UILabel!
    
    let cellId = "cellId"
    var todoGroups = [TGroup]()
    
    
    let apiService = ApiService.shared
    
    let profileImageView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFill
        v.layer.cornerRadius = 20
        v.image = #imageLiteral(resourceName: "cat-profile")
        return v
    }()
    
    let userNameLabel: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFont(ofSize: 15)
        v.text = "SongHeeWung"
        return v
    }()
    
    lazy var refrshCtrl: UIRefreshControl = {
        let c = UIRefreshControl()
        c.attributedTitle = NSAttributedString(string: "당겨서 새로고침")
        c.addTarget(self, action: #selector(self.refreshAction), for: UIControlEvents.valueChanged)
        return c
    }()
    
    var isRequsting = false
    var effect: UIVisualEffect!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        addListButton.isHidden = true
        
        
        setTitleView()
        
        let searchBarItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(loadTodos))
        let addBarItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(moveAddGroup))
        navigationItem.rightBarButtonItems = [searchBarItem, addBarItem]
        
        tableView.refreshControl = refrshCtrl
        
        addListButton.addTarget(self, action: #selector(createTodoGroupAction), for: .touchUpInside)
        
        loadTodos()
    }
    
    func moveAddGroup(){
        let vc = UIStoryboard(name: "CreateGroup", bundle: nil).instantiateInitialViewController() as! CreateGroupViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func animateIn(){
        //view.bringSubview(toFront: visualEffectView)
        view.addSubview(addGroupView)
        
        addGroupView.center = view.center
        addGroupView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
        addGroupView.alpha = 0
        
        
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: { 
            //self.visualEffectView.effect = self.effect
            self.addGroupView.alpha = 1
            self.addGroupView.transform = CGAffineTransform.identity
        }, completion: nil)
    }

    func refreshAction(_ ctrl: UIRefreshControl){
        ctrl.beginRefreshing()
        loadTodos()
    }
    
    func loadTodos(){
        guard !isRequsting else {
            self.refrshCtrl.endRefreshing()
            return
        }
        
        print("connecting")
        isRequsting = true
        apiService.getGroups { (success, groups, totalTodos) in
            if success, let g = groups {
                self.todoGroups = g
                DispatchQueue.main.async {
                    self.allTodoCountLabel.text = "\(totalTodos)"
                    self.tableView.reloadData()
                }
            }
            print("finishing")
            self.isRequsting = false
            self.refrshCtrl.endRefreshing()
        }
    }

    func setTitleView(){
        let titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: 200, height: 42)
        //titleView.backgroundColor = .red
        
        titleView.addSubview(profileImageView)
        titleView.addSubview(userNameLabel)
        //navigationItem.titleView = titleView
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleView)
        
        constrain(titleView, profileImageView, userNameLabel) { (tv, iv, name) in
            iv.left == tv.left
            iv.centerY == tv.centerY
            iv.width == 40
            iv.height == 40
            
            name.left == iv.right + 5
            name.right == tv.right
            name.centerY == tv.centerY
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return todoGroups.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! TodoListTableViewCell
        
        let currentTG = todoGroups[indexPath.row]
        
        cell.titleLabel.text = currentTG.title
        cell.todoCountLabel.text = "\(currentTG.count!)"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let currentTG = todoGroups[indexPath.row]
        let vc = UIStoryboard(name: "Todo", bundle: nil).instantiateInitialViewController() as! TodoViewController
        
        vc.todoGroup = currentTG
        
        navigationController?.pushViewController(vc, animated: true)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func createTodoGroupAction(_ button: UIButton){
        //button.isEnabled = false
        
        animateIn()
    }
    
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAcation = UITableViewRowAction(style: .destructive, title: "삭제") { (action, indexPath) in

            guard let id = self.todoGroups[indexPath.row].id else {return}
            
            self.apiService.deleteGroup(id: id, completion: { (success) in
                if success {
                    self.todoGroups.remove(at: indexPath.row)
                    DispatchQueue.main.async {
                        self.tableView.beginUpdates()
                        self.tableView.deleteRows(at: [indexPath], with: .automatic)
                        self.tableView.endUpdates()
                    }
                }
            })
        }
        
        return [deleteAcation]
    }
}


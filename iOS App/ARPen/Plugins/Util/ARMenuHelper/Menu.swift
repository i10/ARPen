class Menu {
    
    var subMenus: [Menu] = []
    var path: [Int] = [] {
        didSet { updatePathsForSubmenus() }
    }
    
    var label: String
    
    
    var count: Int {
        get { return subMenus.count }
    }
    
    init(label: String = "") {
        self.label = label
    }
    
    convenience init(label: String = "", subMenus: Menu...){
        self.init(label: label)
        for menu in subMenus { addSubmenus(submenus: menu) }
    }
    
    convenience init(label: String = "", leafs: String...){
        self.init(label: label)
        for leaf in leafs { addLeafs(leafs: leaf) }
    }
    
    convenience init(label: String = "", leafs: [String]){
        self.init(label: label)
        for leaf in leafs { addLeafs(leafs: leaf) }
    }
    
    func addSubmenus(submenus: Menu...) {
        for submenu in submenus {
            var path = self.path
            path.append(self.subMenus.count)
            path.append(contentsOf: submenu.path)
            submenu.path = path
            self.subMenus.append(submenu)
        }
    }
    
    func addSubmenus(submenus: [Menu]) {
        for submenu in submenus {
            var path = self.path
            path.append(self.subMenus.count)
            path.append(contentsOf: submenu.path)
            submenu.path = path
            self.subMenus.append(submenu)
        }
    }
    
    func addLeafs(leafs: String...){
        for leaf in leafs { addSubmenus(submenus: Menu(label: leaf)) }
    }
    
    func addLeafs(leafs: [String]){
        for leaf in leafs { addSubmenus(submenus: Menu(label: leaf)) }
    }
    
    private func updatePathsForSubmenus(){
        for (i, submenu) in self.subMenus.enumerated() {
            var path = self.path
            path.append(i)
            submenu.path = path
        }
    }
    
    var isLeaf: Bool {
        get{ return subMenus.isEmpty }
    }
    
    func getMenuWithPath(path: [Int]) -> Menu{
        if path.isEmpty {
            return self
        } else {
            var newPath = path
            let index = newPath.remove(at: 0)
            return subMenus[index].getMenuWithPath(path: newPath)
        }
        
    }
    
    
}

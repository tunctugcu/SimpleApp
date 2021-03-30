//
//  ViewController.swift
//  SimpleApp
//
//  Created by Tunc Tugcu on 27.03.2021.
//

import UIKit

final class ViewController: UIViewController {
    
    @IBOutlet private weak var tableView: UITableView!
    
    @IBOutlet private weak var emptyLabel: UILabel!
    
    private let refreshControl = UIRefreshControl()
    
    private enum Section: Int { case people }
    
    private var isLoading = false {
        didSet {
            if oldValue != isLoading {
                if !isLoading {
                    refreshControl.endRefreshing()
                }
            }
        }
    }
    
    private var nextStr: String?
    
    private var dataSource: UITableViewDiffableDataSource<Section, PersonPresentation>!
    
    private var snapshot: NSDiffableDataSourceSnapshot<Section, PersonPresentation> = NSDiffableDataSourceSnapshot() {
        didSet {
            handleEmpty()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        handleEmpty()
        
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
        tableView.addSubview(refreshControl)
        
        dataSource = UITableViewDiffableDataSource(tableView: tableView,
                                                   cellProvider: { (tableView, indexPath, model) -> UITableViewCell? in
                                                    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
                                                    cell.textLabel?.text = model.text
                                                    
                                                    return cell
                                                    
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @objc private func refresh() {
        guard refreshControl.isRefreshing else { return }
        
        if !snapshot.sectionIdentifiers.isEmpty {
            snapshot.deleteAllItems()
            dataSource.apply(snapshot)
        }
        
        self.fetchNext()
    }
    
    private func handleEmpty() {
        if snapshot.itemIdentifiers.isEmpty {
            emptyLabel.isHidden = false
            tableView.separatorStyle = .none
        } else {
            emptyLabel.isHidden = true
            tableView.separatorStyle = .singleLine
        }
    }
    
    private func fetchNext() {
        guard !isLoading else {
            print("App is already loading...")
            
            return
        }
        self.isLoading = true
        DataSource.fetch(next: nextStr) { [weak self] (response, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.isLoading = false
                self.showFetchError(error)
                
                return
            }
            
            guard let response = response else {
                fatalError("Response and error not found!")
            }
            
            
            self.applySnapshotWithPeople(response.people) {
                self.nextStr = response.next
                if self.isLastCellOnScreen() {
                    self.isLoading = false
                    self.fetchNext()
                } else {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func showFetchError(_ error: FetchError) {
        let alertController = UIAlertController(title: "Error", message: error.errorDescription, preferredStyle: .alert)
        
        let retryAction = UIAlertAction(title: "Retry", style: .default) { (action) in
            self.fetchNext()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(retryAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
    
    private func applySnapshotWithPeople(_ people: [Person], completion: @escaping () -> Void) {
        guard !people.isEmpty else { return }
        
        var presentations = [PersonPresentation]()
        
        for person in people {
            let item = PersonPresentation(person: person)
            
            if !snapshot.itemIdentifiers.contains(item) {
                presentations.append(item)
            }
        }
        
        if !snapshot.sectionIdentifiers.contains(.people) {
            snapshot.appendSections([.people])
        }
        
        snapshot.appendItems(presentations, toSection: .people)
        
        dataSource.apply(snapshot, animatingDifferences: false, completion: completion)
    }
}


// MARK: - TableView delegate
extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard
            !isLoading,
            let lastIndexPath = getLastIndexPath(),
            indexPath == lastIndexPath
        else { return }
        
        self.fetchNext()
    }
}


// MARK: - Helpers
extension ViewController {
    private func isLastCellOnScreen() -> Bool {
        
        guard let indexPath = getLastIndexPath() else {
            return false
        }
        
        
        return tableView.indexPathsForVisibleRows?.contains(indexPath) ?? false
        
    }
    
    private func getLastIndexPath() -> IndexPath? {
        let lastSection = tableView.numberOfSections - 1
        
        guard lastSection >= 0 else {
            
            return nil
        }
        
        let lastRow = tableView.numberOfRows(inSection: lastSection) - 1
        
        guard lastRow >= 0 else {
            return nil
        }
        
        return IndexPath(row: lastRow, section: lastSection)
    }
}


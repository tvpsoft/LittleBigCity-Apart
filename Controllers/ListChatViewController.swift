//
//  ListChatViewController.swift
//  LittleBigCity
//
//  Copyright © 2016 Viet Phuong Tran. All rights reserved.
//

import UIKit
import RealmSwift
import Siesta
import SwiftyJSON

class ListChatViewController: UIViewController, ResourceObserver {
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var placeHolderView: UIView!
    
    var loader = SBAnimatedLoaderView(_backgroundColor: ColorLBC.DARK_COLOR, _frame: CGRectMake(0, 0, screenWidth, screenHeight ), _width:45)
    
    var dataCollection: Resource? {
        didSet {
            oldValue?.removeObservers(ownedBy: self)
            dataCollection?.addObserver(self)
            
        }
    }
    
    let _emptyContent = EmptyDiscussion()
    let _emptyConnection = EmptyConnection()
    
    var arrDiscussions = Results<Discussion>?()

    var currentUser:User?
    var currentPage : Int = 1
    var isLoading = false
    
    var refreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register cell for collection view
        collectionView.register(PDiscussionCollectionViewCell)
        collectionView.register(PDiscussionChannelCollectionViewCell)
        
        self.currentUser = User().getCurrentUser()
        
        self.dataCollection = LbcPushAPI.discussionList
        self.collectionView.addSubview(loader)
        loader.show()
        self.dataCollection?.load(usingRequest: self.dataCollection!.request(.POST, json: [ "userId" : (currentUser?.id)!, "channel":1]))
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.tintColor = UIColor.whiteColor()
        self.refreshControl.addTarget(self, action: #selector(ListChatViewController.reloadChatList), forControlEvents: UIControlEvents.ValueChanged)
        self.collectionView.addSubview(self.refreshControl)

        //Empty content
        self.placeHolderView.addSubview(_emptyContent)
        _emptyContent.layoutSubviews()
        _emptyContent.frame = CGRectMake(0, 0, screenWidth, screenHeight)
        _emptyContent.hidden = true
        
        
        //Empty connection
        self.collectionView.addSubview(_emptyConnection)
        _emptyConnection.layoutSubviews()
        _emptyConnection.frame = CGRectMake(0, 0, screenWidth, screenHeight)
        _emptyConnection.hidden = true
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ListChatViewController.reloadChatList), name: "reloadChatList", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ListChatViewController.reloadChatList), name: "refreshConnection", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ListChatViewController.reloadChatListData), name: "reloadChatListData", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ListChatViewController.openPublicChannel), name: "openPublicChannel", object: nil)
        
    }
    
    func reloadChatListData(){
        self.collectionView.reloadData()
    }
    
    func reloadChatList(){
        self.collectionView.setContentOffset(CGPoint.zero, animated: false)
        
        self.dataCollection = LbcPushAPI.discussionList
        self.dataCollection?.load(usingRequest: self.dataCollection!.request(.POST, json: [ "userId" : (self.currentUser?.id)!, "channel":1]))
    }
    
    func resourceRequestProgress(resource: Resource, progress: Double) {
        _emptyConnection.hidden = true
    }
    
    func resourceChanged(resource: Resource, event: ResourceEvent) {
        if case .NewData = event {
            loader.hide()
            if((resource.latestData) != nil){
                //Save data to Realm
                if(resource.jsonDict.count > 0){
                    Discussion().saveValueFromJSON(resource.json["getList"])

                }
                
                arrDiscussions = Discussion().getList()
                
                self.isLoading = false
                self.refreshControl.endRefreshing()
                collectionView.reloadData()
                
                
                if(arrDiscussions!.count == 0)
                {
                    _emptyContent.hidden = false
                    placeHolderView.hidden = false
                }else{
                    _emptyContent.hidden = true
                    placeHolderView.hidden = true
                }
                
            }
        }
        
        if case .Error = event {
            loader.hide()
            if(resource.latestError != nil){
                self.refreshControl.endRefreshing()
                self.isLoading = false
                //Show error here
                if(Reachability.isConnectedToNetwork() == true ){
                    
                }else{
                    
                    // Show emptyConnection
                    _emptyConnection.hidden = false
                }

            }
        }
    }
}



//Bind data
extension ListChatViewController: UICollectionViewDataSource {
    
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        let _unread = Discussion().getNumberUnread()
        // Show the bubble
        NSNotificationCenter.defaultCenter().postNotificationName("changeChatImage", object: ["data": _unread])
        arrDiscussions = Discussion().getList()
        return arrDiscussions!.count
        
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        
        let _data = arrDiscussions![indexPath.row]
        if(_data.id == 1){
            let cell = collectionView.dequeueReusableCell(forIndexPath: indexPath) as PDiscussionChannelCollectionViewCell
            cell.setValueDisplay(_data)
            return cell
        }else{
            let cell = collectionView.dequeueReusableCell(forIndexPath: indexPath) as PDiscussionCollectionViewCell
            cell.setValueDisplay(_data)
            return cell
        }
        
    }
    
    
    //Use for size
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let _data = arrDiscussions![indexPath.row]
        if(_data.id == 1){
            //TODO @Tom: change the height of public channel here
            return CGSize(width: screenWidth, height: 180)
        }else{
            return CGSize(width: screenWidth, height: 75)
        }
        
    }
    
    //Use for interspacing
    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
            return 0.0
    }
    
    func collectionView(collectionView: UICollectionView, layout
        collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
            return 0.0
    }
    
    
    func openPublicChannel(){
        let chatController = storyboardMain.instantiateViewControllerWithIdentifier("chatScreen") as! DetailChatViewController
        chatController.discussion = self.arrDiscussions![0]
        
        self.navigationController?.pushViewController(chatController, animated: true)
    
    }
    
    
}


extension ListChatViewController: UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let chatController = storyboardMain.instantiateViewControllerWithIdentifier("chatScreen") as! DetailChatViewController
        chatController.discussion = self.arrDiscussions![indexPath.row]
        
        self.navigationController?.pushViewController(chatController, animated: true)
    }
    
    
}

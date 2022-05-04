/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//////////////////////////////////////////////////////////
//     __ __                     __  ___         __     //
//    / //_/__  ___  ___ ____   /  |/  /__ _____/ /_    //
//   / ,< / _ \/ _ \/ _ `/_ /  / /|_/ / _ `/ __/ __/    //
//  /_/|_|\___/_//_/\_, //__/ /_/  /_/\_,_/_/  \__/     //
//                 /___/                                //
//                               by 0xInuarashi.eth     //
//////////////////////////////////////////////////////////

/*

    KongzMart is a special Marketplace Contract created by 0xInuarashi.eth for
    CyberKongz. It uses ERC1155 safeTransferFrom to burn PNK assets to acquire
    whitelists.

*/

// TEST VERSION

abstract contract Ownable {
    address public owner; 
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    function transferOwnership(address new_) external onlyOwner { owner = new_; }
}

interface IERC1155 {
    function balanceOf(address address_, uint256 id_) external view returns (uint256);
    function safeTransferFrom(address from_, address to_, uint256 id_,
    uint256 amount_, bytes calldata data_) external;
}

interface IERC721 {
    function balanceOf(address address_) external view returns (uint256);
}

contract KongzMartTest is Ownable {

    ///// Structs /////
    struct VendingItem {
        string title; // for metadata uri usage, set title to metadata uri instead
        string imageUri;
        string projectUri;
        string description;

        uint32 amountAvailable;
        uint32 amountPurchased;

        uint32 startTime;
        uint32 endTime;

        uint32 tokenId;
        uint32 tokenPrice;
    }

    ///// Events /////
    event TreasuryManaged(address indexed owner_, address treasury_);
    event RequireOwnershipManaged(address indexed owner_, bool bool_);
    
    event GovernorManaged(address indexed owner_, address governor_, bool bool_);
    event OperatorManaged(address indexed owner_, address operator_, bool bool_);

    event VendingItemAdded(address indexed owner_, VendingItem item_);
    event VendingItemModified(address indexed owner_, VendingItem before_, 
        VendingItem after_);
    event VendingItemRemoved(address indexed owner_, VendingItem item_);

    event VendingItemPurchased(address indexed buyer_, VendingItem item_);
    event VendingItemGifted(address indexed owner_, VendingItem item_);

    ///// Interfaces /////
    IERC1155 public PNKAssets = IERC1155(0xb0B9dE03C42eF68380953527f702E4029F6a5ec0);
    function O_setPNKAssets(address address_) external onlyOwner {
        PNKAssets = IERC1155(address_);
    }

    IERC721 public KONGZVX = IERC721(0xc24eF52B3099129a11E50E8F8315a2577BA947ae);
    function O_setKONGZVX(address address_) external onlyOwner {
        KONGZVX = IERC721(address_);
    }

    ///// Governance /////

    /* Owner */
    address public treasuryAddress = 0x000000000000000000000000000000000000dEaD;

    function O_settreasuryAddress(address address_) external onlyOwner {

        treasuryAddress = address_;
        
        emit TreasuryManaged(msg.sender, address_);
    }

    bool public requireHoldVX;

    function O_setRequireHoldVx(bool bool_) external onlyOwner {
        requireHoldVX = bool_;

        emit RequireOwnershipManaged(msg.sender, bool_);
    }

    /* Governor */
    mapping(address => bool) public governors;
    
    function O_manageGovernor(address governor_, bool bool_) external onlyOwner {

        governors[governor_] = bool_;

        emit GovernorManaged(msg.sender, governor_, bool_);
    }

    modifier onlyOwnerOrGovernor {
        require(msg.sender == owner 
            || governors[msg.sender],
            "You are not the owner or governor!");
        _;
    }

    /* Controller */
    mapping(address => bool) public controllers;

    function G_manageController(address controller_, bool bool_) external 
    onlyOwnerOrGovernor {

        controllers[controller_] = bool_;

        emit OperatorManaged(msg.sender, controller_, bool_);
    }

    modifier onlyMarketAuthorized {
        require(msg.sender == owner 
            || governors[msg.sender]
            || controllers[msg.sender],
            "You are not the owner, governor, or controller!");
        _;
    }

    ///// Marketplace /////
    VendingItem[] public vendingItems;

    mapping(uint256 => address[]) public indexToPurchasers;
    mapping(uint256 => mapping(address => bool)) public indexToPurchased;

    function addVendingItem(VendingItem memory VendingItem_) external 
    onlyMarketAuthorized {
        require(bytes(VendingItem_.title).length > 0,
            "You must specify a Title!");
        require(uint256(VendingItem_.endTime) > block.timestamp,
            "block.timestamp > endTime!");
        require(VendingItem_.endTime > VendingItem_.startTime,
            "endTime > startTime!");
        
        // Make sure that amountPurchased is always 0 on adding an item
        VendingItem_.amountPurchased = 0;

        // Push the item to the database array
        vendingItems.push(VendingItem_);

        emit VendingItemAdded(msg.sender, VendingItem_);
    }

    function modifyVendingItem(uint256 index_, VendingItem memory VendingItem_)
    external onlyMarketAuthorized {
        VendingItem memory _item = vendingItems[index_];

        require(bytes(_item.title).length > 0,
            "This VendingItem doesn't exist!");
        require(bytes(VendingItem_.title).length > 0,
            "You must specify a Title!");
        require(VendingItem_.amountAvailable >= _item.amountPurchased,
            "amountPurchased >= amountAvailable!");

        // Make sure that amountPurchased always equals previous purchased amount
        VendingItem_.amountPurchased = _item.amountPurchased;

        vendingItems[index_] = VendingItem_;

        emit VendingItemModified(msg.sender, _item, VendingItem_);
    }

    function deleteMostRecentVendingItem() external onlyMarketAuthorized {
        uint256 _lastIndex = vendingItems.length - 1;

        VendingItem memory _item = vendingItems[_lastIndex];
        
        require(_item.amountPurchased == 0,
            "Cannot delete item with already bought goods!");
        
        vendingItems.pop();

        emit VendingItemRemoved(msg.sender, _item);
    }

    function purchaseVendingItem(uint256 index_) external {
        VendingItem memory _item = vendingItems[index_];

        if (requireHoldVX) {
            require(KONGZVX.balanceOf(msg.sender) > 0,  
            "You must hold a Kongz VX to purchase!");
        }

        require(bytes(_item.title).length > 0,
            "This VendingItem doesn't exist!");
        require(_item.amountAvailable > _item.amountPurchased,
            "No more items remaining!");
        require(_item.startTime <= block.timestamp,
            "Not started yet!");
        require(_item.endTime >= block.timestamp,
            "Already ended!");
        require(!indexToPurchased[index_][msg.sender],
            "Already purchased!");
        require(_item.tokenPrice != 0,
            "Item doesn't have a price!");
        require(PNKAssets.balanceOf(msg.sender, _item.tokenId) 
            >= uint256(_item.tokenPrice),
            "Not enough tokens!");
        
        // Pay for the item
        PNKAssets
        .safeTransferFrom(msg.sender, treasuryAddress, _item.tokenId, 
        _item.tokenPrice, "");

        // Add the address into the WL List
        indexToPurchased[index_][msg.sender] = true;
        indexToPurchasers[index_].push(msg.sender);

        // Increment Amount Purchased
        vendingItems[index_].amountPurchased++;

        emit VendingItemPurchased(msg.sender, _item);
    }

    ///// Marketplace View Functions /////
    function getPurchasersOfItem(uint256 index_) public view returns (address[] memory) {
        return indexToPurchasers[index_];
    }

    function getVendingItemsLength() public view returns (uint256) {
        return vendingItems.length;
    }

    function getVendingItemsAll() public view returns (VendingItem[] memory) {
        return vendingItems;
    }

    function getVendingItemsPaginated(uint256 start_, uint256 end_) public
    view returns (VendingItem[] memory) {
        uint256 _arrayLength = end_ - start_ + 1;
        VendingItem[] memory _items = new VendingItem[] (_arrayLength);
        uint256 _index;

        for (uint256 i = 0; i < _arrayLength; i++) {
            _items[_index++] = vendingItems[start_ + i];
        }

        return _items;
    }

    function getIndexToPurchasedBatch(address purchaser_, uint256[] memory indexes_) public view returns(bool[] memory) {
        uint256 len = indexes_.length;
        bool[] memory purchasedArray = new bool[](len);

        uint256 i = 0;
        while (i < len) {
            purchasedArray[i] = indexToPurchased[indexes_[i]][purchaser_];
            i++;
        }

        return purchasedArray;
    }
}
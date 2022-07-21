/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Ownable {
    address public owner; 
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Not Owner!"); _; }
    function transferOwnership(address new_) external onlyOwner { owner = new_; }
}

interface ICHANKO {
    function owner() external view returns (address);
    function balanceOf(address address_) external view returns (uint256);
    function transferFrom(address from_, address to_, uint256 amount_) external;
    function burnFrom(address from_, uint256 amount_) external;
}

contract SHOKUDO is Ownable {

    event WLVendingItemAdded(address indexed contract_, string title_, 
        string imageUri_, string projectUri_, string description_, 
        uint32 amountAvailable_, uint32 deadline_, uint256 price_);
    event WLVendingItemRemoved(address indexed contract_, address operator_,
        WLVendingItem item_);
    event WLVendingItemPurchased(address indexed contract_, uint256 index_, 
        address buyer_, WLVendingItem item_);
    event WLVendingItemModified(address indexed contract_, WLVendingItem before_,
        WLVendingItem after_);

    ICHANKO public CHANCO = ICHANKO(0xced7c61617aD24b076729Af8EE607A4b30CBf2E4);
    function setCHANCO(address address_) external onlyOwner {
        CHANCO = ICHANKO(address_);
    }

    struct WLVendingItem {
        string title;
        string imageUri;
        string projectUri;
        string description;
        uint32 amountAvailable;
        uint32 amountPurchased;
        uint32 deadline;
        uint256 price;
    }

    mapping(address => WLVendingItem[]) public contractToWLVendingItems;
    
    mapping(address => mapping(uint256 => address[])) public contractToWLPurchasers;
    mapping(address => mapping(uint256 => mapping(address => bool))) public 
        contractToWLPurchased;

    function addWLVendingItem(address contract_, string calldata title_, 
    string calldata imageUri_, string calldata projectUri_, 
    string calldata description_, uint32 amountAvailable_, 
    uint32 deadline_, uint256 price_) external 
    onlyOwner {
        require(bytes(title_).length > 0,
            "You must specify a Title!");
        require(uint256(deadline_) > block.timestamp,
            "Already expired timestamp!");

        contractToWLVendingItems[contract_].push(
            WLVendingItem(
                title_,
                imageUri_,
                projectUri_,
                description_,
                amountAvailable_,
                0,
                deadline_,
                price_
            )
        );
        emit WLVendingItemAdded(contract_, title_, imageUri_, projectUri_, description_,
        amountAvailable_, deadline_, price_);
    }

    function modifyWLVendingItem(address contract_, uint256 index_,
    WLVendingItem memory WLVendingItem_) external 
    onlyOwner {
        WLVendingItem memory _item = contractToWLVendingItems[contract_][index_];

        require(bytes(_item.title).length > 0,
            "This WLVendingItem does not exist!");
        require(WLVendingItem_.amountAvailable >= _item.amountPurchased,
            "Amount Available must be >= Amount Purchased!");
        
        contractToWLVendingItems[contract_][index_] = WLVendingItem_;
        emit WLVendingItemModified(contract_, _item, WLVendingItem_);
    }

    function deleteMostRecentWLVendingItem(address contract_) external
    onlyOwner {
        uint256 _lastIndex = contractToWLVendingItems[contract_].length - 1;

        WLVendingItem memory _item = contractToWLVendingItems[contract_][_lastIndex];

        require(_item.amountPurchased == 0,
            "Cannot delete item with already bought goods!");
        
        contractToWLVendingItems[contract_].pop();
        emit WLVendingItemRemoved(contract_, msg.sender, _item);
    }

    function purchaseWLVendingItem(address contract_, uint256 index_) external {

        WLVendingItem memory _item = contractToWLVendingItems[contract_][index_];

        require(bytes(_item.title).length > 0,
            "This WLVendingItem does not exist!");
        require(_item.amountAvailable > _item.amountPurchased,
            "No more WL remaining!");
        require(_item.deadline >= block.timestamp,
            "Passed deadline!");
        require(!contractToWLPurchased[contract_][index_][msg.sender], 
            "Already purchased!");
        require(CHANCO.balanceOf(msg.sender) >= _item.price,
            "Not enough tokens!");

        CHANCO.burnFrom(msg.sender, _item.price);

        contractToWLPurchased[contract_][index_][msg.sender] = true;
        contractToWLPurchasers[contract_][index_].push(msg.sender);

        contractToWLVendingItems[contract_][index_].amountPurchased++;

        emit WLVendingItemPurchased(contract_, index_, msg.sender, _item);
    }

    function getWLPurchasersOf(address contract_, uint256 index_) external view 
    returns (address[] memory) { 
        return contractToWLPurchasers[contract_][index_];
    }
    function getWLVendingItemsAll(address contract_) external view 
    returns (WLVendingItem[] memory) {
        return contractToWLVendingItems[contract_];
    }
    function getWLVendingItemsLength(address contract_) external view 
    returns (uint256) {
        return contractToWLVendingItems[contract_].length;
    }
    function getWLVendingItemsPaginated(address contract_, uint256 start_, uint256 end_)
    external view returns (WLVendingItem[] memory) {
        uint256 _arrayLength = end_ - start_ + 1;
        WLVendingItem[] memory _items = new WLVendingItem[] (_arrayLength);
        uint256 _index;

        for (uint256 i = 0; i < _arrayLength; i++) {
            _items[_index++] = contractToWLVendingItems[contract_][start_ + i];
        }

        return _items;
    }
}
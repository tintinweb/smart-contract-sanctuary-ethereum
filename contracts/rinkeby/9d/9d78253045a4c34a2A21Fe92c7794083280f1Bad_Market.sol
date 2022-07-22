/**
 *Submitted for verification at Etherscan.io on 2022-07-22
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

interface IOwnable {
    function owner() external view returns (address);
}

interface IPriceController {
    function getPriceOfItem(address contract_, uint256 index_) external view
    returns (uint256);
}

interface ITokenController {
    function getTokenNameOfItem(address contract_, uint256 index_) external view
    returns (string memory);
    function getTokenImageOfItem(address contract_, uint256 index_) external view
    returns (string memory);
    function getTokenOfItem(address contract_, uint256 index_) external view
    returns (address);
}

contract Market is Ownable {

    event WLVendingItemAdded(address indexed contract_, address indexed operator_,
        WLVendingItem item_);
    event WLVendingItemModified(address indexed contract_, address indexed operator_, 
        WLVendingItem before_, WLVendingItem after_);
    event WLVendingItemRemoved(address indexed contract_, address indexed operator_,
        WLVendingItem item_);
    event WLVendingItemPurchased(address indexed contract_, address indexed purchaser_, 
        uint256 index_, WLVendingObject object_);
    event WLVendingItemGifted(address indexed contract_, address indexed gifted_,
        uint256 index_, WLVendingObject object_);

    ICHANKO public CHANCO = 
        ICHANKO(0x3C2Eb40D25a4b2B5A068a959a40d57D63Dc98B95);
    function setCHANCO(address address_) external onlyOwner {
        CHANCO = ICHANKO(address_);
    } 

    ITokenController public TokenController = 
        ITokenController(0x3C2Eb40D25a4b2B5A068a959a40d57D63Dc98B95);
    function O_setTokenController(address address_) external onlyOwner {
        TokenController = ITokenController(address_);
    } 

    IPriceController public PriceController = 
        IPriceController(0x3C2Eb40D25a4b2B5A068a959a40d57D63Dc98B95);
    function O_setPriceController(address address_) external onlyOwner {
        PriceController = IPriceController(address_);
    } 

    address private treasuryaddy;
    function setTreasury(address _address) external onlyOwner {
      treasuryaddy = _address;
    }

    struct WLVendingItem {
        string title;
        string imageUri;
        string projectUri;
        string description;

        uint32 amountAvailable;
        uint32 amountPurchased;

        uint32 startTime;
        uint32 endTime;
        
        uint256 price;
    }

    mapping(address => WLVendingItem[]) public contractToWLVendingItems;
    mapping(address => mapping(uint256 => address[])) public contractToWLPurchasers;
    mapping(address => mapping(uint256 => mapping(address => bool))) public 
        contractToWLPurchased;

    function addWLVendingItem(address contract_, WLVendingItem memory WLVendingItem_)
    external onlyOwner {
        require(bytes(WLVendingItem_.title).length > 0,
            "You must specify a Title!");
        require(uint256(WLVendingItem_.endTime) > block.timestamp,
            "Already expired timestamp!");
        require(WLVendingItem_.endTime > WLVendingItem_.startTime,
            "endTime > startTime!");

        WLVendingItem_.amountPurchased = 0;
        contractToWLVendingItems[contract_].push(WLVendingItem_);
        
        emit WLVendingItemAdded(contract_, msg.sender, WLVendingItem_);
    }

    function modifyWLVendingItem(address contract_, uint256 index_,
    WLVendingItem memory WLVendingItem_) external
    onlyOwner {
        WLVendingItem memory _item = contractToWLVendingItems[contract_][index_];

        require(bytes(_item.title).length > 0,
            "This WLVendingItem does not exist!");
        require(bytes(WLVendingItem_.title).length > 0,
            "Title must not be empty!");
        
        require(WLVendingItem_.amountAvailable >= _item.amountPurchased,
            "Amount Available must be >= Amount Purchased!");
        
        contractToWLVendingItems[contract_][index_] = WLVendingItem_;
        
        emit WLVendingItemModified(contract_, msg.sender, _item, WLVendingItem_);
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
        WLVendingObject memory _object = getWLVendingObject(contract_, index_);
        require(bytes(_object.title).length > 0,
            "This WLVendingObject does not exist!");
        require(_object.amountAvailable > _object.amountPurchased,
            "No more WL remaining!");
        require(_object.startTime <= block.timestamp,
            "Not started yet!");
        require(_object.endTime >= block.timestamp,
            "Past deadline!");
        require(!contractToWLPurchased[contract_][index_][msg.sender], 
            "Already purchased!");
        require(_object.price != 0,
            "Item does not have a set price!");
        require(CHANCO.balanceOf(msg.sender) >= _object.price,
            "Not enough tokens!");
        CHANCO.transferFrom(msg.sender, treasuryaddy, _object.price);
        contractToWLPurchased[contract_][index_][msg.sender] = true;
        contractToWLPurchasers[contract_][index_].push(msg.sender);
        contractToWLVendingItems[contract_][index_].amountPurchased++;

        emit WLVendingItemPurchased(contract_, msg.sender, index_, _object);
    }


    struct WLVendingObject {
        string title;
        string imageUri;
        string projectUri;
        string description;
        
        uint32 amountAvailable;
        uint32 amountPurchased;
        uint32 startTime;
        uint32 endTime;

        string tokenName;
        string tokenImageUri;
        address tokenAddress;

        uint256 price;
    }

    function getWLPurchasersOf(address contract_, uint256 index_) public view 
    returns (address[] memory) { 
        return contractToWLPurchasers[contract_][index_];
    }

    function getWLVendingItemsLength(address contract_) public view 
    returns (uint256) {
        return contractToWLVendingItems[contract_].length;
    }

    function raw_getWLVendingItemsAll(address contract_) public view 
    returns (WLVendingItem[] memory) {
        return contractToWLVendingItems[contract_];
    }
    function raw_getWLVendingItemsPaginated(address contract_, uint256 start_, 
    uint256 end_) public view returns (WLVendingItem[] memory) {
        uint256 _arrayLength = end_ - start_ + 1;
        WLVendingItem[] memory _items = new WLVendingItem[] (_arrayLength);
        uint256 _index;

        for (uint256 i = 0; i < _arrayLength; i++) {
            _items[_index++] = contractToWLVendingItems[contract_][start_ + i];
        }

        return _items;
    }

    function getWLVendingObject(address contract_, uint256 index_) public 
    view returns (WLVendingObject memory) {
        WLVendingItem memory _item = contractToWLVendingItems[contract_][index_];
        WLVendingObject memory _object = WLVendingObject(
            _item.title,
            _item.imageUri,
            _item.projectUri,
            _item.description,

            _item.amountAvailable,
            _item.amountPurchased,
            _item.startTime,
            _item.endTime,

            TokenController.getTokenNameOfItem(contract_, index_),
            TokenController.getTokenImageOfItem(contract_, index_),
            TokenController.getTokenOfItem(contract_, index_),

            PriceController.getPriceOfItem(contract_, index_)
        );
        return _object;
    }

    function getWLVendingObjectsPaginated(address contract_, uint256 start_, 
    uint256 end_) public view returns (WLVendingObject[] memory) {
        uint256 _arrayLength = end_ - start_ + 1;
        WLVendingObject[] memory _objects = new WLVendingObject[] (_arrayLength);
        uint256 _index;

        for (uint256 i = 0; i < _arrayLength; i++) {

            uint256 _itemIndex = start_ + i;
            
            WLVendingItem memory _item = contractToWLVendingItems[contract_][_itemIndex];
            WLVendingObject memory _object = WLVendingObject(
                _item.title,
                _item.imageUri,
                _item.projectUri,
                _item.description,

                _item.amountAvailable,
                _item.amountPurchased,
                _item.startTime,
                _item.endTime,

                TokenController.getTokenNameOfItem(contract_, (_itemIndex)),
                TokenController.getTokenImageOfItem(contract_, (_itemIndex)),
                TokenController.getTokenOfItem(contract_, (_itemIndex)),

                PriceController.getPriceOfItem(contract_, (_itemIndex))
            );

            _objects[_index++] = _object;
        }

        return _objects;
    }
}
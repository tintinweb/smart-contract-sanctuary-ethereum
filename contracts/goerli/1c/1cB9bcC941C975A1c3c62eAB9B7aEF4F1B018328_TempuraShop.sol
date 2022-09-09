//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/*
🍤🍤🍤🍤🍤🍤🍤🍤
The Tempura Shop
🍤🍤🍤🍤🍤🍤🍤🍤
*/

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20Like {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;
}

interface IERC721Like {
    function balanceOf(address owner) external view returns (uint256);

}

contract TempuraShop is Ownable {

    ///@notice Main listing struct
    ///@param amountAvailable Total amount available for listing
    ///@param amountPurchased Total amount purchased for listing
    ///@param startTime Start time for listing
    ///@param endTime End time for listing
    ///@param price Price of listing in ETH base units
    ///@param _type Indicator for OG/Elite/Regular market
    struct Item {
        uint64 index;
        uint32 amountAvailable;
        uint32 amountPurchased;
        uint32 startTime;
        uint32 endTime;
        uint32 price;
        uint32 _type;
    }

    ///@notice Array containing all listings
    Item[] public items;

    ///@notice Event to index purchases
    event Purchase(address buyer, string discordId, uint64 index);

    ///@notice Setting our contracts...
    IERC20Like public Tempura = IERC20Like(0xE73E34dc58E839eF58B64B3FC81F37BC864a9065);
    IERC721Like public OGYakuza = IERC721Like(0x7C4e30a43ecC4d3231b5B07ed082329020D141F3);
    IERC721Like public YakuzaElite = IERC721Like(0x7C4e30a43ecC4d3231b5B07ed082329020D141F3);

    address public burnAddress = 0x000000000000000000000000000000000000dEaD;

    ///@notice Managers can set/modify listings
    mapping(address => bool) public managers;
    ///@notice Mapping that stores an array of all purchases for each item index
    mapping(uint256 => address[]) public indexToPurchasers;
    ///@notice Mapping that notates if an address has purchased a listing already.
    mapping(uint256 => mapping(address => bool)) public indexToPurchased;

    modifier onlyManager() {
        require(managers[msg.sender], "You are not a manager!");
        _;
    }

                /////////////////////////////////
                // Owner Restricted Functions //
                ///////////////////////////////

    function setBurnAddress(address address_) external onlyOwner {
        burnAddress = address_;
    }

    function setManagers(address manager, bool status) external onlyOwner {
        managers[manager] = status;
    }

    function setTempura(address _tempura) external onlyOwner {
        Tempura = IERC20Like(_tempura);
    }

    function setOGYakuza(address _og) external onlyOwner {
        OGYakuza = IERC721Like(_og);
    }

    function setYakuzaElite(address _elite) external onlyOwner {
        YakuzaElite = IERC721Like(_elite);
    }

                ///////////////////////////////////
                // Manager Restricted Functions //
                /////////////////////////////////

    function addItem(Item memory Item_) external onlyManager {
        Item_.amountPurchased = 0;
        Item_.index = uint64(items.length);
        items.push(Item_);
    }

    function addMultiItems(Item[] memory Item_) external onlyManager {
        for (uint256 i; i < Item_.length; i++) {
            Item_[i].amountPurchased = 0;
            Item_[i].index = uint64(items.length);
            items.push(Item_[i]);
        }
    }

    function modifyItem(uint256 index_, Item memory Item_) external onlyManager {
        Item memory _item = items[index_];
        require(_item.price > 0, "This Item doesn't exist!");
        Item_.amountPurchased = _item.amountPurchased;
        items[index_] = Item_;
    }

    function deleteMostRecentItem() external onlyManager {
        uint256 _lastIndex = items.length - 1;

        Item memory _item = items[_lastIndex];

        require(_item.amountPurchased == 0, "Cannot delete item with already bought goods!");

        items.pop();
    }

    function purchaseItem(uint256 index_, string calldata discordId) external {
        Item memory _item = items[index_];

        if (_item._type == 0) {
            require(OGYakuza.balanceOf(msg.sender) != 0, "You must hold an OG Yakuza to purchase!");
        }
        if (_item._type == 1) {
            require(YakuzaElite.balanceOf(msg.sender) > 0, "You  must hold a Yakuza Elite to purchase!");
        }

        require(_item.amountAvailable > _item.amountPurchased, "No more items remaining!");
        require(_item.startTime <= block.timestamp, "Not started yet!");
        require(_item.endTime >= block.timestamp, "Already ended!");
        require(!indexToPurchased[index_][msg.sender], "Already purchased!");

        // Pay for the item
        Tempura.transferFrom(msg.sender, burnAddress, (_item.price * 1 ether));

        // Add the address into the WL List
        indexToPurchased[index_][msg.sender] = true;
        indexToPurchasers[index_].push(msg.sender);

        // Increment Amount Purchased
        items[index_].amountPurchased++;

        emit Purchase(msg.sender, discordId, _item.index);
    }

                ///////////////////////////////
                // View/Marketplace Helpers //
                /////////////////////////////

    function getPurchasersOfItem(uint256 index_) public view returns (address[] memory) {
        return indexToPurchasers[index_];
    }

    function getItemsLength() public view returns (uint256) {
        return items.length;
    }

    function getItemsAll() public view returns (Item[] memory) {
        return items;
    }

    function getActiveItems() public view returns (Item[] memory) {
        Item[] memory activeListings = new Item[](items.length);
        for (uint256 i; i < items.length; i++) {
            if (items[i].amountPurchased < items[i].amountAvailable) {
                activeListings[activeListings.length] = items[i];
            }
        }
        return activeListings;
    }

    function getRemainingSupply(uint256 index_) public view returns (uint32) {
        return items[index_].amountAvailable - items[index_].amountPurchased;
    }

    function getRemainingSupplyForAll() public view returns (uint32[] memory) {
        uint32[] memory allSupplies = new uint32[](items.length);
        for (uint256 i; i < items.length; i++) {
            uint32 supply = getRemainingSupply(i);
            allSupplies[i] = supply;
        }
        return allSupplies;
    }

    function getItemIndexByType(uint32 _type) public view returns (uint64[] memory) {
        Item[] memory activeListings = getActiveItems();
        uint64[] memory typeListingIndex;
        for(uint256 i; i < activeListings.length; i++) {
            if(activeListings[i]._type == _type) {
                typeListingIndex[i] = activeListings[i].index;
            }
        }
        return typeListingIndex;
    }

    function getSomeItems(uint256 start_, uint256 end_) public view returns (Item[] memory) {
        uint256 _arrayLength = end_ - start_ + 1;
        Item[] memory _items = new Item[](_arrayLength);
        uint256 _index;

        for (uint256 i = 0; i < _arrayLength; i++) {
            _items[_index++] = items[start_ + i];
        }

        return _items;
    }

    function getIndexToPurchasedBatch(address purchaser_, uint256[] memory indexes_)
        public
        view
        returns (bool[] memory)
    {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
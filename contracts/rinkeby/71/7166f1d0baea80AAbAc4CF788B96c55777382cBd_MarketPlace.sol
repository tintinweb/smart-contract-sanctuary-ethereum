//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/**  Custom error using revert to be more gas efficient
 *   Also, it will refund any remaining gas to the caller
 */

error MarketPlace__NotOwner();
error MarketPlace__NullValueNotAllowed();
error MarketPlace__SameItemNotAllowed();
error MarketPlace__ItemAlreadyListed();
error MarketPlace__BalanceTransferFailed();
error MarketPlace__EnterExactPrice();
error MarketPlace__ItemNotListed();
error MarketPlace__EnterRightItem();
error MarketPlace__NoItemAvailableToBuySell();

/** @title A simple MarketPlace Contract
 *  @author Bijay Ghullu
 *  @notice This contract is for creating a decentralized smart contract
 *  @dev This implements struct data structure for gas efficiency.
 *       Emit an Event to store information in loggin structure in a way more gas efficient than to
 *       to store in storage vairable.
 *       Reduce the number of storage operation by uisng local memory variable in loops before assigning
 *       it to a storage variable.
 *       Use of Revert instead of Require.
 */

contract MarketPlace {
    struct Items {
        string itemName;
        uint256 unit;
        uint256 price;
        address payable seller;
        address payable buyer;
        bool listed;
    }

    Items[] public s_item;
    address private immutable i_owner; // immutable and
    uint private constant UPDATED_ITEM_NUM = 1; // constant are gas saving keywords
    uint256 private constant PRICE = 1 ether;
    // Event to log the inforamtion

    event ItemAdded(
        string indexed itemName,
        uint256 unit,
        uint256 price,
        address seller,
        address buyer,
        bool listed
    );
    event ItemToSeller(address indexed seller, string itemName);
    event ItemSoldTo(address indexed buyer, string itemName);

    constructor() {
        i_owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert MarketPlace__NotOwner();
        _;
    }

    /**
     *  @dev This function can only be called by the owner of the contract to list the items
     *  and the function will be external because memory allocation is gas expensive, whereas
     *  reading from calldata is cheap.
     */
    function listItems(string memory _itemName) public onlyOwner {
        if (
            keccak256(abi.encodePacked((_itemName))) ==
            keccak256(abi.encodePacked(("")))
        ) {
            revert MarketPlace__NullValueNotAllowed();
        }
        (, bool addItem) = checkData(_itemName);
        if (addItem != true) {
            Items memory _item = Items(
                _itemName,
                0,
                0,
                payable(address(0)),
                payable(address(0)),
                false
            );
            s_item.push(_item);
        } else {
            revert MarketPlace__SameItemNotAllowed();
        }
        emit ItemAdded(
            _itemName,
            0,
            0,
            payable(address(0)),
            payable(address(0)),
            false
        );
    }

    function checkData(string memory _itemName)
        internal
        view
        returns (uint256, bool)
    {
        /**
         * @dev Storing struct in a memory will be much more gas efficent when we wil loop through it to read the data.
         *     In smart contract, reading data has one of the highest gas cost.
         */

        Items[] memory _item = s_item;
        bool checkItem;
        bool goAhead;
        uint256 index;
        for (uint256 i = 0; i < _item.length; i++) {
            checkItem =
                keccak256(abi.encodePacked((_item[i].itemName))) ==
                keccak256(abi.encodePacked((_itemName)));
            if (checkItem == true) {
                index = i;
                goAhead = true;
            }
        }

        return (index, goAhead);
    }

    function seller(string memory _itemName) external {
        if (s_item.length == 0) {
            revert MarketPlace__NoItemAvailableToBuySell();
        }
        (uint256 index, bool goAhead) = checkData(_itemName);
        if (goAhead == false) {
            revert MarketPlace__EnterRightItem();
        }
        if (s_item[index].listed == true) {
            revert MarketPlace__ItemAlreadyListed();
        }
        s_item[index].unit = UPDATED_ITEM_NUM;
        s_item[index].price = PRICE;
        s_item[index].listed = true;
        s_item[index].seller = payable(msg.sender);

        emit ItemToSeller(msg.sender, _itemName);
    }

    function buyer(string memory _itemName) external payable {
        if (s_item.length == 0) {
            revert MarketPlace__NoItemAvailableToBuySell();
        }
        (uint256 index, bool goAhead) = checkData(_itemName);
        if (goAhead == false) {
            revert MarketPlace__EnterRightItem();
        }
        if (s_item[index].listed != true) {
            revert MarketPlace__ItemNotListed();
        }
        if (msg.value != PRICE) {
            revert MarketPlace__EnterExactPrice();
        }
        s_item[index].buyer = payable(msg.sender);

        address payable _seller = s_item[index].seller;
        (bool callSuccess, ) = _seller.call{value: s_item[index].price}("");
        delete s_item[index];
        if (!callSuccess) {
            revert MarketPlace__BalanceTransferFailed();
        }

        emit ItemSoldTo(msg.sender, _itemName);
    }

    function getItem() external view returns (Items[] memory) {
        return s_item;
    }

    function getItemPrice() external pure returns (uint256) {
        return PRICE;
    }
}
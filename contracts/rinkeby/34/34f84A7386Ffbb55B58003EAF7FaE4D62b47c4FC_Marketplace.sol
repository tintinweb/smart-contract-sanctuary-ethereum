// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";

error Marketplace__NewItemExist();
error Marketplace__NotOwner();

/** @title A contract for buying and selling items
 *  @author Abolaji
 *  @dev
 */

contract Marketplace {
    //Variables
    address private immutable feeAccount;
    uint256 public immutable feePercent;
    address public immutable i_owner;
    string public item;
    address payable internal user;
    uint256 public orderCount;

    struct _order {
        uint256 id;
        address seller;
        string item;
        uint256 qtty_to_sell;
        uint256 price;
        uint256 timestamp;
    }

    mapping(address => mapping(string => uint256)) public goods;

    // store the order
    mapping(address => uint256) public getBal;
    mapping(uint256 => _order) public orders;
    mapping(uint256 => ORDER_STATE) public orderStatus;
    mapping(uint256 => bool) public orderCancelled;
    mapping(uint256 => bool) public orderFilled;
    mapping(uint256 => bool) public orderCreated;
    mapping(uint256 => bool) public orderDelivered;
    mapping(uint256 => address) public Buyers;
    mapping(uint256 => uint256) public filledAmount;
    mapping(uint256 => uint256) public filledQuantity;
    //_order[] public OpenOrder;
    string[] public allowedItems;

    //Events
    event Deposit(address user, uint256 amount, uint256 bal);
    event Withdraw(address user, uint256 amount, uint256 bal);
    event OrderCreated(
        uint256 id,
        address seller,
        string item,
        uint256 qtty_to_sell,
        uint256 price,
        uint256 timestamp
    );
    event OrderFilled(
        uint256 id,
        address seller,
        address buyer,
        string item,
        uint256 qtty_bought,
        uint256 price,
        uint256 timestamp
    );
    event OrderDelivered(
        uint256 id,
        address seller,
        address buyer,
        string item,
        uint256 qtty_bought,
        uint256 price,
        uint256 timestamp
    );
    event CancelOpenOrder(
        uint256 id,
        address seller,
        string item,
        uint256 qtty_to_sell,
        uint256 price,
        uint256 timestamp
    );
    event CancelFilledOrder(
        uint256 id,
        address seller,
        address buyer,
        string item,
        uint256 qtty_bought,
        uint256 price,
        uint256 timestamp
    );

    enum ORDER_STATE {
        OPEN,
        FILLED,
        CLOSED
    }

    constructor(address _feeAccount, uint256 _feePercent) {
        feeAccount = _feeAccount;
        feePercent = _feePercent;
        i_owner = msg.sender;
    }

    function depositEther() public payable {
        getBal[msg.sender] = getBal[msg.sender] + msg.value;

        emit Deposit(msg.sender, msg.value, getBal[msg.sender]);
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert Marketplace__NotOwner();
        _;
    }

    // //Fallback: reverts if Ether is sent to this smart contract by mistake
    // function() external {
    //     revert();
    // }

    function withdrawEther(uint256 _amount) public {
        user = payable(msg.sender);
        require(getBal[msg.sender] >= _amount);
        getBal[msg.sender] = getBal[msg.sender] - _amount;
        user.transfer(_amount);
        emit Withdraw(msg.sender, _amount, getBal[msg.sender]);
    }

    function myBalance() public view returns (uint256) {
        return getBal[msg.sender];
    }

    // Create an order as a seller
    function makeOrder(
        string memory _item,
        uint256 _quantity,
        uint256 _price
    ) public {
        require(itemIsAllowed(_item), "Item is currently not allowed");
        orderCount = orderCount + 1;
        orders[orderCount] = _order(
            orderCount,
            msg.sender,
            _item,
            _quantity,
            _price,
            block.timestamp
        );
        orderStatus[orderCount] = ORDER_STATE.OPEN;
        goods[msg.sender][_item] = _quantity;
        emit OrderCreated(
            orderCount,
            msg.sender,
            _item,
            _quantity,
            _price,
            block.timestamp
        );
    }

    // Fill an order as a buyer
    function fillOrder(uint256 _id, uint256 _quantity) public {
        require(_id > 0 && _id <= orderCount);
        require(orderStatus[_id] == ORDER_STATE.OPEN);

        address _buyer = msg.sender;

        // Fetch the order
        _order memory order = orders[_id];
        require(_quantity <= order.qtty_to_sell, "Reduce the quantity");
        uint256 amount = _quantity * order.price;
        require(getBal[_buyer] >= amount, "You need more eth");

        _orderBond(_id, _buyer, _quantity, amount);

        // Mark order as filled
        orderFilled[_id] = true;
        orderStatus[_id] = ORDER_STATE.FILLED;
        Buyers[_id] = _buyer;
        filledAmount[_id] = amount;
        filledQuantity[_id] = _quantity;

        emit OrderFilled(
            _id,
            order.seller,
            _buyer,
            order.item,
            _quantity,
            order.price,
            block.timestamp
        );
    }

    //Getting orders that are still available for buying
    function open_order()
        public
        view
        returns (
            uint256[] memory idOrder,
            string[] memory _item,
            uint256[] memory _qty,
            uint256[] memory _prc
        )
    {
        idOrder = new uint256[](orderCount);
        _item = new string[](orderCount);
        _qty = new uint256[](orderCount);
        _prc = new uint256[](orderCount);
        for (uint256 i = 1; i <= orderCount; i++) {
            if (orderStatus[i] == ORDER_STATE.OPEN) {
                idOrder[i - 1] = orders[i].id;
                _item[i - 1] = orders[i].item;
                _qty[i - 1] = orders[i].qtty_to_sell;
                _prc[i - 1] = orders[i].price / (10**15);
            }
        }
        return (idOrder, _item, _qty, _prc);
    }

    // When the buyer confirms the receipt of the items, the money is released to the seller
    function OrderReceived(uint256 _id) public {
        address _buyer = Buyers[_id];
        _order memory order = orders[_id];
        require(orderStatus[_id] == ORDER_STATE.FILLED);
        require(msg.sender == _buyer, "Not your order");
        uint256 amount = filledAmount[_id];
        uint256 quantity = filledQuantity[_id];

        _orderCompleted(_id, _buyer, quantity, amount);
        orderStatus[_id] = ORDER_STATE.CLOSED;
        emit OrderDelivered(
            _id,
            order.seller,
            _buyer,
            order.item,
            quantity,
            order.price,
            block.timestamp
        );
    }

    function cancelOpenOrder(uint256 _id) public {
        _order memory order = orders[_id];
        require(order.seller == msg.sender, "Not your order"); // must be "my" order
        require(orderStatus[_id] == ORDER_STATE.OPEN);

        orderCancelled[_id] = true;
        orderStatus[_id] == ORDER_STATE.CLOSED;
        emit CancelOpenOrder(
            _id,
            order.seller,
            order.item,
            order.qtty_to_sell,
            order.price,
            block.timestamp
        );
    }

    function cancelFilledOrder(uint256 _id) public {
        _order memory order = orders[_id];
        address _buyer = Buyers[_id];
        require(
            order.seller == msg.sender || _buyer == msg.sender,
            "Not your order"
        ); // must be "my" order
        require(orderStatus[_id] == ORDER_STATE.FILLED);
        uint256 _amount = filledAmount[_id];
        uint256 _quantity = filledQuantity[_id];

        getBal[_buyer] = getBal[_buyer] + _amount;
        goods[msg.sender][order.item] =
            goods[msg.sender][order.item] +
            _quantity;
        orderStatus[_id] == ORDER_STATE.CLOSED;
        orderCancelled[_id] = true;
        emit CancelFilledOrder(
            _id,
            order.seller,
            _buyer,
            order.item,
            _quantity,
            order.price,
            block.timestamp
        );
    }

    function _orderBond(
        uint256 _id,
        address _buyer,
        uint256 _quantity,
        uint256 _amount
    ) internal {
        _order memory order = orders[_id];
        // place order
        getBal[_buyer] = getBal[_buyer] - _amount;
        goods[order.seller][order.item] =
            goods[order.seller][order.item] -
            _quantity;
    }

    function _orderCompleted(
        uint256 _id,
        address _buyer,
        uint256 _quantity,
        uint256 _amount
    ) internal {
        _order memory order = orders[_id];
        _amount = _amount - ((feePercent * _amount) / 100);

        getBal[order.seller] = getBal[order.seller] + _amount;
        goods[_buyer][order.item] = goods[_buyer][order.item] + _quantity;
        getBal[feeAccount] =
            getBal[feeAccount] +
            ((feePercent * _amount) / 100);
    }

    function addAllowedItems(string memory _item) public onlyOwner {
        //require (newItemIsUnique(_item));
        allowedItems.push(_item);
    }

    function itemIsAllowed(string memory _item) public view returns (bool) {
        for (
            uint256 allowedItemIndex = 0;
            allowedItemIndex < allowedItems.length;
            allowedItemIndex++
        ) {
            if (
                keccak256(bytes(allowedItems[allowedItemIndex])) ==
                keccak256(bytes(_item))
            ) {
                return true;
            }
        }
        return false;
    }

    // function newItemIsUnique(string memory _item) public view  returns (bool) {
    //     string[] memory itemArray= allowedItems;
    //     for (uint256 i=0; i<itemArray.length; i++){
    //         if (keccak256(bytes(itemArray[i]))==keccak256(bytes(_item))){
    //             revert Marketplace__NewItemExist();
    //         }
    //     }
    //     return true;
    // }

    function getAllowedItems() public view returns (string[] memory) {
        return allowedItems;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
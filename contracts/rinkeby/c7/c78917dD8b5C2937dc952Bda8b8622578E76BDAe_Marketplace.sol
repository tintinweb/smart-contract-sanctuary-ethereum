// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error Marketplace__NotOwner();

/** @title A contract for buying and selling items
 *  @author Abolaji
 *  @dev It uses an ERC20 token for transaction on the development network
 */

contract Marketplace is Ownable {
    //Variables
    address public feeAccount;
    uint256 public feePercent;
    address private immutable i_owner;
    string public item;
    address internal ethAddress;
    IERC20 public ETHER;
    string[] public allowedItems;
    address payable internal user;

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
    mapping(address => mapping(IERC20 => uint256)) public balance;
    mapping(uint256 => _order) public orders;
    uint256 public orderCount;
    mapping(uint256 => ORDER_STATE) public orderStatus;
    mapping(uint256 => bool) public orderCancelled;
    mapping(uint256 => bool) public orderFilled;
    mapping(uint256 => bool) public orderCreated;
    mapping(uint256 => bool) public orderDelivered;
    mapping(uint256 => address) public Buyers;
    mapping(uint256 => uint256) public filledAmount;
    mapping(uint256 => uint256) public filledQuantity;

    //Events
    event Deposit(IERC20 token, address user, uint256 amount, uint256 balance);
    event Withdraw(IERC20 token, address user, uint256 amount, uint256 balance);
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

    //ORDER_STATE public orderState;

    constructor(
        address _ethAddress,
        address _feeAccount,
        uint256 _feePercent
    ) {
        ETHER = IERC20(_ethAddress);
        feeAccount = _feeAccount;
        feePercent = _feePercent;
        i_owner = msg.sender;
    }

    function depositEther(IERC20 _token, uint256 _amount) public payable {
        require(_token == ETHER, "Unknown token");
        ETHER.transferFrom(msg.sender, address(this), _amount);
        balance[msg.sender][ETHER] = balance[msg.sender][ETHER] + msg.value;

        emit Deposit(ETHER, msg.sender, msg.value, balance[msg.sender][ETHER]);
    }

    // allowing users to deposit ether

    // //Fallback: reverts if Ether is sent to this smart contract by mistake
    // function() external {
    //     revert();
    // }

    function withdrawEther(IERC20 _token, uint256 _amount) public {
        user = payable(msg.sender);
        require(_token == ETHER, "Unknown token");
        require(balance[msg.sender][ETHER] >= _amount);
        balance[msg.sender][ETHER] = balance[msg.sender][ETHER] - _amount;
        _token.transfer(user, _amount);
        emit Withdraw(_token, msg.sender, _amount, balance[msg.sender][_token]);
    }

    function balanceOf(address _user, IERC20 _token)
        public
        view
        returns (uint256)
    {
        return balance[_user][_token];
    }

    // add the order to storage
    function makeOrder(
        string memory _item,
        uint256 _quantity,
        uint256 _price
    ) public {
        require(itemIsAllowed(_item), "Item is currently not allowed");
        orderCount = orderCount + 1;
        orderStatus[orderCount] = ORDER_STATE.CLOSED;
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

    function fillOrder(uint256 _id, uint256 _quantity) public {
        require(_id > 0 && _id <= orderCount);
        require(orderStatus[_id] == ORDER_STATE.OPEN);

        address _buyer = msg.sender;

        // Fetch the order
        _order storage order = orders[_id];
        require(_quantity <= order.qtty_to_sell, "Reduce the quantity");
        uint256 amount = _quantity * order.price;
        require(balance[_buyer][ETHER] >= amount, "You need more eth");

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

    function OrderReceived(uint256 _id) public {
        address _buyer = Buyers[_id];
        _order storage order = orders[_id];
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
        _order storage order = orders[_id];
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
        _order storage order = orders[_id];
        address _buyer = Buyers[_id];
        require(
            order.seller == msg.sender || _buyer == msg.sender,
            "Not your order"
        ); // must be "my" order
        require(orderStatus[_id] == ORDER_STATE.FILLED);

        orderCancelled[_id] = true;
        orderStatus[_id] == ORDER_STATE.CLOSED;
        emit CancelFilledOrder(
            _id,
            order.seller,
            _buyer,
            order.item,
            filledQuantity[_id],
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
        _order storage order = orders[_id];
        // place order
        balance[_buyer][ETHER] = balance[_buyer][ETHER] - _amount;
        goods[msg.sender][order.item] =
            goods[msg.sender][order.item] -
            _quantity;
    }

    function _orderCompleted(
        uint256 _id,
        address _buyer,
        uint256 _quantity,
        uint256 _amount
    ) internal {
        _order storage order = orders[_id];
        _amount = _amount - ((feePercent * _amount) / 100);

        // place order
        balance[order.seller][ETHER] = balance[order.seller][ETHER] + _amount;
        goods[_buyer][order.item] = goods[_buyer][order.item] + _quantity;
        balance[feeAccount][ETHER] =
            balance[feeAccount][ETHER] +
            ((feePercent * _amount) / 100);
    }

    function addAllowedItems(string memory _item) public onlyOwner {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
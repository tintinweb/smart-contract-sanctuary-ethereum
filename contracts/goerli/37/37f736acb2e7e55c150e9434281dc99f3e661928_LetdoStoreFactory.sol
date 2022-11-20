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
pragma solidity ^0.8.13;

import "./LetdoStoreMetadata.sol";
import "../structs/LetdoEscrowOp.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract LetdoEscrowStoreMetadata is LetdoStoreMetadata {
    uint256 constant MAX_STORE_TIME = 90 days;
    uint256 constant THRESHOLD_NOT_RECEIVED = 60 days;
    LetdoEscrowOp[] _ops;
    uint256 _availableCurrencyToken;

    error NotEnoughFunds();
    error OpAlreadyFinished();
    error NotEnoughCurrencyToken();

    event AvailableFundsForWithdraw(uint256 amount);

    function _beginEscrow(uint256 amount) internal {
        IERC20 token = IERC20(storeCurrencyERC20);
        if (token.balanceOf(msg.sender) < amount) revert NotEnoughFunds();
        token.transferFrom(msg.sender, address(this), amount);
        LetdoEscrowOp memory op = LetdoEscrowOp(
            msg.sender,
            amount,
            block.timestamp,
            false
        );
        _ops.push(op);
    }

    function _returnFundsEscrow(uint256 orderId) internal {
        LetdoEscrowOp memory op = _ops[orderId];
        if (op.completed) revert OpAlreadyFinished();
        IERC20 token = IERC20(storeCurrencyERC20);
        token.transfer(op.sender, op.amount);
        op.completed = true;
        _ops[orderId] = op;
    }

    function _releaseFundsEscrow(uint256 orderId) internal {
        LetdoEscrowOp memory op = _ops[orderId];
        if (op.completed) revert OpAlreadyFinished();
        _availableCurrencyToken += op.amount;
        emit AvailableFundsForWithdraw(op.amount);
        op.completed = true;
        _ops[orderId] = op;
    }

    function _isOpFinished(uint256 orderId) internal view returns (bool) {
        LetdoEscrowOp memory op = _ops[orderId];
        return op.completed;
    }

    function _canBeSetAsNotReceived(uint256 orderId)
        internal
        view
        returns (bool)
    {
        LetdoEscrowOp memory op = _ops[orderId];
        if (
            !op.completed &&
            block.timestamp > op.timestamp + THRESHOLD_NOT_RECEIVED &&
            block.timestamp < op.timestamp + MAX_STORE_TIME
        ) {
            return true;
        }

        return false;
    }

    function _canOpBeSetAsCompleted(uint256 orderId) internal view returns (bool) {
        LetdoEscrowOp memory op = _ops[orderId];
        if (!op.completed && block.timestamp > op.timestamp + MAX_STORE_TIME) {
            return true;
        }

        return false;
    }

    function checkAvailableCurrencyToken() external view returns (uint256) {
        return _availableCurrencyToken;
    }

    function withdrawAvailableCurrencyToken() external onlyStoreOwner {
        if (_availableCurrencyToken == 0) revert NotEnoughCurrencyToken();

        IERC20 token = IERC20(storeCurrencyERC20);
        token.transfer(storeOwner, _availableCurrencyToken);
        _availableCurrencyToken = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./LetdoEscrowStoreMetadata.sol";
import "../structs/LetdoItem.sol";
import "../structs/LetdoOrder.sol";

contract LetdoStore is LetdoEscrowStoreMetadata {
    LetdoItem[] _inventory;
    mapping(uint256 => LetdoOrder) _orders;
    mapping(uint256 => bool) _rejectedOrders;
    uint256 _orderCounter;
    uint256[2] _reviews; // [0] positive reviews, [1] negative reviews

    error IdNotFound();
    error ItemNotAvailable();
    error InvalidItemAmount();
    error InvalidBuyer();
    error OrderAlreadyCompleted();
    error ActionNotAvailable();

    event OrderCreated(
        address indexed buyer,
        uint256 orderId,
        uint256 amount,
        uint256 itemId
    );

    event ReviewSubmitted(
        address indexed buyer,
        uint256 orderId,
        uint256 indexed itemId,
        int8 review
    );

    event OrderCompleted(uint256 orderId);

    constructor(
        string memory _storeName,
        address _storeCurrencyERC20,
        string memory _storePublicKey
    ) {
        storeName = _storeName;
        storeOwner = msg.sender;
        storeCurrencyERC20 = _storeCurrencyERC20;
        storePublicKey = _storePublicKey;
    }

    modifier onlyExistingItem(uint256 id) {
        if (id > _inventory.length - 1) revert IdNotFound();
        _;
    }

    modifier onlyExistingOrder(uint256 id) {
        if (id > _orderCounter - 1) revert IdNotFound();
        _;
    }

    modifier onlyBuyerOfOrder(uint256 id) {
        LetdoOrder memory order = getOrder(id);
        if (order.buyer != msg.sender) revert InvalidBuyer();
        _;
    }

    modifier onlyEscrowNotCompleted(uint256 id) {
        if (_isOpFinished(id)) revert OrderAlreadyCompleted();
        _;
    }

    function addInventoryItem(string calldata metadataURI, uint256 price)
        external
        onlyStoreOwner
    {
        _inventory.push(LetdoItem(metadataURI, price, true));
    }

    function toggleInventoryItemAvailability(uint256 id)
        external
        onlyStoreOwner
        onlyExistingItem(id)
    {
        LetdoItem memory item = getInventoryItem(id);
        item.available = !item.available;
        _inventory[id] = item;
    }

    function inventoryLength() external view returns (uint256) {
        return _inventory.length;
    }

    function getInventoryItem(uint256 id)
        public
        view
        onlyExistingItem(id)
        returns (LetdoItem memory)
    {
        LetdoItem memory item = _inventory[id];
        if (!item.available) revert ItemNotAvailable();
        return item;
    }

    function getOrder(uint256 id)
        public
        view
        onlyExistingOrder(id)
        returns (LetdoOrder memory)
    {
        return _orders[id];
    }

    function getStoreReviews() external view returns (uint256[2] memory) {
        return _reviews;
    }

    function purchase(
        uint256 itemId,
        uint256 quantity,
        string memory encryptedDeliveryData
    ) external onlyExistingItem(itemId) returns (uint256) {
        if (quantity == 0) revert InvalidItemAmount();
        LetdoItem memory item = getInventoryItem(itemId);
        _beginEscrow(item.price * quantity);
        _orders[_orderCounter] = LetdoOrder(
            encryptedDeliveryData,
            item.price * quantity,
            itemId,
            msg.sender
        );

        emit OrderCreated(
            msg.sender,
            _orderCounter,
            item.price * quantity,
            itemId
        );

        _orderCounter++;

        return _orderCounter - 1;
    }

    function setPurchaseAsReceived(uint256 orderId, bool positiveVote)
        external
        onlyBuyerOfOrder(orderId)
        onlyEscrowNotCompleted(orderId)
    {
        LetdoOrder memory order = getOrder(orderId);
        if (positiveVote) {
            _reviews[0] += 1;
            emit ReviewSubmitted(order.buyer, orderId, order.itemId, 1);
        } else {
            _reviews[1] += 1;
            emit ReviewSubmitted(order.buyer, orderId, order.itemId, -1);
        }

        _releaseFundsEscrow(orderId);
        emit OrderCompleted(orderId);
    }

    function setPurchaseAsNotReceived(uint256 orderId)
        external
        onlyBuyerOfOrder(orderId)
        onlyEscrowNotCompleted(orderId)
    {
        if (!_canBeSetAsNotReceived(orderId)) revert ActionNotAvailable();

        _reviews[1] += 1;

        LetdoOrder memory order = getOrder(orderId);
        emit ReviewSubmitted(order.buyer, orderId, order.itemId, -1);

        _returnFundsEscrow(orderId);
        emit OrderCompleted(orderId);
    }

    function setOrderAsComplete(uint256 orderId)
        external
        onlyExistingOrder(orderId)
        onlyStoreOwner
        onlyEscrowNotCompleted(orderId)
    {
        if (!_canOpBeSetAsCompleted(orderId)) revert ActionNotAvailable();

        _releaseFundsEscrow(orderId);
        emit OrderCompleted(orderId);
    }

    function rejectOrder(uint256 orderId)
        external
        onlyExistingOrder(orderId)
        onlyStoreOwner
        onlyEscrowNotCompleted(orderId)
    {
        _rejectedOrders[orderId] = true;
    }

    function claimFundsAfterRejection(uint256 orderId)
        external
        onlyBuyerOfOrder(orderId)
        onlyEscrowNotCompleted(orderId)
    {
        if (!_rejectedOrders[orderId]) revert ActionNotAvailable();

        _returnFundsEscrow(orderId);
        emit OrderCompleted(orderId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "./LetdoStore.sol";

contract LetdoStoreFactory {
    address[] public allStores;

    event StoreCreated(address store, address indexed owner);

    address public storesCurrencyERC20;

    error EmptyString();

    constructor(address _storesCurrencyERC20) {
        require(_storesCurrencyERC20 != address(0));
        storesCurrencyERC20 = _storesCurrencyERC20;
    }

    function allStoresLength() external view returns (uint256) {
        return allStores.length;
    }

    function createStore(
        string calldata storeName,
        string calldata storePublicKey
    ) external returns (address) {
        if (bytes(storeName).length == 0 || bytes(storePublicKey).length == 0)
            revert EmptyString();

        bytes32 salt = keccak256(
            abi.encodePacked(allStores.length, msg.sender)
        );

        address newStoreAddress = address(
            new LetdoStore{salt: salt}(
                storeName,
                storesCurrencyERC20,
                storePublicKey
            )
        );

        allStores.push(newStoreAddress);

        emit StoreCreated(newStoreAddress, msg.sender);

        return newStoreAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract LetdoStoreMetadata {
    string public storeName;
    address public storeOwner;
    address public storeCurrencyERC20;
    string public storePublicKey;

    error NotOwner();

    modifier onlyStoreOwner() {
        if (msg.sender != storeOwner) revert NotOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

struct LetdoEscrowOp {
    address sender;
    uint256 amount;
    uint256 timestamp;
    bool completed;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

struct LetdoItem {
    string metadataURI;
    uint256 price;
    bool available;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

struct LetdoOrder {
    string encryptedDeliveryAddress;
    uint256 amount;
    uint256 itemId;
    address buyer;
}
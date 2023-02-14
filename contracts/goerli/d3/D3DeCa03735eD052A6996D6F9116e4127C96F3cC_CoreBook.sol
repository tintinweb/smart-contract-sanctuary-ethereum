// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './interfaces/IWETH.sol';

contract CoreBook is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    // The address of the WETH contract
    address public wCORE;

    // Restriction Bools
    bool public isPaused;

    // The order info
    struct Order {
        // The address of the Lister
        address payable lister;
        // The time that the order started
        uint32 startTime;
        // The time that the order is scheduled to end
        uint32 endTime;
        // Is the order All or None
        bool allOrNone;
        // The token being sold
        IERC20 sellToken;
        // The amount of tokens to sell
        uint256 sellAmount;
        IERC20[] buyTokens;
        uint256[] buyAmounts;
        // The statuses of the order
        bool settled;
        bool canceled;
        bool failed;
    }
    mapping(uint256 => Order) public orderId;
    uint32 private currentId = 1;

    uint32 public activeOrderCount;

    uint16 public tax;
    address payable public taxWallet;

    modifier notPaused() {
        require(!isPaused, "Contract is Paused to new orders");
        _;
    }

    event OrderCreated(uint256 indexed OrderId, uint256 startTime, uint256 endTime, IERC20 SellToken, uint256 SellAmount, IERC20[] BuyTokens, uint256[] BuyAmounts);
    event OrderSinglePriceEdited(uint256 indexed OrderId, IERC20 BuyToken, uint256 OldBuyAmount, uint256 NewBuyAmount);
    event OrderEndTimeEdited(uint256 indexed OrderId, uint256 endTime);
    event OrderFulfilledFull(uint256 indexed OrderId, address Buyer, address Seller, IERC20 BuyToken, uint256 BuyAmount, uint256 SellAmount, uint256 TaxAmount);
    event OrderFulfilledPartial(uint256 indexed OrderId, address Buyer, address Seller, IERC20 BuyToken, uint256 BuyAmount, uint256 SellAmount, uint256 TaxAmount, uint256 SellAmountRemaining);
    event OrderRefunded(uint256 indexed OrderId, address Lister, IERC20 SellToken, uint256 SellAmountRefunded, address Caller);
    event OrderCanceled(uint256 indexed OrderId, address Lister, IERC20 SellToken, uint256 SellAmountRefunded, address Caller, uint256 TimeStamp);
    event Received(address indexed From, uint256 Amount);

    /**
     * @notice Initialize the order house and base contracts,
     * populate configuration values, and pause the contract.
     * @dev This function can only be called once.
     */
    constructor( 
        address _wcore,
        address payable _taxWallet, 
        uint16 _tax
    ) {
        wCORE = _wcore;
        taxWallet = _taxWallet;
        tax = _tax;
    }

    function setPaused(bool _flag) external onlyOwner {
        isPaused = _flag;
    }

    function setTax(address payable _taxWallet, uint16 _tax) external onlyOwner {
        taxWallet = _taxWallet;
        tax = _tax;
    }

    function createOrder(IERC20 _sellToken, uint256 _sellAmount, IERC20[] memory _buyTokens, uint256[] memory _buyAmounts, bool _allOrNone, uint32 _endTime) external notPaused nonReentrant {
        uint32 startTime = uint32(block.timestamp);
        uint32 _orderId = currentId++;

        orderId[_orderId].lister = payable(msg.sender);
        orderId[_orderId].sellToken = _sellToken;
        orderId[_orderId].sellAmount = _sellAmount;
        orderId[_orderId].buyTokens = _buyTokens;
        orderId[_orderId].buyAmounts = _buyAmounts;
        orderId[_orderId].allOrNone = _allOrNone;
        orderId[_orderId].startTime = startTime;
        orderId[_orderId].endTime = _endTime;
        activeOrderCount++;

        _sellToken.safeTransferFrom(msg.sender, address(this), _sellAmount);

        emit OrderCreated(_orderId, startTime, _endTime, _sellToken, _sellAmount, _buyTokens, _buyAmounts);
    }

    function createOrderCore(uint256 _sellAmount, IERC20[] memory _buyTokens, uint256[] memory _buyAmounts, bool _allOrNone, uint32 _endTime) external payable notPaused nonReentrant {
        require(_sellAmount == msg.value, "Wrong CORE amount sent");
        uint32 startTime = uint32(block.timestamp);
        uint32 _orderId = currentId++;

        orderId[_orderId].lister = payable(msg.sender);
        orderId[_orderId].sellToken = IERC20(wCORE);
        orderId[_orderId].sellAmount = _sellAmount;
        orderId[_orderId].buyTokens = _buyTokens;
        orderId[_orderId].buyAmounts = _buyAmounts;
        orderId[_orderId].allOrNone = _allOrNone;
        orderId[_orderId].startTime = startTime;
        orderId[_orderId].endTime = _endTime;
        activeOrderCount++;

        // IWETH(wCORE).deposit{value: msg.value}();

        emit OrderCreated(_orderId, startTime, _endTime, IERC20(wCORE), _sellAmount, _buyTokens, _buyAmounts);
    }

    function cancelOrder(uint32 _id) external nonReentrant {
        require(msg.sender == orderId[_id].lister, "Only Lister can cancel");
        require(orderStatus(_id) == 1, "Order is not active");
        orderId[_id].canceled = true;

        activeOrderCount--;
        orderId[_id].sellToken.safeTransfer(orderId[_id].lister, orderId[_id].sellAmount);

        emit OrderCanceled(_id, orderId[_id].lister, orderId[_id].sellToken, orderId[_id].sellAmount, msg.sender, block.timestamp);
    }

    function editOrderPricesAll(uint32 _id, IERC20[] memory _buyTokens, uint256[] memory _buyAmounts) external notPaused nonReentrant {
        require(msg.sender == orderId[_id].lister, "Only Lister can edit");
        require(orderStatus(_id) == 1, "Order is not active");
        uint256 lt = _buyTokens.length;
        uint256 la = _buyAmounts.length;
        require(lt == la && la == orderId[_id].buyTokens.length, "Must update all prices");

        uint256 _oldBuyAmount;
        for(uint i = 0; i < lt; i++) {
            require(_buyTokens[i] == orderId[_id].buyTokens[i], "Tokens misordered");
            _oldBuyAmount = orderId[_id].buyAmounts[i];
            orderId[_id].buyAmounts[i] = _buyAmounts[i];
            emit OrderSinglePriceEdited(_id, _buyTokens[i], _oldBuyAmount, _buyAmounts[i]);
        }
    }

    function editOrderPriceSingle(uint32 _id, uint256 _index, IERC20 _buyToken, uint256 _buyAmount) external notPaused nonReentrant {
        require(msg.sender == orderId[_id].lister, "Only Lister can edit");
        require(orderStatus(_id) == 1, "Order is not active");
        require(_buyToken == orderId[_id].buyTokens[_index], "Token does not exist at index");

        uint256 _oldBuyAmount = orderId[_id].buyAmounts[_index];
        orderId[_id].buyAmounts[_index] = _buyAmount;

        emit OrderSinglePriceEdited(_id, _buyToken, _oldBuyAmount, _buyAmount);
    }

    function editOrderEndTime(uint32 _id, uint32 _newEndTime) external notPaused nonReentrant {
        require(msg.sender == orderId[_id].lister, "Only Lister can edit");
        require(orderStatus(_id) == 1, "Order is not active");
        require(_newEndTime > block.timestamp, "End time already passed");

        orderId[_id].endTime = _newEndTime;

        emit OrderEndTimeEdited(_id, _newEndTime);
    }

    function executeOrder(uint32 _id, uint256 index, IERC20 _token, uint256 _amount) external nonReentrant {
        require(orderStatus(_id) == 1 && !orderId[_id].settled, 'Order has already been settled or canceled');
        require(block.timestamp <= orderId[_id].endTime, 'Order has expired');
        require(_token == orderId[_id].buyTokens[index], "Invalid Token");

        uint256 orderBuyAmount = orderId[_id].buyAmounts[index];
        if(_amount == orderBuyAmount) {
            fulfillFullOrder(msg.sender, _id, _token, _amount);
        } else {
            require(!orderId[_id].allOrNone, "Order is All or None");
            require(_amount < orderBuyAmount, "Invalid Amount");
            fulfillPartialOrder(msg.sender, _id, index, _token, _amount);
        }
    }

    function fulfillFullOrder(address _taker, uint32 _id, IERC20 _token, uint256 _amount) internal {
        orderId[_id].settled = true;
        activeOrderCount--;

        uint256 taxAmount = _amount * tax / 10000;
        uint256 finalAmount = _amount - taxAmount;

        _token.safeTransferFrom(_taker, taxWallet, taxAmount);
        _token.safeTransferFrom(_taker, orderId[_id].lister, finalAmount);
        if(orderId[_id].sellToken == IERC20(wCORE)) {
            _safeTransferETHWithFallback(_taker, orderId[_id].sellAmount);
        } else {
            orderId[_id].sellToken.safeTransfer(_taker, orderId[_id].sellAmount);
        }

        emit OrderFulfilledFull(_id, _taker, orderId[_id].lister, _token, _amount, orderId[_id].sellAmount, taxAmount);
    }

    function fulfillPartialOrder(address _taker, uint32 _id, uint256 index, IERC20 _token, uint256 _amount) internal {
        uint256 _fullSellAmount = orderId[_id].sellAmount;
        uint256 _fullBuyAmount = orderId[_id].buyAmounts[index];
        uint256 adjuster = ((_amount * 10**18) / _fullBuyAmount);
        uint256 _partialSellAmount = ((_fullSellAmount * adjuster) / 10**18);
        orderId[_id].sellAmount -= _partialSellAmount;

        uint256 l = orderId[_id].buyTokens.length;
        uint256 b;
        uint256 n;
        for(uint i = 0; i < l; i++) {
            b = orderId[_id].buyAmounts[i];
            n = (b - ((b * adjuster) / 10**18));
            orderId[_id].buyAmounts[i] = n;
            emit OrderSinglePriceEdited(_id, orderId[_id].buyTokens[i], b, n);
        }

        uint256 taxAmount = _amount * tax / 10000;
        uint256 finalAmount = _amount - taxAmount;

        _token.safeTransferFrom(_taker, taxWallet, taxAmount);
        _token.safeTransferFrom(_taker, orderId[_id].lister, finalAmount);
        if(orderId[_id].sellToken == IERC20(wCORE)) {
            _safeTransferETHWithFallback(_taker, _partialSellAmount);
        } else {
            orderId[_id].sellToken.safeTransfer(_taker, _partialSellAmount);
        }

        emit OrderFulfilledPartial(_id, _taker, orderId[_id].lister, _token, _amount, _partialSellAmount, taxAmount, orderId[_id].sellAmount);
    }

    function executeOrderCore(uint32 _id, uint256 index) external payable nonReentrant {
        require(orderStatus(_id) == 1 && !orderId[_id].settled, 'Order has already been settled or canceled');
        require(block.timestamp <= orderId[_id].endTime, 'Order has expired');
        IERC20 _token = IERC20(wCORE);
        require(_token == orderId[_id].buyTokens[index], "Invalid Token");

        uint256 _amount = msg.value;
        uint256 orderBuyAmount = orderId[_id].buyAmounts[index];
        if(_amount == orderBuyAmount) {
            fulfillFullOrderCore(msg.sender, _id, _token, _amount);
        } else {
            require(!orderId[_id].allOrNone, "Order is All or None");
            require(_amount < orderBuyAmount, "Invalid Amount");
            fulfillPartialOrderCore(msg.sender, _id, index, _token, _amount);
        }
    }

    function fulfillFullOrderCore(address _taker, uint32 _id, IERC20 _token, uint256 _amount) internal {
        orderId[_id].settled = true;
        activeOrderCount--;

        uint256 taxAmount = _amount * tax / 10000;
        uint256 finalAmount = _amount - taxAmount;

        _safeTransferETHWithFallback(taxWallet, taxAmount);
        _safeTransferETHWithFallback(orderId[_id].lister, finalAmount);
        orderId[_id].sellToken.safeTransfer(_taker, orderId[_id].sellAmount);

        emit OrderFulfilledFull(_id, _taker, orderId[_id].lister, _token, _amount, orderId[_id].sellAmount, taxAmount);
    }

    function fulfillPartialOrderCore(address _taker, uint32 _id, uint256 index, IERC20 _token, uint256 _amount) internal {
        uint256 _fullSellAmount = orderId[_id].sellAmount;
        uint256 _fullBuyAmount = orderId[_id].buyAmounts[index];
        uint256 adjuster = ((_amount * 10**18) / _fullBuyAmount);
        uint256 _partialSellAmount = ((_fullSellAmount * adjuster) / 10**18);
        orderId[_id].sellAmount -= _partialSellAmount;

        uint256 l = orderId[_id].buyTokens.length;
        uint256 b;
        uint256 n;
        for(uint i = 0; i < l; i++) {
            b = orderId[_id].buyAmounts[i];
            n = (b - ((b * adjuster) / 10**18));
            orderId[_id].buyAmounts[i] = n;
            emit OrderSinglePriceEdited(_id, orderId[_id].buyTokens[i], b, n);
        }

        uint256 taxAmount = _amount * tax / 10000;
        uint256 finalAmount = _amount - taxAmount;

        _safeTransferETHWithFallback(taxWallet, taxAmount);
        _safeTransferETHWithFallback(orderId[_id].lister, finalAmount);
        orderId[_id].sellToken.safeTransfer(_taker, _partialSellAmount);

        emit OrderFulfilledPartial(_id, _taker, orderId[_id].lister, _token, _amount, _partialSellAmount, taxAmount, orderId[_id].sellAmount);
    }

    function claimRefundOnExpire(uint32 _id) external nonReentrant {
        require(msg.sender == orderId[_id].lister || msg.sender == owner(), 'Only Lister caan initiate refund');
        require(orderStatus(_id) == 3, 'Order has not expired');
        require(!orderId[_id].failed && !orderId[_id].canceled, 'Refund already claimed');
        orderId[_id].failed = true;
        activeOrderCount--;
        IERC20 token = orderId[_id].sellToken;
        if(token == IERC20(wCORE)) {
            _safeTransferETHWithFallback(orderId[_id].lister, orderId[_id].sellAmount);
        } else {
            token.safeTransfer(orderId[_id].lister, orderId[_id].sellAmount);
        }
        

        emit OrderRefunded(_id, orderId[_id].lister, orderId[_id].sellToken, orderId[_id].sellAmount, msg.sender);
    }

    function emergencyCancelOrder(uint32 _id) external nonReentrant onlyOwner {
        require(orderStatus(_id) == 1, "Order is not active");
        orderId[_id].canceled = true;

        activeOrderCount--;

        IERC20 token = orderId[_id].sellToken;
        if(token == IERC20(wCORE)) {
            _safeTransferETHWithFallback(orderId[_id].lister, orderId[_id].sellAmount);
        } else {
            token.safeTransfer(orderId[_id].lister, orderId[_id].sellAmount);
        }

        emit OrderCanceled(_id, orderId[_id].lister, orderId[_id].sellToken, orderId[_id].sellAmount, msg.sender, block.timestamp);
    }

    function orderStatus(uint32 _id) public view returns (uint8) {
        if (orderId[_id].canceled) {
        return 3; // CANCELED - Lister canceled
        }
        if ((block.timestamp > orderId[_id].endTime) && !orderId[_id].settled) {
        return 3; // FAILED - not sold by end time
        }
        if (orderId[_id].settled) {
        return 2; // SUCCESS - hardcap met
        }
        if ((block.timestamp <= orderId[_id].endTime) && !orderId[_id].settled) {
        return 1; // ACTIVE - deposits enabled
        }
        return 0; // QUEUED - awaiting start time
    }

    function getAllActiveOrders() external view returns (uint32[] memory _activeOrders) {
        uint256 length = activeOrderCount;
        _activeOrders = new uint32[](length);
        uint32 z = 0;
        for(uint32 i = 1; i <= currentId; i++) {
            if(orderStatus(i) == 1) {
                _activeOrders[z] = i;
                z++;
            } else {
                continue;
            }
        }
    }

    function getAllOrders() external view returns (uint32[] memory orders, uint8[] memory status) {
        orders = new uint32[](currentId);
        status = new uint8[](currentId);
        for(uint32 i = 1; i < currentId; i++) {
            orders[i - 1] = i;
            status[i - 1] = orderStatus(i);
        }
    }

    /**
     * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     */
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(wCORE).deposit{ value: amount }();
            IERC20(wCORE).transfer(to, amount);
        }
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function transfer(address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
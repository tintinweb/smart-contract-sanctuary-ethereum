//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IToken.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// This contract can be automated using automatic function call services, such as Gelato.
// Therefore, there are no checks in the contract on whether the time of the round has ended or not,
// but there is only a check on which round is currently underway.

// Error list:
//     ERROR #1 = You cannot call this function in this round;
//     ERROR #2 = The order you are trying to delete does not exist;
//     ERROR #3 = You have already registered;
//     ERROR #4 = Referrer should be registred;
//     ERROR #5 = The last round is not over yet;
//     ERROR #6 = The last round has not ended yet or all tokens have not been sold;
//     ERROR #7 = There are not enough tokens left in this round for your transaction;
//     ERROR #8 = You are trying to buy more tokens than there are in the order;
//     ERROR #9 = You cannot delete this order;

contract SalePlatform is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    address public token;

    Counters.Counter public roundId;
    Counters.Counter public orderId;

    uint256 public roundTimeDuration;
    uint256 public lastTokenPrice;

    uint256 public rewardForL1ReffererInSale;
    uint256 public rewardForL2ReffererInSale;
    uint256 public rewardForRefferersInTrade;

    uint256 public tokensOnSell;

    RoundType public currentRoundType;

    event Registred(address indexed referral, address indexed referrer);
    event SaleRoundEnded(
        uint256 indexed roundId,
        uint256 tokenPrice,
        uint256 tokenSupply,
        uint256 tokensBuyed
    );
    event TradeRoundEnded(
        uint256 indexed roundId,
        uint256 tradeVolume,
        uint256 ordersAmount
    );
    event TokensPurchased(
        address indexed buyer,
        uint256 indexed roundId,
        uint256 tokensAmount
    );
    event OrderAdded(
        address indexed seller,
        uint256 indexed orderId,
        uint256 tokensAmount,
        uint256 tokenPrice
    );
    event OrderRemoved(
        address indexed seller,
        uint256 indexed orderId,
        uint256 tokensWithdrawn,
        uint256 tokenPrice
    );
    event OrderRedeemed(
        address indexed buyer,
        uint256 indexed orderId,
        uint256 tokensAmount,
        uint256 tokenPrice
    );

    enum RoundType {
        SALE,
        TRADE
    }

    struct TradeRound {
        uint256 totalTradeVolume;
        uint256 endTime;
        uint256 ordersAmount;
    }

    struct SaleRound {
        // There is already a global variable of the current price,
        // but here it is additionally so that it can be tracked in history.
        uint256 tokenPrice;
        uint256 tokenSupply;
        uint256 endTime;
        uint256 tokensBuyed;
    }

    struct ReferralProgram {
        bool isRegistred;
        address userReferrer;
    }

    struct Order {
        address seller;
        uint256 tokensToSell;
        uint256 tokenPrice;
    }

    mapping(address => ReferralProgram) private referralProgram;

    mapping(uint256 => SaleRound) private saleRounds;
    mapping(uint256 => TradeRound) private tradeRounds;
    mapping(uint256 => Order) private orders;

    constructor(
        address _token,
        uint256 _roundTime,
        uint256 saleL1Rewards,
        uint256 saleL2Rewards,
        uint256 tradeReward,
        uint256 startTokenPrice,
        uint256 startTokenAmount
    ) {
        token = _token;
        roundTimeDuration = _roundTime;

        rewardForL1ReffererInSale = saleL1Rewards;
        rewardForL2ReffererInSale = saleL2Rewards;

        rewardForRefferersInTrade = tradeReward;

        // Genesis round for platform.
        saleRounds[0] = SaleRound(
            startTokenPrice,
            startTokenAmount,
            block.timestamp + roundTimeDuration,
            0
        );
        lastTokenPrice = startTokenPrice;
        currentRoundType = RoundType.SALE;
    }

    modifier isCorrectRound(RoundType round) {
        require(currentRoundType == round, "Platform: ERROR #1");
        _;
    }

    modifier isOrderExist(uint256 _orderId) {
        require(_orderId <= orderId.current(), "Platform: ERROR #2");
        _;
    }

    function register(address referrer) external {
        address registering = _msgSender();

        require(
            !referralProgram[registering].isRegistred,
            "Platform: ERROR #3"
        );

        if (referrer != address(0)) {
            require(
                referralProgram[referrer].isRegistred,
                "Platform: ERROR #4"
            );
            referralProgram[registering].userReferrer = referrer;
        }

        referralProgram[registering].isRegistred = true;

        emit Registred(registering, referrer);
    }

    function startSaleRound() external isCorrectRound(RoundType.TRADE) {
        uint256 tradeRoundId = roundId.current();
        TradeRound memory lastTradeRound = tradeRounds[tradeRoundId];

        require(
            lastTradeRound.endTime <= block.timestamp,
            "Platform: ERROR #5"
        );

        _startSaleRound();

        emit TradeRoundEnded(
            tradeRoundId,
            lastTradeRound.totalTradeVolume,
            lastTradeRound.ordersAmount
        );

        // If the trading volume was equal to 0,
        // then we start the next round,
        // since the volume of tokens for sale would be equal to 0.

        if (lastTradeRound.totalTradeVolume == 0) {
            emit SaleRoundEnded(roundId.current(), lastTokenPrice, 0, 0);
            _startTradeRound();
        }
    }

    function startTradeRound() external isCorrectRound(RoundType.SALE) {
        uint256 saleRoundId = roundId.current();
        SaleRound memory lastSaleRound = saleRounds[saleRoundId];

        require(
            lastSaleRound.endTime <= block.timestamp ||
                lastSaleRound.tokenSupply == lastSaleRound.tokensBuyed,
            "Platform: ERROR #6"
        );

        _startTradeRound();

        emit SaleRoundEnded(
            saleRoundId,
            lastSaleRound.tokenPrice,
            lastSaleRound.tokenSupply,
            lastSaleRound.tokensBuyed
        );
    }

    // In the two following functions - there could be checks that msg.value > 0,
    // but in theory, this should not lead to any problems, since there will be 0 in all values, too.
    // The only thing is that users who send 0 wei will have to pay a full commission,
    // as if they have a normal transaction, but on the other hand, we will save on checking for adequate users.

    function buyToken()
        external
        payable
        isCorrectRound(RoundType.SALE)
        nonReentrant
    {
        address buyer = _msgSender();
        uint256 currentRoundId = roundId.current();
        uint256 tokensAmount = calculateTokensAmount(msg.value);
        SaleRound storage currentRound = saleRounds[currentRoundId];

        require(
            tokensAmount <= currentRound.tokenSupply - currentRound.tokensBuyed,
            "Platform: ERROR #7"
        );

        IERC20(token).transfer(buyer, tokensAmount);
        currentRound.tokensBuyed += tokensAmount;

        payToRefferers(buyer);

        emit TokensPurchased(buyer, currentRoundId, tokensAmount);
    }

    function addOrder(uint256 amount, uint256 priceInETH)
        external
        isCorrectRound(RoundType.TRADE)
    {
        address seller = _msgSender();

        IERC20(token).transferFrom(seller, address(this), amount);
        tokensOnSell += amount;

        orderId.increment();
        orders[orderId.current()] = Order(seller, amount, priceInETH);

        tradeRounds[roundId.current()].ordersAmount++;

        emit OrderAdded(seller, orderId.current(), amount, priceInETH);
    }

    function redeemOrder(uint256 _orderId)
        external
        payable
        nonReentrant
        isCorrectRound(RoundType.TRADE)
        isOrderExist(_orderId)
    {
        Order storage currentOrder = orders[_orderId];

        uint256 tokensAmount = msg.value / currentOrder.tokenPrice;
        require(
            currentOrder.tokensToSell >= tokensAmount,
            "Platform: ERROR #8"
        );

        address buyer = _msgSender();
        uint256 amountToSeller = msg.value -
            ((msg.value / 100) * (rewardForRefferersInTrade * 2));

        IERC20(token).transfer(buyer, tokensAmount);

        tokensOnSell -= tokensAmount;
        currentOrder.tokensToSell -= tokensAmount;
        tradeRounds[roundId.current()].totalTradeVolume += msg.value;

        Address.sendValue(payable(currentOrder.seller), amountToSeller);
        payToRefferers(currentOrder.seller);

        emit OrderRedeemed(
            buyer,
            _orderId,
            tokensAmount,
            currentOrder.tokenPrice
        );
    }

    function removeOrder(uint256 _orderId)
        external
        isCorrectRound(RoundType.TRADE)
        isOrderExist(_orderId)
    {
        Order memory currentOrder = orders[_orderId];

        // Either the order has already been deleted,
        // or the caller is not the owner of this order
        require(currentOrder.seller == _msgSender(), "Platform: ERROR #9");

        // It makes no sense to leave information about the order in storage,
        // since after assigning tokensToSell = 0, the rest of the information does not seem important.
        // And everything you need can be viewed in the event.
        // Therefore, in order to save gas, we delete the order from storage.
        delete orders[_orderId];

        if (currentOrder.tokensToSell != 0) {
            IERC20(token).transfer(
                currentOrder.seller,
                currentOrder.tokensToSell
            );
            tokensOnSell -= currentOrder.tokensToSell;
        }

        emit OrderRemoved(
            currentOrder.seller,
            _orderId,
            currentOrder.tokensToSell,
            currentOrder.tokenPrice
        );
    }

    // Private functions
    function _startSaleRound() private {
        uint256 newTokensAmount = calculateTokensAmount(
            tradeRounds[roundId.current()].totalTradeVolume
        );

        lastTokenPrice = calculateNewPrice();

        roundId.increment();

        saleRounds[roundId.current()] = SaleRound(
            lastTokenPrice,
            newTokensAmount,
            block.timestamp + roundTimeDuration,
            0
        );

        currentRoundType = RoundType.SALE;

        IToken(token).mint(address(this), newTokensAmount);
    }

    function _startTradeRound() private {
        uint256 balance = IERC20(token).balanceOf(address(this));

        if (balance > 0) {
            IToken(token).burn(balance - tokensOnSell);
        }

        roundId.increment();
        tradeRounds[roundId.current()] = TradeRound(
            0,
            block.timestamp + roundTimeDuration,
            0
        );

        currentRoundType = RoundType.TRADE;
    }

    function payToRefferers(address seller) private {
        address l1Refferer = referralProgram[seller].userReferrer;

        if (currentRoundType == RoundType.SALE) {
            if (l1Refferer != address(0)) {
                Address.sendValue(
                    payable(l1Refferer),
                    (msg.value / 100) * rewardForL1ReffererInSale
                );

                address l2Refferer = referralProgram[l1Refferer].userReferrer;
                if (l2Refferer != address(0)) {
                    Address.sendValue(
                        payable(l2Refferer),
                        (msg.value / 100) * rewardForL2ReffererInSale
                    );
                }
            }
        } else {
            if (l1Refferer != address(0)) {
                Address.sendValue(
                    payable(l1Refferer),
                    (msg.value / 100) * rewardForRefferersInTrade
                );

                address l2Refferer = referralProgram[l1Refferer].userReferrer;
                if (l2Refferer != address(0)) {
                    Address.sendValue(
                        payable(l2Refferer),
                        (msg.value / 100) * rewardForRefferersInTrade
                    );
                }
            }
        }
    }

    // Utils functions for calculating new values
    function calculateNewPrice() private view returns (uint256) {
        return (lastTokenPrice * 103) / 100 + 4000000000000;
    }

    function calculateTokensAmount(uint256 value)
        private
        view
        returns (uint256)
    {
        return (value / lastTokenPrice) * 10**18;
    }

    // Getters
    function getUserReferrer(address _user) external view returns (address) {
        return referralProgram[_user].userReferrer;
    }

    function isUserRegistred(address _user) external view returns (bool) {
        return referralProgram[_user].isRegistred;
    }

    function getTokensBuyed(uint256 _roundId) external view returns (uint256) {
        return saleRounds[_roundId].tokensBuyed;
    }

    function getSaleRoundEndTime(uint256 _roundId)
        external
        view
        returns (uint256)
    {
        return saleRounds[_roundId].endTime;
    }

    function getSaleRoundTokenSupply(uint256 _roundId)
        external
        view
        returns (uint256)
    {
        return saleRounds[_roundId].tokenSupply;
    }

    function getTotalTradeVolume(uint256 _roundId)
        external
        view
        returns (uint256)
    {
        return tradeRounds[_roundId].totalTradeVolume;
    }

    function getTradeRoundEndTime(uint256 _roundId)
        external
        view
        returns (uint256)
    {
        return tradeRounds[_roundId].endTime;
    }

    function getTradeRoundOrdersAmount(uint256 _roundId)
        external
        view
        returns (uint256)
    {
        return tradeRounds[_roundId].ordersAmount;
    }

    function getSellerOfOrder(uint256 _orderId)
        external
        view
        returns (address)
    {
        return orders[_orderId].seller;
    }

    function getOrderTokenPrice(uint256 _orderId)
        external
        view
        returns (uint256)
    {
        return orders[_orderId].tokenPrice;
    }

    function getOrderTokensAmount(uint256 _orderId)
        external
        view
        returns (uint256)
    {
        return orders[_orderId].tokensToSell;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IToken {
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address owner, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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
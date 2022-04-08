// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

import "./interface/IACDMToken.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ACDMPlatform is ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _orderIds;
    uint256 public constant saleCommissionFirstLvl = 50;
    uint256 public constant saleCommissionSecondLvl = 30;
    uint256 public constant tradeCommission = 25;

    IACDMToken public token;
    Round public roundType;
    uint256 public roundTime;
    uint256 public roundEndTime;
    uint256 public tradeETHVolume;
    uint256 public tradeACDMVolume;
    uint256 public tokenPrice;

    struct Order {
        address seller;
        uint256 amountACDM;
        uint256 amountETH;
    }

    enum Round {
        Sale,
        Trade
    }

    event Register(address user, address referrer);
    event BoughtACDM(address user, uint256 amount);
    event SaleRoundStarted(uint256 timestamp);
    event TradeRoundStarted(uint256 timestamp);
    event OrderAdded(uint256 idOrder, uint256 amountACDM, uint256 amountETH);
    event OrderRemoved(uint256 idOrder);
    event OrderRedeemed(address buyer, uint256 idOrder, uint256 amountACDM);

    mapping(address => address) referrers;
    mapping(uint256 => Order) public orders;

    constructor(IACDMToken _token, uint256 _roundTime) {
        token = _token;
        roundType = Round.Sale;
        roundTime = _roundTime;
        roundEndTime = block.timestamp + _roundTime;
        tradeETHVolume = 1 ether;
        tradeACDMVolume = 10**5;
        tokenPrice = tradeETHVolume / tradeACDMVolume;
    }

    function register(address _referrer) public {
        require(
            referrers[msg.sender] == address(0),
            "This address already has a referrer"
        );
        require(msg.sender != _referrer, "Cannot refer yourself");
        referrers[msg.sender] = _referrer;
        emit Register(msg.sender, _referrer);
    }

    function _payReferral(
        uint256 commissionValFirst,
        uint256 commissionValSecond
    ) private {
        if (referrers[msg.sender] != address(0)) {
            _sendETH(referrers[msg.sender], commissionValFirst);
            if (referrers[referrers[msg.sender]] != address(0)) {
                _sendETH(referrers[referrers[msg.sender]], commissionValSecond);
            }
        }
    }

    function buyACDM(uint256 _amount) public payable nonReentrant {
        require(
            roundType == Round.Sale,
            "Cannot buy ACDM tokens during trade round"
        );
        require(
            _amount <= tradeACDMVolume,
            "Cannot buy more tokens than supply"
        );
        require(msg.value >= tokenPrice * _amount, "Not enough ETH");
        token.transfer(msg.sender, _amount);
        _payReferral(
            (msg.value * saleCommissionFirstLvl) / 1000,
            (msg.value * saleCommissionSecondLvl) / 1000
        );
        tradeACDMVolume -= _amount;
        emit BoughtACDM(msg.sender, _amount);
    }

    function startSaleRound() public {
        require(roundType != Round.Sale, "Sale round is already active");
        require(
            block.timestamp > roundEndTime,
            "Wait until trade round is over"
        );
        roundType = Round.Sale;
        roundEndTime = block.timestamp + roundTime;
        token.burn(address(this), tradeACDMVolume);
        //Check trade volume to avoid price dropping to zero
        if (tradeETHVolume > 0) {
            tradeACDMVolume = tradeETHVolume / tokenPrice;
        } else {
            tradeETHVolume = 1 ether; //Start with default value
        }
        tokenPrice = (tokenPrice * 103) / 100 + 4 * 10**12 wei;
        token.mint(address(this), tradeACDMVolume);
        uint256 ordersNum = _orderIds.current();
        for (uint256 i = 0; i < ordersNum; i++) {
            token.transfer(orders[i].seller, orders[i].amountACDM);
            delete orders[i];
            _orderIds.decrement();
        }
        emit SaleRoundStarted(block.timestamp);
    }

    function startTradeRound() public {
        require(roundType != Round.Trade, "Trade round is already active");
        require(
            block.timestamp > roundEndTime || tradeACDMVolume == 0,
            "Wait until sale round is over"
        );
        roundType = Round.Trade;
        roundEndTime = block.timestamp + roundTime;
        tradeETHVolume = 0;
        emit TradeRoundStarted(block.timestamp);
    }

    function addOrder(uint256 _amountACDM, uint256 _amountETH) public {
        require(roundType == Round.Trade, "Wait until sale round is over");
        require(
            token.balanceOf(msg.sender) >= _amountACDM,
            "Not enough ACDM tokens"
        );
        token.transferFrom(msg.sender, address(this), _amountACDM);
        uint256 idOrder = _orderIds.current();
        orders[idOrder].seller = msg.sender;
        orders[idOrder].amountACDM = _amountACDM;
        orders[idOrder].amountETH = _amountETH;
        _orderIds.increment();
        emit OrderAdded(idOrder, _amountACDM, _amountETH);
    }

    function removeOrder(uint256 _idOrder) public {
        require(
            orders[_idOrder].seller == msg.sender,
            "You cannot remove this order"
        );
        //Soft remove to preserve orders consistency during active round
        token.transfer(orders[_idOrder].seller, orders[_idOrder].amountACDM);
        orders[_idOrder].amountACDM = 0;
        orders[_idOrder].amountETH = 0;
        emit OrderRemoved(_idOrder);
    }

    function redeemOrder(uint256 _amount, uint256 _idOrder)
        public
        payable
        nonReentrant
    {
        require(orders[_idOrder].seller != address(0), "Order does not exist");
        require(
            orders[_idOrder].amountACDM >= _amount,
            "Order does not have enough tokens"
        );
        require(
            msg.value >=
                (orders[_idOrder].amountETH / orders[_idOrder].amountACDM) *
                    _amount,
            "Not enough ETH"
        );
        token.transfer(msg.sender, _amount);
        uint256 paidETH = (orders[_idOrder].amountETH /
            orders[_idOrder].amountACDM) * _amount;
        _sendETH(orders[_idOrder].seller, (paidETH * 95) / 100);
        _payReferral(
            (paidETH * tradeCommission) / 1000,
            (paidETH * tradeCommission) / 1000
        );
        tradeETHVolume += paidETH;
        orders[_idOrder].amountACDM -= _amount;
        orders[_idOrder].amountETH -= paidETH;
        emit OrderRedeemed(msg.sender, _idOrder, _amount);
    }

    function _sendETH(address _to, uint256 _amount) private returns (bool) {
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Could not send ETH");
        return sent;
    }

    function withdrawETH(address payable _to, uint256 _amount)
        public
        payable
        nonReentrant
        onlyOwner
    {
        require(address(this).balance > 0, "No ETH to withdraw");
        _sendETH(_to, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

interface IACDMToken {
    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function mint(address to, uint256 amount) external;

    function burn(address owner, uint256 amount) external;

    function balanceOf(address owner) external returns (uint256);
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
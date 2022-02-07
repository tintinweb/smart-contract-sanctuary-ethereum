// contracts/WAP.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";


contract WAP is Ownable {

    // the price for a monthly subscription (31 days)
    uint256 public MONTHLY_COST;
    // the monthly subscription duration in days
    uint256 public MONTHLY_DURATION = 31 days;
    // the price for a yearly subscription (365 days)
    uint256 public YEARLY_COST;
    // the yearly subscription duration in days
    uint256 public YEARLY_DURATION  = 365 days;
    // pause new subscriptions flag
    bool public newSubscriptionsEnabled = true;
    // the subscriptions map (address, end timestamp)
    mapping(address => uint256) private subscriptions;

    /**
     * @dev constructor
     */
    constructor(uint256 monthlyCost, uint256 yearlyCost) {
        require(yearlyCost > monthlyCost, "Configuration not valid");
        MONTHLY_COST = monthlyCost;
        YEARLY_COST  = yearlyCost;
    }

    /**
    * @dev returns true if the caller has a valid subscription
    */
    function hasValidSubscription() public view returns (bool) {
        return subscriptions[msg.sender] >= block.timestamp;
    }

    /**
    * @dev get the subscription end timestamp for the caller
    */
    function getSubscriptionEnd() public view returns (uint256) {
        return subscriptions[msg.sender];
    }

    /**
    * @dev pay for 31 additional days of subscription, the monthly cost is charged.
    */
    function payMonthlySubscription() public payable {
        require(newSubscriptionsEnabled, "New subscriptions not allowed");
        require(MONTHLY_COST == msg.value, "Ether value sent is not correct");

        // the caller can have valid subscription: extend it
        uint256 startTime = Math.max(subscriptions[msg.sender], block.timestamp);

        subscriptions[msg.sender] = startTime + MONTHLY_DURATION;
    }

    /**
    * @dev pay for 365 additional days of subscription, the yearly cost is charged.
    */
    function payYearlySubscription() public payable {
        require(newSubscriptionsEnabled, "New subscriptions not allowed");
        require(YEARLY_COST == msg.value, "Ether value sent is not correct");

        // the caller can have valid subscription: extend it
        uint256 startTime = Math.max(subscriptions[msg.sender], block.timestamp);

        subscriptions[msg.sender] = startTime + YEARLY_DURATION;
    }


    /**
     * @dev update all the subscription costs
     */
    function updateCosts(uint256 monthlyCost, uint256 yearlyCost) onlyOwner() public {
        require(yearlyCost > monthlyCost, "Configuration not valid");

        MONTHLY_COST = monthlyCost;
        YEARLY_COST  = yearlyCost;
    }

    /**
     * @dev toggle the status for the new subscriptions flag
     */
    function toggleNewSubscriptionsFlag() onlyOwner() public {
        newSubscriptionsEnabled = !newSubscriptionsEnabled;
    }

    /**
     * @dev gift a subscription to all the given wallets
     */
    function giftSubscription(address[] calldata wallets, uint256 numDays) onlyOwner() public {
        for(uint i = 0; i < wallets.length; i++){
            uint256 startTime = Math.max(subscriptions[wallets[i]], block.timestamp);
            subscriptions[wallets[i]] = startTime + (numDays * (1 days));
        }
    }

    /**
    * @dev check the subscription end timestamp for a given wallet
    */
    function checkSubscriptionEnd(address wallet) onlyOwner() public view returns (uint256) {
        return subscriptions[wallet];
    }

    /**
     * @dev withdraw contract balance to a specific destination
     */
    function withdraw(address destination) onlyOwner() public returns (bool) {
        uint balance = address(this).balance;
        (bool success,) = destination.call{value : balance}("");

        return success;
    }


    /* ================================================================================================== */
    /* FOR DEBUG ONLY                                                                                     */
    /* ================================================================================================== */
    function resetSubscription() public {
        subscriptions[msg.sender] = 0;
    }

    function modifyDuration(uint256 montyDays, uint256 yearlyDays) onlyOwner() public {
        MONTHLY_DURATION = montyDays * (1 days);
        YEARLY_DURATION  = yearlyDays * (1 days);
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
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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
// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @title RareBlocksSubscription contract
/// @author poster & SterMi
/// @notice Manage RareBlocks subscription for an amount of months
contract RareBlocksSubscription is Ownable, Pausable {
    /*///////////////////////////////////////////////////////////////
                             STORAGE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Subscription price per month
    uint256 public subscriptionMonthlyPrice;

    /// @notice map of subscriptions made by users that store the expire time for a subscription
    mapping(address => uint256) public subscriptions;

    /// @notice Treasury contract address
    address public treasury;

    /// @notice Affiliate fee percentage
    /// @dev 0 = 0%, 5000 = 50%, 10000 = 100%
    uint256 public referrerFee = 2000;

    /*///////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        uint256 _subscriptionMonthlyPrice,
        address _treasury
    ) Ownable() {
        // check that all the parameters are valid
        require(_subscriptionMonthlyPrice != 0, "INVALID_PRICE_PER_MONTH");
        require(_treasury != address(0), "INVALID_TREASURY_ADDRESSS");

        subscriptionMonthlyPrice = _subscriptionMonthlyPrice;
        treasury = _treasury;
    }

    /*///////////////////////////////////////////////////////////////
                             PAUSE LOGIC
    //////////////////////////////////////////////////////////////*/

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /*///////////////////////////////////////////////////////////////
                             REFERRER LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted after the owner update the referrer fee
    /// @param user The authorized user who triggered the update
    /// @param newReferrerFee The referrer fee paid to referrer
    event ReferrerFeeUpdated(address indexed user, uint256 newReferrerFee);

    function setReferrerFee(uint256 newReferrerFee) external onlyOwner {
        require(newReferrerFee != 0, "INVALID_PERCENTAGE");
        require(referrerFee != newReferrerFee, "SAME_FEE");
        require(newReferrerFee <= 10_000, "MAX_REACHED");

        referrerFee = newReferrerFee;

        emit ReferrerFeeUpdated(msg.sender, newReferrerFee);
    }

    /*///////////////////////////////////////////////////////////////
                             SUBSCRIPTION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted after the owner update the monthly price of a rareblocks
    /// @param user The authorized user who triggered the update
    /// @param newSubscriptionMonthlyPrice The price to subscribe to a RareBlocks pass for 1 month
    event SubscriptionMonthPriceUpdated(address indexed user, uint256 newSubscriptionMonthlyPrice);

    /// @notice Emitted after a user has subscribed to a RareBlocks pass
    /// @param user The user who purchased the pass subscription
    /// @param months The amount of month of the subscription
    /// @param price The price paid to subscribe to the pass
    event Subscribed(address indexed user, uint256 months, uint256 price);

    /// @notice Emitted after a user has subscribed to a RareBlocks pass
    /// @param user The user who purchased the pass subscription
    /// @param referrer The affiliate who got paid
    /// @param fee The price paid to subscribe to the pass
    event PaidReferrer(address indexed user, address indexed referrer, uint256 fee);

    function setSubscriptionMonthlyPrice(uint256 newSubscriptionMonthlyPrice) external onlyOwner {
        require(newSubscriptionMonthlyPrice != 0, "INVALID_PRICE");
        require(subscriptionMonthlyPrice != newSubscriptionMonthlyPrice, "SAME_PRICE");

        subscriptionMonthlyPrice = newSubscriptionMonthlyPrice;

        emit SubscriptionMonthPriceUpdated(msg.sender, newSubscriptionMonthlyPrice);
    }

    function subscribe(uint256 months, address referrer) external payable whenNotPaused {
        // Check that the user amount of months is valid
        require(months > 0 && months <= 12, "INVALID_AMOUNT_OF_MONTHS");

        uint256 totalPrice = months * subscriptionMonthlyPrice;

        // Provide 3 months free when signing up yearly
        if(months == 12){
            totalPrice = 9 * subscriptionMonthlyPrice;
        }

        // check if the user has sent enough funds to subscribe to the pass
        require(msg.value == totalPrice, "NOT_ENOUGH_FUNDS");

        // check that the user has not an active pass
        require(subscriptions[msg.sender] < block.timestamp, "SUBSCRIPTION_STILL_ACTIVE");

        // Update subscriptions
        subscriptions[msg.sender] = block.timestamp + (31 days * months);

        // emit the event
        emit Subscribed(msg.sender, months, totalPrice);

        // Payout affiliate if not null address and not own wallet
        if(referrer != address(0) && referrer != msg.sender){
            uint256 affiliateAmount = (msg.value * referrerFee) / 10_000;
            (bool success, ) = referrer.call{value: affiliateAmount}("");
            require(success, "WITHDRAW_FAIL");

            emit PaidReferrer(msg.sender, referrer, affiliateAmount);
        }
    }

    function isSubscriptionActive(address _address) external view returns (bool) {
        return subscriptions[_address] > block.timestamp;
    }

    /*///////////////////////////////////////////////////////////////
                             TREASURY LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted after the owner pull the funds to the treasury address
    /// @param user The authorized user who triggered the withdraw
    /// @param treasury The treasury address to which the funds have been sent
    /// @param amount The amount withdrawn
    event TreasuryWithdraw(address indexed user, address treasury, uint256 amount);

    /// @notice Emitted after the owner pull the funds to the treasury address
    /// @param user The authorized user who triggered the withdraw
    /// @param newTreasury The new treasury address
    event TreasuryUpdated(address indexed user, address newTreasury);

    function setTreasury(address _treasury) external onlyOwner {
        // check that the new treasury address is valid
        require(_treasury != address(0), "INVALID_TREASURY_ADDRESS");
        require(treasury != _treasury, "SAME_TREASURY_ADDRESS");

        // update the treasury
        treasury = _treasury;

        // emit the event
        emit TreasuryUpdated(msg.sender, _treasury);
    }

    function withdrawTreasury() external onlyOwner {
        // calc the amount of balance that can be sent to the treasury
        uint256 amount = address(this).balance;
        require(amount != 0, "NO_TREASURY");

        // emit the event
        emit TreasuryWithdraw(msg.sender, treasury, amount);

        // Transfer to the treasury
        (bool success, ) = treasury.call{value: amount}("");
        require(success, "WITHDRAW_FAIL");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
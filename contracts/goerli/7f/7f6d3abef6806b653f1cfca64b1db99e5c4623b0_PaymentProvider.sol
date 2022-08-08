/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/PaymentProvider.sol



pragma solidity ^0.8.10;



// Contract written by Unavailable
contract PaymentProvider is Ownable, ReentrancyGuard {

    struct SubscriptionPlan {
        uint256 price;
        uint256 renewalFee;
        uint256 duration;
    }

    struct Subscription {
        uint256 tier;
        uint256 expiration;
    }

    mapping(uint256 => SubscriptionPlan) public subscriptionPlans; // Different plans. Tier => Plan
    mapping(address => Subscription) public subscriptions; // Address => Subscription

    // TODO: find optimal pricing
    constructor() {
        // Plan #1
        // Buy the tool with 1 month access
        subscriptionPlans[1] = SubscriptionPlan(
            0.3 ether,
            0.1 ether,
            30 days
        );
        // Plan #2
        // Buy the tool with 3 months access
        subscriptionPlans[2] = SubscriptionPlan(
            0.45 ether,
            0.09 ether,
            90 days
        );
        // Plan #3
        // Buy the tool with 6 months access
        subscriptionPlans[3] = SubscriptionPlan(
            0.6 ether,
            0.08 ether,
            180 days
        );
    }

    // Get the subscription information from the given tier
    function getSubscriptionPlan(uint256 _tier) public view returns (SubscriptionPlan memory) {
        SubscriptionPlan memory plan = subscriptionPlans[_tier];
        require(plan.duration > 0, "Plan does not exist.");

        return plan;
    }

    // Get the subscription from the given user address
    function getUserSubscription(address _address) public view returns (Subscription memory) {
        Subscription memory subscription = subscriptions[_address];
        require(subscription.tier > 0, "Address has no plan.");

        return subscription;
    }

    // Get the subscription plan from the given user address
    function getUserSubscriptionPlan(address _address) public view returns (SubscriptionPlan memory) {
        Subscription memory subscription = subscriptions[_address];
        require(subscription.tier > 0, "Address has no plan.");
        SubscriptionPlan memory plan = subscriptionPlans[subscription.tier];

        return plan;
    }

    // Get the expiration time of the users subscription
    function getSubscriptionExpiration(address _address) public view returns (uint256) {
        Subscription memory subscription = subscriptions[_address];
        require(subscription.tier > 0, "Address has no plan.");

        return subscription.expiration;
    }

    // Create a new subscription plan
    function addSubscriptionPlan(
        uint256 _tier, 
        uint256 _price, 
        uint256 _renewalFee, 
        uint256 _duration
    ) public onlyOwner {
        require(subscriptionPlans[_tier].duration < 1, "Plan does already exist.");
        subscriptionPlans[_tier] = SubscriptionPlan(
            _price,
            _renewalFee,
            _duration
        );
    }

    // Edit an existing subscription plan
    function editSubscriptionPlan(
        uint256 _tier, 
        uint256 _price, 
        uint256 _renewalFee, 
        uint256 _duration
    ) public onlyOwner {
        SubscriptionPlan storage plan = subscriptionPlans[_tier];
        require(plan.duration > 0, "Plan does not exist.");

        if (_price != plan.price) plan.price = _price;
        if (_renewalFee != plan.renewalFee) plan.renewalFee = _renewalFee;
        if (_duration != plan.duration) plan.duration = _duration;
    }

    // Check to see if the subscription from an address has expired
    function hasSubscriptionExpired(address _address) public view returns (bool) {
        Subscription memory subscription = subscriptions[_address];

        return subscription.expiration > block.number;
    }

    // Buying a subscription plan for the first time
    // _tier = 1 - buy plan #1
    // _tier = 2 - buy plan #2
    // _tier = 3 - buy plan #3
    function buySubscription(uint256 _tier) public payable nonReentrant {
        require(subscriptions[msg.sender].tier < 1, "User already subscribed. Please renew or upgrade your subscription.");
        SubscriptionPlan memory plan = subscriptionPlans[_tier];
        require(msg.value == plan.price, "Incorrect value sent. Please send the correct value for the chosen subscription.");
        require(plan.duration > 0, "Invalid plan chosen.");

        uint256 expirationTimestamp = block.timestamp + plan.duration;
        subscriptions[msg.sender] = Subscription(
            _tier,
            expirationTimestamp
        );
    }

    // Renew your current subscription
    // Set the amount of months you would like to renew your subscription
    function renewSubscription(uint256 _months) public payable nonReentrant {
        require(subscriptions[msg.sender].tier > 0, "You don't have a valid subscription. Please buy one before renewing.");
        require(_months > 0, "Must renew atleast 1 month.");
        Subscription memory mySubscription = subscriptions[msg.sender];
        uint256 myTier = mySubscription.tier;
        SubscriptionPlan memory plan = subscriptionPlans[myTier];
        require(msg.value == _months * plan.renewalFee, "Incorrect value sent for chosen plan.");

        uint256 startTimestamp = block.number;
        uint256 expirationTimestamp;
        // Check if subscription has already expired
        if (mySubscription.expiration < startTimestamp) {
            // If subscription expired, take current blocknumber and add time to this
            expirationTimestamp = startTimestamp + (_months * plan.duration);
        } else {
            // If subscription valid; take subscription blocknumber and add time to this
            expirationTimestamp = (mySubscription.expiration) + (_months * plan.duration);
        }
        subscriptions[msg.sender] = Subscription(
            myTier,
            expirationTimestamp
        );
    }

    // Gift a subscription to an address
    // Make sure to know which subscription the receiver has so you can send the correct amount of ether
    function giftSubscription(address _to, uint256 _months) public payable nonReentrant {
        Subscription memory subscription = subscriptions[_to];
        require(subscription.tier > 0, "Address does not have a valid subscription.");
        require(_months > 0, "Must give atleast 1 month.");
        uint256 _tier = subscription.tier;
        SubscriptionPlan memory plan = subscriptionPlans[_tier];
        require(msg.value == _months * plan.renewalFee, "Incorrect value sent. Please check if you are sending the correct fee for the receivers plan.");

        uint256 startTimestamp = block.number;
        uint256 expirationTimestamp;
        // Check if subscription has already expired
        if (subscription.expiration < startTimestamp) {
            // If subscription expired, take current blocknumber and add time to this
            expirationTimestamp = startTimestamp + (_months * plan.duration);
        } else {
            // If subscription valid; take subscription blocknumber and add time to this
            expirationTimestamp = (subscription.expiration) + (_months * plan.duration);
        }
        subscriptions[_to] = Subscription(
            _tier,
            expirationTimestamp
        );
    }

    // Gifting a subscription
    function adminGiftSubscription(address _to, uint256 _tier) public onlyOwner {
        require(subscriptions[_to].tier == 0, "Address already has a subscription.");
        SubscriptionPlan memory plan = subscriptionPlans[_tier];
        require(plan.duration > 0, "Invalid plan chosen.");

        uint256 expirationTimestamp = block.number + plan.duration;
        subscriptions[_to] = Subscription(
            _tier,
            expirationTimestamp
        );
    }

    // Gift X months of access to a user
    function adminGiftRenewal(address _to, uint256 _months) public onlyOwner {
        require(_months > 0, "Must give atleast 1 month.");
        Subscription memory userSubscription = subscriptions[_to];
        uint256 _tier = userSubscription.tier;
        require(_tier > 0, "Address has no subscription.");
        SubscriptionPlan memory plan = subscriptionPlans[_tier];

        uint256 startTimestamp = block.number;
        uint256 expirationTimestamp;
        if (userSubscription.expiration < expirationTimestamp) {
            expirationTimestamp = startTimestamp + (_months * plan.duration);
        } else {
            expirationTimestamp = (userSubscription.expiration) + (_months * plan.duration);
        }

        subscriptions[_to] = Subscription(
            _tier,
            expirationTimestamp
        );
    }

    // Withdraw funds from the contract
    function withdrawFunds() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw failed. Please try again.");
    }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PaymentProvider is Ownable, ReentrancyGuard {
    // Different payment plans
    struct Plan {
        string name;
        uint256 price;
        uint256 duration;
    }

    bool public saleLive = true; // State to change the sale status
    uint256 public base_fee = 0.25 ether; // Charged extra on your first purchase
    uint256 public INACTIVITY_TIME = 90 days; // 90 days inactive means you have to pay the base_fee if you want to use the app again

    mapping(address => uint256) public expirationTime; // Timestamp when the subscription will end
    mapping(uint256 => Plan) public paymentPlans; // Different payment plans

    constructor() {
        paymentPlans[1] = Plan(
            "Trial",
            0 ether, // 0.05 ether,
            1 days
        );
        paymentPlans[2] = Plan(
            "Month",
            0 ether, // 0.1 ether,
            30 days
        );
        paymentPlans[3] = Plan(
            "Quarter",
            0 ether, // 0.25 ether,
            90 days
        );
        paymentPlans[4] = Plan(
            "LifeTime",
            0 ether, // 1.25 ether,
            9999999999 days
        );
    }

    // You can buy your own plan or gift a plan to someone else
    // _plan = 1 - buy a Trial (7 days)
    // _plan = 2 - buy a Month (30 days)
    // _plan = 3 - buy a Quarter (90 days)
    // _plan = 4 - buy LifeTime (unlimited days)
    function buyPlan(address _address, uint256 _plan) public payable nonReentrant {
        uint256 addressExpirationTimestamp = expirationTime[_address];
        // Check if the user already have a subscription, if not, we need to check if the sale is active
        if (addressExpirationTimestamp == 0) {
            require(saleLive, "Sale is not live for new users.");
        }

        Plan memory plan = paymentPlans[_plan];
        require(plan.duration > 0, "Plan does not exist.");
        
        uint256 startTimestamp = block.timestamp;

        uint256 planPrice = plan.price;
        // Check if the user has an expiration date OR the users expiration is longer than 3 months ago
        if (addressExpirationTimestamp == 0 || startTimestamp < (startTimestamp - INACTIVITY_TIME)) {
            planPrice = (base_fee + plan.price);
        }
        require(msg.value == planPrice, "Incorrect value sent. Please send the correct value for the chosen Plan.");

        uint256 expirationTimestamp;
        // Checks for existing and new addresses
        if (addressExpirationTimestamp < startTimestamp) {
            // If subscription expired, take current blocknumber and add time to this
            expirationTimestamp = startTimestamp + plan.duration;
        } else {
            // If subscription valid; take subscription blocknumber and add time to this
            expirationTimestamp = (addressExpirationTimestamp) + (plan.duration);
        }

        expirationTime[_address] = expirationTimestamp;
    }

    // Gift X amount of days to the given address
    // Add onlyOwner
    function adminGiftPlan(address[] calldata _addresses, uint256 _days) public {
        require(_days > 0, "Must gift atleast 1 day.");
        uint256 _daysInSeconds = convertDayToSeconds(_days);

        uint256 startTimestamp = block.timestamp;
        uint256 expirationTimestamp;

        for (uint256 i = 0; i < _addresses.length; i++) {
            address _address = _addresses[i];
            uint256 addressExpirationTimestamp = expirationTime[_address];

            if (addressExpirationTimestamp < startTimestamp) {
                expirationTimestamp = startTimestamp + _daysInSeconds;
            } else {
                expirationTimestamp = addressExpirationTimestamp + _daysInSeconds;
            }
            expirationTime[_address] = expirationTimestamp;
        }
    }

    // Add onlyOwner
    function addNewPlan(
        uint256 _plan, 
        string memory _name,
        uint256 _price, 
        uint256 _durationInDays
    ) public {
        require(paymentPlans[_plan].duration < 1, "Payment Plan already exists.");
        uint256 _durationInSeconds = convertDayToSeconds(_durationInDays);
        paymentPlans[_plan] = Plan(
            _name,
            _price,
            _durationInSeconds
        );
    }

    // Edit an existing plan
    // duration should be in seconds, eg: 1 day = 86400
    // Add onlyOwner
    function editExistingPlan(
        uint256 _plan, 
        string memory _name,
        uint256 _price, 
        uint256 _durationInDays
    ) public {
        Plan storage plan = paymentPlans[_plan];
        require(plan.duration > 0, "Plan does not exist.");
        uint256 _durationInSeconds = convertDayToSeconds(_durationInDays);

        if (keccak256(bytes(_name)) != keccak256(bytes(plan.name))) plan.name = _name;
        if (_price != plan.price) plan.price = _price;
        if (_durationInSeconds != plan.duration) plan.duration = _durationInSeconds;
    }

    // Remove existing subscription from a user
    // Add onlyOwner
    function removeSubscriptions(address[] calldata _addresses) external {
        for (uint256 i = 0; i < _addresses.length; i++) {
            address _address = _addresses[i];
            uint256 addressExpirationTimestamp = expirationTime[_address];
            if (addressExpirationTimestamp == 0) continue;
            expirationTime[_address] = 0;
        }
    }

    // Set a new base fee
    // Add onlyOwner
    function setBaseFee(uint256 _newBaseFee) public {
        require(base_fee != _newBaseFee, "New base fee is already the same.");
        base_fee = _newBaseFee;
    }

    // Switch sale state
    // Add onlyOwner
    function setSaleState() external {
        saleLive = !saleLive;
    }

    // Get the remaining time from the given address
    function getRemainingTime(address _address) external view returns (uint256) {
        uint256 expirationTimeStamp = expirationTime[_address];
        uint256 currentTimestamp = block.timestamp;

        if (currentTimestamp >= expirationTimeStamp) {
            return 0;
        } else {
            return expirationTimeStamp - currentTimestamp;
        }
    }

    // Return if the given address has an active subscription
    function hasValidSubscription(address _address) public view returns (bool) {
        uint256 expirationTimestamp = expirationTime[_address];

        return expirationTimestamp > block.timestamp;
    }

    // To add days to a subscription, we need to convert days to seconds
    function convertDayToSeconds(uint256 _days) internal pure returns (uint256) {
        require(_days % 1 == 0, "Days should have not decimals.");
        require(_days > 0, "Need to be atleast 1 day.");

        return _days * 86400;
    }

    // Withdraw funds from the contract
    // Add onlyOwner
    function withdrawFunds() external {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw failed. Please try again.");
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
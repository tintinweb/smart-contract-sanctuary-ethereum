// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "openzeppelin-contracts/access/Ownable.sol";
import "./lib/AddressSetLib.sol";

contract StackSuite is Ownable {

    /* -------------------------------------------------------------------------- */
    /*                                   errors                                   */
    /* -------------------------------------------------------------------------- */
    error ErrSubscriptionSaleNotOn();
    error ErrSupplyCapExceeded();
    error ErrIncorrectValue();
    error ErrNotSubscribed();
    error ErrTooLateForRenewal();

    error ErrOneTimePurchaseSaleNotOn();
    error ErrOneTimePurchaseSupplyExceeded();

    error ErrSubscriberNotStale();

    /* -------------------------------------------------------------------------- */
    /*                                   events                                   */
    /* -------------------------------------------------------------------------- */
    // user
    event EvSubscribed(address indexed subscriber, uint256 price, uint256 duration);
    event EvRenewed(address indexed subscriber, uint256 price, uint256 duration);
    event EvOneTimePurchase(address indexed purchaser, uint256 price, uint256 duration);

    // owners
    event EvStartSubscriptionSale(uint256 price, uint256 duration, uint256 supplyCap);
    event EvUpdateSubscriptionSale(uint256 price, uint256 duration, uint256 supplyCap);
    event EvStopSubscription();

    event EvStartOneTimePurchaseSale(uint256 price, uint256 duration, uint256 supply);
    event EvUpdateOneTimePurchaseSale(uint256 price, uint256 duration, uint256 supply);
    event EvStopOneTimePurchase();

    /* -------------------------------------------------------------------------- */
    /*                                  constants                                 */
    /* -------------------------------------------------------------------------- */
    uint256 SUBSCRIPTION_NON_RENEWABLE_PERIOD = 4 days;

    /* -------------------------------------------------------------------------- */
    /*                                    libs                                    */
    /* -------------------------------------------------------------------------- */
    using AddressSetLib for AddressSetLib.Set;

    /* -------------------------------------------------------------------------- */
    /*                                    state                                   */
    /* -------------------------------------------------------------------------- */
    /* --------------------------- subscription params -------------------------- */
    uint256 public subscriptionSupplyCap = 333;
    uint256 public subscriptionPrice = 0.1 ether;
    uint256 public subscriptionDuration = 30 days;
    bool public subscriptionSaleOn = true;

    /* --------------------------- subscription states -------------------------- */
    uint256 public subscriptionTotalSupply;
    mapping(address => uint256) internal _subscriptionMap;
    AddressSetLib.Set internal _subscribers;

    /* ------------------------ one time purchases params ----------------------- */
    uint256 public oneTimePurchaseSupplyCap;
    uint256 public oneTimePurchasePrice;
    uint256 public oneTimePurchaseDuration;
    bool public oneTimePurchaseSaleOn;

    /* ------------------------ one time purchases states ----------------------- */
    uint256 public oneTimePurchaseTotalSupply;
    mapping(address => uint256) internal _oneTimePurchaseMap;
    AddressSetLib.Set internal _purchasers;

    /* -------------------------------------------------------------------------- */
    /*                                  external                                  */
    /* -------------------------------------------------------------------------- */
    function subscribe() external payable {

        uint256 _duration = subscriptionDuration;
        uint256 _price = subscriptionPrice;
        uint256 _subscriptionTotalSupply = subscriptionTotalSupply;

        // check sale is on
        if (!subscriptionSaleOn) { revert ErrSubscriptionSaleNotOn(); }

        // check supply not exceeded
        if (_subscriptionTotalSupply >= subscriptionSupplyCap) { revert ErrSupplyCapExceeded(); }

        // check payment
        if (msg.value != _price) { revert ErrIncorrectValue(); }

        // subscribe
        _subscriptionMap[msg.sender] = block.timestamp + _duration;
        _subscribers.insert(msg.sender); // checks not already subscribed
        subscriptionTotalSupply = _subscriptionTotalSupply + 1;

        // event
        emit EvSubscribed(msg.sender, _price, _duration);
    }

    function renew() external payable {

        uint256 _duration = subscriptionDuration;
        uint256 _price = subscriptionPrice;

        // check sale is on
        if (!subscriptionSaleOn) { revert ErrSubscriptionSaleNotOn(); }

        // check price
        if (msg.value != _price) { revert ErrIncorrectValue(); }

        // check has subscription
        uint256 subsciptionEndTimestamp = _subscriptionMap[msg.sender];
        if (subsciptionEndTimestamp == 0) { revert ErrNotSubscribed(); }

        // check within grace period
        if (block.timestamp > subsciptionEndTimestamp - SUBSCRIPTION_NON_RENEWABLE_PERIOD) {
            revert ErrTooLateForRenewal();
        }

        // renew
        _subscriptionMap[msg.sender] = subsciptionEndTimestamp + _duration;

        // event
        emit EvRenewed(msg.sender, _price, _duration);
    }

    function buy() external payable {

        uint256 _price = oneTimePurchasePrice;
        uint256 _oneTimePurchaseTotalSupply = oneTimePurchaseTotalSupply;
        uint256 _duration = oneTimePurchaseDuration;

        // check sale is one
        if (!oneTimePurchaseSaleOn) { revert ErrOneTimePurchaseSaleNotOn(); }

        // check price
        if (msg.value != _price) { revert ErrIncorrectValue(); }

        // check supply
        if (_oneTimePurchaseTotalSupply >= oneTimePurchaseSupplyCap) {
            revert ErrOneTimePurchaseSupplyExceeded();
        }

        // buy
        _oneTimePurchaseMap[msg.sender] = block.timestamp + _duration;
        _purchasers.insert(msg.sender);
        oneTimePurchaseTotalSupply = _oneTimePurchaseTotalSupply + 1;

        // event
        emit EvOneTimePurchase(msg.sender, _price, _duration);
    }

    /* -------------------------------------------------------------------------- */
    /*                                    views                                   */
    /* -------------------------------------------------------------------------- */
    struct Subscriber { address addr; uint256 endTime; }
    function getSubscribers() public view returns (Subscriber[] memory subscribers) {
        address[] memory subscriberAddresses = _subscribers.all();

        uint256 totalSubscribers = subscriberAddresses.length;
        subscribers = new Subscriber[](totalSubscribers);
        for (uint i = 0; i < totalSubscribers; i++) {
            address addr = subscriberAddresses[i];
            uint256 endTime = subscriptionEndTime(addr);
            subscribers[i] = Subscriber({ addr: addr, endTime: endTime });
        }

        return subscribers;
    }

    function subscriptionEndTime(address subscriber) public view returns (uint256) {
        return _subscriptionMap[subscriber];
    }

    function getPurchasers() public view returns (address[] memory) {
        return _purchasers.all();
    }

    function oneTimePurchaseEndTime(address purchaser) public view returns (uint256) {
        return _oneTimePurchaseMap[purchaser];
    }

    function isSubscribed(address addr) public view returns (bool) {
        return _subscribers.exists(addr);
    }

    function isSubscriptionValid(address addr) public view returns (bool) {
        return isSubscribed(addr) && block.timestamp < _subscriptionMap[addr];
    }

    /* -------------------------------------------------------------------------- */
    /*                                 owners only                                */
    /* -------------------------------------------------------------------------- */
    /* ------------------------------ subscription ------------------------------ */
    function startSubscriptionSale(uint256 price_, uint256 duration_, uint256 supplyCap_) external onlyOwner {
        subscriptionPrice = price_;
        subscriptionDuration = duration_;
        subscriptionSupplyCap = supplyCap_;
        subscriptionSaleOn = true;

        emit EvStartSubscriptionSale(price_, duration_, supplyCap_);
    }

    function stopSubscriptionSale() external onlyOwner {
        subscriptionSaleOn = false;

        emit EvStopSubscription();
    }

    function updateSubscriptionSale(uint256 price_, uint256 duration_, uint256 supplyCap_) external onlyOwner {
        subscriptionPrice = price_;
        subscriptionDuration = duration_;
        subscriptionSupplyCap = supplyCap_;

        emit EvUpdateSubscriptionSale(price_, duration_, supplyCap_);
    }

    /* --------------------------- one time purchases --------------------------- */
    function startOneTimePurchaseSale(uint256 price_, uint256 duration_, uint256 supply_) external onlyOwner {
        oneTimePurchaseSupplyCap = supply_;
        oneTimePurchasePrice = price_;
        oneTimePurchaseDuration = duration_;
        oneTimePurchaseSaleOn = true;

        emit EvStartOneTimePurchaseSale(price_, duration_, supply_);
    }

    function stopOneTimePurchaseSale() external onlyOwner {
        oneTimePurchaseSaleOn = false;

        emit EvStopOneTimePurchase();
    }

    function updateOneTimePurchase(uint256 price_, uint256 duration_, uint256 supply_) external onlyOwner {
        oneTimePurchaseSupplyCap = supply_;
        oneTimePurchasePrice = price_;
        oneTimePurchaseDuration = duration_;

        emit EvUpdateOneTimePurchaseSale(price_, duration_, supply_);
    }

    /* ---------------------------------- chore --------------------------------- */
    function clearStaleSubscribers(address[] calldata staleSubscribers) external onlyOwner {

        uint256 cutoffTimestamp = block.timestamp - SUBSCRIPTION_NON_RENEWABLE_PERIOD;

        for (uint i=0; i<staleSubscribers.length; i++) {
            address staleSubscriber = staleSubscribers[i];

            // check is stale /// gas cost
            if (_subscriptionMap[staleSubscriber] > cutoffTimestamp) {
                revert ErrSubscriberNotStale();
            }

            // clear
            _subscribers.remove(staleSubscriber);
            delete _subscriptionMap[staleSubscriber];
        }

        // update totalSupply
        subscriptionTotalSupply -= staleSubscribers.length;
    }

    /* -------------------------------- withdraw -------------------------------- */
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
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
pragma solidity ^0.8.16;

library AddressSetLib {

    error ErrAddressSetKeyAlreadyExists();
    error ErrAddressSetKeyDoesNotExist();

    struct Set {
        mapping(address => uint256) map;
        address[] list;
    }

    function insert(Set storage self, address k) internal {
        if (exists(self, k)) { revert ErrAddressSetKeyAlreadyExists(); }
        self.list.push(k);
        self.map[k] =  self.list.length - 1;
    }

    function remove(Set storage self, address k) internal {
        if (!exists(self, k)) { revert ErrAddressSetKeyDoesNotExist(); }
        uint256 lastIndex = self.list.length - 1;
        uint256 indexToReplace = self.map[k];
        if (indexToReplace != lastIndex) {
            address lastElem = self.list[lastIndex];
            self.map[lastElem] = indexToReplace;
            self.list[indexToReplace] = lastElem;
        }
        delete self.map[k];
        self.list.pop();
    }

    function length(Set storage self) internal view returns(uint256) {
        return self.list.length;
    }

    function exists(Set storage self, address k) internal view returns(bool) {
        if (self.list.length == 0) { return false; }
        return self.list[self.map[k]] == k;
    }

    function all(Set storage self) internal view returns (address[] memory) {
        return self.list;
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
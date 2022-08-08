//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./IPatreon.sol";
import "./PatreonRegistry.sol";

contract Patreon is IPatreon, Ownable {
    uint public immutable override subscriptionFee;
    uint public immutable override subscriptionPeriod;
    uint public override ownerBalance;
    uint public override subscriberCount;
    string public override description;
    address private immutable registryAddress;
    mapping(address => Subscriber) internal _subscribers;

    modifier onlySubscriber() {
        if(!_subscribers[msg.sender].isSubscribed)
            revert Unauthorized(msg.sender);
        _;
    }
    
    modifier onlyNonSubscriber() {
        if (_subscribers[msg.sender].isSubscribed)
            revert Unauthorized(msg.sender);
        _;
    }

    modifier onlyNonOwner() {
        if (msg.sender == owner())
            revert Unauthorized(msg.sender);
        _;
    }

    constructor(
        address _registryAddress,
        uint _subscriptionFee,
        uint _subscriptionPeriod,
        string memory _description
    ) Ownable() {
        registryAddress = _registryAddress;
        subscriptionFee = _subscriptionFee;
        subscriptionPeriod = _subscriptionPeriod;
        description = _description;
    }

    function subscribe()
        external
        payable
        override
        onlyNonSubscriber
        onlyNonOwner
    {
        if (msg.value < subscriptionFee)
            revert InsufficientFunds(subscriptionFee, msg.value);

        Subscriber storage subscriber = _subscribers[msg.sender];
        ownerBalance += subscriptionFee;
        subscriber.balance += (msg.value - subscriptionFee);
        subscriber.isSubscribed = true;
        subscriber.subscribedAt = block.timestamp;
        subscriber.lastChargedAt = block.timestamp;
        subscriberCount += 1;
        emit Subscribed(msg.sender, msg.value, block.timestamp);

        PatreonRegistry(registryAddress).registerPatreonSubscription(msg.sender);
    }

    function unsubscribe()
        external
        override
        onlySubscriber
    {
        Subscriber storage subscriber = _subscribers[msg.sender];
        uint remainingSubscriptionBalance = subscriber.balance;
        subscriber.balance = 0;
        subscriber.isSubscribed = false;
        subscriberCount -= 1;
        emit Unsubscribed(msg.sender, remainingSubscriptionBalance, block.timestamp);
    } 

    function chargeSubscription(address[] calldata subscribers)
        external
        virtual
        override
        onlyOwner
    {
        for (uint i = 0; i < subscribers.length; i = i + 1) {
            Subscriber storage subscriber = _subscribers[subscribers[i]];
            // We can charge a subscriber iff `isSubscribed` == true && `lastChargedAt` + `subscriptionPeriod` >= `block.timestamp`.abi
            // Simply ignore addresses that don't match this criteria
            if (!subscriber.isSubscribed || subscriber.lastChargedAt + subscriptionPeriod > block.timestamp)
                continue;

            uint subscriptionBalanceBeforeCharge = subscriber.balance;
            if (subscriber.balance < subscriptionFee) {
                // Subscriber has insufficient funds so we transfer their balance to the owner and cancel
                // the subscription
                ownerBalance += subscriptionBalanceBeforeCharge;
                subscriber.balance = 0;
                subscriber.isSubscribed = false;
                subscriber.lastChargedAt = block.timestamp;
                subscriberCount -= 1;
                emit SubscriptionCanceled(subscribers[i], subscriptionBalanceBeforeCharge, block.timestamp);
            } else {
                // Subscriber has sufficient funds so we allocate the fee amount to the owner balance and
                // decrement it from the subscription balance.
                ownerBalance += subscriptionFee;
                subscriber.balance -= subscriptionFee;
                subscriber.lastChargedAt = block.timestamp;
            }

            emit Charged(subscribers[i], subscriptionBalanceBeforeCharge, block.timestamp);
        }
    }

    function depositFunds()
        external
        payable
        override
        onlySubscriber
    {
        _subscribers[msg.sender].balance += msg.value;
    }

    function withdraw(uint amount) external override {
        if (msg.sender == owner()) {
            withdrawOwnerBalance(amount);
        } else if (_subscribers[msg.sender].isSubscribed) {
            withdrawSubscriberBalance(amount);
        } else {
            revert Unauthorized(msg.sender);
        }
    }

    function getSubscriber(address subscriber)
        external
        view
        override
        returns (Subscriber memory)
    {
        return _subscribers[subscriber];
    }

    function withdrawOwnerBalance(uint amount) private onlyOwner {
        if (amount > ownerBalance)
            revert InsufficientFunds(amount, ownerBalance);

        ownerBalance -= amount;
        payable(owner()).transfer(amount);
    }

    function withdrawSubscriberBalance(uint amount) private onlySubscriber {
        if (amount > _subscribers[msg.sender].balance)
            revert InsufficientFunds(amount, _subscribers[msg.sender].balance);

        _subscribers[msg.sender].balance -= amount;
        payable(msg.sender).transfer(amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IPatreonRegistry.sol";
import "./Patreon.sol";

contract PatreonRegistry is IPatreonRegistry {
    mapping(address => bool) public override isPatreonContract;
    uint public override numPatreons;

    // Track the Patreon contracts owned by an EOA
    mapping(address => address[]) internal ownerToPatreons;
    // Track the Patreon contracts to which an EOA is currently subscribed
    // or has subscribed to in the past
    mapping(address => address[]) private subscriberToPatreons;
    mapping(address => mapping (address => bool)) private subscriberAlreadySubscribed;

    modifier onlyPatreonContract {
        require(
            isPatreonContract[msg.sender],
            "Only registered Patreon contracts can call this function"
        );
        _;
    }

    /// Create a new Patreon contract and assign it to the caller.
    /// The contract address will appear in the `ownerToPatreons` map.
    function createPatreon(
        uint _subscriptionFee,
        uint _subscriptionPeriod,
        string memory _description
    )
        virtual
        external
        override
        returns (address)
    {
        Patreon patreon = new Patreon(
            address(this),
            _subscriptionFee,
            _subscriptionPeriod,
            _description
        );

        isPatreonContract[address(patreon)] = true;
        address[] storage patreons = ownerToPatreons[msg.sender];
        patreons.push(address(patreon));
        numPatreons += 1; 

        // Transfer ownership from the registry to the minter
        patreon.transferOwnership(msg.sender);

        emit CreatePatreon(
            msg.sender,
            patreons[patreons.length - 1],
            block.timestamp,
            _description
        );

        return address(patreon);
    }

    /// Called by a Patreon contract when it receives a new subscriber.
    /// The Patreon contract address is added to the subscriber's list
    /// of subcsriptions in the `subcsriberToPatreons` map.
    function registerPatreonSubscription(address subscriber)
        external
        override
        onlyPatreonContract
    {
        if (!subscriberAlreadySubscribed[subscriber][msg.sender]) {
            subscriberToPatreons[subscriber].push(msg.sender);
            subscriberAlreadySubscribed[subscriber][msg.sender] = true;
        }
    }

    /// Fetch the list of Patreon contracts owned by the address.
    function getPatreonsForOwner(address owner)
        external
        view
        override
        returns (address[] memory)
    {
        return ownerToPatreons[owner];
    }

    /// Fetch the list of Patreon contracts to which the address is
    /// subscribed OR has subscribed to in the past. 
    function getPatreonsForSubscriber(address subscriber)
        external
        view
        override
        returns (address[] memory)
    {
        return subscriberToPatreons[subscriber];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title A Patreon contract with an owner and subscribers. Anyone can subscribe and the
/// owner can periodically withdraw fees. It's up to the owner what kind of perks/benefits
/// they wish to give the active subcsribers
/// @author Dalton G. Sweeney
/// @custom:experimental This is a toy interface. Use at your own risk!
interface IPatreon {

    /// @notice Subscriber info for an address
    ///
    /// @param subscribedAt Time at which the the address subscribed. Only relevant if `isSubscribed` is `true`
    /// @param balance The balance of this address from which the address can withdraw funds and the owner can charge the fee
    /// @param isSubscribed When `true` the address is an active subscriber
    /// @param lastChargedAt Timestamp (in seconds) when the fee was last charged (either successfully or attempted)
    struct Subscriber {
        uint subscribedAt;
        uint balance;
        bool isSubscribed;
        uint lastChargedAt;
    }

    /// @notice Emitted when an address subscribes
    /// @param _address Address that was subscribed
    /// @param amountSubscribedWith Amount subscribed with in wei (i.e. msg.amount when `subscribe` was called)
    /// @param subscribedAt Epoch time in seconds at which the event was emitted
    event Subscribed(
        address indexed _address,
        uint amountSubscribedWith,
        uint indexed subscribedAt
    );

    /// @notice Emitted when an address unsubscribes
    /// @param _address Address that was subscribed
    /// @param amountUnsubscribedWith Amount unsubscribed with in wei, i.e. the balance on the Subscriber object
    /// @param unsubscribedAt Epoch time in seconds at whith the event was emitted
    event Unsubscribed(
        address indexed _address,
        uint amountUnsubscribedWith,
        uint indexed unsubscribedAt
    );

    /// @notice Emitted when a subscription is canceled because the owner charged the subscriber
    /// but the subscriber had insufficient funds to pay the subscription fee
    ///
    /// @param _address Address that had its subscription canceled
    /// @param amountCanceledWith Amount in wei of the address's balance at the time of cancellation
    /// @param canceledAt Epoch time in seconds at which the event was emitted
    event SubscriptionCanceled(
        address indexed _address,
        uint amountCanceledWith,
        uint indexed canceledAt
    );

    /// @notice Emitted when a subscriber is charged the subscription fee (either successfully or attempted)
    /// @param subscriber address of that was charged
    /// @param amount Amount charged in wei
    /// @param chargedAt Epoch time in seconds at which the event was emitted
    event Charged(
        address indexed subscriber,
        uint amount,
        uint indexed chargedAt
    );

    /// @notice Revert with this error when a balance requested exceeds the maximum allowable balance
    /// @param requested wei amount requested
    /// @param limit the maximum amount (i.e. limit < requested)
    error InsufficientFunds(uint256 requested, uint256 limit);

    /// @notice Revert with this error when unauthorized access to a function is attempted
    /// @param _address who made the failed access attempt
    error Unauthorized(address _address);

    /// @notice Human readable description, e.g. purpose, perks unlocked, etc.
    function description() external view returns (string memory);

    /// @notice Fee the owner of the Patreon may charge once per period
    /// @return Fee (wei)
    function subscriptionFee() external view returns (uint);

    /// @notice Minimum waiting period for the owner to charge a subscriber
    /// @return Waiting period (seconds). E.g. 604800 => subscription can be charged weekly
    function subscriptionPeriod() external view returns (uint);

    /// @notice Owner's balance. This is the sum of all fees paid to them by the subscribers
    /// @dev Fees are awarded to the owner when an owner subscribes and when the subscriber is charged
    /// @return Balance (wei)
    function ownerBalance() external view returns (uint);

    /// @notice Get the Subscriber object for an address
    function getSubscriber(address) external view returns (Subscriber calldata);

    /// @notice Active subscriber count
    function subscriberCount() external view returns (uint);

    /// @notice Subscribe the message sender to this Patreon.
    /// The value of the message must be at least the subscription fee because this function
    /// will transfer an amount equal to the subscription fee directly to the owner. Any
    /// remaining funds from msg.value is allocated to the sender's balance in their Subscriber
    /// object.
    ///
    /// @dev The subscription must be recorded in the registery via `registerPatreonSubscription(address subscriber)`
    /// @dev Subscription must increment the subscriber count
    /// @dev Subscription must emit a `Subscribed` event
    /// @dev Subscription must set the sender's `subscribedAt` property to `true`
    /// @dev Subscription should revert unless called by a non-owner non-subscriber
    function subscribe() external payable;

    /// @notice Unsubscribe the message sender from this Patreon. This will set the subscriber's balance
    /// to 0, so it is HIGHLY recommended the subscriber withdraws their total balance before unsubscribing
    ///
    /// @dev Unsubscription must decrement the subscriber count
    /// @dev Unsubscription must emit an `Unsubscribed` event
    /// @dev Unsubscription should revert unless called by a subscriber
    function unsubscribe() external;

    /// @notice Charge the subscription fee to the subscriber list. This can be done at most once every
    /// `subscriptionPeriod` seconds for each subscriber. Only the owner of the patreon can call this
    /// function and it's their responsibility to supply the correct subcsriber addresses. If a
    /// subscriber's balance is under the subscription fee then the remaining balance is transferred to
    /// the owner's balance and the subscriber is automatically unsubscribed.
    ///
    /// @dev A subscriber list is provided instead of internally iterating through all the subscribers
    /// to avoid hitting the gas limit. The number of subscribers could be unbounded so if we simply
    /// iterated through that list to charge the subscriptions then the gas cost of this function would
    /// also be unbounded. This interface allows the owner to break up the subscription charges into chunks
    /// @dev A `Charged` event should be emitted when any amount is tranferred from a subscriber to the owner
    /// @dev A `SubscriptionCanceled` event should be emitted if the subscriber is unsubscribed due to
    /// insufficient funds
    function chargeSubscription(address[] calldata subscribers) external;

    /// @notice A subscriber calls this function to deposit funds and maintain their balance over the fee
    function depositFunds() external payable;

    /// @notice Allow the owner or a subscriber to withdraw their funds. The address cannot withdraw more than
    /// their balance
    ///
    /// @param amount Withdrawal amount to transfer to the message sender
    function withdraw(uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title A registry to create new IPatreon contracts and keep track of owners/subscribers to those contracts
/// @author Dalton G. Sweeney
/// @custom:experimental This is a toy interface. Use at your own risk!
interface IPatreonRegistry {

    /// @notice Check if an address is a Patreon contract minted from this registry
    function isPatreonContract(address) external view returns (bool);

    /// @notice Total number of Patreon contracts minted from this registry
    function numPatreons() external view returns (uint);

    /// @notice Mint a new Patreon contract that will be tracked by this Registry
    /// @param _subscriptionFee Fee charged the owner of the Patreon can charge their subscribers for per period
    /// @param _subscriptionPeriod Charging period for the Patreon
    /// @param _description Human readable description of the Patreon. E.g. purpose, perks unlocked, etc.
    /// @dev MUST emit a CreatePatreon event upon successfully creation such that `owner` is the message sender,
    /// `patreon` is the address of the minted contract, `createdAt` is the block timestamp, and `description`
    /// is the `_description` param
    /// @dev MUST transfer ownership of the minted contract to the message sender
    /// @return the addresses of the minted Patreon contract
    function createPatreon(
        uint _subscriptionFee,
        uint _subscriptionPeriod,
        string memory _description
    ) external returns (address);

    /// @notice called by a Patreon contract when registering a new subscriber
    /// @dev SHOULD revert if the caller is not a Patreon contract under this registry
    function registerPatreonSubscription(address subscriber) external;

    /// @notice Get the addresses of the patreon contracts owned by `owner`
    /// @param owner The address which owns of the returned Patreon contracts
    /// @return List of the addresses
    function getPatreonsForOwner(address owner) external view returns (address[] memory);

    /// @notice Get the addresses of the patreon contracts to which `subscriber` is subscribed to
    /// OR has subscribed to in the past (i.e. Patreons to which `subscriber` was subscribed but
    /// has since been unsubscribed from MUST be included)
    /// @param subscriber The address that is/was subscribed to the returned Patreon contracts
    /// @return List of the addresses
    function getPatreonsForSubscriber(address subscriber) external view returns (address[] memory);

    /// @notice Emitted when a Patreon contract is minted from this registry
    event CreatePatreon(
        address indexed owner,
        address indexed patreon,
        uint indexed createdAt,
        string description
    );

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
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
/**
 * @notice This is a deprecated interface. Please use AutomationCompatibleInterface directly.
 */
pragma solidity ^0.8.0;
import {AutomationCompatibleInterface as KeeperCompatibleInterface} from "./AutomationCompatibleInterface.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/PullPayment.sol)

pragma solidity ^0.8.0;

import "../utils/escrow/Escrow.sol";

/**
 * @dev Simple implementation of a
 * https://consensys.github.io/smart-contract-best-practices/development-recommendations/general/external-calls/#favor-pull-over-push-for-external-calls[pull-payment]
 * strategy, where the paying contract doesn't interact directly with the
 * receiver account, which must withdraw its payments itself.
 *
 * Pull-payments are often considered the best practice when it comes to sending
 * Ether, security-wise. It prevents recipients from blocking execution, and
 * eliminates reentrancy concerns.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * To use, derive from the `PullPayment` contract, and use {_asyncTransfer}
 * instead of Solidity's `transfer` function. Payees can query their due
 * payments with {payments}, and retrieve them with {withdrawPayments}.
 */
abstract contract PullPayment {
    Escrow private immutable _escrow;

    constructor() {
        _escrow = new Escrow();
    }

    /**
     * @dev Withdraw accumulated payments, forwarding all gas to the recipient.
     *
     * Note that _any_ account can call this function, not just the `payee`.
     * This means that contracts unaware of the `PullPayment` protocol can still
     * receive funds this way, by having a separate account call
     * {withdrawPayments}.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee Whose payments will be withdrawn.
     *
     * Causes the `escrow` to emit a {Withdrawn} event.
     */
    function withdrawPayments(address payable payee) public virtual {
        _escrow.withdraw(payee);
    }

    /**
     * @dev Returns the payments owed to an address.
     * @param dest The creditor's address.
     */
    function payments(address dest) public view returns (uint256) {
        return _escrow.depositsOf(dest);
    }

    /**
     * @dev Called by the payer to store the sent amount as credit to be pulled.
     * Funds sent in this way are stored in an intermediate {Escrow} contract, so
     * there is no danger of them being spent before withdrawal.
     *
     * @param dest The destination address of the funds.
     * @param amount The amount to transfer.
     *
     * Causes the `escrow` to emit a {Deposited} event.
     */
    function _asyncTransfer(address dest, uint256 amount) internal virtual {
        _escrow.deposit{value: amount}(dest);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/escrow/Escrow.sol)

pragma solidity ^0.8.0;

import "../../access/Ownable.sol";
import "../Address.sol";

/**
 * @title Escrow
 * @dev Base escrow contract, holds funds designated for a payee until they
 * withdraw them.
 *
 * Intended usage: This contract (and derived escrow contracts) should be a
 * standalone contract, that only interacts with the contract that instantiated
 * it. That way, it is guaranteed that all Ether will be handled according to
 * the `Escrow` rules, and there is no need to check for payable functions or
 * transfers in the inheritance tree. The contract that uses the escrow as its
 * payment method should be its owner, and provide public methods redirecting
 * to the escrow's deposit and withdraw.
 */
contract Escrow is Ownable {
    using Address for address payable;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param payee The destination address of the funds.
     *
     * Emits a {Deposited} event.
     */
    function deposit(address payee) public payable virtual onlyOwner {
        uint256 amount = msg.value;
        _deposits[payee] += amount;
        emit Deposited(payee, amount);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     *
     * Emits a {Withdrawn} event.
     */
    function withdraw(address payable payee) public virtual onlyOwner {
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        payee.sendValue(payment);

        emit Withdrawn(payee, payment);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

import "./lottery/ILotteryImmutables.sol";

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface ILottery is ILotteryImmutables, KeeperCompatibleInterface {

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.9;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface ILotteryImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function ticketPrice() external view returns (uint256);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function durationMinutes() external view returns (uint256);
}

// SPDX-FileCopyrightText: © Lotterypto <[email protected]>
// SPDX-License-Identifier: CC-BY-NC-SA-4.0

// Lottery Smart Contract © Lotterypto is licensed under Attribution-NonCommercial-ShareAlike 4.0 International
// To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/4.0/
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/ILottery.sol";
import "./NoDelegateCall.sol";

error InvalidState();
error InvalidVrfCoordinatorResponse();
error InvalidVrfCoordinatorAddress();
error InvalidTicketPrice();
error InvalidWinnerPayoutPercentage();
error PlayerAlreadyEntered();
error InvalidFeePercentage();
error InvalidFeeDestinationAddress();
error InvalidPayoutsPerBlock();
error InvalidCharityDestinationAddress();
error InvalidMaxPlayers();
error InvalidMinPlayers();
error InvalidPayout();
error InvalidCall();

contract Lottery is ILottery, Ownable, Pausable, ReentrancyGuard, VRFConsumerBaseV2, PullPayment, NoDelegateCall {
    enum LotteryState {
        Opened,
        Draw,
        ReadyForPayouts,
        Closed
    }

    VRFCoordinatorV2Interface public vrfCoordinatorV2Interface;
    LotteryState public lotteryState = LotteryState.Closed;

    bytes32 internal vrfKeyHash;
    uint16 internal vrfRequestConfirmations;
    uint32 internal vrfCoordinatorCallbackGasLimit;
    uint64 internal vrfSubscriptionId;
    uint256 public maxPlayers;
    uint256 public minPlayers;
    uint256 public payoutsPerBlock;
    uint256 public payoutsExecuted;
    uint256 public id;
    uint256 public openedAt;
    uint256 internal vrfRequestId;
    uint256 public feePercentage;
    uint256 public charityPercentage;
    uint256 public jackpot;
    uint256 public winnerPayout;
    uint256 public leftOverPayoutPerPlayer;
    uint256 public winnerPayoutPercentage;
    uint256 public vrfRandomNumber;
    address public winner;
    address public feeDestination;
    address public charityDestination;
    address[] public players;
    bool public isInitialized = false;
    mapping(address => bool) public playerHasEntered;
    mapping(address => uint256) public balances;

    /// @inheritdoc ILotteryImmutables
    address public immutable override factory;
    /// @inheritdoc ILotteryImmutables
    uint256 public immutable override ticketPrice;
    /// @inheritdoc ILotteryImmutables
    uint256 public immutable override durationMinutes;

    event VrfSettings(
        address vrfCoordinatorAddress,
        bytes32 vrfKeyHash,
        uint64 vrfSubscriptionId,
        uint32 vrfCoordinatorCallbackGasLimit,
        uint16 vrfRequestConfirmations
    );

    event LotterySettings(
        uint256 ticketPrice,
        uint256 winnerPayoutPercentage,
        uint256 feePercentage,
        address feeDestination,
        uint256 charityPercentage,
        address charityDestination,
        uint256 maxPlayers,
        uint256 minPlayers,
        uint256 payoutsPerBlock,
        uint256 durationMinutes
    );
    event LotteryOpened(
        uint256 id,
        uint256 ticketPrice,
        uint256 winnerPayoutPercentage,
        uint256 feePercentage,
        address feeDestination,
        uint256 charityPercentage,
        address charityDestination,
        uint256 maxPlayers,
        uint256 minPlayers,
        uint256 payoutsPerBlock,
        uint256 durationMinutes
    );
    event PlayerEntered(uint256 id, address player, uint256 ticketPrice);
    event LotteryDrawStarted(uint256 id, uint256 jackpot);
    event LotteryDrawCompleted(uint256 id, uint256 vrfRequestId, uint256 vrfRandomNumber);
    event LotteryWinner(uint256 id, address winner, uint256 winnerPayout);
    event LotteryClosed(uint256 id);
    event LotteryPayoutWithdrawn(address player, uint256 amount);

    constructor(
        address owner_,
        address vrfCoordinatorAddress_,
        uint256 ticketPrice_,
        uint256 durationMinutes_
    ) VRFConsumerBaseV2(vrfCoordinatorAddress_) {
        vrfCoordinatorV2Interface = VRFCoordinatorV2Interface(vrfCoordinatorAddress_);
        factory = msg.sender;
        ticketPrice = ticketPrice_;
        durationMinutes = durationMinutes_;

        // immediately transfer ownership from factory to the owner
        // so that the owner can set the VRF settings
        transferOwnership(owner_);
    }

    function asyncTransfer(address dest, uint256 amount) internal {
        _asyncTransfer(dest, amount);
    }

    function enter() external payable nonReentrant whenNotPaused {
        if (!_isReadyToAcceptPlayer(msg.sender)) revert InvalidState();
        if (msg.value != ticketPrice) revert InvalidTicketPrice();
        _enter(msg.sender);
    }

    receive() external payable virtual nonReentrant whenNotPaused {
        revert InvalidCall();
    }

    fallback() external payable nonReentrant whenNotPaused {
        revert InvalidCall();
    }

    function close() external nonReentrant onlyOwner {
        _close();
    }

    function _close() internal whenNotPaused {
        if (!_isReadyForClose()) revert InvalidState();
        // Divisions leaves few wei behind
        // so we add it to the fee destination
        // to ensure that the contract is empty
        asyncTransfer(feeDestination, jackpot);
        jackpot = 0;
        lotteryState = LotteryState.Closed;

        emit LotteryClosed(id);
    }

    function vrfSettings(
        address vrfCoordinatorAddress_,
        bytes32 vrfKeyHash_,
        uint64 vrfSubscriptionId_,
        uint32 vrfCoordinatorCallbackGasLimit_,
        uint16 vrfRequestConfirmations_
    ) external onlyOwner {
        if (vrfCoordinatorAddress_ == address(0)) revert InvalidVrfCoordinatorAddress();

        vrfCoordinatorV2Interface = VRFCoordinatorV2Interface(vrfCoordinatorAddress_);
        vrfKeyHash = vrfKeyHash_;
        vrfSubscriptionId = vrfSubscriptionId_;
        vrfCoordinatorCallbackGasLimit = vrfCoordinatorCallbackGasLimit_;
        vrfRequestConfirmations = vrfRequestConfirmations_;

        emit VrfSettings(
            vrfCoordinatorAddress_,
            vrfKeyHash,
            vrfSubscriptionId,
            vrfCoordinatorCallbackGasLimit,
            vrfRequestConfirmations
        );
    }

    function initialize(
        uint256 winnerPayoutPercentage_,
        uint256 feePercentage_,
        address feeDestination_,
        uint256 charityPercentage_,
        address charityDestination_,
        uint256 maxPlayers_,
        uint256 minPlayers_,
        uint256 payoutsPerBlock_
    ) external onlyOwner {
        if (!_isReadyForChangeSettings()) revert InvalidState();
        if (feeDestination_ == address(0)) revert InvalidFeeDestinationAddress();
        if (feePercentage_ == 0) revert InvalidFeePercentage();
        if (winnerPayoutPercentage_ == 0) revert InvalidWinnerPayoutPercentage();
        if (charityPercentage_ > 0 && charityDestination_ == address(0)) revert InvalidCharityDestinationAddress();
        if (charityPercentage_ == 0 && charityDestination_ != address(0)) revert InvalidCharityDestinationAddress();
        if (maxPlayers_ == 0) revert InvalidMaxPlayers();
        if (minPlayers_ == 0 || minPlayers_ >= maxPlayers_) revert InvalidMinPlayers();
        if (payoutsPerBlock_ == 0) revert InvalidPayoutsPerBlock();

        feePercentage = feePercentage_;
        feeDestination = payable(feeDestination_);
        charityPercentage = charityPercentage_;
        charityDestination = payable(charityDestination_);
        winnerPayoutPercentage = winnerPayoutPercentage_;
        maxPlayers = maxPlayers_;
        minPlayers = minPlayers_;
        payoutsPerBlock = payoutsPerBlock_;

        isInitialized = true;

        emit LotterySettings(
            ticketPrice,
            winnerPayoutPercentage,
            feePercentage,
            feeDestination,
            charityPercentage,
            charityDestination,
            maxPlayers,
            minPlayers,
            payoutsPerBlock,
            durationMinutes
        );
    }

    function open() external onlyOwner {
        _open();
    }

    function _open() internal {
        if (!_isReadyForOpen()) revert InvalidState();

        id++;
        openedAt = block.timestamp;
        lotteryState = LotteryState.Opened;
        players = new address[](0);
        balances[feeDestination] = 0;
        balances[charityDestination] = 0;
        payoutsExecuted = 0;

        emit LotteryOpened(
            id,
            ticketPrice,
            winnerPayoutPercentage,
            feePercentage,
            feeDestination,
            charityPercentage,
            charityDestination,
            maxPlayers,
            minPlayers,
            payoutsPerBlock,
            durationMinutes
        );
    }

    function _enter(address player_) internal {
        players.push(payable(player_));
        playerHasEntered[player_] = true;

        uint256 fee = (ticketPrice * feePercentage) / 100;
        uint256 charity = ((ticketPrice * charityPercentage) / 100);

        asyncTransfer(feeDestination, fee);
        asyncTransfer(charityDestination, charity);

        jackpot += (ticketPrice - fee - charity);
        emit PlayerEntered(id, player_, ticketPrice);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override nonReentrant {
        if (vrfRequestId != requestId) revert InvalidVrfCoordinatorResponse();
        if (lotteryState != LotteryState.Draw) revert InvalidState();
        if (randomWords.length < 1) revert InvalidVrfCoordinatorResponse();

        vrfRandomNumber = randomWords[0];
        winner = players[vrfRandomNumber % players.length];
        lotteryState = LotteryState.ReadyForPayouts;

        emit LotteryDrawCompleted(id, vrfRequestId, vrfRandomNumber);
        emit LotteryWinner(id, winner, (jackpot * winnerPayoutPercentage) / 100);
    }

    function _isReadyForChangeSettings() internal view returns (bool) {
        return lotteryState != LotteryState.Opened;
    }

    function _isReadyForOpen() internal view returns (bool) {
        bool isClosed = (lotteryState == LotteryState.Closed);
        bool isJackpotEmpty = (jackpot == 0);
        return (isClosed && isInitialized && isJackpotEmpty);
    }

    function _isReadyForDraw() internal view returns (bool) {
        bool isOpen = (lotteryState == LotteryState.Opened);
        bool hasEnoughPlayers = (players.length >= minPlayers);
        bool maxPlayersReached = (players.length == maxPlayers);
        bool isExpired = (block.timestamp >= (openedAt + durationMinutes * 1 minutes));

        return (isOpen && (maxPlayersReached || (isExpired && hasEnoughPlayers)));
    }

    function _isReadyForPayouts() internal view returns (bool) {
        return lotteryState == LotteryState.ReadyForPayouts;
    }

    function _isReadyToAcceptPlayer(address player_) internal view returns (bool) {
        bool isOpen = (lotteryState == LotteryState.Opened);
        bool isNewPlayer = (!playerHasEntered[player_]);
        bool isNotMaxPlayers = (players.length + 1 <= maxPlayers);

        return (isOpen && isNewPlayer && isNotMaxPlayers);
    }

    function _isReadyForClose() internal view returns (bool) {
        bool isNotClosed = lotteryState != LotteryState.Closed;
        bool allPlayersPaid = payoutsExecuted == players.length;

        return (isNotClosed && allPlayersPaid);
    }

    function draw() external nonReentrant whenNotPaused onlyOwner {
        _draw();
    }

    function _draw() private {
        if (!(_isReadyForDraw())) revert InvalidState();
        lotteryState = LotteryState.Draw;
        emit LotteryDrawStarted(id, jackpot);

        winnerPayout = (jackpot * winnerPayoutPercentage) / 100;
        leftOverPayoutPerPlayer = (jackpot - winnerPayout) / (players.length - 1);

        vrfRequestId = vrfCoordinatorV2Interface.requestRandomWords(
            vrfKeyHash,
            vrfSubscriptionId,
            vrfRequestConfirmations,
            vrfCoordinatorCallbackGasLimit,
            1
        );
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    ) external view override returns (bool upkeepNeeded, bytes memory performData) {
        if (_isReadyForOpen()) {
            performData = abi.encode(LotteryState.Opened, new address[](0), new uint256[](0));
            upkeepNeeded = true;
            return (upkeepNeeded, performData);
        }

        if (_isReadyForDraw()) {
            performData = abi.encode(LotteryState.Draw, new address[](0), new uint256[](0));
            upkeepNeeded = true;
            return (upkeepNeeded, performData);
        }

        if (_isReadyForPayouts()) {
            (address[] memory _addresses, uint256[] memory _balances) = _computePayouts(payoutsExecuted);
            performData = abi.encode(LotteryState.ReadyForPayouts, _addresses, _balances);
            upkeepNeeded = true;
            return (upkeepNeeded, performData);
        }

        upkeepNeeded = false;
        return (upkeepNeeded, "");
    }

    // Give ability to manually execute payouts in batches
    // This is useful if the upkeeper is not able to automatically execute the payouts
    // i.e. Chainlink related issues or severe1
    function performUpkeepManual(bytes calldata performData) external nonReentrant onlyOwner {
        (LotteryState nextState, address[] memory _addresses, uint256[] memory _balances) = abi.decode(
            performData,
            (LotteryState, address[], uint256[])
        );
        _performUpkeep(nextState, _addresses, _balances);
    }

    function performUpkeep(bytes calldata performData) external override nonReentrant whenNotPaused {
        (LotteryState nextState, address[] memory _addresses, uint256[] memory _balances) = abi.decode(
            performData,
            (LotteryState, address[], uint256[])
        );

        _performUpkeep(nextState, _addresses, _balances);
    }

    function _performUpkeep(
        LotteryState nextState,
        address[] memory _addresses,
        uint256[] memory _balances
    ) internal whenNotPaused {
        if (nextState == LotteryState.Opened) return _open();
        if (nextState == LotteryState.Draw) return _draw();
        if (nextState == LotteryState.ReadyForPayouts) return _executePayouts(_addresses, _balances);
    }

    function _computePayouts(uint256 startIndex) internal view returns (address[] memory, uint256[] memory) {
        address[] memory _players = players;
        uint256 payoutsLeft = players.length - startIndex;
        uint256 currentBlockPayouts = payoutsLeft > payoutsPerBlock ? payoutsPerBlock : payoutsLeft;

        address[] memory _addresses = new address[](currentBlockPayouts);
        uint256[] memory _payouts = new uint256[](currentBlockPayouts);

        uint256 tempIndex = 0;
        for (uint256 i = startIndex; i < (startIndex + currentBlockPayouts); i = unsafeInc(i)) {
            _addresses[tempIndex] = _players[i];
            if (_players[i] == winner) _payouts[tempIndex] = winnerPayout;
            else _payouts[tempIndex] = leftOverPayoutPerPlayer;

            tempIndex++;
        }
        return (_addresses, _payouts);
    }

    function _executePayouts(address[] memory _addresses, uint256[] memory _payouts) internal {
        if (!(_isReadyForPayouts())) revert InvalidState();

        payoutsExecuted = payoutsExecuted + _addresses.length;

        for (uint256 index = 0; index < _addresses.length; index = unsafeInc(index)) {
            // Ensure that
            // 1. the payout is not executed twice for the same player
            if (!playerHasEntered[_addresses[index]]) revert PlayerAlreadyEntered();
            // 2. that addresses that have not participated in the lottery are not paid
            // 3. that the input payout is not more than the player's balance
            if (_addresses[index] == winner && _payouts[index] != winnerPayout) revert InvalidPayout();
            else if (_addresses[index] != winner && _payouts[index] != leftOverPayoutPerPlayer) revert InvalidPayout();

            playerHasEntered[_addresses[index]] = false;
            jackpot -= _payouts[index];
            asyncTransfer(_addresses[index], _payouts[index]);
        }

        if (payoutsExecuted == players.length) {
            _close();
        }
    }

    function unsafeInc(uint256 index) internal pure returns (uint256) {
        unchecked {
            return index + 1;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

/// @title Prevents delegatecall to a contract
/// @notice Base contract that provides a modifier for preventing delegatecall to methods in a child contract
abstract contract NoDelegateCall {
    /// @dev The original address of this contract
    address private immutable original;

    constructor() {
        // Immutables are computed in the init code of the contract, and then inlined into the deployed bytecode.
        // In other words, this variable won't change when it's checked at runtime.
        original = address(this);
    }

    /// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method,
    ///     and the use of immutable means the address bytes are copied in every place the modifier is used.
    function checkNotDelegateCall() private view {
        require(address(this) == original);
    }

    /// @notice Prevents delegatecall into the modified method
    modifier noDelegateCall() {
        checkNotDelegateCall();
        _;
    }
}
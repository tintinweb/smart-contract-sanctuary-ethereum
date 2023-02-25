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
pragma solidity 0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

import "./lottery/ILotteryEvents.sol";
import "./lottery/ILotteryEnums.sol";
import "./lottery/ILotteryState.sol";
import "./lottery/ILotteryImmutables.sol";
import "./lottery/ILotteryOwnerActions.sol";
import "./lottery/ILotteryActions.sol";
import "./lottery/ILotteryDerivedState.sol";

/// @title The interface for a Lottery
/// @notice A Lottery
/// @dev The lottery interface is broken up into many smaller pieces
interface ILottery is
    ILotteryEnums,
    ILotteryImmutables,
    ILotteryState,
    ILotteryDerivedState,
    ILotteryOwnerActions,
    ILotteryActions,
    ILotteryEvents,
    KeeperCompatibleInterface
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

/// @title Lottery actions
/// @notice Contains lottery methods that can be called by anyoneinterface ILotteryActions {
interface ILotteryActions {
    /// @notice The standard receive() function.
    /// This is prevented from being called in favor of the enter() function
    receive() external payable;

    /// @notice The standard fallback() function.
    /// This is prevented from being called.
    fallback() external payable;

    /// @notice Enter the lottery
    function enter() external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "./ILotteryEnums.sol";
import "./ILotteryStructs.sol";

/// @title Permissionless lottery actions
/// @notice Contains lottery methods that can be called by anyoneinterface ILotteryActions {
interface ILotteryDerivedState is ILotteryStructs {
    /// @notice Get the lottery totale players
    /// @return The total number of players in the lottery at the time of the request
    function getTotalPlayers() external view returns (uint256);

    /// @notice Get the lottery data
    /// @return The lottery data
    function getLotteryMetadata() external view returns (LotteryMetadata memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

/// @title Lottery state that never changes
/// @notice These parameters are fixed for a lotter forever, i.e., the methods will always return the same values
interface ILotteryEnums {
    /// @notice The lottery state enum
    enum LotteryState {
        Opened,
        Draw,
        ReadyForPayouts,
        Closed
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

/// @title Lottery state that never changes
/// @notice These parameters are fixed for a lotter forever, i.e., the methods will always return the same values
interface ILotteryEvents {
    event VRFSettings(
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
        uint256 drawId,
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
    event PlayerEntered(uint256 drawId, address player, uint256 ticketPrice);
    event LotteryDrawStarted(uint256 drawId, uint256 jackpot);
    event LotteryDrawCompleted(
        uint256 drawId,
        uint256 vrfRequestId,
        uint256 vrfRandomNumber,
        address winner,
        uint256 winnerPayout
    );
    event LotteryClosed(
        uint256 drawId,
        uint256 ticketPrice,
        uint256 feePercentage,
        address feeDestination,
        uint256 charityPercentage,
        address charityDestination,
        uint256 vrfRequestId,
        uint256 vrfRandomNumber,
        address winner,
        uint256 winnerPayout,
        uint256 leftOverPayoutPerPlayer
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Lottery state that never changes
/// @notice These parameters are fixed for a lotter forever, i.e., the methods will always return the same values
interface ILotteryImmutables {
    /// @notice The VRF Coordinator interface
    /// @return The contract VRF Coordinator interface
    function vrfCoordinatorV2Interface() external view returns (VRFCoordinatorV2Interface);

    /// @notice The contract that deployed the lottery, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice For ERC20 enabled lotteries, the token contract address
    /// @return The token contract address or address(0) if the lottery is not ERC20 enabled
    function token() external view returns (IERC20);

    /// @notice The first of the two tokens of the lottery, sorted by address
    /// @return The token contract address
    function ticketPrice() external view returns (uint256);

    /// @notice The second of the two tokens of the lottery, sorted by address
    /// @return The token contract address
    function durationMinutes() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

/// @title Permissioned lottery actions
/// @notice Contains lottery methods that may only be called by the factory owner
interface ILotteryOwnerActions {
    /// @notice Set the VRF settings for the lottery
    /// @param vrfKeyHash_ The VRF key hash
    /// @param vrfSubscriptionId_ The VRF subscription ID
    /// @param vrfCoordinatorCallbackGasLimit_  The VRF coordinator callback gas limit
    /// @param vrfRequestConfirmations_ The number of VRF request confirmations
    function setVRFSettings(
        bytes32 vrfKeyHash_,
        uint64 vrfSubscriptionId_,
        uint32 vrfCoordinatorCallbackGasLimit_,
        uint16 vrfRequestConfirmations_
    ) external;

    /// @notice Set the lottery settings for the lottery
    /// @param winnerPayoutPercentage_ The percentage of the jackpot that goes to the winner
    /// @param feePercentage_ The percentage of the ticket price that goes to the fee destination
    /// @param feeDestination_ The address of the fee destination
    /// @param charityPercentage_ The percentage of the ticket price that goes to charity
    /// @param charityDestination_ The address of the charity destination
    /// @param maxPlayers_ The maximum number of players allowed in the lottery
    /// @param minPlayers_ The minimum number of players required to start the lottery
    /// @param payoutsPerBlock_ The number of payouts to make per block
    function initialize(
        uint256 winnerPayoutPercentage_,
        uint256 feePercentage_,
        address feeDestination_,
        uint256 charityPercentage_,
        address charityDestination_,
        uint256 maxPlayers_,
        uint256 minPlayers_,
        uint256 payoutsPerBlock_
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "./ILotteryEnums.sol";

/// @title Lottery state that never changes
/// @notice These parameters are fixed for a lotter forever, i.e., the methods will always return the same values
interface ILotteryState is ILotteryEnums {
    /// @notice The lottery ID which increments with each lottery
    /// @return The lottery ID
    function drawId() external view returns (uint256);

    /// @notice The lottery state
    /// @return The lottery state
    function lotteryState() external view returns (LotteryState);

    /// @notice The block timestamp when the lottery was opened
    /// @return The timestamp
    function openedAt() external view returns (uint256);

    /// @notice Whether the lottery has been initialized
    /// @return Whether the lottery has been initialized
    function isInitialized() external view returns (bool);

    /// @notice The balance of the player in the current lottery
    /// @return The balance of the player in the current lottery
    function balances(address player) external view returns (uint256);

    /// @notice The maximum number of players allowed in a lottery
    /// @return The maximum number of players
    function maxPlayers() external view returns (uint256);

    /// @notice The minimum number of players to trigger a draw when the duration has passed
    /// @return The minimum number of players
    function minPlayers() external view returns (uint256);

    /// @notice The number of payouts per block in order to scale the payouts regardless of the number of players
    /// @return The number of payouts per block
    function payoutsPerBlock() external view returns (uint256);

    /// @notice The number of payouts executed within the current lottery
    /// @return The number of payouts executed
    function payoutsExecuted() external view returns (uint256);

    /// @notice Thepercentage of the lottery ticket price that goes to the fee destination
    /// @return The fee percentage
    function feePercentage() external view returns (uint256);

    /// @notice The address of the fee destination
    /// @return The fee destination address
    function feeDestination() external view returns (address);

    /// @notice The percentage of the lottery ticket price that goes to charity
    /// @return The charity percentage
    function charityPercentage() external view returns (uint256);

    /// @notice The address of the charity destination
    /// @return The charity destination address
    function charityDestination() external view returns (address);

    /// @notice The jackpot of the current lottery
    /// @return The jackpot
    function jackpot() external view returns (uint256);

    /// @notice The percentage of the jackpot that goes to the winner of the lottery
    /// @return The winner payout percentage
    function winnerPayoutPercentage() external view returns (uint256);

    /// @notice The amount of the jackpot that goes to the winner of the lottery
    /// @return The winner payout
    function winnerPayout() external view returns (uint256);

    /// @notice The winner of the current lottery
    /// @return The winner address
    function winner() external view returns (address);

    /// @notice The amount of the jackpot that goes to othr players in the lottery
    /// @return The left over payout per player
    function leftOverPayoutPerPlayer() external view returns (uint256);

    /// @notice Whether the player has entered the current lottery
    /// @return Whether the player has entered the current lottery
    function playerHasEntered(address player) external view returns (bool);

    /// @notice The key hash of the VRF coordinator
    /// @return The key hash
    function vrfKeyHash() external view returns (bytes32);

    /// @notice The number of confirmations required for a VRF request to be considered confirmed
    /// @return The number of confirmations
    function vrfRequestConfirmations() external view returns (uint16);

    /// @notice The gas limit for the VRF coordinator callback
    /// @return The gas limit
    function vrfCoordinatorCallbackGasLimit() external view returns (uint32);

    /// @notice The subscription ID of the VRF coordinator
    /// @return The subscription ID
    function vrfSubscriptionId() external view returns (uint64);

    /// @notice The VRF request ID of the current lottery
    /// @return The VRF request ID
    function vrfRequestId() external view returns (uint256);

    /// @notice The VRF random number (randomness) generated at the draw of the current lottery
    /// @return The VRF random number
    function vrfRandomNumber() external view returns (uint256);

    /// @notice Mapping lotteries ID to the related winner address
    /// @return The winner address for the given lottery ID
    function lotteriesWinner(uint256 _id) external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ILotteryEnums.sol";

/// @title Lottery state that never changes
/// @notice These parameters are fixed for a lotter forever, i.e., the methods will always return the same values
interface ILotteryStructs is ILotteryEnums {
    /// @notice The lottery metadata struct
    struct LotteryMetadata {
        uint256 id;
        IERC20 erc20Token;
        LotteryState lotteryState;
        uint256 openedAt;
        uint256 durationMinutes;
        uint256 ticketPrice;
        uint256 jackpot;
        uint256 totalPlayers;
        address winner;
        uint256 winnerPayout;
        uint256 winnerPayoutPercentage;
        uint256 feePercentage;
        address feeDestination;
        uint256 charityPercentage;
        address charityDestination;
        uint256 maxPlayers;
        uint256 minPlayers;
        uint256 payoutsPerBlock;
        uint256 vrfRequestId;
        uint256 vrfRandomNumber;
    }
}

// SPDX-FileCopyrightText: © Lotterypto <[email protected]>
// SPDX-License-Identifier: CC-BY-NC-SA-4.0

// Lottery Smart Contract © Lotterypto is licensed under Attribution-NonCommercial-ShareAlike 4.0 International
// To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/4.0/
pragma solidity 0.8.19;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/ILottery.sol";

error InvalidState();
error InvalidVRFCoordinatorResponse();
error InvalidVRFCoordinatorAddress();
error InvalidTicketPrice();
error InvalidWinnerPayoutPercentage();
error PlayerAlreadyEntered();
error InvalidFeePercentage();
error InvalidFeeDestinationAddress();
error InvalidPayoutsPerBlock();
error InvalidCharityDestinationAddress();
error InvalidCharityPercentage();
error InvalidMaxPlayers();
error InvalidMinPlayers();
error InvalidPayout();
error InvalidCall();
error EmptyBalance();

contract LotteryERC20 is ILottery, Ownable, Pausable, ReentrancyGuard, VRFConsumerBaseV2 {
    using SafeERC20 for IERC20;

    // @inheritdoc ILotteryState
    LotteryState public override lotteryState = LotteryState.Closed;
    // @inheritdoc ILotteryState
    uint256 public override drawId;
    // @inheritdoc ILotteryState
    uint256 public override openedAt;
    // @inheritdoc ILotteryState
    bool public override isInitialized;
    // @inheritdoc ILotteryState
    mapping(address => uint256) public override balances;
    // @inheritdoc ILotteryState
    mapping(uint256 => address) public override lotteriesWinner;
    // @inheritdoc ILotteryState
    uint256 public override maxPlayers;
    // @inheritdoc ILotteryState
    uint256 public override minPlayers;
    // @inheritdoc ILotteryState
    uint256 public override payoutsPerBlock;
    // @inheritdoc ILotteryState
    uint256 public override payoutsExecuted;
    // @inheritdoc ILotteryState
    uint256 public override feePercentage;
    // @inheritdoc ILotteryState
    address public override feeDestination;
    // @inheritdoc ILotteryState
    uint256 public override charityPercentage;
    // @inheritdoc ILotteryState
    address public override charityDestination;
    // @inheritdoc ILotteryState
    uint256 public override jackpot;
    // @inheritdoc ILotteryState
    uint256 public override winnerPayoutPercentage;
    // @inheritdoc ILotteryState
    uint256 public override winnerPayout;
    // @inheritdoc ILotteryState
    address public override winner;
    // @inheritdoc ILotteryState
    uint256 public override leftOverPayoutPerPlayer;
    // @inheritdoc ILotteryState
    mapping(address => bool) public override playerHasEntered;
    // @inheritdoc ILotteryState
    bytes32 public override vrfKeyHash;
    // @inheritdoc ILotteryState
    uint16 public override vrfRequestConfirmations;
    // @inheritdoc ILotteryState
    uint32 public override vrfCoordinatorCallbackGasLimit;
    // @inheritdoc ILotteryState
    uint64 public override vrfSubscriptionId;
    // @inheritdoc ILotteryState
    uint256 public override vrfRequestId;
    // @inheritdoc ILotteryState
    uint256 public override vrfRandomNumber;

    /// @inheritdoc ILotteryImmutables
    IERC20 public immutable token;
    /// @inheritdoc ILotteryImmutables
    VRFCoordinatorV2Interface public immutable vrfCoordinatorV2Interface;
    /// @inheritdoc ILotteryImmutables
    address public immutable override factory;
    /// @inheritdoc ILotteryImmutables
    uint256 public immutable override ticketPrice;
    /// @inheritdoc ILotteryImmutables
    uint256 public immutable override durationMinutes;

    address[] public players;

    constructor(
        address owner_,
        address tokenAddress_,
        address vrfCoordinatorAddress_,
        uint256 ticketPrice_,
        uint256 durationMinutes_
    ) VRFConsumerBaseV2(vrfCoordinatorAddress_) {
        factory = msg.sender;
        ticketPrice = ticketPrice_;
        durationMinutes = durationMinutes_;

        vrfCoordinatorV2Interface = VRFCoordinatorV2Interface(vrfCoordinatorAddress_);
        token = IERC20(tokenAddress_);

        // immediately transfer ownership from factory to the owner
        // so that the owner can set the VRF settings
        transferOwnership(owner_);
    }

    function enter() external payable override nonReentrant whenNotPaused {
        if (msg.value != 0) revert InvalidCall();
        if (!_isReadyToAcceptPlayer(msg.sender)) revert InvalidState();
        _enter(msg.sender);
        token.safeTransferFrom(msg.sender, address(this), ticketPrice);
    }

    receive() external payable virtual nonReentrant whenNotPaused {
        revert InvalidCall();
    }

    fallback() external payable nonReentrant whenNotPaused {
        revert InvalidCall();
    }

    /// @inheritdoc ILotteryDerivedState
    function getLotteryMetadata() external view override returns (LotteryMetadata memory) {
        return
            LotteryMetadata(
                drawId,
                token,
                lotteryState,
                openedAt,
                durationMinutes,
                ticketPrice,
                jackpot,
                players.length,
                winner,
                winnerPayout,
                winnerPayoutPercentage,
                feePercentage,
                feeDestination,
                charityPercentage,
                charityDestination,
                maxPlayers,
                minPlayers,
                payoutsPerBlock,
                vrfRequestId,
                vrfRandomNumber
            );
    }

    /// @inheritdoc ILotteryDerivedState
    function getTotalPlayers() external view override returns (uint256) {
        return players.length;
    }

    // @inheritdoc ILotteryOwnerActions
    function setVRFSettings(
        bytes32 vrfKeyHash_,
        uint64 vrfSubscriptionId_,
        uint32 vrfCoordinatorCallbackGasLimit_,
        uint16 vrfRequestConfirmations_
    ) external override onlyOwner {
        vrfKeyHash = vrfKeyHash_;
        vrfSubscriptionId = vrfSubscriptionId_;
        vrfCoordinatorCallbackGasLimit = vrfCoordinatorCallbackGasLimit_;
        vrfRequestConfirmations = vrfRequestConfirmations_;

        emit VRFSettings(vrfKeyHash, vrfSubscriptionId, vrfCoordinatorCallbackGasLimit, vrfRequestConfirmations);
    }

    // @inheritdoc ILotteryOwnerActions
    function initialize(
        uint256 winnerPayoutPercentage_,
        uint256 feePercentage_,
        address feeDestination_,
        uint256 charityPercentage_,
        address charityDestination_,
        uint256 maxPlayers_,
        uint256 minPlayers_,
        uint256 payoutsPerBlock_
    ) external override onlyOwner {
        if (!_isReadyForChangeSettings()) revert InvalidState();
        if (feeDestination_ == address(0)) revert InvalidFeeDestinationAddress();
        if (feePercentage_ == 0) revert InvalidFeePercentage();
        if (winnerPayoutPercentage_ == 0) revert InvalidWinnerPayoutPercentage();
        if (charityPercentage_ > 0 && charityDestination_ == address(0)) revert InvalidCharityDestinationAddress();
        if (charityPercentage_ == 0 && charityDestination_ != address(0)) revert InvalidCharityPercentage();
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

    // @notice Opens a new lottery
    // @dev The lottery must be initialized before it can be opened via the initialize function
    // @dev Can only be called from the upkeeper and only when the lottery is in the Closed state and when the jackpot has been paid out
    // @dev emits a LotteryOpened event
    function _open() private {
        if (!_isReadyForOpen()) revert InvalidState();

        drawId++;
        openedAt = block.timestamp;
        lotteryState = LotteryState.Opened;
        players = new address[](0);
        balances[feeDestination] = 0;
        balances[charityDestination] = 0;
        payoutsExecuted = 0;

        emit LotteryOpened(
            drawId,
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

    // @notice accepts a player into the lottery deducting the fee and charity amount (immediately async transfers the fee and charity to the fee and charity destinations) and updates the whole jackpot
    // @dev can only be called from the enter function
    // @dev Can only be called when the lottery is in the Opened state, the player has not already entered and the player has sent the correct amount of tokens
    // @dev emits a PlayerEntered event
    function _enter(address player_) private {
        players.push(payable(player_));
        playerHasEntered[player_] = true;

        uint256 fee = (ticketPrice * feePercentage) / 100;
        uint256 charity = ((ticketPrice * charityPercentage) / 100);

        _asyncTransfer(feeDestination, fee);
        _asyncTransfer(charityDestination, charity);

        jackpot += (ticketPrice - fee - charity);
        emit PlayerEntered(drawId, player_, ticketPrice);
    }

    // @notice called by the VRF coordinator when the randomness is ready, picks the winner based on randomness and updates the lottery state
    // @dev emits a LotteryDrawCompleted event and a LotteryWinner event
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override nonReentrant {
        if (vrfRequestId != requestId) revert InvalidVRFCoordinatorResponse();
        if (lotteryState != LotteryState.Draw) revert InvalidState();
        if (randomWords.length < 1) revert InvalidVRFCoordinatorResponse();

        vrfRandomNumber = randomWords[0];
        winner = players[vrfRandomNumber % players.length];
        lotteryState = LotteryState.ReadyForPayouts;

        lotteriesWinner[drawId] = winner;

        emit LotteryDrawCompleted(
            drawId,
            vrfRequestId,
            vrfRandomNumber,
            winner,
            (jackpot * winnerPayoutPercentage) / 100
        );
    }

    // @notice verifies that the lottery is ready for changing lottery settings
    // @return true if the lottery is ready for changing lottery settings
    function _isReadyForChangeSettings() private view returns (bool) {
        return lotteryState != LotteryState.Opened;
    }

    // @notice verifies that the lottery is ready for opening
    // @dev the lottery must be initialized and the jackpot must have been paid out in full
    // @return true if the lottery is ready for opening
    function _isReadyForOpen() private view returns (bool) {
        bool isClosed = (lotteryState == LotteryState.Closed);
        bool isJackpotEmpty = (jackpot == 0);
        return (isClosed && isInitialized && isJackpotEmpty);
    }

    // @notice verifies that the lottery is ready for start the draw and pick a winner
    // @dev the lottery must be in the Opened state, have enough players if duration has been passed or and have already reached the max players limit.
    // @dev This is to speed up the next opening in case of high participation or to prevent the lottery from being open for ever if there are not enough players
    // @dev using block.timestamp here since even if time manipulation happens the worst case scenario is that the lottery will be open few minutes longer than expected
    // @return true if the lottery is ready for start the draw and pick a winner
    function _isReadyForDraw() private view returns (bool) {
        bool isOpen = (lotteryState == LotteryState.Opened);
        bool hasEnoughPlayers = (players.length >= minPlayers);
        bool maxPlayersReached = (players.length == maxPlayers);
        bool isExpired = (block.timestamp >= (openedAt + durationMinutes * 1 minutes));

        return (isOpen && (maxPlayersReached || (isExpired && hasEnoughPlayers)));
    }

    // @notice verifies that the lottery is ready to distribute payouts
    // @dev the lottery must be in the ReadyForPayouts state
    // @return true if the lottery is ready to distribute payouts
    function _isReadyForPayouts() private view returns (bool) {
        return lotteryState == LotteryState.ReadyForPayouts;
    }

    // @notice verifies that the lottery is ready to accept a new player
    // @dev the lottery must be in the Opened state, the player must not have already entered and the max players limit must not have been reached
    // @return true if the lottery is ready to accept a player
    function _isReadyToAcceptPlayer(address player_) private view returns (bool) {
        bool isOpen = (lotteryState == LotteryState.Opened);
        bool isNewPlayer = (!playerHasEntered[player_]);
        bool isNotMaxPlayers = (players.length + 1 <= maxPlayers);

        return (isOpen && isNewPlayer && isNotMaxPlayers);
    }

    // @notice verifies that the lottery is ready to be closed
    // @dev the lottery must not be in the Opened state and all players must have been paid out
    // @return true if the lottery is ready to be closed
    function _isReadyForClose() private view returns (bool) {
        bool isNotClosed = lotteryState != LotteryState.Closed;
        bool allPlayersPaid = payoutsExecuted == players.length;

        return (isNotClosed && allPlayersPaid);
    }

    // @notice Calculates the winner payout and the left over payout per player and requests a random number from the VRF coordinator to obtain a provably random number
    // @dev Can only be called from the upkeeper and only when the lottery is in the Opened state and when the lottery has expired or the max players have been reached
    // @dev emits a LotteryDrawStarted event
    function _draw() private {
        if (!(_isReadyForDraw())) revert InvalidState();
        lotteryState = LotteryState.Draw;
        emit LotteryDrawStarted(drawId, jackpot);

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

    // @notice performs the upkeeping of the lottery by deciding what to do next based on the nextState parameter coming from the checkUpkeep function
    // @dev Can only be called from the upkeeper
    // @dev even nextState is used to determine what to do next, the private functions will still ensure that the state of the lottery is consistent to make sure that the upkeeper is not trying to do something that is not allowed
    function _performUpkeep(
        LotteryState nextState,
        address[] memory _addresses,
        uint256[] memory _balances
    ) private whenNotPaused {
        if (nextState == LotteryState.Opened) return _open();
        if (nextState == LotteryState.Draw) return _draw();
        if (nextState == LotteryState.ReadyForPayouts) return _executePayouts(_addresses, _balances);
    }

    // @notice computes the payouts for the current block
    // @dev the payouts are computed based on the startIndex parameter and the payoutsPerBlock parameter
    // @dev the startIndex parameter is used to determine where to start computing the payouts from
    // @dev the payoutsPerBlock parameter is used to determine how many payouts to compute
    // @dev this is to prevent the gas limit from being exceeded when computing payouts for all players by distributing the payouts over multiple blocks, scaling with the number of players
    // @dev the payouts are computed by looping through the players array and adding the winner payout to the winner and the left over payout per player to all other players
    // @dev a view function is used to save gas in payouts calulcations and pay gas fees only when we know exact payout amout per address
    // @return the addresses of the players that will receive a payout with the payout amounts in the current block
    function _computePayouts(uint256 startIndex) private view returns (address[] memory, uint256[] memory) {
        address[] memory _players = players;
        uint256 payoutsLeft = players.length - startIndex;
        uint256 currentBlockPayouts = payoutsLeft > payoutsPerBlock ? payoutsPerBlock : payoutsLeft;

        address[] memory _addresses = new address[](currentBlockPayouts);
        uint256[] memory _payouts = new uint256[](currentBlockPayouts);

        uint256 tempIndex = 0;
        for (uint256 i = startIndex; i < (startIndex + currentBlockPayouts); i = _unsafeInc(i)) {
            _addresses[tempIndex] = _players[i];
            if (_players[i] == winner) _payouts[tempIndex] = winnerPayout;
            else _payouts[tempIndex] = leftOverPayoutPerPlayer;

            tempIndex++;
        }
        return (_addresses, _payouts);
    }

    // @notice executes the payouts for the current block
    // @dev the payouts are executed based on the addresses and payouts parameters coming from the _computePayouts function
    // @dev the addresses and payouts parameters are used to determine which players will receive a payout and how much they will receive
    // @dev the payouts are executed by looping through the addresses and payouts arrays and transferring the payout amount to the player address
    // @dev funds are transferred via the _asyncTransfer function to avoid issues if reciever is a malicious contract that reverts the transaction risking the lottery to be stuck in a state where payouts are never executed
    function _executePayouts(address[] memory _addresses, uint256[] memory _payouts) private {
        if (!(_isReadyForPayouts())) revert InvalidState();

        payoutsExecuted = payoutsExecuted + _addresses.length;

        for (uint256 index = 0; index < _addresses.length; index = _unsafeInc(index)) {
            if (!playerHasEntered[_addresses[index]]) revert PlayerAlreadyEntered();
            if (_addresses[index] == winner && _payouts[index] != winnerPayout) revert InvalidPayout();
            else if (_addresses[index] != winner && _payouts[index] != leftOverPayoutPerPlayer) revert InvalidPayout();

            playerHasEntered[_addresses[index]] = false;
            jackpot -= _payouts[index];
            _asyncTransfer(_addresses[index], _payouts[index]);
        }

        if (payoutsExecuted == players.length) {
            _close();
        }
    }

    // @notice closes the lottery
    // @dev since divisions leave few wei behind, the remaining wei are transferred to the fee destination to ensure that the contract is empty before closing the lottery
    // @dev Can only be called from the upkeeper and only when the lottery is in the ReadyForPayouts state and when all players have been paid
    // @dev emits a LotteryClosed event
    function _close() private whenNotPaused {
        if (!_isReadyForClose()) revert InvalidState();
        // Divisions leaves few wei behind
        // so we add it to the fee destination
        // to ensure that the contract is empty
        _asyncTransfer(feeDestination, jackpot);
        jackpot = 0;
        lotteryState = LotteryState.Closed;

        emit LotteryClosed(
            drawId,
            ticketPrice,
            feePercentage,
            feeDestination,
            charityPercentage,
            charityDestination,
            vrfRequestId,
            vrfRandomNumber,
            winner,
            winnerPayout,
            leftOverPayoutPerPlayer
        );
    }

    // @inheritdoc KeeperCompatibleInterface
    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData) {
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

    // @inheritdoc KeeperCompatibleInterface
    function performUpkeep(bytes calldata performData) external override nonReentrant whenNotPaused {
        (LotteryState nextState, address[] memory _addresses, uint256[] memory _balances) = abi.decode(
            performData,
            (LotteryState, address[], uint256[])
        );

        _performUpkeep(nextState, _addresses, _balances);
    }

    // @notice increments a uint256 by 1 to save gas in loops
    // @dev this function is used to save gas in loops by not checking for overflows since we control the start and end of the loop
    function _unsafeInc(uint256 index) private pure returns (uint256) {
        unchecked {
            return index + 1;
        }
    }

    function _asyncTransfer(address dest, uint256 amount) internal {
        balances[dest] += amount;
    }

    function payments(address dest) external view returns (uint256) {
        return balances[dest];
    }

    function withdrawPayments(address payable payee) external nonReentrant whenNotPaused {
        if (balances[payee] == 0) revert EmptyBalance();

        uint256 payout = balances[payee];
        balances[payee] = 0;

        token.safeApprove(address(this), payout);
        token.safeTransferFrom(address(this), payee, payout);
    }
}
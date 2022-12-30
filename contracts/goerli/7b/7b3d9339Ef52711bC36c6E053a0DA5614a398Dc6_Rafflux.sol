// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

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
/**
 * @notice This is a deprecated interface. Please use AutomationCompatible directly.
 */
pragma solidity ^0.8.0;
import {AutomationCompatible as KeeperCompatible} from "./AutomationCompatible.sol";
import {AutomationBase as KeeperBase} from "./AutomationBase.sol";
import {AutomationCompatibleInterface as KeeperCompatibleInterface} from "./interfaces/AutomationCompatibleInterface.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// Rafflux.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "@openzeppelin/contracts/utils/Counters.sol";

// VRF imports
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

// This import could be not necessary
// This import includes functions from both ./KeeperBase.sol and
// ./interfaces/KeeperCompatibleInterface.sol
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";


contract Rafflux is VRFConsumerBaseV2, Ownable {

	using Counters for Counters.Counter;
	
	// Address in charge of accept/decline proposals. raffleFee beneficiary
	address payable _owner;
	
	// A fee every raffle creator will pay to create a new raffle
	uint raffleFee = 0.01 ether;			// 0.01 ether for testing purposes
	// After this deadline, the proposer could revoke the proposal
	uint proposalDeadline = 60 seconds;		// 60 seconds for testing purposes
	// The maximum number of tickets allowed per raffle
	uint maxTicketsPerRaffle = 10;			// 10 for testing purporses
	// The maximun time a raffle could be active
	uint maxTimeActive = 300 seconds;		// 5 minutes for testing purposes
		
	// Assets type accepted by the contract
	enum assetType {
		ERC721,
		ERC1155
	}
	
	// Info about a raffle pending to be accepted by the admin
	struct ProposedRaffle {
		address by;  			//	The address proposing a raffle
		assetType assetType;	//	The type of the asset to be raffle off
		uint assetId;			//	The id of the asset to be raffled off
		address assetContract;	//	The asset contract address
		uint price;  			//	The price of every ticket
		uint maxTickets;		//	The max number of tickets
		uint maxTimeActive;		// 	The max time the raffle will be active
		uint proposedAt;		//  The timestamp of the propose
	}
	
	// Info about a raffle accepted by the admin
	struct AcceptedRaffle {
		address by;  			//	The address of the raffle creator
		assetType assetType;	//	The type of the asset to be raffle off
		uint assetId;			//	The id of the asset to be raffled off
		address assetContract;	//	The asset contract address
		uint price;  			//	The price of every ticket
		uint maxTickets;		//	The max number of tickets
		uint maxTimeActive;		// 	The max time the raffle will be active
		uint startedAt;			//	The timestamp when raffle starts
		uint ticketsLeft;		//	The number of tickets left until sold out
	}
	
	// Info about a ticket sold for a determined raffle
	struct Ticket {
		uint ticketId;			// The ID of the ticket
		address owner;			// The address who owns the ticket
		uint256 raffleId;		// The ID of the raffle the ticket belongs to
	}
	
	// Keep track of the proposed raffles by id 
	mapping (uint256 => ProposedRaffle) public idToProposedRaffle;
	// Keep track of the accepted raffles by id 
	mapping (uint256 => AcceptedRaffle) public idToAcceptedRaffle;
	// Keep track of the tickets by id
	mapping (uint256 => Ticket) public tickets;
	
	mapping(uint256 => uint256) public requestIdToRaffleId;
	
	// Keep track of every raffle proposed. This counter will be used as raffleId
	Counters.Counter totalRaffles;
	
	// Emit an event after successfully proposing a raffle
	event NewProposedRaffle(
		uint256 raffleId,
		address by,
		assetType assetType,
		uint assetId,
		address assetContract,
		uint price,
		uint maxTickets,
		uint maxTimeActive,
		uint proposedAt
	);
	
	// Emit an event after the admin accepted a raffle
	event NewAcceptedRaffle(
		uint256 raffleId,
		address by,
		assetType assetType,
		uint assetId,
		address assetContract,		
		uint price,
		uint maxTickets,
		uint maxTimeActive,
		uint startedAt
	);
	
	// Emit an event after successfully sell a raffle ticket
	event TicketSold(uint256 indexed raffleId, uint indexed ticketId, address buyer);	
	// Emit an event when no more tickets left for a raffle
	event SoldOut(uint256 indexed raffleId, uint256 indexed requestId);
	// Emit an event when no more time left for a raffle
	event TimeOut(uint256 indexed raffleId, uint256 requestId);
	
	// Emit an event after successfully payment to the winner of a raffle
	event NewFinishedRaffle(
		uint256 raffleId,
		uint ticketId,
		address winner,
		assetType assetType,
		uint assetId,
		address assetContract,
		address creator
	);
	
	// VRF
	VRFCoordinatorV2Interface public COORDINATOR;
	uint64 public s_subscriptionId;
	//uint256 public s_requestId;
    uint256[] public s_randomWords;
    uint32 public callbackGasLimit = 2500000;
    bytes32 keyhash =  0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;
	// More info: https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/
    
    
    // GOERLI COORDINATOR: 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D
	constructor(/*address _vrfCoordinator*/) VRFConsumerBaseV2(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D) {
		_owner = payable(msg.sender);
		
		COORDINATOR = VRFCoordinatorV2Interface(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D); 
		s_subscriptionId = 7611;
	}
	
	
	// Any user could propose a new raffle
	function proposeRaffle(assetType _assetType, uint _assetId, address _assetContract, uint _price, uint _maxTickets, uint _maxTimeActive) payable external {
		require(msg.value == raffleFee, 
			"The exact amount of the fee must be paid");
		require(_assetType == assetType.ERC721 || _assetType == assetType.ERC1155, 
			"AssetTypeError");
		require(_assetContract != address(0), 
			"AssetContractAddressError");
		require(_price > 0, 
			"The price must be greater than Zero");
		require(_maxTickets < maxTicketsPerRaffle && _maxTickets > 0,
			 "TicketsAmountError");
		require(_maxTimeActive < maxTimeActive && _maxTimeActive > 0,
			 "ActiveTimeError");
		// Store the raffle proposal
		//-- uint256 raffleId = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
		uint256 raffleId = totalRaffles.current();
		totalRaffles.increment();
		idToProposedRaffle[raffleId] = ProposedRaffle(
			msg.sender,
			_assetType,
			_assetId,
			_assetContract,
			_price,
			_maxTickets,
			_maxTimeActive,
			block.timestamp
		);
		// Emit event after a successfull proposal
		emit NewProposedRaffle(
			raffleId,
			msg.sender,
			_assetType,
			_assetId,
			_assetContract,
			_price,
			_maxTickets,
			_maxTimeActive,
			block.timestamp
		);
	}
	
	
	// The Admin accepts a proposed raffle
	function acceptRaffle(uint256 _raffleId) external onlyOwner {
		require(block.timestamp < idToProposedRaffle[_raffleId].proposedAt + proposalDeadline,
			"Proposal deadline reached");
				
		idToAcceptedRaffle[_raffleId] = AcceptedRaffle(
			idToProposedRaffle[_raffleId].by,
			idToProposedRaffle[_raffleId].assetType,
			idToProposedRaffle[_raffleId].assetId,
			idToProposedRaffle[_raffleId].assetContract,
			idToProposedRaffle[_raffleId].price,
			idToProposedRaffle[_raffleId].maxTickets,
			idToProposedRaffle[_raffleId].maxTimeActive,
			// Init the raffle timer
			block.timestamp,
			// Put the tickets in the ticket machine
			idToProposedRaffle[_raffleId].maxTickets
			//0
		);
		
		_transferToContract(
			idToProposedRaffle[_raffleId].by,
			idToProposedRaffle[_raffleId].assetType,
			idToProposedRaffle[_raffleId].assetContract,
			idToProposedRaffle[_raffleId].assetId
		);
		
		emit NewAcceptedRaffle(
			_raffleId,
			idToProposedRaffle[_raffleId].by,
			idToProposedRaffle[_raffleId].assetType,
			idToProposedRaffle[_raffleId].assetId,
			idToProposedRaffle[_raffleId].assetContract,
			idToProposedRaffle[_raffleId].price,
			idToProposedRaffle[_raffleId].maxTickets,
			idToProposedRaffle[_raffleId].maxTimeActive,
			idToAcceptedRaffle[_raffleId].startedAt
		);
		
		delete idToProposedRaffle[_raffleId];
	}
	
	
	// The Admin declines a proposed raffle
	function declineRaffle(uint256 _raffleId) external onlyOwner {
		payable(idToProposedRaffle[_raffleId].by).transfer(raffleFee);
		delete idToProposedRaffle[_raffleId];
	}
	
	
	// A proposer can revoke the propose after non response from Admin
	function revokeRaffle(uint256 _raffleId) external {
		require(msg.sender == idToProposedRaffle[_raffleId].by,
			"You are not the proposer");
		require(block.timestamp > idToProposedRaffle[_raffleId].proposedAt + proposalDeadline,
			"Proposal deadline not reached yet. Admin still could accept it");
			
		payable(msg.sender).transfer(raffleFee);
		delete idToProposedRaffle[_raffleId];
	}
	
	
	// Any user could buy a ticket for an accepted raffle
	function buyTicket(uint256 _raffleId) payable external {
		require(msg.value > 0,
			"INVALID AMOUNT");
		require(msg.value == idToAcceptedRaffle[_raffleId].price,
			"INVALID AMOUNT");
		require(idToAcceptedRaffle[_raffleId].ticketsLeft - 1 > 0,
			"SOLD OUT");
		require(block.timestamp < idToAcceptedRaffle[_raffleId].startedAt + idToAcceptedRaffle[_raffleId].maxTimeActive, 
			"Deadline reached. Ended Raffle");
		
		// Transfer an amount equals to the price of the ticket to the raffle creator
		payable(idToAcceptedRaffle[_raffleId].by).transfer(msg.value);

		uint ticketId = idToAcceptedRaffle[_raffleId].maxTickets -
						idToAcceptedRaffle[_raffleId].ticketsLeft;
		tickets[uint(keccak256(abi.encodePacked(_raffleId, ticketId)))] = Ticket(
			ticketId,
			msg.sender,
			_raffleId
		);
		
		idToAcceptedRaffle[_raffleId].ticketsLeft = idToAcceptedRaffle[_raffleId].ticketsLeft - 1;
			
		emit TicketSold(
			_raffleId,
			ticketId,
			msg.sender
		);
		
		if (idToAcceptedRaffle[_raffleId].ticketsLeft == 0) {
			uint256 requestId = _requestRandomness(_raffleId);
			emit SoldOut(_raffleId, requestId);
		}
	}	
	
	// Any user could buy some tickets for an accepted raffle
	function buyTickets(uint256 _raffleId, uint _totalTickets) payable external {
		require(_totalTickets > 0 && msg.value > 0,
			"TICKETS or AMOUNT cannot be Zero");
		unchecked {
			require(msg.value == _totalTickets * idToAcceptedRaffle[_raffleId].price,
				"INVALID AMOUNT");
		}
		require(idToAcceptedRaffle[_raffleId].ticketsLeft >= _totalTickets,
			"SOLD OUT or INVALID ID");
		require(block.timestamp < idToAcceptedRaffle[_raffleId].startedAt + idToAcceptedRaffle[_raffleId].maxTimeActive, 
			"Deadline reached. Ended Raffle");
		
		// Transfer an amount equals to the price of the tickets to the raffle creator
		payable(idToAcceptedRaffle[_raffleId].by).transfer(msg.value);
		
		for (uint i = 0; i < _totalTickets; i++) {
			uint ticketId = idToAcceptedRaffle[_raffleId].maxTickets -
							idToAcceptedRaffle[_raffleId].ticketsLeft;
			tickets[uint(keccak256(abi.encodePacked(_raffleId, ticketId)))] = Ticket(
				ticketId,
				msg.sender,
				_raffleId
			);
			
			idToAcceptedRaffle[_raffleId].ticketsLeft = idToAcceptedRaffle[_raffleId].ticketsLeft - 1;
			
			emit TicketSold(
				_raffleId,
				ticketId,
				msg.sender
			);
		}
		
		if (idToAcceptedRaffle[_raffleId].ticketsLeft == 0) {
			uint256 requestId = _requestRandomness(_raffleId);
			emit SoldOut(_raffleId, requestId);
		}
	}
	
	
	// When deadline is reached, someone need to call the requestRandomness,
	// whoever do it will get 1 FREE ticket as incentive to pay the gas cost
	function requestFinishRaffle(uint256 _raffleId) external {
		require(block.timestamp > idToAcceptedRaffle[_raffleId].startedAt + idToAcceptedRaffle[_raffleId].maxTimeActive, 
			"Deadline not reached");
		require(idToAcceptedRaffle[_raffleId].ticketsLeft > 0, "SOLD OUT");
		
		// Send the FREE ticket to the tx sender
		_freeTicket(_raffleId, msg.sender);
		
		uint256 requestId = _requestRandomness(_raffleId);
		emit TimeOut(_raffleId, requestId);
	}
	
	
	// Send a FREE ticket for a raffle to an address
	function _freeTicket(uint256 _raffleId, address to) internal {
		uint ticketId = idToAcceptedRaffle[_raffleId].maxTickets -
						idToAcceptedRaffle[_raffleId].ticketsLeft;
		tickets[uint(keccak256(abi.encodePacked(_raffleId, ticketId)))] = Ticket(
			ticketId,
			to,
			_raffleId
		);
		
		idToAcceptedRaffle[_raffleId].ticketsLeft = idToAcceptedRaffle[_raffleId].ticketsLeft - 1;
		
		emit TicketSold(
			_raffleId,
			ticketId,
			to
		);
	}
	
	
	// Request a random value to Vrf Chainlink
	function _requestRandomness(uint256 _raffleId) internal returns (uint256) {
		require(s_subscriptionId != 0, "Subscription ID not set");
        // Will revert if subscription is not set and funded
        uint256 requestId = COORDINATOR.requestRandomWords(
            keyhash,
            s_subscriptionId,
            3, 						// minimum confirmations before response
            callbackGasLimit,
            1 						// `numWords` : number of random values we want
        );
        
        requestIdToRaffleId[requestId] = _raffleId;
        
        return requestId;
		//console.log("Request ID: ", s_requestId);
        // requestId looks like uint256:
        // 80023009725525451140349768621743705773526822376835636211719588211198618496446
	}
	
	
    // This is the callback that the VRF coordinator sends the random values to
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        // randomWords looks like this uint256:
        // 68187645017388103597074813724954069904348581739269924188458647203960383435815
		s_randomWords = _randomWords;
		
		uint256 _raffleId = requestIdToRaffleId[_requestId];
        
     	uint totalTicketsSold = idToAcceptedRaffle[_raffleId].maxTickets - idToAcceptedRaffle[_raffleId].ticketsLeft;
        uint256 random = _randomWords[0] % totalTicketsSold; // use modulo to choose a random index.
		
		_finishRaffle(_raffleId, random);
    }
	
	
	// The Raffle will end and the payment will send after receive a random number
	function _finishRaffle(uint256 _raffleId, uint256 _random) internal {
		require(idToAcceptedRaffle[_raffleId].ticketsLeft == 0 ||
				block.timestamp > idToAcceptedRaffle[_raffleId].startedAt + idToAcceptedRaffle[_raffleId].maxTimeActive, "Raffle still on going");
		
		uint256 ticketWinnerId = uint(keccak256(abi.encodePacked(_raffleId, _random)));
		
		_transferFromContract(
			tickets[ticketWinnerId].owner,
			idToAcceptedRaffle[_raffleId].assetType,
			idToAcceptedRaffle[_raffleId].assetContract,
			idToAcceptedRaffle[_raffleId].assetId
		);
				
		emit NewFinishedRaffle(
			_raffleId,
			tickets[ticketWinnerId].ticketId,
			tickets[ticketWinnerId].owner,
			idToAcceptedRaffle[_raffleId].assetType,
			idToAcceptedRaffle[_raffleId].assetId,
			idToAcceptedRaffle[_raffleId].assetContract,
			idToAcceptedRaffle[_raffleId].by	
		);
		
		uint totalTicketsSold = idToAcceptedRaffle[_raffleId].maxTickets - idToAcceptedRaffle[_raffleId].ticketsLeft;
		for (uint i = 0; i < totalTicketsSold; i++) {
			delete tickets[uint(keccak256(abi.encodePacked(_raffleId, i)))];
		}
		
		delete idToAcceptedRaffle[_raffleId];
	}
	
	
	// Set the Chainlink VRF subscription ID
	function setSubscriptionId(uint64 _subscriptionId) public {
		s_subscriptionId = _subscriptionId;
	}
	
	function setCallbackGasLimit(uint32 _callbackGasLimit) public {
		callbackGasLimit = _callbackGasLimit;
	}
	
	// Setters
	function setRaffleFee(uint _raffleFee) public { raffleFee = _raffleFee; }
	
	function setMaxTicketsPerRaffle(uint _maxTicketsPerRaffle) public {
		maxTicketsPerRaffle = _maxTicketsPerRaffle;
	}
	
	function setMaxTimeActive(uint _maxTimeActive) public { 
		maxTimeActive = _maxTimeActive;
	}
	
	function setProposalDeadline(uint _proposalDeadline) public { 
		proposalDeadline = _proposalDeadline;
	}
	
	
	// Transfer the asset to be raffle off to the contract
	function _transferToContract(address _from, assetType _type, address _assetContract, uint256 _assetId) internal {
		if (_type == assetType.ERC721) {
			IERC721(_assetContract)
				.safeTransferFrom(_from, address(this), _assetId);
    	} else if (_type == assetType.ERC1155) {
			IERC1155(_assetContract)
				.safeTransferFrom(_from, address(this), _assetId, 1, "");
    	}
	}
	
	
	// Transfer the asset from the contract to the winner or to the proposer
	function _transferFromContract(address _to, assetType _type, address _assetContract, uint256 _assetId) internal {
		if (_type == assetType.ERC721) {
			IERC721(_assetContract)
				.safeTransferFrom(address(this), _to, _assetId);
    	} else if (_type == assetType.ERC1155) {
			IERC1155(_assetContract)
				.safeTransferFrom(address(this), _to, _assetId, 1, "");
    	}		
	}
	
	
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
    
    	
	// Withdraw functions
	function withdraw() payable external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}
	
	function withdraw(uint amount) payable external onlyOwner {
		require(amount >= 0, "NegativeAmountError");
		payable(msg.sender).transfer(amount);
	}
}
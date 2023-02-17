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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

error Lottery__NotEnoughETHEnteredOrIncorrectEntries();
error Lottery__TransferFailed();
error Lottery__CallerIsNotAllowed();
error Lottery__NotOPEN();
error Lottery__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);
error Lottery__NFTReceived();
error Lottery__NothingToClaim();
error Lottery__NFTIsMissing();
error Lottery__NFTIsAlreadySet();
error Lottery__RateIsGreaterThanFour();
error Lottery__CallerIsNotTreasurer();
error Lottery__CallerIsNotRedeemer();
error Lottery__NotEnoughBonuses();

/** @title Lottery Contract
 *  @author @itsalexey
 *  @notice Decentralized NFT and ETH/BNB Lottery
 *  @dev Chainlink VRF v2 and Keepers for provable randomness
 *  Enter the lottery with set ticket price (multiple entries allowed)
 *  If >s_target tickets sold -> raffle the nft
 *  If <s_target tickets sold withing the interval -> award random winners
 *  chainlink -> vrf, keepers
 */

contract Lottery is Ownable, VRFConsumerBaseV2, AutomationCompatibleInterface, ERC721Holder {
    /* Types */
    enum LotteryState {
        OPEN,
        CALCULATING
    }

    mapping(address => uint256) balances;
    mapping(address => uint256) points;
    mapping(address => uint256) weight;

    struct NFTLoad {
        IERC721 s_nftRaffled;
        uint256 s_tokenId;
        uint256 s_target;
    }

    NFTLoad[] LoadedNFTs;

    /* State Variables */
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint256 private s_entranceFee;
    address[] private s_players;
    uint256 private s_feeBalance;
    uint256 private s_raffleBalance;
    uint256 private s_feePercent; //ex. 10%
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATIONS = 4;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;
    address private s_recentWinner;
    address private s_allowed;
    uint256 private s_interval; //ex. 60s
    uint256 private s_lastTimeStamp;
    LotteryState private s_lotteryState;
    uint256 private s_collectedFunds;
    bool s_NFTmode = true;
    uint256 private s_recentPayout;
    address private s_treasury;
    uint256 private s_rate; //ex. 1X
    address private s_redeemer;
    uint256 private s_treasuryBalance;

    /* Events */
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed recentWinner, string indexed mode, uint256 indexed chance);
    event Winnings(uint256 indexed w_tokenId, address indexed w_nftAddress, uint256 indexed w_eth);

    constructor(
        address vrfCoordinatorV2,
        uint256 entranceFee,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 feePercent,
        uint256 interval
    ) Ownable() VRFConsumerBaseV2(vrfCoordinatorV2) {
        s_entranceFee = entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_feePercent = feePercent;
        s_allowed = msg.sender;
        s_redeemer = msg.sender;
        s_treasury = msg.sender;
        s_interval = interval;
        s_lotteryState = LotteryState.OPEN;
        s_lastTimeStamp = block.timestamp;
        s_rate = 1;
    }

    /* Functions */

    function enterRaffle(uint256 entries) public payable {
        if ((msg.value < (s_entranceFee * entries)) || entries < 1) {
            revert Lottery__NotEnoughETHEnteredOrIncorrectEntries();
        }
        if (s_lotteryState != LotteryState.OPEN) {
            revert Lottery__NotOPEN();
        }
        s_collectedFunds += ((msg.value * (s_feePercent * 1e2)) / 1e4);
        s_raffleBalance += ((msg.value * (1e4 - (s_feePercent * 1e2))) / 1e4);
        for (uint256 i = 0; i < entries; i++) {
            s_players.push(msg.sender);
            points[msg.sender] += (msg.value / 1e16) * s_rate;
            weight[msg.sender] += 1;
            emit RaffleEnter(msg.sender);
        }
    }

    /** @dev Chainlink upkeep if:
     * 1. Time interval has passed OR
     * 2. Enough of participants
     * 3. Our subscription is funded with LINK
     * 4. Lottery is in the "open" state with at least 1 player
     */

    function checkUpkeep(
        bytes memory /* checkData */
    ) public view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool isOpen = (LotteryState.OPEN == s_lotteryState);
        bool timePassed = (((block.timestamp - s_lastTimeStamp) > s_interval) ||
            s_raffleBalance >= LoadedNFTs[LoadedNFTs.length - 1].s_target);
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = s_raffleBalance > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Lottery__UpkeepNotNeeded(
                s_raffleBalance,
                s_players.length,
                uint256(s_lotteryState)
            );
        }
        s_lotteryState = LotteryState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    }

    function detailsNFT(uint256 position) internal view returns (IERC721, uint256, uint256) {
        return (
            LoadedNFTs[position].s_nftRaffled,
            LoadedNFTs[position].s_tokenId,
            LoadedNFTs[position].s_target
        );
    }

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override {
        if (LoadedNFTs.length > 0) {
            (IERC721 nftRaffled, uint256 tokenId, uint256 target) = detailsNFT(
                LoadedNFTs.length - 1
            );
            if (
                (s_raffleBalance >= target && nftRaffled.balanceOf(address(this)) >= 1) &&
                s_NFTmode == true
            ) {
                uint256 indexOfWinner = randomWords[0] % s_players.length;
                address recentWinner = s_players[indexOfWinner];
                s_recentWinner = recentWinner;
                s_collectedFunds += s_raffleBalance;
                s_raffleBalance = 0;
                uint256 num = s_players.length;
                s_players = new address[](0);
                s_recentPayout = 0;
                nftRaffled.safeTransferFrom(address(this), recentWinner, tokenId);
                LoadedNFTs.pop();
                s_lotteryState = LotteryState.OPEN;
                s_lastTimeStamp = block.timestamp;
                emit WinnerPicked(recentWinner, "nft", (weight[recentWinner] * 1e2) / (num));
                emit Winnings(tokenId, address(nftRaffled), target);
                weight[recentWinner] = 0;
            } else {
                uint256 indexOfWinner = randomWords[0] % s_players.length;
                uint256 payout = (s_raffleBalance * 4) / 5;
                address recentWinner = s_players[indexOfWinner];
                s_recentWinner = recentWinner;
                s_recentPayout = payout;
                balances[s_players[indexOfWinner]] += payout;
                s_treasuryBalance += (s_raffleBalance - payout);
                s_raffleBalance = 0;
                uint256 num = s_players.length;
                s_players = new address[](0);
                s_lotteryState = LotteryState.OPEN;
                s_lastTimeStamp = block.timestamp;
                emit WinnerPicked(recentWinner, "ETH", (weight[recentWinner] * 1e2) / (num));
                emit Winnings(0, address(0), payout);
                weight[recentWinner] = 0;
            }
        } else {
            uint256 indexOfWinner = randomWords[0] % s_players.length;
            uint256 payout = (s_raffleBalance * 4) / 5;
            address recentWinner = s_players[indexOfWinner];
            s_recentWinner = recentWinner;
            s_recentPayout = payout;
            balances[s_players[indexOfWinner]] += payout;
            s_treasuryBalance += (s_raffleBalance - payout);
            s_raffleBalance = 0;
            uint256 num = s_players.length;
            s_players = new address[](0);
            s_lotteryState = LotteryState.OPEN;
            s_lastTimeStamp = block.timestamp;
            emit WinnerPicked(recentWinner, "ETH", (weight[recentWinner] * 1e2) / (num));
            emit Winnings(0, address(0), payout);
            weight[recentWinner] = 0;
        }
    }

    function claimWinnings() external {
        if (balances[msg.sender] <= 0) {
            revert Lottery__NothingToClaim();
        }
        uint256 claim = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: claim}("");
        if (!success) {
            revert Lottery__TransferFailed();
        }
    }

    function withdrawTreasury() external {
        if (msg.sender != s_treasury) {
            revert Lottery__CallerIsNotTreasurer();
        }
        uint256 value = s_treasuryBalance;
        s_treasuryBalance = 0;
        (bool success, ) = payable(s_treasury).call{value: value}("");
        if (!success) {
            revert Lottery__TransferFailed();
        }
    }

    function redeemBonuses(address player, uint256 amount) external {
        if (msg.sender != s_redeemer) {
            revert Lottery__CallerIsNotRedeemer();
        }
        if (points[player] < amount) {
            revert Lottery__NotEnoughBonuses();
        }
        points[player] -= amount;
    }

    function withdrawETH() external onlyOwner {
        uint256 value = s_collectedFunds;
        s_collectedFunds = 0;
        (bool success, ) = payable(msg.sender).call{value: value}("");
        if (!success) {
            revert Lottery__TransferFailed();
        }
    }

    function sendNFT(address nftAddress, uint256 tokenId, address to) external onlyOwner {
        //(IERC721 nftContract, uint256 tokenId, , uint256 index) = detailsNFT(position);
        IERC721 nftContract = IERC721(nftAddress);
        nftContract.safeTransferFrom(address(this), to, tokenId);
        deleteStruct(nftAddress, tokenId);
    }

    function recoverAllNFTs(address to) external onlyOwner {
        for (uint i = 0; i < LoadedNFTs.length; i++) {
            (IERC721 nftContract, uint256 tokenId, ) = detailsNFT(i);
            nftContract.safeTransferFrom(address(this), to, tokenId);
        }
        for (uint i = 0; i < LoadedNFTs.length + 1; i++) {
            LoadedNFTs.pop();
        }
    }

    function sendAnyNFT(address nftContract, address to, uint256 tokenId) external onlyOwner {
        IERC721(nftContract).safeTransferFrom(address(this), to, tokenId);
    }

    function deleteStruct(address nftAddress, uint256 tokenId) internal {
        NFTLoad memory removeMe;
        for (uint i = 0; i < LoadedNFTs.length; i++) {
            if (
                address(LoadedNFTs[i].s_nftRaffled) == nftAddress &&
                LoadedNFTs[i].s_tokenId == tokenId
            ) {
                removeMe = LoadedNFTs[i];
                LoadedNFTs[i] = LoadedNFTs[LoadedNFTs.length - 1];
                LoadedNFTs[LoadedNFTs.length - 1] = removeMe;
            }
        }
        LoadedNFTs.pop();
    }

    function refundALL() external onlyOwner {
        uint256 value = s_raffleBalance;
        s_raffleBalance = 0;
        (bool success, ) = payable(msg.sender).call{value: value}("");
        if (!success) {
            revert Lottery__TransferFailed();
        }
    }

    /* Setters */
    function setInterval(uint256 interval) external onlyOwner {
        s_interval = interval;
    }

    function setRedeemer(address redeemerAddress) external onlyOwner {
        s_redeemer = redeemerAddress;
    }

    function setTreasury(address treasuryAddress) external onlyOwner {
        s_treasury = treasuryAddress;
    }

    function setBonusRate(uint256 rate) external onlyOwner {
        if (rate > 4) {
            revert Lottery__RateIsGreaterThanFour();
        }
        s_rate = rate;
    }

    function NFTmodeON_OFF(bool value) external onlyOwner {
        s_NFTmode = value;
    }

    function setEntraceFee(uint256 entranceFee) external onlyOwner {
        s_entranceFee = entranceFee;
    }

    function setFeePercent(uint256 feePercent) external onlyOwner {
        s_feePercent = feePercent;
    }

    function setAllowedNFTWallet(address allowed) external onlyOwner {
        s_allowed = allowed;
    }

    function setNFTwithTarget(address nftContract, uint256 tokenId, uint256 target) external {
        if (msg.sender != s_allowed) {
            revert Lottery__CallerIsNotAllowed();
        }
        if (IERC721(nftContract).balanceOf(address(this)) < 1) {
            revert Lottery__NFTIsMissing();
        }
        NFTLoad memory nft;
        nft.s_nftRaffled = IERC721(nftContract);
        nft.s_tokenId = tokenId;
        nft.s_target = target;
        if ((LoadedNFTs.length >= 1) && LoadedNFTs[LoadedNFTs.length - 1].s_tokenId == tokenId) {
            revert Lottery__NFTIsAlreadySet();
        }
        LoadedNFTs.push(nft);
    }

    function resetNFT(
        address nftContract,
        uint256 tokenId,
        uint256 target,
        uint256 position
    ) external {
        if (msg.sender != s_allowed) {
            revert Lottery__CallerIsNotAllowed();
        }
        LoadedNFTs[position].s_nftRaffled = IERC721(nftContract);
        LoadedNFTs[position].s_tokenId = tokenId;
        LoadedNFTs[position].s_target = target;
    }

    function resetLotteryState() external onlyOwner {
        s_lotteryState = LotteryState.OPEN;
    }

    function closeLottery() external onlyOwner {
        s_lotteryState = LotteryState.CALCULATING;
    }

    /* View/Pure functions */
    function getRedeemer() public view returns (address) {
        return s_redeemer;
    }

    function getTreasury() public view returns (address) {
        return s_treasury;
    }

    function checkTreasuryBalance() public view returns (uint256) {
        return s_treasuryBalance;
    }

    function getBonusRate() public view returns (uint256) {
        return s_rate;
    }

    function checkBonusBalance(address wallet) public view returns (uint256) {
        return points[wallet];
    }

    function getNFTMode() public view returns (bool) {
        return s_NFTmode;
    }

    function getEntranceFee() public view returns (uint256) {
        return s_entranceFee;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getRaffleBalance() public view returns (uint256) {
        return s_raffleBalance;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getCurrentNFT() public view returns (address, uint256, uint256) {
        NFTLoad storage nft = LoadedNFTs[LoadedNFTs.length - 1];
        return (address(nft.s_nftRaffled), nft.s_tokenId, nft.s_target);
    }

    function getSpecificNFT(
        uint256 position
    ) public view returns (address, uint256, uint256, string memory) {
        return (
            address(LoadedNFTs[position].s_nftRaffled),
            LoadedNFTs[position].s_tokenId,
            LoadedNFTs[position].s_target,
            IERC721Metadata(address(LoadedNFTs[position].s_nftRaffled)).tokenURI(
                LoadedNFTs[position].s_tokenId
            )
        );
    }

    function getNFTAmount() public view returns (uint256) {
        return LoadedNFTs.length;
    }

    function getTarget() public view returns (uint256) {
        return LoadedNFTs[LoadedNFTs.length - 1].s_target;
    }

    function getLotteryState() public view returns (LotteryState) {
        return s_lotteryState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function getLatestTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getInterval() public view returns (uint256) {
        return s_interval;
    }

    function getVrfCoordinatorV2Address() public view returns (address) {
        return address(i_vrfCoordinator);
    }

    function getGasLane() public view returns (bytes32) {
        return i_gasLane;
    }

    function getCollectedFunds() public view returns (uint256) {
        return s_collectedFunds;
    }

    function getFeePercent() public view returns (uint256) {
        return s_feePercent;
    }

    function getPayout() public view returns (uint256) {
        return s_recentPayout;
    }

    function getBalances(address wallet) public view returns (uint256) {
        return balances[wallet];
    }
}
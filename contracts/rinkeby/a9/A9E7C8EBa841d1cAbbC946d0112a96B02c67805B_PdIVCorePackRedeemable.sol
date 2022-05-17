// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
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

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";

contract PdIVCorePackRedeemable is VRFConsumerBaseV2, Ownable {
    // Chainlink Parameters
    VRFCoordinatorV2Interface internal vrfCoordinator;
    uint64 internal subscriptionId;
    bytes32 internal keyHash;
    uint32 internal callbackGasLimit = 2000000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 1;

    // External addresses
    IERC1155 public parallelAuxiliaryItem =
        IERC1155(0x38398a2d7A4278b8d83967E0D235164335A0394A);
    address public routerContractAddress =
        0x38398a2d7A4278b8d83967E0D235164335A0394A;
    IERC1155 public parallelAlpha =
        IERC1155(0x76BE3b62873462d2142405439777e971754E8E77);

    address pullTokensFromAddress = 0x46365c0fb29B066e05800F4D060827D37B3608cA;
    address public pullParallelAuxiliaryItemFromAddress = address(0);
    uint256 public pdIVTokenId = 3;
    uint256 public primeKeyTokenId = 87; // mainnet: 87

    bool public receiveDisabled = false;
    uint256 public packPrice = 75000000000000000;

    uint16[] private availablePackIds;
    uint16[17470] private fullCardList;
    uint16 public CARDPACKSIZE = 10;

    struct Deposit {
        address owner;
        // a deposit has packs [0, numPacksToSendToUser)
        uint16 numPacksToSendToUser;
        bool assignedPacks;
    }

    mapping(uint256 => Deposit) public VRFRequestIDToDeposit;

    mapping(address => uint256) public PDIVClaimed;

    // A queue for each account of packs owed
    mapping(address => uint256[]) public assignedPackIDs;

    event Deposited(address owner, uint256 requestID);
    event PacksRedeemed(uint256 requestID, uint256[] packIDs, address owner);
    event Assigned(uint256 requestID, uint256 packID, address owner); // todo - remove this? it's not used
    event DepositRecovered(address owner, uint256 requestID);
    event Collected(
        address owner,
        uint256 pdIVTokenId,
        uint256 requestedPackCount
    );

    bytes32 public merkleRoot;

    constructor(
        uint64 _subscriptionId,
        address _coordinator,
        bytes32 _keyHash
    ) VRFConsumerBaseV2(_coordinator) {
        // Chainlink Addresses Doc: https://docs.chain.link/docs/vrf-contracts/#ethereum-mainnet
        // Ethereum Mainnet
        // VRF Coordinator 0x271682DEB8C4E0901D1a1550aD2e64D568E69909
        // Key Hash 200 GWei 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef
        // Key Hash 500 GWei 0xff8dedfbfa60af186cf3c830acbc32c05aae823045ae5ea7da1e45fbfaba4f92
        // Key Hash 1000 GWei 0x9fe0eebf5e446e3c998ec9bb19951541aee00bb90ea201ae456421a2ded86805
        // Rinkeby testnet
        // VRF Coordinator 0x6168499c0cFfCaCD319c818142124B7A15E857ab
        // Key Hash 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc
        vrfCoordinator = VRFCoordinatorV2Interface(_coordinator);
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPrimeKeyTokenId(uint256 _primeKeyTokenId) public onlyOwner {
        primeKeyTokenId = _primeKeyTokenId;
    }

    function setPullParallelAuxiliaryItemFromAddress(address _address)
        public
        onlyOwner
    {
        pullParallelAuxiliaryItemFromAddress = _address;
    }

    function setParallelAuxiliaryItem(IERC1155 _address) public onlyOwner {
        parallelAuxiliaryItem = _address;
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords() internal returns (uint256 requestID) {
        requestID = vrfCoordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function collect(
        address account,
        uint256 accountAmount,
        bytes32[] calldata merkleProof,
        uint256 requestedPackCount
    ) external payable {
        // Verify the merkle proof.
        bytes32 leaf = keccak256(
            abi.encodePacked(account, pdIVTokenId, accountAmount)
        );

        require(
            MerkleProof.verify(merkleProof, merkleRoot, leaf),
            "invalid proof"
        );

        // has not requested more then avalible assigned packs
        require(
            requestedPackCount + PDIVClaimed[account] <= accountAmount,
            "cannot claim more then assigned"
        );
        // update claimed amount
        PDIVClaimed[account] += requestedPackCount;

        // send nft
        uint256 expectedCost = requestedPackCount * packPrice;
        require(msg.value >= expectedCost, "Insufficient eth payment amount");
        parallelAuxiliaryItem.safeTransferFrom(
            pullParallelAuxiliaryItemFromAddress,
            account,
            pdIVTokenId,
            requestedPackCount,
            bytes("")
        );
        emit Collected(account, pdIVTokenId, requestedPackCount);
    }

    // Deposit hook
    function handleReceive(
        address _userAddress,
        address, /*_receiverAddress*/
        uint256, /*_type*/
        uint256, /*_id*/
        uint256, /*_ethValue*/
        uint256, /*_primeValue*/
        uint256[] memory _cardIds,
        uint256[] memory _cardQuantities,
        bytes memory /*_data*/
    ) public payable onlyParallelAuxiliaryItemsRouter {
        require(!receiveDisabled, "disabled");
        require(
            _cardIds.length == 1 && _cardQuantities.length == 1,
            "only send single nft type"
        );
        require(_cardIds[0] == 3, "needs PDIV pack reservation");
        uint256 numPacksToSendToUser = _cardQuantities[0];
        require(1 <= numPacksToSendToUser, "min 1 pack at a time");
        require(numPacksToSendToUser <= 10, "max 10 packs at a time");

        // Create deposit struct and store in mapping under VRF request ID
        Deposit memory newDeposit;
        newDeposit.owner = _userAddress;
        newDeposit.numPacksToSendToUser = uint16(numPacksToSendToUser);

        // Request VRF
        uint256 requestID = requestRandomWords();

        VRFRequestIDToDeposit[requestID] = newDeposit;
        emit Deposited(_userAddress, requestID);
    }

    // callback function hit from chainlink, we do pack assignment here such that user has no control over pack assignment
    function fulfillRandomWords(uint256 requestID, uint256[] memory randomWords)
        internal
        override
    {
        uint256 randomSeed = randomWords[0];

        Deposit memory deposit = VRFRequestIDToDeposit[requestID];
        require(deposit.owner != address(0), "cannot fulfil empty deposit");

        // We need to assign deposit.numPacksToSendToUser to the pack owner
        uint256 popIndex;
        uint256 packID;
        uint256[] memory _assignedPackIDs;

        uint256[] memory cardIdsToSend = new uint256[](
            CARDPACKSIZE * deposit.numPacksToSendToUser
        );
        uint256[] memory cardQuantitiesToSend = new uint256[](
            CARDPACKSIZE * deposit.numPacksToSendToUser
        );

        for (uint8 i = 0; i < deposit.numPacksToSendToUser; i++) {
            popIndex = getRandomIndex(randomSeed, i);
            packID = availablePackIds[popIndex];
            _assignedPackIDs[i] = packID;
            // Prevent pack from ever being assigned again
            remove(popIndex);

            // Add all the cards in card pack to batch transfer from
            for (uint8 j = 0; j < CARDPACKSIZE; j++) {
                cardIdsToSend[i * CARDPACKSIZE + j] = fullCardList[
                    packID * CARDPACKSIZE + j
                ];
                cardQuantitiesToSend[i * CARDPACKSIZE + j] = 1;
            }
        }

        parallelAlpha.safeBatchTransferFrom(
            pullTokensFromAddress,
            deposit.owner,
            cardIdsToSend,
            cardQuantitiesToSend,
            bytes("")
        );

        deposit.assignedPacks = true;
        emit PacksRedeemed(requestID, _assignedPackIDs, deposit.owner);
    }

    function getRandomIndex(uint256 randomSeed, uint256 packNumber)
        public
        view
        returns (uint256)
    {
        // hash(concat(randomSeed, packNumber)) gives us a random index for each pack
        uint256 n = uint256(
            keccak256(abi.encodePacked(randomSeed, packNumber))
        ) % availablePackIds.length;
        return n;
    }

    // we don't care about maintaining order, so just move the last item to the deletion index and pop the last
    function remove(uint256 index) internal {
        availablePackIds[index] = availablePackIds[availablePackIds.length - 1];
        availablePackIds.pop();
    }

    function initializeAvailablePackIds() public onlyOwner {
        require(availablePackIds.length == 0, "cant re-initialize");
        for (uint16 i = 0; i < 700; i++) {
            availablePackIds.push(i);
        }
    }

    function initializeAvailablePackIds2() public onlyOwner {
        require(availablePackIds.length == 700, "cant re-initialize 2");
        for (uint16 i = 700; i < 1220; i++) {
            availablePackIds.push(i);
        }
    }

    function setFullCardList(uint16[] memory _fullCardList, uint256 index)
        public
        onlyOwner
    {
        for (uint256 i = index; i < index + _fullCardList.length; i++) {
            fullCardList[i] = _fullCardList[i - index];
        }
    }

    function recoverRequestID(uint256 oldRequestID) external onlyOwner {
        Deposit memory oldDeposit = VRFRequestIDToDeposit[oldRequestID];
        require(
            !oldDeposit.assignedPacks,
            "deposit has already been assigned packs"
        );

        // fire off new one
        uint256 newRequestID = requestRandomWords();
        Deposit memory newDeposit;
        newDeposit.owner = oldDeposit.owner;
        newDeposit.numPacksToSendToUser = oldDeposit.numPacksToSendToUser;
        VRFRequestIDToDeposit[newRequestID] = newDeposit;

        // delete old deposit
        delete VRFRequestIDToDeposit[oldRequestID];

        // Emit new requestID
        emit DepositRecovered(newDeposit.owner, newRequestID);
    }

    modifier onlyParallelAuxiliaryItemsRouter() {
        require(
            msg.sender == routerContractAddress,
            "only callable by PAI router"
        );
        _;
    }

    function setParallelAlphaContractAddress(IERC1155 _newAddr)
        public
        onlyOwner
    {
        parallelAlpha = _newAddr;
    }

    function setRouterContractAddress(address _newAddr) public onlyOwner {
        routerContractAddress = _newAddr;
    }

    function setReceiveDisabled(bool _val) public onlyOwner {
        receiveDisabled = _val;
    }

    function setPullTokensFromAddress(address _address) public onlyOwner {
        pullTokensFromAddress = _address;
    }

    function setCorePrice(uint256 _val) public onlyOwner {
        packPrice = _val;
    }

    function setSubscriptionId(uint64 _subscriptionId) public onlyOwner {
        subscriptionId = _subscriptionId;
    }

    function setKeyHash(bytes32 _keyHash) public onlyOwner {
        keyHash = _keyHash;
    }

    function getLenAvailablePackIds() public view onlyOwner returns (uint256) {
        return availablePackIds.length;
    }

    function getAssignedPackIDs(address owner)
        external
        view
        returns (uint256[] memory)
    {
        return assignedPackIDs[owner];
    }
}
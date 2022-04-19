/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// File: @chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol


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

// File: @chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol


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

// File: @chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol


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

// File: @openzeppelin/[email protected]/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: @openzeppelin/[email protected]/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/[email protected]/utils/introspection/IERC165.sol


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

// File: @openzeppelin/[email protected]/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/[email protected]/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// File: @openzeppelin/[email protected]/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/[email protected]/utils/Context.sol


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

// File: @openzeppelin/[email protected]/access/Ownable.sol


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

// File: @openzeppelin/[email protected]/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/[email protected]/token/ERC721/ERC721.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: contracts/Ragnarok.sol



pragma solidity ^0.8.0;







interface ICollectibles {
    function burn(address account, uint256 id, uint256 value) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
}

interface IHeroes {
    function mintAdminSingle(address to, uint256 tokenType) external;
}

// ragnarok v3
contract Ragnarok is Ownable, ERC721, VRFConsumerBaseV2 {
    // Chainlink info
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;
    uint64 s_subscriptionId;
    
    // rinkeby - todo comment these
    address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
    address link = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
    bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;

    // // mainnet
    // address vrfCoordinator = 0x271682DEB8C4E0901D1a1550aD2e64D568E69909;
    // address link = 0x514910771af9ca656af840dff83e8264ecf986ca;
    // bytes32 keyHash = 0x9fe0eebf5e446e3c998ec9bb19951541aee00bb90ea201ae456421a2ded86805;

    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords =  1;
    uint256 public s_requestId;

    using Address for address;

    uint256 public totalSupply;
    bool public mintingLockedForAll;
    bool public mintingPaused = true;
    bool public presaleEnded;
    mapping (address => bool) public allowedToMint;
    event AllowedToMint(address indexed addr, bool value);

    uint256 public currentRound;
    uint256 public firstGameRound;
    mapping (uint256 => uint256) public gameSeeds;
    mapping (uint256 => mapping (uint256 => uint256)) public roundToWinners;
    
    /* Warrior information (faction, rarity, blessing usage) are stored as uint256 bitsets for read+write gas optimization. 
     * When the bit count doesn't exactly divide 256, we only store int(256/bitcount) elements in the uint256, so as not to split elements across multiple uints.
     * All of them stored as mappings for further gas optimization over arrays.
     *
     * Information details:
     *  - faction (per tokenId): 8 possible values - odin, thor, fenrir, hel, jormungand, loki, surtr, ymir
     *  - rarity (per tokenId): 4 possible values - common, uncommon, epic, legendary
     *  - blessing (perRound & per tokenId): 2 possible values - blessing not used, blessing used
     * 
     * Bitset implementations:
     *  - faction: 8 possible values - 3 bits per item - 85 items per uint256 - 49 uints necessary
     *  - rarity: 4 possible values - 2 bits per item - 128 items per uint256 - 32 uints necessary
     *  - blessing: 2 possible values - 1 bit per item - 256 items per uint256 - 16 uints necessary
     */
    mapping (uint256 => uint256) public factions;
    mapping (uint256 => uint256) public rarities;
    mapping (uint256 => mapping (uint256 => uint256)) public roundToBlessings;
    mapping (uint256 => bool) public blessingsLocked;
    bool public raritiesLocked;
    uint256 public raritiesGenerationHash;

    /* Further optimization - loading values from storage uses the SLOAD instruction which consumes a lot of gas on the first access per slot 
     * (2100gas for first access + 100gas for subsequent accesses for the same slot, since EIP-2929) 
     * This is bad for us since we need to access most of the storage slots for each round.
     *
     * The solution is to cache the necessary info into memory arrays (which is expensive due to memory allocation and takes about 300,000 gas)
     * and then capitalize on the cheap memory read ops
     */
    struct StorageClone {
        uint256[49] factions;
        uint256[32] rarities;
        uint256[16] blessings;
    }

    // round info struct to save up on local vars
    struct RoundInfo {
        uint256 token1;
        uint256 token2;
        uint256 temp;
        uint256 faction1;
        uint256 faction2;
        uint256 rand;
        uint256 score;
        uint256 round;
        uint256 permuteSeed;
        uint256 fightSeed;
    }

    // contract configs
    ICollectibles public collectiblesContract;
    IHeroes public heroesContract;

    uint256 public constant MAX_PER_FACTION = 512;
    uint256 public maxHeimdallPackages = 100;
    mapping (uint256 => uint256) public mintedByFaction;
    uint256 public mintedPackages;
    uint256 public price = 0.44 ether;

    bool public metadataLocked;
    string public baseURI;

    // --------------- CONSTRUCTOR --------------
    
    constructor(address collectiblesContractAddress, address heroesContractAddress, uint64 subscriptionId, string memory uri)
        ERC721("Ragnarok", "RROK") VRFConsumerBaseV2(vrfCoordinator)
    {
        collectiblesContract = ICollectibles(collectiblesContractAddress);
        heroesContract = IHeroes(heroesContractAddress);

        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(link);
        s_subscriptionId = subscriptionId;

        baseURI = uri;
    }

    // --------------- MINTING ----------------

    /**
     * @dev Set contract addresses for Collectibles (holds WL runes) and Heroes (holds Heimdalls)
     */
    function setContracts(address collectiblesContractAddress, address heroesContractAddress) external onlyOwner {
        collectiblesContract = ICollectibles(collectiblesContractAddress);
        heroesContract = IHeroes(heroesContractAddress);
    }

    /**
     * @dev Lock minting for owner and public
     */
    function lockMintingForeverForOwnerAndPublic(uint256 powerOfTwo) external onlyOwner {
        require(!mintingLockedForAll);
        require(totalSupply == 2**powerOfTwo);
        mintingLockedForAll = true;
    }

    /**
     * @dev Toggle pause minting temporarily
     */
    function togglePausePublicMinting() external onlyOwner {
        mintingPaused = !mintingPaused;
    }

    /**
     * @dev End presale and start sale
     */
    function endPresale() external onlyOwner {
        require(!presaleEnded);
        presaleEnded = true;
    }

    /**
     * @dev Set max Heimdall packages
     */
    function setMaxHeimdallPackages(uint256 value) external onlyOwner {
        maxHeimdallPackages = value;
    }

    /**
     * @dev Set price point per mint
     */
    function setPrice(uint256 value) external onlyOwner {
        price = value;
    }

    /**
     * @dev Mark address as allowed to mint
     */
    function setAllowedToMint(address addr, bool value) external onlyOwner {
        allowedToMint[addr] = value;
        emit AllowedToMint(addr, value);
    }

    /**
     * @dev Mint from faction (internal)
     */
    function mintInternal(address to, uint256 faction) internal {
        _mint(to, totalSupply);
        setFaction(totalSupply, faction);
        totalSupply++;
        mintedByFaction[faction]++;
    }

    /**
     * @dev Mint from faction (internal)
     */
    function mintPackageInternal(address to) internal {
        for (uint256 i = 0; i < 8; i++) {
            mintInternal(to, i);
        }
        mintedPackages++;
        heroesContract.mintAdminSingle(to, 0);
    }

    /**
     * @dev Public mint during sale
     */
    function mintOwner(address[] calldata mintAddresses, uint256[] calldata mintFactions) external onlyOwner {
        require(!mintingLockedForAll, "Minting is over");
        require(mintAddresses.length == mintFactions.length, "Bad lengths");
        
        for (uint256 i=0; i<mintAddresses.length; i++) {
            uint256 faction = mintFactions[i];

            require(0 <= faction && faction <= 8, "Unknown faction");

            if (faction == 8) {
                // Heimdall package minting
                mintPackageInternal(mintAddresses[i]);
            } else {
                // Regular warrior minting
                uint256 reservedForHeimdall = mintedPackages < maxHeimdallPackages ? (maxHeimdallPackages-mintedPackages) : 0;
                require(mintedByFaction[faction]+reservedForHeimdall+1 <= MAX_PER_FACTION, "Supply exceeded");

                mintInternal(msg.sender, faction);
            }
        }
    }

    /**
     * @dev Public mint during sale
     */
    function mintPublicSale(uint256 faction) public payable {
        require(0 <= faction && faction <= 8, "Unknown faction");
        require(!mintingLockedForAll, "Minting is over");
        require(!mintingPaused, "Minting paused");
        require(presaleEnded, "Public sale not activated");

        if (faction == 8) {
            // Heimdall package minting
            require(msg.value == 8*price, "Wrong ETH value");
            require(mintedPackages+1 <= maxHeimdallPackages, "Supply exceeded");

            mintPackageInternal(msg.sender);
        } else {
            // Regular warrior minting
            require(msg.value == price, "Wrong ETH value");
            
            uint256 reservedForHeimdall = mintedPackages < maxHeimdallPackages ? (maxHeimdallPackages-mintedPackages) : 0;
            require(mintedByFaction[faction]+reservedForHeimdall+1 <= MAX_PER_FACTION, "Supply exceeded");

            mintInternal(msg.sender, faction);
        }
    }

    /**
     * @dev Public mint during presale
     */
    function mintPublicPresale(uint256 faction) public payable {
        require(0 <= faction && faction <= 8, "Unknown faction");
        require(!mintingLockedForAll, "Minting is over");
        require(!mintingPaused, "Minting paused");
        require(!presaleEnded, "Presale ended");

        if (faction == 8) {
            // Heimdall package minting
            require(msg.value == 8*price, "Wrong ETH value");
            require(mintedPackages+1 <= maxHeimdallPackages, "Supply exceeded");

            mintPackageInternal(msg.sender);

            collectiblesContract.burn(msg.sender, 17, 1);
        } else {
            // Regular warrior minting
            require(msg.value == price, "Wrong ETH value");
            
            uint256 reservedForHeimdall = mintedPackages < maxHeimdallPackages ? (maxHeimdallPackages-mintedPackages) : 0;
            require(mintedByFaction[faction]+reservedForHeimdall+1 <= MAX_PER_FACTION, "Supply exceeded");

            mintInternal(msg.sender, faction);

            uint256 wlRune;
            if (faction == 0) {
                wlRune = 15;
            } else if (faction == 1) {
                wlRune = 1;
            } else if (faction == 2) {
                wlRune = 9;
            } else if (faction == 3) {
                wlRune = 7;
            } else if (faction == 4) {
                wlRune = 5;
            } else if (faction == 5) {
                wlRune = 3;
            } else if (faction == 6) {
                wlRune = 13;
            } else if (faction == 7) {
                wlRune = 11;
            }

            collectiblesContract.burn(msg.sender, wlRune, 1);
        }
    }

    /**
     * @dev Batch burn Collectible tokens
     */
    function batchBurnCollectibles(address[] calldata owners, uint256[] calldata ids) external onlyOwner {
        for (uint256 i = 0; i < owners.length; i++) { 
            collectiblesContract.burn(owners[i], ids[i], collectiblesContract.balanceOf(owners[i], ids[i]));
        }
    }

    /**
     * @dev Withdraw ether from this contract, callable by owner
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    // --------------- METADATA ---------------
    
    /**
     * @dev Sets base metadata URI, callable by owner
     */
    function setBaseUri(string memory _uri) external onlyOwner {
        require(metadataLocked == false);
        baseURI = _uri;
    }

    /**
     * @dev Lock metadata URI forever, callable by owner
     */
    function lockMetadata() external onlyOwner {
        require(metadataLocked == false);
        metadataLocked = true;
    }

    /**
     * @dev _baseURI override, called by tokenURI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // --------------- FACTIONS ----------------
    
    /**
     * @dev Set the faction of a token
     */
    function setFaction(uint256 tokenId, uint256 faction) internal {
        uint256 batch = tokenId / 85;
        uint256 offset = (tokenId % 85) * 3;
        factions[batch] |= faction << offset;
    }

    /**
     * @dev Get the faction of a token
     */
    function getFaction(uint256 tokenId) public view returns (uint256){
        uint256 batch = tokenId / 85;
        uint256 offset = (tokenId % 85) * 3;

        return (factions[batch] >> offset) & 7;
    }

    // --------------- BLESSINGS ----------------

    /**
     * @dev Set whether blessing has been used on a token in a specific round
     */
    function setBlessingsInBatch(uint256[] calldata values) external onlyOwner {
        require(currentRound+1 >= 2, "Round < 2");
        require(values.length == 16, "e12");
        require(!blessingsLocked[currentRound+1]);
        for (uint256 i=0; i < values.length; i++) {
            roundToBlessings[currentRound+1][i] = values[i];
        }
    }

    /**
     * @dev Get whether blessing has been used on a token in a specific round
     */
    function getBlessingInRound(uint256 tokenId, uint256 round) public view returns (bool) {
        uint256 batch = tokenId / 256;
        uint256 offset = tokenId % 256;

        return ((roundToBlessings[round][batch] >> offset) & 1) == 1;
    }

    /**
     * @dev Lock blessings for current round
     * Round parameter only used to confirm the action - must be equal to the current round
     */
    function lockBlessingsInRound(uint256 round) external onlyOwner {
        require(round == currentRound+1, "Invalid");
        require(!blessingsLocked[round]);
        blessingsLocked[round] = true;
    }

    // --------------- RARITIES ----------------
    
    /**
     * @dev Set rarity generation hash - callable only once
     */
    function setRaritiesHash(uint256 hash) external onlyOwner {
        require(raritiesGenerationHash == 0);
        raritiesGenerationHash = hash;
    }

    /**
     * @dev Set token rarities in batch
     */
    function setRaritiesInBatch(uint256[] calldata values) external onlyOwner {
        require(!raritiesLocked, "Locked");
        require(mintingLockedForAll, "Invalid");
        require(values.length == 32, "e12");
        for (uint256 i=0; i < values.length; i++) {
            rarities[i] = values[i];
        }
    }

    /**
     * @dev Get the rarity of a token
     */
    function getRarity(uint256 tokenId) public view returns (uint256){
        uint256 batch = tokenId / 128;
        uint256 offset = (tokenId % 128) * 2;

        return (rarities[batch] >> offset) & 3;
    }

    /**
     * @dev Lock rarities
     */
    function lockRarities() external onlyOwner {
        require(!raritiesLocked);
        raritiesLocked = true;
    }

    // --------------- PERMUTATIONS ----------------

    /**
     * @dev Permute index forward using seed
     */
    function randomPermuteFw(uint256 index, uint256 total, uint256 seed) public pure returns (uint256) {
        uint256 reverseThreshold;

        for (uint256 k = 1; k <= 2; k++) {
            reverseThreshold = ((seed >> (k * 24)) & 4095) % total;
            index = (index + ((seed >> (k * 24 + 12)) & 4095)) % total;

            if (index > reverseThreshold) {
                index = total - (index-reverseThreshold);
            }
        }

        return index;
    }

    /**
     * @dev Permute index backwards using seed
     */
    function randomPermuteBw(uint256 index, uint256 total, uint256 seed) public pure returns (uint256) {
        uint256 reverseThreshold;

        for (uint256 k = 2; k >= 1; k--) {
            reverseThreshold = ((seed >> (k * 24)) & 4095) % total;

            if (index > reverseThreshold) {
                index = total - (index-reverseThreshold);
            }

            index = (index + total - (((seed >> (k * 24 + 12)) & 4095) % total)) % total;
        }

        return index;
    }

    // --------------- ROUND VIEW ----------------

    /**
     * @dev Get index in next round from prev pos
     */
    function posToRoundMatchIndex(uint256 pos, uint256 round) public view returns (uint256) {
        require(gameSeeds[round-1] != 0, "e11");
        return randomPermuteFw(pos, 2**(13-round), gameSeeds[round-1]);
    }

    /**
     * @dev Get prev pos from index in next round
     */
    function roundMatchIndexToPrevPos(uint256 index, uint256 round) public view returns (uint256) {
        require(gameSeeds[round-1] != 0, "e11");
        return randomPermuteBw(index, 2**(13-round), gameSeeds[round-1]);
    }

    /**
     * @dev Get index of opponent
     */
    function getMatchupIndexOfIndex(uint256 index, uint256 round) public pure returns (uint256) {
        return (index+(2**(12-round)))%(2**(13-round));
    }

    /**
     * @dev Get total participants in round (only half will remain alive)
     */
    function getTotalParticipantsInRound(uint256 round) public pure returns (uint256) {
        return 2**(13-round);
    }

    /**
     * @dev Get fight result between two tokens (only valid if seed is in)
     */
    function getRoundResultBetweenTokens(uint256 round, uint256 token1, uint256 token2) public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(gameSeeds[round], token1, token2))) % 1000;
    }

    /**
     * @dev View odds for a given fight
     */
    function computeScore(uint256 index, uint256 round) public view returns (uint256) {
        RoundInfo memory rinfo;

        rinfo.round = round;
        require(rinfo.round > 0 && rinfo.round <= 12, "e10");

        (rinfo.token1, rinfo.token2) = getParticipantsInRoundAtIndex(round, index);

        uint[4] memory typeScores = [uint256(0), uint256(25), uint256(100), uint256(250)];

        rinfo.score = 500;

        rinfo.faction1 = (factions[rinfo.token1/85] >> ((rinfo.token1%85)*3)) & 7;
        rinfo.faction2 = (factions[rinfo.token2/85] >> ((rinfo.token2%85)*3)) & 7;

        if ((rinfo.faction2+1)%8==rinfo.faction1) {
            rinfo.score -= 50;
        }
        if ((rinfo.faction1+1)%8==rinfo.faction2) {
            rinfo.score += 50;
        }

        rinfo.score += typeScores[(rarities[rinfo.token1/128] >> ((rinfo.token1%128)*2)) & 3];
        rinfo.score -= typeScores[(rarities[rinfo.token2/128] >> ((rinfo.token2%128)*2)) & 3];
        
        if ((roundToBlessings[rinfo.round][rinfo.token1/256] >> (rinfo.token1%256)) & 1 == 1) {
            rinfo.score += 50;
        }
        if ((roundToBlessings[rinfo.round][rinfo.token2/256] >> (rinfo.token2%256)) & 1 == 1) {
            rinfo.score -= 50;
        }

        return rinfo.score;
    }

    /**
     * @dev Get the two tokens participating in a specific fight
     */
    function getParticipantsInRoundAtIndex(uint256 round, uint256 index) public view returns (uint256, uint256) {
        RoundInfo memory rinfo;

        rinfo.round = round;
        require(rinfo.round > 0 && rinfo.round <= 12, "e10");

        rinfo.permuteSeed = gameSeeds[rinfo.round-1];
        require(rinfo.permuteSeed != 0, "e9");

        uint[] memory ind1 = new uint[](1);
        uint[] memory ind2 = new uint[](1);

        ind1[0] = index;
        ind2[0] = (index+(2**(12-rinfo.round)))%(2**(13-rinfo.round));

        randomPermuteMemoryArraysBw(ind1, ind2, 2**(13-rinfo.round), rinfo.permuteSeed);

        if (rinfo.round == firstGameRound) {
            rinfo.token1 = ind1[0] < ind2[0] ? ind1[0] : ind2[0];
            rinfo.token2 = ind1[0] < ind2[0] ? ind2[0] : ind1[0];
        } else {
            rinfo.token1 = (roundToWinners[rinfo.round-1][ind1[0]/21] >> ((ind1[0]%21)*12)) & 4095;
            rinfo.token2 = (roundToWinners[rinfo.round-1][ind2[0]/21] >> ((ind2[0]%21)*12)) & 4095;
            if (rinfo.token1 > rinfo.token2) {
                rinfo.temp = rinfo.token1;
                rinfo.token1 = rinfo.token2;
                rinfo.token2 = rinfo.temp;
            }
        }

        return (rinfo.token1, rinfo.token2);
    }

    // --------------- ROUND PROCEDURE ----------------

    /** 
     * @dev Randomly permute two arrays of indexes (backwards)
     */
    function randomPermuteMemoryArraysBw(uint256[] memory indexes, uint256[] memory indexes2, uint256 total, uint256 seed) internal pure {
        uint256 reverseThreshold;

        for (uint256 k = 2; k >= 1; k--) {
            reverseThreshold = ((seed >> (k * 24)) & 4095) % total;

            for (uint256 i = 0; i < indexes.length; i++) {
                uint256 val = total - (((seed >> (k * 24 + 12)) & 4095) % total);

                if (indexes[i] > reverseThreshold) {
                    indexes[i] = total - (indexes[i]-reverseThreshold);
                }

                indexes[i] = (indexes[i] + val) % total;

                if (indexes2[i] > reverseThreshold) {
                    indexes2[i] = total - (indexes2[i]-reverseThreshold);
                }

                indexes2[i] = (indexes2[i] + val) % total;
            }
        }
    }

    /**
     * @dev Memoize winners of round for gas efficient access further down the line
     * fills from `from` to `to` (inclusive at both ends)
     */
    function fillRoundWinners(uint256 from, uint256 to, bool cloneMemory) public onlyOwner {
        RoundInfo memory rinfo;

        rinfo.round = currentRound;
        require(rinfo.round > 0 && rinfo.round <= 12, "e10");
        // require(to < 2**(12-rinfo.round) && ((to+1)%21 == 0 || to == 2**(12-rinfo.round)-1), "Invalid to");

        require(blessingsLocked[rinfo.round]);

        rinfo.permuteSeed = gameSeeds[rinfo.round-1];
        rinfo.fightSeed = gameSeeds[rinfo.round];
        require(rinfo.permuteSeed != 0 && rinfo.fightSeed != 0, "e9");

        uint[] memory ind1 = new uint[](to-from+1);
        uint[] memory ind2 = new uint[](to-from+1);
        uint[4] memory typeScores = [uint256(0), uint256(25), uint256(100), uint256(250)];

        for (uint256 i=from; i<=to; i++) {
            ind1[i-from] = i;
            ind2[i-from] = (i+(2**(12-rinfo.round)))%(2**(13-rinfo.round));
        }

        randomPermuteMemoryArraysBw(ind1, ind2, 2**(13-rinfo.round), rinfo.permuteSeed);

        if (cloneMemory) {
            uint[] memory cloneRoundToWinners;
            if (rinfo.round > firstGameRound) {
                cloneRoundToWinners = new uint[](((2**(13-rinfo.round))+20)/21); 
                for (uint256 i=0; i < cloneRoundToWinners.length; i++) {
                    cloneRoundToWinners[i] = roundToWinners[rinfo.round-1][i];
                }
            }

            StorageClone memory sclone;

            for (uint256 i=0; i < 49; i++) {
                sclone.factions[i] = factions[i];
            }
            for (uint256 i=0; i < 16; i++) {
                sclone.blessings[i] = roundToBlessings[rinfo.round][i];
            }
            for (uint256 i=0; i < 32; i++) {
                sclone.rarities[i] = rarities[i];
            }

            for (uint256 i=from; i <=to; i++) {
                if (rinfo.round == firstGameRound) {
                    rinfo.token1 = ind1[i-from] < ind2[i-from] ? ind1[i-from] : ind2[i-from];
                    rinfo.token2 = ind1[i-from] < ind2[i-from] ? ind2[i-from] : ind1[i-from];
                } else {
                    rinfo.token1 = (cloneRoundToWinners[ind1[i-from]/21] >> ((ind1[i-from]%21)*12)) & 4095;
                    rinfo.token2 = (cloneRoundToWinners[ind2[i-from]/21] >> ((ind2[i-from]%21)*12)) & 4095;
                    if (rinfo.token1 > rinfo.token2) {
                        rinfo.temp = rinfo.token1;
                        rinfo.token1 = rinfo.token2;
                        rinfo.token2 = rinfo.temp;
                    }
                }

                rinfo.score = 500;

                rinfo.faction1 = (sclone.factions[rinfo.token1/85] >> ((rinfo.token1%85)*3)) & 7;
                rinfo.faction2 = (sclone.factions[rinfo.token2/85] >> ((rinfo.token2%85)*3)) & 7;

                if ((rinfo.faction2+1)%8==rinfo.faction1) {
                    rinfo.score -= 50;
                }
                if ((rinfo.faction1+1)%8==rinfo.faction2) {
                    rinfo.score += 50;
                }

                rinfo.score += typeScores[(sclone.rarities[rinfo.token1/128] >> ((rinfo.token1%128)*2)) & 3];
                rinfo.score -= typeScores[(sclone.rarities[rinfo.token2/128] >> ((rinfo.token2%128)*2)) & 3];
                
                if ((sclone.blessings[rinfo.token1/256] >> (rinfo.token1%256)) & 1 == 1) {
                    rinfo.score += 50;
                }
                if ((sclone.blessings[rinfo.token2/256] >> (rinfo.token2%256)) & 1 == 1) {
                    rinfo.score -= 50;
                }

                rinfo.rand = uint256(keccak256(abi.encodePacked(rinfo.fightSeed, rinfo.token1, rinfo.token2))) % 1000;

                if (rinfo.rand < rinfo.score) {
                    roundToWinners[currentRound][i/21] |= rinfo.token1 << ((i%21)*12);
                } else {
                    roundToWinners[currentRound][i/21] |= rinfo.token2 << ((i%21)*12);
                }
                roundToWinners[currentRound][i/21] |= 1 << 255;
            }
        } else {
            for (uint256 i=from; i <=to; i++) {
                if (rinfo.round == firstGameRound) {
                    rinfo.token1 = ind1[i-from] < ind2[i-from] ? ind1[i-from] : ind2[i-from];
                    rinfo.token2 = ind1[i-from] < ind2[i-from] ? ind2[i-from] : ind1[i-from];
                } else {
                    rinfo.token1 = (roundToWinners[rinfo.round-1][ind1[i-from]/21] >> ((ind1[i-from]%21)*12)) & 4095;
                    rinfo.token2 = (roundToWinners[rinfo.round-1][ind2[i-from]/21] >> ((ind2[i-from]%21)*12)) & 4095;
                    if (rinfo.token1 > rinfo.token2) {
                        rinfo.temp = rinfo.token1;
                        rinfo.token1 = rinfo.token2;
                        rinfo.token2 = rinfo.temp;
                    }
                }

                rinfo.score = 500;

                rinfo.faction1 = (factions[rinfo.token1/85] >> ((rinfo.token1%85)*3)) & 7;
                rinfo.faction2 = (factions[rinfo.token2/85] >> ((rinfo.token2%85)*3)) & 7;

                if ((rinfo.faction2+1)%8==rinfo.faction1) {
                    rinfo.score -= 50;
                }
                if ((rinfo.faction1+1)%8==rinfo.faction2) {
                    rinfo.score += 50;
                }

                rinfo.score += typeScores[(rarities[rinfo.token1/128] >> ((rinfo.token1%128)*2)) & 3];
                rinfo.score -= typeScores[(rarities[rinfo.token2/128] >> ((rinfo.token2%128)*2)) & 3];
                
                if ((roundToBlessings[rinfo.round][rinfo.token1/256] >> (rinfo.token1%256)) & 1 == 1) {
                    rinfo.score += 50;
                }
                if ((roundToBlessings[rinfo.round][rinfo.token2/256] >> (rinfo.token2%256)) & 1 == 1) {
                    rinfo.score -= 50;
                }

                rinfo.rand = uint256(keccak256(abi.encodePacked(rinfo.fightSeed, rinfo.token1, rinfo.token2))) % 1000;

                if (rinfo.rand < rinfo.score) {
                    roundToWinners[currentRound][i/21] |= rinfo.token1 << ((i%21)*12);
                } else {
                    roundToWinners[currentRound][i/21] |= rinfo.token2 << ((i%21)*12);
                }
                roundToWinners[currentRound][i/21] |= 1 << 255;
            }
        }
    }

    /** 
     * @dev Check all winner batches have been filled
     */
    function checkFill() public view returns (bool) {
        uint256 totalIndexes = getTotalParticipantsInRound(currentRound)/2;
        for (uint256 t=0; t < (totalIndexes+20)/21; t++) {
            if (roundToWinners[currentRound][t] == 0) {
                return false;
            }
        }
        return true;
    }

    /** 
     * @dev Gets winning token at round and index
     */
    function getWinnerAtRound(uint256 round, uint256 i) public view returns (uint256) {
        uint256 batch = i / 21;
        uint256 offset = i % 21;

        return (roundToWinners[round][batch] >> (offset*12)) & 4095;
    }

    // --------------- ROUND TRIGGERING ----------------

    /** 
     * @dev Gets next fight seed
     */
    function advanceToRound(uint256 round) public onlyOwner {
        require(firstGameRound > 0, "e1");
        require(round == currentRound+1, "e2");
        require(currentRound < 13, "e3");
        require(gameSeeds[currentRound] != 0, "e4");
        require(blessingsLocked[currentRound+1], "e5");

        if (round > firstGameRound) {
            require(checkFill(), "e6");
        }
        
        currentRound = round;
        triggerChainlinkVRF();
    } 

    /** 
     * @dev Triggers first game round, potentially skipping first (round-1) rounds
     */
    function triggerFirstRound(uint256 round) public onlyOwner {
        require(round > 0, "e10");
        require(totalSupply == 2**(13-round), "Invalid supply");
        require(raritiesLocked && mintingLockedForAll, "e8");
        require(firstGameRound == 0, "e7");
        
        currentRound = round-1;
        firstGameRound = round;

        triggerChainlinkVRF();
    }

    // --------------- CHAINLINK ----------------

    /** 
     * @dev Trigger Chainlink VRF (random word is only stored the first time it arrives)
     */
    function triggerChainlinkVRF() public onlyOwner {
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    /** 
     * @dev Fulfill random words (called by Chainlink contract)
     */
    function fulfillRandomWords(
        uint256,
        uint256[] memory randomWords
    ) internal override {
        if (gameSeeds[currentRound] == 0) {
            gameSeeds[currentRound] = randomWords[0];
        }
    }

    /**
     * @dev Update Chainlink subscription id and gas lane
     */
    function updateChainlinkInfo(uint64 subscriptionId, bytes32 _keyHash) external onlyOwner {
        s_subscriptionId = subscriptionId;
        keyHash = _keyHash;
    }

    // // TODO REMOVE
    // function simulateVRFResponse(uint256 s) public onlyOwner {
    //     uint256[] memory randomWords = new uint256[](1);
    //     randomWords[0] = uint256(keccak256(abi.encodePacked(currentRound, s)));
    //     fulfillRandomWords(0, randomWords);
    // }
}
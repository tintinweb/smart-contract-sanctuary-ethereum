/**
 *Submitted for verification at Etherscan.io on 2023-05-23
*/

// File: @chainlink/contracts/src/v0.8/interfaces/VRFV2WrapperInterface.sol


pragma solidity ^0.8.0;

interface VRFV2WrapperInterface {
  /**
   * @return the request ID of the most recent VRF V2 request made by this wrapper. This should only
   * be relied option within the same transaction that the request was made.
   */
  function lastRequestId() external view returns (uint256);

  /**
   * @notice Calculates the price of a VRF request with the given callbackGasLimit at the current
   * @notice block.
   *
   * @dev This function relies on the transaction gas price which is not automatically set during
   * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   */
  function calculateRequestPrice(uint32 _callbackGasLimit) external view returns (uint256);

  /**
   * @notice Estimates the price of a VRF request with a specific gas limit and gas price.
   *
   * @dev This is a convenience function that can be called in simulation to better understand
   * @dev pricing.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _requestGasPriceWei is the gas price in wei used for the estimation.
   */
  function estimateRequestPrice(uint32 _callbackGasLimit, uint256 _requestGasPriceWei) external view returns (uint256);
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

// File: @chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol


pragma solidity ^0.8.0;



/** *******************************************************************************
 * @notice Interface for contracts using VRF randomness through the VRF V2 wrapper
 * ********************************************************************************
 * @dev PURPOSE
 *
 * @dev Create VRF V2 requests without the need for subscription management. Rather than creating
 * @dev and funding a VRF V2 subscription, a user can use this wrapper to create one off requests,
 * @dev paying up front rather than at fulfillment.
 *
 * @dev Since the price is determined using the gas price of the request transaction rather than
 * @dev the fulfillment transaction, the wrapper charges an additional premium on callback gas
 * @dev usage, in addition to some extra overhead costs associated with the VRFV2Wrapper contract.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFV2WrapperConsumerBase. The consumer must be funded
 * @dev with enough LINK to make the request, otherwise requests will revert. To request randomness,
 * @dev call the 'requestRandomness' function with the desired VRF parameters. This function handles
 * @dev paying for the request based on the current pricing.
 *
 * @dev Consumers must implement the fullfillRandomWords function, which will be called during
 * @dev fulfillment with the randomness result.
 */
abstract contract VRFV2WrapperConsumerBase {
  LinkTokenInterface internal immutable LINK;
  VRFV2WrapperInterface internal immutable VRF_V2_WRAPPER;

  /**
   * @param _link is the address of LinkToken
   * @param _vrfV2Wrapper is the address of the VRFV2Wrapper contract
   */
  constructor(address _link, address _vrfV2Wrapper) {
    LINK = LinkTokenInterface(_link);
    VRF_V2_WRAPPER = VRFV2WrapperInterface(_vrfV2Wrapper);
  }

  /**
   * @dev Requests randomness from the VRF V2 wrapper.
   *
   * @param _callbackGasLimit is the gas limit that should be used when calling the consumer's
   *        fulfillRandomWords function.
   * @param _requestConfirmations is the number of confirmations to wait before fulfilling the
   *        request. A higher number of confirmations increases security by reducing the likelihood
   *        that a chain re-org changes a published randomness outcome.
   * @param _numWords is the number of random words to request.
   *
   * @return requestId is the VRF V2 request ID of the newly created randomness request.
   */
  function requestRandomness(
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords
  ) internal returns (uint256 requestId) {
    LINK.transferAndCall(
      address(VRF_V2_WRAPPER),
      VRF_V2_WRAPPER.calculateRequestPrice(_callbackGasLimit),
      abi.encode(_callbackGasLimit, _requestConfirmations, _numWords)
    );
    return VRF_V2_WRAPPER.lastRequestId();
  }

  /**
   * @notice fulfillRandomWords handles the VRF V2 wrapper response. The consuming contract must
   * @notice implement it.
   *
   * @param _requestId is the VRF V2 request ID.
   * @param _randomWords is the randomness result.
   */
  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual;

  function rawFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external {
    require(msg.sender == address(VRF_V2_WRAPPER), "only VRF V2 wrapper can fulfill");
    fulfillRandomWords(_requestId, _randomWords);
  }
}

// File: @chainlink/contracts/src/v0.8/interfaces/OwnableInterface.sol


pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// File: @chainlink/contracts/src/v0.8/ConfirmedOwnerWithProposal.sol


pragma solidity ^0.8.0;


/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// File: @chainlink/contracts/src/v0.8/ConfirmedOwner.sol


pragma solidity ^0.8.0;


/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: contracts/Lottery/ILottery.sol

/*
Crafted with love by
Fueled on Bacon
https://fueledonbacon.com
*/


pragma solidity ^0.8.13;


interface ILottery {
    event BuyTicket(address buyer, uint256 amountTickets);
    event RaisedJackpot(uint256 amount);
    event Jackpot(address winner, uint256 amount);
    event Winner(address winner, uint256 amount);
    event RequestSent(uint256 requestId);
    event Claimed(address winner, uint256 weekNumber, uint256 prize);

    struct Prize {
        uint256 prize;
        uint256 jackpot;
        uint256 result;
        uint256 requestId;
        address winner; //0x1 if no winner, 0x0 if not yet executed
        bool claimed;
    }

    function buyTicket(uint256[] memory tNumbers) external;

    function buyTicketAdmin(uint256[] memory tNumbers) external;

    function execute() external;

    function getWeekNumber() external view returns (uint256);

    function claim(uint256 weekNumber) external;

    function withdrawSplitterBalance() external;

    function setSplitter(address splitter) external;

    function setPrice(uint256 price_) external;

    function setNFT(IERC721Enumerable nft) external;

    function togglePause() external;

    function withdrawLink() external;

    function addToJackpot(uint256 amount) external;

    function getPrize(uint256 weekNumber) external view returns(Prize memory);

    function getUserTickets(uint256 weekNumber, address account) external view returns(uint256[] memory);

    function getTicketsSoldByWeek(uint256 weekNumber) external view returns(uint256[] memory);

    function getTicketBuyer(uint256 weekNumber, uint256 ticketNumber) external view returns(address);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/Lottery/Lottery.sol

/*
Crafted with love by
Fueled on Bacon
https://fueledonbacon.com
*/
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;









contract Lottery is ILottery, VRFV2WrapperConsumerBase, Context, Ownable, ERC165, ReentrancyGuard {

    uint256 private constant POOL_PERCENTAGE = 70;
    address private constant NO_WINNER = 0x0000000000000000000000000000000000000001;

    address private immutable _linkToken;
    address private immutable _vrfWrapper;

    address private _splitter;

    uint256 public constant LOTTERY_LENGTH =3 days;// 1 weeks;
    uint256 internal immutable _startTime;

    uint8 public state; // 1 = paused
    uint32 private _callbackGasLimit = 150000;

    uint256 public price;
    uint256 public jackpot;
    uint256 public lastExecutedWeek;
    uint256 public splitterBalance;

    bool isExecuting;

    IERC721Enumerable private _nft;
    IERC20 private _paymentToken;

    mapping(uint256 => Prize) public prizePerWeek;

    //in the form of weekNumber => (userAddress => tickets)
    mapping(uint256 => mapping(address => uint256[])) public ticketsUserByWeek;

    //in the form of weekNumber => (ticketNumber => userAddress)
    mapping(uint256 => mapping(uint256 => address)) public userTicketOwnerByWeek;

    //in the form of weekNumber => amountOfTicketsSold
    mapping(uint256 => uint256[]) ticketsSoldByWeek;

    mapping(uint256 => uint256) vrfRequestByWeek;
    mapping(uint256 => uint256) weekByVrfRequest;

    constructor(
        uint256 startTime_, 
        uint256 price_, 
        IERC721Enumerable nft, 
        IERC20 paymentToken,
        address linkToken,
        address vrfWrapper,
        address splitter
    ) VRFV2WrapperConsumerBase(linkToken, vrfWrapper) {
        require(startTime_ > block.timestamp, "Invalid start time");
        require(price_ > 0, "Price is 0");
        require(address(nft) != address(0), "NFT address 0x0");
        require(address(paymentToken) != address(0), "Payment token address 0x0");
        _startTime = startTime_;
        _paymentToken = paymentToken;
        _nft = nft;
        price = price_;
        _linkToken = linkToken;
        _vrfWrapper = vrfWrapper;
        _splitter = splitter;
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns(bool) {
         return interfaceId == type(ILottery).interfaceId;
    }


    ///@dev lottery number starts from 0 to nft.totalSupply()
    function buyTicket(uint256[] memory tNumbers) external override {
        require(state == 0, "Lottery is paused");
        uint256 amount = tNumbers.length;
        require(amount > 0, "Cannot buy 0 tickets");
        uint256 currentWeek = getWeekNumber();

        address buyer = _msgSender();
        require(_nft.balanceOf(buyer) > 0, "Not NFT Owner");
        uint256 totalPrice = price*amount;
        _paymentToken.transferFrom(buyer, address(this), totalPrice);
        
        prizePerWeek[currentWeek].prize += totalPrice*POOL_PERCENTAGE/100;
        splitterBalance +=  totalPrice*(100-POOL_PERCENTAGE)/100;
        _saveTickets(currentWeek, tNumbers, buyer);
        emit BuyTicket(buyer, amount);
    }

    function buyTicketAdmin(uint256[] memory tNumbers) external override onlyOwner {
        require(state == 0, "Lottery is paused");
        uint256 amount = tNumbers.length;
        require(amount > 0, "Cannot buy 0 tickets");
        uint256 currentWeek = getWeekNumber();

        address buyer = _msgSender();
        require(_nft.balanceOf(buyer) > 0, "Not NFT Owner");
        uint256 totalPrice = price*amount;
        //_paymentToken.transferFrom(buyer, address(this), totalPrice);
        
        prizePerWeek[currentWeek].prize += totalPrice*POOL_PERCENTAGE/100;
        splitterBalance +=  totalPrice*(100-POOL_PERCENTAGE)/100;
        _saveTickets(currentWeek, tNumbers, buyer);
        emit BuyTicket(buyer, amount);
    }

    function execute() public override {
        require(!isExecuting, "Executing lottery");
        isExecuting = true;
        uint256 weekNumber = getWeekNumber();
        uint256 weekToExecute = lastExecutedWeek + 1;
        require(weekNumber > weekToExecute, "All weeks already executed");
        _execute(weekToExecute);
    }

    function _execute(uint256 weekNumber) internal {
        Prize storage prize = prizePerWeek[weekNumber];
        if(prize.prize > 0 && prize.winner == address(0) && vrfRequestByWeek[weekNumber] == 0) {
            uint256 requestId = _requestRandomWords();
            vrfRequestByWeek[weekNumber] = requestId;
            weekByVrfRequest[requestId] = weekNumber;
            prize.requestId = requestId;
        } else {
            lastExecutedWeek = weekNumber;
            isExecuting = false;
            uint256 nextWeek = weekNumber + 1;
            if(getWeekNumber() > nextWeek) {
                execute();
            }
        }
    }

    function getWeekNumber() public virtual override view returns(uint256) {
        uint256 timestamp = block.timestamp;
        require(_startTime < timestamp, "Not yet started");
        uint256 weekNumber = (timestamp - _startTime) / LOTTERY_LENGTH;
        return weekNumber + 1;
    }

    function _requestRandomWords() internal virtual returns (uint256 requestId) {
        requestId = requestRandomness(_callbackGasLimit, 3, 1);
        emit RequestSent(requestId);
    }

    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual override {
        uint256 weekNumber = weekByVrfRequest[_requestId];
        lastExecutedWeek = weekNumber;

        //uint256 rndNumber = _randomWords[0] % (_nft.totalSupply()-1);
        uint256 rndNumber = _randomWords[0] % (_nft.totalSupply()-1);
        address winner = getTicketBuyer(weekNumber, rndNumber);
        Prize memory prize = prizePerWeek[weekNumber];
        prize.result = rndNumber;

        if(winner == address(0)) {
            prize.winner = NO_WINNER;
            jackpot += prize.prize;
            emit RaisedJackpot(jackpot);
        } else {
            prize.winner = winner;
            if(jackpot > 0) {
                prize.jackpot = jackpot;
                jackpot = 0;
                emit Jackpot(winner, jackpot);
            }
            emit Winner(winner, prize.prize);
        }
        prizePerWeek[weekNumber] = prize;
        isExecuting = false;
    }

    function claim(uint256 weekNumber) external override nonReentrant {
        Prize storage prize = prizePerWeek[weekNumber];
        require(!prize.claimed, "Prize already claimed");
        address winner = prize.winner;
        require(winner != address(0), "Lotery not yet executed");
        require(winner != NO_WINNER, "Lottery not won");
        require(_msgSender() == winner, "You are not lottery winner");
        prize.claimed = true;
        uint256 total = prize.prize + prize.jackpot;
        _paymentToken.transfer(winner, total);
        emit Claimed(winner, weekNumber, total);
    }
    

    ///@dev only accept tickets from 0 to nft.totalSupply() - 1
    function _saveTickets(uint256 currentWeek, uint256[] memory tNumbers, address buyer) internal {
        for(uint256 i; i < tNumbers.length; i++){
            uint256 tNumber = tNumbers[i];
            //require(tNumber < _nft.totalSupply(), "Ticket number out of bounds");
            require(tNumber <= _nft.totalSupply(), "Ticket number out of bounds");
            require(userTicketOwnerByWeek[currentWeek][tNumber] == address(0), "Ticket number already used");
            userTicketOwnerByWeek[currentWeek][tNumber] = buyer;
            ticketsUserByWeek[currentWeek][buyer].push(tNumber);
            ticketsSoldByWeek[currentWeek].push(tNumber);
        }
    }

    //Setters
    function withdrawSplitterBalance() external override nonReentrant {
        _paymentToken.transfer(_splitter, splitterBalance);
        splitterBalance;
    }

    function setSplitter(address splitter) external override onlyOwner {
        require(splitter != address(0), "Wrong splitter");
        _splitter = splitter;
    }

    function setPrice(uint256 price_) external override onlyOwner {
        require(price_ > 0, "Price is 0");
        price = price_;
    }

    function setNFT(IERC721Enumerable nft) external override onlyOwner {
        require(address(nft) != address(0), "NFT address 0x0");
        _nft = nft;
    }

    function togglePause() external override onlyOwner {
        if(state == 0) state = 1;
        else state = 0;
    }

    function withdrawLink() external override onlyOwner {
        IERC20 linkToken = IERC20(_linkToken);
        linkToken.transfer(_msgSender(), linkToken.balanceOf(address(this)));
    }

    function addToJackpot(uint256 amount) external override {
        _paymentToken.transferFrom(_msgSender(), address(this), amount);
        jackpot += amount;
        emit RaisedJackpot(jackpot);
    }

    //Getters

    function getPrize(uint256 weekNumber) external view override returns(Prize memory) {
        return prizePerWeek[weekNumber];
    }

    function getUserTickets(uint256 weekNumber, address account) external override view returns(uint256[] memory) {
        return ticketsUserByWeek[weekNumber][account];
    }

    function getTicketsSoldByWeek(uint256 weekNumber) external override view returns(uint256[] memory) {
        return ticketsSoldByWeek[weekNumber];
    }

    function getTicketBuyer(uint256 weekNumber, uint256 ticketNumber) public override view returns(address) {
        return userTicketOwnerByWeek[weekNumber][ticketNumber];
    }
}
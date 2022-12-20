// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721A.sol';

/**
 * @dev Interface of ERC721AQueryable.
 */
interface IERC721AQueryable is IERC721A {
    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *
     * - `addr = address(0)`
     * - `startTimestamp = 0`
     * - `burned = false`
     * - `extraData = 0`
     *
     * If the `tokenId` is burned:
     *
     * - `addr = <Address of owner before token was burned>`
     * - `startTimestamp = <Timestamp when token was burned>`
     * - `burned = true`
     * - `extraData = <Extra data when token was burned>`
     *
     * Otherwise:
     *
     * - `addr = <Address of owner>`
     * - `startTimestamp = <Timestamp of start of ownership>`
     * - `burned = false`
     * - `extraData = <Extra data at start of ownership>`
     */
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start < stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
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

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IFewl is IERC20 {

    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;


interface IMetaFlyers {

    // store lock meta data
    struct Locked {
        uint64 tokenId;
        uint64 lockTimestamp;
        uint128 claimedAmount;
    }
    
    function totalMinted() external returns (uint16);
    function totalLocked() external returns (uint16);
    function getLock(uint256 tokenId) external view returns (Locked memory);
    function isLocked(uint256 tokenId) external view returns(bool);
    
    function mint(address recipient, uint16 qty) external; // onlyAdmin
    function burn(uint256 tokenId) external; // onlyAdmin
    function lock( uint256 tokenId, address user) external; // onlyAdmin
    function unlock(uint256 tokenId, address user) external; // onlyAdmin
    function refreshLock(uint256 tokenId, uint256 amount) external; // onlyAdmin
    
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../lib/erc721a/contracts/extensions/IERC721AQueryable.sol";
import "./interfaces/IMetaFlyers.sol";
import "./interfaces/IFewl.sol";


contract mfMain is Ownable, Pausable, ReentrancyGuard {

    // CONTRACTS 
    IFewl public fewlContract;
    IMetaFlyers public mfContract;

    constructor(address _mfContract, address _fewlContract){
        mfContract = IMetaFlyers(_mfContract);
        fewlContract = IFewl(_fewlContract);
        _pause();
    }    

    // EVENTS 
    event MetaFlyersMinted(address indexed owner, uint16[] tokenIds);
    event MetaFlyersLocked(address indexed owner, uint256[] tokenIds);
    event MetaFlyersClaimed(address indexed owner, uint256[] tokenIds);

    // ERRORS
    error InvalidAmount();
    error InvalidOwner();
    error MintingNotActive();
    error LockingInactive();
    error NotWhitelisted();
    error MaxAllowedPreSaleMints();    
    error MaxAllowedPublicSaleMints();

    // PUBLIC VARS 
    uint256 public MINT_PRICE = 0.047 ether;
    uint256 public DAILY_BASE_FEWL_RATE = 5 ether;
    uint256 public DAILY_TIER1_FEWL_RATE = 10 ether;
    uint256 public DAILY_TIER2_FEWL_RATE = 20 ether;
    uint256 public BONUS_FEWL_AMOUNT = 200 ether;

    // Time that must pass before a Locked Nft can receive bonus FEWL amount
    uint256 public MINIMUM_DAYS_TO_BONUS = 14 days;       

    bool public PRE_SALE_STARTED;
    bool public PUBLIC_SALE_STARTED;
    bool public LOCKING_STARTED;
    bool public TIER_EMISSIONS_STARTED;

    uint16 public MAX_PRE_SALE_MINTS = 5;   
    uint16 public MAX_PUBLIC_SALE_MINTS = 10;

    address public withdrawAddress;
    

    // PRIVATE VARS 
    mapping(address => bool) private _admins;
    mapping(address => uint8) private _publicSaleMints;
    mapping(uint256 => bool) private _tier1Tokens;
    mapping(uint256 => bool) private _tier2Tokens;
    mapping(address => bool) private _preSaleAddresses;
    mapping(address => uint8) private _preSaleMints;


    function mint(uint8 amount, bool lock) external payable whenNotPaused nonReentrant {
        if(!PRE_SALE_STARTED && !PUBLIC_SALE_STARTED) revert MintingNotActive();

        if (PRE_SALE_STARTED) {
            if(!_preSaleAddresses[_msgSender()]) revert NotWhitelisted();
            if(_preSaleMints[_msgSender()] + amount > MAX_PRE_SALE_MINTS) revert MaxAllowedPreSaleMints();
        } else {
            if(_publicSaleMints[_msgSender()] + amount > MAX_PUBLIC_SALE_MINTS) revert MaxAllowedPublicSaleMints();
        }
        //check for adequate value sent
        if (PRE_SALE_STARTED && _preSaleMints[_msgSender()] == 0){
            if(msg.value < (amount - 1) * MINT_PRICE) revert InvalidAmount();
        }
        else if(msg.value < amount * MINT_PRICE) revert InvalidAmount();
        

        if (PRE_SALE_STARTED) _preSaleMints[_msgSender()] += amount;
        else _publicSaleMints[_msgSender()] += amount;

        mfContract.mint(_msgSender(), amount);

        if(lock){
           uint256[] memory tokens = IERC721AQueryable(address(mfContract)).tokensOfOwner(_msgSender());
           for(uint16 i = 0; i < tokens.length; i++) {
            if(!mfContract.isLocked(tokens[i])){
                 mfContract.lock(tokens[i], _msgSender());
            }
           }
        }
    }

    function lockMetaFlyers(uint256[] memory tokenIds) external whenNotPaused nonReentrant {
        if(!LOCKING_STARTED) revert LockingInactive();

        for(uint16 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            
            if(IERC721AQueryable(address(mfContract)).ownerOf(tokenId) != _msgSender()) revert InvalidOwner();
            // lock MetaFlyer
            //reverts if nft is already locked
            mfContract.lock(tokenId, _msgSender());
        }

        emit MetaFlyersLocked(_msgSender(), tokenIds);
    }

    function claimMetaFlyers(uint256[] memory tokenIds, bool unlock) public whenNotPaused nonReentrant {
        uint256 stakingRewards;
        uint256 mintAmount;
        for(uint16 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if(IERC721AQueryable(address(mfContract)).ownerOf(tokenId) != _msgSender()) revert InvalidOwner();

            // pay out rewards
            stakingRewards = calculateLockingRewards(tokenId);
            mintAmount += stakingRewards;
            // unlock if the owner wishes to
            if (unlock) mfContract.unlock(tokenId, _msgSender());
            else mfContract.refreshLock(tokenId, stakingRewards);            
        }

        //mint claimed amount
        fewlContract.mint(_msgSender(), mintAmount);        

        emit MetaFlyersClaimed(_msgSender(), tokenIds);
    }

    function calculateAllLockingRewards(uint256[] memory tokenIds) public view returns(uint256 rewards) {
        for(uint16 i = 0; i < tokenIds.length; i++) {
            rewards += calculateLockingRewards(tokenIds[i]);
        }
    }

    function calculateLockingRewards(uint256 tokenId) public view returns(uint256 rewards) {
        //reverts if not locked
        IMetaFlyers.Locked memory myStake = mfContract.getLock(tokenId);
        uint256 lockDuration = block.timestamp - myStake.lockTimestamp;
        uint256 fewlRate = DAILY_BASE_FEWL_RATE;
        
        //calculate proper bonus rewards based on time locked
        rewards = lockDuration / MINIMUM_DAYS_TO_BONUS * BONUS_FEWL_AMOUNT;        

        //calculate tier emission rate
        if(TIER_EMISSIONS_STARTED){
            if(_tier1Tokens[tokenId]) fewlRate = DAILY_TIER1_FEWL_RATE;                
            if(_tier2Tokens[tokenId]) fewlRate = DAILY_TIER2_FEWL_RATE;                      
        } 

        //if tier emissions have not started all nfts get base rate
        rewards += lockDuration * fewlRate / 1 days;        

        if(rewards > myStake.claimedAmount){
            rewards -= myStake.claimedAmount;
        } else rewards = 0;               
        
    }

    function getPreSaleAddress(address user) external view returns (bool){
        return _preSaleAddresses[user];
    }

    function getPreSaleMints(address user) external view returns (uint256) {
        return _preSaleMints[user];
    }

    function getPublicSaleSaleMints(address user) external view returns (uint256) {
        return _publicSaleMints[user];
    }

    // OWNER ONLY FUNCTIONS 
    function setContracts(address _mfContract, address _fewlContract) external onlyOwner {
        mfContract = IMetaFlyers(_mfContract);
        fewlContract = IFewl(_fewlContract);
    }

    function mintForTeam(address receiver, uint16 amount) external whenNotPaused onlyOwner {        
        mfContract.mint(receiver, amount);        
    }

    function addToPresale(address[] memory addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            _preSaleAddresses[addresses[i]] = true;
        }
    }

    function withdraw() external {
        require(withdrawAddress != address(0x00), "Withdraw address not set");
        require(_msgSender() == withdrawAddress, "Withdraw address only");
        uint256 totalAmount = address(this).balance;
        bool sent;

        (sent, ) = withdrawAddress.call{value: totalAmount}("");
        require(sent, "Main: Failed to send funds");

    }

    function setWithdrawAddress(address addr) external onlyOwner {
        withdrawAddress = addr;
    }

    function setPreSaleStarted(bool started) external onlyOwner {
        PRE_SALE_STARTED = started;
        if (PRE_SALE_STARTED) PUBLIC_SALE_STARTED = false;
    }

    function setPublicSaleStarted(bool started) external onlyOwner {
        PUBLIC_SALE_STARTED = started;
        if (PUBLIC_SALE_STARTED) PRE_SALE_STARTED = false;
    }

    function setLockingStarted(bool started) external onlyOwner {
        LOCKING_STARTED = started;
    }

    function setTierEmissionStarted(bool started) external onlyOwner {
        TIER_EMISSIONS_STARTED = started;
    }

    function setMintPrice(uint256 number) external onlyOwner {
        MINT_PRICE = number;
    }

    function setMaxPublicSaleMints(uint16 number) external onlyOwner {
        MAX_PUBLIC_SALE_MINTS = number;
    }

    function setMaxPreSaleMints(uint16 number) external onlyOwner {
        MAX_PRE_SALE_MINTS = number;
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    function setDailyBaseFewlRate(uint256 number) external onlyOwner {
        DAILY_BASE_FEWL_RATE = number;
    }

    function setDailyTier1FewlRate(uint256 number) external onlyOwner {
        DAILY_TIER1_FEWL_RATE = number;
    }

    function setDailyTier2FewlRate(uint256 number) external onlyOwner {
        DAILY_TIER2_FEWL_RATE = number;
    }

    //Base = Tier 0, Agents= Tier 1, 1/1= Tier2
    function addTokensToTier(uint256[] memory tokenIds, uint8 tier) external onlyOwner {
        require(tier==1 || tier==2, "Tier must be 1 or 2");
        for (uint i = 0; i < tokenIds.length; i++) {
            if (tier==1) _tier1Tokens[tokenIds[i]] = true;
                else _tier2Tokens[tokenIds[i]] = true;
        }
    }

    function setBonusFewlAmount(uint256 amount) external onlyOwner {
        BONUS_FEWL_AMOUNT = amount;
    }

    function setMinimumDaysToBonus(uint256 number) external onlyOwner {
        MINIMUM_DAYS_TO_BONUS = number;
    }

}
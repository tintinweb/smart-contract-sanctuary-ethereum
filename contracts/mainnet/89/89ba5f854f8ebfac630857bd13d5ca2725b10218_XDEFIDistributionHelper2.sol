/**
 *Submitted for verification at Etherscan.io on 2022-12-13
*/

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


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

// File: contracts/interfaces/IXDEFIDistribution.sol



pragma solidity =0.8.12;


interface IXDEFIDistribution is IERC721Enumerable {
    /***********/
    /* Structs */
    /***********/

    struct Position {
        uint96 units; // 240,000,000,000,000,000,000,000,000 XDEFI * 2.55x bonus (which fits in a `uint96`).
        uint88 depositedXDEFI; // XDEFI cap is 240000000000000000000000000 (which fits in a `uint88`).
        uint32 expiry; // block timestamps for the next 50 years (which fits in a `uint32`).
        uint32 created;
        uint256 pointsCorrection;
    }

    /**********/
    /* Errors */
    /**********/

    error BeyondConsumeLimit();
    error CannotUnlock();
    error ConsumePermitExpired();
    error EmptyArray();
    error IncorrectBonusMultiplier();
    error InsufficientAmountUnlocked();
    error InsufficientCredits();
    error InvalidConsumePermit();
    error InvalidDuration();
    error InvalidMultiplier();
    error InvalidToken();
    error LockingIsDisabled();
    error LockResultsInTooFewUnits();
    error MustMergeMultiple();
    error NoReentering();
    error NoUnitSupply();
    error NotApprovedOrOwnerOfToken();
    error NotInEmergencyMode();
    error PositionAlreadyUnlocked();
    error PositionStillLocked();
    error TokenDoesNotExist();
    error Unauthorized();

    /**********/
    /* Events */
    /**********/

    /// @notice Emitted when the base URI is set (or re-set).
    event BaseURISet(string baseURI);

    /// @notice Emitted when some credits of a token are consumed.
    event CreditsConsumed(uint256 indexed tokenId, address indexed consumer, uint256 amount);

    /// @notice Emitted when a new amount of XDEFI is distributed to all locked positions, by some caller.
    event DistributionUpdated(address indexed caller, uint256 amount);

    /// @notice Emitted when the contract is no longer allowing locking XDEFI, and is allowing all locked positions to be unlocked effective immediately.
    event EmergencyModeActivated();

    /// @notice Emitted when a new lock period duration, in seconds, has been enabled with some bonus multiplier (scaled by 100, 0 signaling it is disabled).
    event LockPeriodSet(uint256 indexed duration, uint256 indexed bonusMultiplier);

    /// @notice Emitted when a new locked position is created for some amount of XDEFI, and the NFT is minted to an owner.
    event LockPositionCreated(uint256 indexed tokenId, address indexed owner, uint256 amount, uint256 indexed duration);

    /// @notice Emitted when a locked position is unlocked, withdrawing some amount of XDEFI.
    event LockPositionWithdrawn(uint256 indexed tokenId, address indexed owner, uint256 amount);

    /// @notice Emitted when an account has accepted ownership.
    event OwnershipAccepted(address indexed previousOwner, address indexed owner);

    /// @notice Emitted when owner proposed an account that can accept ownership.
    event OwnershipProposed(address indexed owner, address indexed pendingOwner);

    /// @notice Emitted when unlocked tokens are merged into one.
    event TokensMerged(uint256[] mergedTokenIds, uint256 tokenId, uint256 credits);

    /*************/
    /* Constants */
    /*************/

    /// @notice The IERC721Permit domain separator.
    function DOMAIN_SEPARATOR() external view returns (bytes32 domainSeparator_);

    /// @notice The minimum units that can result from a lock of XDEFI.
    function MINIMUM_UNITS() external view returns (uint256 minimumUnits_);

    /*********/
    /* State */
    /*********/

    /// @notice The base URI for NFT metadata.
    function baseURI() external view returns (string memory baseURI_);

    /// @notice The multiplier applied to the deposited XDEFI amount to determine the units of a position, and thus its share of future distributions.
    function bonusMultiplierOf(uint256 duration_) external view returns (uint256 bonusMultiplier_);

    /// @notice Returns the consume permit nonce for a token.
    function consumePermitNonce(uint256 tokenId_) external view returns (uint256 nonce_);

    /// @notice Returns the credits of a token.
    function creditsOf(uint256 tokenId_) external view returns (uint256 credits_);

    /// @notice The amount of XDEFI that is distributable to all currently locked positions.
    function distributableXDEFI() external view returns (uint256 distributableXDEFI_);

    /// @notice The contract is no longer allowing locking XDEFI, and is allowing all locked positions to be unlocked effective immediately.
    function inEmergencyMode() external view returns (bool lockingDisabled_);

    /// @notice The account that can set and unset lock periods and transfer ownership of the contract.
    function owner() external view returns (address owner_);

    /// @notice The account that can take ownership of the contract.
    function pendingOwner() external view returns (address pendingOwner_);

    /// @notice Returns the position details (`pointsCorrection_` is a value used in the amortized work pattern for token distribution).
    function positionOf(uint256 tokenId_) external view returns (Position memory position_);

    /// @notice The amount of XDEFI that was deposited by all currently locked positions.
    function totalDepositedXDEFI() external view returns (uint256 totalDepositedXDEFI_);

    /// @notice The amount of locked position units (in some way, it is the denominator use to distribute new XDEFI to each unit).
    function totalUnits() external view returns (uint256 totalUnits_);

    /// @notice The address of the XDEFI token.
    function xdefi() external view returns (address XDEFI_);

    /*******************/
    /* Admin Functions */
    /*******************/

    /// @notice Allows the `pendingOwner` to take ownership of the contract.
    function acceptOwnership() external;

    /// @notice Disallows locking XDEFI, and is allows all locked positions to be unlocked effective immediately.
    function activateEmergencyMode() external;

    /// @notice Allows the owner to propose a new owner for the contract.
    function proposeOwnership(address newOwner_) external;

    /// @notice Sets the base URI for NFT metadata.
    function setBaseURI(string calldata baseURI_) external;

    /// @notice Allows the setting or un-setting (when the multiplier is 0) of multipliers for lock durations. Scaled such that 1x is 100.
    function setLockPeriods(uint256[] calldata durations_, uint256[] calldata multipliers) external;

    /**********************/
    /* Position Functions */
    /**********************/

    /// @notice Unlock only the deposited amount from a non-fungible position, sending the XDEFI to some destination, when in emergency mode.
    function emergencyUnlock(uint256 tokenId_, address destination_) external returns (uint256 amountUnlocked_);

    /// @notice Returns the bonus multiplier of a locked position.
    function getBonusMultiplierOf(uint256 tokenId_) external view returns (uint256 bonusMultiplier_);

    /// @notice Locks some amount of XDEFI into a non-fungible (NFT) position, for a duration of time. The caller must first approve this contract to spend its XDEFI.
    function lock(
        uint256 amount_,
        uint256 duration_,
        uint256 bonusMultiplier_,
        address destination_
    ) external returns (uint256 tokenId_);

    /// @notice Locks some amount of XDEFI into a non-fungible (NFT) position, for a duration of time, with a signed permit to transfer XDEFI from the caller.
    function lockWithPermit(
        uint256 amount_,
        uint256 duration_,
        uint256 bonusMultiplier_,
        address destination_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external returns (uint256 tokenId_);

    /// @notice Unlock an un-lockable non-fungible position and re-lock some amount, for a duration of time, sending the balance XDEFI to some destination.
    function relock(
        uint256 tokenId_,
        uint256 lockAmount_,
        uint256 duration_,
        uint256 bonusMultiplier_,
        address destination_
    ) external returns (uint256 amountUnlocked_, uint256 newTokenId_);

    /// @notice Unlock an un-lockable non-fungible position, sending the XDEFI to some destination.
    function unlock(uint256 tokenId_, address destination_) external returns (uint256 amountUnlocked_);

    /// @notice To be called as part of distributions to force the contract to recognize recently transferred XDEFI as distributable.
    function updateDistribution() external;

    /// @notice Returns the amount of XDEFI that can be withdrawn when the position is unlocked. This will increase as distributions are made.
    function withdrawableOf(uint256 tokenId_) external view returns (uint256 withdrawableXDEFI_);

    /****************************/
    /* Batch Position Functions */
    /****************************/

    /// @notice Unlocks several un-lockable non-fungible positions and re-lock some amount, for a duration of time, sending the balance XDEFI to some destination.
    function relockBatch(
        uint256[] calldata tokenIds_,
        uint256 lockAmount_,
        uint256 duration_,
        uint256 bonusMultiplier_,
        address destination_
    ) external returns (uint256 amountUnlocked_, uint256 newTokenId_);

    /// @notice Unlocks several un-lockable non-fungible positions, sending the XDEFI to some destination.
    function unlockBatch(uint256[] calldata tokenIds_, address destination_) external returns (uint256 amountUnlocked_);

    /*****************/
    /* NFT Functions */
    /*****************/

    /// @notice Returns the tier and credits of an NFT.
    function attributesOf(uint256 tokenId_)
        external
        view
        returns (
            uint256 tier_,
            uint256 credits_,
            uint256 withdrawable_,
            uint256 expiry_
        );

    /// @notice Consumes some credits from an NFT, returning the number of credits left.
    function consume(uint256 tokenId_, uint256 amount_) external returns (uint256 remainingCredits_);

    /// @notice Consumes some credits from an NFT, with a signed permit from the owner, returning the number of credits left.
    function consumeWithPermit(
        uint256 tokenId_,
        uint256 amount_,
        uint256 limit_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    ) external returns (uint256 remainingCredits_);

    /// @notice Returns the URI for the contract metadata.
    function contractURI() external view returns (string memory contractURI_);

    /// @notice Returns the credits an NFT will have, given some amount locked for some duration.
    function getCredits(uint256 amount_, uint256 duration_) external pure returns (uint256 credits_);

    /// @notice Returns the tier an NFT will have, given some credits, which itself can be determined from `getCredits`.
    function getTier(uint256 credits_) external pure returns (uint256 tier_);

    /// @notice Burns several unlocked NFTs to combine their credits into the first.
    function merge(uint256[] calldata tokenIds_) external returns (uint256 tokenId_, uint256 credits_);

    /// @notice Returns the URI for the NFT metadata for a given token ID.
    function tokenURI(uint256 tokenId_) external view returns (string memory tokenURI_);
}

// File: contracts/interfaces/IXDEFIDistributionHelper.sol



pragma solidity =0.8.12;


interface IXDEFIDistributionLike {
    struct Position {
        uint96 units;
        uint88 depositedXDEFI;
        uint32 expiry;
        uint32 created;
        uint256 pointsCorrection;
    }

    function balanceOf(address account_) external view returns (uint256 balance_);

    function creditsOf(uint256 tokenId_) external view returns (uint256 credits_);

    function positionOf(uint256 tokenId_) external view returns (Position memory position_);

    function tokenOfOwnerByIndex(address account_, uint256 index_) external view returns (uint256 tokenId_);

    function withdrawableOf(uint256 tokenId_) external view returns (uint256 withdrawableXDEFI_);
}

interface IXDEFIDistributionHelper {
    function getAllTokensForAccount(address xdefiDistribution_, address account_) external view returns (uint256[] memory tokenIds_);

    function getAllTokensAndCreditsForAccount(address xdefiDistribution_, address account_) external view returns (uint256[] memory tokenIds_, uint256[] memory credits_);

    function getAllLockedPositionsForAccount(address xdefiDistribution_, address account_)
        external
        view
        returns (
            uint256[] memory tokenIds_,
            IXDEFIDistributionLike.Position[] memory positions_,
            uint256[] memory withdrawables_
        );

    function getAllLockedPositionsAndCreditsForAccount(address xdefiDistribution_, address account_)
        external
        view
        returns (
            uint256[] memory tokenIds_,
            IXDEFIDistributionLike.Position[] memory positions_,
            uint256[] memory withdrawables_,
            uint256[] memory credits_
        );
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

// File: contracts/4_XDEFIDistributionHelper2.sol



pragma solidity =0.8.12;



/// @dev Stateful helper contract for external clients to reduce web3 calls to gather XDEFIDistribution information related to individual accounts.
contract XDEFIDistributionHelper2 is Ownable {

    address public xdefiAddress;
    address public xdefiDistributionHelperAddress;

    constructor() {
    }

    function setConfig(address xdefiAddress_, address xdefiDistributionHelperAddress_) public onlyOwner {
        xdefiAddress = xdefiAddress_;
        xdefiDistributionHelperAddress = xdefiDistributionHelperAddress_;
    }

    
    function balanceOfStakedXDEFI(address account_) public view returns (uint256 totalStakedXDEFI) {
        IXDEFIDistributionLike.Position[] memory positions;
        
        (, positions, ) = IXDEFIDistributionHelper(xdefiDistributionHelperAddress).getAllLockedPositionsForAccount(xdefiAddress, account_);

        totalStakedXDEFI = 0;
        for (uint256 i; i < positions.length; ) {
            totalStakedXDEFI += uint256(positions[i].depositedXDEFI);

            unchecked {
                ++i;
            }
        }
    }

}
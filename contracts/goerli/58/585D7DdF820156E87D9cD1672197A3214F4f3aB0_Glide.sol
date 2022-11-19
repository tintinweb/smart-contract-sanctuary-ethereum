// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "hardhat/console.sol";
import "./utils/Ownable.sol";
import "./token/IERC721A.sol";

// TODO change name of DNA contract
contract Glide is Ownable {
    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // No need for upper dna mask because we can just right shift the number 128 bits 
    uint256 public constant LOWER_DNA_MASK = (1 << 128) - 1;

    uint256 public constant _BITMASK_REROLL = 1 << 128;
    uint256 public constant REROLLABLE_TRAITS = 5;

    uint256 public constant REROLL_COST = 0.01 ether;

    uint256 public constant MAX_BOOST_AMOUNT = 10;

    // Only 5 rerollable traits, will fit in 3 bits
    uint256 public constant BOOSTER_TRAIT_LENGTH = 3;
    uint256 public constant BOOSTER_TRAIT_MASK = (1 << BOOSTER_TRAIT_LENGTH) - 1;
    // Only must be less than 10, so it will fit in 4 bits
    uint256 public constant BOOSTER_AMOUNT_LENGTH = 4;
    uint256 public constant BOOSTER_AMOUNT_MASK = ((1 << BOOSTER_AMOUNT_LENGTH) - 1) << BOOSTER_TRAIT_LENGTH;

    uint256 public constant BOOSTER_MASK_COMPLEMENT = type(uint256).max << (BOOSTER_TRAIT_LENGTH + BOOSTER_AMOUNT_LENGTH);
    
    uint256 public constant BOOSTER_VALUE_LENGTH = 20;
    uint256 public constant BOOSTER_VALUE_MASK = (1 << BOOSTER_VALUE_LENGTH) - 1;

    // This IPFS code hash will have a function that can translate any token's
    // DNA into the corresponding traits. This logic is put here so that the
    // gas fee for rerolling is minimal for the user.
    string public DNA_TRANSLATOR_CODE_HASH = "";

    // To be released later
    string public INITIAL_PROVENANCE_HASH = "";

    // To be released later
    string public SECONDARY_PROVENANCE_HASH = "";

    // =============================================================
    //                            STORAGE
    // =============================================================

    // for pseudo-rng
    uint256 private _seed;

    bool public initialDnaLocked;

    address public immutable tokenContract;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..126]   `booster`
    // - [127]      `freeRerollUsed`
    // - [128..255] `initialDna`
    mapping(uint256 => uint256) private _dna;
    mapping(uint256 => uint256) public activeBooster;

    event Bought(
        uint256 indexed tokenId,
        uint256 indexed traitId,
        uint256 tokenDna,
        uint256 boosterVal
    );
    event Boost(uint256 indexed tokenId, uint256 boosterId, uint256 tokenDna);

    // =============================================================
    //                         Constructor
    // =============================================================
    constructor (address tokenAddress) {
        tokenContract = tokenAddress;
    }

    // =============================================================
    //                          Only Owner
    // =============================================================

    // TODO add events for DNA injection and locking
    function injectDna(uint256[] memory initialDna, uint256[] memory tokenIds) external onlyOwner {
        if (initialDnaLocked) revert();

        for (uint i = 0; i < tokenIds.length; i++) {
            _dna[tokenIds[i]] = initialDna[i];
        }
    }

    function lockInitialDna() external onlyOwner {
        initialDnaLocked = true;
    }

    function getTokenDna(uint256 tokenId) external view returns (uint256) {
        return _dna[tokenId];
    }

    function _rerollUsed(uint256 tokenId) internal view returns (bool) {
        return _dna[tokenId] & _BITMASK_REROLL == 0;
    }
    function _setRerollUsed(uint256 tokenId) internal {
        _dna[tokenId] = _dna[tokenId] | _BITMASK_REROLL;
    }

    function freeReroll(uint256 tokenId, uint256 traitId) external {
        if (_rerollUsed(tokenId)) revert();
        _setRerollUsed(tokenId);
        _rerollTrait(tokenId, traitId, 1);
    }

    function rerollTrait(
        uint256 tokenId,
        uint256 traitId,
        uint256 boostAmount
    ) external payable {
        _rerollTrait(tokenId, traitId, boostAmount);
    }

    function _rerollTrait(
        uint256 tokenId,
        uint256 traitId,
        uint256 boostAmount
    ) internal {
        if (IERC721A(tokenContract).ownerOf(tokenId) != msg.sender) revert NotTokenOwner();
        if (_dna[tokenId] == 0) revert();
        if (traitId >= REROLLABLE_TRAITS) revert TraitNotRerollable();
        
        if (boostAmount > MAX_BOOST_AMOUNT) revert BoostAmountTooLarge();

        uint256 boosterVal = _randomNumber() & BOOSTER_MASK_COMPLEMENT;
        boosterVal = boosterVal | traitId | (boostAmount << BOOSTER_TRAIT_LENGTH);

        activeBooster[tokenId] = boosterVal;
        emit Bought(tokenId, traitId, _dna[tokenId], boosterVal);
    }

    function boost(uint256 tokenId, uint256 boosterIdx) external {
        if(IERC721A(tokenContract).ownerOf(tokenId) != msg.sender) revert NotTokenOwner();
        uint256 boosterVal = activeBooster[tokenId];

        uint256 traitId = boosterVal & BOOSTER_TRAIT_MASK;
        uint256 numBoosts = (boosterVal & BOOSTER_AMOUNT_MASK) >> BOOSTER_TRAIT_LENGTH;

        if (numBoosts <= boosterIdx) revert InvalidBoostIdx();

        uint256 shiftAmount = boosterIdx * BOOSTER_VALUE_LENGTH + BOOSTER_AMOUNT_LENGTH + BOOSTER_TRAIT_LENGTH;
        uint256 selectedVal = (boosterVal & (BOOSTER_VALUE_MASK << shiftAmount)) >> shiftAmount;

        uint256 traitShiftAmount = traitId * BOOSTER_VALUE_LENGTH;
        _dna[tokenId] = _dna[tokenId] & ~(BOOSTER_VALUE_MASK << traitShiftAmount) | (selectedVal << traitShiftAmount);
        emit Boost(tokenId, boosterIdx, _dna[tokenId]);
    }

    function _randomNumber() internal returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, _seed++)));
    }

    error InvalidBoostIdx();
    error BoostAmountTooLarge();
    error NotTokenOwner();
    error TraitNotRerollable();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

error CallerNotOwner();
error OwnerNotZero();

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
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        if (owner() != _msgSender()) revert CallerNotOwner();
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
        if (newOwner == address(0)) revert OwnerNotZero();
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
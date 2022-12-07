// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./utils/Ownable.sol";
import "./token/ERC721/IERC721A.sol";

/**
 * Subset of a Utility with only the methods that the dna contract will call.
 */
interface Utility {
    function approvedBurn(address spender, uint256 tokenId, uint256 amount) external;
}

// TODO change name of DNA contract
contract Glide is Ownable {
    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Checks the `ownerOf` method of this address for tokenId re-roll eligibility
    address public immutable TOKEN_CONTRACT;

    // This IPFS code hash will have a function that can translate any token's
    // DNA into the corresponding traits. This logic is put here so that the
    // gas fee for rerolling is minimal for the user.
    string public DNA_TRANSLATOR_CODE_HASH = "";

    // To be released later
    string public INITIAL_PROVENANCE_HASH = "";

    // To be released later
    string public SECONDARY_PROVENANCE_HASH = "";

    // The Initial DNA is composed of 128 bits for each token
    // with each trait taking up 8 bits.
    uint256 private constant _BITMASK_INITIAL_DNA = (1 << 8) - 1;

    uint256 private constant _BITMASK_FREE_REROLL_START = 1 << 128;
    uint256 public constant FREE_REROLLS = 7;
    
    uint256 private constant _BOOSTER_OFFSET = 135;


    // 3 rerollable traits will fit in 2 bits
    uint256 private constant _BITLEN_BOOSTER_TRAIT = 2;
    uint256 private constant _BITMASK_BOOSTER_TRAIT = (1 << _BITLEN_BOOSTER_TRAIT) - 1;

    // Reroll amount fit easily in 4 bits
    uint256 private constant _BITMASK_BOOSTER_AMT = ((1 << 4) - 1) << _BITLEN_BOOSTER_TRAIT;

    // Starting bit position of the booster values
    uint256 private constant _BITPOS_BOOSTER_VAL = 6;
    
    uint256 private constant _BITLEN_SINGLE_BOOST = 20;
    uint256 private constant _BITMASK_SINGLE_BOOST = (1 << _BITLEN_SINGLE_BOOST) - 1;
    uint256 private constant _BITLEN_TRAIT_BOOST = 21;
    uint256 private constant _BITMASK_TRAIT_BOOST = (1 << _BITLEN_TRAIT_BOOST) - 1;

    // =============================================================
    //                            STORAGE
    // =============================================================

    address public utilityAddress;
    uint256 public utilityTokenId;

    // Checks the `ownerOf` method of this address for tokenId re-roll eligibility
    bool public initialDnaLocked;
    bool public rerollActive;

    // for pseudo-rng
    uint256 private _seed;
    
    // Mapping tokenId to DNA information. An extra bit is needed for
    // each trait because the random boosterValue does have the tiniest
    // but non-zero probability to roll a 0. (1 in 1_048_576)
    //
    // Bits Layout:
    // - [0..127]   `initialDna`
    // - [135]      `hasHairBooster`
    // - [135..154] `hairBooster`
    // - [155]      `hasClothingBooster`
    // - [156..175] `clothingBooster`
    // - [176]      `hasWeaponBooster`
    // - [177..196] `weaponBooster`
    // - [197..255]  Extra Unused Bits
    mapping(uint256 => uint256) private _dna;

    // Bits Layout:
    // - [0..2]     `boosterIdx`
    // - [4..7]     `boosterValue`
    // - [28..47]   `boosterRoll`
    // - [48..67]   `boosterRoll`
    // - [68..87]   `boosterRoll`
    // - [88..107]  `boosterRoll`
    // - [108..127] `boosterRoll` // 20 bits long
    mapping(uint256 => uint256) public activeBooster;

    // =============================================================
    //                         Events
    // =============================================================

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
        TOKEN_CONTRACT = tokenAddress;
    }

    // =============================================================
    //                          Only Owner
    // =============================================================

    function injectDna(uint256[] memory initialDna, uint256[] memory tokenIds) external onlyOwner {
        if (initialDnaLocked) revert InitialDnaLocked();

        for (uint i = 0; i < tokenIds.length; ) {
            _dna[tokenIds[i]] = initialDna[i];

            unchecked {
                ++i;
            }
        }
    }

    function setRerollToken(address token, uint256 tokenId) external onlyOwner {
        utilityAddress = token;
        utilityTokenId = tokenId;
    }

    function setRerollActive(bool active) external onlyOwner {
        rerollActive = active;
    }

    function lockInitialDna() external onlyOwner {
        initialDnaLocked = true;
    }

    function getTokenDna(uint256 tokenId) external view returns (uint256) {
        return _dna[tokenId];
    }

    /**
     * TraitId can only be 1, 2, or 3
     */
    function reroll(uint256 tokenId, uint256 rerollTraitId) external {
        if (!rerollActive) revert RerollInactive();
        if (msg.sender != tx.origin) revert NotEOA();
        if (rerollTraitId > 2) revert TraitNotRerollable();
        if (IERC721A(TOKEN_CONTRACT).ownerOf(tokenId) != msg.sender) revert NotTokenOwner();

        Utility(utilityAddress).approvedBurn(msg.sender, utilityTokenId, 1);

        _rerollTrait(tokenId, rerollTraitId, 3);
    }

    function _rerollTrait(
        uint256 tokenId,
        uint256 rerollTraitId,
        uint256 boostAmount
    ) internal {
        // Cheaper gaswise to do bitshift than to multiple
        if (_dna[tokenId] & (_BITMASK_INITIAL_DNA << (rerollTraitId << 3)) == 0) revert TraitNotOnToken();

        // Can safely just shift _randomNumber up to make room for reroll information bits
        uint256 boosterVal = _randomNumber() << _BITPOS_BOOSTER_VAL;
        boosterVal = boosterVal | (boostAmount << _BITLEN_BOOSTER_TRAIT) | rerollTraitId;

        activeBooster[tokenId] = boosterVal;
        emit Bought(tokenId, rerollTraitId, _dna[tokenId], boosterVal);
    }

    function boost(uint256 tokenId, uint256 boosterIdx) external {
        if(IERC721A(TOKEN_CONTRACT).ownerOf(tokenId) != msg.sender) revert NotTokenOwner();
        uint256 boosterVal = activeBooster[tokenId];
        activeBooster[tokenId] = 0;

        // uint256 numBoosts = (boosterVal & _BITMASK_BOOSTER_AMT) >> _BITLEN_BOOSTER_TRAIT;
        if ((boosterVal & _BITMASK_BOOSTER_AMT) >> _BITLEN_BOOSTER_TRAIT <= boosterIdx) revert InvalidBoostIdx();
        uint256 selectedVal = 
            (boosterVal >> (boosterIdx * _BITLEN_SINGLE_BOOST + _BITPOS_BOOSTER_VAL)) &
            _BITMASK_SINGLE_BOOST;

        // This shifts the value up one bit and adds a flag to show that this trait has been boosted.
        // This is needed on the small chance that random value generated is exactly 0.
        selectedVal = selectedVal << 1 | 1;

        // Similarly this value is 21 to account for this extra bit. It is cheaper gaswise to put 21
        // than to put (_BITLEN_SINGLE_BOOST + 1). It is also cheaper to not initialize a variable for
        // uint256 rerollTraitId = boosterVal & _BITMASK_BOOSTER_TRAIT;
        uint256 traitShiftAmount = (boosterVal & _BITMASK_BOOSTER_TRAIT) * _BITLEN_TRAIT_BOOST + _BOOSTER_OFFSET;

        _dna[tokenId] = _dna[tokenId] & ~(_BITMASK_TRAIT_BOOST << traitShiftAmount) | (selectedVal << traitShiftAmount);
        emit Boost(tokenId, boosterIdx, _dna[tokenId]);
    }

    /**
     * Makes a random number.
     */
    function _randomNumber() internal returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, ++_seed)));
    }

    error RerollInactive();
    error IncorrectMsgValue();
    error InitialDnaLocked();
    error InvalidBoostIdx();
    error NotEOA();
    error NotTokenOwner();
    error RerollEnded();
    error TraitNotRerollable();
    error TraitNotOnToken();
    error WithdrawFailed();
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
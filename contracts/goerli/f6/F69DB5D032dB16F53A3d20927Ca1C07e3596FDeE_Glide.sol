// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./utils/Ownable.sol";
import "./token/IERC721A.sol";

// TODO change name of DNA contract
contract Glide is Ownable {

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    uint256 public constant TRAIT_MASK_LENGTH = 8;

    uint256 public constant TRAIT_MASK = 2**TRAIT_MASK_LENGTH - 1;

    uint256 public constant IDENTITY_MASK = 2**16 - 1;

    uint256 public constant MAX_BOOST_AMOUNT = 10;

    bool public initialDnaInjected;

    // for pseudo-rng
    uint256 private _seed;

    address public immutable tokenContract;

    /**
     * Not all traits are rerollable. Potentially can change make this check simpler
     * if all non-rerollable or all rerollable traits are consecutive.
     */
    mapping(uint256 => bool) public rerollableTraits;

    // tokenId to dna
    mapping(uint256 => uint256) public dna;
    mapping(uint256 => uint256) public traitBoosters;

    mapping(uint256 => uint256[]) private _allTraitOdds;

    /**
     * Certain trait combinations do not fit together visually, this mapping
     * is a way to prevent these conflicts from being potential rolls.
     * 
     * Example: Having a helmet that covers the ears and having earrings.
     */
    mapping(uint256 => uint256) private traitConflicts;
    
    event Bought(
        uint256 indexed tokenId,
        uint256 indexed traitId,
        uint256 boosterVal
    );
    event Boost(uint256 indexed tokenId, uint256 boosterId, uint256 newDNA);

    // =============================================================
    //                         CONSTRUCTOR
    // =============================================================
    constructor (address tokenAddress) {
        tokenContract = tokenAddress;
    }

    function injectDna(uint256[] memory initialDna, uint256[] memory tokenIds) external onlyOwner {
        if (initialDnaInjected) revert();
        if (initialDna.length != tokenIds.length) revert();

        for (uint i = 0; i < initialDna.length; i++) {
            dna[tokenIds[i]] = initialDna[i];
        }
    }

    function lockInitialDna() external onlyOwner {
        initialDnaInjected = true;
    }

    function addTraitOdds(uint256 traitIdentity, uint256[] memory traitOdds) external onlyOwner {
        _allTraitOdds[traitIdentity] = traitOdds;
    }

    function addRerollableTrait(uint256 traitId) external onlyOwner {
        rerollableTraits[traitId] = true;
    }

    function _randomNumber() internal returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, _seed++)));
    }

    function _totalSum(uint256[] memory traitOdds, uint256 skipVals)
        internal
        pure
        returns (uint256)
    {
        uint256 sum = 0;
        for (uint256 i = 0; i < traitOdds.length; i++) {
            if ((skipVals >> i) % 2 == 0) {
                sum += traitOdds[i];
            }
        }
        return sum;
    }

    function _getRandTrait(
        uint256 rand,
        uint256[] memory traitOdds,
        uint256 skipVals
    ) internal pure returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < traitOdds.length; i++) {
            if ((skipVals >> i) % 2 == 0) {
                sum += traitOdds[i];
                if (sum > rand) {
                    return i;
                }
            }
        }

        revert();
    }

    function _calculateConflicts(uint256 currDna, uint256 traitId)
        internal
        view
        returns (uint256)
    {
        // uint256[] memory traitConflicts = traitIdToConflicts[traitId];

        uint256 totalConflicts = 0;
        // for (uint256 i = 0; i < traitConflicts.length; i++) {
        //     uint256 conMask = currDna &
        //         (BIT_MASK << (BIT_MASK_LENGTH * traitConflicts[i]));
        //     // TODO figure out 0
        //     totalConflicts |= traitIdBAD[traitId][conMask];
        // }

        return totalConflicts;
    }

    function rerollTrait(
        uint256 tokenId,
        uint256 traitId,
        uint256 boostAmount
    ) external payable {
        if (tx.origin != msg.sender) revert();
        if (IERC721A(tokenContract).ownerOf(tokenId) != msg.sender) revert NotTokenOwner();
        if (!rerollableTraits[traitId]) revert TraitNotRerollable();
        if (boostAmount > MAX_BOOST_AMOUNT) revert();

        uint256 currDna = dna[tokenId];
        if (currDna & (IDENTITY_MASK << (16)) == 0) revert();
        uint256 randVal;

        // This covers identity based conflicts
        uint256 traitsIndex = (currDna & IDENTITY_MASK) | traitId;
        if (_allTraitOdds[traitsIndex].length == 0) {
            traitsIndex = traitId;
        } 

        uint256 boosterVal = 0;

        uint256 conflict = 0; // _calculateConflicts(currDna, traitsIndex);
        uint256 traitSum = 10000;
        // if (conflict != 0) {
        //     traitSum = _totalSum(_allTraitOdds[traitsIndex], conflict);
        // }

        do {
            randVal = _getRandTrait(
                _randomNumber() % traitSum,
                _allTraitOdds[traitsIndex],
                conflict
            );

            // +1 because randVal can return 0 index, but a value of 0 is
            // reserved for an empty booster
            boosterVal = (boosterVal << TRAIT_MASK_LENGTH) + randVal + 1;
        } while ((boosterVal >> (TRAIT_MASK_LENGTH * (boostAmount - 1))) == 0);

        // add which traitId this 
        traitBoosters[tokenId] = (boosterVal << TRAIT_MASK_LENGTH) + traitId;
        emit Bought(tokenId, traitId, traitBoosters[tokenId]);
    }

    function boost(uint256 tokenId, uint256 boosterIdx) external {
        if(IERC721A(tokenContract).ownerOf(tokenId) != msg.sender) revert NotTokenOwner();
        if(boosterIdx == 0) revert();

        uint256 traitId = traitBoosters[tokenId] & TRAIT_MASK;
        uint256 selectedVal = (traitBoosters[tokenId] >>
            (TRAIT_MASK_LENGTH * boosterIdx)) & TRAIT_MASK;
        if (selectedVal == 0) revert();

        uint256 newTraitDna = (selectedVal - 1) << (TRAIT_MASK_LENGTH * traitId);
        uint256 newBitMask = ~(TRAIT_MASK << (TRAIT_MASK_LENGTH * traitId));

        traitBoosters[tokenId] = 0;
        dna[tokenId] = (dna[tokenId] & newBitMask) | newTraitDna;
        emit Boost(tokenId, boosterIdx, dna[tokenId]);
    }

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
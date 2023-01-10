// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./Authority.sol";
import "./interfaces/IAuthorityFactory.sol";

contract AuthorityFactory is IAuthorityFactory {
    address public immutable comboCollFactory;
    address public immutable tokenIdentifier;
    address public immutable lockerIndexer;

    constructor(
        address comboCollFactory_,
        address tokenIdentifier_,
        address lockerIndexer_
    ) {
        if (
            comboCollFactory_ == address(0) ||
            tokenIdentifier_ == address(0) ||
            lockerIndexer_ == address(0)
        ) {
            revert ZeroAddress();
        }

        comboCollFactory = comboCollFactory_;
        tokenIdentifier = tokenIdentifier_;
        lockerIndexer = lockerIndexer_;
    }

    function deploy(address combo_) external override returns (address) {
        if (msg.sender != comboCollFactory) {
            revert CallerNotAllowed();
        }

        Authority authority = new Authority(
            combo_,
            tokenIdentifier,
            lockerIndexer
        );
        authority.transferOwnership(comboCollFactory);
        return address(authority);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./ICollectionType.sol";

interface IComboReceipt is ICollectionType {

    struct ComboReceipt {
        uint256 comboId;
        bytes32 comboHash;

        uint256 usedTotalCount;
        address[] usedColls;
        uint256[] usedCollCounts;
        uint256[] addOnFees;

        address[] lockColls;    // ERC721 and ERC1155
        CollectionType[] lockCollTypes;
        uint256[][] lockTokenIds;
        uint256[][] lockTokenAmounts;
        uint256[][] lockUUIDs;

        address[] unlockColls; // only ERC721 (including Combo)
        uint256[][] unlockTokenIds;
        uint256[][] unlockUUIDs;

        uint64[] sets;
        address[][] collsForSet;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./ICollectionType.sol";


interface IComboCoreStructs is ICollectionType {

    struct Factor {
        uint128 max;
        uint128 min;
        // collection = address(0) indicates this is a factor for set and
        // Factor.setId must not be 0.
        address collection;
        // setId = 0 indicates this is a factor for non-set colection and 
        // Factor.collection must not be address(0).
        uint64 setId;
        bool lock;
    }

    struct Limit {
        address collection; // Only ERC721
        uint128 maxTokenUsage; // Max usage times for each token
    }

    struct ComboRules {
        Factor[] factors;
        Limit[] limits;
    }

    struct ConstructorParams {
        string name;
        string symbol;
        string contractURIPath;
        ComboRules comboRules;
    }

    // ============================ ComboMeta ============================
    struct Item {
        uint256 uuid;
        uint128 amount;
        uint64 setId;
        uint8 typ;
        bool lock;
        bool limit;
    }

    struct ComboMeta {
        // the one who created or edited this combo
        address creator;
        Item[] items;
    }

    // ============================ ComboParams ============================
    struct ComboParams {
        Ingredients ingredients;

        // For ingredients.collections
        CollectionType[] collectionTypes;

        // For ERC1155 collection, dup does not matter.
        uint256[][] userBalancesFor1155Items;

        uint256[][] uuidForItems;
        string hash;
    }

    struct Ingredients {
        address[] collections;    // sorted in ascending order. no dup.
        uint256[][] itemsForCollections; // sorted in ascending order. dup is only allowed for ERC-1155.
        uint128[][] amountsForItems;
        uint64[][] setsForItems;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface ICollectionType {
    enum CollectionType {
        UNDEFINED, // unused
        ERC721,
        ERC1155,
        COMBO
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface ITokenIdentifier {
    error ZeroAddress();    // 0xd92e233d
    error TokenNotExists(); // 0x01bdc21c

    struct Token {
        address tokenAddress;
        uint256 tokenId;
    }

    function getOrGenerateUUID(
        address[] calldata collections,
        uint256[][] calldata tokenIds
    ) external returns (uint256[][] memory);

    function getUUID(
        address[] calldata collections,
        uint256[][] calldata tokenIds,
        bool mustExist
    ) external view returns (uint256[][] memory);

    /**
     * @dev no error thrown if not found
     */
    function tokensOf(uint256[][] calldata uuids)
        external
        view
        returns (Token[][] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./base/IComboReceipt.sol";
import "./ITokenIdentifier.sol";
import "./base/IComboCoreStructs.sol";

interface ILockerIndexer {
    error ZeroAddress();        // 0xd92e233d
    error DuplicateLockers();   // 0x8bd0ef32
    error CallerNotAllowed();   // 0x2af07d20
    error ParentExists();       // 0xbca6ce22
    error LockerNotExists();    // 0xde129513
    error ParentDiffers(        // 0x37452d1e
        uint256 uuid,
        uint256 expect,
        uint256 actual
    );

    struct LockerInfo {
        bool registered;
        bool enabled;
    }
    
    function addLocker(address locker) external;

    function setEnabled(address locker, bool enabled) external;

    function getInfos(address[] calldata lockers)
        external
        view
        returns (LockerInfo[] memory);

    function addIndex(
        address combo,
        IComboReceipt.ComboReceipt calldata receipt
    ) external;

    function removeIndex(
        address combo,
        uint256 comboId,
        IComboCoreStructs.ComboMeta calldata meta
    ) external;

    function rootCombosOf(
        address[] calldata tokenAddresses,
        uint256[][] calldata tokenIds
    ) external returns (ITokenIdentifier.Token[][] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface IAuthorityFactory {
    error ZeroAddress();        // 0xd92e233d
    error CallerNotAllowed();   // 0x2af07d20

    function deploy(address combo) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "./base/IComboReceipt.sol";

interface IAuthority {
    error NotTokenOwner();      // 0x59dc379f
    error ZeroAddress();        // 0xd92e233d
    error ZeroAmount();         // 0x1f2a2005
    error ZeroPageParam();      // 0xad45b8c6
    error AllowanceNotEnough(); // 0x902b38ea
    error TokenNotExists();     // 0x01bdc21c

    event IncreaseAllowance(
        address indexed combo,
        address indexed spender,
        uint256[][] uuids,
        uint256[][] amounts
    );

    event DecreaseAllowance(
        address indexed combo,
        address indexed spender,
        uint256 uuid
    );

    function increaseAllowance(
        address owner,
        address spender,
        address[] calldata tokenAddresses,
        uint256[][] calldata tokenIds,
        uint256[][] calldata amounts
    ) external;

    function decreaseAllowance(
        address spender,
        IComboReceipt.ComboReceipt calldata receipt
    ) external;

    function authoritiesOf(
        address spender,
        uint256 pageNum,
        uint256 pageSize
    )
        external
        view
        returns (
            uint256 total,
            uint256[] memory uuids,
            uint256[] memory allowances
        );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./interfaces/IAuthority.sol";
import "./interfaces/ITokenIdentifier.sol";
import "./interfaces/ILockerIndexer.sol";

// @dev only support erc-721
contract Authority is IAuthority, Ownable {
    address private immutable _combo;
    address private immutable _tokenIdentifier;
    address private immutable _lockerIndexer;

    struct AuthBook {
        // excluding the uuid with zero allowance
        uint256[] uuids;
        // uuid => allowance
        mapping(uint256 => uint256) allowances;
        // uuid => index
        mapping(uint256 => uint256) indexPlusOnes;
    }

    // user address => AuthBook
    mapping(address => AuthBook) private _accounts;

    constructor(
        address combo_,
        address tokenIdentifier_,
        address lockerIndexer_
    ) {
        _combo = combo_;
        _tokenIdentifier = tokenIdentifier_;
        _lockerIndexer = lockerIndexer_;
    }

    function increaseAllowance(
        address owner_,
        address spender_,
        address[] calldata tokenAddresses_,
        uint256[][] calldata tokenIds_,
        uint256[][] calldata amounts_
    ) external override onlyOwner {
        if (spender_ == address(0)) {
            revert ZeroAddress();
        }

        uint256[][] memory uuids = ITokenIdentifier(_tokenIdentifier)
            .getOrGenerateUUID(tokenAddresses_, tokenIds_);

        AuthBook storage book = _accounts[spender_];

        for (uint256 i = 0; i < tokenAddresses_.length; ) {
            IERC721 token = IERC721(tokenAddresses_[i]);
            for (uint256 j = 0; j < tokenIds_[i].length; ) {
                if (amounts_[i][j] == 0) {
                    revert ZeroAmount();
                }

                if (owner_ != token.ownerOf(tokenIds_[i][j])) {
                    revert NotTokenOwner();
                }

                if (book.indexPlusOnes[uuids[i][j]] == 0) {
                    book.uuids.push(uuids[i][j]);
                    book.indexPlusOnes[uuids[i][j]] = book.uuids.length;
                }

                book.allowances[uuids[i][j]] += amounts_[i][j];

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }

        emit IncreaseAllowance(_combo, spender_, uuids, amounts_);
    }

    function decreaseAllowance(
        address spender_,
        IComboReceipt.ComboReceipt calldata receipt_
    ) external override onlyOwner {
        ITokenIdentifier.Token[][] memory rootCombos = ILockerIndexer(
            _lockerIndexer
        ).rootCombosOf(receipt_.unlockColls, receipt_.unlockTokenIds);

        AuthBook storage book = _accounts[spender_];

        for (uint256 i = 0; i < receipt_.unlockColls.length; ) {
            IERC721 coll = IERC721(receipt_.unlockColls[i]);
            for (uint256 j = 0; j < receipt_.unlockTokenIds[i].length; ) {
                address tokenOwner = coll.ownerOf(
                    receipt_.unlockTokenIds[i][j]
                );
                if (tokenOwner == address(0)) {
                    // may be burnt
                    revert TokenNotExists();
                }
                if (
                    tokenOwner != spender_ &&
                    (rootCombos[i][j].tokenAddress == address(0) ||
                        IERC721(rootCombos[i][j].tokenAddress).ownerOf(
                            rootCombos[i][j].tokenId
                        ) !=
                        spender_)
                ) {
                    uint256 uuid = receipt_.unlockUUIDs[i][j];
                    uint256 indexPlusOne = book.indexPlusOnes[uuid];
                    if (indexPlusOne == 0) {
                        revert AllowanceNotEnough();
                    }

                    if (book.allowances[uuid] == 1) {
                        uint256 curIndex = indexPlusOne - 1;
                        uint256 lastIndex = book.uuids.length - 1;

                        if (curIndex != lastIndex) {
                            uint256 lastUUID = book.uuids[lastIndex];
                            book.uuids[curIndex] = lastUUID;
                            book.indexPlusOnes[lastUUID] = indexPlusOne;
                        }

                        book.uuids.pop();
                        delete book.allowances[uuid];
                        delete book.indexPlusOnes[uuid];
                    } else {
                        --book.allowances[uuid];
                    }
                    emit DecreaseAllowance(_combo, spender_, uuid);
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    function authoritiesOf(
        address spender_,
        uint256 pageNum_,
        uint256 pageSize_
    )
        external
        view
        override
        returns (
            uint256 total,
            uint256[] memory uuids,
            uint256[] memory allowances
        )
    {
        if (pageNum_ == 0 || pageSize_ == 0) {
            revert ZeroPageParam();
        }

        AuthBook storage book = _accounts[spender_];

        total = book.uuids.length;
        uint256 start = (pageNum_ - 1) * pageSize_;
        if (start >= total) {
            return (total, uuids, allowances);
        }
        uint256 end = start + pageSize_;
        if (end > total) {
            end = total;
        }

        uuids = new uint256[](end - start);
        allowances = new uint256[](end - start);

        for (uint256 i = start; i < end; ++i) {
            uint256 index = i - start;
            uuids[index] = book.uuids[i];
            allowances[index] = book.allowances[uuids[index]];
        }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
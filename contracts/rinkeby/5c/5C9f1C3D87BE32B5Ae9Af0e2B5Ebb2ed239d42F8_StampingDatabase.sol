//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IStampingDatabase.sol";

import "./interfaces/IStampingHub.sol";
import "./interfaces/IStampingDatabaseDeployer.sol";

contract StampingDatabase is IStampingDatabase {

    /// @inheritdoc IStampingDatabase
    address public immutable override hub;

    /// @inheritdoc IStampingDatabase
    address public immutable override token;

    /// @inheritdoc IStampingDatabase
    mapping(bytes32 => IStampingDatabase.Category) public override categories;

    /// @inheritdoc IStampingDatabase
    mapping(bytes32 => mapping(uint256 => bytes32)) public override data;

    /// @dev Prevents calling a function from anyone except the address returned by IStampingHub#owner()
    modifier onlyHubOwner() {
        require(msg.sender == IStampingHub(hub).owner(), "Caller is not the hub owner");
        _;
    }

    constructor() {
        (hub, token) = IStampingDatabaseDeployer(msg.sender).parameters();
    }

    /// @dev Check the ownership of erc721 token
    /// @dev This function is gas optimized to avoid a redundant extcodesize check in addition to the returndatasize
    /// check
    function ownerOf(uint256 tokenId) private view returns (address) {
        (bool _success, bytes memory _data) =
            token.staticcall(abi.encodeWithSelector(IERC721.ownerOf.selector, tokenId));
        require(_success && _data.length >= 32, "Token id not exist");
        return abi.decode(_data, (address));
    }

    /// @dev Returns true if the specific trait existed in that category
    function checkValidTrait(bytes32[] memory traits, bytes32 trait) internal pure returns (bool) {
        for (uint i; i < traits.length; i++) {
            if (traits[i] == trait)
                return true;
        }
        return false;
    }

    /// @inheritdoc IStampingDatabase
    function addCategory(bytes32 title, bytes32 description, bytes calldata traits, bool editable, bool onlyOwner) external override {
        require(!categories[title].activated, "This category already exist");
        categories[title] = IStampingDatabase.Category(description, traits, editable, onlyOwner, true);
        emit CategoryAdded(title, description, traits, editable, onlyOwner, msg.sender);
    }

    /// @inheritdoc IStampingDatabase
    function stamp(bytes32 title, bytes32 trait, uint256 tokenId) external override {
        IStampingDatabase.Category memory category = categories[title];
        require(category.activated, "Category not exist");

        
        (bytes32[] memory _traits) = abi.decode(category.traits, (bytes32[]));
        if (_traits.length > 0) {
            require(checkValidTrait(_traits, trait), "Invalid trait for this category");
        }

        if (!category.editable) {
            require(data[title][tokenId] == 0, "This tokenId already stamped");
        }

        if (category.onlyOwner) {
            require(ownerOf(tokenId) == msg.sender, "Caller is not the owner");
        }
        
        data[title][tokenId] = trait;
        emit TokenStamped(title, trait, tokenId, msg.sender);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @title The interface for a Stamping database
/// @notice A Stamping database facilitates data storage for each of category name
interface IStampingDatabase {
    /// @notice Emitted when a category is added
    /// @param title The title of category
    /// @param description The description for this category
    /// @param traits The trait list that can be use for stamping (can be NULL to allow any trait)
    /// @param editable The status to determine whether the trait can be change later or not
    /// @return onlyOwner The status to determine whether the stamper needed to be token owner or not
    /// @param creator  The sender address
    event CategoryAdded(
        bytes32 title,
        bytes32 description,
        bytes traits,
        bool editable,
        bool onlyOwner,
        address creator
    );

    /// @notice Emitted when stamping happen
    /// @param title The title of category
    /// @param trait The trait to be stamped
    /// @param tokenId The tokenId to be stamped
    /// @param sender The sender address
    event TokenStamped(
        bytes32 title, 
        bytes32 trait, 
        uint256 tokenId, 
        address sender
    );

    struct Category {
        bytes32 description;
        bytes traits;
        bool editable;
        bool onlyOwner;
        bool activated;
    }

    /// @notice The contract that deployed the database, which must adhere to the IStampingHub interface
    /// @return hub The contract address
    function hub() external view returns (address);

    /// @notice The token of the database
    /// @return token The token address
    function token() external view returns (address);

    /// @notice The category info
    /// @param title The title of category
    /// @return description The description for this category
    /// @return traits The trait list that can be use for stamping (can be NULL to allow any trait)
    /// @return editable The status to determine whether the trait can be change later or not
    /// @return onlyOwner The status to determine whether the stamper needed to be token owner or not
    /// @return activated The status to determine whether this category is already activated or not
    function categories(bytes32 title) external view returns (bytes32 description, bytes memory traits, bool editable, bool onlyOwner, bool activated);

    /// @notice The content stored in database
    /// @param title The title of category
    /// @param tokenId The id of stamped token
    /// @return value The value stored in the position
    function data(bytes32 title, uint256 tokenId) external view returns (bytes32);

    /// @notice Add a new category to be stamped
    /// @dev Category needed to be added before stamping
    /// @param title The title of category
    /// @param description The description for this category
    /// @param traits The trait list that can be use for stamping (can be NULL to allow any trait)
    /// @param editable The status to determine whether the trait can be change later or not
    /// @param onlyOwner The status to determine whether the stamper needed to be token owner or not
    function addCategory(bytes32 title, bytes32 description, bytes calldata traits, bool editable, bool onlyOwner) external;

    /// @notice Stamp the data between trait and nft token
    /// @param title The title of category
    /// @param trait The trait to be stamped with token
    /// @param tokenId The specific token id owned by sender
    function stamp(bytes32 title, bytes32 trait, uint256 tokenId) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @title The interface for the Database Hub
/// @notice The Database Hub facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IStampingHub {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a database is created
    /// @param token The address of token for the created database
    /// @param database The address of the created database
    event DatabaseCreated(
        address token,
        address database
    );

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the database address for a given name
    /// @param token The address of token for the created database
    /// @return database The database address
    function getDatabase(
        address token
    ) external view returns (address database);

    /// @notice Creates a pool for the given name
    /// @param token The address of token for the created database
    /// @return database The address of the newly created database
    function createDatabase(
        address token
    ) external returns (address database);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @title An interface for a contract that is capable of deploying Stamping Databse
/// @notice A contract that constructs a database must implement this to pass arguments to the database
/// @dev This is used to avoid having constructor arguments in the database contract, which results in the init code hash
/// of the database being constant allowing the CREATE2 address of the database to be cheaply computed on-chain
interface IStampingDatabaseDeployer {
    /// @notice Get the parameters to be used in constructing the database
    /// @dev Called by the stamping database constructor to fetch the parameters of the database
    /// Returns hub The hub address
    /// Returns token The address of token for database
    function parameters()
        external
        view
        returns (
            address hub,
            address token
        );
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
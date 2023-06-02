// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import "./ERC721Pool.sol";
import "./IERC721PoolFactory.sol";

/// @title ERC721PoolFactory
/// @author Hifi
contract ERC721PoolFactory is IERC721PoolFactory, Ownable {
    /// PUBLIC STORAGE ///

    /// @inheritdoc IERC721PoolFactory
    mapping(address => address) public override getPool;

    /// @inheritdoc IERC721PoolFactory
    address[] public allPools;

    /// @inheritdoc IERC721PoolFactory
    uint256 public nonce = 0;

    /// PUBLIC CONSTANT FUNCTIONS ///

    /// @inheritdoc IERC721PoolFactory
    function allPoolsLength() external view override returns (uint256) {
        return allPools.length;
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IERC721PoolFactory
    function createPool(address asset) external override {
        if (!IERC165(asset).supportsInterface(type(IERC721Metadata).interfaceId)) {
            revert ERC721PoolFactory__DoesNotImplementIERC721Metadata();
        }
        if (getPool[asset] != address(0)) {
            revert ERC721PoolFactory__PoolAlreadyExists();
        }

        string memory name = string.concat(IERC721Metadata(asset).name(), " Pool");
        string memory symbol = string.concat(IERC721Metadata(asset).symbol(), "p");

        bytes32 salt = keccak256(abi.encodePacked(asset, nonce));
        nonce++;
        ERC721Pool pool = new ERC721Pool{ salt: salt }();
        pool.initialize(name, symbol, asset);

        getPool[asset] = address(pool);
        allPools.push(address(pool));

        emit CreatePool(name, symbol, asset, address(pool));
    }

    /// @inheritdoc IERC721PoolFactory
    function rescueLastNFT(address asset, address to) external override onlyOwner {
        address poolAddress = getPool[asset];
        if (poolAddress == address(0)) {
            revert ERC721PoolFactory__PoolDoesNotExist();
        }
        if (to == address(0)) {
            revert ERC721PoolFactory__RecipientZeroAddress();
        }
        ERC721Pool pool = ERC721Pool(poolAddress);
        pool.rescueLastNFT(to);
        delete getPool[asset];
    }

    /// @inheritdoc IERC721PoolFactory
    function setENSName(
        address asset,
        address registrar,
        string memory name
    ) external override onlyOwner {
        if (getPool[asset] == address(0)) {
            revert ERC721PoolFactory__PoolDoesNotExist();
        }
        if (registrar == address(0)) {
            revert ERC721PoolFactory__RegistrarZeroAddress();
        }
        ERC721Pool pool = ERC721Pool(getPool[asset]);
        pool.setENSName(registrar, name);
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.4;

import "@ensdomains/ens-contracts/contracts/registry/IReverseRegistrar.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./IERC721Pool.sol";
import "./ERC20Wnft.sol";

/// @title ERC721Pool
/// @author Hifi

contract ERC721Pool is IERC721Pool, ERC20Wnft {
    using EnumerableSet for EnumerableSet.UintSet;

    /// PUBLIC STORAGE ///

    /// @inheritdoc IERC721Pool
    bool public poolFrozen;

    /// INTERNAL STORAGE ///

    /// @dev The asset token IDs held in the pool.
    EnumerableSet.UintSet internal holdings;

    /// CONSTRUCTOR ///

    constructor() ERC20Wnft() {
        // solhint-disable-previous-line no-empty-blocks
    }

    /// MODIFIERS ///

    /// @notice Ensures that the pool is not frozen.
    modifier notFrozen() {
        if (poolFrozen) {
            revert ERC721Pool__PoolFrozen();
        }
        _;
    }

    /// @notice Ensures that the caller is the factory.
    modifier onlyFactory() {
        if (msg.sender != factory) {
            revert ERC721Pool__CallerNotFactory({ factory: factory, caller: msg.sender });
        }
        _;
    }

    /// PUBLIC CONSTANT FUNCTIONS ///

    /// @inheritdoc IERC721Pool
    function holdingAt(uint256 index) external view override returns (uint256) {
        return holdings.at(index);
    }

    function holdingContains(uint256 id) external view override returns (bool) {
        return holdings.contains(id);
    }

    /// @inheritdoc IERC721Pool
    function holdingsLength() external view override returns (uint256) {
        return holdings.length();
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IERC721Pool
    function deposit(uint256 id, address beneficiary) external override notFrozen {
        // Checks: beneficiary is not zero address
        if (beneficiary == address(0)) {
            revert ERC721Pool__ZeroAddress();
        }
        // Checks: Add a NFT to the holdings.
        if (!holdings.add(id)) {
            revert ERC721Pool__NFTAlreadyInPool(id);
        }

        // Interactions: perform the Erc721 transfer from caller.
        IERC721(asset).transferFrom(msg.sender, address(this), id);

        // Effects: Mint an equivalent amount of pool tokens to the beneficiary.
        _mint(beneficiary, 10**18);

        emit Deposit(id, beneficiary, msg.sender);
    }

    /// @inheritdoc IERC721Pool
    function rescueLastNFT(address to) external override onlyFactory {
        // Checks: The pool must contain exactly one NFT.
        if (holdings.length() != 1) {
            revert ERC721Pool__MustContainExactlyOneNFT();
        }
        uint256 lastNFT = holdings.at(0);

        // Effects: Remove lastNFT from the holdings.
        holdings.remove(lastNFT);

        // Interactions: Transfer the NFT to the specified address.
        IERC721(asset).transferFrom(address(this), to, lastNFT);

        // Effects: Freeze the pool.
        poolFrozen = true;

        emit RescueLastNFT(lastNFT, to);
    }

    /// @inheritdoc IERC721Pool
    function setENSName(address registrar, string memory name) external override onlyFactory returns (bytes32) {
        bytes32 nodeHash = IReverseRegistrar(registrar).setName(name);
        emit ENSNameSet(registrar, name, nodeHash);
        return nodeHash;
    }

    /// @inheritdoc IERC721Pool
    function withdraw(uint256 id, address beneficiary) public override notFrozen {
        // Checks: Remove the NFT from the holdings.
        if (!holdings.remove(id)) {
            revert ERC721Pool__NFTNotFoundInPool(id);
        }

        // Effects: Burn an equivalent amount of pool token from the caller.
        // `msg.sender` is the caller of this function. Pool tokens are burnt from their account.
        _burn(msg.sender, 10**18);

        // Interactions: Perform the ERC721 transfer from the pool to the beneficiary address.
        IERC721(asset).transferFrom(address(this), beneficiary, id);

        emit Withdraw(id, beneficiary, msg.sender);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title IERC721PoolFactory
/// @author Hifi
interface IERC721PoolFactory {
    /// CUSTOM ERRORS ///

    error ERC721PoolFactory__DoesNotImplementIERC721Metadata();
    error ERC721PoolFactory__PoolAlreadyExists();
    error ERC721PoolFactory__PoolDoesNotExist();
    error ERC721PoolFactory__RecipientZeroAddress();
    error ERC721PoolFactory__RegistrarZeroAddress();

    /// EVENTS ///

    /// @notice Emitted when a new pool is created.
    /// @param name The ERC-20 name of the pool.
    /// @param symbol The ERC-20 symbol of the pool.
    /// @param asset The underlying ERC-721 asset contract address.
    /// @param pool The created pool contract address.
    event CreatePool(string name, string symbol, address indexed asset, address indexed pool);

    /// CONSTANT FUNCTIONS ///

    /// @notice Returns the pool of the given asset token.
    /// @param asset The underlying ERC-721 asset contract address.
    function getPool(address asset) external view returns (address pool);

    /// @notice Returns the list of all pools.
    function allPools(uint256) external view returns (address pool);

    /// @notice Returns the length of the pools list.
    function allPoolsLength() external view returns (uint256);

    /// @notice Returns the nonce used to calculate the salt for deploying new pools.
    /// @dev The nonce ensures that each new pool contract is deployed at a unique address.
    function nonce() external view returns (uint256);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Create a new pool.
    ///
    /// @dev Emits a {CreatePool} event.
    ///
    /// @dev Requirements:
    /// - Can only create one pool per asset.
    ///
    /// @param asset The underlying ERC-721 asset contract address.
    function createPool(address asset) external;

    /// @notice Rescue the last NFT of a pool.
    ///
    /// @dev Emits a {RescueLastNFT} event.
    ///
    /// @dev Requirements:
    /// - Can only rescue the last NFT of a pool.
    /// - Can only be called by the owner.
    /// - The pool must exist.
    ///
    /// @param asset The underlying ERC-721 asset contract address.
    /// @param to The address to which the NFT will be sent.
    function rescueLastNFT(address asset, address to) external;

    /// @notice Set the ENS name of a pool.
    ///
    /// @dev Requirements:
    /// - Can only be called by the owner.
    /// - The pool must exist.
    ///
    /// @param asset The underlying ERC-721 asset contract address.
    /// @param registrar The ENS registrar address.
    /// @param name The ENS name.
    function setENSName(
        address asset,
        address registrar,
        string memory name
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

pragma solidity >=0.8.4;

interface IReverseRegistrar {
    function setDefaultResolver(address resolver) external;

    function claim(address owner) external returns (bytes32);

    function claimForAddr(
        address addr,
        address owner,
        address resolver
    ) external returns (bytes32);

    function claimWithResolver(
        address owner,
        address resolver
    ) external returns (bytes32);

    function setName(string memory name) external returns (bytes32);

    function setNameForAddr(
        address addr,
        address owner,
        address resolver,
        string memory name
    ) external returns (bytes32);

    function node(address addr) external pure returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.4;

import "./IERC20Wnft.sol";

/// @title IERC721Pool
/// @author Hifi
interface IERC721Pool is IERC20Wnft {
    /// CUSTOM ERRORS ///

    error ERC721Pool__CallerNotFactory(address factory, address caller);
    error ERC721Pool__MustContainExactlyOneNFT();
    error ERC721Pool__PoolFrozen();
    error ERC721Pool__NFTAlreadyInPool(uint256 id);
    error ERC721Pool__NFTNotFoundInPool(uint256 id);
    error ERC721Pool__ZeroAddress();

    /// EVENTS ///

    /// @notice Emitted when NFT are deposited and an equal amount of pool tokens are minted.
    /// @param id The asset token ID sent from the user's account to the pool.
    /// @param beneficiary The address to receive the pool tokens.
    /// @param caller The caller of the function equal to msg.sender.
    event Deposit(uint256 id, address beneficiary, address caller);

    /// @notice Emitted when the ENS name is set.
    /// @param registrar The address of the ENS registrar.
    /// @param name The ENS name.
    /// @param nodeHash The ENS node hash.
    event ENSNameSet(address registrar, string name, bytes32 nodeHash);

    /// @notice Emitted when the last NFT of a pool is rescued.
    /// @param lastNFT The last NFT of the pool.
    /// @param to The address to which the NFT was sent.
    event RescueLastNFT(uint256 lastNFT, address to);

    /// @notice Emitted when NFT are withdrawn from the pool in exchange for an equal amount of pool tokens.
    /// @param id The asset token IDs released from the pool.
    /// @param beneficiary The address to receive the NFT.
    /// @param caller The caller of the function equal to msg.sender.
    event Withdraw(uint256 id, address beneficiary, address caller);

    /// CONSTANT FUNCTIONS ///

    /// @notice Returns the asset token ID held at index.
    /// @param index The index to check.
    function holdingAt(uint256 index) external view returns (uint256);

    /// @notice Returns true if the asset token ID is held in the pool.
    /// @param id The asset token ID to check.
    function holdingContains(uint256 id) external view returns (bool);

    /// @notice Returns the total number of asset token IDs held.
    function holdingsLength() external view returns (uint256);

    /// @notice A boolean flag indicating whether the pool is frozen.
    function poolFrozen() external view returns (bool);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Deposit NFT in exchange for an equivalent amount of pool tokens.
    ///
    /// @dev Emits a {Deposit} event.
    ///
    /// @dev Requirements:
    /// - The caller must have allowed the Pool to transfer the NFT.
    /// - The pool must not be frozen.
    /// - The address `beneficiary` must not be the zero address.
    ///
    /// @param id The asset token ID sent from the user's account to the pool.
    /// @param beneficiary The address to receive the pool tokens. Can be the caller themselves or any other address.
    function deposit(uint256 id, address beneficiary) external;

    /// @notice Allows the factory to rescue the last NFT in the pool and set the pool to frozen.
    ///
    /// Emits a {RescueLastNFT} event.
    ///
    /// @dev Requirements:
    /// - The caller must be the factory.
    /// - The pool must only hold one NFT.
    ///
    /// @param to The address to send the NFT to.
    function rescueLastNFT(address to) external;

    /// @notice Allows the factory to set the ENS name for the pool.
    ///
    /// Emits a {ENSNameSet} event.
    ///
    /// @dev Requirements:
    /// - The caller must be the factory.
    ///
    /// @param registrar The address of the ENS registrar.
    /// @param name The name to set.
    /// @return The ENS node hash.
    function setENSName(address registrar, string memory name) external returns (bytes32);

    /// @notice Withdraws a specified NFT in exchange for an equivalent amount of pool tokens.
    ///
    /// @dev Emits a {Withdraw} event.
    ///
    /// @dev Requirements:
    /// - The pool must not be frozen.
    /// - The address `beneficiary` must not be the zero address.
    /// - The specified NFT must be held in the pool.
    /// - The caller must hold the equivalent amount of pool tokens
    ///
    /// @param id The asset token ID to be released from the pool.
    /// @param beneficiary The address to receive the NFT. Can be the caller themselves or any other address.
    function withdraw(uint256 id, address beneficiary) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.4;

import "./IERC20Wnft.sol";

/// @title ERC20Wnft
/// @author Hifi
contract ERC20Wnft is IERC20Wnft {
    /// PUBLIC STORAGE ///

    /// @inheritdoc IERC20
    uint256 public override totalSupply;

    /// @inheritdoc IERC20
    mapping(address => uint256) public override balanceOf;

    /// @inheritdoc IERC20
    mapping(address => mapping(address => uint256)) public override allowance;

    /// @inheritdoc IERC20Metadata
    string public override name;

    /// @inheritdoc IERC20Metadata
    string public override symbol;

    /// @inheritdoc IERC20Metadata
    uint8 public constant override decimals = 18;

    /// @dev version
    string public constant version = "1";

    /// @inheritdoc IERC20Permit
    bytes32 public override DOMAIN_SEPARATOR;
    // solhint-disable-previous-line var-name-mixedcase

    /// @inheritdoc IERC20Permit
    mapping(address => uint256) public override nonces;

    /// @dev keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @inheritdoc IERC20Wnft
    address public override asset;

    /// @inheritdoc IERC20Wnft
    address public immutable override factory;

    /// CONSTRUCTOR ///

    constructor() {
        factory = msg.sender;
    }

    /// PUBLIC NON-CONSTANT FUNCTIONS ///

    /// @inheritdoc IERC20Wnft
    function initialize(
        string memory name_,
        string memory symbol_,
        address asset_
    ) public override {
        if (msg.sender != factory) {
            revert ERC20Wnft__Forbidden();
        }
        name = name_;
        symbol = symbol_;
        asset = asset_;

        uint256 chainId;
        assembly {
            // solhint-disable-previous-line no-inline-assembly
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                address(this)
            )
        );
        emit Initialize(name, symbol, asset);
    }

    /// @inheritdoc IERC20
    function approve(address spender, uint256 value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /// @inheritdoc IERC20
    function transfer(address to, uint256 value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /// @inheritdoc IERC20
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender] - value;
        }
        _transfer(from, to, value);
        return true;
    }

    /// @inheritdoc IERC20Permit
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override {
        if (deadline < block.timestamp) {
            revert ERC20Wnft__PermitExpired();
        }
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        if (recoveredAddress == address(0) || recoveredAddress != owner) {
            revert ERC20Wnft__InvalidSignature();
        }
        _approve(owner, spender, value);
    }

    /// INTERNAL NON-CONSTANT FUNCTIONS ///

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply + value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from] - value;
        totalSupply = totalSupply - value;
        emit Transfer(from, address(0), value);
    }

    /// @dev See the documentation for the public functions that call this internal function.
    function permitInternal(
        uint256 amount,
        uint256 deadline,
        bytes memory signature
    ) internal {
        if (signature.length > 0) {
            bytes32 r;
            bytes32 s;
            uint8 v;

            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            permit(msg.sender, address(this), amount, deadline, v, r, s);
        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] = balanceOf[from] - value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(from, to, value);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

/// @title IERC20Wnft
/// @author Hifi
interface IERC20Wnft is IERC20Permit, IERC20Metadata {
    /// CUSTOM ERRORS ///

    error ERC20Wnft__Forbidden();
    error ERC20Wnft__InvalidSignature();
    error ERC20Wnft__PermitExpired();

    /// EVENTS ///

    /// @notice Emitted when the contract is initialized.
    /// @param name The ERC-20 name.
    /// @param symbol The ERC-20 symbol.
    /// @param asset The underlying ERC-721 asset contract address.
    event Initialize(string name, string symbol, address indexed asset);

    /// CONSTANT FUNCTIONS ///

    /// @notice Returns the address of the underlying ERC-721 asset.
    function asset() external view returns (address);

    /// @notice Returns the factory contract address.
    function factory() external view returns (address);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Initializes the contract with the given values.
    ///
    /// @dev Emits an {Initialize} event.
    ///
    /// @dev Requirements:
    /// - Can only be called by the factory.
    ///
    /// @param name The ERC-20 name.
    /// @param symbol The ERC-20 symbol.
    /// @param asset The underlying ERC-721 asset contract address.
    function initialize(
        string memory name,
        string memory symbol,
        address asset
    ) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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
interface IERC165Upgradeable {
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
 */
library EnumerableSetUpgradeable {
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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
     * @dev Returns the number of values on the set. O(1).
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
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';
import './Factories/FactoryStorage.sol';
import './Factories/IFactoryConsumer.sol';

contract BeyondFactories is OwnableUpgradeable, PausableUpgradeable, FactoryStorage {
	using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

	// emitted when a factory is created
	event FactoryCreated(uint256 indexed id, address indexed creator, string metadata);

	// emitted when factories are updated (active, paused, price, metadata...)
	event FactoriesUpdate(uint256[] factoryIds);

	// emitted when a factory has reached its max supply
	event FactoryOut(uint256 indexed id);

	// emitted when a donation recipient is created or modified
	event DonationRecipientsUpdate(uint256[] ids);

	// emitted when configuration changed
	event ConfigurationUpdate();

	// emitted when a tokenId is minted from a factory
	event MintFromFactory(
		uint256 indexed factoryId,
		address indexed minter,
		uint256 createdIndex, // index in factory
		address registry,
		uint256 tokenId,
		bytes32 data,
		string seed,
		uint256 price
	);

	/**
	 * @dev initialize function
	 */
	function initialize(
		address payable platformBeneficiary,
		uint16 platformFee,
		uint16 donationMinimum,
		bool restricted,
		bool defaultActive,
		bool canEditPlatformFees,
		address ownedBy
	) public initializer {
		__Ownable_init();
		__Pausable_init();

		contractConfiguration.platformBeneficiary = platformBeneficiary;
		contractConfiguration.platformFee = platformFee;
		contractConfiguration.donationMinimum = donationMinimum;
		contractConfiguration.canEditPlatformFees = canEditPlatformFees;

		// defines if factory are active by defualt or not
		contractConfiguration.defaultFactoryActivation = defaultActive;

		// if the factory is restricted
		contractConfiguration.restricted = restricted;

		if (address(0) != ownedBy) {
			transferOwnership(ownedBy);
		}
	}

	/**
	 * @dev called by creators or admin to register a new factory
	 *
	 * @param factoryType - if unique (erc721) or edition (erc1155)
	 * @param creator - the factory creator, is used when contract is restricted
	 * @param paused - if the factory starts paused
	 * @param price - factory price, in wei
	 * @param maxSupply - times this factory can be used; 0 = inifinity
	 * @param withSeed - if the factory needs a seed when creating
	 * @param metadata - factory metadata uri - ipfs uri most of the time
	 */
	function registerFactory(
		FactoryType factoryType, // if erc721 or erc1155
		address creator,
		bool paused, // if the factory start paused
		uint256 price, // factory price, in wei
		uint256 maxSupply, // max times this factory can be used; 0 = inifinity
		bool withSeed, // if the factory needs a seed when creating
		string memory metadata,
		uint256 royaltyValue,
		address consumer
	) external {
		require(bytes(metadata).length > 0, 'Need metadata URI');
		ContractConfiguration memory _configuration = contractConfiguration;
		require(!_configuration.restricted || owner() == _msgSender(), 'Restricted.');

		// Restricted contracts only allow OPERATORS to mint
		if (creator == address(0)) {
			creator = msg.sender;
		}

		// if no consumer given, take one of the default
		if (consumer == address(0)) {
			if (factoryType == FactoryType.Unique) {
				consumer = _configuration.uniqueConsumer;
			} else {
				consumer = _configuration.editionsConsumer;
			}
		}

		uint256 factoryId = factoriesCount + 1;
		factories[factoryId] = Factory({
			factoryType: factoryType,
			creator: creator,
			active: _configuration.defaultFactoryActivation,
			paused: paused,
			price: price,
			maxSupply: maxSupply,
			withSeed: withSeed,
			royaltyValue: royaltyValue,
			metadata: metadata,
			created: 0,
			consumer: consumer,
			donationId: 0,
			donationAmount: _configuration.donationMinimum
		});
		factoriesCount = factoryId;

		emit FactoryCreated(factoryId, creator, metadata);
	}

	/**
	 * @dev Function to mint a token without any seed
	 *
	 * @param factoryId id of the factory to mint from
	 * @param amount - amount to mint; only for Editions factories
	 * @param to - address to mint to, if address(0), msg.sender
	 * @param swapContract - address of the contract if this is a swap
	 * @param swapTokenId - id of the token if it's a swap
	 */
	function mintFrom(
		uint256 factoryId,
		uint256 amount,
		address to,
		address swapContract,
		uint256 swapTokenId
	) external payable {
		_mintFromFactory(factoryId, '', '', amount, to, swapContract, swapTokenId);
	}

	/**
	 * @dev Function to mint a token from a factory with a 32 bytes hex string as has
	 *
	 * @param factoryId id of the factory to mint from
	 * @param seed The hash used to create the seed
	 * @param amount - amount to mint; only for Editions factories
	 * @param to - address to mint to, if address(0), msg.sender
	 * @param swapContract - address of the contract if this is a swap
	 * @param swapTokenId - id of the token if it's a swap
	 *
	 * Seed will be used to create, off-chain, the token unique seed with the function:
	 * tokenSeed = sha3(blockHash, factoryId, createdIndex, minter, registry, tokenId, seed)
	 *
	 * There is as much chance of collision than there is on creating a duplicate
	 * of an ethereum private key, which is low enough to not go to crazy length in
	 * order to try to stop the "almost impossible"
	 *
	 * I thought about using a commit/reveal (revealed at the time of nft metadata creation)
	 * But this could break the token generation if, for example, the reveal was lost (db problem)
	 * between the function call and the reveal.
	 *
	 *
	 * All in all, using the blockhash in the seed makes this as secure as "on-chain pseudo rng".
	 *
	 * Also with this method, all informations to recreate the token can always be retrieved from the events.
	 */
	function mintWithHash(
		uint256 factoryId,
		bytes32 seed,
		uint256 amount,
		address to,
		address swapContract,
		uint256 swapTokenId
	) external payable {
		require(seed != 0x0, 'Invalid seed');
		_mintFromFactory(factoryId, seed, '', amount, to, swapContract, swapTokenId);
	}

	/**
	 * @dev Function to mint a token from a factory with a known seed
	 *
	 * This known seed can either be:
	 * - a user inputed seed
	 * - the JSON string of the factory properties. Allowing for future reconstruction of nft metadata if needed
	 *
	 * @param factoryId id of the factory to mint from
	 * @param seed The seed used to mint
	 * @param amount - amount to mint; only for Editions factories
	 * @param to - address to mint to, if address(0), msg.sender
	 * @param swapContract - address of the contract if this is a swap
	 * @param swapTokenId - id of the token if it's a swap
	 */
	function mintWithOpenSeed(
		uint256 factoryId,
		string memory seed,
		uint256 amount,
		address to,
		address swapContract,
		uint256 swapTokenId
	) external payable {
		require(bytes(seed).length > 0, 'Invalid seed');
		_mintFromFactory(
			factoryId,
			keccak256(abi.encodePacked(seed)),
			seed,
			amount,
			to,
			swapContract,
			swapTokenId
		);
	}

	/**
	 * @dev allows a creator to pause / unpause the use of their Factory
	 */
	function setFactoryPause(uint256 factoryId, bool isPaused) external {
		Factory storage factory = factories[factoryId];
		require(msg.sender == factory.creator, 'Not factory creator');
		factory.paused = isPaused;

		emit FactoriesUpdate(_asSingletonArray(factoryId));
	}

	/**
	 * @dev allows a creator to update the price of their factory
	 */
	function setFactoryPrice(uint256 factoryId, uint256 price) external {
		Factory storage factory = factories[factoryId];
		require(msg.sender == factory.creator, 'Not factory creator');
		factory.price = price;

		emit FactoriesUpdate(_asSingletonArray(factoryId));
	}

	/**
	 * @dev allows a creator to define a swappable factory
	 */
	function setFactorySwap(
		uint256 factoryId,
		address swapContract,
		uint256 swapTokenId,
		bool fixedId
	) external {
		Factory storage factory = factories[factoryId];
		require(msg.sender == factory.creator, 'Not factory creator');
		if (swapContract == address(0)) {
			delete factorySwap[factoryId];
		} else {
			factorySwap[factoryId] = TokenSwap({
				is1155: IERC1155Upgradeable(swapContract).supportsInterface(0xd9b67a26),
				fixedId: fixedId,
				swapContract: swapContract,
				swapTokenId: swapTokenId
			});
		}

		emit FactoriesUpdate(_asSingletonArray(factoryId));
	}

	/**
	 * @dev allows a creator to define to which orga they want to donate if not automatic
	 * and how much (minimum 2.50, taken from the BeyondNFT 10%)
	 *
	 * Be careful when using this:
	 * - if donationId is 0, then the donation will be automatic
	 * if you want to set a specific donation id, always use id + 1
	 */
	function setFactoryDonation(
		uint256 factoryId,
		uint256 donationId,
		uint16 donationAmount
	) external {
		Factory storage factory = factories[factoryId];
		require(msg.sender == factory.creator, 'Not factory creator');

		// if 0, set automatic;
		factory.donationId = donationId;

		// 2.50 is the minimum that can be set
		// those 2.50 are taken from BeyondNFT share of 10%
		if (donationAmount >= contractConfiguration.donationMinimum) {
			factory.donationAmount = donationAmount;
		}

		emit FactoriesUpdate(_asSingletonArray(factoryId));
	}

	/**
	 * @dev allows to activate and deactivate factories
	 *
	 * Because BeyondNFT is an open platform with no curation prior factory creation
	 * This can only be called by BeyondNFT administrators, if there is any abuse with a factory
	 */
	function setFactoryActiveBatch(uint256[] memory factoryIds, bool[] memory areActive)
		external
		onlyOwner
	{
		for (uint256 i; i < factoryIds.length; i++) {
			Factory storage factory = factories[factoryIds[i]];
			require(address(0) != factory.creator, 'Factory not found');

			factory.active = areActive[i];
		}
		emit FactoriesUpdate(factoryIds);
	}

	/**
	 * @dev allows to set a factory consumer
	 */
	function setFactoryConsumerBatch(uint256[] memory factoryIds, address[] memory consumers)
		external
		onlyOwner
	{
		for (uint256 i; i < factoryIds.length; i++) {
			Factory storage factory = factories[factoryIds[i]];
			require(address(0) != factory.creator, 'Factory not found');

			factory.consumer = consumers[i];
		}
		emit FactoriesUpdate(factoryIds);
	}

	/**
	 * @dev adds Donation recipients
	 */
	function addDonationRecipientsBatch(
		address[] memory recipients,
		string[] memory names,
		bool[] memory autos
	) external onlyOwner {
		DonationRecipient[] storage donationRecipients_ = donationRecipients;
		EnumerableSetUpgradeable.UintSet storage autoDonations_ = autoDonations;
		uint256[] memory ids = new uint256[](recipients.length);
		for (uint256 i; i < recipients.length; i++) {
			require(bytes(names[i]).length > 0, 'Invalid name');
			donationRecipients_.push(
				DonationRecipient({
					autoDonation: autos[i],
					recipient: recipients[i],
					name: names[i]
				})
			);
			ids[i] = donationRecipients_.length - 1;
			if (autos[i]) {
				autoDonations_.add(ids[i]);
			}
		}
		emit DonationRecipientsUpdate(ids);
	}

	/**
	 * @dev modify Donation recipients
	 */
	function setDonationRecipientBatch(
		uint256[] memory ids,
		address[] memory recipients,
		string[] memory names,
		bool[] memory autos
	) external onlyOwner {
		DonationRecipient[] storage donationRecipients_ = donationRecipients;
		EnumerableSetUpgradeable.UintSet storage autoDonations_ = autoDonations;
		for (uint256 i; i < recipients.length; i++) {
			if (address(0) != recipients[i]) {
				donationRecipients_[ids[i]].recipient = recipients[i];
			}

			if (bytes(names[i]).length > 0) {
				donationRecipients_[ids[i]].name = names[i];
			}

			donationRecipients_[ids[i]].autoDonation = autos[i];
			if (autos[i]) {
				autoDonations_.add(ids[i]);
			} else {
				autoDonations_.remove(ids[i]);
			}
		}

		emit DonationRecipientsUpdate(ids);
	}

	/**
	 * @dev allows to update a factory metadata
	 *
	 * This can only be used by admins in very specific cases when a critical bug is found
	 */
	function setFactoryMetadata(uint256 factoryId, string memory metadata) external onlyOwner {
		Factory storage factory = factories[factoryId];
		require(address(0) != factory.creator, 'Factory not found');
		factory.metadata = metadata;

		emit FactoriesUpdate(_asSingletonArray(factoryId));
	}

	function setPlatformFee(uint16 fee) external onlyOwner {
		require(contractConfiguration.canEditPlatformFees == true, "Can't edit platform fees");
		require(fee <= 10000, 'Fees too high');
		contractConfiguration.platformFee = fee;
		emit ConfigurationUpdate();
	}

	function setPlatformBeneficiary(address payable beneficiary) external onlyOwner {
		require(contractConfiguration.canEditPlatformFees == true, "Can't edit platform fees");
		require(address(beneficiary) != address(0), 'Invalid beneficiary');
		contractConfiguration.platformBeneficiary = beneficiary;
		emit ConfigurationUpdate();
	}

	function setDefaultFactoryActivation(bool isDefaultActive) external onlyOwner {
		contractConfiguration.defaultFactoryActivation = isDefaultActive;
		emit ConfigurationUpdate();
	}

	function setRestricted(bool restricted) external onlyOwner {
		contractConfiguration.restricted = restricted;
		emit ConfigurationUpdate();
	}

	function setFactoriesConsumers(address unique, address editions) external onlyOwner {
		if (address(0) != unique) {
			contractConfiguration.uniqueConsumer = unique;
		}

		if (address(0) != editions) {
			contractConfiguration.editionsConsumer = editions;
		}

		emit ConfigurationUpdate();
	}

	/**
	 * @dev Pauses all token creation.
	 *
	 * Requirements:
	 *
	 * - the caller must have the `DEFAULT_ADMIN_ROLE`.
	 */
	function pause() public virtual onlyOwner {
		_pause();
	}

	/**
	 * @dev Unpauses all token creation.
	 *
	 * Requirements:
	 *
	 * - the caller must have the `DEFAULT_ADMIN_ROLE`.
	 */
	function unpause() public virtual onlyOwner {
		_unpause();
	}

	/**
	 * @dev This function does the minting process.
	 * It checkes that the factory exists, and if there is a seed, that it wasn't already
	 * used for it.
	 *
	 * Depending on the factory type, it will call the right contract to mint the token
	 * to msg.sender
	 *
	 * Requirements:
	 * - contract musn't be paused
	 * - If there is a seed, it must not have been used for this Factory
	 */
	function _mintFromFactory(
		uint256 factoryId,
		bytes32 seed,
		string memory openSeed,
		uint256 amount,
		address to,
		address swapContract,
		uint256 swapTokenId
	) internal whenNotPaused {
		require(amount >= 1, 'Amount is zero');

		Factory storage factory = factories[factoryId];

		require(factory.active && !factory.paused, 'Factory inactive or not found');
		require(
			factory.maxSupply == 0 || factory.created < factory.maxSupply,
			'Factory max supply reached'
		);

		// if the factory requires a seed (user seed, random seed)
		if (factory.withSeed) {
			// verify that the seed is not empty and that it was never used before
			// for this factory
			require(
				seed != 0x0 && factoriesSeed[factoryId][seed] == false,
				'Invalid seed or already taken'
			);
			factoriesSeed[factoryId][seed] = true;
		}

		factory.created++;

		address consumer = _doPayment(factoryId, factory, swapContract, swapTokenId);

		// if people mint to another address
		if (to == address(0)) {
			to = msg.sender;
		}

		uint256 tokenId =
			IFactoryConsumer(consumer).mint(
				to,
				factoryId,
				amount,
				factory.creator,
				factory.royaltyValue
			);

		// emit minting from factory event with data and seed
		emit MintFromFactory(
			factoryId,
			to,
			factory.created,
			consumer,
			tokenId,
			seed,
			openSeed,
			msg.value
		);

		if (factory.created == factory.maxSupply) {
			emit FactoryOut(factoryId);
		}
	}

	function _doPayment(
		uint256 factoryId,
		Factory storage factory,
		address swapContract,
		uint256 swapTokenId
	) internal returns (address) {
		ContractConfiguration memory contractConfiguration_ = contractConfiguration;
		// try swap
		if (swapContract != address(0)) {
			TokenSwap memory swap = factorySwap[factoryId];

			// verify that the swap asked is the right one
			require(
				// contract match
				swap.swapContract == swapContract &&
					// and either ANY idea id works, either the given ID is the right one
					(!swap.fixedId || swap.swapTokenId == swapTokenId),
				'Invalid swap'
			);
			require(msg.value == 0, 'No value allowed when swapping');

			// checking if ERC1155 or ERC721
			// and burn the tokenId
			// using 0xdead address to be sure it works with contracts
			// that have no burn function
			//
			// those functions calls should revert if there is a problem when transfering
			if (swap.is1155) {
				IERC1155Upgradeable(swapContract).safeTransferFrom(
					msg.sender,
					address(0xdEaD),
					swapTokenId,
					1,
					''
				);
			} else {
				IERC721Upgradeable(swapContract).transferFrom(
					msg.sender,
					address(0xdEaD),
					swapTokenId
				);
			}
		} else if (factory.price > 0) {
			require(msg.value == factory.price, 'Wrong value sent');

			uint256 platformFee = (msg.value * uint256(contractConfiguration_.platformFee)) / 10000;

			DonationRecipient[] memory donationRecipients_ = donationRecipients;
			uint256 donation;
			if (donationRecipients_.length > 0) {
				donation = (msg.value * uint256(factory.donationAmount)) / 10000;

				// send fees to platform
				contractConfiguration_.platformBeneficiary.transfer(platformFee);

				if (factory.donationId > 0) {
					payable(donationRecipients_[factory.donationId - 1].recipient).transfer(
						donation
					);
				} else {
					// send to current cursor
					EnumerableSetUpgradeable.UintSet storage autoDonations_ = autoDonations;

					payable(donationRecipients_[autoDonations_.at(donationCursor)].recipient)
						.transfer(donation);
					donationCursor = (donationCursor + 1) % autoDonations_.length();
				}
			}

			// send rest to creator
			payable(factory.creator).transfer(msg.value - platformFee - donation);
		}

		if (factory.consumer != address(0)) {
			return factory.consumer;
		}

		return
			factory.factoryType == FactoryType.Multiple
				? contractConfiguration_.editionsConsumer
				: contractConfiguration_.uniqueConsumer;
	}

	function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
		uint256[] memory array = new uint256[](1);
		array[0] = element;

		return array;
	}

	/**
	 * @dev do not accept value sent directly to contract
	 */
	receive() external payable {
		revert('No value accepted');
	}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';

contract FactoryStorage {
	enum FactoryType {Unique, Multiple}

	struct DonationRecipient {
		bool autoDonation;
		address recipient;
		string name;
	}

	struct TokenSwap {
		bool is1155;
		bool fixedId;
		address swapContract;
		uint256 swapTokenId;
	}

	struct Factory {
		// factory type
		FactoryType factoryType;
		// factory creator
		address creator;
		// if factory is active or not
		// this is changed by beyondNFT admins if abuse with factories
		bool active;
		// if factory is paused or not <- this is changed by creator
		bool paused;
		// if the factory requires a seed
		bool withSeed;
		// the contract this factory mint with
		address consumer;
		// donation amount, 2.5% (250) is the minimum amount
		uint16 donationAmount;
		// id of the donation recipient for this factory
		// this id must be id + 1, so 0 can be considered as automatic
		uint256 donationId;
		// price to mint
		uint256 price;
		// how many were minted already
		uint256 created;
		// 0 if infinite
		uint256 maxSupply;
		// royalties
		uint256 royaltyValue;
		// The factory metadata uri, contains all informations about where to find code, properties etc...
		// this is the base that will be used to create NFTs
		string metadata;
	}

	struct ContractConfiguration {
		bool restricted;
		bool defaultFactoryActivation;
		address uniqueConsumer;
		address editionsConsumer;
		bool canEditPlatformFees;
		uint16 platformFee;
		uint16 donationMinimum;
		address payable platformBeneficiary;
	}

	ContractConfiguration public contractConfiguration;

	uint256 public factoriesCount;

	// the factories
	mapping(uint256 => Factory) public factories;

	// some factories allow to swap other contracts token again one from the factory
	mapping(uint256 => TokenSwap) public factorySwap;

	// the seeds already used by each factories
	// not in the struct as it complicated things
	mapping(uint256 => mapping(bytes32 => bool)) public factoriesSeed;

	DonationRecipient[] public donationRecipients;

	uint256 donationCursor;
	EnumerableSetUpgradeable.UintSet internal autoDonations;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFactoryConsumer {
	function mint(
		address creator,
		uint256 factoryId,
		uint256 amount,
		address royaltyRecipient,
		uint256 royaltyValue
	) external returns (uint256);
}
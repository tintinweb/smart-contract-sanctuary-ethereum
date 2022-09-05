// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

abstract contract DaoCollateralWhitelist is ContextUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    struct CollateralWhitelist {
        // Token symbols to ERC20 Token contract addresses
        EnumerableSetUpgradeable.AddressSet tokens;
        // Token symbols to ERC20 Token contract addresses
        mapping(address => string) symbols;
    }

    event AddCollateralWhitelist(
        uint256 indexed daoId,
        address indexed collateralTokens,
        address indexed instigator
    );
    event RemoveCollateralWhitelist(
        uint256 indexed daoId,
        address indexed collateralTokens,
        address indexed instigator
    );

    /**
     * @notice Returns a list of the whitelisted tokens' symbols.
     *
     * @dev NOTE This is a convenience getter function, due to looking an unknown gas cost,
     *             never call within a transaction, only use a call from an EOA.
     *
     * @param daoId Internal ID of the DAO whose collateral symbol list is wanted.
     */
    function daoCollateralSymbolWhitelist(uint256 daoId)
        external
        view
        returns (string[] memory)
    {
        address[] memory keys = _daoCollateralWhitelist(daoId).tokens.values();
        string[] memory symbols = new string[](keys.length);
        for (uint256 i = 0; i < keys.length; i++) {
            symbols[i] = _daoCollateralWhitelist(daoId).symbols[keys[i]];
        }
        return symbols;
    }

    /**
     * @notice The whitelisted ERC20 token address associated for a symbol.
     *
     * @param daoId Internal ID of the DAO whose collateral whitelist list will be checked.
     * @return When present in the whitelist, the token address, otherwise address zero.
     */
    function isAllowedDaoCollateral(
        uint256 daoId,
        address erc20CollateralTokens
    ) public view returns (bool) {
        return _isDaoCollateralWhitelisted(daoId, erc20CollateralTokens);
    }

    //slither-disable-next-line naming-convention
    function __DaoCollateralWhitelist_init() internal onlyInitializing {}

    /**
     * @notice Performs whitelisting of the ERC20 collateral token.
     *
     * @dev Whitelists the collateral token, expecting the symbol is not already whitelisted.
     *
     * @param daoId Internal ID of the DAO whose collateral whitelist will be updated.
     * @param  erc20CollateralTokens IERC20MetadataUpgradeable contract to whitelist.
     */
    function _whitelistDaoCollateral(
        uint256 daoId,
        address erc20CollateralTokens
    ) internal {
        require(_isValidDaoId(daoId), "DAO Collateral: invalid DAO id");
        require(
            erc20CollateralTokens != address(0),
            "DAO Collateral: zero address"
        );
        require(
            !_isDaoCollateralWhitelisted(daoId, erc20CollateralTokens),
            "DAO Collateral: already present"
        );
        require(
            _daoCollateralWhitelist(daoId).tokens.add(erc20CollateralTokens),
            "DAO Collateral: failed to add"
        );
        _daoCollateralWhitelist(daoId).symbols[
            erc20CollateralTokens
        ] = IERC20MetadataUpgradeable(erc20CollateralTokens).symbol();

        emit AddCollateralWhitelist(daoId, erc20CollateralTokens, _msgSender());
    }

    /**
     * @notice Deletes a collateral token entry from the whitelist.
     *
     * @dev Expects the symbol to be an existing entry, otherwise reverts.
     *
     * @param daoId Internal ID of the DAO whose collateral whitelist will be updated.
     * @param  erc20CollateralTokens ERC20 contract to remove from the whitelist.
     */
    function _removeWhitelistedDaoCollateral(
        uint256 daoId,
        address erc20CollateralTokens
    ) internal {
        require(_isValidDaoId(daoId), "DAO Collateral: invalid DAO id");
        require(
            _isDaoCollateralWhitelisted(daoId, erc20CollateralTokens),
            "DAO Collateral: not whitelisted"
        );
        require(
            _daoCollateralWhitelist(daoId).tokens.remove(erc20CollateralTokens),
            "DAO Collateral: failed to remove"
        );

        delete _daoCollateralWhitelist(daoId).symbols[erc20CollateralTokens];

        emit RemoveCollateralWhitelist(
            daoId,
            erc20CollateralTokens,
            _msgSender()
        );
    }

    /**
     * @notice Provides access to the internal storage for the whitelist of collateral tokens for a single DAO.
     *
     * @dev Although a view modifier, the underlying storage may be altered, as in this case the view restriction
     *         applies to the reference rather than the addresses.
     *
     * @param daoId Internal ID of the DAO whose collateral whitelist will be retrieved.
     */
    //slither-disable-next-line dead-code
    function _daoCollateralWhitelist(uint256 daoId)
        internal
        view
        virtual
        returns (CollateralWhitelist storage);

    /**
     * @notice Whether a given DAO ID is currently associated with a currently live DAO.
     *
     * @dev At any moment, expect a range of IDs that have been assigned, with the possibility some DAOs within being
     *          deleted.
     *
     * @param daoId Internal ID of the DAO whose existence is to be determined.
     */
    //slither-disable-next-line dead-code
    function _isValidDaoId(uint256 daoId) internal view virtual returns (bool);

    /**
     * @notice Whether a contract address is a member of the set of whitelisted tokens for a DAO.
     *
     * @param daoId Internal ID of the DAO whose whitelist will be checked.
     * @param  erc20CollateralTokens address to determine whitelist membership.
     */
    function _isDaoCollateralWhitelisted(
        uint256 daoId,
        address erc20CollateralTokens
    ) private view returns (bool) {
        return
            _daoCollateralWhitelist(daoId).tokens.contains(
                erc20CollateralTokens
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
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
        return _values(set._inner);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./DaoCollateralWhitelist.sol";

abstract contract DaoConfiguration is DaoCollateralWhitelist {
    struct DaoConfig {
        // Address zero is an invalid address, can be used to identify null structs
        address treasury;
        string metaData;
        CollateralWhitelist whitelist;
    }

    mapping(uint256 => DaoConfig) private _daoConfig;
    uint256 private _daoConfigLastId;

    event DaoTreasuryUpdate(
        uint256 indexed daoId,
        address indexed treasury,
        address indexed instigator
    );

    event CreateDao(
        uint256 indexed id,
        address indexed treasury,
        address indexed instigator
    );

    event DaoMetaDataUpdate(
        uint256 indexed daoId,
        string data,
        address indexed instigator
    );

    function daoTreasury(uint256 daoId) external view returns (address) {
        return _daoConfig[daoId].treasury;
    }

    function daoMetaData(uint256 daoId) external view returns (string memory) {
        return _daoConfig[daoId].metaData;
    }

    function highestDaoId() external view returns (uint256) {
        return _daoConfigLastId;
    }

    /**
     * @notice The _msgSender() is given membership of all roles, to allow granting and future renouncing after others
     *      have been setup.
     */
    //slither-disable-next-line naming-convention
    function __DaoConfiguration_init() internal onlyInitializing {
        __DaoCollateralWhitelist_init();
    }

    function _daoConfiguration(address erc20CapableTreasury)
        internal
        returns (uint256)
    {
        require(
            erc20CapableTreasury != address(0),
            "DAO Treasury: address is zero"
        );

        _daoConfigLastId++;

        _setTreasury(_daoConfigLastId, erc20CapableTreasury);

        return _daoConfigLastId;
    }

    function _setDaoTreasury(uint256 daoId, address replacementTreasury)
        internal
    {
        require(_isValidDaoId(daoId), "DAO Treasury: invalid DAO Id");
        require(
            replacementTreasury != address(0),
            "DAO Treasury: address is zero"
        );
        require(
            _daoConfig[daoId].treasury != replacementTreasury,
            "DAO Treasury: identical address"
        );
        _setTreasury(daoId, replacementTreasury);
    }

    function _setDaoMetaData(uint256 daoId, string calldata replacementMetaData)
        internal
    {
        _daoConfig[daoId].metaData = replacementMetaData;
        emit DaoMetaDataUpdate(daoId, replacementMetaData, _msgSender());
    }

    function _daoCollateralWhitelist(uint256 daoId)
        internal
        view
        override
        returns (CollateralWhitelist storage)
    {
        return _daoConfig[daoId].whitelist;
    }

    function _daoTreasury(uint256 daoId) internal view returns (address) {
        return _daoConfig[daoId].treasury;
    }

    function _isValidDaoId(uint256 daoId)
        internal
        view
        override
        returns (bool)
    {
        return _daoConfig[daoId].treasury != address(0);
    }

    function _setTreasury(uint256 daoId, address treasury) private {
        _daoConfig[daoId].treasury = treasury;
        emit DaoTreasuryUpdate(daoId, treasury, _msgSender());
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../dao-configuration/DaoConfiguration.sol";

/**
 * @title Box to test the access control dedicated for the Bond and StakingPool family of contracts.
 *
 * @notice An empty box for testing the provided modifiers and management for access control required throughout the Bond contracts.
 */
contract DaoConfigurationBox is DaoConfiguration {
    /**
     * As BondAccessControl is intended to be used in Upgradable contracts, it uses an init.
     */
    constructor() initializer {
        __DaoConfiguration_init();
    }

    function daoConfiguration(address erc20CapableTreasury)
        external
        returns (uint256)
    {
        return _daoConfiguration(erc20CapableTreasury);
    }

    function setDaoTreasury(uint256 daoId, address replacementTreasury)
        external
    {
        _setDaoTreasury(daoId, replacementTreasury);
    }

    function setDaoMetaData(uint256 daoId, string calldata replacementMetaData)
        external
    {
        _setDaoMetaData(daoId, replacementMetaData);
    }

    function whitelistDaoCollateral(
        uint256 daoId,
        address erc20CollateralTokens
    ) external {
        _whitelistDaoCollateral(daoId, erc20CollateralTokens);
    }

    function removeWhitelistedDaoCollateral(uint256 daoId, address tokens)
        external
    {
        _removeWhitelistedDaoCollateral(daoId, tokens);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./StakingPoolCurator.sol";
import "./StakingPoolCreator.sol";
import "../dao-configuration/DaoConfiguration.sol";
import "../Version.sol";
import "../sweep/SweepERC20.sol";

/**
 * @title Mediates between a StakingPool creator and StakingPool curator.
 *
 * @dev Orchestrates a StakingPoolCreator and StakingPoolCurator to provide a single function to aggregate the various calls
 *      providing a single function to create and setup a staking pool for management with the curator.
 */
contract StakingPoolMediator is
    DaoConfiguration,
    StakingPoolCurator,
    SweepERC20,
    UUPSUpgradeable,
    Version
{
    StakingPoolCreator private _creator;

    event StakingPoolCreatorUpdate(
        address indexed previousCreator,
        address indexed updateCreator,
        address indexed instigator
    );

    /**
     * @notice The _msgSender() is given membership of all roles, to allow granting and future renouncing after others
     *      have been setup.
     *
     * @param factory A deployed StakingPoolFactory contract to use when creating bonds.
     * @param treasury Beneficiary of any token sweeping.
     */
    function initialize(StakingPoolCreator factory, address treasury)
        external
        initializer
    {
        require(
            AddressUpgradeable.isContract(address(factory)),
            "SPM: creator not a contract"
        );

        __StakingPoolCurator_init();
        __DaoConfiguration_init();
        __UUPSUpgradeable_init();
        __TokenSweep_init(treasury);

        _creator = factory;
    }

    function createDao(address erc20CapableTreasury)
        external
        atLeastDaoCreatorRole
        returns (uint256)
    {
        uint256 id = _daoConfiguration(erc20CapableTreasury);
        _grantDaoCreatorAdminRoleInTheirDao(id);

        emit CreateDao(id, erc20CapableTreasury, _msgSender());

        return id;
    }

    function createManagedStakingPool(
        StakingPoolLib.Config calldata config,
        bool launchPaused,
        uint32 rewardsAvailableTimestamp
    )
        external
        whenNotPaused
        atLeastDaoMeepleRole(config.daoId)
        returns (address)
    {
        require(_isValidDaoId(config.daoId), "SPM: invalid DAO Id");
        require(
            isAllowedDaoCollateral(config.daoId, address(config.stakeToken)),
            "SPM: collateral not whitelisted"
        );

        // Reentrancy warning from an emitted event, which needs the Bond, created by an external call above.
        //slither-disable-next-line reentrancy-events
        address stakingPool = _creator.createStakingPool(
            config,
            launchPaused,
            rewardsAvailableTimestamp
        );

        _addStakingPool(config.daoId, stakingPool);

        return stakingPool;
    }

    /**
     * @notice Permits updating the meta data for the DAO.
     */
    function setDaoMetaData(uint256 daoId, string calldata replacement)
        external
        whenNotPaused
        atLeastDaoAdminRole(daoId)
    {
        _setDaoMetaData(daoId, replacement);
    }

    /**
     * @notice Updates the StakingPool creator reference.
     *
     * @param factory Contract address for the new StakingPoolCreator to use from now onwards when creating managed bonds.
     */
    function setStakingPoolCreator(address factory)
        external
        whenNotPaused
        atLeastSysAdminRole
    {
        require(
            AddressUpgradeable.isContract(factory),
            "SPM: creator not a contract"
        );
        address previousCreator = address(_creator);
        require(factory != previousCreator, "SPM: matches existing");

        emit StakingPoolCreatorUpdate(
            address(_creator),
            address(factory),
            _msgSender()
        );
        _creator = StakingPoolCreator(factory);
    }

    /**
     * @notice Permits updating the default DAO treasury address.
     *
     * @dev Only applies for bonds created after the update, previously created bond treasury addresses remain unchanged.
     */
    function setDaoTreasury(uint256 daoId, address replacement)
        external
        whenNotPaused
        atLeastDaoAdminRole(daoId)
    {
        _setDaoTreasury(daoId, replacement);
    }

    function updateTokenSweepBeneficiary(address newBeneficiary)
        external
        whenNotPaused
        onlySuperUserRole
    {
        _setTokenSweepBeneficiary(newBeneficiary);
    }

    function sweepERC20Tokens(address tokens, uint256 amount)
        external
        whenNotPaused
        onlySuperUserRole
    {
        _sweepERC20Tokens(tokens, amount);
    }

    /**
     * @notice Adds an ERC20 token to the collateral whitelist.
     *
     * @dev When a staking pool is created, the tokens used as collateral must have been whitelisted.
     *
     * @param daoId The DAO who is having the collateral token whitelisted.
     * @param erc20CollateralTokens Whitelists the token from now onwards.
     *      On staking pool creation the tokens address used is retrieved by symbol from the whitelist.
     */
    function whitelistCollateral(uint256 daoId, address erc20CollateralTokens)
        external
        whenNotPaused
        atLeastDaoAdminRole(daoId)
    {
        _whitelistDaoCollateral(daoId, erc20CollateralTokens);
    }

    function stakingPoolCreator() external view returns (address) {
        return address(_creator);
    }

    /**
     * @notice Permits only the relevant admins to perform proxy upgrades.
     *
     * @dev Only applicable when deployed as implementation to a UUPS proxy.
     */
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        atLeastSysAdminRole
    {}

    function _grantDaoCreatorAdminRoleInTheirDao(uint256 daoId) private {
        if (_hasGlobalRole(Roles.DAO_CREATOR, _msgSender())) {
            _grantDaoRole(daoId, Roles.DAO_ADMIN, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "../RoleAccessControl.sol";
import "./StakingPool.sol";
import "./StakingPoolLib.sol";

/**
 * @title Manages interactions with StakingPool contracts.
 *
 * @notice A central place to discover created StakingPools and apply access control to them.
 *
 * @dev Owns of all StakingPools it manages, guarding function accordingly allows finer access control to be provided.
 */
abstract contract StakingPoolCurator is RoleAccessControl, PausableUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(uint256 => EnumerableSetUpgradeable.AddressSet)
        private _stakingPools;

    event AddStakingPool(
        uint256 indexed daoId,
        address indexed stakingPool,
        address indexed instigator
    );

    function stakingPoolPause(uint256 daoId, address stakingPool)
        external
        whenNotPaused
        atLeastDaoAdminRole(daoId)
    {
        _requireManagingStakingPool(daoId, stakingPool);

        StakingPool(stakingPool).pause();
    }

    function stakingPoolUnpause(uint256 daoId, address stakingPool)
        external
        whenNotPaused
        atLeastDaoAdminRole(daoId)
    {
        _requireManagingStakingPool(daoId, stakingPool);

        StakingPool(stakingPool).unpause();
    }

    function stakingPoolInitializeRewardTokens(
        uint256 daoId,
        address stakingPool,
        address benefactor,
        StakingPoolLib.Reward[] calldata rewards
    ) external whenNotPaused atLeastDaoMeepleRole(daoId) {
        _requireManagingStakingPool(daoId, stakingPool);

        StakingPool(stakingPool).initializeRewardTokens(benefactor, rewards);
    }

    function stakingPoolEnableEmergencyMode(uint256 daoId, address stakingPool)
        external
        atLeastDaoMeepleRole(daoId)
    {
        _requireManagingStakingPool(daoId, stakingPool);

        StakingPool(stakingPool).enableEmergencyMode();
    }

    function stakingPoolAdminEmergencyRewardSweep(
        uint256 daoId,
        address stakingPool
    ) external atLeastDaoMeepleRole(daoId) {
        _requireManagingStakingPool(daoId, stakingPool);

        StakingPool(stakingPool).adminEmergencyRewardSweep();
    }

    function stakingPoolSetRewardsAvailableTimestamp(
        uint256 daoId,
        address stakingPool,
        uint32 timestamp
    ) external atLeastDaoMeepleRole(daoId) {
        _requireManagingStakingPool(daoId, stakingPool);

        StakingPool(stakingPool).setRewardsAvailableTimestamp(timestamp);
    }

    function stakingPoolSweepERC20Tokens(
        uint256 daoId,
        address stakingPool,
        address tokens,
        uint256 amount
    ) external atLeastDaoMeepleRole(daoId) {
        _requireManagingStakingPool(daoId, stakingPool);

        StakingPool(stakingPool).sweepERC20Tokens(tokens, amount);
    }

    function stakingPoolUpdateTokenSweepBeneficiary(
        uint256 daoId,
        address stakingPool,
        address newBeneficiary
    ) external atLeastDaoMeepleRole(daoId) {
        _requireManagingStakingPool(daoId, stakingPool);

        StakingPool(stakingPool).updateTokenSweepBeneficiary(newBeneficiary);
    }

    /**
     * @notice Pauses most side affecting functions.
     */
    function pause() external whenNotPaused atLeastSysAdminRole {
        _pause();
    }

    /**
     * @notice Resumes all paused side affecting functions.
     */
    function unpause() external whenPaused atLeastSysAdminRole {
        _unpause();
    }

    function stakingPoolAt(uint256 daoId, uint256 index)
        external
        view
        returns (address)
    {
        require(
            index < EnumerableSetUpgradeable.length(_stakingPools[daoId]),
            "StakingPool: too large"
        );

        return EnumerableSetUpgradeable.at(_stakingPools[daoId], index);
    }

    function stakingPoolCount(uint256 daoId) external view returns (uint256) {
        return EnumerableSetUpgradeable.length(_stakingPools[daoId]);
    }

    function _addStakingPool(uint256 daoId, address stakingPool)
        internal
        whenNotPaused
    {
        require(
            !_stakingPools[daoId].contains(stakingPool),
            "StakingPool: already managing"
        );
        require(
            OwnableUpgradeable(stakingPool).owner() == address(this),
            "StakingPool: not owner"
        );

        emit AddStakingPool(daoId, stakingPool, _msgSender());

        bool added = _stakingPools[daoId].add(stakingPool);
        require(added, "StakingPool: failed to add");
    }

    //slither-disable-next-line naming-convention
    function __StakingPoolCurator_init() internal onlyInitializing {
        __RoleAccessControl_init();
        __Pausable_init();
    }

    function _requireManagingStakingPool(uint256 daoId, address stakingPool)
        private
        view
    {
        require(
            _stakingPools[daoId].contains(stakingPool),
            "StakingPool: not managing"
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./StakingPoolLib.sol";

/**
 * @title Deploys new StakingPools.
 *
 * @notice Creating a StakingPool involves the two steps of deploying and initialising.
 */
interface StakingPoolCreator {
    /**
     * @notice Deploys and initialises a new StakingPool.
     */
    function createStakingPool(
        StakingPoolLib.Config calldata config,
        bool launchPaused,
        uint32 rewardsAvailableTimestamp
    ) external returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

abstract contract Version {
    string public constant VERSION = "v0.0.1";
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./TokenSweep.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @title Adds the ability to sweep ERC20 tokens to a beneficiary address
 */
abstract contract SweepERC20 is TokenSweep {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event ERC20Sweep(
        address indexed beneficiary,
        address indexed tokens,
        uint256 amount,
        address indexed instigator
    );

    /**
     * @notice Sweep the erc20 tokens to the beneficiary address
     *
     * @param tokens The registry for the ERC20 token to transfer,
     * @param amount How many tokens, in the ERC20's decimals to transfer.
     **/
    function _sweepERC20Tokens(address tokens, uint256 amount) internal {
        require(tokens != address(this), "SweepERC20: self transfer");
        require(tokens != address(0), "SweepERC20: address zero");

        emit ERC20Sweep(tokenSweepBeneficiary(), tokens, amount, _msgSender());

        IERC20Upgradeable(tokens).safeTransfer(tokenSweepBeneficiary(), amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./RoleMembership.sol";
import "./Roles.sol";

/**
 * @title Access control using a predefined set of roles.
 *
 * @notice The roles and their relationship to each other are defined.
 *
 * @dev There are two categories of role:
 * - Global; permissions granted across all DAOs.
 * - Dao; permissions granted only in a single DAO.
 */
abstract contract RoleAccessControl is RoleMembership {
    uint8 private _superUserCounter;

    modifier onlySuperUserRole() {
        if (_isMissingGlobalRole(Roles.SUPER_USER, _msgSender())) {
            revert(
                _revertMessageMissingGlobalRole(Roles.SUPER_USER, _msgSender())
            );
        }
        _;
    }

    modifier atLeastDaoCreatorRole() {
        if (
            _isMissingGlobalRole(Roles.SUPER_USER, _msgSender()) &&
            _isMissingGlobalRole(Roles.DAO_CREATOR, _msgSender())
        ) {
            revert(
                _revertMessageMissingGlobalRole(Roles.DAO_CREATOR, _msgSender())
            );
        }
        _;
    }

    modifier atLeastSysAdminRole() {
        if (
            _isMissingGlobalRole(Roles.SUPER_USER, _msgSender()) &&
            _isMissingGlobalRole(Roles.SYSTEM_ADMIN, _msgSender())
        ) {
            revert(
                _revertMessageMissingGlobalRole(
                    Roles.SYSTEM_ADMIN,
                    _msgSender()
                )
            );
        }
        _;
    }

    modifier atLeastDaoAdminRole(uint256 daoId) {
        if (
            _isMissingGlobalRole(Roles.SUPER_USER, _msgSender()) &&
            _isMissingDaoRole(daoId, Roles.DAO_ADMIN, _msgSender())
        ) {
            revert(
                _revertMessageMissingDaoRole(
                    daoId,
                    Roles.DAO_ADMIN,
                    _msgSender()
                )
            );
        }
        _;
    }

    modifier atLeastDaoMeepleRole(uint256 daoId) {
        if (
            _isMissingGlobalRole(Roles.SUPER_USER, _msgSender()) &&
            _isMissingDaoRole(daoId, Roles.DAO_ADMIN, _msgSender()) &&
            _isMissingDaoRole(daoId, Roles.DAO_MEEPLE, _msgSender())
        ) {
            revert(
                _revertMessageMissingDaoRole(
                    daoId,
                    Roles.DAO_MEEPLE,
                    _msgSender()
                )
            );
        }
        _;
    }

    function grantSuperUserRole(address account) external onlySuperUserRole {
        _grantGlobalRole(Roles.SUPER_USER, account);
        _superUserCounter++;
    }

    function grantDaoCreatorRole(address account) external onlySuperUserRole {
        _grantGlobalRole(Roles.DAO_CREATOR, account);
    }

    function grantSysAdminRole(address account) external atLeastSysAdminRole {
        _grantGlobalRole(Roles.SYSTEM_ADMIN, account);
    }

    function grantDaoAdminRole(uint256 daoId, address account)
        external
        atLeastDaoAdminRole(daoId)
    {
        _grantDaoRole(daoId, Roles.DAO_ADMIN, account);
    }

    function grantDaoMeepleRole(uint256 daoId, address account)
        external
        atLeastDaoAdminRole(daoId)
    {
        _grantDaoRole(daoId, Roles.DAO_MEEPLE, account);
    }

    function revokeSuperUserRole(address account) external onlySuperUserRole {
        _revokeGlobalRole(Roles.SUPER_USER, account);
        require(_superUserCounter > 1, "RAC: no revoking last SuperUser");
        _superUserCounter--;
    }

    function revokeDaoCreatorRole(address account) external onlySuperUserRole {
        _revokeGlobalRole(Roles.DAO_CREATOR, account);
    }

    function revokeSysAdminRole(address account) external atLeastSysAdminRole {
        _revokeGlobalRole(Roles.SYSTEM_ADMIN, account);
    }

    function revokeDaoAdminRole(uint256 daoId, address account)
        external
        atLeastDaoAdminRole(daoId)
    {
        _revokeDaoRole(daoId, Roles.DAO_ADMIN, account);
    }

    function revokeDaoMeepleRole(uint256 daoId, address account)
        external
        atLeastDaoAdminRole(daoId)
    {
        _revokeDaoRole(daoId, Roles.DAO_MEEPLE, account);
    }

    function hasSuperUserAccess(address account) external view returns (bool) {
        return _hasGlobalRole(Roles.SUPER_USER, account);
    }

    function hasDaoAdminAccess(uint256 daoId, address account)
        external
        view
        returns (bool)
    {
        return
            _hasGlobalRole(Roles.SUPER_USER, account) ||
            _hasDaoRole(daoId, Roles.DAO_ADMIN, account);
    }

    function hasDaoCreatorAccess(address account) external view returns (bool) {
        return
            _hasGlobalRole(Roles.SUPER_USER, account) ||
            _hasGlobalRole(Roles.DAO_CREATOR, account);
    }

    function hasDaoMeepleAccess(uint256 daoId, address account)
        external
        view
        returns (bool)
    {
        return
            _hasGlobalRole(Roles.SUPER_USER, account) ||
            _hasDaoRole(daoId, Roles.DAO_ADMIN, account) ||
            _hasDaoRole(daoId, Roles.DAO_MEEPLE, account);
    }

    function hasSysAdminAccess(address account) external view returns (bool) {
        return
            _hasGlobalRole(Roles.SUPER_USER, account) ||
            _hasGlobalRole(Roles.SYSTEM_ADMIN, account);
    }

    /**
     * @notice The _msgSender() is given membership of the SuperUser role.
     *
     * @dev Allows granting and future renouncing after other addresses have been setup.
     */
    //slither-disable-next-line naming-convention
    function __RoleAccessControl_init() internal onlyInitializing {
        __RoleMembership_init();

        _grantGlobalRole(Roles.SUPER_USER, _msgSender());
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./StakingPoolLib.sol";
import "../Version.sol";
import "../sweep/SweepERC20.sol";

/**
 * @title StakingPool with optional fixed or floating token rewards
 *
 * @notice Users can deposit a stake token into the pool up to the specified pool maximum contribution.
 * If the minimum criteria for the pool to go ahead are met, stake tokens are locked for an epochDuration.
 * After this period expires the user can withdraw their stake token and reward tokens (if available) separately.
 * The amount of rewards is determined by the pools rewardType - a floating reward ratio is updated on each deposit
 * while fixed tokens rewards are calculated once per user.
 */
contract StakingPool is
    PausableUpgradeable,
    ReentrancyGuard,
    OwnableUpgradeable,
    SweepERC20,
    Version
{
    using SafeERC20 for IERC20;

    // Magic Number fixed length rewardsAmounts to fit 3 words. Only used here.
    struct User {
        uint128 depositAmount;
        uint128[5] rewardAmounts;
    }

    struct RewardOwed {
        IERC20 tokens;
        uint128 amount;
    }

    mapping(address => User) private _users;
    mapping(address => bool) private _supportedRewards;

    uint32 private _rewardsAvailableTimestamp;
    bool private _emergencyMode;
    uint128 private _totalStakedAmount;

    StakingPoolLib.Config private _stakingPoolConfig;

    event WithdrawRewards(
        address indexed user,
        address rewardToken,
        uint256 rewards
    );
    event WithdrawStake(address indexed user, uint256 stake);
    event Deposit(address indexed user, uint256 depositAmount);
    event InitializeRewards(address rewardTokens, uint256 amount);
    event RewardsAvailableTimestamp(uint32 rewardsAvailableTimestamp);
    event EmergencyMode(address indexed admin);
    event NoRewards(address indexed user);

    modifier rewardsAvailable() {
        require(_isRewardsAvailable(), "StakingPool: rewards too early");
        _;
    }

    modifier stakingPeriodComplete() {
        require(_isStakingPeriodComplete(), "StakingPool: still stake period");
        _;
    }

    modifier stakingPoolRequirementsUnmet() {
        //slither-disable-next-line timestamp
        require(
            (_totalStakedAmount < _stakingPoolConfig.minTotalPoolStake) &&
                (block.timestamp > _stakingPoolConfig.epochStartTimestamp),
            "StakingPool: requirements unmet"
        );
        _;
    }

    modifier emergencyModeEnabled() {
        require(_emergencyMode, "StakingPool: not emergency mode");
        _;
    }

    function pause() external whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() external whenPaused onlyOwner {
        _unpause();
    }

    /**
     * @notice Only entry point for a user to deposit into the staking pool
     *
     * @param amount Amount of stake tokens to deposit
     */
    function deposit(uint128 amount) external whenNotPaused nonReentrant {
        StakingPoolLib.Config storage _config = _stakingPoolConfig;

        require(
            amount >= _config.minimumContribution,
            "StakingPool: min contribution"
        );
        require(
            _totalStakedAmount + amount <= _config.maxTotalPoolStake,
            "StakingPool: oversubscribed"
        );
        //slither-disable-next-line timestamp
        require(
            block.timestamp < _config.epochStartTimestamp,
            "StakingPool: too late"
        );

        User storage user = _users[_msgSender()];

        user.depositAmount += amount;
        _totalStakedAmount += amount;

        emit Deposit(_msgSender(), amount);

        // calculate/update rewards
        if (_config.rewardType == StakingPoolLib.RewardType.FLOATING) {
            _updateRewardsRatios(_config);
        }
        if (_config.rewardType == StakingPoolLib.RewardType.FIXED) {
            _calculateFixedRewards(_config, user, amount);
        }

        _config.stakeToken.safeTransferFrom(
            _msgSender(),
            address(this),
            amount
        );
    }

    /**
     * @notice Withdraw both stake and reward tokens when the stake period is complete
     */
    function withdraw()
        external
        whenNotPaused
        stakingPeriodComplete
        rewardsAvailable
        nonReentrant
    {
        User memory user = _users[_msgSender()];
        require(user.depositAmount > 0, "StakingPool: not eligible");

        delete _users[_msgSender()];

        StakingPoolLib.Config storage _config = _stakingPoolConfig;

        //slither-disable-next-line reentrancy-events
        _transferStake(user.depositAmount, _config.stakeToken);

        _withdrawRewards(_config, user);
    }

    /**
     * @notice Withdraw only stake tokens after staking period is complete. Reward tokens may not be available yet.
     */
    function withdrawStake()
        external
        stakingPeriodComplete
        nonReentrant
        whenNotPaused
    {
        _withdrawStake();
    }

    /**
     * @notice Withdraw only reward tokens. Stake must have already been withdrawn.
     */
    function withdrawRewards()
        external
        stakingPeriodComplete
        rewardsAvailable
        whenNotPaused
    {
        StakingPoolLib.Config memory _config = _stakingPoolConfig;

        User memory user = _users[_msgSender()];
        require(user.depositAmount == 0, "StakingPool: withdraw stake");
        delete _users[_msgSender()];

        bool noRewards = true;

        for (uint256 i = 0; i < user.rewardAmounts.length; i++) {
            if (user.rewardAmounts[i] > 0) {
                noRewards = false;
                //slither-disable-next-line calls-loop
                _transferRewards(
                    user.rewardAmounts[i],
                    _config.rewardTokens[i].tokens
                );
            }
        }
        if (noRewards) {
            emit NoRewards(_msgSender());
        }
    }

    /**
     * @notice Withdraw stake tokens when minimum pool conditions to begin are not met
     */
    function earlyWithdraw()
        external
        stakingPoolRequirementsUnmet
        whenNotPaused
    {
        _withdrawWithoutRewards();
    }

    /**
     * @notice Withdraw stake tokens when admin has enabled emergency mode
     */
    function emergencyWithdraw() external emergencyModeEnabled {
        _withdrawStake();
    }

    function sweepERC20Tokens(address tokens, uint256 amount)
        external
        whenNotPaused
        onlyOwner
    {
        _sweepERC20Tokens(tokens, amount);
    }

    function initialize(
        StakingPoolLib.Config calldata info,
        bool paused,
        uint32 rewardsTimestamp,
        address beneficiary
    ) external virtual initializer {
        __Context_init_unchained();
        __Pausable_init();
        __Ownable_init();
        __TokenSweep_init(beneficiary);

        //slither-disable-next-line timestamp
        require(
            info.epochStartTimestamp >= block.timestamp,
            "StakingPool: start >= now"
        );

        _enforceUniqueRewardTokens(info.rewardTokens);
        require(
            address(info.stakeToken) != address(0),
            "StakingPool: stake token defined"
        );
        //slither-disable-next-line timestamp
        require(
            rewardsTimestamp > info.epochStartTimestamp + info.epochDuration,
            "StakingPool: init rewards"
        );
        require(info.treasury != address(0), "StakePool: treasury address 0");
        require(info.maxTotalPoolStake > 0, "StakePool: maxTotalPoolStake > 0");
        require(info.epochDuration > 0, "StakePool: epochDuration > 0");
        require(info.minimumContribution > 0, "StakePool: minimumContribution");

        if (paused) {
            _pause();
        }

        _rewardsAvailableTimestamp = rewardsTimestamp;
        emit RewardsAvailableTimestamp(rewardsTimestamp);

        _stakingPoolConfig = info;
    }

    function initializeRewardTokens(
        address benefactor,
        StakingPoolLib.Reward[] calldata rewards
    ) external onlyOwner {
        _initializeRewardTokens(benefactor, rewards);
    }

    function enableEmergencyMode() external onlyOwner {
        _emergencyMode = true;
        emit EmergencyMode(_msgSender());
    }

    function adminEmergencyRewardSweep()
        external
        emergencyModeEnabled
        onlyOwner
    {
        _adminEmergencyRewardSweep();
    }

    function setRewardsAvailableTimestamp(uint32 timestamp) external onlyOwner {
        _setRewardsAvailableTimestamp(timestamp);
    }

    function updateTokenSweepBeneficiary(address newBeneficiary)
        external
        whenNotPaused
        onlyOwner
    {
        _setTokenSweepBeneficiary(newBeneficiary);
    }

    function currentExpectedRewards(address user)
        external
        view
        returns (uint256[] memory)
    {
        User memory _user = _users[user];
        StakingPoolLib.Config memory _config = _stakingPoolConfig;

        uint256[] memory rewards = new uint256[](_config.rewardTokens.length);

        for (uint256 i = 0; i < _config.rewardTokens.length; i++) {
            rewards[i] = _calculateRewardAmount(_config, _user, i);
        }
        return rewards;
    }

    function stakingPoolData()
        external
        view
        returns (StakingPoolLib.Config memory)
    {
        return _stakingPoolConfig;
    }

    function rewardsAvailableTimestamp() external view returns (uint32) {
        return _rewardsAvailableTimestamp;
    }

    function getUser(address activeUser) external view returns (User memory) {
        return _users[activeUser];
    }

    function emergencyMode() external view returns (bool) {
        return _emergencyMode;
    }

    function totalStakedAmount() external view returns (uint128) {
        return _totalStakedAmount;
    }

    function isRedeemable() external view returns (bool) {
        //slither-disable-next-line timestamp
        return _isRewardsAvailable() && _isStakingPeriodComplete();
    }

    function isRewardsAvailable() external view returns (bool) {
        return _isRewardsAvailable();
    }

    function isStakingPeriodComplete() external view returns (bool) {
        return _isStakingPeriodComplete();
    }

    /**
     * @notice Returns the final amount of reward due for a user
     *
     * @param user address to calculate rewards for
     */
    function currentRewards(address user)
        external
        view
        returns (RewardOwed[] memory)
    {
        User memory _user = _users[user];
        StakingPoolLib.Config memory _config = _stakingPoolConfig;

        RewardOwed[] memory rewards = new RewardOwed[](
            _config.rewardTokens.length
        );

        for (uint256 i = 0; i < _config.rewardTokens.length; i++) {
            if (_config.rewardType == StakingPoolLib.RewardType.FLOATING) {
                rewards[i] = RewardOwed({
                    amount: _calculateFloatingReward(
                        _config.rewardTokens[i].ratio,
                        _user.depositAmount
                    ),
                    tokens: _config.rewardTokens[i].tokens
                });
            }
            if (_config.rewardType == StakingPoolLib.RewardType.FIXED) {
                rewards[i] = RewardOwed({
                    amount: _user.rewardAmounts[i],
                    tokens: _config.rewardTokens[i].tokens
                });
            }
        }
        return rewards;
    }

    function _initializeRewardTokens(
        address benefactor,
        StakingPoolLib.Reward[] calldata _rewardTokens
    ) internal {
        _enforceUniqueRewardTokens(_rewardTokens);
        for (uint256 i = 0; i < _rewardTokens.length; i++) {
            emit InitializeRewards(
                address(_rewardTokens[i].tokens),
                _rewardTokens[i].maxAmount
            );

            require(
                _rewardTokens[i].tokens.allowance(benefactor, address(this)) >=
                    _rewardTokens[i].maxAmount,
                "StakingPool: invalid allowance"
            );

            _rewardTokens[i].tokens.safeTransferFrom(
                benefactor,
                address(this),
                _rewardTokens[i].maxAmount
            );
        }
    }

    function _withdrawWithoutRewards() internal {
        User memory user = _users[_msgSender()];
        require(user.depositAmount > 0, "StakingPool: not eligible");

        delete _users[_msgSender()];
        StakingPoolLib.Config memory _config = _stakingPoolConfig;
        _transferStake(uint256((user.depositAmount)), _config.stakeToken);
    }

    function _setRewardsAvailableTimestamp(uint32 timestamp) internal {
        require(!_isStakingPeriodComplete(), "StakePool: already finalized");
        //slither-disable-next-line timestamp
        require(timestamp > block.timestamp, "StakePool: future rewards");

        _rewardsAvailableTimestamp = timestamp;
        emit RewardsAvailableTimestamp(timestamp);
    }

    function _transferStake(uint256 amount, IERC20 stakeToken) internal {
        emit WithdrawStake(_msgSender(), amount);
        _transferToken(amount, stakeToken);
    }

    function _transferRewards(uint256 amount, IERC20 rewardsToken) internal {
        emit WithdrawRewards(_msgSender(), address(rewardsToken), amount);
        _transferToken(amount, rewardsToken);
    }

    function _adminEmergencyRewardSweep() internal {
        StakingPoolLib.Reward[] memory rewards = _stakingPoolConfig
            .rewardTokens;
        address treasury = _stakingPoolConfig.treasury;

        for (uint256 i = 0; i < rewards.length; i++) {
            rewards[i].tokens.safeTransfer(
                treasury,
                rewards[i].tokens.balanceOf(address(this))
            );
        }
    }

    function _withdrawStake() internal {
        User storage user = _users[_msgSender()];
        require(user.depositAmount > 0, "StakingPool: not eligible");

        uint128 currentDepositBalance = user.depositAmount;
        user.depositAmount = 0;

        StakingPoolLib.Config storage _config = _stakingPoolConfig;
        // set users floating reward if applicable
        if (_config.rewardType == StakingPoolLib.RewardType.FLOATING) {
            for (uint256 i = 0; i < _config.rewardTokens.length; i++) {
                user.rewardAmounts[i] = _calculateFloatingReward(
                    _config.rewardTokens[i].ratio,
                    currentDepositBalance
                );
            }
        }
        _transferStake(currentDepositBalance, _config.stakeToken);
    }

    function _isRewardsAvailable() internal view returns (bool) {
        //slither-disable-next-line timestamp
        return block.timestamp >= _rewardsAvailableTimestamp;
    }

    function _isStakingPeriodComplete() internal view returns (bool) {
        //slither-disable-next-line timestamp
        return
            block.timestamp >=
            (_stakingPoolConfig.epochStartTimestamp +
                _stakingPoolConfig.epochDuration);
    }

    function _calculateRewardAmount(
        StakingPoolLib.Config memory _config,
        User memory _user,
        uint256 rewardIndex
    ) internal pure returns (uint256) {
        if (_config.rewardType == StakingPoolLib.RewardType.FIXED) {
            return _user.rewardAmounts[rewardIndex];
        }

        if (_config.rewardType == StakingPoolLib.RewardType.FLOATING) {
            if (_user.depositAmount == 0) {
                // user has already withdrawn stake
                return _user.rewardAmounts[rewardIndex];
            }

            // user has not withdrawn stake yet
            return
                _calculateFloatingReward(
                    _config.rewardTokens[rewardIndex].ratio,
                    _user.depositAmount
                );
        }
        return 0;
    }

    function _calculateFloatingReward(
        uint256 rewardAmountRatio,
        uint128 depositAmount
    ) internal pure returns (uint128) {
        return uint128((rewardAmountRatio * depositAmount) / 1 ether);
    }

    function _computeFloatingRewardsPerShare(
        uint256 availableTokenRewards,
        uint256 total
    ) internal pure returns (uint256) {
        return (availableTokenRewards * 1 ether) / total;
    }

    function _transferToken(uint256 amount, IERC20 token) private {
        //slither-disable-next-line calls-loop
        token.safeTransfer(_msgSender(), amount);
    }

    /**
     * @notice Updates the global reward ratios for each reward token in a floating reward pool
     */
    function _updateRewardsRatios(StakingPoolLib.Config storage _config)
        private
    {
        for (uint256 i = 0; i < _config.rewardTokens.length; i++) {
            _config.rewardTokens[i].ratio = _computeFloatingRewardsPerShare(
                _config.rewardTokens[i].maxAmount,
                _totalStakedAmount
            );
        }
    }

    /**
     * @notice Calculates and sets the users reward amount for a fixed reward pool
     */
    function _calculateFixedRewards(
        StakingPoolLib.Config memory _config,
        User storage user,
        uint256 amount
    ) private {
        for (uint256 i = 0; i < _config.rewardTokens.length; i++) {
            user.rewardAmounts[i] += uint128(
                (amount * _config.rewardTokens[i].ratio)
            );
        }
    }

    function _withdrawRewards(
        StakingPoolLib.Config memory _config,
        User memory user
    ) private {
        bool noRewards = true;

        // calculate the rewardAmounts due to the user
        for (uint256 i = 0; i < _config.rewardTokens.length; i++) {
            uint256 amount = _calculateRewardAmount(_config, user, i);

            if (amount > 0) {
                noRewards = false;
                //slither-disable-next-line calls-loop
                _transferRewards(amount, _config.rewardTokens[i].tokens);
            }
        }
        if (noRewards) {
            emit NoRewards(_msgSender());
        }
    }

    /**
     * @notice Enforces that each of the reward tokens are unique
     */
    function _enforceUniqueRewardTokens(
        StakingPoolLib.Reward[] calldata rewardPools
    ) private {
        for (uint256 i = 0; i < rewardPools.length; i++) {
            // Ensure no prev entries contain the same tokens address
            require(
                !_supportedRewards[address(rewardPools[i].tokens)],
                "StakePool: tokens must be unique"
            );
            _supportedRewards[address(rewardPools[i].tokens)] = true;
        }
        for (uint256 i = 0; i < rewardPools.length; i++) {
            delete _supportedRewards[address(rewardPools[i].tokens)];
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library StakingPoolLib {
    enum RewardType {
        NONE,
        FIXED,
        FLOATING
    }

    struct Reward {
        IERC20 tokens;
        uint256 maxAmount;
        uint256 ratio; // only initialized for fixed
    }

    struct Config {
        uint256 daoId;
        uint128 minTotalPoolStake;
        uint128 maxTotalPoolStake;
        uint128 minimumContribution;
        uint32 epochDuration;
        uint32 epochStartTimestamp;
        address treasury;
        IERC20 stakeToken;
        Reward[] rewardTokens;
        RewardType rewardType;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

/**
 * @title Role based set membership.
 *
 * @notice Encapsulation of tracking, management and validation of role membership of addresses.
 *
 *  A role is a bytes32 value.
 *
 *  There are two distinct classes of roles:
 *  - Global; without scope limit.
 *  - Dao; membership scoped to that of the key (uint256).
 *
 * @dev Meaningful application of role membership is expected to come from derived contracts.
 *      e.g. access control.
 */
abstract contract RoleMembership is ContextUpgradeable {
    // DAOs to their roles to members; scoped to an individual DAO
    mapping(uint256 => mapping(bytes32 => mapping(address => bool)))
        private _daoRoleMembers;

    // Global roles to members; apply across all DAOs
    mapping(bytes32 => mapping(address => bool)) private _globalRoleMembers;

    event GrantDaoRole(
        uint256 indexed daoId,
        bytes32 indexed role,
        address account,
        address indexed instigator
    );
    event GrantGlobalRole(
        bytes32 indexedrole,
        address account,
        address indexed instigator
    );
    event RevokeDaoRole(
        uint256 indexed daoId,
        bytes32 indexed role,
        address account,
        address indexed instigator
    );
    event RevokeGlobalRole(
        bytes32 indexed role,
        address account,
        address indexed instigator
    );

    function hasGlobalRole(bytes32 role, address account)
        external
        view
        returns (bool)
    {
        return _globalRoleMembers[role][account];
    }

    function hasDaoRole(
        uint256 daoId,
        bytes32 role,
        address account
    ) external view returns (bool) {
        return _daoRoleMembers[daoId][role][account];
    }

    function _grantDaoRole(
        uint256 daoId,
        bytes32 role,
        address account
    ) internal {
        if (_hasDaoRole(daoId, role, account)) {
            revert(_revertMessageAlreadyHasDaoRole(daoId, role, account));
        }

        _daoRoleMembers[daoId][role][account] = true;
        emit GrantDaoRole(daoId, role, account, _msgSender());
    }

    function _grantGlobalRole(bytes32 role, address account) internal {
        if (_hasGlobalRole(role, account)) {
            revert(_revertMessageAlreadyHasGlobalRole(role, account));
        }

        _globalRoleMembers[role][account] = true;
        emit GrantGlobalRole(role, account, _msgSender());
    }

    function _revokeDaoRole(
        uint256 daoId,
        bytes32 role,
        address account
    ) internal {
        if (_isMissingDaoRole(daoId, role, account)) {
            revert(_revertMessageMissingDaoRole(daoId, role, account));
        }

        delete _daoRoleMembers[daoId][role][account];
        emit RevokeDaoRole(daoId, role, account, _msgSender());
    }

    function _revokeGlobalRole(bytes32 role, address account) internal {
        if (_isMissingGlobalRole(role, account)) {
            revert(_revertMessageMissingGlobalRole(role, account));
        }

        delete _globalRoleMembers[role][account];
        emit RevokeGlobalRole(role, account, _msgSender());
    }

    //slither-disable-next-line naming-convention
    function __RoleMembership_init() internal onlyInitializing {}

    function _hasDaoRole(
        uint256 daoId,
        bytes32 role,
        address account
    ) internal view returns (bool) {
        return _daoRoleMembers[daoId][role][account];
    }

    function _hasGlobalRole(bytes32 role, address account)
        internal
        view
        returns (bool)
    {
        return _globalRoleMembers[role][account];
    }

    function _isMissingDaoRole(
        uint256 daoId,
        bytes32 role,
        address account
    ) internal view returns (bool) {
        return !_daoRoleMembers[daoId][role][account];
    }

    function _isMissingGlobalRole(bytes32 role, address account)
        internal
        view
        returns (bool)
    {
        return !_globalRoleMembers[role][account];
    }

    /**
     * @dev Override for a custom revert message.
     */
    function _revertMessageAlreadyHasGlobalRole(bytes32 role, address account)
        internal
        view
        virtual
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "RoleMembership: account ",
                    StringsUpgradeable.toHexString(uint160(account), 20),
                    " already has role ",
                    StringsUpgradeable.toHexString(uint256(role), 32)
                )
            );
    }

    /**
     * @dev Override the function for a custom revert message.
     */
    function _revertMessageAlreadyHasDaoRole(
        uint256 daoId,
        bytes32 role,
        address account
    ) internal view virtual returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "RoleMembership: account ",
                    StringsUpgradeable.toHexString(uint160(account), 20),
                    " already has role ",
                    StringsUpgradeable.toHexString(uint256(role), 32),
                    " in DAO ",
                    StringsUpgradeable.toHexString(daoId, 32)
                )
            );
    }

    /**
     * @dev Override the function for a custom revert message.
     */
    function _revertMessageMissingGlobalRole(bytes32 role, address account)
        internal
        view
        virtual
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "RoleMembership: account ",
                    StringsUpgradeable.toHexString(uint160(account), 20),
                    " is missing role ",
                    StringsUpgradeable.toHexString(uint256(role), 32)
                )
            );
    }

    /**
     * @dev Override the function for a custom revert message.
     */
    function _revertMessageMissingDaoRole(
        uint256 daoId,
        bytes32 role,
        address account
    ) internal view virtual returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "RoleMembership: account ",
                    StringsUpgradeable.toHexString(uint160(account), 20),
                    " is missing role ",
                    StringsUpgradeable.toHexString(uint256(role), 32),
                    " in DAO ",
                    StringsUpgradeable.toHexString(daoId, 32)
                )
            );
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 * @title Roles within the hierarchical DAO access control schema.
 *
 * @notice Similar to a Linux permission system there is a super user, with some of the other roles being tiered
 *          amongst each other.
 *
 *  SUPER_USER role the manage for DAO_CREATOR roles, in addition to being a super set to to all other roles functions.
 *  DAO_CREATOR role only business is creating DAOs and their configurations.
 *  DAO_ADMIN role can update the DAOs configuration and may intervene to sweep / flush.
 *  DAO_MEEPLE role is deals with the life cycle of the DAOs products.
 *  SYSTEM_ADMIN role deals with tasks such as pause-ability and the upgrading of contract.
 */
library Roles {
    bytes32 public constant DAO_ADMIN = "DAO_ADMIN";
    bytes32 public constant DAO_CREATOR = "DAO_CREATOR";
    bytes32 public constant DAO_MEEPLE = "DAO_MEEPLE";
    bytes32 public constant SUPER_USER = "SUPER_USER";
    bytes32 public constant SYSTEM_ADMIN = "SYSTEM_ADMIN";
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/**
 * @title Abstract upgradeable contract providing the ability to sweep tokens to a nominated beneficiary address.
 *
 * @dev Access control implementation is required for many functions by design.
 */
abstract contract TokenSweep is ContextUpgradeable {
    address private _beneficiary;

    event BeneficiaryUpdate(
        address indexed beneficiary,
        address indexed instigator
    );

    function tokenSweepBeneficiary() public view returns (address) {
        return _beneficiary;
    }

    //slither-disable-next-line naming-convention
    function __TokenSweep_init(address beneficiary) internal onlyInitializing {
        __Context_init();
        _setTokenSweepBeneficiary(beneficiary);
    }

    /**
     * @notice Sets the beneficiary of the token sweep.
     *
     * @dev Needs access control implemented in the inheriting contract.
     *
     * @param newBeneficiary The address to replace as the nominated beneficiary of any sweeping.
     */
    function _setTokenSweepBeneficiary(address newBeneficiary) internal {
        require(newBeneficiary != address(0), "TokenSweep: beneficiary zero");
        require(newBeneficiary != address(this), "TokenSweep: self address");
        require(newBeneficiary != _beneficiary, "TokenSweep: beneficiary same");

        _beneficiary = newBeneficiary;
        emit BeneficiaryUpdate(newBeneficiary, _msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
interface IERC20PermitUpgradeable {
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../sweep/SweepERC20.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract SweepERC20TokensHarness is SweepERC20 {
    function setBeneficiary(address beneficiary) external {
        _setTokenSweepBeneficiary(beneficiary);
    }

    function sweepERC20Tokens(address token, uint256 amount) external {
        _sweepERC20Tokens(token, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/presets/ERC20PresetMinterPauser.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../extensions/ERC20Burnable.sol";
import "../extensions/ERC20Pausable.sol";
import "../../../access/AccessControlEnumerable.sol";
import "../../../utils/Context.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 *
 * _Deprecated in favor of https://wizard.openzeppelin.com/[Contracts Wizard]._
 */
contract ERC20PresetMinterPauser is Context, AccessControlEnumerable, ERC20Burnable, ERC20Pausable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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
        return _values(set._inner);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is ERC721, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./StakingPool.sol";
import "./StakingPoolLib.sol";
import "./StakingPoolCreator.sol";
import "../Version.sol";
import "../sweep/SweepERC20.sol";

contract StakingPoolFactory is
    OwnableUpgradeable,
    PausableUpgradeable,
    StakingPoolCreator,
    SweepERC20,
    Version
{
    event StakingPoolCreated(
        address indexed stakingPool,
        StakingPoolLib.Config config,
        address indexed creator
    );

    constructor(address beneficiary) initializer {
        __Pausable_init();
        __Ownable_init();
        __TokenSweep_init(beneficiary);
    }

    function pause() external whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() external whenPaused onlyOwner {
        _unpause();
    }

    function createStakingPool(
        StakingPoolLib.Config calldata config,
        bool launchPaused,
        uint32 rewardsAvailableTimestamp
    ) external override whenNotPaused returns (address) {
        StakingPool stakingPool = new StakingPool();

        emit StakingPoolCreated(address(stakingPool), config, _msgSender());

        stakingPool.initialize(
            config,
            launchPaused,
            rewardsAvailableTimestamp,
            config.treasury
        );
        stakingPool.transferOwnership(_msgSender());

        return address(stakingPool);
    }

    function updateTokenSweepBeneficiary(address newBeneficiary)
        external
        whenNotPaused
        onlyOwner
    {
        _setTokenSweepBeneficiary(newBeneficiary);
    }

    function sweepERC20Tokens(address tokens, uint256 amount)
        external
        whenNotPaused
        onlyOwner
    {
        _sweepERC20Tokens(tokens, amount);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../Version.sol";
import "./BaseBox.sol";

/**
 * @title An upgradable storage box for a string.
 *
 * @notice The storage box can store a single string value, emit an event and also retrieve the stored value.
 *
 * @dev Event emitted on storing the value.
 */
contract Box is BaseBox, Version {

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title An upgradable storage box for a string.
 *
 * @notice The storage box can store a single string value, emit an event and also retrieve the stored value.
 *
 * @dev Event emitted on storing the value.
 */
abstract contract BaseBox is OwnableUpgradeable, UUPSUpgradeable {
    string private _value;

    event Store(string value);

    /**
     * @notice Permits the owner to store a value.
     *
     * @dev storing the value causes the Store event to be emitted, overwriting any previously stored value.
     *
     * @param boxValue value for storage in the Box, no restrictions.
     */
    function store(string calldata boxValue) external onlyOwner {
        _value = boxValue;

        emit Store(_value);
    }

    /**
     * @notice retrieves the stored value.
     *
     * @dev the Box stores only a single value.
     *
     * @return store value, which could be uninitialized.
     */
    function value() external view returns (string memory) {
        return _value;
    }

    /**
     * @notice An initializer instead of a constructor.
     *
     * @dev Compared to a constructor, an init adds deployment cost (as constructor code is executed but not deployed).
     *      However when used in conjunction with a proxy, the init means the contract can be upgraded.
     */
    function initialize() public virtual initializer {}

    /**
     * @notice Permits only the owner to perform proxy upgrades.
     *
     * @dev Only applicable when deployed as implementation to a UUPS proxy.
     */
    function _authorizeUpgrade(address newImplementation) internal override {}
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./Box.sol";

contract MockUpgradedVersion {
    string public constant VERSION = "mock_tag";
}

contract VeryLongVersionTag {
    // ascii chars in UFT-8 encoding take 1 byte. We want a tag that has > 256 bits * 2 = 64 bytes long => 65 ascii chars
    string public constant VERSION =
        "blahblahblahblahblahblahblahblahblahblahblahblahblahblahblahblahb"; // 65 chars long
}

/**
 * Contract adding a variable create a unique contract, that a Box may be upgraded as.
 */
contract BoxExtension is BaseBox, MockUpgradedVersion {

}

contract BoxExtensionWithVeryLongVersionTag is BaseBox, VeryLongVersionTag {}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./PerformanceBond.sol";
import "../RoleAccessControl.sol";
import "./PerformanceBondCreator.sol";
import "./PerformanceBondCurator.sol";
import "../Roles.sol";
import "../Version.sol";

/**
 * @title Entry point for the PerformanceBond family of contract.
 *
 * @dev Orchestrates the various PerformanceBond contracts to provide a single function to aggregate the various calls.
 */
interface PerformanceBondPortal {
    /**
     * @notice Initialises a new DAO with essential configuration.
     *
     * @param erc20CapableTreasury Treasury that receives forfeited collateral. Must not be address zero.
     * @return ID for the created DAO.
     */
    function createDao(address erc20CapableTreasury) external returns (uint256);

    /**
     * @notice Creates a new PerformanceBond, registering with the manager.
     *
     * @dev Creates a new PerformanceBond with the creator and registers it with the curator.
     */
    function createManagedPerformanceBond(
        uint256 daoId,
        PerformanceBond.MetaData calldata metadata,
        PerformanceBond.Settings calldata configuration,
        PerformanceBond.TimeLockRewardPool[] calldata rewards
    ) external returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
 * @title Domain model for Performance Bonds.
 */
library PerformanceBond {
    struct MetaData {
        /** Description of the purpose for the Performance Bond. */
        string name;
        /** Abbreviation to identify the Performance Bond. */
        string symbol;
        /** Metadata bucket not required for the operation of the Performance Bond, but needed by external actors. */
        string data;
    }

    struct Settings {
        /** Number of tokens to create, which get swapped for collateral tokens by depositing. */
        uint256 debtTokenAmount;
        /** Token contract for the collateral that is swapped for debt tokens during deposit. */
        address collateralTokens;
        /**
         * Unix timestamp for when the Bond is expired and anyone can move the remaining collateral to the Treasury,
         * then petitions may be made for redemption.
         */
        uint256 expiryTimestamp;
        /**
         * Minimum debt holding allowed in the deposit phase. Once the minimum is met,
         * any sized deposit from that account is allowed, as the minimum has already been met.
         */
        uint256 minimumDeposit;
    }

    struct TimeLockRewardPool {
        /** Tokens being used for the reward. */
        address tokens;
        /** Total number of tokens awarded to guarantors. */
        uint128 amount;
        /** Seconds reward is locked up after redemption is allowed. */
        uint128 timeLock;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./PerformanceBond.sol";

/**
 * @title Deploys new PerformanceBonds.
 *
 * @notice Creating a Performance Bond involves the two steps of deploying and initialising.
 */
interface PerformanceBondCreator {
    /**
     * @notice Deploys and initialises a new PerformanceBond.
     *
     * @param metadata General details about the Bond no essential for operation.
     * @param configuration Values to use during the Bond creation process.
     * @param rewards Motivation for the guarantors to deposit, available after redemption.
     * @param treasury Receiver of any slashed or swept tokens or collateral.
     */
    function createPerformanceBond(
        PerformanceBond.MetaData calldata metadata,
        PerformanceBond.Settings calldata configuration,
        PerformanceBond.TimeLockRewardPool[] calldata rewards,
        address treasury
    ) external returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "../RoleAccessControl.sol";
import "./SingleCollateralPerformanceBond.sol";

/**
 * @title Manages interactions with Performance Bond contracts.
 *
 * @notice A central place to discover created Performance Bonds and apply access control to them.
 *
 * @dev Owns of all Performance Bonds that it manages, with guarding function providing finer access control.
 */
abstract contract PerformanceBondCurator is
    RoleAccessControl,
    PausableUpgradeable
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(uint256 => EnumerableSetUpgradeable.AddressSet) private _bonds;

    event AddPerformanceBond(
        uint256 indexed daoId,
        address indexed bond,
        address indexed instigator
    );

    function performanceBondAllowRedemption(
        uint256 daoId,
        address bond,
        string calldata reason
    ) external whenNotPaused atLeastDaoMeepleRole(daoId) {
        _requireManagingBond(daoId, bond);

        SingleCollateralPerformanceBond(bond).allowRedemption(reason);
    }

    function performanceBondPause(uint256 daoId, address bond)
        external
        whenNotPaused
        atLeastDaoAdminRole(daoId)
    {
        _requireManagingBond(daoId, bond);

        SingleCollateralPerformanceBond(bond).pause();
    }

    function performanceBondSlash(
        uint256 daoId,
        address bond,
        uint256 amount,
        string calldata reason
    ) external whenNotPaused atLeastDaoMeepleRole(daoId) {
        _requireManagingBond(daoId, bond);

        SingleCollateralPerformanceBond(bond).slash(amount, reason);
    }

    function performanceBondSetMetaData(
        uint256 daoId,
        address bond,
        string calldata data
    ) external whenNotPaused atLeastDaoMeepleRole(daoId) {
        _requireManagingBond(daoId, bond);

        SingleCollateralPerformanceBond(bond).setMetaData(data);
    }

    function performanceBondSetTreasury(
        uint256 daoId,
        address bond,
        address replacement
    ) external whenNotPaused atLeastDaoAdminRole(daoId) {
        _requireManagingBond(daoId, bond);

        SingleCollateralPerformanceBond(bond).setTreasury(replacement);
    }

    function performanceBondSweepERC20Tokens(
        uint256 daoId,
        address bond,
        address tokens,
        uint256 amount
    ) external whenNotPaused atLeastDaoAdminRole(daoId) {
        _requireManagingBond(daoId, bond);

        SingleCollateralPerformanceBond(bond).sweepERC20Tokens(tokens, amount);
    }

    function performanceBondUpdateRewardTimeLock(
        uint256 daoId,
        address bond,
        address tokens,
        uint128 timeLock
    ) external whenNotPaused atLeastDaoAdminRole(daoId) {
        _requireManagingBond(daoId, bond);

        SingleCollateralPerformanceBond(bond).updateRewardTimeLock(
            tokens,
            timeLock
        );
    }

    function performanceBondUnpause(uint256 daoId, address bond)
        external
        whenNotPaused
        atLeastDaoAdminRole(daoId)
    {
        _requireManagingBond(daoId, bond);

        SingleCollateralPerformanceBond(bond).unpause();
    }

    function performanceBondWithdrawCollateral(uint256 daoId, address bond)
        external
        whenNotPaused
        atLeastDaoAdminRole(daoId)
    {
        _requireManagingBond(daoId, bond);

        SingleCollateralPerformanceBond(bond).withdrawCollateral();
    }

    /**
     * @notice Pauses most side affecting functions.
     */
    function pause() external whenNotPaused atLeastSysAdminRole {
        _pause();
    }

    /**
     * @notice Resumes all paused side affecting functions.
     */
    function unpause() external whenPaused atLeastSysAdminRole {
        _unpause();
    }

    function performanceBondAt(uint256 daoId, uint256 index)
        external
        view
        returns (address)
    {
        require(
            index < EnumerableSetUpgradeable.length(_bonds[daoId]),
            "BondCurator: too large"
        );

        return EnumerableSetUpgradeable.at(_bonds[daoId], index);
    }

    function performanceBondCount(uint256 daoId)
        external
        view
        returns (uint256)
    {
        return EnumerableSetUpgradeable.length(_bonds[daoId]);
    }

    function _addBond(uint256 daoId, address bond) internal whenNotPaused {
        require(!_bonds[daoId].contains(bond), "BondCurator: already managing");
        require(
            OwnableUpgradeable(bond).owner() == address(this),
            "BondCurator: not bond owner"
        );

        emit AddPerformanceBond(daoId, bond, _msgSender());

        bool added = _bonds[daoId].add(bond);
        require(added, "BondCurator: failed to add");
    }

    //slither-disable-next-line naming-convention
    function __BondCurator_init() internal onlyInitializing {
        __RoleAccessControl_init();
        __Pausable_init();
    }

    function _requireManagingBond(uint256 daoId, address bond) private view {
        require(_bonds[daoId].contains(bond), "BondCurator: not managing");
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface SingleCollateralPerformanceBond {
    /**
     * @notice Transitions the PerformanceBond state, from being non-redeemable (accepting deposits and slashing) to
     *          redeemable (accepting redeem and withdraw collateral).
     *
     * @dev Debt tokens are not allowed to be redeemed before the owner grants permission.
     */
    function allowRedemption(string calldata reason) external;

    /**
     * @notice Deposit swaps collateral tokens for an equal amount of debt tokens.
     *
     * @dev Before the deposit can be made, this contract must have been approved to transfer the given amount
     * from the ERC20 token being used as collateral.
     *
     * @param amount The number of collateral token to transfer from the _msgSender().
     *          Must be in the range of one to the number of debt tokens available for swapping.
     *          The _msgSender() receives the debt tokens.
     */
    function deposit(uint256 amount) external;

    /**
     * @notice Pauses most side affecting functions.
     *
     * @dev The ony side effecting (non view or pure function) function exempt from pausing is expire().
     */
    function pause() external;

    /**
     * @notice Redeem swaps debt tokens for collateral tokens.
     *
     * @dev Converts the amount of debt tokens owned by the sender, at the exchange ratio determined by the remaining
     *  amount of collateral against the remaining amount of debt.
     *  There are operations that reduce the held collateral, while the debt remains constant.
     *
     * @param amount The number of debt token to transfer from the sender.
     *          Must be in the range of one to the number of debt tokens available for swapping.
     */
    function redeem(uint256 amount) external;

    /**
     * @notice Sweep any non collateral ERC20 tokens to the beneficiary address
     *
     * @param tokens The registry for the ERC20 token to transfer,
     * @param amount How many tokens, in the ERC20's decimals to transfer.
     */
    function sweepERC20Tokens(address tokens, uint256 amount) external;

    /**
     * @notice Resumes all paused side affecting functions.
     */
    function unpause() external;

    /**
     * @notice Enact a penalty for guarantors, a loss of a portion of their bonded collateral.
     *          The designated Treasury is the recipient for the slashed collateral.
     *
     * @dev The penalty can range between one and all of the collateral.
     *
     * As the amount of debt tokens remains the same. Slashing reduces the collateral tokens, so each debt token
     * is redeemable for less collateral, altering the redemption ratio calculated on allowRedemption().
     *
     * @param amount The number of bonded collateral token to transfer from the Bond to the Treasury.
     *          Must be in the range of one to the number of collateral tokens held by the Bond.
     */
    function slash(uint256 amount, string calldata reason) external;

    /**
     * @notice Replaces any stored metadata.
     *
     * @dev As metadata is not pertinent for PerformanceBond operations, this may be anything e.g. a delimitated string.
     *
     * @param data Information useful for off-chain actions e.g. performance factor, assessment date, rewards pool.
     */
    function setMetaData(string calldata data) external;

    /**
     * @notice Permits the owner to update the Treasury address.
     *
     * @dev treasury is the recipient of slashed, expired or withdrawn collateral.
     *          Must be a non-zero address.
     *
     * @param replacement Treasury recipient for future operations. Must not be zero address.
     */
    function setTreasury(address replacement) external;

    /**
     * @notice Overwrites the existing time lock for a Bond reward.
     *
     * @param tokens ERC20 rewards already registered.
     * @param timeLock seconds to lock rewards after redemption is allowed.
     */
    function updateRewardTimeLock(address tokens, uint128 timeLock) external;

    /**
     * @notice Permits the owner to transfer all collateral held by the Bond to the Treasury.
     *
     * @dev Intention is to sweeping up excess collateral from redemption ration calculation, such as  when there has
     *      been slashing. Slashing can result in collateral remaining due to flooring.
     *
     *  Can also provide an emergency extracting moving of funds out of the Bond by the owner.
     */
    function withdrawCollateral() external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./SingleCollateralMultiRewardPerformanceBond.sol";
import "./ERC20SingleCollateralPerformanceBond.sol";
import "../RoleAccessControl.sol";
import "./PerformanceBondCreator.sol";
import "../Roles.sol";
import "../Version.sol";
import "../sweep/SweepERC20.sol";

/**
 * @title Creates Performance Bond contracts.
 *
 * @dev An upgradable contract that encapsulates the Bond implementation and associated deployment cost.
 */
contract PerformanceBondFactory is
    PerformanceBondCreator,
    OwnableUpgradeable,
    PausableUpgradeable,
    SweepERC20,
    Version
{
    event CreatePerformanceBond(
        address indexed bond,
        PerformanceBond.MetaData metadata,
        PerformanceBond.Settings configuration,
        PerformanceBond.TimeLockRewardPool[] rewards,
        address indexed treasury,
        address indexed instigator
    );

    constructor(address treasury) initializer {
        __Ownable_init();
        __TokenSweep_init(treasury);
    }

    function createPerformanceBond(
        PerformanceBond.MetaData calldata metadata,
        PerformanceBond.Settings calldata configuration,
        PerformanceBond.TimeLockRewardPool[] calldata rewards,
        address treasury
    ) external override whenNotPaused returns (address) {
        SingleCollateralMultiRewardPerformanceBond bond = new SingleCollateralMultiRewardPerformanceBond();

        emit CreatePerformanceBond(
            address(bond),
            metadata,
            configuration,
            rewards,
            treasury,
            _msgSender()
        );

        bond.initialize(metadata, configuration, rewards, treasury);
        bond.transferOwnership(_msgSender());

        return address(bond);
    }

    /**
     * @notice Pauses most side affecting functions.
     */
    function pause() external whenNotPaused onlyOwner {
        _pause();
    }

    function setTokenSweepBeneficiary(address newBeneficiary)
        external
        whenNotPaused
        onlyOwner
    {
        _setTokenSweepBeneficiary(newBeneficiary);
    }

    /**
     * @notice Resumes all paused side affecting functions.
     */
    function unpause() external whenPaused onlyOwner {
        _unpause();
    }

    function sweepERC20Tokens(address tokens, uint256 amount)
        external
        whenNotPaused
        onlyOwner
    {
        _sweepERC20Tokens(tokens, amount);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ERC20SingleCollateralPerformanceBond.sol";
import "./TimeLockMultiRewardPerformanceBond.sol";
import "./PerformanceBond.sol";

contract SingleCollateralMultiRewardPerformanceBond is
    ERC20SingleCollateralPerformanceBond,
    TimeLockMultiRewardPerformanceBond
{
    function allowRedemption(string calldata reason) external override {
        _allowRedemption(reason);
        _setRedemptionTimestamp(uint128(block.timestamp));
    }

    function deposit(uint256 amount) external override {
        address claimant = _msgSender();
        uint256 claimantDebt = balanceOf(claimant) + amount;
        _calculateRewardDebt(claimant, claimantDebt, totalSupply());
        _deposit(amount);
    }

    function initialize(
        PerformanceBond.MetaData calldata metadata,
        PerformanceBond.Settings calldata configuration,
        PerformanceBond.TimeLockRewardPool[] calldata rewards,
        address erc20CapableTreasury
    ) external initializer {
        __ERC20SingleCollateralBond_init(
            metadata,
            configuration,
            erc20CapableTreasury
        );
        __TimeLockMultiRewardBond_init(rewards);
    }

    function updateRewardTimeLock(address tokens, uint128 timeLock)
        external
        override
        onlyOwner
    {
        _updateRewardTimeLock(tokens, timeLock);
    }

    /**
     * @dev When debt tokens are transferred before redemption is allowed, the new holder gains full proportional
     *      rewards for the new holding of debt tokens, while the previous holder looses any entitlement.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (amount > 0 && !redeemable()) {
            uint256 supply = totalSupply();
            _calculateRewardDebt(from, balanceOf(from), supply);
            _calculateRewardDebt(to, balanceOf(to), supply);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./ExpiryTimestamp.sol";
import "./SingleCollateralPerformanceBond.sol";
import "./MetaDataStore.sol";
import "./Redeemable.sol";
import "../Version.sol";
import "./PerformanceBond.sol";
import "../sweep/SweepERC20.sol";

/**
 * @title A PerformanceBond is an issuance of debt tokens, which are exchange for deposit of collateral.
 *
 * @notice A single type of ERC20 token is accepted as collateral.
 *
 * The PerformanceBond uses a single redemption model. Before redemption, receiving and slashing collateral is permitted,
 * while after redemption, redeem (by guarantors) or complete withdrawal (by owner) is allowed.
 *
 * @dev A single token type is held by the contract as collateral, with the PerformanceBond ERC20 token being the debt.
 */
abstract contract ERC20SingleCollateralPerformanceBond is
    ERC20Upgradeable,
    ExpiryTimestamp,
    SingleCollateralPerformanceBond,
    MetaDataStore,
    OwnableUpgradeable,
    PausableUpgradeable,
    Redeemable,
    SweepERC20,
    Version
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct Slash {
        string reason;
        uint256 collateralAmount;
    }

    Slash[] private _slashes;

    // Multiplier / divider for four decimal places, used in redemption ratio calculation.
    uint256 private constant _REDEMPTION_RATIO_ACCURACY = 1e4;

    /*
     * Collateral that is held by the bond, owed to the Guarantors (unless slashed).
     *
     * Kept to guard against the edge case of collateral tokens being directly transferred
     * (i.e. transfer in the collateral contract, not via deposit) to the contract address inflating redemption amounts.
     */
    uint256 private _collateral;

    uint256 private _collateralSlashed;

    address private _collateralTokens;

    uint256 private _debtTokensInitialSupply;

    // Balance of debts tokens held by guarantors, double accounting avoids potential affects of any minting/burning
    uint256 private _debtTokensOutstanding;

    // Balance of debt tokens held by the Bond when redemptions were allowed.
    uint256 private _debtTokensRedemptionExcess;

    // Minimum debt holding allowed in the pre-redemption state.
    uint256 private _minimumDeposit;

    /*
     * Ratio value between one (100% bond redeem) and zero (0% redeem), accuracy defined by _REDEMPTION_RATIO_ACCURACY.
     *
     * Calculated only once, when the redemption is allowed. Ratio will be one, unless slashing has occurred.
     */
    uint256 private _redemptionRatio;

    address private _treasury;

    event AllowRedemption(address indexed authorizer, string reason);
    event DebtIssue(
        address indexed receiver,
        address indexed debTokens,
        uint256 debtAmount
    );
    event Deposit(
        address indexed depositor,
        address indexed collateralTokens,
        uint256 collateralAmount
    );
    event Expire(
        address indexed treasury,
        address indexed collateralTokens,
        uint256 collateralAmount,
        address indexed instigator
    );
    event PartialCollateral(
        address indexed collateralTokens,
        uint256 collateralAmount,
        address indexed debtTokens,
        uint256 debtRemaining,
        address indexed instigator
    );
    event FullCollateral(
        address indexed collateralTokens,
        uint256 collateralAmount,
        address indexed instigator
    );
    event Redemption(
        address indexed redeemer,
        address indexed debtTokens,
        uint256 debtAmount,
        address indexed collateralTokens,
        uint256 collateralAmount
    );
    event SlashDeposits(
        address indexed collateralTokens,
        uint256 collateralAmount,
        string reason,
        address indexed instigator
    );
    event WithdrawCollateral(
        address indexed treasury,
        address indexed collateralTokens,
        uint256 collateralAmount,
        address indexed instigator
    );

    /**
     *  @notice Moves all remaining collateral to the Treasury and pauses the bond.
     *
     *  @dev A fail safe, callable by anyone after the Bond has expired.
     *       If control is lost, this can be used to move all remaining collateral to the Treasury,
     *       after which petitions for redemption can be made.
     *
     *  Expiry operates separately to pause, so a paused contract can be expired (fail safe for loss of control).
     */
    function expire() external whenBeyondExpiry {
        uint256 collateralBalance = IERC20Upgradeable(_collateralTokens)
            .balanceOf(address(this));
        require(collateralBalance > 0, "Bond: no collateral remains");

        emit Expire(
            _treasury,
            _collateralTokens,
            collateralBalance,
            _msgSender()
        );

        IERC20Upgradeable(_collateralTokens).safeTransfer(
            _treasury,
            collateralBalance
        );

        _pauseSafely();
    }

    function pause() external override whenNotPaused onlyOwner {
        _pause();
    }

    function redeem(uint256 amount)
        external
        override
        whenNotPaused
        whenRedeemable
    {
        require(amount > 0, "Bond: too small");
        require(balanceOf(_msgSender()) >= amount, "Bond: too few debt tokens");

        uint256 totalSupply = totalSupply() - _debtTokensRedemptionExcess;
        uint256 redemptionAmount = _redemptionAmount(amount, totalSupply);
        _collateral -= redemptionAmount;
        _debtTokensOutstanding -= redemptionAmount;

        emit Redemption(
            _msgSender(),
            address(this),
            amount,
            _collateralTokens,
            redemptionAmount
        );

        _burn(_msgSender(), amount);

        // Slashing can reduce redemption amount to zero
        if (redemptionAmount > 0) {
            IERC20Upgradeable(_collateralTokens).safeTransfer(
                _msgSender(),
                redemptionAmount
            );
        }
    }

    function unpause() external override whenPaused onlyOwner {
        _unpause();
    }

    function slash(uint256 amount, string calldata reason)
        external
        override
        whenNotPaused
        whenNotRedeemable
        onlyOwner
    {
        require(amount > 0, "Bond: too small");
        require(amount <= _collateral, "Bond: too large");

        _collateral -= amount;
        _collateralSlashed += amount;

        emit SlashDeposits(_collateralTokens, amount, reason, _msgSender());

        _slashes.push(Slash(reason, amount));

        IERC20Upgradeable(_collateralTokens).safeTransfer(_treasury, amount);
    }

    function setMetaData(string calldata data)
        external
        override
        whenNotPaused
        onlyOwner
    {
        return _setMetaData(data);
    }

    function setTreasury(address replacement)
        external
        override
        whenNotPaused
        onlyOwner
    {
        require(replacement != address(0), "Bond: treasury is zero address");
        _treasury = replacement;
        _setTokenSweepBeneficiary(replacement);
    }

    function sweepERC20Tokens(address tokens, uint256 amount)
        external
        override
        whenNotPaused
        onlyOwner
    {
        require(tokens != _collateralTokens, "Bond: no collateral sweeping");
        _sweepERC20Tokens(tokens, amount);
    }

    function withdrawCollateral()
        external
        override
        whenNotPaused
        whenRedeemable
        onlyOwner
    {
        uint256 collateralBalance = IERC20Upgradeable(_collateralTokens)
            .balanceOf(address(this));
        require(collateralBalance > 0, "Bond: no collateral remains");

        emit WithdrawCollateral(
            _treasury,
            _collateralTokens,
            collateralBalance,
            _msgSender()
        );

        IERC20Upgradeable(_collateralTokens).safeTransfer(
            _treasury,
            collateralBalance
        );
    }

    /**
     * @notice How much collateral held by the bond is owned to the Guarantors.
     *
     * @dev Collateral has come from guarantors, with the balance changes on deposit, redeem, slashing and flushing.
     *      This value may differ to balanceOf(this), if collateral tokens have been directly transferred
     *      i.e. direct transfer interaction with the token contract, rather then using the Bond functions.
     */
    function collateral() external view returns (uint256) {
        return _collateral;
    }

    /**
     * @notice The ERC20 contract being used as collateral.
     */
    function collateralTokens() external view returns (address) {
        return address(_collateralTokens);
    }

    /**
     * @notice Sum of collateral moved from the bond to the Treasury by slashing.
     *
     * @dev Other methods of performing moving of collateral outside of slashing, are not included.
     */
    function collateralSlashed() external view returns (uint256) {
        return _collateralSlashed;
    }

    /**
     * @notice Balance of debt tokens held by the bond.
     *
     * @dev Number of debt tokens that can still be swapped for collateral token (if before redemption state),
     *          or the amount of under-collateralization (if during redemption state).
     *
     */
    function debtTokens() external view returns (uint256) {
        return _debtTokensRemaining();
    }

    /**
     * @notice Balance of debt tokens held by the guarantors.
     *
     * @dev Number of debt tokens still held by Guarantors. The number only reduces when guarantors redeem
     *          (swap their debt tokens for collateral).
     */
    function debtTokensOutstanding() external view returns (uint256) {
        return _debtTokensOutstanding;
    }

    /**
     * @notice Balance of debt tokes outstanding when the redemption state was entered.
     *
     * @dev As the collateral deposited is a 1:1, this is amount of collateral that was not received.
     *
     * @return zero if redemption is not yet allowed or full collateral was met, otherwise the number of debt tokens
     *          remaining without matched deposit when redemption was allowed,
     */
    function excessDebtTokens() external view returns (uint256) {
        return _debtTokensRedemptionExcess;
    }

    /**
     * @notice Debt tokens created on initialization.
     *
     * @dev Number of debt tokens minted on init. The total supply of debt tokens will decrease, as redeem burns them.
     */
    function initialDebtTokens() external view returns (uint256) {
        return _debtTokensInitialSupply;
    }

    /**
     * @notice Minimum amount of debt allowed.
     *
     * @dev Avoids micro holdings, as some operations cost scale linear to debt holders.
     *      Once an account holds the minimum, any deposit from is acceptable as their holding is above the minimum.
     */
    function minimumDeposit() external view returns (uint256) {
        return _minimumDeposit;
    }

    function treasury() external view returns (address) {
        return _treasury;
    }

    function getSlashes() external view returns (Slash[] memory) {
        return _slashes;
    }

    function getSlashByIndex(uint256 index)
        external
        view
        returns (Slash memory)
    {
        require(index < _slashes.length, "Bond: slash does not exist");
        return _slashes[index];
    }

    function hasFullCollateral() public view returns (bool) {
        return _debtTokensRemaining() == 0;
    }

    //slither-disable-next-line naming-convention
    function __ERC20SingleCollateralBond_init(
        PerformanceBond.MetaData calldata metadata,
        PerformanceBond.Settings calldata configuration,
        address erc20CapableTreasury
    ) internal onlyInitializing {
        require(
            erc20CapableTreasury != address(0),
            "Bond: treasury is zero address"
        );
        require(
            configuration.collateralTokens != address(0),
            "Bond: collateral is zero address"
        );

        __ERC20_init(metadata.name, metadata.symbol);
        __Ownable_init();
        __Pausable_init();
        __ExpiryTimestamp_init(configuration.expiryTimestamp);
        __MetaDataStore_init(metadata.data);
        __Redeemable_init();
        __TokenSweep_init(erc20CapableTreasury);

        _collateralTokens = configuration.collateralTokens;
        _debtTokensInitialSupply = configuration.debtTokenAmount;
        _minimumDeposit = configuration.minimumDeposit;
        _treasury = erc20CapableTreasury;

        _mint(configuration.debtTokenAmount);
    }

    function _allowRedemption(string calldata reason)
        internal
        whenNotPaused
        whenNotRedeemable
        onlyOwner
    {
        _setAsRedeemable(reason);
        emit AllowRedemption(_msgSender(), reason);

        if (_hasDebtTokensRemaining()) {
            _debtTokensRedemptionExcess = _debtTokensRemaining();

            emit PartialCollateral(
                _collateralTokens,
                IERC20Upgradeable(_collateralTokens).balanceOf(address(this)),
                address(this),
                _debtTokensRemaining(),
                _msgSender()
            );
        }

        if (_hasBeenSlashed()) {
            _redemptionRatio = _calculateRedemptionRatio();
        }
    }

    function _deposit(uint256 amount) internal whenNotPaused whenNotRedeemable {
        require(amount > 0, "Bond: too small");
        require(amount <= _debtTokensRemaining(), "Bond: too large");
        require(
            balanceOf(_msgSender()) + amount >= _minimumDeposit,
            "Bond: below minimum"
        );

        _collateral += amount;
        _debtTokensOutstanding += amount;

        emit Deposit(_msgSender(), _collateralTokens, amount);

        IERC20Upgradeable(_collateralTokens).safeTransferFrom(
            _msgSender(),
            address(this),
            amount
        );

        emit DebtIssue(_msgSender(), address(this), amount);

        _transfer(address(this), _msgSender(), amount);

        if (hasFullCollateral()) {
            emit FullCollateral(
                _collateralTokens,
                IERC20Upgradeable(_collateralTokens).balanceOf(address(this)),
                _msgSender()
            );
        }
    }

    /**
     * @dev Mints additional debt tokens, inflating the supply. Without additional deposits the redemption ratio is affected.
     */
    function _mint(uint256 amount) private whenNotPaused whenNotRedeemable {
        require(amount > 0, "Bond::mint: too small");
        _mint(address(this), amount);
    }

    /**
     *  @dev Pauses the Bond if not already paused. If already paused, does nothing (no revert).
     */
    function _pauseSafely() private {
        if (!paused()) {
            _pause();
        }
    }

    /**
     * @dev Collateral is deposited at a 1 to 1 ratio, however slashing can change that lower.
     */
    function _redemptionAmount(uint256 amount, uint256 totalSupply)
        private
        view
        returns (uint256)
    {
        if (_collateral == totalSupply) {
            return amount;
        } else {
            return _applyRedemptionRation(amount);
        }
    }

    function _applyRedemptionRation(uint256 amount)
        private
        view
        returns (uint256)
    {
        return (_redemptionRatio * amount) / _REDEMPTION_RATIO_ACCURACY;
    }

    /**
     * @return Redemption ration float value as an integer.
     *           The float has been multiplied by _REDEMPTION_RATIO_ACCURACY, with any excess accuracy floored (lost).
     */
    function _calculateRedemptionRatio() private view returns (uint256) {
        return
            (_REDEMPTION_RATIO_ACCURACY * _collateral) /
            (totalSupply() - _debtTokensRedemptionExcess);
    }

    /**
     * @dev The balance of debt token held; amount of debt token that are awaiting collateral swap.
     */
    function _debtTokensRemaining() private view returns (uint256) {
        return balanceOf(address(this));
    }

    /**
     * @dev Whether the Bond has been slashed. Assumes a 1:1 deposit ratio (collateral to debt).
     */
    function _hasBeenSlashed() private view returns (bool) {
        return _collateral != (totalSupply() - _debtTokensRedemptionExcess);
    }

    /**
     * @dev Whether the Bond has held debt tokens.
     */
    function _hasDebtTokensRemaining() private view returns (bool) {
        return _debtTokensRemaining() > 0;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./PerformanceBond.sol";

/**
 * @title Multiple reward with time lock support.
 *
 * @notice Supports multiple ERC20 rewards with an optional time lock on pull based claiming.
 *         Rewards are not accrued, rather they are given to token holder on redemption of their debt token.
 *
 * @dev Each reward has it's own time lock, allowing different rewards to be claimable at different points in time.
 *
 *      When a guarantor deposits collateral or transfers debt tokens (for a purpose other than redemption), then
 *      _calculateRewardDebt() must be called to keep their rewards updated.
 */
abstract contract TimeLockMultiRewardPerformanceBond is PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct ClaimableReward {
        address tokens;
        uint256 amount;
    }

    mapping(address => mapping(address => uint256))
        private _claimantToRewardPoolDebt;
    PerformanceBond.TimeLockRewardPool[] private _rewardPools;
    uint256 private _redemptionTimestamp;
    mapping(address => bool) private _tokensCounter;

    event ClaimReward(
        address indexed tokens,
        uint256 amount,
        address indexed instigator
    );
    event RegisterReward(
        address indexed tokens,
        uint256 amount,
        uint256 timeLock,
        address indexed instigator
    );
    event RewardDebt(
        address indexed tokens,
        address indexed claimant,
        uint256 rewardDebt,
        address indexed instigator
    );
    event RedemptionTimestampUpdate(
        uint256 timestamp,
        address indexed instigator
    );
    event RewardTimeLockUpdate(
        address indexed tokens,
        uint256 timeLock,
        address indexed instigator
    );

    /**
     * @notice Makes a function callable only when the contract has the redemption times set.
     *
     * @dev Reverts unless the redemption timestamp has been set.
     */
    modifier whenRedemptionTimestampSet() {
        require(_isRedemptionTimeSet(), "Rewards: redemption time not set");
        _;
    }

    /**
     * @notice Makes a function callable only when the contract has not yet had a redemption times set.
     *
     * @dev Reverts unless the redemption timestamp has been set.
     */
    modifier whenNoRedemptionTimestamp() {
        require(!_isRedemptionTimeSet(), "Rewards: redemption time set");
        _;
    }

    /**
     * @notice Claims any available rewards for the caller.
     *
     * @dev Rewards are claimable when their are registered and their time lock has expired.
     *
     *  NOTE: If there is nothing to claim, the function completes execution without revert. Handle this problem
     *        with UI. Only display a claim when there an available reward to claim.
     */
    function claimAllAvailableRewards()
        external
        whenNotPaused
        whenRedemptionTimestampSet
    {
        address claimant = _msgSender();

        for (uint256 i = 0; i < _rewardPools.length; i++) {
            PerformanceBond.TimeLockRewardPool
                storage rewardPool = _rewardPools[i];
            _claimReward(claimant, rewardPool);
        }
    }

    /**
     * @notice The set of total rewards outstanding for the PerformanceBond.
     *
     * @dev These rewards will be split proportionally between the debt holders.
     *
     *      After claiming, these value remain unchanged (as they are not used after redemption is allowed,
     *      only for calculations after deposits and transfers).
     *
     * NOTE: Values are copied to a memory array be wary of gas cost if call within a transaction!
     *       Expected usage is by view accessors that are queried without any gas fees.
     */
    function allRewardPools()
        external
        view
        returns (PerformanceBond.TimeLockRewardPool[] memory)
    {
        PerformanceBond.TimeLockRewardPool[]
            memory rewards = new PerformanceBond.TimeLockRewardPool[](
                _rewardPools.length
            );

        for (uint256 i = 0; i < _rewardPools.length; i++) {
            rewards[i] = _rewardPools[i];
        }
        return rewards;
    }

    /**
     * @notice Retrieves the set full set of rewards, with the amounts populated for only claimable rewards.
     *
     * @dev Rewards that are not yet claimable, or have already been claimed are zero.
     *
     * NOTE: Values are copied to a memory array be wary of gas cost if call within a transaction!
     *       Expected usage is by view accessors that are queried without any gas fees.
     */
    // Intentional use of timestamp for time lock expiry check
    //slither-disable-next-line timestamp
    function availableRewards()
        external
        view
        returns (ClaimableReward[] memory)
    {
        ClaimableReward[] memory rewards = new ClaimableReward[](
            _rewardPools.length
        );
        address claimant = _msgSender();

        for (uint256 i = 0; i < _rewardPools.length; i++) {
            PerformanceBond.TimeLockRewardPool
                storage rewardPool = _rewardPools[i];
            rewards[i].tokens = rewardPool.tokens;

            if (
                _hasTimeLockExpired(rewardPool) &&
                _hasRewardDebt(claimant, rewardPool)
            ) {
                rewards[i].amount = _rewardDebt(claimant, rewardPool);
            }
        }

        return rewards;
    }

    function redemptionTimestamp() external view returns (uint256) {
        return _redemptionTimestamp;
    }

    /**
     * @notice Reward debt currently assigned to claimant.
     *
     * @dev These rewards are the sum owed pending the time lock after redemption timestamp.
     */
    function rewardDebt(address claimant, address tokens)
        external
        view
        returns (uint256)
    {
        return _claimantToRewardPoolDebt[claimant][tokens];
    }

    /**
     * @notice Initial time locked reward pools available for participating in the PerformanceBond.
     *
     * @dev The initial configuration for the pools is retrieve .i.e. not decremented as rewards are claimed.
     *
     * NOTE: Values are copied to a memory array be wary of gas cost if call within a transaction!
     *       Expected usage is by view accessors that are queried without any gas fees.
     */
    function timeLockRewardPools()
        external
        view
        returns (PerformanceBond.TimeLockRewardPool[] memory)
    {
        return _rewardPools;
    }

    /**
     * @notice Calculate the rewards the claimant will be entitled to after redemption and corresponding lock up period.
     *
     * @dev Must be called when the guarantor deposits collateral or on transfer of debt tokens, but not when they
     *      the claimant redeems, otherwise you will erase their rewards.
     */
    function _calculateRewardDebt(
        address claimant,
        uint256 claimantDebtTokens,
        uint256 totalSupply
    ) internal whenNotPaused whenNoRedemptionTimestamp {
        require(claimantDebtTokens <= totalSupply, "Rewards: too much debt");

        for (uint256 i = 0; i < _rewardPools.length; i++) {
            PerformanceBond.TimeLockRewardPool
                storage rewardPool = _rewardPools[i];

            uint256 owed = (rewardPool.amount * claimantDebtTokens) /
                totalSupply;

            _claimantToRewardPoolDebt[claimant][rewardPool.tokens] = owed;
            emit RewardDebt(rewardPool.tokens, claimant, owed, _msgSender());
        }
    }

    function _updateRewardTimeLock(address tokens, uint128 timeLock)
        internal
        whenNotPaused
        whenNoRedemptionTimestamp
    {
        PerformanceBond.TimeLockRewardPool
            storage rewardPool = _rewardPoolByToken(tokens);

        rewardPool.timeLock = timeLock;

        emit RewardTimeLockUpdate(tokens, timeLock, _msgSender());
    }

    /**
     * @notice The time at which the debt tokens are redeemable.
     *
     * @dev Until a redemption time is set, no rewards are claimable.
     */
    function _setRedemptionTimestamp(uint128 timestamp)
        internal
        whenNotPaused
        whenNoRedemptionTimestamp
    {
        require(
            _isPresentOrFutureTime(timestamp),
            "Rewards: time already past"
        );

        _redemptionTimestamp = timestamp;

        emit RedemptionTimestampUpdate(timestamp, _msgSender());
    }

    /**
     * @param rewardPools Set of rewards claimable after a time lock following bond becoming redeemable.
     */
    //slither-disable-next-line naming-convention
    function __TimeLockMultiRewardBond_init(
        PerformanceBond.TimeLockRewardPool[] calldata rewardPools
    ) internal onlyInitializing {
        __Pausable_init();

        _enforceUniqueRewardTokens(rewardPools);
        _registerRewardPools(rewardPools);
    }

    /**
     * @dev When there are insufficient fund the transfer causes the transaction to revert,
     *      either as a revert in the ERC20 or when the return boolean is false.
     */
    function _claimReward(
        address claimant,
        PerformanceBond.TimeLockRewardPool storage rewardPool
    ) private {
        if (_hasTimeLockExpired(rewardPool)) {
            address tokens = rewardPool.tokens;
            uint256 amount = _claimantToRewardPoolDebt[claimant][tokens];
            delete _claimantToRewardPoolDebt[claimant][tokens];

            emit ClaimReward(tokens, amount, _msgSender());

            _transferReward(tokens, amount, claimant);
        }
    }

    function _registerRewardPools(
        PerformanceBond.TimeLockRewardPool[] memory rewardPools
    ) private {
        for (uint256 i = 0; i < rewardPools.length; i++) {
            _registerRewardPool(rewardPools[i]);
        }
    }

    function _registerRewardPool(
        PerformanceBond.TimeLockRewardPool memory rewardPool
    ) private {
        require(rewardPool.tokens != address(0), "Rewards: address is zero");
        require(rewardPool.amount > 0, "Rewards: no reward amount");

        emit RegisterReward(
            rewardPool.tokens,
            rewardPool.amount,
            rewardPool.timeLock,
            _msgSender()
        );

        _rewardPools.push(rewardPool);
    }

    // Claiming multiple rewards in a single function, looping is unavoidable
    //slither-disable-next-line calls-loop
    function _transferReward(
        address tokens,
        uint256 amount,
        address claimant
    ) private {
        IERC20Upgradeable(tokens).safeTransfer(claimant, amount);
    }

    function _enforceUniqueRewardTokens(
        PerformanceBond.TimeLockRewardPool[] calldata rewardPools
    ) private {
        for (uint256 i = 0; i < rewardPools.length; i++) {
            // Ensure no prev entries contain the same tokens address
            if (_tokensCounter[rewardPools[i].tokens]) {
                revert("Rewards: tokens must be unique");
            }
            _tokensCounter[rewardPools[i].tokens] = true;
        }
        for (uint256 i = 0; i < rewardPools.length; i++) {
            delete _tokensCounter[rewardPools[i].tokens];
        }
    }

    function _hasRewardDebt(
        address claimant,
        PerformanceBond.TimeLockRewardPool storage rewardPool
    ) private view returns (bool) {
        return _claimantToRewardPoolDebt[claimant][rewardPool.tokens] > 0;
    }

    function _rewardDebt(
        address claimant,
        PerformanceBond.TimeLockRewardPool storage rewardPool
    ) private view returns (uint256) {
        return _claimantToRewardPoolDebt[claimant][rewardPool.tokens];
    }

    // Intentional use of timestamp for time lock expiry check
    //slither-disable-next-line timestamp
    function _hasTimeLockExpired(
        PerformanceBond.TimeLockRewardPool storage rewardPool
    ) private view returns (bool) {
        return block.timestamp >= rewardPool.timeLock + _redemptionTimestamp;
    }

    // Intentional use of timestamp for input validation
    //slither-disable-next-line timestamp
    function _isPresentOrFutureTime(uint128 timestamp)
        private
        view
        returns (bool)
    {
        return timestamp >= block.timestamp;
    }

    function _isRedemptionTimeSet() private view returns (bool) {
        return _redemptionTimestamp > 0;
    }

    function _rewardPoolByToken(address tokens)
        private
        view
        returns (PerformanceBond.TimeLockRewardPool storage)
    {
        for (uint256 i = 0; i < _rewardPools.length; i++) {
            PerformanceBond.TimeLockRewardPool
                storage rewardPool = _rewardPools[i];

            if (rewardPool.tokens == tokens) {
                return rewardPool;
            }
        }

        revert("Rewards: tokens not found");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title Provides an expiry timestamp, with evaluation modifier.
 *
 * @dev Time evaluation uses the block current timestamp.
 */
abstract contract ExpiryTimestamp is Initializable {
    uint256 private _expiry;

    /**
     * @notice Reverts when the time has not met or passed the expiry timestamp.
     *
     * @dev Warning: use of block timestamp introduces risk of miner time manipulation.
     */
    modifier whenBeyondExpiry() {
        require(block.timestamp >= _expiry, "ExpiryTimestamp: not yet expired");
        _;
    }

    /**
     * @notice The timestamp compared with the block time to determine expiry.
     *
     * @dev Timestamp is the Unix time.
     */
    function expiryTimestamp() external view returns (uint256) {
        return _expiry;
    }

    /**
     * @notice Initialisation of the expiry timestamp to enable the 'hasExpired' modifier.
     *
     * @param timestamp expiry without any restriction e.g. it has not yet passed.
     */
    //slither-disable-next-line naming-convention
    function __ExpiryTimestamp_init(uint256 timestamp)
        internal
        onlyInitializing
    {
        _expiry = timestamp;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/**
 * @title A string storage bucket for metadata.
 *
 * @notice Useful for off-chain actors to store on data on-chain.
 *          Information related to the contract but not required for contract operations.
 *
 * @dev Metadata could include UI related pieces, perhaps in a delimited format to support multiple items.
 */
abstract contract MetaDataStore is ContextUpgradeable {
    string private _metaData;

    event MetaDataUpdate(string data, address indexed instigator);

    /**
     * @notice The storage box for metadata. Information not required by the contract for operations.
     *
     * @dev Information related to the contract but not needed by the contract.
     */
    function metaData() external view returns (string memory) {
        return _metaData;
    }

    //slither-disable-next-line naming-convention
    function __MetaDataStore_init(string calldata data)
        internal
        onlyInitializing
    {
        _setMetaData(data);
    }

    /**
     * @notice Replaces any existing stored metadata.
     *
     * @dev To expose the setter externally with modifier access control, create a new method invoking _setMetaData.
     */
    function _setMetaData(string calldata data) internal {
        _metaData = data;
        emit MetaDataUpdate(data, _msgSender());
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/**
 * @title Encapsulates the state of being redeemable.
 *
 * @notice The state of being redeemable is boolean and single direction transition from false to true.
 */
abstract contract Redeemable is ContextUpgradeable {
    bool private _redeemable;

    string private _reason;

    event RedeemableUpdate(
        bool isRedeemable,
        string reason,
        address indexed instigator
    );

    /**
     * @notice Makes a function callable only when the contract is not redeemable.
     *
     * @dev Reverts when the contract is redeemable.
     *
     * Requirements:
     * - The contract must not be redeemable.
     */
    modifier whenNotRedeemable() {
        require(!_redeemable, "whenNotRedeemable: redeemable");
        _;
    }

    /**
     * @notice Makes a function callable only when the contract is redeemable.
     *
     * @dev Reverts when the contract is not yet redeemable.
     *
     * Requirements:
     * - The contract must be redeemable.
     */
    modifier whenRedeemable() {
        require(_redeemable, "whenRedeemable: not redeemable");
        _;
    }

    function redemptionReason() external view returns (string memory) {
        return _reason;
    }

    function redeemable() public view returns (bool) {
        return _redeemable;
    }

    //slither-disable-next-line naming-convention
    function __Redeemable_init() internal onlyInitializing {}

    /**
     * @dev Transitions redeemable from `false` to `true`.
     *
     * No affect if state is already transitioned.
     */
    function _setAsRedeemable(string calldata reason) internal {
        _redeemable = true;
        _reason = reason;
        emit RedeemableUpdate(true, reason, _msgSender());
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./PerformanceBondCreator.sol";
import "./PerformanceBondCurator.sol";
import "./PerformanceBondPortal.sol";
import "./PerformanceBond.sol";
import "../dao-configuration/DaoConfiguration.sol";
import "../Version.sol";
import "../sweep/SweepERC20.sol";

/**
 * @title Mediates between a creator and a curator.
 *
 * @dev Orchestrates a PerformanceBondCreator and PerformanceBondCurator to provide a single function to aggregate
 *      the various calls providing a single function to create and setup a bond for management with the curator.
 */
contract PerformanceBondMediator is
    PerformanceBondCurator,
    PerformanceBondPortal,
    DaoConfiguration,
    SweepERC20,
    UUPSUpgradeable,
    Version
{
    PerformanceBondCreator private _creator;

    event PerformanceBondCreatorUpdate(
        address indexed previousCreator,
        address indexed updateCreator,
        address indexed instigator
    );

    /**
     * @notice The _msgSender() is given membership of all roles, to allow granting and future renouncing after others
     *      have been setup.
     *
     * @param factory A deployed PerformanceBondCreator contract to use when creating PerformanceBonds.
     * @param treasury Beneficiary of any token sweeping.
     */
    function initialize(address factory, address treasury)
        external
        initializer
    {
        require(
            AddressUpgradeable.isContract(factory),
            "BM: creator not a contract"
        );

        __BondCurator_init();
        __DaoConfiguration_init();
        __UUPSUpgradeable_init();
        __TokenSweep_init(treasury);

        _creator = PerformanceBondCreator(factory);
    }

    function createDao(address erc20CapableTreasury)
        external
        override
        atLeastDaoCreatorRole
        returns (uint256)
    {
        uint256 id = _daoConfiguration(erc20CapableTreasury);
        _grantDaoCreatorAdminRoleInTheirDao(id);

        emit CreateDao(id, erc20CapableTreasury, _msgSender());

        return id;
    }

    function createManagedPerformanceBond(
        uint256 daoId,
        PerformanceBond.MetaData calldata metadata,
        PerformanceBond.Settings calldata configuration,
        PerformanceBond.TimeLockRewardPool[] calldata rewards
    )
        external
        override
        whenNotPaused
        atLeastDaoMeepleRole(daoId)
        returns (address)
    {
        require(_isValidDaoId(daoId), "BM: invalid DAO Id");
        require(
            isAllowedDaoCollateral(daoId, configuration.collateralTokens),
            "BM: collateral not whitelisted"
        );

        address bond = _creator.createPerformanceBond(
            metadata,
            configuration,
            rewards,
            _daoTreasury(daoId)
        );

        // Reentrancy warning from an emitted event, which needs the Bond, created by an external call above.
        //slither-disable-next-line reentrancy-events
        _addBond(daoId, bond);

        return bond;
    }

    /**
     * @notice Updates the PerformanceBond creator reference.
     *
     * @param factory Contract address for the new PerformanceBondCreator to use from now onwards when creating bonds.
     */
    function setPerformanceBondCreator(address factory)
        external
        whenNotPaused
        atLeastSysAdminRole
    {
        require(
            AddressUpgradeable.isContract(factory),
            "BM: creator not a contract"
        );
        address previousCreator = address(_creator);
        require(factory != previousCreator, "BM: matches existing");

        emit PerformanceBondCreatorUpdate(
            address(_creator),
            factory,
            _msgSender()
        );
        _creator = PerformanceBondCreator(factory);
    }

    /**
     * @notice Permits updating the default DAO treasury address.
     *
     * @dev Only applies for bonds created after the update, previously created bond treasury addresses remain unchanged.
     */
    function setDaoTreasury(uint256 daoId, address replacement)
        external
        whenNotPaused
        atLeastDaoAdminRole(daoId)
    {
        _setDaoTreasury(daoId, replacement);
    }

    /**
     * @notice Permits updating the meta data for the DAO.
     */
    function setDaoMetaData(uint256 daoId, string calldata replacement)
        external
        whenNotPaused
        atLeastDaoAdminRole(daoId)
    {
        _setDaoMetaData(daoId, replacement);
    }

    function updateTokenSweepBeneficiary(address newBeneficiary)
        external
        whenNotPaused
        onlySuperUserRole
    {
        _setTokenSweepBeneficiary(newBeneficiary);
    }

    /**
     * @notice Permits the owner to remove a collateral token from being accepted in future bonds.
     *
     * @dev Only applies for bonds created after the removal, previously created bonds remain unchanged.
     *
     * @param erc20CollateralTokens token to remove from whitelist
     * @param daoId The DAO who is having the collateral token removed from their whitelist.
     */
    function removeWhitelistedCollateral(
        uint256 daoId,
        address erc20CollateralTokens
    ) external whenNotPaused atLeastDaoAdminRole(daoId) {
        _removeWhitelistedDaoCollateral(daoId, erc20CollateralTokens);
    }

    function sweepERC20Tokens(address tokens, uint256 amount)
        external
        whenNotPaused
        onlySuperUserRole
    {
        _sweepERC20Tokens(tokens, amount);
    }

    /**
     * @notice Adds an ERC20 token to the collateral whitelist.
     *
     * @dev When a bond is created, the tokens used as collateral must have been whitelisted.
     *
     * @param daoId The DAO who is having the collateral token whitelisted.
     * @param erc20CollateralTokens Whitelists the token from now onwards.
     *      On bond creation the tokens address used is retrieved by symbol from the whitelist.
     */
    function whitelistCollateral(uint256 daoId, address erc20CollateralTokens)
        external
        whenNotPaused
        atLeastDaoAdminRole(daoId)
    {
        _whitelistDaoCollateral(daoId, erc20CollateralTokens);
    }

    function bondCreator() external view returns (address) {
        return address(_creator);
    }

    /**
     * @notice Permits only the relevant admins to perform proxy upgrades.
     *
     * @dev Only applicable when deployed as implementation to a UUPS proxy.
     */
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        atLeastSysAdminRole
    {}

    function _grantDaoCreatorAdminRoleInTheirDao(uint256 daoId) private {
        if (_hasGlobalRole(Roles.DAO_CREATOR, _msgSender())) {
            _grantDaoRole(daoId, Roles.DAO_ADMIN, _msgSender());
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../performance-bonds/TimeLockMultiRewardPerformanceBond.sol";

contract TimeLockMultiRewardBondBox is TimeLockMultiRewardPerformanceBond {
    uint256 private constant _TOTAL_SUPPLY = 10000;

    function claimantDebt(uint256 amount) external {
        address claimant = _msgSender();
        _calculateRewardDebt(claimant, amount, totalSupply());
    }

    function initialize(PerformanceBond.TimeLockRewardPool[] calldata rewards)
        external
        initializer
    {
        __TimeLockMultiRewardBond_init(rewards);
    }

    function setRedemptionTimestamp() external {
        _setRedemptionTimestamp(uint128(block.timestamp));
    }

    function totalSupply() public pure returns (uint256) {
        return _TOTAL_SUPPLY;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../performance-bonds/PerformanceBondCurator.sol";

/**
 * @title Box to test the PerformanceBond curator abstract contract.
 *
 * @notice An empty box for testing the provided functions required in management of PerformanceBond.
 */
contract BondCuratorBox is PerformanceBondCurator {
    function initialize() external initializer {
        __BondCurator_init();
    }

    function addBond(uint256 daoId, address bond) external {
        _addBond(daoId, bond);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../performance-bonds/ERC20SingleCollateralPerformanceBond.sol";

contract ERC20SingleCollateralBondBox is ERC20SingleCollateralPerformanceBond {
    function allowRedemption(string calldata reason) external override {
        _allowRedemption(reason);
    }

    function deposit(uint256 amount) external override {
        _deposit(amount);
    }

    function initialize(
        PerformanceBond.MetaData calldata metadata,
        PerformanceBond.Settings calldata configuration,
        address treasury
    ) external initializer {
        __ERC20SingleCollateralBond_init(metadata, configuration, treasury);
    }

    function updateRewardTimeLock(address tokens, uint128 timeLock)
        external
        override
    {}
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../RoleAccessControl.sol";

/**
 * @title Box to test the access control dedicated for the Bond family of contracts.
 *
 * @notice An empty box for testing the provided modifiers and management for access control required throughout the Bond contracts.
 */
contract BondAccessControlBox is RoleAccessControl {
    /**
     * As BondAccessControl is intended to be used in Upgradable contracts, it uses an init.
     */
    constructor() initializer {
        __RoleAccessControl_init();
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./TokenSweep.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

/**
 * @title Adds the ability to sweep ERC721 tokens to a beneficiary address
 */
abstract contract SweepERC721 is TokenSweep {
    /**
     * @notice Sweep the erc721 tokens to the beneficiary address
     **/
    function _sweepERC721Tokens(address token, uint256 tokenId) internal {
        require(token != address(this), "SweepERC721: self transfer");
        require(token != address(0), "SweepERC721: address zero");

        IERC721Upgradeable(token).safeTransferFrom(
            address(this),
            tokenSweepBeneficiary(),
            tokenId
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../sweep/SweepERC721.sol";
import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";

contract SweepERC721TokensHarness is SweepERC721 {
    function setBeneficiary(address beneficiary) external {
        _setTokenSweepBeneficiary(beneficiary);
    }

    function sweepERC721Tokens(address token, uint256 tokenId) external {
        _sweepERC721Tokens(token, tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../extensions/ERC721Enumerable.sol";
import "../extensions/ERC721Burnable.sol";
import "../extensions/ERC721Pausable.sol";
import "../../../access/AccessControlEnumerable.sol";
import "../../../utils/Context.sol";
import "../../../utils/Counters.sol";

/**
 * @dev {ERC721} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *  - token ID and URI autogeneration
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 *
 * _Deprecated in favor of https://wizard.openzeppelin.com/[Contracts Wizard]._
 */
contract ERC721PresetMinterPauserAutoId is
    Context,
    AccessControlEnumerable,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable
{
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    Counters.Counter private _tokenIdTracker;

    string private _baseTokenURI;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * Token URIs will be autogenerated based on `baseURI` and their token IDs.
     * See {ERC721-tokenURI}.
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have minter role to mint");

        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        _mint(to, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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
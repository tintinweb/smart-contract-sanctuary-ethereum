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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./PPAgentV2Flags.sol";
import "./PPAgentV2Interfaces.sol";

library ConfigFlags {
  function check(uint256 cfg, uint256 flag) internal pure returns (bool) {
    return (cfg & flag) != 0;
  }
}

/**
 * @title PowerAgentLite
 * @author PowerPool
 */
contract PPAgentV2 is IPPAgentV2Executor, IPPAgentV2Viewer, IPPAgentV2JobOwner, PPAgentV2Flags, Initializable, Ownable {
  error OnlyOwner();
  error NonEOASender();
  error InsufficientKeeperStake();
  error InsufficientJobScopedKeeperStake();
  error KeeperWorkerNotAuthorized();
  error InsufficientJobCredits(uint256 actual, uint256 wanted);
  error InsufficientJobOwnerCredits(uint256 actual, uint256 wanted);
  error InactiveJob(bytes32 jobKey);
  error JobIdOverflow();
  error OnlyJobOwner();
  error JobWithoutOwner();
  error MissingJobAddress();
  error MissingMaxBaseFeeGwei();
  error NoFixedNorPremiumPctReward();
  error CreditsDepositOverflow();
  error StakeAmountOverflow();
  error CreditsWithdrawalUnderflow();
  error MissingDeposit();
  error IntervalNotReached(uint256 lastExecutedAt, uint256 interval, uint256 _now);
  error BaseFeeGtGasPrice(uint256 baseFee, uint256 jobMaxBaseFeeGwei);
  error InvalidCalldataSource();
  error MissingInputCalldata();
  error SelectorCheckFailed();
  error JobCallRevertedWithoutDetails();
  error InsufficientAmountToCoverSlashedStake(uint256 wanted, uint256 actual);
  error AmountGtStake(uint256 wanted, uint256 actualStake, uint256 actualSlashedStake);
  error WithdrawalTimoutNotReached();
  error NoPendingWithdrawal();
  error MissingAmount();
  error WithdrawAmountExceedsAvailable(uint256 wanted, uint256 actual);
  error JobShouldHaveInterval();
  error ResolverJobCantHaveInterval();
  error InvalidJobAddress();
  error InvalidKeeperId();
  error MissingResolverAddress();
  error NotSupportedByJobCalldataSource();
  error OnlyKeeperAdmin();
  error OnlyKeeperAdminOrJobOwner();
  error OnlyKeeperAdminOrWorker();
  error TimeoutTooBig();
  error FeeTooBig();
  error InsufficientAmount();
  error OnlyPendingOwner();
  error WorkerAlreadyAssigned();

  string public constant VERSION = "2.3.0";
  uint256 internal constant MAX_PENDING_WITHDRAWAL_TIMEOUT_SECONDS = 30 days;
  uint256 internal constant MAX_FEE_PPM = 5e4;
  uint256 internal constant FIXED_PAYMENT_MULTIPLIER = 1e15;

  enum CalldataSourceType {
    SELECTOR,
    PRE_DEFINED,
    RESOLVER
  }

  IERC20 public immutable CVP;

  event Execute(
    bytes32 indexed jobKey,
    address indexed job,
    uint256 indexed keeperId,
    uint256 gasUsed,
    uint256 baseFee,
    uint256 gasPrice,
    uint256 compensation,
    bytes32 binJobAfter
  );
  event WithdrawFees(address indexed to, uint256 amount);
  event Slash(uint256 indexed keeperId, address indexed to, uint256 currentAmount, uint256 pendingAmount);
  event RegisterAsKeeper(uint256 indexed keeperId, address indexed keeperAdmin, address indexed keeperWorker);
  event SetWorkerAddress(uint256 indexed keeperId, address indexed prev, address indexed worker);
  event Stake(uint256 indexed keeperId, uint256 amount, address staker);
  event InitiateRedeem(uint256 indexed keeperId, uint256 redeemAmount, uint256 stakeAmount, uint256 slashedStakeAmount);
  event FinalizeRedeem(uint256 indexed keeperId, address indexed beneficiary, uint256 amount);
  event WithdrawCompensation(uint256 indexed keeperId, address indexed to, uint256 amount);
  event DepositJobCredits(bytes32 indexed jobKey, address indexed depositor, uint256 amount, uint256 fee);
  event WithdrawJobCredits(bytes32 indexed jobKey, address indexed owner, address indexed to, uint256 amount);
  event DepositJobOwnerCredits(address indexed jobOwner, address indexed depositor, uint256 amount, uint256 fee);
  event WithdrawJobOwnerCredits(address indexed jobOwner, address indexed to, uint256 amount);
  event InitiateJobTransfer(bytes32 indexed jobKey, address indexed from, address indexed to);
  event AcceptJobTransfer(bytes32 indexed jobKey_, address indexed to_);
  event SetJobConfig(bytes32 indexed jobKey, bool isActive_, bool useJobOwnerCredits_, bool assertResolverSelector_);
  event SetJobResolver(bytes32 indexed jobKey, address resolverAddress, bytes resolverCalldata);
  event SetJobPreDefinedCalldata(bytes32 indexed jobKey, bytes preDefinedCalldata);
  event SetAgentParams(uint256 minKeeperCvp_, uint256 timeoutSeconds_, uint256 feePpm_);
  event RegisterJob(
    bytes32 indexed jobKey,
    address indexed jobAddress,
    uint256 indexed jobId,
    address owner,
    RegisterJobParams params
  );
  event JobUpdate(
    bytes32 indexed jobKey,
    uint256 maxBaseFeeGwei,
    uint256 rewardPct,
    uint256 fixedReward,
    uint256 jobMinCvp,
    uint256 intervalSeconds
  );

  struct Keeper {
    address worker;
    uint88 cvpStake;
    bool isActive;
  }

  struct ExecutionResponsesData {
    bytes resolverResponse;
    bytes executionResponse;
  }

  uint256 internal minKeeperCvp;
  uint256 internal pendingWithdrawalTimeoutSeconds;
  uint256 internal feeTotal;
  uint256 internal feePpm;
  uint256 internal lastKeeperId;

  // keccak256(jobAddress, id) => ethBalance
  mapping(bytes32 => Job) internal jobs;
  // keccak256(jobAddress, id) => customCalldata
  mapping(bytes32 => bytes) internal preDefinedCalldatas;
  // keccak256(jobAddress, id) => minKeeperCvpStake
  mapping(bytes32 => uint256) internal jobMinKeeperCvp;
  // keccak256(jobAddress, id) => owner
  mapping(bytes32 => address) internal jobOwners;
  // keccak256(jobAddress, id) => resolver(address,calldata)
  mapping(bytes32 => Resolver) internal resolvers;
  // keccak256(jobAddress, id) => pendingAddress
  mapping(bytes32 => address) internal jobPendingTransfers;

  // jobAddress => lastIdRegistered(actually uint24)
  mapping(address => uint256) public jobLastIds;

  // keeperId => (worker,CVP stake)
  mapping(uint256 => Keeper) internal keepers;
  // keeperId => admin
  mapping(uint256 => address) internal keeperAdmins;
  // keeperId => the slashed CVP amount
  mapping(uint256 => uint256) internal slashedStakeOf;
  // keeperId => native token compensation
  mapping(uint256 => uint256) internal compensations;

  // keeperId => pendingWithdrawalCVP amount
  mapping(uint256 => uint256) internal pendingWithdrawalAmounts;
  // keeperId => pendingWithdrawalEndsAt timestamp
  mapping(uint256 => uint256) internal pendingWithdrawalEndsAt;

  // owner => credits
  mapping(address => uint256) public jobOwnerCredits;

  // worker => keeperIs
  mapping(address => uint256) public workerKeeperIds;

  /*** PSEUDO-MODIFIERS ***/

  function _assertOnlyOwner() internal view {
    if (msg.sender != owner()) {
      revert OnlyOwner();
    }
  }

  function _assertOnlyJobOwner(bytes32 jobKey_) internal view {
    if (msg.sender != jobOwners[jobKey_]) {
      revert OnlyJobOwner();
    }
  }

  function _assertOnlyKeeperAdmin(uint256 keeperId_) internal view {
    if (msg.sender != keeperAdmins[keeperId_]) {
      revert OnlyKeeperAdmin();
    }
  }

  function _assertOnlyKeeperAdminOrWorker(uint256 keeperId_) internal view {
    if (msg.sender != keeperAdmins[keeperId_] && msg.sender != keepers[keeperId_].worker) {
      revert OnlyKeeperAdminOrWorker();
    }
  }

  function _assertKeeperIdExists(uint256 keeperId_) internal view {
    if (keeperId_ > lastKeeperId) {
      revert InvalidKeeperId();
    }
  }

  function _assertWorkerNotAssigned(address worker_) internal view {
    if (workerKeeperIds[worker_] != 0) {
      revert WorkerAlreadyAssigned();
    }
  }

  function _assertNonZeroAmount(uint256 amount_) internal pure {
    if (amount_ == 0) {
      revert MissingAmount();
    }
  }

  function _assertNonZeroValue() internal view {
    if (msg.value == 0) {
      revert MissingDeposit();
    }
  }

  function _assertJobCalldataSource(bytes32 jobKey_, CalldataSourceType source_) internal view {
    if (CalldataSourceType(jobs[jobKey_].calldataSource) != source_) {
      revert NotSupportedByJobCalldataSource();
    }
  }

  function _assertJobParams(uint256 maxBaseFeeGwei_, uint256 fixedReward_, uint256 rewardPct_) internal pure {
    if (maxBaseFeeGwei_ == 0) {
      revert MissingMaxBaseFeeGwei();
    }

    if (fixedReward_ == 0 && rewardPct_ == 0) {
      revert NoFixedNorPremiumPctReward();
    }
  }

  function _assertInterval(uint256 interval_, CalldataSourceType calldataSource_) internal pure {
    if (interval_ == 0 &&
      (calldataSource_ == CalldataSourceType.SELECTOR || calldataSource_ == CalldataSourceType.PRE_DEFINED)) {
      revert JobShouldHaveInterval();
    }
    if (interval_ != 0 && calldataSource_ == CalldataSourceType.RESOLVER) {
      revert ResolverJobCantHaveInterval();
    }
  }

  constructor(address cvp_) {
    CVP = IERC20(cvp_);
  }

  function initialize(
    address owner_,
    uint256 minKeeperCvp_,
    uint256 pendingWithdrawalTimeoutSeconds_
  ) public initializer {
    _setAgentParams(minKeeperCvp_, pendingWithdrawalTimeoutSeconds_, 0);
    _transferOwnership(owner_);
  }

  /*** HOOKS ***/
  function _beforeExecute(bytes32 jobKey_, uint256 actualKeeperId_, uint256 binJob_) internal view virtual {}
  function _beforeInitiateRedeem(uint256 keeperId_) internal view virtual {}

  function _afterExecutionSucceeded(bytes32 jobKey_, uint256 actualKeeperId_, uint256 binJob_) internal virtual {}
  function _afterRegisterJob(bytes32 jobKey_) internal virtual {}
  function _afterDepositJobCredits(bytes32 jobKey_) internal virtual {}
  function _afterWithdrawJobCredits(bytes32 jobKey_) internal virtual {}

  /*** CONSTANT GETTERS ***/
  function getStrategy() public pure virtual returns (string memory) {
    return "basic";
  }

  function _getJobGasOverhead() internal pure virtual returns (uint256) {
    return 40_000;
  }

  /*** UPKEEP INTERFACE ***/

  /**
   * Executes a job.
   * The method arguments a tightly coupled with a custom layout in order to save some gas.
   * The calldata has the following layout :
   *  0x      00000000 1b48315d66ba5267aac8d0ab63c49038b56b1dbc 0000f1 03     00001a    402b2eed11
   *  name    selector jobContractAddress                       jobId  config keeperId  calldata (optional)
   *  size b  bytes4   bytes20                                  uint24 uint8  uint24    any
   *  size u  uint32   uint160                                  bytes3 bytes1 bytes3    any
   *  bits    0-3      4-23                                     24-26  27-27  28-30     31+
   */
  function execute_44g58pv() external {
    uint256 gasStart = gasleft();
    bytes32 jobKey;

    assembly ("memory-safe") {
      // size of (address(bytes20)+id(uint24/bytes3))
      let size := 23

      // keccack256(address+id(uint24)) to memory to generate jobKey
      calldatacopy(0, 4, size)
      jobKey := keccak256(0, size)
    }

    address jobAddress;
    uint256 actualKeeperId;
    uint256 cfg;

    assembly ("memory-safe") {
      // load jobAddress, cfg, and keeperId from calldata to the stack
      jobAddress := shr(96, calldataload(4))
      cfg := shr(248, calldataload(27))
      actualKeeperId := shr(232, calldataload(28))
    }

    uint256 binJob = getJobRaw(jobKey);

    _beforeExecute(jobKey, actualKeeperId, binJob);

    // 0. Keeper has sufficient stake
    {
      Keeper memory keeper = keepers[actualKeeperId];
      if (keeper.worker != msg.sender) {
        revert KeeperWorkerNotAuthorized();
      }
      if (keeper.cvpStake < minKeeperCvp) {
        revert InsufficientKeeperStake();
      }
    }

    // 1. Assert the job is active
    {
      if (!ConfigFlags.check(binJob, CFG_ACTIVE)) {
        revert InactiveJob(jobKey);
      }
    }

    // 2. Assert job-scoped keeper's minimum CVP deposit
    if (ConfigFlags.check(binJob, CFG_CHECK_KEEPER_MIN_CVP_DEPOSIT) && keepers[actualKeeperId].cvpStake < jobMinKeeperCvp[jobKey]) {
      revert InsufficientJobScopedKeeperStake();
    }

    // 3. For interval job ensure the interval has passed
    {
      uint256 intervalSeconds = (binJob << 32) >> 232;

      if (intervalSeconds > 0) {
        uint256 lastExecutionAt = binJob >> 224;
        if (lastExecutionAt > 0) {
          uint256 nextExecutionAt;
          unchecked {
            nextExecutionAt = lastExecutionAt + intervalSeconds;
          }
          if (nextExecutionAt > block.timestamp) {
            revert IntervalNotReached(lastExecutionAt, intervalSeconds, block.timestamp);
          }
        }
      }
    }

    // 4. Ensure gas price fits base fee
    uint256 maxBaseFee = _checkBaseFee(binJob, cfg);

    // 5. Ensure msg.sender is EOA
    if (msg.sender != tx.origin) {
      revert NonEOASender();
    }

    bool ok;
    uint256 jobGas = gasleft() - 50_000;

    // Source: Selector
    CalldataSourceType calldataSource = CalldataSourceType((binJob << 56) >> 248);
    if (calldataSource == CalldataSourceType.SELECTOR) {
      bytes4 selector;
      assembly ("memory-safe") {
        selector := shl(224, shr(8, binJob))
      }
      (ok,) = jobAddress.call{ gas: jobGas }(abi.encode(selector));
    // Source: Bytes
    } else if (calldataSource == CalldataSourceType.PRE_DEFINED) {
      (ok,) = jobAddress.call{ gas: jobGas }(preDefinedCalldatas[jobKey]);
    // Source: Resolver
    } else if (calldataSource == CalldataSourceType.RESOLVER) {
      assembly ("memory-safe") {
        let cdInCdSize := calldatasize()
        // calldata offset is 31
        let beforeCdSize := 31
        let ptr := mload(0x40)
        if lt(cdInCdSize, beforeCdSize) {
          // revert MissingInputCalldata()
          mstore(ptr, 0x47a0bafb00000000000000000000000000000000000000000000000000000000)
          revert(ptr, 4)
        }
        let cdSize := sub(cdInCdSize, beforeCdSize)
        mstore(0x40, add(ptr, cdSize))
        calldatacopy(ptr, beforeCdSize, cdSize)
        // CFG_ASSERT_RESOLVER_SELECTOR = 0x04 from PPAgentLiteFlags
        if and(binJob, 0x04) {
          if iszero(eq(
            // actual
            shl(224, shr(224, calldataload(31))),
            // expected
            shl(224, shr(8, binJob))
          )) {
            // revert SelectorCheckFailed()
            mstore(ptr, 0x84fb827500000000000000000000000000000000000000000000000000000000)
            revert(ptr, 4)
          }
        }
        // The remaining gas could not be less than 50_000
        ok := call(jobGas, jobAddress, 0, ptr, cdSize, 0x0, 0x0)
      }
    } else {
      // Should never be reached
      revert InvalidCalldataSource();
    }

    // Load returned response only if the job call had failed
    bytes memory executionResponse;
    if (!ok) {
      assembly ("memory-safe") {
        let size := returndatasize()
        if gt(size, 0) {
          executionResponse := mload(0x40)
          mstore(executionResponse, size)
          let p := add(executionResponse, 0x20)
          returndatacopy(p, 0, size)
          mstore(0x40, add(executionResponse, add(32, size)))
        }
      }
    }

    // Payout block
    uint256 compensation;
    uint256 gasUsed;
    {
      binJob = getJobRaw(jobKey);
      unchecked {
        gasUsed = gasStart - gasleft();
      }

      {
        uint256 min = block.basefee;
        if (maxBaseFee < min) {
          min = maxBaseFee;
        }

        compensation = _calculateCompensation(ok, binJob, actualKeeperId, min, gasUsed);
      }
      {
        bool jobChanged;

        if (ConfigFlags.check(binJob, CFG_USE_JOB_OWNER_CREDITS)) {
          // use job owner credits
          _useJobOwnerCredits(ok, jobKey, compensation);
        } else {
          // use job credits
          uint256 creditsBefore = (binJob << 128) >> 168;
          if (creditsBefore < compensation) {
            if (ok) {
              revert InsufficientJobCredits(creditsBefore, compensation);
            } else {
              compensation = creditsBefore;
            }
          }

          uint256 creditsAfter;
          unchecked {
            creditsAfter = creditsBefore - compensation;
          }
          // update job credits
          binJob = binJob & BM_CLEAR_CREDITS | (creditsAfter << 40);
          jobChanged = true;
        }

        if (ConfigFlags.check(cfg, FLAG_ACCRUE_REWARD)) {
          compensations[actualKeeperId] += compensation;
        } else {
          payable(msg.sender).transfer(compensation);
        }

        // Update lastExecutionAt for interval jobs
        {
          uint256 intervalSeconds = (binJob << 32) >> 232;
          if (intervalSeconds > 0) {
            uint256 lastExecutionAt = uint32(block.timestamp);
            binJob = binJob & BM_CLEAR_LAST_UPDATE_AT | (lastExecutionAt << 224);
            jobChanged = true;
          }
        }

        if (jobChanged) {
          _updateRawJob(jobKey, binJob);
        }
      }
    }

    if (ok) {
      // Transaction succeeded
      emit Execute(
        jobKey,
        jobAddress,
        actualKeeperId,
        gasUsed,
        block.basefee,
        tx.gasprice,
        compensation,
        bytes32(binJob)
      );

      _afterExecutionSucceeded(jobKey, actualKeeperId, binJob);
    } else {
      // Tx reverted
      _afterExecutionReverted(jobKey, calldataSource, actualKeeperId, executionResponse);
    }
  }

  function _checkBaseFee(uint256 binJob_, uint256 cfg_) internal view virtual returns (uint256) {
    uint256 maxBaseFee;
    unchecked {
      maxBaseFee = ((binJob_ << 112) >> 240)  * 1 gwei;
    }
    if (block.basefee > maxBaseFee && !ConfigFlags.check(cfg_, FLAG_ACCEPT_MAX_BASE_FEE_LIMIT)) {
      revert BaseFeeGtGasPrice(block.basefee, maxBaseFee);
    }
    return maxBaseFee;
  }

  function _afterExecutionReverted(
    bytes32 jobKey_,
    CalldataSourceType calldataSource_,
    uint256 keeperId_,
    bytes memory executionResponse_
  ) internal virtual {
    jobKey_;
    keeperId_;
    calldataSource_;

    if (executionResponse_.length == 0) {
      revert JobCallRevertedWithoutDetails();
    } else {
      assembly ("memory-safe") {
        revert(add(32, executionResponse_), mload(executionResponse_))
      }
    }
  }

  function _calculateCompensation(
    bool ok_,
    uint256 job_,
    uint256 keeperId_,
    uint256 gasPrice_,
    uint256 gasUsed_
  ) internal view virtual returns (uint256) {
    ok_; // silence unused param warning
    keeperId_; // silence unused param warning
    uint256 fixedReward = (job_ << 64) >> 224;
    uint256 rewardPct = (job_ << 96) >> 240;
    return calculateCompensationPure(rewardPct, fixedReward, gasPrice_, gasUsed_);
  }

  function _useJobOwnerCredits(bool ok_, bytes32 jobKey_, uint256 compensation_) internal {
    uint256 jobOwnerCreditsBefore = jobOwnerCredits[jobOwners[jobKey_]];
    if (jobOwnerCreditsBefore < compensation_) {
      if (ok_) {
        revert InsufficientJobOwnerCredits(jobOwnerCreditsBefore, compensation_);
      } else {
        compensation_ = jobOwnerCreditsBefore;
      }
    }

    unchecked {
      jobOwnerCredits[jobOwners[jobKey_]] = jobOwnerCreditsBefore - compensation_;
    }
  }

  /*** JOB OWNER INTERFACE ***/

  /**
   * Registers a new job.
   *
   * Job id is unique counter for a given job address. Up to 2**24-1 jobs per address.
   * Job key is a keccak256(address, jobId).
   * The following options are immutable:
   *  - `params_.jobaddress`
   *  - `params_.calldataSource`
   * If you need to modify one of the immutable options above later consider creating a new job.
   *
   * @param params_ Job-specific params
   * @param resolver_ Resolver details(address, calldata), required only for CALLDATA_SOURCE_RESOLVER
   *                  job type. Use empty values for the other job types.
   * @param preDefinedCalldata_ Calldata to call a job with, required only for CALLDATA_SOURCE_PRE_DEFINED
   *              job type. Keep empty for the other job types.
   */
  function registerJob(
    RegisterJobParams calldata params_,
    Resolver calldata resolver_,
    bytes calldata preDefinedCalldata_
  ) public payable virtual returns (bytes32 jobKey, uint256 jobId){
    jobId = jobLastIds[params_.jobAddress] + 1;

    if (jobId > type(uint24).max) {
      revert JobIdOverflow();
    }

    if (msg.value > type(uint88).max) {
      revert CreditsDepositOverflow();
    }

    if (params_.jobAddress == address(0)) {
      revert MissingJobAddress();
    }

    if (params_.calldataSource > 2) {
      revert InvalidCalldataSource();
    }

    if (params_.jobAddress == address(CVP) || params_.jobAddress == address(this)) {
      revert InvalidJobAddress();
    }

    _assertInterval(params_.intervalSeconds, CalldataSourceType(params_.calldataSource));
    _assertJobParams(params_.maxBaseFeeGwei, params_.fixedReward, params_.rewardPct);
    jobKey = getJobKey(params_.jobAddress, jobId);

    emit RegisterJob(
      jobKey,
      params_.jobAddress,
      jobId,
      msg.sender,
      params_
    );

    if (CalldataSourceType(params_.calldataSource) == CalldataSourceType.PRE_DEFINED) {
      _setJobPreDefinedCalldata(jobKey, preDefinedCalldata_);
    } else if (CalldataSourceType(params_.calldataSource) == CalldataSourceType.RESOLVER) {
      _setJobResolver(jobKey, resolver_);
    }

    {
      bytes4 selector = 0x00000000;
      if (CalldataSourceType(params_.calldataSource) != CalldataSourceType.PRE_DEFINED) {
        selector = params_.jobSelector;
      }

      uint256 config = CFG_ACTIVE;
      if (params_.useJobOwnerCredits) {
        config = config | CFG_USE_JOB_OWNER_CREDITS;
      }
      if (params_.assertResolverSelector) {
        config = config | CFG_ASSERT_RESOLVER_SELECTOR;
      }
      if (params_.jobMinCvp > 0) {
        config = config | CFG_CHECK_KEEPER_MIN_CVP_DEPOSIT;
      }

      jobs[jobKey] = Job({
        config: uint8(config),
        selector: selector,
        credits: 0,
        maxBaseFeeGwei: params_.maxBaseFeeGwei,
        fixedReward: params_.fixedReward,
        rewardPct: params_.rewardPct,
        calldataSource: params_.calldataSource,

        // For interval jobs
        intervalSeconds: params_.intervalSeconds,
        lastExecutionAt: 0
      });
      jobMinKeeperCvp[jobKey] = params_.jobMinCvp;
    }

    jobLastIds[params_.jobAddress] = jobId;
    jobOwners[jobKey] = msg.sender;

    if (msg.value > 0) {
      if (params_.useJobOwnerCredits) {
        _processJobOwnerCreditsDeposit(msg.sender);
      } else {
        _processJobCreditsDeposit(jobKey);
      }
    }

    _afterRegisterJob(jobKey);
  }

  /**
   * Updates a job details.
   *
   * The following options are immutable:
   *  - `jobAddress`
   *  - `job.selector`
   *  - `job.calldataSource`
   * If you need to modify one of the immutable options above later consider creating a new job.
   *
   * @param jobKey_ The job key
   * @param maxBaseFeeGwei_ The maximum basefee in gwei to use for a job compensation
   * @param rewardPct_ The reward premium in pct, where 1 == 1%
   * @param fixedReward_ The fixed reward divided by FIXED_PAYMENT_MULTIPLIER
   * @param jobMinCvp_ The keeper minimal CVP stake to be eligible to execute this job
   * @param intervalSeconds_ The interval for a job execution
   */
  function updateJob(
    bytes32 jobKey_,
    uint16 maxBaseFeeGwei_,
    uint16 rewardPct_,
    uint32 fixedReward_,
    uint256 jobMinCvp_,
    uint24 intervalSeconds_
  ) external {
    _assertOnlyJobOwner(jobKey_);
    _assertJobParams(maxBaseFeeGwei_, fixedReward_, rewardPct_);

    Job memory job = jobs[jobKey_];

    _assertInterval(intervalSeconds_, CalldataSourceType(job.calldataSource));

    uint256 cfg = job.config;

    if (jobMinCvp_ > 0 && !ConfigFlags.check(job.config, CFG_CHECK_KEEPER_MIN_CVP_DEPOSIT)) {
      cfg = cfg | CFG_CHECK_KEEPER_MIN_CVP_DEPOSIT;
    }
    if (jobMinCvp_ == 0 && ConfigFlags.check(job.config, CFG_CHECK_KEEPER_MIN_CVP_DEPOSIT)) {
      cfg = cfg ^ CFG_CHECK_KEEPER_MIN_CVP_DEPOSIT;
    }

    jobs[jobKey_].config = uint8(cfg);
    jobMinKeeperCvp[jobKey_] = jobMinCvp_;

    jobs[jobKey_].maxBaseFeeGwei = maxBaseFeeGwei_;
    jobs[jobKey_].rewardPct = rewardPct_;
    jobs[jobKey_].fixedReward = fixedReward_;
    jobs[jobKey_].intervalSeconds = intervalSeconds_;

    emit JobUpdate(jobKey_, maxBaseFeeGwei_, rewardPct_, fixedReward_, jobMinCvp_, intervalSeconds_);
  }

  /**
   * A job owner updates job resolver details.
   *
   * @param jobKey_ The jobKey
   * @param resolver_ The new job resolver details
   */
  function setJobResolver(bytes32 jobKey_, Resolver calldata resolver_) external {
    _assertOnlyJobOwner(jobKey_);
    _assertJobCalldataSource(jobKey_, CalldataSourceType.RESOLVER);

    _setJobResolver(jobKey_, resolver_);
  }

  function _setJobResolver(bytes32 jobKey_, Resolver calldata resolver_) internal {
    if (resolver_.resolverAddress == address(0)) {
      revert MissingResolverAddress();
    }
    resolvers[jobKey_] = resolver_;
    emit SetJobResolver(jobKey_, resolver_.resolverAddress, resolver_.resolverCalldata);
  }

  /**
   * A job owner updates pre-defined calldata.
   *
   * @param jobKey_ The jobKey
   * @param preDefinedCalldata_ The new job pre-defined calldata
   */
  function setJobPreDefinedCalldata(bytes32 jobKey_, bytes calldata preDefinedCalldata_) external {
    _assertOnlyJobOwner(jobKey_);
    _assertJobCalldataSource(jobKey_, CalldataSourceType.PRE_DEFINED);

    _setJobPreDefinedCalldata(jobKey_, preDefinedCalldata_);
  }

  function _setJobPreDefinedCalldata(bytes32 jobKey_, bytes calldata preDefinedCalldata_) internal {
    preDefinedCalldatas[jobKey_] = preDefinedCalldata_;
    emit SetJobPreDefinedCalldata(jobKey_, preDefinedCalldata_);
  }

  /**
   * A job owner updates a job config flag.
   *
   * @param jobKey_ The jobKey
   * @param isActive_ Whether the job is active or not
   * @param useJobOwnerCredits_ The useJobOwnerCredits flag
   * @param assertResolverSelector_ The assertResolverSelector flag
   */
  function setJobConfig(
    bytes32 jobKey_,
    bool isActive_,
    bool useJobOwnerCredits_,
    bool assertResolverSelector_
  ) public virtual {
    _assertOnlyJobOwner(jobKey_);
    uint256 newConfig = 0;

    if (isActive_) {
      newConfig = newConfig | CFG_ACTIVE;
    }
    if (useJobOwnerCredits_) {
      newConfig = newConfig | CFG_USE_JOB_OWNER_CREDITS;
    }
    if (assertResolverSelector_) {
      newConfig = newConfig | CFG_ASSERT_RESOLVER_SELECTOR;
    }

    uint256 job = getJobRaw(jobKey_) & BM_CLEAR_CONFIG | newConfig;
    _updateRawJob(jobKey_, job);

    emit SetJobConfig(jobKey_, isActive_, useJobOwnerCredits_, assertResolverSelector_);
  }

  function _updateRawJob(bytes32 jobKey_, uint256 job_) internal {
    Job storage job = jobs[jobKey_];
    assembly ("memory-safe") {
      sstore(job.slot, job_)
    }
  }

  /**
   * A job owner initiates the job transfer to a new owner.
   * The actual owner doesn't update until the pending owner accepts the transfer.
   *
   * @param jobKey_ The jobKey
   * @param to_ The new job owner
   */
  function initiateJobTransfer(bytes32 jobKey_, address to_) external {
    _assertOnlyJobOwner(jobKey_);
    jobPendingTransfers[jobKey_] = to_;
    emit InitiateJobTransfer(jobKey_, msg.sender, to_);
  }

  /**
   * A pending job owner accepts the job transfer.
   *
   * @param jobKey_ The jobKey
   */
  function acceptJobTransfer(bytes32 jobKey_) external {
    if (msg.sender != jobPendingTransfers[jobKey_]) {
      revert OnlyPendingOwner();
    }

    jobOwners[jobKey_] = msg.sender;
    delete jobPendingTransfers[jobKey_];

    emit AcceptJobTransfer(jobKey_, msg.sender);
  }

  /**
   * Top-ups the job credits in NATIVE tokens.
   *
   * @param jobKey_ The jobKey to deposit for
   */
  function depositJobCredits(bytes32 jobKey_) external virtual payable {
    _assertNonZeroValue();

    if (jobOwners[jobKey_] == address(0)) {
      revert JobWithoutOwner();
    }

    _processJobCreditsDeposit(jobKey_);

    _afterDepositJobCredits(jobKey_);
  }

  function _processJobCreditsDeposit(bytes32 jobKey_) internal {
    (uint256 fee, uint256 amount) = _calculateDepositFee();
    uint256 creditsAfter = jobs[jobKey_].credits + amount;
    if (creditsAfter > type(uint88).max) {
      revert CreditsDepositOverflow();
    }

    unchecked {
      feeTotal += fee;
    }
    jobs[jobKey_].credits = uint88(creditsAfter);

    emit DepositJobCredits(jobKey_, msg.sender, amount, fee);
  }

  function _calculateDepositFee() internal view returns (uint256 fee, uint256 amount) {
    fee = msg.value * feePpm / 1e6 /* 100% in ppm */;
    amount = msg.value - fee;
  }

  /**
   * A job owner withdraws the job credits in NATIVE tokens.
   *
   * @param jobKey_ The jobKey
   * @param to_ The address to send NATIVE tokens to
   * @param amount_ The amount to withdraw. Use type(uint256).max for the total available credits withdrawal.
   */
  function withdrawJobCredits(
    bytes32 jobKey_,
    address payable to_,
    uint256 amount_
  ) external {
    uint88 creditsBefore = jobs[jobKey_].credits;
    if (amount_ == type(uint256).max) {
      amount_ = creditsBefore;
    }

    _assertOnlyJobOwner(jobKey_);
    _assertNonZeroAmount(amount_);

    if (creditsBefore < amount_) {
      revert CreditsWithdrawalUnderflow();
    }

    unchecked {
      jobs[jobKey_].credits = creditsBefore - uint88(amount_);
    }

    to_.transfer(amount_);

    emit WithdrawJobCredits(jobKey_, msg.sender, to_, amount_);

    _afterWithdrawJobCredits(jobKey_);
  }

  /**
   * Top-ups the job owner credits in NATIVE tokens.
   *
   * @param for_ The job owner address to deposit for
   */
  function depositJobOwnerCredits(address for_) external payable {
    _assertNonZeroValue();

    _processJobOwnerCreditsDeposit(for_);
  }

  function _processJobOwnerCreditsDeposit(address for_) internal {
    (uint256 fee, uint256 amount) = _calculateDepositFee();

    unchecked {
      feeTotal += fee;
      jobOwnerCredits[for_] += amount;
    }

    emit DepositJobOwnerCredits(for_, msg.sender, amount, fee);
  }

  /**
   * A job owner withdraws the job owner credits in NATIVE tokens.
   *
   * @param to_ The address to send NATIVE tokens to
   * @param amount_ The amount to withdraw. Use type(uint256).max for the total available credits withdrawal.
   */
  function withdrawJobOwnerCredits(address payable to_, uint256 amount_) external {
    uint256 creditsBefore = jobOwnerCredits[msg.sender];
    if (amount_ == type(uint256).max) {
      amount_ = creditsBefore;
    }

    _assertNonZeroAmount(amount_);

    if (creditsBefore < amount_) {
      revert CreditsWithdrawalUnderflow();
    }

    unchecked {
      jobOwnerCredits[msg.sender] = creditsBefore - amount_;
    }

    to_.transfer(amount_);

    emit WithdrawJobOwnerCredits(msg.sender, to_, amount_);
  }

  /*** KEEPER INTERFACE ***/

  /**
   * Actor registers as a keeper.
   * One keeper address could have multiple keeper IDs. Requires at least `minKeepCvp` as an initial CVP deposit.
   *
   * @dev Overflow-safe only for CVP which total supply is less than type(uint96).max
   * @dev Maximum 2^24-1 keepers supported. There is no explicit check for overflow, but the keepers with ID >= 2^24
   *         won't be able to perform upkeep operations.
   *
   * @param worker_ The worker address
   * @param initialDepositAmount_ The initial CVP deposit. Should be no less than `minKeepCvp`
   * @return keeperId The registered keeper ID
   */
  function registerAsKeeper(address worker_, uint256 initialDepositAmount_) public virtual returns (uint256 keeperId) {
    _assertWorkerNotAssigned(worker_);

    if (initialDepositAmount_ < minKeeperCvp) {
      revert InsufficientAmount();
    }

    keeperId = ++lastKeeperId;
    keeperAdmins[keeperId] = msg.sender;
    keepers[keeperId] = Keeper(worker_, 0, true);
    workerKeeperIds[worker_] = keeperId;
    emit RegisterAsKeeper(keeperId, msg.sender, worker_);

    _stake(keeperId, initialDepositAmount_);
  }

  /**
   * A keeper updates a keeper worker address
   *
   * @param keeperId_ The keeper ID
   * @param worker_ The new worker address
   */
  function setWorkerAddress(uint256 keeperId_, address worker_) external {
    _assertOnlyKeeperAdmin(keeperId_);
    _assertWorkerNotAssigned(worker_);

    address prev = keepers[keeperId_].worker;
    delete workerKeeperIds[prev];
    workerKeeperIds[worker_] = keeperId_;
    keepers[keeperId_].worker = worker_;

    emit SetWorkerAddress(keeperId_, prev, worker_);
  }

  /**
   * A keeper withdraws NATIVE token rewards.
   *
   * @param keeperId_ The keeper ID
   * @param to_ The address to withdraw to
   * @param amount_ The amount to withdraw. Use type(uint256).max for the total available compensation withdrawal.
   */
  function withdrawCompensation(uint256 keeperId_, address payable to_, uint256 amount_) external {
    uint256 available = compensations[keeperId_];
    if (amount_ == type(uint256).max) {
      amount_ = available;
    }

    _assertNonZeroAmount(amount_);
    _assertOnlyKeeperAdminOrWorker(keeperId_);

    if (amount_ > available) {
      revert WithdrawAmountExceedsAvailable(amount_, available);
    }

    unchecked {
      compensations[keeperId_] = available - amount_;
    }

    to_.transfer(amount_);

    emit WithdrawCompensation(keeperId_, to_, amount_);
  }

  /**
   * Deposits CVP for the given keeper ID. The beneficiary receives a derivative erc20 token in exchange of CVP.
   *   Accounts the staking amount on the beneficiary's stakeOf balance.
   *
   * @param keeperId_ The keeper ID
   * @param amount_ The amount to stake
   */
  function stake(uint256 keeperId_, uint256 amount_) external {
    _assertNonZeroAmount(amount_);
    _assertKeeperIdExists(keeperId_);
    _stake(keeperId_, amount_);
  }

  function _stake(uint256 keeperId_, uint256 amount_) internal {
    uint256 amountAfter = keepers[keeperId_].cvpStake + amount_;
    if (amountAfter > type(uint88).max) {
      revert StakeAmountOverflow();
    }
    CVP.transferFrom(msg.sender, address(this), amount_);
    keepers[keeperId_].cvpStake += uint88(amount_);

    emit Stake(keeperId_, amount_, msg.sender);
  }

  /**
   * A keeper initiates CVP withdrawal.
   * The given CVP amount needs to go through the cooldown stage. After the cooldown is complete this amount could be
   * withdrawn using `finalizeRedeem()` method.
   * The msg.sender burns the paCVP token in exchange of the corresponding CVP amount.
   * Accumulates the existing pending for withdrawal amounts and re-initiates cooldown period.
   * If there is any slashed amount for the msg.sender, it should be compensated within the first initiateRedeem transaction
   * by burning the equivalent amount of paCVP tokens. The remaining CVP tokens won't be redeemed unless the slashed
   * amount is compensated.
   *
   * @param keeperId_ The keeper ID
   * @param amount_ The amount to cooldown
   * @return pendingWithdrawalAfter The total pending for withdrawal amount
   */
  function initiateRedeem(uint256 keeperId_, uint256 amount_) external returns (uint256 pendingWithdrawalAfter) {
    _assertOnlyKeeperAdmin(keeperId_);
    _assertNonZeroAmount(amount_);
    _beforeInitiateRedeem(keeperId_);

    uint256 stakeOfBefore = keepers[keeperId_].cvpStake;
    uint256 slashedStakeOfBefore = slashedStakeOf[keeperId_];
    uint256 totalStakeBefore = stakeOfBefore + slashedStakeOfBefore;

    // Should burn at least the total slashed stake
    if (amount_ < slashedStakeOfBefore) {
      revert InsufficientAmountToCoverSlashedStake(amount_, slashedStakeOfBefore);
    }

    if (amount_ > totalStakeBefore) {
      revert AmountGtStake(amount_, stakeOfBefore, slashedStakeOfBefore);
    }

    slashedStakeOf[keeperId_] = 0;
    uint256 stakeOfToReduceAmount;
    unchecked {
      stakeOfToReduceAmount = amount_ - slashedStakeOfBefore;
      keepers[keeperId_].cvpStake = uint88(stakeOfBefore - stakeOfToReduceAmount);
      pendingWithdrawalAmounts[keeperId_] += stakeOfToReduceAmount;
    }

    pendingWithdrawalAfter = block.timestamp + pendingWithdrawalTimeoutSeconds;
    pendingWithdrawalEndsAt[keeperId_] = pendingWithdrawalAfter;

    emit InitiateRedeem(keeperId_, amount_, stakeOfToReduceAmount, slashedStakeOfBefore);
  }

  /**
   * A keeper finalizes CVP withdrawal and receives the staked CVP tokens.
   *
   * @param keeperId_ The keeper ID
   * @param to_ The address to transfer CVP to
   * @return redeemedCvp The redeemed CVP amount
   */
  function finalizeRedeem(uint256 keeperId_, address to_) external returns (uint256 redeemedCvp) {
    _assertOnlyKeeperAdmin(keeperId_);

    if (pendingWithdrawalEndsAt[keeperId_] > block.timestamp) {
      revert WithdrawalTimoutNotReached();
    }

    redeemedCvp = pendingWithdrawalAmounts[keeperId_];
    if (redeemedCvp == 0) {
      revert NoPendingWithdrawal();
    }

    pendingWithdrawalAmounts[keeperId_] = 0;
    CVP.transfer(to_, redeemedCvp);

    emit FinalizeRedeem(keeperId_, to_, redeemedCvp);
  }

  /*** CONTRACT OWNER INTERFACE ***/
  /**
   * Slashes any keeper_ for an amount within keeper's deposit.
   * Penalises a keeper for malicious behaviour like sandwitching upkeep transactions.
   *
   * @param keeperId_ The keeper ID to slash
   * @param to_ The address to send the slashed CVP to
   * @param currentAmount_ The amount to slash from the current keeper.cvpStake balance
   * @param pendingAmount_ The amount to slash from the pendingWithdrawals balance
   */
  function slash(uint256 keeperId_, address to_, uint256 currentAmount_, uint256 pendingAmount_) external {
    _assertOnlyOwner();
    uint256 totalAmount = currentAmount_ + pendingAmount_;
    _assertNonZeroAmount(totalAmount);

    if (currentAmount_ > 0) {
      keepers[keeperId_].cvpStake -= uint88(currentAmount_);
      slashedStakeOf[keeperId_] += currentAmount_;
    }

    if (pendingAmount_ > 0) {
      pendingWithdrawalAmounts[keeperId_] -= pendingAmount_;
    }

    CVP.transfer(to_, totalAmount);

    emit Slash(keeperId_, to_, currentAmount_, pendingAmount_);
  }

  /**
   * Owner withdraws all the accrued rewards in native tokens to the provided address.
   *
   * @param to_ The address to send rewards to
   */
  function withdrawFees(address payable to_) external {
    _assertOnlyOwner();

    uint256 amount = feeTotal;
    feeTotal = 0;

    to_.transfer(amount);

    emit WithdrawFees(to_, amount);
  }

  /**
   * Owner updates minKeeperCVP value
   *
   * @param minKeeperCvp_ The new minKeeperCVP value
   */
  function setAgentParams(
    uint256 minKeeperCvp_,
    uint256 timeoutSeconds_,
    uint256 feePpm_
  ) external {
    _assertOnlyOwner();
    _setAgentParams(minKeeperCvp_, timeoutSeconds_, feePpm_);
  }

  function _setAgentParams(
    uint256 minKeeperCvp_,
    uint256 timeoutSeconds_,
    uint256 feePpm_
  ) internal {
    if (timeoutSeconds_ > MAX_PENDING_WITHDRAWAL_TIMEOUT_SECONDS) {
      revert TimeoutTooBig();
    }
    if (feePpm_ > MAX_FEE_PPM) {
      revert FeeTooBig();
    }

    minKeeperCvp = minKeeperCvp_;
    pendingWithdrawalTimeoutSeconds = timeoutSeconds_;
    feePpm = feePpm_;

    emit SetAgentParams(minKeeperCvp_, timeoutSeconds_, feePpm_);
  }

  /*** GETTERS ***/

  /**
   * Pure method that calculates keeper compensation based on a dynamic and a fixed multipliers.
   * DANGER: could overflow when used externally
   *
   * @param rewardPct_ The fixed percent. uint16. 0 == 0%, 100 == 100%, 500 == 500%, max 56535 == 56535%
   * @param fixedReward_ The fixed reward. uint32. Always multiplied by 1e15 (FIXED_PAYMENT_MULTIPLIER).
   *                     For ex. 2 == 2e15, 1_000 = 1e18, max 4294967295 == 4_294_967.295e18
   * @param blockBaseFee_ The block.basefee value.
   * @param gasUsed_ The gas used in wei.
   *
   */
  function calculateCompensationPure(
    uint256 rewardPct_,
    uint256 fixedReward_,
    uint256 blockBaseFee_,
    uint256 gasUsed_
  ) public pure returns (uint256) {
    unchecked {
      return (gasUsed_ + _getJobGasOverhead()) * blockBaseFee_ * rewardPct_ / 100
             + fixedReward_ * FIXED_PAYMENT_MULTIPLIER;
    }
  }

  function getKeeperWorkerAndStake(uint256 keeperId_)
    external view returns (
      address worker,
      uint256 currentStake,
      bool isActive
    )
  {
    Keeper memory keeper = keepers[keeperId_];

    return (
      keeper.worker,
      keeper.cvpStake,
      keeper.isActive
    );
  }

  function getConfig()
    external view returns (
      uint256 minKeeperCvp_,
      uint256 pendingWithdrawalTimeoutSeconds_,
      uint256 feeTotal_,
      uint256 feePpm_,
      uint256 lastKeeperId_
    )
  {
    return (
      minKeeperCvp,
      pendingWithdrawalTimeoutSeconds,
      feeTotal,
      feePpm,
      lastKeeperId
    );
  }

  function getKeeper(uint256 keeperId_)
    external view returns (
      address admin,
      address worker,
      bool isActive,
      uint256 currentStake,
      uint256 slashedStake,
      uint256 compensation,
      uint256 pendingWithdrawalAmount,
      uint256 pendingWithdrawalEndAt
    )
  {
    pendingWithdrawalEndAt = pendingWithdrawalEndsAt[keeperId_];
    pendingWithdrawalAmount = pendingWithdrawalAmounts[keeperId_];
    compensation = compensations[keeperId_];
    slashedStake = slashedStakeOf[keeperId_];

    Keeper memory keeper = keepers[keeperId_];
    currentStake = keeper.cvpStake;
    isActive = keeper.isActive;
    worker = keeper.worker;

    admin = keeperAdmins[keeperId_];
  }

  function getJob(bytes32 jobKey_)
    external view returns (
      address owner,
      address pendingTransfer,
      uint256 jobLevelMinKeeperCvp,
      Job memory details,
      bytes memory preDefinedCalldata,
      Resolver memory resolver
    )
  {
    return (
      jobOwners[jobKey_],
      jobPendingTransfers[jobKey_],
      jobMinKeeperCvp[jobKey_],
      jobs[jobKey_],
      preDefinedCalldatas[jobKey_],
      resolvers[jobKey_]
    );
  }

  /**
   * Returns the principal job data stored in a single EVM slot.
   * @notice To get parsed job data use `getJob()` method instead.
   *
   * The job slot data layout:
   *  0x0000000000000a000000000a002300640000000de0b6b3a7640000d09de08a01
   *  0x      00000000   00000a   00             0000000a    0023      0064           0000000de0b6b3a7640000 d09de08a 01
   *  name    lastExecAt interval calldataSource fixedReward rewardPct maxBaseFeeGwei nativeCredits          selector config bitmask
   *  size b  bytes4     bytes3   bytes4         bytes4      bytes2    bytes2         bytes11                bytes4   bytes1
   *  size u  uint32     uint24   uint8          uint32      uint16    uint16         uint88                 uint32   uint8
   *  bits    0-3        4-6      7-7            8-11        12-13     14-15          16-26                  27-30    31-31
   */
  function getJobRaw(bytes32 jobKey_) public view returns (uint256 rawJob) {
    Job storage job = jobs[jobKey_];
    assembly ("memory-safe") {
      rawJob := sload(job.slot)
    }
  }

  function getJobKey(address jobAddress_, uint256 jobId_) public pure returns (bytes32 jobKey) {
    assembly ("memory-safe") {
      mstore(0, shl(96, jobAddress_))
      mstore(20, shl(232, jobId_))
      jobKey := keccak256(0, 23)
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract PPAgentV2Flags {
  // Keeper pass this flags withing execute() transaction
  uint256 internal constant FLAG_ACCEPT_MAX_BASE_FEE_LIMIT = 0x01;
  uint256 internal constant FLAG_ACCRUE_REWARD = 0x02;

  // Job owner uses CFG_* flags to configure a job options
  uint256 internal constant CFG_ACTIVE = 0x01;
  uint256 internal constant CFG_USE_JOB_OWNER_CREDITS = 0x02;
  uint256 internal constant CFG_ASSERT_RESOLVER_SELECTOR = 0x04;
  uint256 internal constant CFG_CHECK_KEEPER_MIN_CVP_DEPOSIT = 0x08;

  uint256 internal constant BM_CLEAR_CONFIG = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00;
  uint256 internal constant BM_CLEAR_CREDITS = 0xffffffffffffffffffffffffffffffff0000000000000000000000ffffffffff;
  uint256 internal constant BM_CLEAR_LAST_UPDATE_AT = 0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IPPAgentV2Executor {
  function execute_44g58pv() external;
}

interface IPPAgentV2Viewer {
  struct Job {
    uint8 config;
    bytes4 selector;
    uint88 credits;
    uint16 maxBaseFeeGwei;
    uint16 rewardPct;
    uint32 fixedReward;
    uint8 calldataSource;

    // For interval jobs
    uint24 intervalSeconds;
    uint32 lastExecutionAt;
  }

  struct Resolver {
    address resolverAddress;
    bytes resolverCalldata;
  }

  function getConfig() external view returns (
    uint256 minKeeperCvp_,
    uint256 pendingWithdrawalTimeoutSeconds_,
    uint256 feeTotal_,
    uint256 feePpm_,
    uint256 lastKeeperId_
  );
  function getKeeper(uint256 keeperId_) external view returns (
    address admin,
    address worker,
    bool isActive,
    uint256 currentStake,
    uint256 slashedStake,
    uint256 compensation,
    uint256 pendingWithdrawalAmount,
    uint256 pendingWithdrawalEndAt
  );
  function getKeeperWorkerAndStake(uint256 keeperId_) external view returns (
    address worker,
    uint256 currentStake,
    bool isActive
  );
  function getJob(bytes32 jobKey_) external view returns (
    address owner,
    address pendingTransfer,
    uint256 jobLevelMinKeeperCvp,
    Job memory details,
    bytes memory preDefinedCalldata,
    Resolver memory resolver
  );
  function getJobRaw(bytes32 jobKey_) external view returns (uint256 rawJob);
  function jobOwnerCredits(address owner_) external view returns (uint256 credits);
}

interface IPPAgentV2JobOwner {
  struct RegisterJobParams {
    address jobAddress;
    bytes4 jobSelector;
    bool useJobOwnerCredits;
    bool assertResolverSelector;
    uint16 maxBaseFeeGwei;
    uint16 rewardPct;
    uint32 fixedReward;
    uint256 jobMinCvp;
    uint8 calldataSource;
    uint24 intervalSeconds;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { PPAgentV2, ConfigFlags } from "./PPAgentV2.sol";
import "./PPAgentV2Flags.sol";
import "./PPAgentV2Interfaces.sol";

/**
 * @title PPAgentV2Randao
 * @author PowerPool
 */
contract PPAgentV2Randao is PPAgentV2 {
  using EnumerableSet for EnumerableSet.Bytes32Set;
  using EnumerableSet for EnumerableSet.UintSet;

  error JobHasKeeperAssigned(uint256 keeperId);
  error SlashingEpochBlocksTooLow();
  error InvalidPeriod1();
  error InvalidPeriod2();
  error InvalidSlashingFeeFixedCVP();
  error SlashingBpsGt5000Bps();
  error InvalidStakeDivisor();
  error InactiveKeeper();
  error KeeperIsAssignedToJobs(uint256 amountOfJobs);
  error OnlyCurrentSlasher(uint256 expectedSlasherId);
  error OnlyReservedSlasher(uint256 reservedSlasherId);
  error TooEarlyForSlashing(uint256 now_, uint256 possibleAfter);
  error SlashingNotInitiated();
  error SlashingNotInitiatedExecutionReverted();
  error KeeperCantSlash();
  error KeeperIsAlreadyActive();
  error KeeperIsAlreadyInactive();
  error UnexpectedCodeBlock();
  error InitiateSlashingUnexpectedError();
  error NonIntervalJob();
  error JobCheckResolverError(bytes errReason);
  error JobCheckResolverReturnedFalse();
  error TooEarlyToReinitiateSlashing();
  error JobCheckCanBeExecuted();
  error JobCheckCanNotBeExecuted(bytes errReason);
  error TooEarlyToRelease(bytes32 jobKey, uint256 period2End);
  error TooEarlyForActivationFinalization(uint256 now, uint256 availableAt);
  error CantRelease();
  error ExecutionRevertedOnlyNextKeeper(uint256 expectedKeeperId);
  error OnlyNextKeeper(
    uint256 expectedKeeperId,
    uint256 lastExecutedAt,
    uint256 interval,
    uint256 slashingInterval,
    uint256 _now
  );
  error InsufficientKeeperStakeToSlash(
    bytes32 jobKey,
    uint256 expectedKeeperId,
    uint256 keeperCurrentStake,
    uint256 amountToSlash
  );

  event DisableKeeper(uint256 keeperId);
  event InitiateKeeperActivation(uint256 keeperId, uint256 canBeFinalizedAt);
  event FinalizeKeeperActivation(uint256 keeperId);
  event InitiateSlashing(
    bytes32 indexed jobKey,
    uint256 indexed slasherKeeperId,
    bool useResolver,
    uint256 jobSlashingPossibleAfter
  );
  event ExecutionReverted(
    bytes32 indexed jobKey,
    uint256 indexed keeperId,
    bytes executionReturndata
  );
  event SlashIntervalJob(
    bytes32 indexed jobKey,
    uint256 indexed expectedKeeperId,
    uint256 indexed actualKeeperId,
    uint256 fixedSlashAmount,
    uint256 dynamicSlashAmount
  );
  event SetRdConfig(RandaoConfig rdConfig);
  event KeeperJobLock(uint256 indexed keeperId, bytes32 indexed jobKey);
  event JobKeeperUnassigned(bytes32 indexed jobKey);
  event KeeperJobUnlock(uint256 indexed keeperId, bytes32 indexed jobKey);

  // 8+24+16+24+16+16+40+16+32 = 192
  struct RandaoConfig {
    // max: 2^8 - 1 = 255 blocks
    uint8 slashingEpochBlocks;
    // max: 2^24 - 1 = 16777215 seconds ~ 194 days
    uint24 period1;
    // max: 2^16 - 1 = 65535 seconds ~ 18 hours
    uint16 period2;
    // in 1 CVP. max: 16_777_215 CVP. The value here is multiplied by 1e18 in calculations.
    uint24 slashingFeeFixedCVP;
    // In BPS
    uint16 slashingFeeBps;
    // max: 2^16 - 1 = 65535, in calculations is multiplied by 0.001 ether (1 finney),
    // thus the min is 0.001 ether and max is 65.535 ether
    uint16 jobMinCreditsFinney;
    // max 2^40 ~= 1.1e12, in calculations is multiplied by 1 ether
    uint40 agentMaxCvpStake;
    // max: 2^16 - 1 = 65535, where 10_000 is 100%
    uint16 jobCompensationMultiplierBps;
    // max: 2^32 - 1 = 4_294_967_295
    uint32 stakeDivisor;
    // max: 2^8 - 1 = 255 hours, or ~10.5 days
    uint8 keeperActivationTimeoutHours;
  }

  RandaoConfig public rdConfig;

  // keccak256(jobAddress, id) => nextKeeperId
  mapping(bytes32 => uint256) public jobNextKeeperId;
  // keccak256(jobAddress, id) => nextSlasherId
  mapping(bytes32 => uint256) public jobReservedSlasherId;
  // keccak256(jobAddress, id) => timestamp, for non-interval jobs
  mapping(bytes32 => uint256) public jobSlashingPossibleAfter;
  // keccak256(jobAddress, id) => timestamp
  mapping(bytes32 => uint256) public jobCreatedAt;
  // keeperId => (pending jobs)
  mapping(uint256 => EnumerableSet.Bytes32Set) internal keeperLocksByJob;
  // keeperId => timestamp
  mapping(uint256 => uint256) public keeperActivationCanBeFinalizedAt;

  EnumerableSet.UintSet internal activeKeepers;

  function getStrategy() public pure override returns (string memory) {
    return "randao";
  }

  function _getJobGasOverhead() internal pure override returns (uint256) {
    return 55_000;
  }

  constructor(address cvp_) PPAgentV2(cvp_) {
  }

  function initializeRandao(
    address owner_,
    uint256 minKeeperCvp_,
    uint256 pendingWithdrawalTimeoutSeconds_,
    RandaoConfig memory rdConfig_) external {
    PPAgentV2.initialize(owner_, minKeeperCvp_, pendingWithdrawalTimeoutSeconds_);
    _setRdConfig(rdConfig_);
  }

  /*** AGENT OWNER METHODS ***/
  function setRdConfig(RandaoConfig calldata rdConfig_) external onlyOwner {
    _setRdConfig(rdConfig_);
  }

  function _setRdConfig(RandaoConfig memory rdConfig_) internal {
    if (rdConfig_.slashingEpochBlocks < 3) {
      revert SlashingEpochBlocksTooLow();
    }
    if (rdConfig_.period1 < 15 seconds) {
      revert InvalidPeriod1();
    }
    if (rdConfig_.period2 < 15 seconds) {
      revert InvalidPeriod2();
    }
    if (rdConfig_.slashingFeeFixedCVP > (minKeeperCvp / 2)) {
      revert InvalidSlashingFeeFixedCVP();
    }
    if (rdConfig_.slashingFeeBps > 5000) {
      revert SlashingBpsGt5000Bps();
    }
    if (rdConfig_.stakeDivisor == 0) {
      revert InvalidStakeDivisor();
    }
    emit SetRdConfig(rdConfig_);

    rdConfig = rdConfig_;
  }

  /*** JOB OWNER METHODS ***/
  function assignKeeper(bytes32[] calldata jobKeys_) external {
    for (uint256 i = 0; i < jobKeys_.length; i++) {
      bytes32 jobKey = jobKeys_[i];
      uint256 assignedKeeperId = jobNextKeeperId[jobKey];
      if (assignedKeeperId != 0) {
        revert JobHasKeeperAssigned(assignedKeeperId);
      }
      _assertOnlyJobOwner(jobKey);

      _assignNextKeeper(jobKey);
    }
  }

  /*** KEEPER METHODS ***/
  function releaseJob(bytes32 jobKey_) external {
    uint256 assignedKeeperId = jobNextKeeperId[jobKey_];

    // Job owner can unassign a keeper without any restriction
    if (msg.sender == jobOwners[jobKey_]) {
      _releaseKeeper(jobKey_, assignedKeeperId);
      return;
    }
    // Otherwise this is a keeper's call

    _assertOnlyKeeperAdmin(assignedKeeperId);

    uint256 binJob = getJobRaw(jobKey_);
    uint256 intervalSeconds = (binJob << 32) >> 232;

    // 1. Release if insufficient credits
    if (_releaseKeeperIfRequired(jobKey_, assignedKeeperId)) {
      return;
    }

    // 2. Check interval timeouts otherwise
    // 2.1 If interval job
    if (intervalSeconds != 0) {
      uint256 lastExecutionAt = binJob >> 224;
      if (lastExecutionAt == 0) {
        lastExecutionAt = jobCreatedAt[jobKey_];
      }
      uint256 period2EndsAt = lastExecutionAt + rdConfig.period1 + rdConfig.period2;
      if (period2EndsAt > block.timestamp) {
        revert TooEarlyToRelease(jobKey_, period2EndsAt);
      } // else can release
    // 2.2 If resolver job
    } else {
      // if slashing process initiated
      uint256 _jobSlashingPossibleAfter = jobSlashingPossibleAfter[jobKey_];
      if (_jobSlashingPossibleAfter != 0) {
        uint256 period2EndsAt = _jobSlashingPossibleAfter + rdConfig.period2;
        if (period2EndsAt > block.timestamp) {
          revert TooEarlyToRelease(jobKey_, period2EndsAt);
        }
      // if no slashing initiated
      } else {
        revert CantRelease();
      }
    }

    _releaseKeeper(jobKey_, assignedKeeperId);
  }

  function disableKeeper(uint256 keeperId_) external {
    _assertOnlyKeeperAdmin(keeperId_);

    if (!keepers[keeperId_].isActive) {
      revert KeeperIsAlreadyInactive();
    }

    _ensureCanReleaseKeeper(keeperId_);
    activeKeepers.remove(keeperId_);
    keepers[keeperId_].isActive = false;

    emit DisableKeeper(keeperId_);
  }

  function initiateKeeperActivation(uint256 keeperId_) external {
    _assertOnlyKeeperAdmin(keeperId_);

    if (keepers[keeperId_].isActive) {
      revert KeeperIsAlreadyActive();
    }

    uint256 canBeFinalizedAt = block.timestamp + rdConfig.keeperActivationTimeoutHours * 1 hours;
    keeperActivationCanBeFinalizedAt[keeperId_] = canBeFinalizedAt;

    emit InitiateKeeperActivation(keeperId_, canBeFinalizedAt);
  }

  function finalizeKeeperActivation(uint256 keeperId_) external {
    _assertOnlyKeeperAdmin(keeperId_);

    uint256 availableAt = keeperActivationCanBeFinalizedAt[keeperId_];
    if (availableAt > block.timestamp) {
      revert TooEarlyForActivationFinalization(block.timestamp, availableAt);
    }

    activeKeepers.add(keeperId_);
    keepers[keeperId_].isActive = true;
    keeperActivationCanBeFinalizedAt[keeperId_] = 0;

    emit FinalizeKeeperActivation(keeperId_);
  }

  function _afterExecutionReverted(
    bytes32 jobKey_,
    CalldataSourceType calldataSource_,
    uint256 keeperId_,
    bytes memory executionResponse_
  ) internal override {
    if (calldataSource_ == CalldataSourceType.RESOLVER &&
      jobReservedSlasherId[jobKey_] == 0 && jobSlashingPossibleAfter[jobKey_] == 0) {
      revert SlashingNotInitiatedExecutionReverted();
    }

    _releaseKeeper(jobKey_, keeperId_);

    emit ExecutionReverted(jobKey_, keeperId_, executionResponse_);
  }

  function initiateSlashing(
    address jobAddress_,
    uint256 jobId_,
    uint256 slasherKeeperId_,
    bool useResolver_,
    bytes memory jobCalldata_
  ) external {
    bytes32 jobKey = getJobKey(jobAddress_, jobId_);
    uint256 binJob = getJobRaw(jobKey);

    // 0. Keeper has sufficient stake
    {
      Keeper memory keeper = keepers[slasherKeeperId_];
      if (keeper.worker != msg.sender) {
        revert KeeperWorkerNotAuthorized();
      }
      if (keeper.cvpStake < minKeeperCvp) {
        revert InsufficientKeeperStake();
      }
      if (!keeper.isActive) {
        revert InactiveKeeper();
      }
    }

    // 1. Assert the job is active
    {
      if (!ConfigFlags.check(binJob, CFG_ACTIVE)) {
        revert InactiveJob(jobKey);
      }
    }

    // 2. Assert job-scoped keeper's minimum CVP deposit
    if (ConfigFlags.check(binJob, CFG_CHECK_KEEPER_MIN_CVP_DEPOSIT) &&
      keepers[slasherKeeperId_].cvpStake < jobMinKeeperCvp[jobKey]) {
      revert InsufficientJobScopedKeeperStake();
    }

    // 3. Not an interval job
    {
      uint256 intervalSeconds = (binJob << 32) >> 232;
      if (intervalSeconds != 0) {
        revert NonIntervalJob();
      }
    }

    // 4. keeper can't slash
    if (jobNextKeeperId[jobKey] == slasherKeeperId_) {
      revert KeeperCantSlash();
    }

    // 5. current slasher
    {
      uint256 currentSlasherId = getCurrentSlasherId(jobKey);
      if (slasherKeeperId_ != currentSlasherId) {
        revert OnlyCurrentSlasher(currentSlasherId);
      }
    }

    // 6. Slashing not initiated yet
    uint256 _jobSlashingPossibleAfter = jobSlashingPossibleAfter[jobKey];
    // if is already initiated
    if (_jobSlashingPossibleAfter != 0 &&
      // but not overdue yet
      (_jobSlashingPossibleAfter + rdConfig.period2) > block.timestamp
      ) {
      revert TooEarlyToReinitiateSlashing();
    }

    // 7. check if could be executed
    if (useResolver_) {
      IPPAgentV2Viewer.Resolver memory resolver = resolvers[jobKey];
      (bool ok, bytes memory result) = resolver.resolverAddress.call(resolver.resolverCalldata);
      if (!ok) {
        revert JobCheckResolverError(result);
      }
      (bool canExecute,) = abi.decode(result, (bool, bytes));
      if (!canExecute) {
        revert JobCheckResolverReturnedFalse();
      } // else can be executed
    } else {
      (bool ok, bytes memory result) = address(this).call(
        abi.encodeWithSelector(PPAgentV2Randao.checkCouldBeExecuted.selector, jobAddress_, jobCalldata_)
      );
      if (ok) {
        revert UnexpectedCodeBlock();
      }
      bytes4 selector = bytes4(result);
      if (selector == PPAgentV2Randao.JobCheckCanNotBeExecuted.selector) {
        assembly ("memory-safe") {
            revert(add(32, result), mload(result))
        }
      } else if (selector != PPAgentV2Randao.JobCheckCanBeExecuted.selector) {
        revert InitiateSlashingUnexpectedError();
      } // else can be executed
    }

    jobReservedSlasherId[jobKey] = slasherKeeperId_;
    _jobSlashingPossibleAfter = block.timestamp + rdConfig.period1;
    jobSlashingPossibleAfter[jobKey] = _jobSlashingPossibleAfter;

    emit InitiateSlashing(jobKey, slasherKeeperId_, useResolver_, _jobSlashingPossibleAfter);
  }

  /*** OVERRIDES ***/
  function registerJob(
    RegisterJobParams calldata params_,
    Resolver calldata resolver_,
    bytes calldata preDefinedCalldata_
  ) public payable override returns (bytes32 jobKey, uint256 jobId){
    (jobKey, jobId) = super.registerJob(params_, resolver_, preDefinedCalldata_);
    jobCreatedAt[jobKey] = block.timestamp;
  }

  function registerAsKeeper(address worker_, uint256 initialDepositAmount_) public override returns (uint256 keeperId) {
    keeperId = super.registerAsKeeper(worker_, initialDepositAmount_);
    activeKeepers.add(keeperId);
  }

  function setJobConfig(
    bytes32 jobKey_,
    bool isActive_,
    bool useJobOwnerCredits_,
    bool assertResolverSelector_
  ) public override {
    uint256 rawJobBefore = getJobRaw(jobKey_);
    super.setJobConfig(jobKey_, isActive_, useJobOwnerCredits_, assertResolverSelector_);
    bool wasActiveBefore = ConfigFlags.check(rawJobBefore, CFG_ACTIVE);

    // inactive => active: assign if required
    if(!wasActiveBefore && isActive_)  {
      _assignNextKeeperIfRequired(jobKey_);
    }

    // job was and remain active, but the credits source has changed: assign or release if requried
    if (wasActiveBefore && isActive_ &&
      (ConfigFlags.check(rawJobBefore, CFG_USE_JOB_OWNER_CREDITS) != useJobOwnerCredits_)) {

      if (!_assignNextKeeperIfRequired(jobKey_)) {
        uint256 expectedKeeperId = jobNextKeeperId[jobKey_];
        _releaseKeeperIfRequired(jobKey_, expectedKeeperId);
      }
    }

    // active => inactive: unassign
    if (wasActiveBefore && !isActive_) {
      uint256 expectedKeeperId = jobNextKeeperId[jobKey_];
      _releaseKeeper(jobKey_, expectedKeeperId);
    }
  }

  /*** HOOKS ***/
  function _beforeExecute(bytes32 jobKey_, uint256 actualKeeperId_, uint256 binJob_) internal view override {
    uint256 nextKeeperId = jobNextKeeperId[jobKey_];
    uint256 intervalSeconds = (binJob_ << 32) >> 232;
    uint256 lastExecutionAt = binJob_ >> 224;

    // if interval task is called by a slasher
    if (intervalSeconds > 0 && nextKeeperId != actualKeeperId_) {
      uint256 nextExecutionTimeoutAt;
      uint256 _lastExecutionAt = lastExecutionAt;
      if (_lastExecutionAt == 0) {
        _lastExecutionAt = jobCreatedAt[jobKey_];
      }
      unchecked {
        nextExecutionTimeoutAt = _lastExecutionAt + intervalSeconds + rdConfig.period1;
      }
      // if it is to early to slash this job
      if (block.timestamp < nextExecutionTimeoutAt) {
        revert OnlyNextKeeper(nextKeeperId, lastExecutionAt, intervalSeconds, rdConfig.period1, block.timestamp);
      }

      uint256 currentSlasherId = getCurrentSlasherId(jobKey_);
      if (actualKeeperId_ != currentSlasherId) {
        revert OnlyCurrentSlasher(currentSlasherId);
      }
    // if a resolver job is called by a slasher
    } else  if (intervalSeconds == 0 && nextKeeperId != actualKeeperId_) {
      uint256 _jobSlashingPossibleAfter = jobSlashingPossibleAfter[jobKey_];
      if (_jobSlashingPossibleAfter == 0) {
        revert SlashingNotInitiated();
      }
      if (_jobSlashingPossibleAfter > block.timestamp) {
        revert TooEarlyForSlashing(block.timestamp, jobSlashingPossibleAfter[jobKey_]);
      }

      uint256 _jobReservedSlasherId = jobReservedSlasherId[jobKey_];
      if (_jobReservedSlasherId != actualKeeperId_) {
        revert OnlyReservedSlasher(_jobReservedSlasherId);
      }
    }
  }

  function _afterDepositJobCredits(bytes32 jobKey_) internal override {
    _assignNextKeeperIfRequired(jobKey_);
  }

  function _afterWithdrawJobCredits(bytes32 jobKey_) internal override {
    uint256 expectedKeeperId = jobNextKeeperId[jobKey_];
    _releaseKeeperIfRequired(jobKey_, expectedKeeperId);
  }

  function _afterExecutionSucceeded(bytes32 jobKey_, uint256 actualKeeperId_, uint256 binJob_) internal override {
    uint256 expectedKeeperId = jobNextKeeperId[jobKey_];
    _releaseKeeper(jobKey_, expectedKeeperId);

    uint256 intervalSeconds = (binJob_ << 32) >> 232;

    if (intervalSeconds == 0) {
      jobReservedSlasherId[jobKey_] = 0;
      jobSlashingPossibleAfter[jobKey_] = 0;
    }

    // if slashing
    if (expectedKeeperId != actualKeeperId_) {
      Keeper memory eKeeper = keepers[expectedKeeperId];
      uint256 dynamicSlashAmount = eKeeper.cvpStake * uint256(rdConfig.slashingFeeBps) / 10_000;
      uint256 fixedSlashAmount = uint256(rdConfig.slashingFeeFixedCVP) * 1 ether;
      // NOTICE: totalSlashAmount can't be >= uint88
      uint88 totalSlashAmount = uint88(fixedSlashAmount + dynamicSlashAmount);
      if (totalSlashAmount > eKeeper.cvpStake) {
        // Actually this block should not be reached, so this is just in case
        revert InsufficientKeeperStakeToSlash(jobKey_, expectedKeeperId, eKeeper.cvpStake, totalSlashAmount);
      }
      keepers[expectedKeeperId].cvpStake -= totalSlashAmount;
      keepers[actualKeeperId_].cvpStake += totalSlashAmount;
      emit SlashIntervalJob(jobKey_, expectedKeeperId, actualKeeperId_, fixedSlashAmount, dynamicSlashAmount);
    }

    _assignNextKeeper(jobKey_);
  }

  function _beforeInitiateRedeem(uint256 keeperId_) internal view override {
    _ensureCanReleaseKeeper(keeperId_);
  }

  function _afterRegisterJob(bytes32 jobKey_) internal override {
    _assignNextKeeper(jobKey_);
  }

  /*** HELPERS ***/
  function _releaseKeeper(bytes32 jobKey_, uint256 keeperId_) internal {
    keeperLocksByJob[keeperId_].remove(jobKey_);

    jobNextKeeperId[jobKey_] = 0;
    jobSlashingPossibleAfter[jobKey_] = 0;
    jobReservedSlasherId[jobKey_] = 0;

    emit KeeperJobUnlock(keeperId_, jobKey_);
  }

  function _ensureCanReleaseKeeper(uint256 keeperId_) internal view {
    uint256 len = keeperLocksByJob[keeperId_].length();
    if (len > 0) {
      revert KeeperIsAssignedToJobs(len);
    }
  }

  function _getPseudoRandom() internal view returns (uint256) {
    return block.difficulty;
  }

  function _releaseKeeperIfRequired(bytes32 jobKey_, uint256 keeperId_) internal returns (bool released) {
    uint256 binJob = getJobRaw(jobKey_);
    return _releaseKeeperIfRequiredBinJob(jobKey_, keeperId_, binJob, false);
  }

  function _releaseKeeperIfRequiredBinJob(
    bytes32 jobKey_,
    uint256 keeperId_,
    uint256 binJob_,
    bool checkAlreadyReleased
  ) internal returns (bool released) {
    uint256 credits = (binJob_ << 128) >> 168;
    if (ConfigFlags.check(binJob_, CFG_USE_JOB_OWNER_CREDITS)) {
      credits = jobOwnerCredits[jobOwners[jobKey_]];
    }

    if ((!checkAlreadyReleased || jobNextKeeperId[jobKey_] != 0) && credits < (uint256(rdConfig.jobMinCreditsFinney) * 0.001 ether)) {
      _releaseKeeper(jobKey_, keeperId_);
      return true;
    }

    return false;
  }

  function _assignNextKeeperIfRequired(bytes32 jobKey_) internal returns (bool assigned) {
    uint256 binJob = getJobRaw(jobKey_);
    uint256 credits = (binJob << 128) >> 168;
    if (ConfigFlags.check(binJob, CFG_USE_JOB_OWNER_CREDITS)) {
      credits = jobOwnerCredits[jobOwners[jobKey_]];
    }

    if (jobNextKeeperId[jobKey_] == 0 && credits >= (uint256(rdConfig.jobMinCreditsFinney) * 0.001 ether)) {
      _assignNextKeeper(jobKey_);
      return true;
    }

    return false;
  }

  function _assignNextKeeper(bytes32 jobKey_) internal {
    if (_releaseKeeperIfRequiredBinJob(jobKey_, jobNextKeeperId[jobKey_], getJobRaw(jobKey_), false)) {
      return;
    }

    uint256 pseudoRandom = _getPseudoRandom();
    uint256 totalActiveKeepers = activeKeepers.length();
    uint256 _jobMinKeeperCvp = jobMinKeeperCvp[jobKey_];
    uint256 index;
    unchecked {
      index = ((pseudoRandom + uint256(jobKey_)) % totalActiveKeepers);
    }

    while (true) {
      if (index  >= totalActiveKeepers) {
        index = 0;
      }
      uint256 _nextExecutionKeeperId = activeKeepers.at(index);

      uint256 requiredStake = _jobMinKeeperCvp > 0 ? _jobMinKeeperCvp : minKeeperCvp;
      Keeper memory keeper = keepers[_nextExecutionKeeperId];

      if (keeper.isActive && keeper.cvpStake >= requiredStake) {
        jobNextKeeperId[jobKey_] = _nextExecutionKeeperId;

        keeperLocksByJob[_nextExecutionKeeperId].add(jobKey_);
        emit KeeperJobLock(_nextExecutionKeeperId, jobKey_);
        return;
      }
      index += 1;
    }
  }

  function _checkBaseFee(uint256 binJob_, uint256 cfg_) internal pure override returns (uint256) {
    binJob_;
    cfg_;

    return type(uint256).max;
  }

  function _calculateCompensation(
    bool ok_,
    uint256 job_,
    uint256 keeperId_,
    uint256 gasPrice_,
    uint256 gasUsed_
  ) internal view override returns (uint256) {
    if (!ok_) {
      return gasUsed_ * gasPrice_;
    }

    job_; // silence unused param warning
    RandaoConfig memory _rdConfig = rdConfig;

    uint256 stake = keepers[keeperId_].cvpStake;
    // fixedReward field for randao jobs contains _jobMaxCvpStake
    uint256 _jobMaxCvpStake = ((job_ << 64) >> 224) * 1 ether;
    if (_jobMaxCvpStake > 0  && _jobMaxCvpStake < stake) {
      stake = _jobMaxCvpStake;
    }
    if (_rdConfig.agentMaxCvpStake > 0 && _rdConfig.agentMaxCvpStake < stake) {
      stake = _rdConfig.agentMaxCvpStake;
    }

    return (gasPrice_ * gasUsed_ * _rdConfig.jobCompensationMultiplierBps / 10_000) +
      (stake / _rdConfig.stakeDivisor);
  }

  /*** GETTERS ***/

  function getJobsAssignedToKeeper(uint256 keeperId_) external view returns (bytes32[] memory jobKeys) {
    return keeperLocksByJob[keeperId_].values();
  }

  function getJobsAssignedToKeeperLength(uint256 keeperId_) external view returns (uint256) {
    return keeperLocksByJob[keeperId_].length();
  }

  function getCurrentSlasherId(bytes32 jobKey_) public view returns (uint256) {
    return getSlasherIdByBlock(block.number, jobKey_);
  }

  function getActiveKeepersLength() public view returns (uint256) {
    return activeKeepers.length();
  }

  function getActiveKeepers() public view returns (uint256[] memory) {
    return activeKeepers.values();
  }

  function getSlasherIdByBlock(uint256 blockNumber_, bytes32 jobKey_) public view returns (uint256) {
    uint256 totalActiveKeepers = activeKeepers.length();
    uint256 index = ((blockNumber_ / rdConfig.slashingEpochBlocks + uint256(jobKey_)) % totalActiveKeepers);
    return activeKeepers.at(index);
  }

  // The function that always reverts
  function checkCouldBeExecuted(address jobAddress_, bytes memory jobCalldata_) external {
    (bool ok, bytes memory result) = jobAddress_.call(jobCalldata_);
    if (ok) {
      revert JobCheckCanBeExecuted();
    } else {
      revert JobCheckCanNotBeExecuted(result);
    }
  }
}
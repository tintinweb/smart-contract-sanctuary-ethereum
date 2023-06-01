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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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

pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';

import "./Dependencies/BaseMath.sol";
import "./Interfaces/IAttributes.sol";
import "./Dependencies/console.sol";

contract Attributes is IAttributes, BaseMath, OwnableUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using SafeMathUpgradeable for uint256;

    string constant public NAME = "Attributes";

    // Minimum collateral ratio for individual clips
    uint256 public MCR;

    // Amount of LSDC to be locked in gas pool on opening clips
    uint256 public LSDC_GAS_COMPENSATION;

    // Percentage of collateral to be drawn from a clip and sent as gas compensation on liquidation
    uint256 public COL_GAS_COMPENSATION_PERCENT_DIVISOR;

    // Minimum amount of net LSDC debt a clip must have
    uint256 public MIN_NET_DEBT;

    uint256 public BORROWING_FEE_FLOOR;

    address public admin;
    // Address of the account that receives redemption and borrowing fee rewards
    address public feeCollector;

    EnumerableSetUpgradeable.AddressSet private _assets;
    mapping (address => AssetConfig) public assetConfigs;

    uint256 internal deploymentStartTime;

    modifier isOwnerOrAdmin() {
        require(msg.sender == owner() || msg.sender == admin, "Unauthorized");
        _;
    }

    function initialize(address _feeCollector) external initializer {
        __Ownable_init();
        deploymentStartTime  = block.timestamp;

        feeCollector = _feeCollector;

        MCR = 1250000000000000000; // 125%
        LSDC_GAS_COMPENSATION = 10e18;
        MIN_NET_DEBT = 490e18;
        BORROWING_FEE_FLOOR = DECIMAL_PRECISION / 1000 * 5; // 0.5%
        COL_GAS_COMPENSATION_PERCENT_DIVISOR = 200; // dividing by 200 yields 0.5%
    }

    function getMCR() public view override returns (uint256) {
        return MCR;
    }

    function setMCR(uint256 _mcr) external override isOwnerOrAdmin {
        MCR = _mcr;
        emit MCRUpdated(_mcr);
    }

    function getLSDCGasCompensation() public view override returns (uint256) {
        return LSDC_GAS_COMPENSATION;
    }

    function setLSDCGasCompensation(uint256 _gasCompensation) external override isOwnerOrAdmin {
        LSDC_GAS_COMPENSATION = _gasCompensation;
        emit LSDCGasCompensationUpdated(_gasCompensation);
    }

    function getColGasCompensationPercentDivisor() public view override returns (uint256) {
        return COL_GAS_COMPENSATION_PERCENT_DIVISOR;
    }

    function setColGasCompensationPercentDivisor(uint256 _colGasCompensationPercentDivisor) external override isOwnerOrAdmin {
        COL_GAS_COMPENSATION_PERCENT_DIVISOR = _colGasCompensationPercentDivisor;
        emit CollateralGasCompensationUpdated(_colGasCompensationPercentDivisor);
    }

    function getMinNetDebt() public view override returns (uint256) {
        return MIN_NET_DEBT;
    }

    function setMinNetDebt(uint256 _minNetDebt) external override isOwnerOrAdmin {
        MIN_NET_DEBT = _minNetDebt;
        emit MinNetDebtUpdated(_minNetDebt);
    }

    function getBorrowingFeeFloor() public view override returns (uint256) {
        return BORROWING_FEE_FLOOR;
    }

    function setBorrowingFeeFloor(uint256 _borrowingFeeFloor) external override isOwnerOrAdmin {
        BORROWING_FEE_FLOOR = _borrowingFeeFloor;
        emit BorrowingFeeFloorUpdated(_borrowingFeeFloor);
    }

    function isDepositAllowed(address _asset) public view returns (bool) {
        return assetConfigs[_asset].depositsEnabled;
    }

    function setDepositAllowed(address _asset, bool _allowed) external isOwnerOrAdmin {
        require(_assets.contains(_asset), "Asset not in use");

        assetConfigs[_asset].depositsEnabled = _allowed;
        emit DepositAllowedUpdated(_asset, _allowed);
    }

    function getAssets() public view returns (address[] memory) {
        return _assets.values();
    }

    function addAsset(address _asset, bool _depositsEnabled) external isOwnerOrAdmin {
        require(!_assets.contains(_asset), "Asset already exists");

        assetConfigs[_asset] = AssetConfig({
            depositsEnabled: _depositsEnabled
        });
        _assets.add(_asset);

        emit AssetAdded(_asset);
        emit DepositAllowedUpdated(_asset, _depositsEnabled);
    }

    function setFeeCollector(address _feeCollector) external override isOwnerOrAdmin {
        feeCollector = _feeCollector;
        emit FeeCollectorAddressChanged(_feeCollector);
    }

    function getDeploymentStartTime() external view override returns (uint256) {
        return deploymentStartTime;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


contract BaseMath {
    uint256 constant public DECIMAL_PRECISION = 1e18;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

// Buidler's helper contract for console logging
library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function log() internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log()"));
		ignored;
	}	function logInt(int p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(int)", p0));
		ignored;
	}

	function logUint(uint256 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256)", p0));
		ignored;
	}

	function logString(string memory p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string)", p0));
		ignored;
	}

	function logBool(bool p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool)", p0));
		ignored;
	}

	function logAddress(address p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address)", p0));
		ignored;
	}

	function logBytes(bytes memory p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes)", p0));
		ignored;
	}

	function logByte(bytes1 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(byte)", p0));
		ignored;
	}

	function logBytes1(bytes1 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes1)", p0));
		ignored;
	}

	function logBytes2(bytes2 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes2)", p0));
		ignored;
	}

	function logBytes3(bytes3 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes3)", p0));
		ignored;
	}

	function logBytes4(bytes4 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes4)", p0));
		ignored;
	}

	function logBytes5(bytes5 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes5)", p0));
		ignored;
	}

	function logBytes6(bytes6 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes6)", p0));
		ignored;
	}

	function logBytes7(bytes7 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes7)", p0));
		ignored;
	}

	function logBytes8(bytes8 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes8)", p0));
		ignored;
	}

	function logBytes9(bytes9 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes9)", p0));
		ignored;
	}

	function logBytes10(bytes10 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes10)", p0));
		ignored;
	}

	function logBytes11(bytes11 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes11)", p0));
		ignored;
	}

	function logBytes12(bytes12 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes12)", p0));
		ignored;
	}

	function logBytes13(bytes13 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes13)", p0));
		ignored;
	}

	function logBytes14(bytes14 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes14)", p0));
		ignored;
	}

	function logBytes15(bytes15 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes15)", p0));
		ignored;
	}

	function logBytes16(bytes16 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes16)", p0));
		ignored;
	}

	function logBytes17(bytes17 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes17)", p0));
		ignored;
	}

	function logBytes18(bytes18 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes18)", p0));
		ignored;
	}

	function logBytes19(bytes19 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes19)", p0));
		ignored;
	}

	function logBytes20(bytes20 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes20)", p0));
		ignored;
	}

	function logBytes21(bytes21 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes21)", p0));
		ignored;
	}

	function logBytes22(bytes22 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes22)", p0));
		ignored;
	}

	function logBytes23(bytes23 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes23)", p0));
		ignored;
	}

	function logBytes24(bytes24 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes24)", p0));
		ignored;
	}

	function logBytes25(bytes25 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes25)", p0));
		ignored;
	}

	function logBytes26(bytes26 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes26)", p0));
		ignored;
	}

	function logBytes27(bytes27 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes27)", p0));
		ignored;
	}

	function logBytes28(bytes28 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes28)", p0));
		ignored;
	}

	function logBytes29(bytes29 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes29)", p0));
		ignored;
	}

	function logBytes30(bytes30 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes30)", p0));
		ignored;
	}

	function logBytes31(bytes31 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes31)", p0));
		ignored;
	}

	function logBytes32(bytes32 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes32)", p0));
		ignored;
	}

	function log(uint256 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256)", p0));
		ignored;
	}

	function log(string memory p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string)", p0));
		ignored;
	}

	function log(bool p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool)", p0));
		ignored;
	}

	function log(address p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address)", p0));
		ignored;
	}

	function log(uint256 p0, uint256 p1) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
		ignored;
	}

	function log(uint256 p0, string memory p1) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,string)", p0, p1));
		ignored;
	}

	function log(uint256 p0, bool p1) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
		ignored;
	}

	function log(uint256 p0, address p1) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,address)", p0, p1));
		ignored;
	}

	function log(string memory p0, uint256 p1) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint256)", p0, p1));
		ignored;
	}

	function log(string memory p0, string memory p1) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string)", p0, p1));
		ignored;
	}

	function log(string memory p0, bool p1) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool)", p0, p1));
		ignored;
	}

	function log(string memory p0, address p1) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address)", p0, p1));
		ignored;
	}

	function log(bool p0, uint256 p1) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
		ignored;
	}

	function log(bool p0, string memory p1) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string)", p0, p1));
		ignored;
	}

	function log(bool p0, bool p1) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool)", p0, p1));
		ignored;
	}

	function log(bool p0, address p1) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address)", p0, p1));
		ignored;
	}

	function log(address p0, uint256 p1) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint256)", p0, p1));
		ignored;
	}

	function log(address p0, string memory p1) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string)", p0, p1));
		ignored;
	}

	function log(address p0, bool p1) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool)", p0, p1));
		ignored;
	}

	function log(address p0, address p1) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address)", p0, p1));
		ignored;
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
		ignored;
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
		ignored;
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
		ignored;
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
		ignored;
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
		ignored;
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
		ignored;
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
		ignored;
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
		ignored;
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
		ignored;
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
		ignored;
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
		ignored;
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
		ignored;
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
		ignored;
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
		ignored;
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
		ignored;
	}

	function log(uint256 p0, address p1, address p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
		ignored;
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
		ignored;
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
		ignored;
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
		ignored;
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
		ignored;
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
		ignored;
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
		ignored;
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
		ignored;
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
		ignored;
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
		ignored;
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
		ignored;
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
		ignored;
	}

	function log(string memory p0, bool p1, address p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
		ignored;
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
		ignored;
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
		ignored;
	}

	function log(string memory p0, address p1, bool p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
		ignored;
	}

	function log(string memory p0, address p1, address p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
		ignored;
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
		ignored;
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
		ignored;
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
		ignored;
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
		ignored;
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
		ignored;
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
		ignored;
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
		ignored;
	}

	function log(bool p0, string memory p1, address p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
		ignored;
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
		ignored;
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
		ignored;
	}

	function log(bool p0, bool p1, bool p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
		ignored;
	}

	function log(bool p0, bool p1, address p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
		ignored;
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
		ignored;
	}

	function log(bool p0, address p1, string memory p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
		ignored;
	}

	function log(bool p0, address p1, bool p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
		ignored;
	}

	function log(bool p0, address p1, address p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
		ignored;
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
		ignored;
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
		ignored;
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
		ignored;
	}

	function log(address p0, uint256 p1, address p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
		ignored;
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
		ignored;
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
		ignored;
	}

	function log(address p0, string memory p1, bool p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
		ignored;
	}

	function log(address p0, string memory p1, address p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
		ignored;
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
		ignored;
	}

	function log(address p0, bool p1, string memory p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
		ignored;
	}

	function log(address p0, bool p1, bool p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
		ignored;
	}

	function log(address p0, bool p1, address p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
		ignored;
	}

	function log(address p0, address p1, uint256 p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
		ignored;
	}

	function log(address p0, address p1, string memory p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
		ignored;
	}

	function log(address p0, address p1, bool p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
		ignored;
	}

	function log(address p0, address p1, address p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
		ignored;
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
		ignored;
	}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IAttributes {
    // --- Structs ---
    struct AssetConfig {
        bool depositsEnabled;
    }

    // --- Events ---
    event MCRUpdated(uint256 _mcr);
    event LSDCGasCompensationUpdated(uint256 _gasCompensation);
    event CollateralGasCompensationUpdated(uint256 _colGasCompensationPercentDivisor);
    event MinNetDebtUpdated(uint256 _minNetDebt);
    event BorrowingFeeFloorUpdated(uint256 _borrowingFeeFloor);
    event AssetAdded(address indexed _asset);
    event DepositAllowedUpdated(address indexed _asset, bool _allowed);
    event FeeCollectorAddressChanged(address indexed _feeCollectorAddress);

    // --- Functions ---
    function getMCR() external view returns (uint256);
    function getLSDCGasCompensation() external view returns (uint256);
    function getColGasCompensationPercentDivisor() external view returns (uint256);
    function getMinNetDebt() external view returns (uint256);
    function getBorrowingFeeFloor() external view returns (uint256);
    function isDepositAllowed(address _asset) external view returns (bool);
    function getAssets() external view returns (address[] memory);
    function feeCollector() external view returns (address);
    function getDeploymentStartTime() external view returns (uint256);

    function setMCR(uint256 _mcr) external;
    function setLSDCGasCompensation(uint256 _gasCompensation) external;
    function setColGasCompensationPercentDivisor(uint256 _colGasCompensationPercentDivisor) external;
    function setMinNetDebt(uint256 _minNetDebt) external;
    function setBorrowingFeeFloor(uint256 _borrowingFeeFloor) external;
    function setDepositAllowed(address _asset, bool _allowed) external;
    function addAsset(address _asset, bool _depositsEnabled) external;
    function setFeeCollector(address _feeCollector) external;
}
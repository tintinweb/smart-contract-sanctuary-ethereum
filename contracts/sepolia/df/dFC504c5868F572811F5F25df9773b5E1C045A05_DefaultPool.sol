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
library SafeMath {
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

pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import './Interfaces/IDefaultPool.sol';
import "./Dependencies/CheckContract.sol";
import "./Dependencies/console.sol";
import "./Dependencies/IERC20.sol";
import "./Dependencies/LucidityMath.sol";

/*
 * The Default Pool holds the ETH and LSDC debt (but not LSDC tokens) from liquidations that have been redistributed
 * to active clips but not yet "applied", i.e. not yet recorded on a recipient active clip's struct.
 *
 * When a clip makes an operation that applies its pending ETH and LSDC debt, its pending ETH and LSDC debt is moved
 * from the Default Pool to the Active Pool.
 */
contract DefaultPool is OwnableUpgradeable, CheckContract, IDefaultPool {
    using SafeMathUpgradeable for uint256;

    string constant public NAME = "DefaultPool";

    address constant ETH_REF_ADDRESS = address(0);

    address public clipManagerAddress;
    address public activePoolAddress;
    mapping(address => uint256) internal ETH;
    mapping(address => uint256) internal LSDCDebt;

    // --- Dependency setters ---

    function setAddresses(
        address _clipManagerAddress,
        address _activePoolAddress
    )
        external
        virtual
        initializer
    {
        checkContract(_clipManagerAddress);
        checkContract(_activePoolAddress);

        __Ownable_init();

        clipManagerAddress = _clipManagerAddress;
        activePoolAddress = _activePoolAddress;

        emit ClipManagerAddressChanged(_clipManagerAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);
    }

    // --- Getters for public variables. Required by IPool interface ---

    /*
    * Returns the ETH state variable.
    *
    * Not necessarily equal to the the contract's raw ETH balance - ether can be forcibly sent to contracts.
    */
    function getETH(address _asset) external view override returns (uint256) {
        return ETH[_asset];
    }

    function getLSDCDebt(address _asset) external view override returns (uint256) {
        return LSDCDebt[_asset];
    }

    // --- Pool functionality ---

    function sendETHToActivePool(address _asset, uint256 _amount) external override {
        _requireCallerIsClipManager();
        address activePool = activePoolAddress; // cache to save an SLOAD
        ETH[_asset] = ETH[_asset].sub(_amount);
        emit DefaultPoolETHBalanceUpdated(_asset, ETH[_asset]);
        emit EtherSent(_asset, activePool, _amount);

        if (_asset != ETH_REF_ADDRESS) {
            bool success = IERC20(_asset).transfer(activePool, LucidityMath.decimalsCorrection(_asset, _amount));
            require(success, "ActivePool: ERC20 transfer failed");
            IDeposit(activePool).receivedERC20(_asset, _amount);
        } else {
            (bool success, ) = activePool.call{ value: _amount }("");
            require(success, "DefaultPool: sending ETH failed");
        }
    }

    function increaseLSDCDebt(address _asset, uint256 _amount) external override {
        _requireCallerIsClipManager();
        LSDCDebt[_asset] = LSDCDebt[_asset].add(_amount);
        emit DefaultPoolLSDCDebtUpdated(_asset, LSDCDebt[_asset]);
    }

    function decreaseLSDCDebt(address _asset, uint256 _amount) external override {
        _requireCallerIsClipManager();
        LSDCDebt[_asset] = LSDCDebt[_asset].sub(_amount);
        emit DefaultPoolLSDCDebtUpdated(_asset, LSDCDebt[_asset]);
    }

    // --- 'require' functions ---

    function _requireCallerIsActivePool() internal view {
        require(msg.sender == activePoolAddress, "DefaultPool: Caller is not the ActivePool");
    }

    function _requireCallerIsClipManager() internal view {
        require(msg.sender == clipManagerAddress, "DefaultPool: Caller is not the ClipManager");
    }

    // --- Fallback function ---

    function receivedERC20(address _asset, uint256 _amount) external override {
        _requireCallerIsActivePool();
        ETH[_asset] = ETH[_asset].add(_amount);
        emit DefaultPoolETHBalanceUpdated(_asset, ETH[_asset]);
    }

    receive() external payable {
        _requireCallerIsActivePool();
        ETH[ETH_REF_ADDRESS] = ETH[ETH_REF_ADDRESS].add(msg.value);
        emit DefaultPoolETHBalanceUpdated(ETH_REF_ADDRESS, ETH[ETH_REF_ADDRESS]);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;


contract CheckContract {
    /**
     * Check that the account is an already deployed non-destroyed contract.
     * See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L12
     */
    function checkContract(address _account) internal view {
        require(_account != address(0), "Account cannot be zero address");

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(_account) }
        require(size > 0, "Account code size cannot be zero");
    }
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

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import "./IERC20.sol";
import "./console.sol";

library LucidityMath {
    using SafeMath for uint;

    uint256 internal constant DECIMAL_PRECISION = 1e18;

    /* Precision for Nominal ICR (independent of price). Rationale for the value:
     *
     * - Making it “too high” could lead to overflows.
     * - Making it “too low” could lead to an ICR equal to zero, due to truncation from Solidity floor division.
     *
     * This value of 1e20 is chosen for safety: the NICR will only overflow for numerator > ~1e39 ETH,
     * and will only truncate to 0 if the denominator is at least 1e20 times greater than the numerator.
     *
     */
    uint256 internal constant NICR_PRECISION = 1e20;

    function _min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a < _b) ? _a : _b;
    }

    function _max(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a >= _b) ? _a : _b;
    }

    /*
    * Multiply two decimal numbers and use normal rounding rules:
    * -round product up if 19'th mantissa digit >= 5
    * -round product down if 19'th mantissa digit < 5
    *
    * Used only inside the exponentiation, _decPow().
    */
    function decMul(uint256 x, uint256 y) internal pure returns (uint256 decProd) {
        uint256 prod_xy = x.mul(y);

        decProd = prod_xy.add(DECIMAL_PRECISION / 2).div(DECIMAL_PRECISION);
    }

    /*
    * _decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
    *
    * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity.
    *
    * Called by one function that represents time in units of minutes:
    * 1) ClipManager._calcDecayedBaseRate
    *
    * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
    * "minutes in 1000 years": 60 * 24 * 365 * 1000
    *
    * If a period of > 1000 years is ever used as an exponent in either of the above functions, the result will be
    * negligibly different from just passing the cap, since:
    *
    * In function 1), the decayed base rate will be 0 for 1000 years or > 1000 years
    * In function 2), the difference in tokens issued at 1000 years and any time > 1000 years, will be negligible
    */
    function _decPow(uint256 _base, uint256 _minutes) internal pure returns (uint256) {

        if (_minutes > 525600000) {_minutes = 525600000;}  // cap to avoid overflow

        if (_minutes == 0) {return DECIMAL_PRECISION;}

        uint256 y = DECIMAL_PRECISION;
        uint256 x = _base;
        uint256 n = _minutes;

        // Exponentiation-by-squaring
        while (n > 1) {
            if (n % 2 == 0) {
                x = decMul(x, x);
                n = n.div(2);
            } else { // if (n % 2 != 0)
                y = decMul(x, y);
                x = decMul(x, x);
                n = (n.sub(1)).div(2);
            }
        }

        return decMul(x, y);
  }

    function _getAbsoluteDifference(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return (_a >= _b) ? _a.sub(_b) : _b.sub(_a);
    }

    function _computeNominalCR(uint256 _coll, uint256 _debt) internal pure returns (uint256) {
        if (_debt > 0) {
            return _coll.mul(NICR_PRECISION).div(_debt);
        }
        // Return the maximal value for uint256 if the Clip has a debt of 0. Represents "infinite" CR.
        else { // if (_debt == 0)
            return 2**256 - 1;
        }
    }

    function _computeCR(uint256 _coll, uint256 _debt, uint256 _price) internal pure returns (uint256) {
        if (_debt > 0) {
            uint256 newCollRatio = _coll.mul(_price).div(_debt);

            return newCollRatio;
        }
        // Return the maximal value for uint256 if the Clip has a debt of 0. Represents "infinite" CR.
        else { // if (_debt == 0)
            return 2**256 - 1;
        }
    }

    //_amount is in ether (1e18) and we want to convert it to the token decimal
    function decimalsCorrection(address _token, uint256 _amount)
    internal
    view
    returns (uint256)
    {
        if (_token == address(0)) return _amount;
        if (_amount == 0) return 0;

        uint8 decimals = IERC20(_token).decimals();

        if (decimals < 18) {
            return _amount.div(10**(18 - decimals));
        } else if(decimals > 18) {
            return _amount.mul(10**(decimals - 18));
        }

        return _amount;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./IPool.sol";


interface IDefaultPool is IPool {
    // --- Events ---
    event ClipManagerAddressChanged(address _newClipManagerAddress);
    event DefaultPoolLSDCDebtUpdated(address _asset, uint256 _LSDCDebt);
    event DefaultPoolETHBalanceUpdated(address _asset, uint256 _ETH);

    // --- Functions ---
    function sendETHToActivePool(address _asset, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IDeposit {
    function receivedERC20(address _asset, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./IDeposit.sol";

// Common interface for the Pools.
interface IPool is IDeposit {

    // --- Events ---

    event ETHBalanceUpdated(uint256 _newBalance);
    event LSDCBalanceUpdated(uint256 _newBalance);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
    event EtherSent(address _asset, address _to, uint256 _amount);

    // --- Functions ---

    function getETH(address _asset) external view returns (uint256);

    function getLSDCDebt(address _asset) external view returns (uint256);

    function increaseLSDCDebt(address _asset, uint256 _amount) external;

    function decreaseLSDCDebt(address _asset, uint256 _amount) external;
}
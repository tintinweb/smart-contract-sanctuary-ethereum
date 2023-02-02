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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/Gameable.sol";
import "./interfaces/Userable.sol";
import "./interfaces/IUserManager.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

abstract contract GameBase is
    Gameable,
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    Game[] public games;
    Tier[] public tiers;

    mapping(uint256 => uint256[]) public gamesOfTokenID;
    mapping(TierType => uint256) public currentTiers;

    uint256 public tokenIDBotA;
    uint256 public tokenIDBotB;
    uint256 public lastGameLaunched;
    Userable public userManager;

    mapping(uint256 => mapping(uint256 => NumberChosen)) public playersOf;

    modifier claimable(uint256 tokenID, uint256 gameID) {
        require(gameID > 0, "The game not start");
        Game memory game = games[gameID];
        require(_gameIsOver(game), "The game is not over");
        require(game.winner == tokenID, "The token is not the winner");
        require(game.pool > 0, "token id has claim the price");
        _;
    }

    event PlayGame(
        uint256 indexed gameID,
        uint256 indexed tokenID,
        TierType category
    );
    event NewGame(
        uint256 indexed gameID,
        uint256 indexed tokenID,
        TierType category
    );

    function initialize() public initializer {
        __Ownable_init();
        __Pausable_init();
        Tier memory tier0 = Tier({
            category: TierType.SOUL,
            duration: 5 minutes,
            amount: 1 ether,
            maxPlayer: 0,
            createdAt: block.timestamp,
            updatedAt: block.timestamp,
            isActive: true
        });
        Tier memory tier1 = Tier({
            category: TierType.MUTANT,
            duration: 5 minutes,
            amount: 3 ether,
            maxPlayer: 0,
            createdAt: block.timestamp,
            updatedAt: block.timestamp,
            isActive: true
        });
        Tier memory tier2 = Tier({
            category: TierType.BORED,
            duration: 5 minutes,
            amount: 10 ether,
            maxPlayer: 0,
            createdAt: block.timestamp,
            updatedAt: block.timestamp,
            isActive: true
        });
        tiers.push(tier0);
        tiers.push(tier1);
        tiers.push(tier2);
        tokenIDBotA = 0;
        tokenIDBotB = 1000000;
        _init();
    }

    function _init() internal virtual {}

    function getGame(
        uint256 gameID
    ) public view virtual override returns (Game memory) {
        require(gameID > 0, "Gameable: The game not exist");
        return games[gameID];
    }

    function getTier(
        TierType category
    ) public view virtual override returns (Tier memory) {
        for (uint256 i; i < tiers.length; i++) {
            Tier memory tier = tiers[i];
            if (tier.category == category) {
                return tier;
            }
        }
        revert("Not found");
    }

    function setTier(Tier memory tier) external virtual onlyOwner {
        int256 indexOf = -1;
        for (uint256 i; i < tiers.length; i++) {
            if (tiers[i].category == tier.category) {
                indexOf = int256(i);
            }
        }
        if (indexOf >= 0) {
            Tier storage storedTier = tiers[uint256(indexOf)];
            storedTier.duration = tier.duration;
            storedTier.amount = tier.amount;
            storedTier.maxPlayer = tier.maxPlayer;
            storedTier.isActive = tier.isActive;
            storedTier.updatedAt = block.timestamp;
        }
    }

    function setTokenIDBot(uint256 botA, uint256 botB) external onlyOwner {
        tokenIDBotA = botA;
        tokenIDBotB = botB;
    }

    function _gameIsOver(
        Game memory game
    ) internal view virtual returns (bool) {
        return block.timestamp >= game.endedAt;
    }

    function _tokenIDExistsIn(
        uint256 gameID,
        uint256 tokenID
    ) internal view returns (bool) {
        for (uint i = 0; i < games[gameID].playersInGame; i++) {
            if (playersOf[gameID][i].tokenID == tokenID) {
                return true;
            }
        }
        return false;
    }

    function getGamesOf(
        uint256 tokenID
    ) external view override returns (Game[] memory) {
        uint256[] memory gameIds = gamesOfTokenID[tokenID];
        Game[] memory gamesOf = new Game[](gameIds.length);
        for (uint256 i; i < gameIds.length; i++) {
            gamesOf[i] = games[gameIds[i]];
        }
        return gamesOf;
    }

    function getPlayersInGame(
        uint256 gameID
    ) public view virtual returns (Player[] memory) {
        Player[] memory players = new Player[](games[gameID].playersInGame);
        for (uint256 i = 0; i < games[gameID].playersInGame; i++) {
            NumberChosen memory nbChosen = playersOf[gameID][i];
            Userable.UserDescription
                memory userDescriptor = _getUserDescription(nbChosen.tokenID);
            players[i] = Player({
                tokenID: nbChosen.tokenID,
                name: userDescriptor.name,
                categoryPlayer: uint256(userDescriptor.category),
                initialBalance: userDescriptor.initialBalance,
                currentBalance: userDescriptor.balance,
                createdAt: nbChosen.createdAt,
                number: nbChosen.number
            });
        }
        return players;
    }

    function sizeGameOf(
        uint256 tokenID
    ) external view virtual returns (uint256) {
        return gamesOfTokenID[tokenID].length;
    }

    function sizeGames() external view virtual returns (uint256) {
        return games.length;
    }

    function setUserManager(address newUserManager) external virtual onlyOwner {
        userManager = Userable(newUserManager);
    }

    function claimPrice(
        uint256 tokenID,
        uint256 gameID
    ) public virtual claimable(tokenID, gameID) {
        Game storage game = games[gameID];
        userManager.credit(tokenID, game.pool);
        game.pool = 0;
        game.updatedAt = block.timestamp;
    }

    function claimAllPrice() external virtual {
        address currentAddress = msg.sender;
        uint256 balance = IERC721Enumerable(address(userManager)).balanceOf(
            currentAddress
        );
        if (balance > 0) {
            for (uint256 i = 0; i < balance; i++) {
                uint256 tokenID = IERC721Enumerable(address(userManager))
                    .tokenOfOwnerByIndex(currentAddress, i);
                uint256[] memory gameIDs = gamesOfTokenID[tokenID];
                for (uint256 j = 0; j < gameIDs.length; j++) {
                    uint256 gameID = gameIDs[j];
                    if (
                        _gameIsOver(games[gameID]) &&
                        games[gameID].pool > 0 &&
                        games[gameID].winner == tokenID
                    ) {
                        claimPrice(tokenID, gameID);
                    }
                }
            }
        }
    }

    function getTiers() external view returns (Tier[] memory) {
        return tiers;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function getActivePlayersBy(
        TierType categroy
    ) external view returns (Player[] memory) {
        Player[] memory players;
        if (currentTiers[categroy] <= 0) {
            return players;
        }
        uint256 gameId = currentTiers[categroy];
        if (_gameIsOver(games[gameId])) {
            return players;
        }
        return getPlayersInGame(gameId);
    }

    function getCurrentGame(
        TierType categroy
    )
        external
        view
        returns (
            uint256 gameID,
            uint256 pool,
            uint256 startedAt,
            Player[] memory players
        )
    {
        gameID = currentTiers[categroy];
        if (gameID > 0) {
            Game memory game = getGame(gameID);
            pool = game.pool;
            startedAt = game.startedAt;
            players = getPlayersInGame(gameID);
        }
    }

    function getGameResult(
        uint256 gameID
    )
        external
        view
        virtual
        returns (uint256 winner, uint256[] memory numbers, uint256 pool)
    {
        if (gameID > 0) {
            Game memory game = games[gameID];
            numbers = new uint256[](game.playersInGame);
            pool = game.pool;
            for (uint i = 0; i < numbers.length; i++) {
                numbers[i] = playersOf[gameID][i].number;
            }
            winner = game.winner;
        }
    }

    function _getUserDescription(
        uint256 tokenID
    ) internal view virtual returns (Userable.UserDescription memory) {
        if (tokenID != tokenIDBotA && tokenID != tokenIDBotB) {
            return userManager.getUserDescription(tokenID);
        }
        Userable.UserDescription memory userDescriptor;
        userDescriptor.name = "The Reapers";
        userDescriptor.initialBalance = 0;
        userDescriptor.balance = 0;
        userDescriptor.category = IUserManager.AprType.BORED;
        return userDescriptor;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./libraries/Random.sol";
import "./GameBase.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract GameManager is GameBase {
    using SafeMathUpgradeable for uint256;

    uint256 nonce;

    function _init() internal override {
        nonce = Random.numberChosen(0, 100, 0);
    }

    function play(
        TierType category,
        uint256 tokenID,
        uint8 numberChosen
    ) external virtual override whenNotPaused returns (uint256) {
        require(
            address(userManager) != address(0),
            "GameManager: missing implementation"
        );
        require(
            numberChosen >= 0 && numberChosen <= 100,
            "GameManager: the number must be between 0 and 100"
        );
        Tier memory tier = getTier(category);
        uint256 balance = userManager.balanceOfTokenID(tokenID);
        require(balance >= tier.amount, "The tokenID not enough credit");
        userManager.debit(tokenID, tier.amount);
        uint256 lastTier = currentTiers[category];
        uint256 gameID;
        if (lastTier <= 0) {
            NumberChosen[] memory numbersChosen = _getNumbersChosen(
                tokenID,
                numberChosen,
                balance
            );
            gameID = _firstGame(numbersChosen, tier, category);
            emit NewGame(gameID, tokenID, category);
        } else {
            Game storage currentGame = games[lastTier];
            if (block.timestamp < currentGame.endedAt) {
                gameID = lastTier;
                if (!_existsPlayer(tokenID, gameID)) {
                    _currentGame(
                        currentGame,
                        tier,
                        gameID,
                        NumberChosen({
                            tokenID: tokenID,
                            number: numberChosen,
                            balanceBeforeGame: balance,
                            createdAt: block.timestamp
                        })
                    );
                } else {
                    revert("The tokenID has already played");
                }
            } else {
                NumberChosen[] memory numbersChosen = _getNumbersChosen(
                    tokenID,
                    numberChosen,
                    balance
                );
                gameID = _newGame(numbersChosen, category, tier);
                emit NewGame(gameID, tokenID, category);
            }
        }
        userManager.updateUserGame(tokenID, gameID);
        currentTiers[category] = gameID;
        gamesOfTokenID[tokenID].push(gameID);
        emit PlayGame(gameID, tokenID, category);
        return gameID;
    }

    function getGamesEndedBetweenIntervalOf(
        uint256 tokenID,
        uint256 startInterval,
        uint256 endInterval
    ) external view override returns (UserGame[] memory) {
        UserGame[] memory userGame;
        if (games.length <= 0) {
            return userGame;
        }
        if (games.length - 1 == 1) {
            uint256 gameID = 1;
            Game memory g = games[gameID];
            if (
                _tokenIDExistsIn(1, tokenID) &&
                g.endedAt >= startInterval &&
                g.endedAt <= endInterval &&
                _gameIsOver(g)
            ) {
                userGame = new UserGame[](1);
                userGame[0].gameID = gameID;
                userGame[0].category = g.category;
                userGame[0].isWinner = g.winner == tokenID;
                for (uint256 i = 0; i < g.playersInGame; i++) {
                    if (playersOf[gameID][i].tokenID == tokenID) {
                        userGame[0].balanceBeforeGame = playersOf[gameID][i]
                            .balanceBeforeGame;
                    }
                }
            }
            return userGame;
        }
        uint256 amountGameOverAndBetweenInterval = 0;
        for (uint i = 0; i < gamesOfTokenID[tokenID].length; i++) {
            Game memory g = games[gamesOfTokenID[tokenID][i]];
            if (
                g.endedAt <= startInterval &&
                g.endedAt <= endInterval &&
                _gameIsOver(g)
            ) {
                amountGameOverAndBetweenInterval++;
            }
        }
        userGame = new UserGame[](amountGameOverAndBetweenInterval);
        for (uint i = 0; i < gamesOfTokenID[tokenID].length; i++) {
            uint256 gameID = gamesOfTokenID[tokenID][i];
            Game memory g = games[gameID];
            if (
                g.endedAt <= startInterval &&
                g.endedAt <= endInterval &&
                _gameIsOver(g)
            ) {
                userGame[i].gameID = gameID;
                userGame[i].category = g.category;
                userGame[i].isWinner = g.winner == tokenID;
                for (uint256 j = 0; j < g.playersInGame; j++) {
                    if (playersOf[gameID][j].tokenID == tokenID) {
                        userGame[i].balanceBeforeGame = playersOf[gameID][j]
                            .balanceBeforeGame;
                    }
                }
            }
        }
        return userGame;
    }

    function _getNumbersChosen(
        uint256 tokenID,
        uint8 numberChosen,
        uint256 balance
    ) internal virtual returns (NumberChosen[] memory) {
        NumberChosen memory botA = NumberChosen({
            tokenID: tokenIDBotA,
            number: Random.numberChosen(0, 100, nonce),
            balanceBeforeGame: 0,
            createdAt: block.timestamp
        });
        nonce++;
        NumberChosen memory botB = NumberChosen({
            tokenID: tokenIDBotB,
            number: Random.numberChosen(0, 100, nonce),
            balanceBeforeGame: 0,
            createdAt: block.timestamp
        });
        nonce++;
        NumberChosen memory player = NumberChosen({
            tokenID: tokenID,
            number: numberChosen,
            balanceBeforeGame: balance,
            createdAt: block.timestamp
        });
        NumberChosen[] memory numbersChosen = new NumberChosen[](3);
        numbersChosen[0] = botA;
        numbersChosen[1] = botB;
        numbersChosen[2] = player;
        return numbersChosen;
    }

    function _computeTarget(
        uint256 gameID,
        uint256 size
    ) internal view virtual returns (uint256) {
        uint256 sum;
        uint256 percent = 80;
        for (uint256 i; i < size; i++) {
            sum += playersOf[gameID][i].number;
        }
        return sum.div(size).mul(percent).div(100);
    }

    function _getWinner(
        uint256 gameID,
        uint256 size,
        uint256 target
    ) internal view virtual returns (NumberChosen memory) {
        NumberChosen memory winner;
        uint256 closestDiff = type(uint256).max;
        for (uint256 i = 0; i < size; i++) {
            NumberChosen memory numberSelected = playersOf[gameID][i];
            uint256 diff = target > numberSelected.number
                ? target - numberSelected.number
                : numberSelected.number - target;
            if (diff < closestDiff) {
                winner = numberSelected;
                closestDiff = diff;
            }
        }
        return winner;
    }

    function _getNumberChosenOf(
        uint256 tokenID,
        NumberChosen[] memory players
    ) internal view virtual returns (NumberChosen memory) {
        for (uint256 i; i < players.length; i++) {
            if (tokenID == players[i].tokenID) {
                return players[i];
            }
        }
        revert("Not found");
    }

    function _existsPlayer(
        uint256 tokenID,
        uint256 gameID
    ) internal view virtual returns (bool) {
        for (uint i = 0; i < games[gameID].playersInGame; i++) {
            if (playersOf[gameID][i].tokenID == tokenID) {
                return true;
            }
        }
        return false;
    }

    function _firstGame(
        NumberChosen[] memory numbersChosen,
        Tier memory tier,
        TierType category
    ) internal returns (uint256) {
        uint256 sizeGame = games.length;
        uint256 gameID;
        Game memory game = Game({
            id: 0,
            winner: 0,
            playersInGame: numbersChosen.length,
            startedAt: block.timestamp,
            endedAt: block.timestamp + tier.duration,
            updatedAt: block.timestamp,
            category: category,
            pool: tier.amount.mul(numbersChosen.length)
        });
        if (sizeGame <= 0) {
            games.push();
            games.push(game);
            gameID = 1;
        } else {
            gameID = games.length;
            games.push(game);
        }
        lastGameLaunched = block.timestamp;
        for (uint256 i = 0; i < numbersChosen.length; i++) {
            playersOf[gameID][i] = numbersChosen[i];
        }
        uint256 target = _computeTarget(gameID, numbersChosen.length);
        games[gameID].winner = _getWinner(gameID, numbersChosen.length, target).tokenID;
        games[gameID].id = gameID;
        return gameID;
    }

    function _currentGame(
        Game storage game,
        Tier memory tier,
        uint256 gameID,
        NumberChosen memory newPlayer
    ) internal virtual {
        uint256 newSize = game.playersInGame + 1;
        playersOf[gameID][0].number = Random.numberChosen(0, 100, nonce);
        nonce++;
        playersOf[gameID][1].number = Random.numberChosen(0, 100, nonce);
        nonce++;
        playersOf[gameID][game.playersInGame] = newPlayer;
        uint256 target = _computeTarget(gameID, newSize);
        NumberChosen memory winner = _getWinner(gameID, newSize, target);
        game.winner = winner.tokenID;
        game.playersInGame = newSize;
        game.updatedAt = block.timestamp;
        game.pool = tier.amount.mul(newSize);
    }

    function _newGame(
        NumberChosen[] memory numbersChosen,
        TierType category,
        Tier memory tier
    ) internal returns (uint256) {
        uint256 gameID = games.length;
        Game memory game = Game({
            id: gameID,
            winner: 0,
            playersInGame: numbersChosen.length,
            startedAt: block.timestamp,
            endedAt: block.timestamp + tier.duration,
            updatedAt: block.timestamp,
            category: category,
            pool: tier.amount.mul(numbersChosen.length)
        });
        lastGameLaunched = block.timestamp;
        games.push(game);
         for (uint256 i = 0; i < numbersChosen.length; i++) {
            playersOf[gameID][i] = numbersChosen[i];
        }
        uint256 target = _computeTarget(gameID, numbersChosen.length);
        games[gameID].winner = _getWinner(gameID, numbersChosen.length, target).tokenID;
        return gameID;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface Gameable {
    enum TierType {
        BORED,
        MUTANT,
        SOUL
    }

    struct NumberChosen {
        uint256 tokenID;
        uint256 number;
        uint256 balanceBeforeGame;
        uint256 createdAt;
    }

    struct UserGame {
        uint256 gameID;
        uint256 balanceBeforeGame;
        TierType category;
        bool isWinner;
    }

    struct Player {
        uint256 tokenID;
        string name;
        uint256 categoryPlayer;
        uint256 initialBalance;
        uint256 currentBalance;
        uint256 createdAt;
        uint256 number;
    }

    struct Game {
        uint256 id;
        uint256 winner;
        uint256 playersInGame;
        uint256 startedAt;
        uint256 endedAt;
        uint256 updatedAt;
        uint256 pool;
        TierType category;
    }

    struct Tier {
        TierType category;
        uint256 duration;
        uint256 amount;
        uint8 maxPlayer;
        uint256 createdAt;
        uint256 updatedAt;
        bool isActive;
    }

    function getGame(uint256 idGame) external returns (Game memory);

    function play(
        TierType category,
        uint256 tokenID,
        uint8 numberChosen
    ) external returns (uint256);

    function getGamesOf(uint256 tokenID) external returns (Game[] memory);

    function getGamesEndedBetweenIntervalOf(
        uint256 tokenID,
        uint256 startInterval,
        uint256 endInterval
    ) external view returns (UserGame[] memory);

    function getTier(TierType category) external view returns (Tier memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUserManager {
    enum AprType {
        BORED,
        MUTANT,
        SOUL
    }
    
    event Created(
        address indexed userAdrr,
        uint256 indexed tokenId,
        AprType category,
        uint256 amount,
        uint256 createdAt
    );

    struct UserGame {
        uint256 id;
        uint256 rewardT0;
        uint256 rewardT1;
        uint256 totalReward;
        uint256 tokenBalance;
        uint256[3] gameIds;
        uint256 date;
        uint256 lastClaimTime;
    }

    struct User {
        uint256 balance;
        uint256 initialBalance;
        AprType category;
        string name;
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct UserDescription {
        uint256 userId;
        uint256 balance;
        uint256 apr;
        uint256 initialBalance;
        string name;
        AprType category;
    }
    
    function getUserDescription(
        uint256 tokenId
    ) external view returns (UserDescription memory userDescription);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IUserManager.sol";

interface Userable is IUserManager {
    struct BaseApr {
        uint256 apr;
        uint256 priceMin;
        uint256 priceMax;
    }

    function balanceOfTokenID(uint256 tokenID) external returns (uint256);

    function credit(uint256 tokenID, uint256 amount) external;

    function debit(uint256 tokenID, uint256 amount) external;

    function updateUserGame(
        uint256 tokenID,
        uint256 gameID
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Random {
    function numberChosen(
        uint256 min,
        uint256 max,
        uint256 nonce
    ) internal view returns (uint256) {
        uint256 amount = uint(
            keccak256(
                abi.encodePacked(block.timestamp + nonce, msg.sender, block.number)
            )
        ) % (max - min);
        amount = amount + min;
        return amount;
    }
}
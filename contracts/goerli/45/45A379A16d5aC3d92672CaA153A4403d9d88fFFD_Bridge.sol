// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
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

// SPDX-License-Identifier: Alt-Research-License-1.0
// Copyright Alt Research Ltd. 2023. All rights reserved.
//
// You acknowledge and agree that Alt Research Ltd. ("Alt Research") (or Alt
// Research's licensors) own all legal rights, titles and interests in and to the
// work, software, application, source code, documentation and any other documents

pragma solidity ^0.8.0;

import "./BridgeBase.sol";
import "./interfaces/IGetRollupInfo.sol";
import "../rollup/interfaces/IInitiateRollup.sol";
import "../rollup/interfaces/IFinalizeRollup.sol";

contract Bridge is BridgeBase, IInitiateRollup {
    event InitiateRollup(
        uint64 destDomainID,
        bytes32 resourceID,
        uint64 nonce,
        uint64 batchSize,
        uint256 startBlock,
        bytes32 stateChangeHash
    );
    event FinalizeRollup(
        uint64 originDomainID,
        bytes32 resourceID,
        uint64 nonce,
        uint64 batchIndex,
        uint64 totalBatches
    );

    constructor(
        uint64 domainID,
        address[] memory initialRelayers,
        uint256 initialRelayerThreshold,
        uint256 expiry
    ) BridgeBase(domainID, initialRelayers, initialRelayerThreshold, expiry) {}

    /// @notice Initiates rollup.
    ///
    /// @notice Requirements:
    /// - Bridge must not be paused.
    /// - Handler must be registered with {resourceID}.
    /// - {_msgSender()} must be registered token address.
    ///
    /// @notice Emits {InitiateRollup} event which is handled by relayer.
    function initiateRollup(
        uint64 destDomainID,
        bytes32 resourceID,
        uint64 batchSize,
        uint256 startBlock,
        bytes32 stateChangeHash
    )
        external
        override
        whenNotPaused
        onlyValidResourceID(resourceID)
        onlyAllowedOutbound(resourceID)
    {
        address tokenAddress = IERCHandler(
            _resourceIDToHandlerAddress[resourceID]
        )._resourceIDToTokenContractAddress(resourceID);
        require(tokenAddress == _msgSender(), "invalid token address");

        uint64 nonce = ++_depositCounts[destDomainID];

        emit InitiateRollup(
            destDomainID,
            resourceID,
            nonce,
            batchSize,
            startBlock,
            stateChangeHash
        );
    }

    /// @notice Finalizes rollup.
    ///
    /// @notice Requirements:
    /// - Handler must be registered with {resourceID}.
    ///
    /// @dev It can be called by anyone.
    function finalizeRollup(
        uint64 originDomainID,
        bytes32 resourceID,
        uint64 nonce,
        bytes calldata data,
        bytes32[] calldata proof
    ) external whenNotPaused onlyValidResourceID(resourceID) {
        (
            address l1TargetAddress,
            bytes32 rootHash,
            uint64 totalBatches
        ) = IGetRollupInfo(_resourceIDToHandlerAddress[resourceID])
                .getRollupInfo(originDomainID, resourceID, nonce);

        IFinalizeRollup(l1TargetAddress).finalizeRollup(
            originDomainID,
            resourceID,
            nonce,
            proof,
            rootHash,
            data
        );

        uint64 batchIndex = abi.decode(data, (uint64));

        // slither-disable-next-line reentrancy-events
        emit FinalizeRollup(
            originDomainID,
            resourceID,
            nonce,
            batchIndex,
            totalBatches
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev This module is supposed to be used in Bridge.
///
/// This is adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/access/AccessControl.sol
/// The only difference is added getRoleMemberIndex(bytes32 role, address account) function.

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

abstract contract BridgeAccessControl is ContextUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    ///  @notice Emitted when `account` is granted `role`.
    ///
    /// `sender` is the account that originated the contract call, an admin role
    /// bearer except when using {_setupRole}.
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /// @notice Emitted when `account` is revoked `role`.
    ///
    /// `sender` is the account that originated the contract call:
    ///   - if using `revokeRole`, it is the admin role bearer
    ///   - if using `renounceRole`, it is the role bearer (i.e. `account`)
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /// @notice Returns `true` if `account` has been granted `role`.
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /// @notice Returns the number of accounts that have `role`. Can be used
    /// together with {getRoleMember} to enumerate all bearers of a role.
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /// @notice Returns one of the accounts that have `role`. `index` must be a
    /// value between 0 and {getRoleMemberCount}, non-inclusive.
    ///
    /// Role bearers are not sorted in any particular way, and their ordering may
    /// change at any point.
    ///
    /// WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
    /// you perform all queries on the same block. See the following
    /// https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
    /// for more information.
    // slither-disable-next-line external-function
    function getRoleMember(bytes32 role, uint256 index)
        public
        view
        returns (address)
    {
        return _roles[role].members.at(index);
    }

    /// @notice Returns the index of the account that have `role`.
    function getRoleMemberIndex(bytes32 role, address account)
        public
        view
        returns (uint256)
    {
        return
            _roles[role].members._inner._indexes[
                bytes32(uint256(uint160(account)))
            ];
    }

    /// @notice Returns the admin role that controls `role`. See {grantRole} and
    /// {revokeRole}.
    ///
    /// To change a role's admin, use {_setRoleAdmin}.
    // slither-disable-next-line external-function
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /// @notice Grants `role` to `account`.
    ///
    /// If `account` had not been already granted `role`, emits a {RoleGranted}
    /// event.
    ///
    /// @notice Requirements:
    /// - the caller must have ``role``'s admin role.
    function grantRole(bytes32 role, address account) public virtual {
        // solhint-disable-next-line reason-string
        require(
            hasRole(_roles[role].adminRole, _msgSender()),
            "AccessControl: sender must be an admin to grant"
        );

        _grantRole(role, account);
    }

    /// @notice Revokes `role` from `account`.
    ///
    /// If `account` had been granted `role`, emits a {RoleRevoked} event.
    ///
    /// @notice Requirements:
    /// - the caller must have ``role``'s admin role.
    function revokeRole(bytes32 role, address account) public virtual {
        // solhint-disable-next-line reason-string
        require(
            hasRole(_roles[role].adminRole, _msgSender()),
            "AccessControl: sender must be an admin to revoke"
        );

        _revokeRole(role, account);
    }

    /// @notice Revokes `role` from the calling account.
    ///
    /// Roles are often managed via {grantRole} and {revokeRole}: this function's
    /// purpose is to provide a mechanism for accounts to lose their privileges
    /// if they are compromised (such as when a trusted device is misplaced).
    ///
    /// If the calling account had been granted `role`, emits a {RoleRevoked}
    /// event.
    ///
    /// @notice Requirements:
    /// - the caller must be `account`.
    function renounceRole(bytes32 role, address account) public virtual {
        // solhint-disable-next-line reason-string
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

        _revokeRole(role, account);
    }

    /// @notice Grants `role` to `account`.
    ///
    /// If `account` had not been already granted `role`, emits a {RoleGranted}
    /// event. Note that unlike {grantRole}, this function doesn't perform any
    /// checks on the calling account.
    ///
    /// WARNING: This function should only be called from the constructor when setting
    /// up the initial roles for the system.
    ///
    /// Using this function in any other way is effectively circumventing the admin
    /// system imposed by {AccessControl}.
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /// @notice Sets `adminRole` as ``role``'s admin role.
    // slither-disable-next-line dead-code
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "./BridgeAccessControl.sol";
import "./interfaces/IERCHandler.sol";
import "./interfaces/IDepositExecute.sol";
import "./interfaces/IDepositNative.sol";
import "./interfaces/IFeeHandler.sol";

/// @notice This contract facilitates the following:
/// - deposits
/// - creation and voting of deposit proposals
/// - deposit executions

contract BridgeBase is PausableUpgradeable, BridgeAccessControl {
    using SafeCastUpgradeable for *;

    /// @notice Limit relayers number because proposal can fit only so much votes
    uint256 public constant MAX_RELAYERS = 200;

    uint64 public immutable _domainID;
    uint8 public _relayerThreshold;
    // slither-disable-next-line immutable-states
    uint40 public _expiry;

    IFeeHandler public _feeHandler;

    enum ProposalStatus {
        Inactive,
        Active,
        Passed,
        Executed,
        Cancelled
    }

    struct Proposal {
        ProposalStatus _status;
        uint200 _yesVotes; // bitmap, 200 maximum votes
        uint8 _yesVotesTotal;
        uint40 _proposedBlock; // 1099511627775 maximum block
    }

    // destinationDomainID => number of deposits
    mapping(uint64 => uint64) public _depositCounts;

    // resourceID => handler address
    mapping(bytes32 => address) public _resourceIDToHandlerAddress;

    // resourceID => allowed outbound
    mapping(bytes32 => bool) public allowedOutbounds;

    // forwarder address => is trusted
    mapping(address => bool) public trustedForwarders;

    // destinationDomainID + depositNonce => dataHash => Proposal
    mapping(uint128 => mapping(bytes32 => Proposal)) private _proposals;

    event FeeHandlerChanged(address newFeeHandler);
    event RelayerThresholdChanged(uint256 newThreshold);
    event RelayerAdded(address relayer);
    event RelayerRemoved(address relayer);
    event Deposit(
        uint64 destinationDomainID,
        bytes32 resourceID,
        uint64 depositNonce,
        address indexed user,
        bytes data,
        bytes handlerResponse
    );
    event ProposalEvent(
        uint64 originDomainID,
        bytes32 resourceID,
        uint64 depositNonce,
        ProposalStatus status,
        bytes32 dataHash
    );
    event ProposalVote(
        uint64 originDomainID,
        uint64 depositNonce,
        ProposalStatus status,
        bytes32 dataHash
    );
    event FailedHandlerExecution(bytes lowLevelData);

    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

    modifier onlyDefaultAdmin() {
        _onlyAdmin();
        _;
    }

    modifier onlyAdminOrRelayer() {
        _onlyAdminOrRelayer();
        _;
    }

    modifier onlyRelayers() {
        _onlyRelayers();
        _;
    }

    modifier onlyValidResourceID(bytes32 resourceID) {
        require(
            _resourceIDToHandlerAddress[resourceID] != address(0),
            "resourceID not mapped to handler"
        );
        _;
    }

    modifier onlyAllowedOutbound(bytes32 resourceID) {
        require(allowedOutbounds[resourceID], "Outbound forbidden");
        _;
    }

    /// @notice Initializes Bridge, creates and grants {_msgSender()} the admin role,
    /// creates and grants {initialRelayers} the relayer role.
    ///
    /// @param domainID ID of chain the Bridge contract exists on.
    /// @param initialRelayers Addresses that should be initially granted the relayer role.
    /// @param initialRelayerThreshold Number of votes needed for a deposit proposal to be considered passed.
    constructor(
        uint64 domainID,
        address[] memory initialRelayers,
        uint256 initialRelayerThreshold,
        uint256 expiry
    ) {
        _domainID = domainID;
        _relayerThreshold = initialRelayerThreshold.toUint8();
        _expiry = expiry.toUint40();

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        for (uint256 i = 0; i < initialRelayers.length; i++) {
            grantRole(RELAYER_ROLE, initialRelayers[i]);
        }
    }

    /// @notice Removes admin role from {_msgSender()} and grants it to {newAdmin}.
    ///
    /// @notice Requirements:
    /// - It must be called by only admin.
    ///
    /// @param newAdmin Address that admin role will be granted to.
    function renounceAdmin(address newAdmin) external onlyDefaultAdmin {
        require(_msgSender() != newAdmin, "Cannot renounce oneself");
        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        renounceRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @notice Pauses deposits, proposal creation and voting, and deposit executions.
    ///
    /// @notice Requirements:
    /// - It must be called by only admin.
    function adminPauseTransfers() external onlyDefaultAdmin {
        _pause();
    }

    /// @notice Unpauses deposits, proposal creation and voting, and deposit executions.
    ///
    /// @notice Requirements:
    /// - It must be called by only admin.
    function adminUnpauseTransfers() external onlyDefaultAdmin {
        _unpause();
    }

    /// @notice Modifies the number of votes required for a proposal to be considered passed.
    ///
    /// @notice Requirements:
    /// - It must be called by only admin.
    ///
    /// @param newThreshold Value {_relayerThreshold} will be changed to.
    ///
    /// @notice Emits {RelayerThresholdChanged} event.
    function adminChangeRelayerThreshold(uint256 newThreshold)
        external
        onlyDefaultAdmin
    {
        _relayerThreshold = newThreshold.toUint8();
        emit RelayerThresholdChanged(newThreshold);
    }

    /// @notice Grants {relayerAddress} the relayer role.
    ///
    /// @notice Requirements:
    /// - It must be called by only admin.
    /// - {relayerAddress} must not already has relayer role.
    /// - The number of current relayer must be less than {MAX_RELAYERS}
    ///
    /// @param relayerAddress Address of relayer to be added.
    ///
    /// @notice Emits {RelayerAdded} event.
    ///
    /// @dev admin role is checked in grantRole()
    function adminAddRelayer(address relayerAddress) external {
        require(
            !hasRole(RELAYER_ROLE, relayerAddress),
            "addr already has relayer role!"
        );
        require(_totalRelayers() < MAX_RELAYERS, "relayers limit reached");
        grantRole(RELAYER_ROLE, relayerAddress);
        emit RelayerAdded(relayerAddress);
    }

    /// @notice Removes relayer role for {relayerAddress}.
    ///
    /// @notice Requirements:
    /// - It must be called by only admin.
    /// - {relayerAddress} must has relayer role.
    ///
    /// @param relayerAddress Address of relayer to be removed.
    ///
    /// @notice Emits {RelayerRemoved} event.
    ///
    /// @dev admin role is checked in revokeRole()
    function adminRemoveRelayer(address relayerAddress) external {
        require(
            hasRole(RELAYER_ROLE, relayerAddress),
            "addr doesn't have relayer role!"
        );
        revokeRole(RELAYER_ROLE, relayerAddress);
        emit RelayerRemoved(relayerAddress);
    }

    /// @notice Sets a new resource for handler contracts that use the IERCHandler interface,
    /// and maps the {handlerAddress} to {resourceID} in {_resourceIDToHandlerAddress}.
    ///
    /// @notice Requirements:
    /// - It must be called by only admin.
    ///
    /// @param handlerAddress Address of handler resource will be set for.
    /// @param resourceID ResourceID to be used when making deposits.
    /// @param tokenAddress Address of contract to be called when a deposit is made and a deposited is executed.
    function adminSetResource(
        address handlerAddress,
        bytes32 resourceID,
        address tokenAddress,
        bool allowed
    ) external onlyDefaultAdmin {
        _resourceIDToHandlerAddress[resourceID] = handlerAddress;
        allowedOutbounds[resourceID] = allowed;
        IERCHandler handler = IERCHandler(handlerAddress);
        handler.setResource(resourceID, tokenAddress);
    }

    /// @notice Sets a resource as burnable for handler contracts that use the IERCHandler interface.
    ///
    /// @notice Requirements:
    /// - It must be called by only admin.
    ///
    /// @param handlerAddress Address of handler resource will be set for.
    /// @param tokenAddress Address of contract to be called when a deposit is made and a deposited is executed.
    function adminSetBurnable(address handlerAddress, address tokenAddress)
        external
        onlyDefaultAdmin
    {
        IERCHandler handler = IERCHandler(handlerAddress);
        handler.setBurnable(tokenAddress);
    }

    /// @notice Sets the nonce for the specific domainID.
    ///
    /// @notice Requirements:
    /// - It must be called by only admin.
    /// - {nonce} must be greater than the current nonce.
    ///
    /// @param domainID Domain ID for increasing nonce.
    /// @param nonce The nonce value to be set.
    function adminSetDepositNonce(uint64 domainID, uint64 nonce)
        external
        onlyDefaultAdmin
    {
        // solhint-disable-next-line reason-string
        require(
            nonce > _depositCounts[domainID],
            "Does not allow decrements of the nonce"
        );
        _depositCounts[domainID] = nonce;
    }

    /// @notice Set a forwarder to be trusted.
    ///
    /// @notice Requirements:
    /// - It must be called by only admin.
    ///
    /// @param forwarder Forwarder address to be added.
    /// @param isTrusted if true, {forwarder} is trusted. Otherwise, it is no longer trusted.
    function adminSetForwarder(address forwarder, bool isTrusted)
        external
        onlyDefaultAdmin
    {
        trustedForwarders[forwarder] = isTrusted;
    }

    /// @notice Changes deposit fee handler contract address.
    ///
    /// @notice Requirements:
    /// - It must be called by only admin.
    ///
    /// @param newFeeHandler Address {_feeHandler} will be updated to.
    function adminChangeFeeHandler(address newFeeHandler)
        external
        onlyDefaultAdmin
    {
        _feeHandler = IFeeHandler(newFeeHandler);
        emit FeeHandlerChanged(newFeeHandler);
    }

    /// @notice Used to manually withdraw funds from ERC safes.
    ///
    /// @notice Requirements:
    /// - It must be called by only admin.
    ///
    /// @param handlerAddress Address of handler to withdraw from.
    /// @param data ABI-encoded withdrawal params relevant to the specified handler.
    function adminWithdraw(address handlerAddress, bytes memory data)
        external
        onlyDefaultAdmin
    {
        IERCHandler handler = IERCHandler(handlerAddress);
        handler.withdraw(data);
    }

    /// @notice Initiates a transfer using a specified handler contract.
    /// @notice Only callable when Bridge is not paused.
    /// @param destinationDomainID ID of chain deposit will be bridged to.
    /// @param resourceID ResourceID used to find address of handler to be used for deposit.
    /// @param depositData Additional data to be passed to specified handler.
    /// @notice Emits {Deposit} event with all necessary parameters and a handler response.
    function depositNative(
        uint64 destinationDomainID,
        bytes32 resourceID,
        bytes calldata depositData
    )
        external
        payable
        whenNotPaused
        onlyValidResourceID(resourceID)
        onlyAllowedOutbound(resourceID)
    {
        require(
            destinationDomainID != _domainID,
            "Can't deposit to current domain"
        );

        address sender = _msgSender();
        uint256 fee = 0;

        if (address(_feeHandler) != address(0)) {
            fee = _feeHandler.fee();

            // Reverts on failure
            // slither-disable-next-line arbitrary-send-eth,reentrancy-benign,reentrancy-events
            _feeHandler.collectFee{value: fee}(
                sender,
                _domainID,
                destinationDomainID,
                resourceID
            );
        }

        address handler = _resourceIDToHandlerAddress[resourceID];

        // slither-disable-next-line reentrancy-benign
        uint64 depositNonce = ++_depositCounts[destinationDomainID];

        IDepositNative depositHandler = IDepositNative(handler);
        bytes memory handlerResponse = depositHandler.depositNative{
            value: msg.value - fee
        }(resourceID, sender, depositData);

        emit Deposit(
            destinationDomainID,
            resourceID,
            depositNonce,
            sender,
            depositData,
            handlerResponse
        );
    }

    /// @notice Initiates a transfer using a specified handler contract.
    /// @notice Only callable when Bridge is not paused.
    /// @param destinationDomainID ID of chain deposit will be bridged to.
    /// @param resourceID ResourceID used to find address of handler to be used for deposit.
    /// @param depositData Additional data to be passed to specified handler.
    /// @notice Emits {Deposit} event with all necessary parameters and a handler response.
    /// - ERC20Handler: responds with an empty data.
    /// - ERC721Handler: responds with the deposited token metadata acquired by calling a tokenURI method in the token contract.
    /// - ERC1155Handler: responds with an empty data.
    function deposit(
        uint64 destinationDomainID,
        bytes32 resourceID,
        bytes calldata depositData
    )
        external
        payable
        whenNotPaused
        onlyValidResourceID(resourceID)
        onlyAllowedOutbound(resourceID)
    {
        require(
            destinationDomainID != _domainID,
            "Can't deposit to current domain"
        );

        address sender = _msgSender();
        if (address(_feeHandler) == address(0)) {
            require(msg.value == 0, "no FeeHandler, msg.value != 0");
        } else {
            // Reverts on failure
            _feeHandler.collectFee{value: msg.value}(
                sender,
                _domainID,
                destinationDomainID,
                resourceID
            );
        }

        address handler = _resourceIDToHandlerAddress[resourceID];

        // slither-disable-next-line reentrancy-benign
        uint64 depositNonce = ++_depositCounts[destinationDomainID];

        IDepositExecute depositHandler = IDepositExecute(handler);
        bytes memory handlerResponse = depositHandler.deposit(
            resourceID,
            sender,
            depositData
        );

        // slither-disable-next-line reentrancy-events
        emit Deposit(
            destinationDomainID,
            resourceID,
            depositNonce,
            sender,
            depositData,
            handlerResponse
        );
    }

    /// @notice When called, {_msgSender()} will be marked as voting in favor of proposal.
    ///
    /// @notice Requirements:
    /// - It must be called by only relayer.
    /// - Bridge must not be paused.
    /// - Handler must be registered with {resourceID}.
    /// - Proposal must not have already been passed or executed.
    /// - Relayer must vote only once.
    ///
    /// @param domainID ID of chain deposit originated from.
    /// @param depositNonce ID of deposited generated by origin Bridge contract.
    /// @param data Data originally provided when deposit was made.
    ///
    /// @notice Emits {ProposalEvent} event with status indicating the proposal status.
    /// @notice Emits {ProposalVote} event.
    function voteProposal(
        uint64 domainID,
        uint64 depositNonce,
        bytes32 resourceID,
        bytes calldata data
    ) external onlyRelayers whenNotPaused onlyValidResourceID(resourceID) {
        require(
            domainID != _domainID,
            "shouldn't originate from the current domain"
        );

        address handler = _resourceIDToHandlerAddress[resourceID];
        uint128 nonceAndID = (uint128(depositNonce) << 64) | uint128(domainID);
        bytes32 dataHash = keccak256(abi.encodePacked(handler, data));
        Proposal memory proposal = _proposals[nonceAndID][dataHash];

        if (proposal._status == ProposalStatus.Passed) {
            executeProposal(domainID, depositNonce, data, resourceID, true);
            return;
        }

        // Passed case is considered already
        // Now we can consider Inactive, Active cases
        // solhint-disable-next-line reason-string
        require(
            uint256(proposal._status) <= 1,
            "proposal already executed/cancelled"
        );
        require(!_hasVoted(proposal, _msgSender()), "relayer already voted");

        if (proposal._status == ProposalStatus.Inactive) {
            proposal = Proposal({
                _status: ProposalStatus.Active,
                _yesVotes: 0,
                _yesVotesTotal: 0,
                _proposedBlock: uint40(block.number) // Overflow is desired.
            });

            emit ProposalEvent(
                domainID,
                resourceID,
                depositNonce,
                ProposalStatus.Active,
                dataHash
            );
        } else if (uint40(block.number - proposal._proposedBlock) > _expiry) {
            // if the number of blocks that has passed since this proposal was
            // submitted exceeds the expiry threshold set, cancel the proposal
            proposal._status = ProposalStatus.Cancelled;

            emit ProposalEvent(
                domainID,
                resourceID,
                depositNonce,
                ProposalStatus.Cancelled,
                dataHash
            );
        }

        if (proposal._status != ProposalStatus.Cancelled) {
            proposal._yesVotes = (proposal._yesVotes |
                _relayerBit(_msgSender())).toUint200();
            proposal._yesVotesTotal++; // TODO: check if bit counting is cheaper.

            emit ProposalVote(
                domainID,
                depositNonce,
                proposal._status,
                dataHash
            );

            // Finalize if _relayerThreshold has been reached
            if (proposal._yesVotesTotal >= _relayerThreshold) {
                proposal._status = ProposalStatus.Passed;
                emit ProposalEvent(
                    domainID,
                    resourceID,
                    depositNonce,
                    ProposalStatus.Passed,
                    dataHash
                );
            }
        }
        _proposals[nonceAndID][dataHash] = proposal;

        // slither-disable-next-line incorrect-equality
        if (proposal._status == ProposalStatus.Passed) {
            executeProposal(domainID, depositNonce, data, resourceID, false);
        }
    }

    /// @notice Cancels a deposit proposal that has not been executed yet.
    ///
    /// @notice Requirements:
    /// - It must be called by only relayer or admin.
    /// - Bridge must not be paused.
    /// - Proposal must be past expiry threshold.
    ///
    /// @param domainID ID of chain deposit originated from.
    /// @param depositNonce ID of deposited generated by origin Bridge contract.
    /// @param dataHash Hash of data originally provided when deposit was made.
    ///
    /// @notice Emits {ProposalEvent} event with status {Cancelled}.
    function cancelProposal(
        uint64 domainID,
        bytes32 resourceID,
        uint64 depositNonce,
        bytes32 dataHash
    ) external onlyAdminOrRelayer {
        uint128 nonceAndID = (uint128(depositNonce) << 64) | uint128(domainID);
        Proposal memory proposal = _proposals[nonceAndID][dataHash];
        ProposalStatus currentStatus = proposal._status;

        require(
            currentStatus == ProposalStatus.Active ||
                currentStatus == ProposalStatus.Passed,
            "Proposal cannot be cancelled"
        );
        require(
            uint40(block.number - proposal._proposedBlock) > _expiry,
            "Proposal not at expiry threshold"
        );

        proposal._status = ProposalStatus.Cancelled;
        _proposals[nonceAndID][dataHash] = proposal;

        emit ProposalEvent(
            domainID,
            resourceID,
            depositNonce,
            ProposalStatus.Cancelled,
            dataHash
        );
    }

    /// @notice Returns a proposal.
    ///
    /// @param originDomainID Chain ID deposit originated from.
    /// @param depositNonce ID of proposal generated by proposal's origin Bridge contract.
    /// @param dataHash Hash of data to be provided when deposit proposal is executed.
    /// @return Proposal which consists of:
    /// - _dataHash Hash of data to be provided when deposit proposal is executed.
    /// - _yesVotes Number of votes in favor of proposal.
    /// - _noVotes Number of votes against proposal.
    /// - _status Current status of proposal.
    function getProposal(
        uint64 originDomainID,
        uint64 depositNonce,
        bytes32 dataHash
    ) external view returns (Proposal memory) {
        uint128 nonceAndID = (uint128(depositNonce) << 64) |
            uint128(originDomainID);
        return _proposals[nonceAndID][dataHash];
    }

    /// @notice Returns true if {relayer} has voted on {destNonce} {dataHash} proposal.
    ///
    /// @param destNonce destinationDomainID + depositNonce of the proposal.
    /// @param dataHash Hash of data to be provided when deposit proposal is executed.
    /// @param relayer Address to check.
    ///
    /// @dev Naming left unchanged for backward compatibility.
    function _hasVotedOnProposal(
        uint128 destNonce,
        bytes32 dataHash,
        address relayer
    ) external view returns (bool) {
        return _hasVoted(_proposals[destNonce][dataHash], relayer);
    }

    /// @notice Returns true if {relayer} has the relayer role.
    ///
    /// @param relayer Address to check.
    function isRelayer(address relayer) external view returns (bool) {
        return hasRole(RELAYER_ROLE, relayer);
    }

    /// @notice Executes a deposit proposal that is considered passed using a specified handler contract.
    ///
    /// @notice Requirements:
    /// - It must be called by only relayer.
    /// - Bridge must not be paused.
    /// - Proposal must have Passed status.
    /// - Hash of {data} must equal proposal's {dataHash}.
    ///
    /// @param domainID ID of chain deposit originated from.
    /// @param resourceID ResourceID to be used when making deposits.
    /// @param depositNonce ID of deposited generated by origin Bridge contract.
    /// @param data Data originally provided when deposit was made.
    /// @param revertOnFail Decision if the transaction should be reverted in case of handler's executeProposal is reverted or not.
    ///
    /// @notice Emits {ProposalEvent} event with status {Executed}.
    /// @notice Emits {FailedExecution} event with the failed reason.
    function executeProposal(
        uint64 domainID,
        uint64 depositNonce,
        bytes calldata data,
        bytes32 resourceID,
        bool revertOnFail
    ) public onlyRelayers whenNotPaused {
        address handler = _resourceIDToHandlerAddress[resourceID];
        uint128 nonceAndID = (uint128(depositNonce) << 64) | uint128(domainID);
        bytes32 dataHash = keccak256(abi.encodePacked(handler, data));
        Proposal storage proposal = _proposals[nonceAndID][dataHash];

        require(
            proposal._status == ProposalStatus.Passed,
            "Proposal must have Passed status"
        );

        proposal._status = ProposalStatus.Executed;
        IDepositExecute depositHandler = IDepositExecute(handler);

        if (revertOnFail) {
            depositHandler.executeProposal(resourceID, data);
        } else {
            try depositHandler.executeProposal(resourceID, data) {} catch (
                // slither-disable-next-line uninitialized-local,variable-scope
                bytes memory lowLevelData
            ) {
                // slither-disable-next-line reentrancy-no-eth
                proposal._status = ProposalStatus.Passed;
                // slither-disable-next-line reentrancy-events
                emit FailedHandlerExecution(lowLevelData);
                return;
            }
        }

        // slither-disable-next-line reentrancy-events
        emit ProposalEvent(
            domainID,
            resourceID,
            depositNonce,
            ProposalStatus.Executed,
            dataHash
        );
    }

    /// @notice Returns total relayers number.
    ///
    /// @dev Added for backwards compatibility.
    function _totalRelayers() public view returns (uint256) {
        return BridgeAccessControl.getRoleMemberCount(RELAYER_ROLE);
    }

    function _onlyAdminOrRelayer() private view {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) ||
                hasRole(RELAYER_ROLE, _msgSender()),
            "sender is not relayer or admin"
        );
    }

    function _onlyAdmin() private view {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "sender doesn't have admin role"
        );
    }

    function _onlyRelayers() private view {
        require(
            hasRole(RELAYER_ROLE, _msgSender()),
            "sender doesn't have relayer role"
        );
    }

    function _relayerBit(address relayer) private view returns (uint256) {
        return
            uint256(1) <<
            (BridgeAccessControl.getRoleMemberIndex(RELAYER_ROLE, relayer) - 1);
    }

    function _hasVoted(Proposal memory proposal, address relayer)
        private
        view
        returns (bool)
    {
        return (_relayerBit(relayer) & uint256(proposal._yesVotes)) > 0;
    }

    function _msgSender() internal view override returns (address) {
        address signer = msg.sender;
        if (msg.data.length >= 20 && trustedForwarders[signer]) {
            assembly {
                // Extract the Transaction Signer address from the last 20 bytes of the call data
                // and use that as the original sender of the transaction (instead of _msgSender())
                // Reference: https://eips.ethereum.org/EIPS/eip-2771
                signer := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        }
        return signer;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

interface IDepositExecute {
    /// @notice It is intended that deposit are made using the Bridge contract.
    /// @param resourceID ResourceID to be used.
    /// @param depositor Address of account making the deposit in the Bridge contract.
    /// @param data Consists of additional data needed for a specific deposit.
    function deposit(
        bytes32 resourceID,
        address depositor,
        bytes calldata data
    ) external returns (bytes memory);

    /// @notice It is intended that proposals are executed by the Bridge contract.
    /// @param resourceID ResourceID to be used.
    /// @param data Consists of additional data needed for a specific deposit execution.
    function executeProposal(bytes32 resourceID, bytes calldata data) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

interface IDepositNative {
    /// @notice It is intended that deposit are made using the Bridge contract.
    /// @param resourceID ResourceID to be used.
    /// @param depositor Address of account making the deposit in the Bridge contract.
    /// @param data Consists of additional data needed for a specific deposit.
    function depositNative(
        bytes32 resourceID,
        address depositor,
        bytes calldata data
    ) external payable returns (bytes memory);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

interface IERCHandler {
    /// @notice gets token contract address.
    /// @param resourceID resource ID that is mapped to the contract address.
    /// @return tokenContractAddress contract address that is mapped to the resource ID.
    function _resourceIDToTokenContractAddress(bytes32 resourceID)
        external
        view
        returns (address);

    /// @notice Correlates {resourceID} with {contractAddress}.
    /// @param resourceID ResourceID to be used when making deposits.
    /// @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
    function setResource(bytes32 resourceID, address contractAddress) external;

    /// @notice Marks {contractAddress} as mintable/burnable.
    /// @param contractAddress Address of contract to be used when making or executing deposits.
    function setBurnable(address contractAddress) external;

    /// @notice Withdraw funds from ERC safes.
    /// @param data ABI-encoded withdrawal params relevant to the handler.
    function withdraw(bytes memory data) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

interface IFeeHandler {
    /// @notice Collects fee for deposit.
    /// @param sender Sender of the deposit.
    /// @param fromDomainID ID of the source chain.
    /// @param destinationDomainID ID of chain deposit will be bridged to.
    /// @param resourceID ResourceID to be used when making deposits.
    function collectFee(
        address sender,
        uint64 fromDomainID,
        uint64 destinationDomainID,
        bytes32 resourceID
    ) external payable;

    /// @notice gets fee for deposit.
    function fee() external view returns (uint256);
}

// SPDX-License-Identifier: Alt-Research-License-1.0
// Copyright Alt Research Ltd. 2023. All rights reserved.
//
// You acknowledge and agree that Alt Research Ltd. ("Alt Research") (or Alt
// Research's licensors) own all legal rights, titles and interests in and to the
// work, software, application, source code, documentation and any other documents

pragma solidity ^0.8.0;

interface IGetRollupInfo {
    function getRollupInfo(
        uint64 originDomainID,
        bytes32 resourceID,
        uint64 nonce
    )
        external
        view
        returns (
            address,
            bytes32,
            uint64
        );
}

// SPDX-License-Identifier: Alt-Research-License-1.0
// Copyright Alt Research Ltd. 2023. All rights reserved.
//
// You acknowledge and agree that Alt Research Ltd. ("Alt Research") (or Alt
// Research's licensors) own all legal rights, titles and interests in and to the
// work, software, application, source code, documentation and any other documents

pragma solidity ^0.8.0;

interface IFinalizeRollup {
    function finalizeRollup(
        uint64 originDomainID,
        bytes32 resourceID,
        uint64 nonce,
        bytes32[] calldata proof,
        bytes32 rootHash,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: Alt-Research-License-1.0
// Copyright Alt Research Ltd. 2023. All rights reserved.
//
// You acknowledge and agree that Alt Research Ltd. ("Alt Research") (or Alt
// Research's licensors) own all legal rights, titles and interests in and to the
// work, software, application, source code, documentation and any other documents

pragma solidity ^0.8.0;

interface IInitiateRollup {
    function initiateRollup(
        uint64 destDomainID,
        bytes32 resourceID,
        uint64 batchSize,
        uint256 startBlock,
        bytes32 state
    ) external;
}
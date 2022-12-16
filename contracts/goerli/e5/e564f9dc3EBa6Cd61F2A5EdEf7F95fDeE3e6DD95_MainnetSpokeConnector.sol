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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

import {ProposedOwnableUpgradeable} from "../shared/ProposedOwnableUpgradeable.sol";
import {MerkleLib} from "./libraries/MerkleLib.sol";

/**
 * @title MerkleTreeManager
 * @notice Contains a Merkle tree instance and exposes read/write functions for the tree.
 * @dev On the hub domain there are two MerkleTreeManager contracts, one for the hub and one for the MainnetSpokeConnector.
 */
contract MerkleTreeManager is ProposedOwnableUpgradeable {
  // ========== Custom Errors ===========

  error MerkleTreeManager__setArborist_zeroAddress();
  error MerkleTreeManager__setArborist_alreadyArborist();

  // ============ Events ============

  event ArboristUpdated(address previous, address updated);

  event LeafInserted(bytes32 root, uint256 count, bytes32 leaf);

  event LeavesInserted(bytes32 root, uint256 count, bytes32[] leaves);

  // ============ Libraries ============

  using MerkleLib for MerkleLib.Tree;

  // ============ Public Storage ============

  /**
   * @notice Core data structure with which this contract is tasked with keeping custody.
   * Writable only by the designated arborist.
   */
  MerkleLib.Tree public tree;

  /**
   * @notice The arborist contract that has permission to write to this tree.
   * @dev This could be the root manager contract or a spoke connector contract, for example.
   */
  address public arborist;

  // ============ Modifiers ============

  modifier onlyArborist() {
    require(arborist == msg.sender, "!arborist");
    _;
  }

  // ============ Getters ============

  /**
   * @notice Returns the current branch.
   */
  function branch() public view returns (bytes32[32] memory) {
    return tree.branch;
  }

  /**
   * @notice Calculates and returns the current root.
   */
  function root() public view returns (bytes32) {
    return tree.root();
  }

  /**
   * @notice Returns the number of inserted leaves in the tree (current index).
   */
  function count() public view returns (uint256) {
    return tree.count;
  }

  /**
   * @notice Convenience getter: returns the root and count.
   */
  function rootAndCount() public view returns (bytes32, uint256) {
    return (tree.root(), tree.count);
  }

  // ======== Initializer =========

  function initialize(address _arborist) public initializer {
    __MerkleTreeManager_init(_arborist);
    __ProposedOwnable_init();
  }

  /**
   * @dev Initializes MerkleTreeManager instance. Sets the msg.sender as the initial permissioned
   */
  function __MerkleTreeManager_init(address _arborist) internal onlyInitializing {
    __MerkleTreeManager_init_unchained(_arborist);
  }

  function __MerkleTreeManager_init_unchained(address _arborist) internal onlyInitializing {
    arborist = _arborist;
  }

  // ============ Admin Functions ==============

  /**
   * @notice Method for the current arborist to assign write permissions to a new arborist.
   * @param newArborist The new address to set as the current arborist.
   */
  function setArborist(address newArborist) external onlyOwner {
    if (newArborist == address(0)) revert MerkleTreeManager__setArborist_zeroAddress();
    address current = arborist;
    if (current == newArborist) revert MerkleTreeManager__setArborist_alreadyArborist();

    // Emit updated event
    emit ArboristUpdated(current, newArborist);

    arborist = newArborist;
  }

  /**
   * @notice Remove ability to renounce ownership
   * @dev Renounce ownership should be impossible as long as there is a possibility the
   * arborist may change.
   */
  function renounceOwnership() public virtual override onlyOwner {}

  // ========= Public Functions =========

  /**
   * @notice Inserts the given leaves into the tree.
   * @param leaves The leaves to be inserted into the tree.
   * @return _root Current root for convenience.
   * @return _count Current node count (i.e. number of indices) AFTER the insertion of the new leaf,
   * provided for convenience.
   */
  function insert(bytes32[] memory leaves) public onlyArborist returns (bytes32 _root, uint256 _count) {
    // For > 1 leaf, considerably more efficient to put this tree into memory, conduct operations,
    // then re-assign it to storage - *especially* if we have multiple leaves to insert.
    MerkleLib.Tree memory _tree = tree;

    uint256 leafCount = leaves.length;
    for (uint256 i; i < leafCount; ) {
      // Insert the new node (using in-memory method).
      _tree = _tree.insert(leaves[i]);
      unchecked {
        ++i;
      }
    }
    // Write the newly updated tree to storage.
    tree = _tree;

    // Get return details for convenience.
    _count = _tree.count;
    // NOTE: Root calculation method currently reads from storage only.
    _root = tree.root();

    emit LeavesInserted(_root, _count, leaves);
  }

  /**
   * @notice Inserts the given leaf into the tree.
   * @param leaf The leaf to be inserted into the tree.
   * @return _root Current root for convenience.
   * @return _count Current node count (i.e. number of indices) AFTER the insertion of the new leaf,
   * provided for convenience.
   */
  function insert(bytes32 leaf) public onlyArborist returns (bytes32 _root, uint256 _count) {
    // Insert the new node.
    tree = tree.insert(leaf);
    _count = tree.count;
    _root = tree.root();

    emit LeafInserted(_root, _count, leaf);
  }

  // ============ Upgrade Gap ============
  uint256[48] private __GAP; // gap for upgrade safety
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

import {ProposedOwnable} from "../shared/ProposedOwnable.sol";
import {WatcherManager} from "./WatcherManager.sol";

/**
 * @notice This contract abstracts the functionality of the watcher manager.
 * Contracts can inherit this contract to be able to use the watcher manager's shared watcher set.
 */

contract WatcherClient is ProposedOwnable, Pausable {
  // ============ Events ============
  /**
   * @notice Emitted when the manager address changes
   * @param watcherManager The updated manager
   */
  event WatcherManagerChanged(address watcherManager);

  // ============ Properties ============
  /**
   * @notice The `WatcherManager` contract governs the watcher allowlist.
   * @dev Multiple clients can share a watcher set using the same manager
   */
  WatcherManager public watcherManager;

  // ============ Constructor ============
  constructor(address _watcherManager) ProposedOwnable() {
    watcherManager = WatcherManager(_watcherManager);
  }

  // ============ Modifiers ============
  /**
   * @notice Enforces the sender is the watcher
   */
  modifier onlyWatcher() {
    require(watcherManager.isWatcher(msg.sender), "!watcher");
    _;
  }

  // ============ Admin fns ============
  /**
   * @notice Owner can enroll a watcher (abilities are defined by inheriting contracts)
   */
  function setWatcherManager(address _watcherManager) external onlyOwner {
    require(_watcherManager != address(watcherManager), "already watcher manager");
    watcherManager = WatcherManager(_watcherManager);
    emit WatcherManagerChanged(_watcherManager);
  }

  /**
   * @notice Owner can unpause contracts if fraud is detected by watchers
   */
  function unpause() external onlyOwner whenPaused {
    _unpause();
  }

  /**
   * @notice Remove ability to renounce ownership
   * @dev Renounce ownership should be impossible as long as only the owner
   * is able to unpause the contracts. You can still propose `address(0)`,
   * but it will never be accepted.
   */
  function renounceOwnership() public virtual override onlyOwner {}

  // ============ Watcher fns ============

  /**
   * @notice Watchers can pause contracts if fraud is detected
   */
  function pause() external onlyWatcher whenNotPaused {
    _pause();
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

import {ProposedOwnable} from "../shared/ProposedOwnable.sol";

/**
 * @notice This contract manages a set of watchers. This is meant to be used as a shared resource that contracts can
 * inherit to make use of the same watcher set.
 */

contract WatcherManager is ProposedOwnable {
  // ============ Events ============
  event WatcherAdded(address watcher);

  event WatcherRemoved(address watcher);

  // ============ Properties ============
  mapping(address => bool) public isWatcher;

  // ============ Constructor ============
  constructor() ProposedOwnable() {
    _setOwner(msg.sender);
  }

  // ============ Modifiers ============

  // ============ Admin fns ============
  /**
   * @dev Owner can enroll a watcher (abilities are defined by inheriting contracts)
   */
  function addWatcher(address _watcher) external onlyOwner {
    require(!isWatcher[_watcher], "already watcher");
    isWatcher[_watcher] = true;
    emit WatcherAdded(_watcher);
  }

  /**
   * @dev Owner can unenroll a watcher (abilities are defined by inheriting contracts)
   */
  function removeWatcher(address _watcher) external onlyOwner {
    require(isWatcher[_watcher], "!exist");
    delete isWatcher[_watcher];
    emit WatcherRemoved(_watcher);
  }

  /**
   * @notice Remove ability to renounce ownership
   * @dev Renounce ownership should be impossible as long as the watcher griefing
   * vector exists. You can still propose `address(0)`, but it will never be accepted.
   */
  function renounceOwnership() public virtual override onlyOwner {}
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

import {ProposedOwnable} from "../../shared/ProposedOwnable.sol";
import {IConnector} from "../interfaces/IConnector.sol";

/**
 * @title Connector
 * @author Connext Labs, Inc.
 * @notice This contract has the messaging interface functions used by all connectors.
 *
 * @dev This contract stores information about mirror connectors, but can be used as a
 * base for contracts that do not have a mirror (i.e. the connector handling messaging on
 * mainnet). In this case, the `mirrorConnector` and `MIRROR_DOMAIN`
 * will be empty
 *
 * @dev If ownership is renounced, this contract will be unable to update its `mirrorConnector`
 * or `mirrorGas`
 */
abstract contract Connector is ProposedOwnable, IConnector {
  // ========== Custom Errors ===========

  error Connector__processMessage_notUsed();

  // ============ Events ============

  event NewConnector(
    uint32 indexed domain,
    uint32 indexed mirrorDomain,
    address amb,
    address rootManager,
    address mirrorConnector
  );

  event MirrorConnectorUpdated(address previous, address current);

  // ============ Public Storage ============

  /**
   * @notice The domain of this Messaging (i.e. Connector) contract.
   */
  uint32 public immutable DOMAIN;

  /**
   * @notice Address of the AMB on this domain.
   */
  address public immutable AMB;

  /**
   * @notice RootManager contract address.
   */
  address public immutable ROOT_MANAGER;

  /**
   * @notice The domain of the corresponding messaging (i.e. Connector) contract.
   */
  uint32 public immutable MIRROR_DOMAIN;

  /**
   * @notice Connector on L2 for L1 connectors, and vice versa.
   */
  address public mirrorConnector;

  // ============ Modifiers ============

  /**
   * @notice Errors if the msg.sender is not the registered AMB
   */
  modifier onlyAMB() {
    require(msg.sender == AMB, "!AMB");
    _;
  }

  /**
   * @notice Errors if the msg.sender is not the registered ROOT_MANAGER
   */
  modifier onlyRootManager() {
    // NOTE: RootManager will be zero address for spoke connectors.
    // Only root manager can dispatch a message to spokes/L2s via the hub connector.
    require(msg.sender == ROOT_MANAGER, "!rootManager");
    _;
  }

  // ============ Constructor ============

  /**
   * @notice Creates a new HubConnector instance
   * @dev The connectors are deployed such that there is one on each side of an AMB (i.e.
   * for optimism, there is one connector on optimism and one connector on mainnet)
   * @param _domain The domain this connector lives on
   * @param _mirrorDomain The spoke domain
   * @param _amb The address of the amb on the domain this connector lives on
   * @param _rootManager The address of the RootManager on mainnet
   * @param _mirrorConnector The address of the spoke connector
   */
  constructor(
    uint32 _domain,
    uint32 _mirrorDomain,
    address _amb,
    address _rootManager,
    address _mirrorConnector
  ) ProposedOwnable() {
    // set the owner
    _setOwner(msg.sender);

    // sanity checks on values
    require(_domain != 0, "empty domain");
    require(_rootManager != address(0), "empty rootManager");
    // see note at top of contract on why the mirror values are not sanity checked

    // set immutables
    DOMAIN = _domain;
    AMB = _amb;
    ROOT_MANAGER = _rootManager;
    MIRROR_DOMAIN = _mirrorDomain;
    // set mutables if defined
    if (_mirrorConnector != address(0)) {
      _setMirrorConnector(_mirrorConnector);
    }

    emit NewConnector(_domain, _mirrorDomain, _amb, _rootManager, _mirrorConnector);
  }

  // ============ Receivable ============
  /**
   * @notice Connectors may need to receive native asset to handle fees when sending a
   * message
   */
  receive() external payable {}

  // ============ Admin Functions ============

  /**
   * @notice Sets the address of the l2Connector for this domain
   */
  function setMirrorConnector(address _mirrorConnector) public onlyOwner {
    _setMirrorConnector(_mirrorConnector);
  }

  // ============ Public Functions ============

  /**
   * @notice Processes a message received by an AMB
   * @dev This is called by AMBs to process messages originating from mirror connector
   */
  function processMessage(bytes memory _data) external virtual onlyAMB {
    _processMessage(_data);
    emit MessageProcessed(_data, msg.sender);
  }

  /**
   * @notice Checks the cross domain sender for a given address
   */
  function verifySender(address _expected) external returns (bool) {
    return _verifySender(_expected);
  }

  // ============ Virtual Functions ============

  /**
   * @notice This function is used by the Connext contract on the l2 domain to send a message to the
   * l1 domain (i.e. called by Connext on optimism to send a message to mainnet with roots)
   * @param _data The contents of the message
   * @param _encodedData Data used to send the message; specific to connector
   */
  function _sendMessage(bytes memory _data, bytes memory _encodedData) internal virtual;

  /**
   * @notice This function is used by the AMBs to handle incoming messages. Should store the latest
   * root generated on the l2 domain.
   */
  function _processMessage(
    bytes memory /* _data */
  ) internal virtual {
    // By default, reverts. This is to ensure the call path is not used unless this function is
    // overridden by the inheriting class
    revert Connector__processMessage_notUsed();
  }

  /**
   * @notice Verify that the msg.sender is the correct AMB contract, and that the message's origin sender
   * is the expected address.
   * @dev Should be overridden by the implementing Connector contract.
   */
  function _verifySender(address _expected) internal virtual returns (bool);

  // ============ Private Functions ============

  function _setMirrorConnector(address _mirrorConnector) internal virtual {
    emit MirrorConnectorUpdated(mirrorConnector, _mirrorConnector);
    mirrorConnector = _mirrorConnector;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

import {IConnectorManager} from "../interfaces/IConnectorManager.sol";
import {IOutbox} from "../interfaces/IOutbox.sol";

/**
 * @notice This is an interface to allow the `Messaging` contract to be used
 * as a `XappConnectionManager` on all router contracts.
 *
 * @dev Each nomad router contract has a `XappConnectionClient`, which references a
 * XappConnectionManager to get the `Home` (outbox) and approved `Replica` (inbox)
 * instances. At any point the client can replace the manager it's pointing to,
 * changing the underlying messaging connection.
 */
abstract contract ConnectorManager is IConnectorManager {
  constructor() {}

  function home() public view returns (IOutbox) {
    return IOutbox(address(this));
  }

  function isReplica(address _potentialReplica) public view returns (bool) {
    return _potentialReplica == address(this);
  }

  function localDomain() external view virtual returns (uint32);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {TypedMemView} from "../../shared/libraries/TypedMemView.sol";
import {ExcessivelySafeCall} from "../../shared/libraries/ExcessivelySafeCall.sol";
import {TypeCasts} from "../../shared/libraries/TypeCasts.sol";

import {MerkleLib} from "../libraries/MerkleLib.sol";
import {Message} from "../libraries/Message.sol";
import {RateLimited} from "../libraries/RateLimited.sol";

import {MerkleTreeManager} from "../MerkleTreeManager.sol";
import {WatcherClient} from "../WatcherClient.sol";

import {Connector, ProposedOwnable} from "./Connector.sol";
import {ConnectorManager} from "./ConnectorManager.sol";

/**
 * @title SpokeConnector
 * @author Connext Labs, Inc.
 * @notice This contract implements the messaging functions needed on the spoke-side of a given AMB.
 * The SpokeConnector extends the HubConnector functionality by being able to send, store, and prove
 * messages.
 *
 * @dev If you are deploying this contract to mainnet, then the mirror values stored in the HubConnector
 * will be unused
 */
abstract contract SpokeConnector is Connector, ConnectorManager, WatcherClient, RateLimited, ReentrancyGuard {
  // ============ Libraries ============

  using MerkleLib for MerkleLib.Tree;
  using TypedMemView for bytes;
  using TypedMemView for bytes29;
  using Message for bytes29;

  // ============ Events ============

  event SenderAdded(address sender);

  event SenderRemoved(address sender);

  event AggregateRootReceived(bytes32 root);

  event AggregateRootRemoved(bytes32 root);

  event AggregateRootVerified(bytes32 indexed root);

  event Dispatch(bytes32 leaf, uint256 index, bytes32 root, bytes message);

  event Process(bytes32 leaf, bool success, bytes returnData);

  event DelayBlocksUpdated(uint256 indexed updated, address caller);

  /**
   * @notice Emitted when funds are withdrawn by the admin
   * @dev See comments in `withdrawFunds`
   * @param to The recipient of the funds
   * @param amount The amount withdrawn
   */
  event FundsWithdrawn(address indexed to, uint256 amount);

  event MessageProven(bytes32 indexed leaf, bytes32 indexed aggregateRoot, uint256 aggregateIndex);

  // ============ Structs ============

  // Status of Message:
  //   0 - None - message has not been proven or processed
  //   1 - Proven - message inclusion proof has been validated
  //   2 - Processed - message has been dispatched to recipient
  enum MessageStatus {
    None,
    Proven,
    Processed
  }

  /**
   * Struct for submitting a proof for a given message. Used in `proveAndProcess` below.
   * @param message Bytes of message to be processed. The hash of this message is considered the leaf.
   * @param proof Merkle proof of inclusion for given leaf.
   * @param index Index of leaf in home's merkle tree.
   */
  struct Proof {
    bytes message;
    bytes32[32] path;
    uint256 index;
  }

  // ============ Public Storage ============

  /**
   * @notice Number of blocks to delay the processing of a message to allow for watchers to verify
   * the validity and pause if necessary.
   */
  uint256 public delayBlocks;

  /**
   * @notice MerkleTreeManager contract instance. Will hold the active tree of message hashes, whose root
   * will be sent crosschain to the hub for aggregation and redistribution.
   */
  MerkleTreeManager public immutable MERKLE;

  /**
   * @notice Minimum gas for processing a received message (reserved for handle)
   */
  uint256 public immutable PROCESS_GAS;

  /**
   * @notice Reserved gas (to ensure tx completes in case message processing runs out)
   */
  uint256 public immutable RESERVE_GAS;

  /**
   * @notice This will hold the commit block for incoming aggregateRoots from the hub chain. Once
   * they are verified, (i.e. have surpassed the verification period in `delayBlocks`) they can
   * be used for proving inclusion of crosschain messages.
   *
   * @dev NOTE: A commit block of 0 should be considered invalid (it is an empty entry in the
   * mapping). We must ALWAYS ensure the value is not 0 before checking whether it has surpassed the
   * verification period.
   */
  mapping(bytes32 => uint256) public pendingAggregateRoots;

  /**
   * @notice This tracks the roots of the aggregate tree containing outbound roots from all other
   * supported domains. The current version is the one that is known to be past the delayBlocks
   * time period.
   * @dev This root is the root of the tree that is aggregated on mainnet (composed of all the roots
   * of previous trees).
   */
  mapping(bytes32 => bool) public provenAggregateRoots;

  /**
   * @notice This tracks whether the root has been proven to exist within the given aggregate root.
   * @dev Tracking this is an optimization so you dont have to prove inclusion of the same constituent
   * root many times.
   */
  mapping(bytes32 => bool) public provenMessageRoots;

  /**
   * @notice This mapping records all message roots that have already been sent in order to prevent
   * redundant message roots from being sent to hub.
   */
  mapping(bytes32 => bool) public sentMessageRoots;

  /**
   * @dev This is used for the `onlyAllowlistedSender` modifier, which gates who
   * can send messages using `dispatch`.
   */
  mapping(address => bool) public allowlistedSenders;

  /**
   * @notice domain => next available nonce for the domain.
   */
  mapping(uint32 => uint32) public nonces;

  /**
   * @notice Mapping of message leaves to MessageStatus, keyed on leaf.
   */
  mapping(bytes32 => MessageStatus) public messages;

  // ============ Modifiers ============

  modifier onlyAllowlistedSender() {
    require(allowlistedSenders[msg.sender], "!allowlisted");
    _;
  }

  // ============ Constructor ============

  /**
   * @notice Creates a new SpokeConnector instance.
   * @param _domain The domain this connector lives on.
   * @param _mirrorDomain The hub domain.
   * @param _amb The address of the AMB on the spoke domain this connector lives on.
   * @param _rootManager The address of the RootManager on the hub.
   * @param _mirrorConnector The address of the spoke connector.
   * @param _processGas The gas costs used in `handle` to ensure meaningful state changes can occur (minimum gas needed
   * to handle transaction).
   * @param _reserveGas The gas costs reserved when `handle` is called to ensure failures are handled.
   * @param _delayBlocks The delay for the validation period for incoming messages in blocks.
   * @param _merkle The address of the MerkleTreeManager on this spoke domain.
   * @param _watcherManager The address of the WatcherManager to whom this connector is a client.
   */
  constructor(
    uint32 _domain,
    uint32 _mirrorDomain,
    address _amb,
    address _rootManager,
    address _mirrorConnector,
    uint256 _processGas,
    uint256 _reserveGas,
    uint256 _delayBlocks,
    address _merkle,
    address _watcherManager
  )
    ConnectorManager()
    Connector(_domain, _mirrorDomain, _amb, _rootManager, _mirrorConnector)
    WatcherClient(_watcherManager)
  {
    // Sanity check: constants are reasonable.
    require(_processGas > 850_000 - 1, "!process gas");
    require(_reserveGas > 15_000 - 1, "!reserve gas");
    PROCESS_GAS = _processGas;
    RESERVE_GAS = _reserveGas;

    require(_merkle != address(0), "!zero merkle");
    MERKLE = MerkleTreeManager(_merkle);

    delayBlocks = _delayBlocks;
  }

  // ============ Admin Functions ============

  /**
   * @notice Adds a sender to the allowlist.
   * @dev Only allowlisted routers (senders) can call `dispatch`.
   */
  function addSender(address _sender) public onlyOwner {
    allowlistedSenders[_sender] = true;
    emit SenderAdded(_sender);
  }

  /**
   * @notice Removes a sender from the allowlist.
   * @dev Only allowlisted routers (senders) can call `dispatch`.
   */
  function removeSender(address _sender) public onlyOwner {
    delete allowlistedSenders[_sender];
    emit SenderRemoved(_sender);
  }

  /**
   * @notice Set the `delayBlocks`, the period in blocks over which an incoming message
   * is verified.
   */
  function setDelayBlocks(uint256 _delayBlocks) public onlyOwner {
    require(_delayBlocks != delayBlocks, "!delayBlocks");
    emit DelayBlocksUpdated(_delayBlocks, msg.sender);
    delayBlocks = _delayBlocks;
  }

  /**
   * @notice Set the rate limit (number of blocks) at which we can send messages from
   * this contract to the hub chain using the `send` method.
   * @dev Rate limit is used to mitigate DoS vectors. (See `RateLimited` for more info.)
   * @param _rateLimit The number of blocks require between sending messages. If set to
   * 0, rate limiting for this spoke connector will be disabled.
   */
  function setRateLimitBlocks(uint256 _rateLimit) public onlyOwner {
    _setRateLimitBlocks(_rateLimit);
  }

  /**
   * @notice Manually remove a pending aggregateRoot by owner if the contract is paused.
   * @dev This method is required for handling fraud cases in the current construction.
   * @param _fraudulentRoot Target fraudulent root that should be erased from the
   * `pendingAggregateRoots` mapping.
   */
  function removePendingAggregateRoot(bytes32 _fraudulentRoot) public onlyOwner whenPaused {
    // Sanity check: pending aggregate root exists.
    require(pendingAggregateRoots[_fraudulentRoot] != 0, "aggregateRoot !exists");
    delete pendingAggregateRoots[_fraudulentRoot];
    emit AggregateRootRemoved(_fraudulentRoot);
  }

  /**
   * @notice This function should be callable by owner, and send funds trapped on
   * a connector to the provided recipient.
   * @dev Withdraws the entire balance of the contract.
   *
   * @param _to The recipient of the funds withdrawn
   */
  function withdrawFunds(address _to) public onlyOwner {
    uint256 amount = address(this).balance;
    Address.sendValue(payable(_to), amount);
    emit FundsWithdrawn(_to, amount);
  }

  /**
   * @notice Remove ability to renounce ownership
   * @dev Renounce ownership should be impossible as long as it is impossible in the
   * WatcherClient, and as long as only the owner can remove pending roots in case of
   * fraud.
   */
  function renounceOwnership() public virtual override(ProposedOwnable, WatcherClient) onlyOwner {}

  // ============ Public Functions ============

  /**
   * @notice This returns the root of all messages with the origin domain as this domain (i.e.
   * all outbound messages)
   */
  function outboundRoot() external view returns (bytes32) {
    return MERKLE.root();
  }

  /**
   * @notice This provides the implementation for what is defined in the ConnectorManager
   * to avoid storing the domain redundantly
   */
  function localDomain() external view override returns (uint32) {
    return DOMAIN;
  }

  /**
   * @notice This returns the root of all messages with the origin domain as this domain (i.e.
   * all outbound messages)
   */
  function send(bytes memory _encodedData) external payable whenNotPaused rateLimited {
    bytes32 root = MERKLE.root();
    require(sentMessageRoots[root] == false, "root already sent");
    bytes memory _data = abi.encodePacked(root);
    _sendMessage(_data, _encodedData);
    sentMessageRoots[root] = true;
    emit MessageSent(_data, _encodedData, msg.sender);
  }

  /**
   * @notice This function adds transfers to the outbound transfer merkle tree.
   * @dev The root of this tree will eventually be dispatched to mainnet via `send`. On mainnet (the "hub"),
   * it will be combined into a single aggregate root by RootManager (along with outbound roots from other
   * chains). This aggregate root will be redistributed to all destination chains.
   *
   * NOTE: okay to leave dispatch operational when paused as pause is designed for crosschain interactions
   */
  function dispatch(
    uint32 _destinationDomain,
    bytes32 _recipientAddress,
    bytes memory _messageBody
  ) external onlyAllowlistedSender returns (bytes32, bytes memory) {
    // Get the next nonce for the destination domain, then increment it.
    uint32 _nonce = nonces[_destinationDomain]++;

    // Format the message into packed bytes.
    bytes memory _message = Message.formatMessage(
      DOMAIN,
      TypeCasts.addressToBytes32(msg.sender),
      _nonce,
      _destinationDomain,
      _recipientAddress,
      _messageBody
    );

    // Insert the hashed message into the Merkle tree.
    bytes32 _messageHash = keccak256(_message);

    // Returns the root calculated after insertion of message, needed for events for
    // watchers
    (bytes32 _root, uint256 _count) = MERKLE.insert(_messageHash);

    // Emit Dispatch event with message information.
    // NOTE: Current leaf index is count - 1 since new leaf has already been inserted.
    emit Dispatch(_messageHash, _count - 1, _root, _message);
    return (_messageHash, _message);
  }

  /**
   * @notice Must be able to call the `handle` function on the BridgeRouter contract. This is called
   * on the destination domain to handle incoming messages.
   *
   * Proving:
   * Calculates the expected inbound root from an origin chain given a leaf (message hash),
   * the index of the leaf, and the merkle proof of inclusion (path). Next, we check to ensure that this
   * calculated inbound root is included in the current aggregateRoot, given its index in the aggregator
   * tree and the proof of inclusion.
   *
   * Processing:
   * After all messages have been proven, we dispatch each message to Connext (BridgeRouter) for
   * execution.
   *
   * @dev Currently, ALL messages in a given batch must path to the same shared inboundRoot, meaning they
   * must all share an origin. See open TODO below for a potential solution to enable multi-origin batches.
   * @dev Intended to be called by the relayer at specific intervals during runtime.
   * @dev Will record a calculated root as having been proven if we've already proven that it was included
   * in the aggregateRoot.
   *
   * @param _proofs Batch of Proofs containing messages for proving/processing.
   * @param _aggregateRoot The target aggregate root we want to prove inclusion for. This root must have
   * already been delivered to this spoke connector contract and surpassed the validation period.
   * @param _aggregatePath Merkle path of inclusion for the inbound root.
   * @param _aggregateIndex Index of the inbound root in the aggregator's merkle tree in the hub.
   */
  function proveAndProcess(
    Proof[] calldata _proofs,
    bytes32 _aggregateRoot,
    bytes32[32] calldata _aggregatePath,
    uint256 _aggregateIndex
  ) external whenNotPaused nonReentrant {
    // Sanity check: proofs are included.
    require(_proofs.length > 0, "!proofs");

    // Optimization: calculate the inbound root for the first message in the batch and validate that
    // it's included in the aggregator tree. We can use this as a reference for every calculation
    // below to minimize storage access calls.
    bytes32 _messageHash = keccak256(_proofs[0].message);
    // TODO: Could use an array of sharedRoots so you can submit a message batch of messages with
    // different origins.
    bytes32 _messageRoot = calculateMessageRoot(_messageHash, _proofs[0].path, _proofs[0].index);

    // Handle proving this message root is included in the target aggregate root.
    proveMessageRoot(_messageRoot, _aggregateRoot, _aggregatePath, _aggregateIndex);
    // Assuming the inbound message root was proven, the first message is now considered proven.
    messages[_messageHash] = MessageStatus.Proven;

    // Now we handle proving all remaining messages in the batch - they should all share the same
    // inbound root!
    uint256 len = _proofs.length;
    for (uint32 i = 1; i < len; ) {
      _messageHash = keccak256(_proofs[i].message);
      bytes32 _calculatedRoot = calculateMessageRoot(_messageHash, _proofs[i].path, _proofs[i].index);
      // Make sure this root matches the validated inbound root.
      require(_calculatedRoot == _messageRoot, "!sharedRoot");
      // Message is proven!
      messages[_messageHash] = MessageStatus.Proven;

      unchecked {
        ++i;
      }
    }

    // All messages have been proven. We iterate separately here to process each message in the batch.
    // NOTE: Going through the proving phase for all messages in the batch BEFORE processing ensures
    // we hit reverts before we consume unbounded gas from `process` calls.
    for (uint32 i = 0; i < len; ) {
      process(_proofs[i].message);
      unchecked {
        ++i;
      }
    }
  }

  // ============ Private Functions ============

  /**
   * @notice This is either called by the Connector (AKA `this`) on the spoke (L2) chain after retrieving
   * latest `aggregateRoot` from the AMB (sourced from mainnet) OR called by the AMB directly.
   * @dev Must check the msg.sender on the origin chain to ensure only the root manager is passing
   * these roots.
   */
  function receiveAggregateRoot(bytes32 _newRoot) internal {
    require(_newRoot != bytes32(""), "new root empty");
    require(pendingAggregateRoots[_newRoot] == 0, "root already pending");
    require(!provenAggregateRoots[_newRoot], "root already proven");

    pendingAggregateRoots[_newRoot] = block.number;
    emit AggregateRootReceived(_newRoot);
  }

  /**
   * @notice Checks whether the given aggregate root has surpassed the verification period.
   * @dev Reverts if the given aggregate root is invalid (does not exist) OR has not surpassed
   * verification period.
   * @dev If the target aggregate root is pending and HAS surpassed the verification period, then we will
   * move it over to the proven mapping.
   * @param _aggregateRoot Target aggregate root to verify.
   */
  function verifyAggregateRoot(bytes32 _aggregateRoot) internal {
    // 0. Sanity check: root is not 0.
    require(_aggregateRoot != bytes32(""), "aggregateRoot empty");

    // 1. Check to see if the target *aggregate* root has already been proven.
    if (provenAggregateRoots[_aggregateRoot]) {
      return; // Short circuit if this root is proven.
    }

    // 2. The target aggregate root must be pending. Aggregate root commit block entry MUST exist.
    uint256 _aggregateRootCommitBlock = pendingAggregateRoots[_aggregateRoot];
    require(_aggregateRootCommitBlock != 0, "aggregateRoot !exist");

    // 3. Pending aggregate root has surpassed the `delayBlocks` verification period.
    require(block.number - _aggregateRootCommitBlock >= delayBlocks, "aggregateRoot !verified");

    // 4. The target aggregate root has surpassed verification period, we can move it over to the
    // proven mapping.
    provenAggregateRoots[_aggregateRoot] = true;
    emit AggregateRootVerified(_aggregateRoot);
    // May as well delete the pending aggregate root entry for the gas refund: it should no longer
    // be needed.
    delete pendingAggregateRoots[_aggregateRoot];
  }

  /**
   * @notice Checks whether a given message is valid. If so, calculates the expected inbound root from an
   * origin chain given a leaf (message hash), the index of the leaf, and the merkle proof of inclusion.
   * @dev Reverts if message's MessageStatus != None (i.e. if message was already proven or processed).
   *
   * @param _messageHash Leaf (message hash) that requires proving.
   * @param _messagePath Merkle path of inclusion for the leaf.
   * @param _messageIndex Index of leaf in the merkle tree on the origin chain of the message.
   * @return bytes32 Calculated root.
   **/
  function calculateMessageRoot(
    bytes32 _messageHash,
    bytes32[32] calldata _messagePath,
    uint256 _messageIndex
  ) internal view returns (bytes32) {
    // Ensure that the given message has not already been proven and processed.
    require(messages[_messageHash] == MessageStatus.None, "!MessageStatus.None");
    // Calculate the expected inbound root from the message origin based on the proof.
    // NOTE: Assuming a valid message was submitted with correct path/index, this should be an inbound root
    // that the hub has received. If the message were invalid, the root calculated here would not exist in the
    // aggregate root.
    return MerkleLib.branchRoot(_messageHash, _messagePath, _messageIndex);
  }

  /**
   * @notice Prove an inbound message root from another chain is included in the target aggregateRoot.
   * @param _messageRoot The message root we want to verify.
   * @param _aggregateRoot The target aggregate root we want to prove inclusion for. This root must have
   * already been delivered to this spoke connector contract and surpassed the validation period.
   * @param _aggregatePath Merkle path of inclusion for the inbound root.
   * @param _aggregateIndex Index of the inbound root in the aggregator's merkle tree in the hub.
   */
  function proveMessageRoot(
    bytes32 _messageRoot,
    bytes32 _aggregateRoot,
    bytes32[32] calldata _aggregatePath,
    uint256 _aggregateIndex
  ) internal {
    // 0. Check to see if the root for this batch has already been proven.
    if (provenMessageRoots[_messageRoot]) {
      // NOTE: It seems counter-intuitive, but we do NOT need to prove the given `_aggregateRoot` param
      // is valid IFF the `_messageRoot` has already been proven; we know that the `_messageRoot` has to
      // have been included in *some* proven aggregate root historically.
      return;
    }

    // 1. Ensure aggregate root has been proven.
    verifyAggregateRoot(_aggregateRoot);

    // 2. Calculate an aggregate root, given this inbound root (as leaf), path (proof), and index.
    bytes32 _calculatedAggregateRoot = MerkleLib.branchRoot(_messageRoot, _aggregatePath, _aggregateIndex);

    // 3. Check to make sure it matches the current aggregate root we have stored.
    require(_calculatedAggregateRoot == _aggregateRoot, "invalid inboundRoot");

    // This inbound root has been proven. We should specify that to optimize future calls.
    provenMessageRoots[_messageRoot] = true;
    emit MessageProven(_messageRoot, _aggregateRoot, _aggregateIndex);
  }

  /**
   * @notice Given formatted message, attempts to dispatch message payload to end recipient.
   * @dev Recipient must implement a `handle` method (refer to IMessageRecipient.sol)
   * Reverts if formatted message's destination domain is not the Replica's domain,
   * if message has not been proven,
   * or if not enough gas is provided for the dispatch transaction.
   * @param _message Formatted message
   * @return _success TRUE iff dispatch transaction succeeded
   */
  function process(bytes memory _message) internal returns (bool _success) {
    bytes29 _m = _message.ref(0);
    // ensure message was meant for this domain
    require(_m.destination() == DOMAIN, "!destination");
    // ensure message has been proven
    bytes32 _messageHash = _m.keccak();
    require(messages[_messageHash] == MessageStatus.Proven, "!proven");
    // check re-entrancy guard
    // require(entered == 1, "!reentrant");
    // entered = 0;
    // update message status as processed
    messages[_messageHash] = MessageStatus.Processed;
    // A call running out of gas TYPICALLY errors the whole tx. We want to
    // a) ensure the call has a sufficient amount of gas to make a
    //    meaningful state change.
    // b) ensure that if the subcall runs out of gas, that the tx as a whole
    //    does not revert (i.e. we still mark the message processed)
    // To do this, we require that we have enough gas to process
    // and still return. We then delegate only the minimum processing gas.
    require(gasleft() > PROCESS_GAS + RESERVE_GAS - 1, "!gas");
    // get the message recipient
    address _recipient = _m.recipientAddress();
    // set up for assembly call
    uint256 _gas = PROCESS_GAS;
    uint16 _maxCopy = 256;
    // allocate memory for returndata
    bytes memory _returnData = new bytes(_maxCopy);
    bytes memory _calldata = abi.encodeWithSignature(
      "handle(uint32,uint32,bytes32,bytes)",
      _m.origin(),
      _m.nonce(),
      _m.sender(),
      _m.body().clone()
    );

    (_success, _returnData) = ExcessivelySafeCall.excessivelySafeCall(_recipient, _gas, 0, _maxCopy, _calldata);

    // emit process results
    emit Process(_messageHash, _success, _returnData);
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

import {IRootManager} from "../../interfaces/IRootManager.sol";
import {IHubConnector} from "../../interfaces/IHubConnector.sol";

import {SpokeConnector} from "../SpokeConnector.sol";

contract MainnetSpokeConnector is SpokeConnector, IHubConnector {
  // ============ Constructor ============
  constructor(
    uint32 _domain,
    uint32 _mirrorDomain,
    address _amb,
    address _rootManager,
    address _mirrorConnector,
    uint256 _processGas,
    uint256 _reserveGas,
    uint256 _delayBlocks,
    address _merkle,
    address _watcherManager
  )
    SpokeConnector(
      _domain,
      _mirrorDomain,
      _amb,
      _rootManager,
      _mirrorConnector,
      _processGas,
      _reserveGas,
      _delayBlocks,
      _merkle,
      _watcherManager
    )
  {}

  // ============ Public fns ============
  /**
   * @notice Sends a message over the amb
   * @dev This is called by the root manager *only* on mainnet to propagate the aggregate root
   * @dev Get 'Base constructor arguments given twice' when trying to inherit
   */
  function sendMessage(bytes memory _data, bytes memory _encodedData) external payable onlyRootManager {
    // Should not include specialized calldata
    require(_encodedData.length == 0, "!data length");
    _sendMessage(_data, bytes(""));
    emit MessageSent(_data, bytes(""), msg.sender);
  }

  // ============ Private fns ============
  /**
   * @dev Asserts the sender of a cross domain message. On mainnet all senders should be this
   */
  function _verifySender(address _expected) internal view override returns (bool) {
    return msg.sender == _expected;
  }

  /**
   * @dev There are two times messages get "sent" from this connector:
   * 1. `RootManager` calls `sendMessage` during `propagate`
   * 2. Relayers call `send`, which calls `_sendMessage` to set the outbound root
   */
  function _sendMessage(bytes memory _data, bytes memory _encodedData) internal override {
    // Should not include specialized calldata
    require(_encodedData.length == 0, "!data length");
    // get the data (should be either the outbound or aggregate root, depending on sender)
    require(_data.length == 32, "!length");
    if (msg.sender == ROOT_MANAGER) {
      // update the aggregate root
      receiveAggregateRoot(bytes32(_data));
      return;
    }
    // otherwise is relayer, update the outbound root on the root manager
    IRootManager(ROOT_MANAGER).aggregate(DOMAIN, bytes32(_data));
  }

  /**
   * @dev The `RootManager` calls `.sendMessage` on all connectors, there is nothing on mainnet
   * that would be processing "inbound messages", so do nothing in this function
   */
  function _processMessage(bytes memory _data) internal override {}
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

import {IProposedOwnable} from "../../shared/interfaces/IProposedOwnable.sol";

/**
 * @notice This interface is what the Connext contract will send and receive messages through.
 * The messaging layer should conform to this interface, and should be interchangeable (i.e.
 * could be Nomad or a generic AMB under the hood).
 *
 * @dev This uses the nomad format to ensure nomad can be added in as it comes back online.
 *
 * Flow from transfer from polygon to optimism:
 * 1. User calls `xcall` with destination specified
 * 2. This will swap in to the bridge assets
 * 3. The swapped assets will get burned
 * 4. The Connext contract will call `dispatch` on the messaging contract to add the transfer
 *    to the root
 * 5. [At some time interval] Relayers call `send` to send the current root from polygon to
 *    mainnet. This is done on all "spoke" domains.
 * 6. [At some time interval] Relayers call `propagate` [better name] on mainnet, this generates a new merkle
 *    root from all of the AMBs
 *    - This function must be able to read root data from all AMBs and aggregate them into a single merkle
 *      tree root
 *    - Will send the mixed root from all chains back through the respective AMBs to all other chains
 * 7. AMB will call `update` to update the latest root on the messaging contract on spoke domains
 * 8. [At any point] Relayers can call `proveAndProcess` to prove inclusion of dispatched message, and call
 *    process on the `Connext` contract
 * 9. Takes minted bridge tokens and credits the LP
 *
 * AMB requirements:
 * - Access `msg.sender` both from mainnet -> spoke and vice versa
 * - Ability to read *our root* from the AMB
 *
 * AMBs:
 * - PoS bridge from polygon
 * - arbitrum bridge
 * - optimism bridge
 * - gnosis chain
 * - bsc (use multichain for messaging)
 */
interface IConnector is IProposedOwnable {
  // ============ Events ============
  /**
   * @notice Emitted whenever a message is successfully sent over an AMB
   * @param data The contents of the message
   * @param encodedData Data used to send the message; specific to connector
   * @param caller Who called the function (sent the message)
   */
  event MessageSent(bytes data, bytes encodedData, address caller);

  /**
   * @notice Emitted whenever a message is successfully received over an AMB
   * @param data The contents of the message
   * @param caller Who called the function
   */
  event MessageProcessed(bytes data, address caller);

  // ============ Public fns ============

  function processMessage(bytes memory _data) external;

  function verifySender(address _expected) external returns (bool);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

import {IOutbox} from "./IOutbox.sol";

/**
 * @notice Each router extends the `XAppConnectionClient` contract. This contract
 * allows an admin to call `setXAppConnectionManager` to update the underlying
 * pointers to the messaging inboxes (Replicas) and outboxes (Homes).
 *
 * @dev This interface only contains the functions needed for the `XAppConnectionClient`
 * will interface with.
 */
interface IConnectorManager {
  /**
   * @notice Get the local inbox contract from the xAppConnectionManager
   * @return The local inbox contract
   * @dev The local inbox contract is a SpokeConnector with AMBs, and a
   * Home contract with nomad
   */
  function home() external view returns (IOutbox);

  /**
   * @notice Determine whether _potentialReplica is an enrolled Replica from the xAppConnectionManager
   * @return True if _potentialReplica is an enrolled Replica
   */
  function isReplica(address _potentialReplica) external view returns (bool);

  /**
   * @notice Get the local domain from the xAppConnectionManager
   * @return The local domain
   */
  function localDomain() external view returns (uint32);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

import {IConnector} from "./IConnector.sol";

interface IHubConnector is IConnector {
  function sendMessage(bytes memory _data, bytes memory _encodedData) external payable;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

/**
 * @notice Interface for all contracts sending messages originating on their
 * current domain.
 *
 * @dev These are the Home.sol interface methods used by the `Router`
 * and exposed via `home()` on the `XAppConnectionClient`
 */
interface IOutbox {
  /**
   * @notice Emitted when a new message is added to an outbound message merkle root
   * @param leafIndex Index of message's leaf in merkle tree
   * @param destinationAndNonce Destination and destination-specific
   * nonce combined in single field ((destination << 32) & nonce)
   * @param messageHash Hash of message; the leaf inserted to the Merkle tree for the message
   * @param committedRoot the latest notarized root submitted in the last signed Update
   * @param message Raw bytes of message
   */
  event Dispatch(
    bytes32 indexed messageHash,
    uint256 indexed leafIndex,
    uint64 indexed destinationAndNonce,
    bytes32 committedRoot,
    bytes message
  );

  /**
   * @notice Dispatch the message it to the destination domain & recipient
   * @dev Format the message, insert its hash into Merkle tree,
   * enqueue the new Merkle root, and emit `Dispatch` event with message information.
   * @param _destinationDomain Domain of destination chain
   * @param _recipientAddress Address of recipient on destination chain as bytes32
   * @param _messageBody Raw bytes content of message
   * @return bytes32 The leaf added to the tree
   */
  function dispatch(
    uint32 _destinationDomain,
    bytes32 _recipientAddress,
    bytes memory _messageBody
  ) external returns (bytes32, bytes memory);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

interface IRootManager {
  /**
   * @notice This is called by relayers to generate + send the mixed root from mainnet via AMB to
   * spoke domains.
   * @dev This must read information for the root from the registered AMBs.
   */
  function propagate(
    address[] calldata _connectors,
    uint256[] calldata _fees,
    bytes[] memory _encodedData
  ) external payable;

  /**
   * @notice Called by the connectors for various domains on the hub to aggregate their latest
   * inbound root.
   * @dev This must read information for the root from the registered AMBs
   */
  function aggregate(uint32 _domain, bytes32 _outbound) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

/**
 * @title MerkleLib
 * @author Illusory Systems Inc.
 * @notice An incremental merkle tree modeled on the eth2 deposit contract.
 **/
library MerkleLib {
  // ========== Custom Errors ===========

  error MerkleLib__insert_treeIsFull();

  // ============ Constants =============

  uint256 internal constant TREE_DEPTH = 32;
  uint256 internal constant MAX_LEAVES = 2**TREE_DEPTH - 1;

  /**
   * @dev Z_i represent the hash values at different heights for a binary tree with leaf values equal to `0`.
   * (e.g. Z_1 is the keccak256 hash of (0x0, 0x0), Z_2 is the keccak256 hash of (Z_1, Z_1), etc...)
   * Z_0 is the bottom of the 33-layer tree, Z_32 is the top (i.e. root).
   * Used to shortcut calculation in root calculation methods below.
   */
  bytes32 internal constant Z_0 = hex"0000000000000000000000000000000000000000000000000000000000000000";
  bytes32 internal constant Z_1 = hex"ad3228b676f7d3cd4284a5443f17f1962b36e491b30a40b2405849e597ba5fb5";
  bytes32 internal constant Z_2 = hex"b4c11951957c6f8f642c4af61cd6b24640fec6dc7fc607ee8206a99e92410d30";
  bytes32 internal constant Z_3 = hex"21ddb9a356815c3fac1026b6dec5df3124afbadb485c9ba5a3e3398a04b7ba85";
  bytes32 internal constant Z_4 = hex"e58769b32a1beaf1ea27375a44095a0d1fb664ce2dd358e7fcbfb78c26a19344";
  bytes32 internal constant Z_5 = hex"0eb01ebfc9ed27500cd4dfc979272d1f0913cc9f66540d7e8005811109e1cf2d";
  bytes32 internal constant Z_6 = hex"887c22bd8750d34016ac3c66b5ff102dacdd73f6b014e710b51e8022af9a1968";
  bytes32 internal constant Z_7 = hex"ffd70157e48063fc33c97a050f7f640233bf646cc98d9524c6b92bcf3ab56f83";
  bytes32 internal constant Z_8 = hex"9867cc5f7f196b93bae1e27e6320742445d290f2263827498b54fec539f756af";
  bytes32 internal constant Z_9 = hex"cefad4e508c098b9a7e1d8feb19955fb02ba9675585078710969d3440f5054e0";
  bytes32 internal constant Z_10 = hex"f9dc3e7fe016e050eff260334f18a5d4fe391d82092319f5964f2e2eb7c1c3a5";
  bytes32 internal constant Z_11 = hex"f8b13a49e282f609c317a833fb8d976d11517c571d1221a265d25af778ecf892";
  bytes32 internal constant Z_12 = hex"3490c6ceeb450aecdc82e28293031d10c7d73bf85e57bf041a97360aa2c5d99c";
  bytes32 internal constant Z_13 = hex"c1df82d9c4b87413eae2ef048f94b4d3554cea73d92b0f7af96e0271c691e2bb";
  bytes32 internal constant Z_14 = hex"5c67add7c6caf302256adedf7ab114da0acfe870d449a3a489f781d659e8becc";
  bytes32 internal constant Z_15 = hex"da7bce9f4e8618b6bd2f4132ce798cdc7a60e7e1460a7299e3c6342a579626d2";
  bytes32 internal constant Z_16 = hex"2733e50f526ec2fa19a22b31e8ed50f23cd1fdf94c9154ed3a7609a2f1ff981f";
  bytes32 internal constant Z_17 = hex"e1d3b5c807b281e4683cc6d6315cf95b9ade8641defcb32372f1c126e398ef7a";
  bytes32 internal constant Z_18 = hex"5a2dce0a8a7f68bb74560f8f71837c2c2ebbcbf7fffb42ae1896f13f7c7479a0";
  bytes32 internal constant Z_19 = hex"b46a28b6f55540f89444f63de0378e3d121be09e06cc9ded1c20e65876d36aa0";
  bytes32 internal constant Z_20 = hex"c65e9645644786b620e2dd2ad648ddfcbf4a7e5b1a3a4ecfe7f64667a3f0b7e2";
  bytes32 internal constant Z_21 = hex"f4418588ed35a2458cffeb39b93d26f18d2ab13bdce6aee58e7b99359ec2dfd9";
  bytes32 internal constant Z_22 = hex"5a9c16dc00d6ef18b7933a6f8dc65ccb55667138776f7dea101070dc8796e377";
  bytes32 internal constant Z_23 = hex"4df84f40ae0c8229d0d6069e5c8f39a7c299677a09d367fc7b05e3bc380ee652";
  bytes32 internal constant Z_24 = hex"cdc72595f74c7b1043d0e1ffbab734648c838dfb0527d971b602bc216c9619ef";
  bytes32 internal constant Z_25 = hex"0abf5ac974a1ed57f4050aa510dd9c74f508277b39d7973bb2dfccc5eeb0618d";
  bytes32 internal constant Z_26 = hex"b8cd74046ff337f0a7bf2c8e03e10f642c1886798d71806ab1e888d9e5ee87d0";
  bytes32 internal constant Z_27 = hex"838c5655cb21c6cb83313b5a631175dff4963772cce9108188b34ac87c81c41e";
  bytes32 internal constant Z_28 = hex"662ee4dd2dd7b2bc707961b1e646c4047669dcb6584f0d8d770daf5d7e7deb2e";
  bytes32 internal constant Z_29 = hex"388ab20e2573d171a88108e79d820e98f26c0b84aa8b2f4aa4968dbb818ea322";
  bytes32 internal constant Z_30 = hex"93237c50ba75ee485f4c22adf2f741400bdf8d6a9cc7df7ecae576221665d735";
  bytes32 internal constant Z_31 = hex"8448818bb4ae4562849e949e17ac16e0be16688e156b5cf15e098c627c0056a9";
  bytes32 internal constant Z_32 = hex"27ae5ba08d7291c96c8cbddcc148bf48a6d68c7974b94356f53754ef6171d757";

  // ============= Structs ==============

  /**
   * @notice Struct representing incremental merkle tree. Contains current
   * branch and the number of inserted leaves in the tree.
   **/
  struct Tree {
    bytes32[TREE_DEPTH] branch;
    uint256 count;
  }

  // ========= Write Methods =========

  /**
   * @notice Inserts a given node (leaf) into merkle tree. Operates on an in-memory tree and
   * returns an updated version of that tree.
   * @dev Reverts if the tree is already full.
   * @param node Element to insert into tree.
   * @return Tree Updated tree.
   **/
  function insert(Tree memory tree, bytes32 node) internal pure returns (Tree memory) {
    // Update tree.count to increase the current count by 1 since we'll be including a new node.
    uint256 size = ++tree.count;
    if (size > MAX_LEAVES) revert MerkleLib__insert_treeIsFull();

    // Loop starting at 0, ending when we've finished inserting the node (i.e. hashing it) into
    // the active branch. Each loop we cut size in half, hashing the inserted node up the active
    // branch along the way.
    for (uint256 i; i < TREE_DEPTH; ) {
      // Check if the current size is odd; if so, we set this index in the branch to be the node.
      if ((size & 1) == 1) {
        // If i > 0, then this node will be a hash of the original node with every layer up
        // until layer `i`.
        tree.branch[i] = node;
        return tree;
      }
      // If the size is not yet odd, we hash the current index in the tree branch with the node.
      node = keccak256(abi.encodePacked(tree.branch[i], node));
      size >>= 1; // Cut size in half (statement equivalent to: `size /= 2`).

      unchecked {
        ++i;
      }
    }
    // As the loop should always end prematurely with the `return` statement, this code should
    // be unreachable. We revert here just to be safe.
    revert MerkleLib__insert_treeIsFull();
  }

  // ========= Read Methods =========

  /**
   * @notice Calculates and returns tree's current root.
   * @return _current bytes32 root.
   **/
  function root(Tree storage tree) internal view returns (bytes32 _current) {
    uint256 _index = tree.count;

    if (_index == 0) {
      return Z_32;
    }

    uint256 i;
    assembly {
      let TREE_SLOT := tree.slot

      for {

      } true {

      } {
        for {

        } true {

        } {
          if and(_index, 1) {
            mstore(0, sload(TREE_SLOT))
            mstore(0x20, Z_0)
            _current := keccak256(0, 0x40)
            break
          }

          if and(_index, shl(1, 1)) {
            mstore(0, sload(add(TREE_SLOT, 1)))
            mstore(0x20, Z_1)
            _current := keccak256(0, 0x40)
            i := 1
            break
          }

          if and(_index, shl(2, 1)) {
            mstore(0, sload(add(TREE_SLOT, 2)))
            mstore(0x20, Z_2)
            _current := keccak256(0, 0x40)
            i := 2
            break
          }

          if and(_index, shl(3, 1)) {
            mstore(0, sload(add(TREE_SLOT, 3)))
            mstore(0x20, Z_3)
            _current := keccak256(0, 0x40)
            i := 3
            break
          }

          if and(_index, shl(4, 1)) {
            mstore(0, sload(add(TREE_SLOT, 4)))
            mstore(0x20, Z_4)
            _current := keccak256(0, 0x40)
            i := 4
            break
          }

          if and(_index, shl(5, 1)) {
            mstore(0, sload(add(TREE_SLOT, 5)))
            mstore(0x20, Z_5)
            _current := keccak256(0, 0x40)
            i := 5
            break
          }

          if and(_index, shl(6, 1)) {
            mstore(0, sload(add(TREE_SLOT, 6)))
            mstore(0x20, Z_6)
            _current := keccak256(0, 0x40)
            i := 6
            break
          }

          if and(_index, shl(7, 1)) {
            mstore(0, sload(add(TREE_SLOT, 7)))
            mstore(0x20, Z_7)
            _current := keccak256(0, 0x40)
            i := 7
            break
          }

          if and(_index, shl(8, 1)) {
            mstore(0, sload(add(TREE_SLOT, 8)))
            mstore(0x20, Z_8)
            _current := keccak256(0, 0x40)
            i := 8
            break
          }

          if and(_index, shl(9, 1)) {
            mstore(0, sload(add(TREE_SLOT, 9)))
            mstore(0x20, Z_9)
            _current := keccak256(0, 0x40)
            i := 9
            break
          }

          if and(_index, shl(10, 1)) {
            mstore(0, sload(add(TREE_SLOT, 10)))
            mstore(0x20, Z_10)
            _current := keccak256(0, 0x40)
            i := 10
            break
          }

          if and(_index, shl(11, 1)) {
            mstore(0, sload(add(TREE_SLOT, 11)))
            mstore(0x20, Z_11)
            _current := keccak256(0, 0x40)
            i := 11
            break
          }

          if and(_index, shl(12, 1)) {
            mstore(0, sload(add(TREE_SLOT, 12)))
            mstore(0x20, Z_12)
            _current := keccak256(0, 0x40)
            i := 12
            break
          }

          if and(_index, shl(13, 1)) {
            mstore(0, sload(add(TREE_SLOT, 13)))
            mstore(0x20, Z_13)
            _current := keccak256(0, 0x40)
            i := 13
            break
          }

          if and(_index, shl(14, 1)) {
            mstore(0, sload(add(TREE_SLOT, 14)))
            mstore(0x20, Z_14)
            _current := keccak256(0, 0x40)
            i := 14
            break
          }

          if and(_index, shl(15, 1)) {
            mstore(0, sload(add(TREE_SLOT, 15)))
            mstore(0x20, Z_15)
            _current := keccak256(0, 0x40)
            i := 15
            break
          }

          if and(_index, shl(16, 1)) {
            mstore(0, sload(add(TREE_SLOT, 16)))
            mstore(0x20, Z_16)
            _current := keccak256(0, 0x40)
            i := 16
            break
          }

          if and(_index, shl(17, 1)) {
            mstore(0, sload(add(TREE_SLOT, 17)))
            mstore(0x20, Z_17)
            _current := keccak256(0, 0x40)
            i := 17
            break
          }

          if and(_index, shl(18, 1)) {
            mstore(0, sload(add(TREE_SLOT, 18)))
            mstore(0x20, Z_18)
            _current := keccak256(0, 0x40)
            i := 18
            break
          }

          if and(_index, shl(19, 1)) {
            mstore(0, sload(add(TREE_SLOT, 19)))
            mstore(0x20, Z_19)
            _current := keccak256(0, 0x40)
            i := 19
            break
          }

          if and(_index, shl(20, 1)) {
            mstore(0, sload(add(TREE_SLOT, 20)))
            mstore(0x20, Z_20)
            _current := keccak256(0, 0x40)
            i := 20
            break
          }

          if and(_index, shl(21, 1)) {
            mstore(0, sload(add(TREE_SLOT, 21)))
            mstore(0x20, Z_21)
            _current := keccak256(0, 0x40)
            i := 21
            break
          }

          if and(_index, shl(22, 1)) {
            mstore(0, sload(add(TREE_SLOT, 22)))
            mstore(0x20, Z_22)
            _current := keccak256(0, 0x40)
            i := 22
            break
          }

          if and(_index, shl(23, 1)) {
            mstore(0, sload(add(TREE_SLOT, 23)))
            mstore(0x20, Z_23)
            _current := keccak256(0, 0x40)
            i := 23
            break
          }

          if and(_index, shl(24, 1)) {
            mstore(0, sload(add(TREE_SLOT, 24)))
            mstore(0x20, Z_24)
            _current := keccak256(0, 0x40)
            i := 24
            break
          }

          if and(_index, shl(25, 1)) {
            mstore(0, sload(add(TREE_SLOT, 25)))
            mstore(0x20, Z_25)
            _current := keccak256(0, 0x40)
            i := 25
            break
          }

          if and(_index, shl(26, 1)) {
            mstore(0, sload(add(TREE_SLOT, 26)))
            mstore(0x20, Z_26)
            _current := keccak256(0, 0x40)
            i := 26
            break
          }

          if and(_index, shl(27, 1)) {
            mstore(0, sload(add(TREE_SLOT, 27)))
            mstore(0x20, Z_27)
            _current := keccak256(0, 0x40)
            i := 27
            break
          }

          if and(_index, shl(28, 1)) {
            mstore(0, sload(add(TREE_SLOT, 28)))
            mstore(0x20, Z_28)
            _current := keccak256(0, 0x40)
            i := 28
            break
          }

          if and(_index, shl(29, 1)) {
            mstore(0, sload(add(TREE_SLOT, 29)))
            mstore(0x20, Z_29)
            _current := keccak256(0, 0x40)
            i := 29
            break
          }

          if and(_index, shl(30, 1)) {
            mstore(0, sload(add(TREE_SLOT, 30)))
            mstore(0x20, Z_30)
            _current := keccak256(0, 0x40)
            i := 30
            break
          }

          if and(_index, shl(31, 1)) {
            mstore(0, sload(add(TREE_SLOT, 31)))
            mstore(0x20, Z_31)
            _current := keccak256(0, 0x40)
            i := 31
            break
          }

          _current := Z_32
          i := 32
          break
        }

        if gt(i, 30) {
          break
        }

        {
          if lt(i, 1) {
            switch and(_index, shl(1, 1))
            case 0 {
              mstore(0, _current)
              mstore(0x20, Z_1)
            }
            default {
              mstore(0, sload(add(TREE_SLOT, 1)))
              mstore(0x20, _current)
            }

            _current := keccak256(0, 0x40)
          }

          if lt(i, 2) {
            switch and(_index, shl(2, 1))
            case 0 {
              mstore(0, _current)
              mstore(0x20, Z_2)
            }
            default {
              mstore(0, sload(add(TREE_SLOT, 2)))
              mstore(0x20, _current)
            }

            _current := keccak256(0, 0x40)
          }

          if lt(i, 3) {
            switch and(_index, shl(3, 1))
            case 0 {
              mstore(0, _current)
              mstore(0x20, Z_3)
            }
            default {
              mstore(0, sload(add(TREE_SLOT, 3)))
              mstore(0x20, _current)
            }

            _current := keccak256(0, 0x40)
          }

          if lt(i, 4) {
            switch and(_index, shl(4, 1))
            case 0 {
              mstore(0, _current)
              mstore(0x20, Z_4)
            }
            default {
              mstore(0, sload(add(TREE_SLOT, 4)))
              mstore(0x20, _current)
            }

            _current := keccak256(0, 0x40)
          }

          if lt(i, 5) {
            switch and(_index, shl(5, 1))
            case 0 {
              mstore(0, _current)
              mstore(0x20, Z_5)
            }
            default {
              mstore(0, sload(add(TREE_SLOT, 5)))
              mstore(0x20, _current)
            }

            _current := keccak256(0, 0x40)
          }

          if lt(i, 6) {
            switch and(_index, shl(6, 1))
            case 0 {
              mstore(0, _current)
              mstore(0x20, Z_6)
            }
            default {
              mstore(0, sload(add(TREE_SLOT, 6)))
              mstore(0x20, _current)
            }

            _current := keccak256(0, 0x40)
          }

          if lt(i, 7) {
            switch and(_index, shl(7, 1))
            case 0 {
              mstore(0, _current)
              mstore(0x20, Z_7)
            }
            default {
              mstore(0, sload(add(TREE_SLOT, 7)))
              mstore(0x20, _current)
            }

            _current := keccak256(0, 0x40)
          }

          if lt(i, 8) {
            switch and(_index, shl(8, 1))
            case 0 {
              mstore(0, _current)
              mstore(0x20, Z_8)
            }
            default {
              mstore(0, sload(add(TREE_SLOT, 8)))
              mstore(0x20, _current)
            }

            _current := keccak256(0, 0x40)
          }

          if lt(i, 9) {
            switch and(_index, shl(9, 1))
            case 0 {
              mstore(0, _current)
              mstore(0x20, Z_9)
            }
            default {
              mstore(0, sload(add(TREE_SLOT, 9)))
              mstore(0x20, _current)
            }

            _current := keccak256(0, 0x40)
          }

          if lt(i, 10) {
            switch and(_index, shl(10, 1))
            case 0 {
              mstore(0, _current)
              mstore(0x20, Z_10)
            }
            default {
              mstore(0, sload(add(TREE_SLOT, 10)))
              mstore(0x20, _current)
            }

            _current := keccak256(0, 0x40)
          }

          if lt(i, 11) {
            switch and(_index, shl(11, 1))
            case 0 {
              mstore(0, _current)
              mstore(0x20, Z_11)
            }
            default {
              mstore(0, sload(add(TREE_SLOT, 11)))
              mstore(0x20, _current)
            }

            _current := keccak256(0, 0x40)
          }

          if lt(i, 12) {
            switch and(_index, shl(12, 1))
            case 0 {
              mstore(0, _current)
              mstore(0x20, Z_12)
            }
            default {
              mstore(0, sload(add(TREE_SLOT, 12)))
              mstore(0x20, _current)
            }

            _current := keccak256(0, 0x40)
          }

          if lt(i, 13) {
            switch and(_index, shl(13, 1))
            case 0 {
              mstore(0, _current)
              mstore(0x20, Z_13)
            }
            default {
              mstore(0, sload(add(TREE_SLOT, 13)))
              mstore(0x20, _current)
            }

            _current := keccak256(0, 0x40)
          }

          if lt(i, 14) {
            switch and(_index, shl(14, 1))
            case 0 {
              mstore(0, _current)
              mstore(0x20, Z_14)
            }
            default {
              mstore(0, sload(add(TREE_SLOT, 14)))
              mstore(0x20, _current)
            }

            _current := keccak256(0, 0x40)
          }

          if lt(i, 15) {
            switch and(_index, shl(15, 1))
            case 0 {
              mstore(0, _current)
              mstore(0x20, Z_15)
            }
            default {
              mstore(0, sload(add(TREE_SLOT, 15)))
              mstore(0x20, _current)
            }

            _current := keccak256(0, 0x40)
          }

          if lt(i, 16) {
            switch and(_index, shl(16, 1))
            case 0 {
              mstore(0, _current)
              mstore(0x20, Z_16)
            }
            default {
              mstore(0, sload(add(TREE_SLOT, 16)))
              mstore(0x20, _current)
            }

            _current := keccak256(0, 0x40)
          }

          if lt(i, 17) {
            switch and(_index, shl(17, 1))
            case 0 {
              mstore(0, _current)
              mstore(0x20, Z_17)
            }
            default {
              mstore(0, sload(add(TREE_SLOT, 17)))
              mstore(0x20, _current)
            }

            _current := keccak256(0, 0x40)
          }

          if lt(i, 18) {
            switch and(_index, shl(18, 1))
            case 0 {
              mstore(0, _current)
              mstore(0x20, Z_18)
            }
            default {
              mstore(0, sload(add(TREE_SLOT, 18)))
              mstore(0x20, _current)
            }

            _current := keccak256(0, 0x40)
          }

          if lt(i, 19) {
            switch and(_index, shl(19, 1))
            case 0 {
              mstore(0, _current)
              mstore(0x20, Z_19)
            }
            default {
              mstore(0, sload(add(TREE_SLOT, 19)))
              mstore(0x20, _current)
            }

            _current := keccak256(0, 0x40)
          }

          if lt(i, 20) {
            switch and(_index, shl(20, 1))
            case 0 {
              mstore(0, _current)
              mstore(0x20, Z_20)
            }
            default {
              mstore(0, sload(add(TREE_SLOT, 20)))
              mstore(0x20, _current)
            }

            _current := keccak256(0, 0x40)
          }

          if lt(i, 21) {
            switch and(_index, shl(21, 1))
            case 0 {
              mstore(0, _current)
              mstore(0x20, Z_21)
            }
            default {
              mstore(0, sload(add(TREE_SLOT, 21)))
              mstore(0x20, _current)
            }

            _current := keccak256(0, 0x40)
          }

          if lt(i, 22) {
            switch and(_index, shl(22, 1))
            case 0 {
              mstore(0, _current)
              mstore(0x20, Z_22)
            }
            default {
              mstore(0, sload(add(TREE_SLOT, 22)))
              mstore(0x20, _current)
            }

            _current := keccak256(0, 0x40)
          }

          if lt(i, 23) {
            switch and(_index, shl(23, 1))
            case 0 {
              mstore(0, _current)
              mstore(0x20, Z_23)
            }
            default {
              mstore(0, sload(add(TREE_SLOT, 23)))
              mstore(0x20, _current)
            }

            _current := keccak256(0, 0x40)
          }

          if lt(i, 24) {
            switch and(_index, shl(24, 1))
            case 0 {
              mstore(0, _current)
              mstore(0x20, Z_24)
            }
            default {
              mstore(0, sload(add(TREE_SLOT, 24)))
              mstore(0x20, _current)
            }

            _current := keccak256(0, 0x40)
          }

          if lt(i, 25) {
            switch and(_index, shl(25, 1))
            case 0 {
              mstore(0, _current)
              mstore(0x20, Z_25)
            }
            default {
              mstore(0, sload(add(TREE_SLOT, 25)))
              mstore(0x20, _current)
            }

            _current := keccak256(0, 0x40)
          }

          if lt(i, 26) {
            switch and(_index, shl(26, 1))
            case 0 {
              mstore(0, _current)
              mstore(0x20, Z_26)
            }
            default {
              mstore(0, sload(add(TREE_SLOT, 26)))
              mstore(0x20, _current)
            }

            _current := keccak256(0, 0x40)
          }

          if lt(i, 27) {
            switch and(_index, shl(27, 1))
            case 0 {
              mstore(0, _current)
              mstore(0x20, Z_27)
            }
            default {
              mstore(0, sload(add(TREE_SLOT, 27)))
              mstore(0x20, _current)
            }

            _current := keccak256(0, 0x40)
          }

          if lt(i, 28) {
            switch and(_index, shl(28, 1))
            case 0 {
              mstore(0, _current)
              mstore(0x20, Z_28)
            }
            default {
              mstore(0, sload(add(TREE_SLOT, 28)))
              mstore(0x20, _current)
            }

            _current := keccak256(0, 0x40)
          }

          if lt(i, 29) {
            switch and(_index, shl(29, 1))
            case 0 {
              mstore(0, _current)
              mstore(0x20, Z_29)
            }
            default {
              mstore(0, sload(add(TREE_SLOT, 29)))
              mstore(0x20, _current)
            }

            _current := keccak256(0, 0x40)
          }

          if lt(i, 30) {
            switch and(_index, shl(30, 1))
            case 0 {
              mstore(0, _current)
              mstore(0x20, Z_30)
            }
            default {
              mstore(0, sload(add(TREE_SLOT, 30)))
              mstore(0x20, _current)
            }

            _current := keccak256(0, 0x40)
          }

          if lt(i, 31) {
            switch and(_index, shl(31, 1))
            case 0 {
              mstore(0, _current)
              mstore(0x20, Z_31)
            }
            default {
              mstore(0, sload(add(TREE_SLOT, 31)))
              mstore(0x20, _current)
            }

            _current := keccak256(0, 0x40)
          }
        }

        break
      }
    }
  }

  /**
   * @notice Calculates and returns the merkle root for the given leaf `_item`,
   * a merkle branch, and the index of `_item` in the tree.
   * @param _item Merkle leaf
   * @param _branch Merkle proof
   * @param _index Index of `_item` in tree
   * @return _current Calculated merkle root
   **/
  function branchRoot(
    bytes32 _item,
    bytes32[TREE_DEPTH] memory _branch,
    uint256 _index
  ) internal pure returns (bytes32 _current) {
    assembly {
      _current := _item
      let BRANCH_DATA_OFFSET := _branch
      let f

      f := shl(5, and(_index, 1))
      mstore(f, _current)
      mstore(sub(0x20, f), mload(BRANCH_DATA_OFFSET))
      _current := keccak256(0, 0x40)

      f := shl(5, iszero(and(_index, shl(1, 1))))
      mstore(sub(0x20, f), _current)
      mstore(f, mload(add(BRANCH_DATA_OFFSET, shl(5, 1))))
      _current := keccak256(0, 0x40)

      f := shl(5, iszero(and(_index, shl(2, 1))))
      mstore(sub(0x20, f), _current)
      mstore(f, mload(add(BRANCH_DATA_OFFSET, shl(5, 2))))
      _current := keccak256(0, 0x40)

      f := shl(5, iszero(and(_index, shl(3, 1))))
      mstore(sub(0x20, f), _current)
      mstore(f, mload(add(BRANCH_DATA_OFFSET, shl(5, 3))))
      _current := keccak256(0, 0x40)

      f := shl(5, iszero(and(_index, shl(4, 1))))
      mstore(sub(0x20, f), _current)
      mstore(f, mload(add(BRANCH_DATA_OFFSET, shl(5, 4))))
      _current := keccak256(0, 0x40)

      f := shl(5, iszero(and(_index, shl(5, 1))))
      mstore(sub(0x20, f), _current)
      mstore(f, mload(add(BRANCH_DATA_OFFSET, shl(5, 5))))
      _current := keccak256(0, 0x40)

      f := shl(5, iszero(and(_index, shl(6, 1))))
      mstore(sub(0x20, f), _current)
      mstore(f, mload(add(BRANCH_DATA_OFFSET, shl(5, 6))))
      _current := keccak256(0, 0x40)

      f := shl(5, iszero(and(_index, shl(7, 1))))
      mstore(sub(0x20, f), _current)
      mstore(f, mload(add(BRANCH_DATA_OFFSET, shl(5, 7))))
      _current := keccak256(0, 0x40)

      f := shl(5, iszero(and(_index, shl(8, 1))))
      mstore(sub(0x20, f), _current)
      mstore(f, mload(add(BRANCH_DATA_OFFSET, shl(5, 8))))
      _current := keccak256(0, 0x40)

      f := shl(5, iszero(and(_index, shl(9, 1))))
      mstore(sub(0x20, f), _current)
      mstore(f, mload(add(BRANCH_DATA_OFFSET, shl(5, 9))))
      _current := keccak256(0, 0x40)

      f := shl(5, iszero(and(_index, shl(10, 1))))
      mstore(sub(0x20, f), _current)
      mstore(f, mload(add(BRANCH_DATA_OFFSET, shl(5, 10))))
      _current := keccak256(0, 0x40)

      f := shl(5, iszero(and(_index, shl(11, 1))))
      mstore(sub(0x20, f), _current)
      mstore(f, mload(add(BRANCH_DATA_OFFSET, shl(5, 11))))
      _current := keccak256(0, 0x40)

      f := shl(5, iszero(and(_index, shl(12, 1))))
      mstore(sub(0x20, f), _current)
      mstore(f, mload(add(BRANCH_DATA_OFFSET, shl(5, 12))))
      _current := keccak256(0, 0x40)

      f := shl(5, iszero(and(_index, shl(13, 1))))
      mstore(sub(0x20, f), _current)
      mstore(f, mload(add(BRANCH_DATA_OFFSET, shl(5, 13))))
      _current := keccak256(0, 0x40)

      f := shl(5, iszero(and(_index, shl(14, 1))))
      mstore(sub(0x20, f), _current)
      mstore(f, mload(add(BRANCH_DATA_OFFSET, shl(5, 14))))
      _current := keccak256(0, 0x40)

      f := shl(5, iszero(and(_index, shl(15, 1))))
      mstore(sub(0x20, f), _current)
      mstore(f, mload(add(BRANCH_DATA_OFFSET, shl(5, 15))))
      _current := keccak256(0, 0x40)

      f := shl(5, iszero(and(_index, shl(16, 1))))
      mstore(sub(0x20, f), _current)
      mstore(f, mload(add(BRANCH_DATA_OFFSET, shl(5, 16))))
      _current := keccak256(0, 0x40)

      f := shl(5, iszero(and(_index, shl(17, 1))))
      mstore(sub(0x20, f), _current)
      mstore(f, mload(add(BRANCH_DATA_OFFSET, shl(5, 17))))
      _current := keccak256(0, 0x40)

      f := shl(5, iszero(and(_index, shl(18, 1))))
      mstore(sub(0x20, f), _current)
      mstore(f, mload(add(BRANCH_DATA_OFFSET, shl(5, 18))))
      _current := keccak256(0, 0x40)

      f := shl(5, iszero(and(_index, shl(19, 1))))
      mstore(sub(0x20, f), _current)
      mstore(f, mload(add(BRANCH_DATA_OFFSET, shl(5, 19))))
      _current := keccak256(0, 0x40)

      f := shl(5, iszero(and(_index, shl(20, 1))))
      mstore(sub(0x20, f), _current)
      mstore(f, mload(add(BRANCH_DATA_OFFSET, shl(5, 20))))
      _current := keccak256(0, 0x40)

      f := shl(5, iszero(and(_index, shl(21, 1))))
      mstore(sub(0x20, f), _current)
      mstore(f, mload(add(BRANCH_DATA_OFFSET, shl(5, 21))))
      _current := keccak256(0, 0x40)

      f := shl(5, iszero(and(_index, shl(22, 1))))
      mstore(sub(0x20, f), _current)
      mstore(f, mload(add(BRANCH_DATA_OFFSET, shl(5, 22))))
      _current := keccak256(0, 0x40)

      f := shl(5, iszero(and(_index, shl(23, 1))))
      mstore(sub(0x20, f), _current)
      mstore(f, mload(add(BRANCH_DATA_OFFSET, shl(5, 23))))
      _current := keccak256(0, 0x40)

      f := shl(5, iszero(and(_index, shl(24, 1))))
      mstore(sub(0x20, f), _current)
      mstore(f, mload(add(BRANCH_DATA_OFFSET, shl(5, 24))))
      _current := keccak256(0, 0x40)

      f := shl(5, iszero(and(_index, shl(25, 1))))
      mstore(sub(0x20, f), _current)
      mstore(f, mload(add(BRANCH_DATA_OFFSET, shl(5, 25))))
      _current := keccak256(0, 0x40)

      f := shl(5, iszero(and(_index, shl(26, 1))))
      mstore(sub(0x20, f), _current)
      mstore(f, mload(add(BRANCH_DATA_OFFSET, shl(5, 26))))
      _current := keccak256(0, 0x40)

      f := shl(5, iszero(and(_index, shl(27, 1))))
      mstore(sub(0x20, f), _current)
      mstore(f, mload(add(BRANCH_DATA_OFFSET, shl(5, 27))))
      _current := keccak256(0, 0x40)

      f := shl(5, iszero(and(_index, shl(28, 1))))
      mstore(sub(0x20, f), _current)
      mstore(f, mload(add(BRANCH_DATA_OFFSET, shl(5, 28))))
      _current := keccak256(0, 0x40)

      f := shl(5, iszero(and(_index, shl(29, 1))))
      mstore(sub(0x20, f), _current)
      mstore(f, mload(add(BRANCH_DATA_OFFSET, shl(5, 29))))
      _current := keccak256(0, 0x40)

      f := shl(5, iszero(and(_index, shl(30, 1))))
      mstore(sub(0x20, f), _current)
      mstore(f, mload(add(BRANCH_DATA_OFFSET, shl(5, 30))))
      _current := keccak256(0, 0x40)

      f := shl(5, iszero(and(_index, shl(31, 1))))
      mstore(sub(0x20, f), _current)
      mstore(f, mload(add(BRANCH_DATA_OFFSET, shl(5, 31))))
      _current := keccak256(0, 0x40)
    }
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

import {TypedMemView} from "../../shared/libraries/TypedMemView.sol";
import {TypeCasts} from "../../shared/libraries/TypeCasts.sol";

/**
 * @title Message Library
 * @author Illusory Systems Inc.
 * @notice Library for formatted messages used by Home and Replica.
 **/
library Message {
  using TypedMemView for bytes;
  using TypedMemView for bytes29;

  // Number of bytes in formatted message before `body` field
  uint256 internal constant PREFIX_LENGTH = 76;

  /**
   * @notice Returns formatted (packed) message with provided fields
   * @param _originDomain Domain of home chain
   * @param _sender Address of sender as bytes32
   * @param _nonce Destination-specific nonce
   * @param _destinationDomain Domain of destination chain
   * @param _recipient Address of recipient on destination chain as bytes32
   * @param _messageBody Raw bytes of message body
   * @return Formatted message
   **/
  function formatMessage(
    uint32 _originDomain,
    bytes32 _sender,
    uint32 _nonce,
    uint32 _destinationDomain,
    bytes32 _recipient,
    bytes memory _messageBody
  ) internal pure returns (bytes memory) {
    return abi.encodePacked(_originDomain, _sender, _nonce, _destinationDomain, _recipient, _messageBody);
  }

  /**
   * @notice Returns leaf of formatted message with provided fields.
   * @param _origin Domain of home chain
   * @param _sender Address of sender as bytes32
   * @param _nonce Destination-specific nonce number
   * @param _destination Domain of destination chain
   * @param _recipient Address of recipient on destination chain as bytes32
   * @param _body Raw bytes of message body
   * @return Leaf (hash) of formatted message
   **/
  function messageHash(
    uint32 _origin,
    bytes32 _sender,
    uint32 _nonce,
    uint32 _destination,
    bytes32 _recipient,
    bytes memory _body
  ) internal pure returns (bytes32) {
    return keccak256(formatMessage(_origin, _sender, _nonce, _destination, _recipient, _body));
  }

  /// @notice Returns message's origin field
  function origin(bytes29 _message) internal pure returns (uint32) {
    return uint32(_message.indexUint(0, 4));
  }

  /// @notice Returns message's sender field
  function sender(bytes29 _message) internal pure returns (bytes32) {
    return _message.index(4, 32);
  }

  /// @notice Returns message's nonce field
  function nonce(bytes29 _message) internal pure returns (uint32) {
    return uint32(_message.indexUint(36, 4));
  }

  /// @notice Returns message's destination field
  function destination(bytes29 _message) internal pure returns (uint32) {
    return uint32(_message.indexUint(40, 4));
  }

  /// @notice Returns message's recipient field as bytes32
  function recipient(bytes29 _message) internal pure returns (bytes32) {
    return _message.index(44, 32);
  }

  /// @notice Returns message's recipient field as an address
  function recipientAddress(bytes29 _message) internal pure returns (address) {
    return TypeCasts.bytes32ToAddress(recipient(_message));
  }

  /// @notice Returns message's body field as bytes29 (refer to TypedMemView library for details on bytes29 type)
  function body(bytes29 _message) internal pure returns (bytes29) {
    return _message.slice(PREFIX_LENGTH, _message.len() - PREFIX_LENGTH, 0);
  }

  function leaf(bytes29 _message) internal pure returns (bytes32) {
    uint256 loc = _message.loc();
    uint256 len = _message.len();
    /*
    prev:
    return
      messageHash(
        origin(_message),
        sender(_message),
        nonce(_message),
        destination(_message),
        recipient(_message),
        TypedMemView.clone(body(_message))
      );

      below added for gas optimization
     */
    bytes32 hash;
    assembly {
      hash := keccak256(loc, len)
    }
    return hash;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

/**
 * @notice An abstract contract intended to manage the rate limiting aspect of spoke
 * connector messaging. Rate limiting the number of messages we can send over a span of
 * blocks is used to mitigate key DoSing vectors for transporting messages between chains.
 */
abstract contract RateLimited {
  // ========== Custom Errors ===========

  error RateLimited__rateLimited_messageSendRateExceeded();

  // ============ Events ============

  event SendRateLimitUpdated(address updater, uint256 newRateLimit);

  // ============ Public Storage ============

  /**
   * @notice The number of blocks required between message sending events.
   * @dev NOTE: This value is 0 by default, meaning that rate limiting functionality
   * will naturally be disabled by default.
   */
  uint256 public rateLimitBlocks;

  /**
   * @notice Tracks the last block that we sent a message.
   */
  uint256 public lastSentBlock;

  // ============ Modifiers ============

  /**
   * @notice Checks to see if we can send this block, given the current rate limit
   * setting and the last block we sent a message. If rate limit has been surpassed,
   * we update the `lastSentBlock` to be the current block.
   */
  modifier rateLimited() {
    // Check to make sure we have surpassed the number of rate limit blocks.
    if (lastSentBlock + rateLimitBlocks > block.number) {
      revert RateLimited__rateLimited_messageSendRateExceeded();
    }
    // Update the last block we sent a message to be the current one.
    lastSentBlock = block.number;
    _;
  }

  // ============ Admin Functions ============

  /**
   * @notice Update the current rate limit to a new value.
   */
  function _setRateLimitBlocks(uint256 _newRateLimit) internal {
    require(_newRateLimit != rateLimitBlocks, "!new rate limit");
    // NOTE: Setting the block rate limit interval to 0 will result in rate limiting
    // being disabled.
    rateLimitBlocks = _newRateLimit;
    emit SendRateLimitUpdated(msg.sender, _newRateLimit);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {IProposedOwnable} from "./interfaces/IProposedOwnable.sol";

/**
 * @title ProposedOwnable
 * @notice Contract module which provides a basic access control mechanism,
 * where there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed via a two step process:
 * 1. Call `proposeOwner`
 * 2. Wait out the delay period
 * 3. Call `acceptOwner`
 *
 * @dev This module is used through inheritance. It will make available the
 * modifier `onlyOwner`, which can be applied to your functions to restrict
 * their use to the owner.
 *
 * @dev The majority of this code was taken from the openzeppelin Ownable
 * contract
 *
 */
abstract contract ProposedOwnable is IProposedOwnable {
  // ========== Custom Errors ===========

  error ProposedOwnable__onlyOwner_notOwner();
  error ProposedOwnable__onlyProposed_notProposedOwner();
  error ProposedOwnable__ownershipDelayElapsed_delayNotElapsed();
  error ProposedOwnable__proposeNewOwner_invalidProposal();
  error ProposedOwnable__proposeNewOwner_noOwnershipChange();
  error ProposedOwnable__renounceOwnership_noProposal();
  error ProposedOwnable__renounceOwnership_invalidProposal();

  // ============ Properties ============

  address private _owner;

  address private _proposed;
  uint256 private _proposedOwnershipTimestamp;

  uint256 private constant _delay = 7 days;

  // ======== Getters =========

  /**
   * @notice Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @notice Returns the address of the proposed owner.
   */
  function proposed() public view virtual returns (address) {
    return _proposed;
  }

  /**
   * @notice Returns the address of the proposed owner.
   */
  function proposedTimestamp() public view virtual returns (uint256) {
    return _proposedOwnershipTimestamp;
  }

  /**
   * @notice Returns the delay period before a new owner can be accepted.
   */
  function delay() public view virtual returns (uint256) {
    return _delay;
  }

  /**
   * @notice Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    if (_owner != msg.sender) revert ProposedOwnable__onlyOwner_notOwner();
    _;
  }

  /**
   * @notice Throws if called by any account other than the proposed owner.
   */
  modifier onlyProposed() {
    if (_proposed != msg.sender) revert ProposedOwnable__onlyProposed_notProposedOwner();
    _;
  }

  /**
   * @notice Throws if the ownership delay has not elapsed
   */
  modifier ownershipDelayElapsed() {
    // Ensure delay has elapsed
    if ((block.timestamp - _proposedOwnershipTimestamp) <= _delay)
      revert ProposedOwnable__ownershipDelayElapsed_delayNotElapsed();
    _;
  }

  /**
   * @notice Indicates if the ownership has been renounced() by
   * checking if current owner is address(0)
   */
  function renounced() public view returns (bool) {
    return _owner == address(0);
  }

  // ======== External =========

  /**
   * @notice Sets the timestamp for an owner to be proposed, and sets the
   * newly proposed owner as step 1 in a 2-step process
   */
  function proposeNewOwner(address newlyProposed) public virtual onlyOwner {
    // Contract as source of truth
    if (_proposed == newlyProposed && _proposedOwnershipTimestamp != 0)
      revert ProposedOwnable__proposeNewOwner_invalidProposal();

    // Sanity check: reasonable proposal
    if (_owner == newlyProposed) revert ProposedOwnable__proposeNewOwner_noOwnershipChange();

    _setProposed(newlyProposed);
  }

  /**
   * @notice Renounces ownership of the contract after a delay
   */
  function renounceOwnership() public virtual onlyOwner ownershipDelayElapsed {
    // Ensure there has been a proposal cycle started
    if (_proposedOwnershipTimestamp == 0) revert ProposedOwnable__renounceOwnership_noProposal();

    // Require proposed is set to 0
    if (_proposed != address(0)) revert ProposedOwnable__renounceOwnership_invalidProposal();

    // Emit event, set new owner, reset timestamp
    _setOwner(address(0));
  }

  /**
   * @notice Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function acceptProposedOwner() public virtual onlyProposed ownershipDelayElapsed {
    // NOTE: no need to check if _owner == _proposed, because the _proposed
    // is 0-d out and this check is implicitly enforced by modifier

    // NOTE: no need to check if _proposedOwnershipTimestamp > 0 because
    // the only time this would happen is if the _proposed was never
    // set (will fail from modifier) or if the owner == _proposed (checked
    // above)

    // Emit event, set new owner, reset timestamp
    _setOwner(_proposed);
  }

  // ======== Internal =========

  function _setOwner(address newOwner) internal {
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
    delete _proposedOwnershipTimestamp;
    delete _proposed;
  }

  function _setProposed(address newlyProposed) private {
    _proposedOwnershipTimestamp = block.timestamp;
    _proposed = newlyProposed;
    emit OwnershipProposed(newlyProposed);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {ProposedOwnable} from "./ProposedOwnable.sol";

abstract contract ProposedOwnableUpgradeable is Initializable, ProposedOwnable {
  /**
   * @dev Initializes the contract setting the deployer as the initial
   */
  function __ProposedOwnable_init() internal onlyInitializing {
    __ProposedOwnable_init_unchained();
  }

  function __ProposedOwnable_init_unchained() internal onlyInitializing {
    _setOwner(msg.sender);
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[47] private __GAP;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title IProposedOwnable
 * @notice Defines a minimal interface for ownership with a two step proposal and acceptance
 * process
 */
interface IProposedOwnable {
  /**
   * @dev This emits when change in ownership of a contract is proposed.
   */
  event OwnershipProposed(address indexed proposedOwner);

  /**
   * @dev This emits when ownership of a contract changes.
   */
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @notice Get the address of the owner
   * @return owner_ The address of the owner.
   */
  function owner() external view returns (address owner_);

  /**
   * @notice Get the address of the proposed owner
   * @return proposed_ The address of the proposed.
   */
  function proposed() external view returns (address proposed_);

  /**
   * @notice Set the address of the proposed owner of the contract
   * @param newlyProposed The proposed new owner of the contract
   */
  function proposeNewOwner(address newlyProposed) external;

  /**
   * @notice Set the address of the proposed owner of the contract
   */
  function acceptProposedOwner() external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

// Taken from: https://github.com/nomad-xyz/ExcessivelySafeCall
// NOTE: There is a difference between npm latest and github main versions
// where the latest github version allows you to specify an ether value.

library ExcessivelySafeCall {
  uint256 constant LOW_28_MASK = 0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

  /// @notice Use when you _really_ really _really_ don't trust the called
  /// contract. This prevents the called contract from causing reversion of
  /// the caller in as many ways as we can.
  /// @dev The main difference between this and a solidity low-level call is
  /// that we limit the number of bytes that the callee can cause to be
  /// copied to caller memory. This prevents stupid things like malicious
  /// contracts returning 10,000,000 bytes causing a local OOG when copying
  /// to memory.
  /// @param _target The address to call
  /// @param _gas The amount of gas to forward to the remote contract
  /// @param _value The value in wei to send to the remote contract
  /// @param _maxCopy The maximum number of bytes of returndata to copy
  /// to memory.
  /// @param _calldata The data to send to the remote contract
  /// @return success and returndata, as `.call()`. Returndata is capped to
  /// `_maxCopy` bytes.
  function excessivelySafeCall(
    address _target,
    uint256 _gas,
    uint256 _value,
    uint16 _maxCopy,
    bytes memory _calldata
  ) internal returns (bool, bytes memory) {
    // set up for assembly call
    uint256 _toCopy;
    bool _success;
    bytes memory _returnData = new bytes(_maxCopy);
    // dispatch message to recipient
    // by assembly calling "handle" function
    // we call via assembly to avoid memcopying a very large returndata
    // returned by a malicious contract
    assembly {
      _success := call(
        _gas, // gas
        _target, // recipient
        _value, // ether value
        add(_calldata, 0x20), // inloc
        mload(_calldata), // inlen
        0, // outloc
        0 // outlen
      )
      // limit our copy to 256 bytes
      _toCopy := returndatasize()
      if gt(_toCopy, _maxCopy) {
        _toCopy := _maxCopy
      }
      // Store the length of the copied bytes
      mstore(_returnData, _toCopy)
      // copy the bytes from returndata[0:_toCopy]
      returndatacopy(add(_returnData, 0x20), 0, _toCopy)
    }
    return (_success, _returnData);
  }

  /// @notice Use when you _really_ really _really_ don't trust the called
  /// contract. This prevents the called contract from causing reversion of
  /// the caller in as many ways as we can.
  /// @dev The main difference between this and a solidity low-level call is
  /// that we limit the number of bytes that the callee can cause to be
  /// copied to caller memory. This prevents stupid things like malicious
  /// contracts returning 10,000,000 bytes causing a local OOG when copying
  /// to memory.
  /// @param _target The address to call
  /// @param _gas The amount of gas to forward to the remote contract
  /// @param _maxCopy The maximum number of bytes of returndata to copy
  /// to memory.
  /// @param _calldata The data to send to the remote contract
  /// @return success and returndata, as `.call()`. Returndata is capped to
  /// `_maxCopy` bytes.
  function excessivelySafeStaticCall(
    address _target,
    uint256 _gas,
    uint16 _maxCopy,
    bytes memory _calldata
  ) internal view returns (bool, bytes memory) {
    // set up for assembly call
    uint256 _toCopy;
    bool _success;
    bytes memory _returnData = new bytes(_maxCopy);
    // dispatch message to recipient
    // by assembly calling "handle" function
    // we call via assembly to avoid memcopying a very large returndata
    // returned by a malicious contract
    assembly {
      _success := staticcall(
        _gas, // gas
        _target, // recipient
        add(_calldata, 0x20), // inloc
        mload(_calldata), // inlen
        0, // outloc
        0 // outlen
      )
      // limit our copy to 256 bytes
      _toCopy := returndatasize()
      if gt(_toCopy, _maxCopy) {
        _toCopy := _maxCopy
      }
      // Store the length of the copied bytes
      mstore(_returnData, _toCopy)
      // copy the bytes from returndata[0:_toCopy]
      returndatacopy(add(_returnData, 0x20), 0, _toCopy)
    }
    return (_success, _returnData);
  }

  /**
   * @notice Swaps function selectors in encoded contract calls
   * @dev Allows reuse of encoded calldata for functions with identical
   * argument types but different names. It simply swaps out the first 4 bytes
   * for the new selector. This function modifies memory in place, and should
   * only be used with caution.
   * @param _newSelector The new 4-byte selector
   * @param _buf The encoded contract args
   */
  function swapSelector(bytes4 _newSelector, bytes memory _buf) internal pure {
    require(_buf.length > 4 - 1);
    uint256 _mask = LOW_28_MASK;
    assembly {
      // load the first word of
      let _word := mload(add(_buf, 0x20))
      // mask out the top 4 bytes
      // /x
      _word := and(_word, _mask)
      _word := or(_newSelector, _word)
      mstore(add(_buf, 0x20), _word)
    }
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

import {TypedMemView} from "./TypedMemView.sol";

library TypeCasts {
  using TypedMemView for bytes;
  using TypedMemView for bytes29;

  // alignment preserving cast
  function addressToBytes32(address _addr) internal pure returns (bytes32) {
    return bytes32(uint256(uint160(_addr)));
  }

  // alignment preserving cast
  function bytes32ToAddress(bytes32 _buf) internal pure returns (address) {
    return address(uint160(uint256(_buf)));
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.17;

library TypedMemView {
  // Why does this exist?
  // the solidity `bytes memory` type has a few weaknesses.
  // 1. You can't index ranges effectively
  // 2. You can't slice without copying
  // 3. The underlying data may represent any type
  // 4. Solidity never deallocates memory, and memory costs grow
  //    superlinearly

  // By using a memory view instead of a `bytes memory` we get the following
  // advantages:
  // 1. Slices are done on the stack, by manipulating the pointer
  // 2. We can index arbitrary ranges and quickly convert them to stack types
  // 3. We can insert type info into the pointer, and typecheck at runtime

  // This makes `TypedMemView` a useful tool for efficient zero-copy
  // algorithms.

  // Why bytes29?
  // We want to avoid confusion between views, digests, and other common
  // types so we chose a large and uncommonly used odd number of bytes
  //
  // Note that while bytes are left-aligned in a word, integers and addresses
  // are right-aligned. This means when working in assembly we have to
  // account for the 3 unused bytes on the righthand side
  //
  // First 5 bytes are a type flag.
  // - ff_ffff_fffe is reserved for unknown type.
  // - ff_ffff_ffff is reserved for invalid types/errors.
  // next 12 are memory address
  // next 12 are len
  // bottom 3 bytes are empty

  // Assumptions:
  // - non-modification of memory.
  // - No Solidity updates
  // - - wrt free mem point
  // - - wrt bytes representation in memory
  // - - wrt memory addressing in general

  // Usage:
  // - create type constants
  // - use `assertType` for runtime type assertions
  // - - unfortunately we can't do this at compile time yet :(
  // - recommended: implement modifiers that perform type checking
  // - - e.g.
  // - - `uint40 constant MY_TYPE = 3;`
  // - - ` modifer onlyMyType(bytes29 myView) { myView.assertType(MY_TYPE); }`
  // - instantiate a typed view from a bytearray using `ref`
  // - use `index` to inspect the contents of the view
  // - use `slice` to create smaller views into the same memory
  // - - `slice` can increase the offset
  // - - `slice can decrease the length`
  // - - must specify the output type of `slice`
  // - - `slice` will return a null view if you try to overrun
  // - - make sure to explicitly check for this with `notNull` or `assertType`
  // - use `equal` for typed comparisons.

  // The null view
  bytes29 public constant NULL = hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
  uint256 constant LOW_12_MASK = 0xffffffffffffffffffffffff;
  uint256 constant TWENTY_SEVEN_BYTES = 8 * 27;
  uint256 private constant _27_BYTES_IN_BITS = 8 * 27; // <--- also used this named constant where ever 216 is used.
  uint256 private constant LOW_27_BYTES_MASK = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffff; // (1 << _27_BYTES_IN_BITS) - 1;

  // ========== Custom Errors ===========

  error TypedMemView__assertType_typeAssertionFailed(uint256 actual, uint256 expected);
  error TypedMemView__index_overrun(uint256 loc, uint256 len, uint256 index, uint256 slice);
  error TypedMemView__index_indexMoreThan32Bytes();
  error TypedMemView__unsafeCopyTo_nullPointer();
  error TypedMemView__unsafeCopyTo_invalidPointer();
  error TypedMemView__unsafeCopyTo_identityOOG();
  error TypedMemView__assertValid_validityAssertionFailed();

  /**
   * @notice          Changes the endianness of a uint256.
   * @dev             https://graphics.stanford.edu/~seander/bithacks.html#ReverseParallel
   * @param _b        The unsigned integer to reverse
   * @return          v - The reversed value
   */
  function reverseUint256(uint256 _b) internal pure returns (uint256 v) {
    v = _b;

    // swap bytes
    v =
      ((v >> 8) & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) |
      ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);
    // swap 2-byte long pairs
    v =
      ((v >> 16) & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) |
      ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);
    // swap 4-byte long pairs
    v =
      ((v >> 32) & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) |
      ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);
    // swap 8-byte long pairs
    v =
      ((v >> 64) & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) |
      ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);
    // swap 16-byte long pairs
    v = (v >> 128) | (v << 128);
  }

  /**
   * @notice      Create a mask with the highest `_len` bits set.
   * @param _len  The length
   * @return      mask - The mask
   */
  function leftMask(uint8 _len) private pure returns (uint256 mask) {
    // ugly. redo without assembly?
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      mask := sar(sub(_len, 1), 0x8000000000000000000000000000000000000000000000000000000000000000)
    }
  }

  /**
   * @notice      Return the null view.
   * @return      bytes29 - The null view
   */
  function nullView() internal pure returns (bytes29) {
    return NULL;
  }

  /**
   * @notice      Check if the view is null.
   * @return      bool - True if the view is null
   */
  function isNull(bytes29 memView) internal pure returns (bool) {
    return memView == NULL;
  }

  /**
   * @notice      Check if the view is not null.
   * @return      bool - True if the view is not null
   */
  function notNull(bytes29 memView) internal pure returns (bool) {
    return !isNull(memView);
  }

  /**
   * @notice          Check if the view is of a invalid type and points to a valid location
   *                  in memory.
   * @dev             We perform this check by examining solidity's unallocated memory
   *                  pointer and ensuring that the view's upper bound is less than that.
   * @param memView   The view
   * @return          ret - True if the view is invalid
   */
  function isNotValid(bytes29 memView) internal pure returns (bool ret) {
    if (typeOf(memView) == 0xffffffffff) {
      return true;
    }
    uint256 _end = end(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ret := gt(_end, mload(0x40))
    }
  }

  /**
   * @notice          Require that a typed memory view be valid.
   * @dev             Returns the view for easy chaining.
   * @param memView   The view
   * @return          bytes29 - The validated view
   */
  function assertValid(bytes29 memView) internal pure returns (bytes29) {
    if (isNotValid(memView)) revert TypedMemView__assertValid_validityAssertionFailed();
    return memView;
  }

  /**
   * @notice          Return true if the memview is of the expected type. Otherwise false.
   * @param memView   The view
   * @param _expected The expected type
   * @return          bool - True if the memview is of the expected type
   */
  function isType(bytes29 memView, uint40 _expected) internal pure returns (bool) {
    return typeOf(memView) == _expected;
  }

  /**
   * @notice          Require that a typed memory view has a specific type.
   * @dev             Returns the view for easy chaining.
   * @param memView   The view
   * @param _expected The expected type
   * @return          bytes29 - The view with validated type
   */
  function assertType(bytes29 memView, uint40 _expected) internal pure returns (bytes29) {
    if (!isType(memView, _expected)) {
      revert TypedMemView__assertType_typeAssertionFailed(uint256(typeOf(memView)), uint256(_expected));
    }
    return memView;
  }

  /**
   * @notice          Return an identical view with a different type.
   * @param memView   The view
   * @param _newType  The new type
   * @return          newView - The new view with the specified type
   */
  function castTo(bytes29 memView, uint40 _newType) internal pure returns (bytes29 newView) {
    // then | in the new type
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      // shift off the top 5 bytes
      newView := or(and(memView, LOW_27_BYTES_MASK), shl(_27_BYTES_IN_BITS, _newType))
    }
  }

  /**
   * @notice          Unsafe raw pointer construction. This should generally not be called
   *                  directly. Prefer `ref` wherever possible.
   * @dev             Unsafe raw pointer construction. This should generally not be called
   *                  directly. Prefer `ref` wherever possible.
   * @param _type     The type
   * @param _loc      The memory address
   * @param _len      The length
   * @return          newView - The new view with the specified type, location and length
   */
  function unsafeBuildUnchecked(
    uint256 _type,
    uint256 _loc,
    uint256 _len
  ) private pure returns (bytes29 newView) {
    uint256 _uint96Bits = 96;
    uint256 _emptyBits = 24;

    // Cast params to ensure input is of correct length
    uint96 len_ = uint96(_len);
    uint96 loc_ = uint96(_loc);
    require(len_ == _len && loc_ == _loc, "!truncated");

    assembly {
      // solium-disable-previous-line security/no-inline-assembly
      newView := shl(_uint96Bits, _type) // insert type
      newView := shl(_uint96Bits, or(newView, loc_)) // insert loc
      newView := shl(_emptyBits, or(newView, len_)) // empty bottom 3 bytes
    }
  }

  /**
   * @notice          Instantiate a new memory view. This should generally not be called
   *                  directly. Prefer `ref` wherever possible.
   * @dev             Instantiate a new memory view. This should generally not be called
   *                  directly. Prefer `ref` wherever possible.
   * @param _type     The type
   * @param _loc      The memory address
   * @param _len      The length
   * @return          newView - The new view with the specified type, location and length
   */
  function build(
    uint256 _type,
    uint256 _loc,
    uint256 _len
  ) internal pure returns (bytes29 newView) {
    uint256 _end = _loc + _len;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      if gt(_end, mload(0x40)) {
        _end := 0
      }
    }
    if (_end == 0) {
      return NULL;
    }
    newView = unsafeBuildUnchecked(_type, _loc, _len);
  }

  /**
   * @notice          Instantiate a memory view from a byte array.
   * @dev             Note that due to Solidity memory representation, it is not possible to
   *                  implement a deref, as the `bytes` type stores its len in memory.
   * @param arr       The byte array
   * @param newType   The type
   * @return          bytes29 - The memory view
   */
  function ref(bytes memory arr, uint40 newType) internal pure returns (bytes29) {
    uint256 _len = arr.length;

    uint256 _loc;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      _loc := add(arr, 0x20) // our view is of the data, not the struct
    }

    return build(newType, _loc, _len);
  }

  /**
   * @notice          Return the associated type information.
   * @param memView   The memory view
   * @return          _type - The type associated with the view
   */
  function typeOf(bytes29 memView) internal pure returns (uint40 _type) {
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      // 216 == 256 - 40
      _type := shr(_27_BYTES_IN_BITS, memView) // shift out lower 24 bytes
    }
  }

  /**
   * @notice          Return the memory address of the underlying bytes.
   * @param memView   The view
   * @return          _loc - The memory address
   */
  function loc(bytes29 memView) internal pure returns (uint96 _loc) {
    uint256 _mask = LOW_12_MASK; // assembly can't use globals
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      // 120 bits = 12 bytes (the encoded loc) + 3 bytes (empty low space)
      _loc := and(shr(120, memView), _mask)
    }
  }

  /**
   * @notice          The number of memory words this memory view occupies, rounded up.
   * @param memView   The view
   * @return          uint256 - The number of memory words
   */
  function words(bytes29 memView) internal pure returns (uint256) {
    return (uint256(len(memView)) + 31) / 32;
  }

  /**
   * @notice          The in-memory footprint of a fresh copy of the view.
   * @param memView   The view
   * @return          uint256 - The in-memory footprint of a fresh copy of the view.
   */
  function footprint(bytes29 memView) internal pure returns (uint256) {
    return words(memView) * 32;
  }

  /**
   * @notice          The number of bytes of the view.
   * @param memView   The view
   * @return          _len - The length of the view
   */
  function len(bytes29 memView) internal pure returns (uint96 _len) {
    uint256 _mask = LOW_12_MASK; // assembly can't use globals
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      _len := and(shr(24, memView), _mask)
    }
  }

  /**
   * @notice          Returns the endpoint of `memView`.
   * @param memView   The view
   * @return          uint256 - The endpoint of `memView`
   */
  function end(bytes29 memView) internal pure returns (uint256) {
    unchecked {
      return loc(memView) + len(memView);
    }
  }

  /**
   * @notice          Safe slicing without memory modification.
   * @param memView   The view
   * @param _index    The start index
   * @param _len      The length
   * @param newType   The new type
   * @return          bytes29 - The new view
   */
  function slice(
    bytes29 memView,
    uint256 _index,
    uint256 _len,
    uint40 newType
  ) internal pure returns (bytes29) {
    uint256 _loc = loc(memView);

    // Ensure it doesn't overrun the view
    if (_loc + _index + _len > end(memView)) {
      return NULL;
    }

    _loc = _loc + _index;
    return build(newType, _loc, _len);
  }

  /**
   * @notice          Shortcut to `slice`. Gets a view representing the first `_len` bytes.
   * @param memView   The view
   * @param _len      The length
   * @param newType   The new type
   * @return          bytes29 - The new view
   */
  function prefix(
    bytes29 memView,
    uint256 _len,
    uint40 newType
  ) internal pure returns (bytes29) {
    return slice(memView, 0, _len, newType);
  }

  /**
   * @notice          Shortcut to `slice`. Gets a view representing the last `_len` byte.
   * @param memView   The view
   * @param _len      The length
   * @param newType   The new type
   * @return          bytes29 - The new view
   */
  function postfix(
    bytes29 memView,
    uint256 _len,
    uint40 newType
  ) internal pure returns (bytes29) {
    return slice(memView, uint256(len(memView)) - _len, _len, newType);
  }

  /**
   * @notice          Load up to 32 bytes from the view onto the stack.
   * @dev             Returns a bytes32 with only the `_bytes` highest bytes set.
   *                  This can be immediately cast to a smaller fixed-length byte array.
   *                  To automatically cast to an integer, use `indexUint`.
   * @param memView   The view
   * @param _index    The index
   * @param _bytes    The bytes
   * @return          result - The 32 byte result
   */
  function index(
    bytes29 memView,
    uint256 _index,
    uint8 _bytes
  ) internal pure returns (bytes32 result) {
    if (_bytes == 0) {
      return bytes32(0);
    }
    if (_index + _bytes > len(memView)) {
      // "TypedMemView/index - Overran the view. Slice is at {loc} with length {len}. Attempted to index at offset {index} with length {slice},
      revert TypedMemView__index_overrun(loc(memView), len(memView), _index, uint256(_bytes));
    }
    if (_bytes > 32) revert TypedMemView__index_indexMoreThan32Bytes();

    uint8 bitLength;
    unchecked {
      bitLength = _bytes * 8;
    }
    uint256 _loc = loc(memView);
    uint256 _mask = leftMask(bitLength);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      result := and(mload(add(_loc, _index)), _mask)
    }
  }

  /**
   * @notice          Parse an unsigned integer from the view at `_index`.
   * @dev             Requires that the view have >= `_bytes` bytes following that index.
   * @param memView   The view
   * @param _index    The index
   * @param _bytes    The bytes
   * @return          result - The unsigned integer
   */
  function indexUint(
    bytes29 memView,
    uint256 _index,
    uint8 _bytes
  ) internal pure returns (uint256 result) {
    return uint256(index(memView, _index, _bytes)) >> ((32 - _bytes) * 8);
  }

  /**
   * @notice          Parse an unsigned integer from LE bytes.
   * @param memView   The view
   * @param _index    The index
   * @param _bytes    The bytes
   * @return          result - The unsigned integer
   */
  function indexLEUint(
    bytes29 memView,
    uint256 _index,
    uint8 _bytes
  ) internal pure returns (uint256 result) {
    return reverseUint256(uint256(index(memView, _index, _bytes)));
  }

  /**
   * @notice          Parse an address from the view at `_index`. Requires that the view have >= 20 bytes
   *                  following that index.
   * @param memView   The view
   * @param _index    The index
   * @return          address - The address
   */
  function indexAddress(bytes29 memView, uint256 _index) internal pure returns (address) {
    return address(uint160(indexUint(memView, _index, 20)));
  }

  /**
   * @notice          Return the keccak256 hash of the underlying memory
   * @param memView   The view
   * @return          digest - The keccak256 hash of the underlying memory
   */
  function keccak(bytes29 memView) internal pure returns (bytes32 digest) {
    uint256 _loc = loc(memView);
    uint256 _len = len(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      digest := keccak256(_loc, _len)
    }
  }

  /**
   * @notice          Return true if the underlying memory is equal. Else false.
   * @param left      The first view
   * @param right     The second view
   * @return          bool - True if the underlying memory is equal
   */
  function untypedEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
    return (loc(left) == loc(right) && len(left) == len(right)) || keccak(left) == keccak(right);
  }

  /**
   * @notice          Return false if the underlying memory is equal. Else true.
   * @param left      The first view
   * @param right     The second view
   * @return          bool - False if the underlying memory is equal
   */
  function untypedNotEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
    return !untypedEqual(left, right);
  }

  /**
   * @notice          Compares type equality.
   * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
   * @param left      The first view
   * @param right     The second view
   * @return          bool - True if the types are the same
   */
  function equal(bytes29 left, bytes29 right) internal pure returns (bool) {
    return left == right || (typeOf(left) == typeOf(right) && keccak(left) == keccak(right));
  }

  /**
   * @notice          Compares type inequality.
   * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
   * @param left      The first view
   * @param right     The second view
   * @return          bool - True if the types are not the same
   */
  function notEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
    return !equal(left, right);
  }

  /**
   * @notice          Copy the view to a location, return an unsafe memory reference
   * @dev             Super Dangerous direct memory access.
   *
   *                  This reference can be overwritten if anything else modifies memory (!!!).
   *                  As such it MUST be consumed IMMEDIATELY.
   *                  This function is private to prevent unsafe usage by callers.
   * @param memView   The view
   * @param _newLoc   The new location
   * @return          written - the unsafe memory reference
   */
  function unsafeCopyTo(bytes29 memView, uint256 _newLoc) private view returns (bytes29 written) {
    if (isNull(memView)) revert TypedMemView__unsafeCopyTo_nullPointer();
    if (isNotValid(memView)) revert TypedMemView__unsafeCopyTo_invalidPointer();

    uint256 _len = len(memView);
    uint256 _oldLoc = loc(memView);

    uint256 ptr;
    bool res;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ptr := mload(0x40)
      // revert if we're writing in occupied memory
      if gt(ptr, _newLoc) {
        revert(0x60, 0x20) // empty revert message
      }

      // use the identity precompile to copy
      // guaranteed not to fail, so pop the success
      res := staticcall(gas(), 4, _oldLoc, _len, _newLoc, _len)
    }
    if (!res) revert TypedMemView__unsafeCopyTo_identityOOG();
    written = unsafeBuildUnchecked(typeOf(memView), _newLoc, _len);
  }

  /**
   * @notice          Copies the referenced memory to a new loc in memory, returning a `bytes` pointing to
   *                  the new memory
   * @dev             Shortcuts if the pointers are identical, otherwise compares type and digest.
   * @param memView   The view
   * @return          ret - The view pointing to the new memory
   */
  function clone(bytes29 memView) internal view returns (bytes memory ret) {
    uint256 ptr;
    uint256 _len = len(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ptr := mload(0x40) // load unused memory pointer
      ret := ptr
    }
    unchecked {
      unsafeCopyTo(memView, ptr + 0x20);
    }
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      mstore(0x40, add(add(ptr, _len), 0x20)) // write new unused pointer
      mstore(ptr, _len) // write len of new array (in bytes)
    }
  }

  /**
   * @notice          Join the views in memory, return an unsafe reference to the memory.
   * @dev             Super Dangerous direct memory access.
   *
   *                  This reference can be overwritten if anything else modifies memory (!!!).
   *                  As such it MUST be consumed IMMEDIATELY.
   *                  This function is private to prevent unsafe usage by callers.
   * @param memViews  The views
   * @return          unsafeView - The conjoined view pointing to the new memory
   */
  function unsafeJoin(bytes29[] memory memViews, uint256 _location) private view returns (bytes29 unsafeView) {
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      let ptr := mload(0x40)
      // revert if we're writing in occupied memory
      if gt(ptr, _location) {
        revert(0x60, 0x20) // empty revert message
      }
    }

    uint256 _offset = 0;
    uint256 _len = memViews.length;
    for (uint256 i = 0; i < _len; ) {
      bytes29 memView = memViews[i];
      unchecked {
        unsafeCopyTo(memView, _location + _offset);
        _offset += len(memView);
        ++i;
      }
    }
    unsafeView = unsafeBuildUnchecked(0, _location, _offset);
  }

  /**
   * @notice          Produce the keccak256 digest of the concatenated contents of multiple views.
   * @param memViews  The views
   * @return          bytes32 - The keccak256 digest
   */
  function joinKeccak(bytes29[] memory memViews) internal view returns (bytes32) {
    uint256 ptr;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ptr := mload(0x40) // load unused memory pointer
    }
    return keccak(unsafeJoin(memViews, ptr));
  }

  /**
   * @notice          copies all views, joins them into a new bytearray.
   * @param memViews  The views
   * @return          ret - The new byte array
   */
  function join(bytes29[] memory memViews) internal view returns (bytes memory ret) {
    uint256 ptr;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ptr := mload(0x40) // load unused memory pointer
    }

    bytes29 _newView;
    unchecked {
      _newView = unsafeJoin(memViews, ptr + 0x20);
    }
    uint256 _written = len(_newView);
    uint256 _footprint = footprint(_newView);

    assembly {
      // solhint-disable-previous-line no-inline-assembly
      // store the legnth
      mstore(ptr, _written)
      // new pointer is old + 0x20 + the footprint of the body
      mstore(0x40, add(add(ptr, _footprint), 0x20))
      ret := ptr
    }
  }
}
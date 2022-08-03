/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

enum Side {
    LONG,
    SHORT
}

interface IPositionManager {
    function increasePosition(
        address _account,
        address _indexToken,
        uint256 _sizeChanged,
        Side _side
    ) external;

    function decreasePosition(
        address _account,
        address _indexToken,
        uint256 _desiredCollateralReduce,
        uint256 _sizeChanged,
        Side _side
    ) external;

    function liquidatePosition(
        address account,
        address collateralToken,
        address market,
        bool isLong
    ) external;

    function validateToken(
        address indexToken,
        Side side,
        address collateralToken
    ) external view returns (bool);
}

uint256 constant FEE_PRECISION = 1e10;
uint256 constant INTEREST_RATE_PRECISION = 1e10;
uint256 constant MAX_POSITION_FEE = 1e8; // 1%

struct Fee {
    /// @notice charge when changing position size
    uint256 positionFee;
    /// @notice charge when liquidate position (in dollar)
    uint256 liquidationFee;
    /// @notice fee reserved rate for admin
    uint256 adminFee;
    /// @notice interest rate when borrow token to leverage
    uint256 interestRate;
    uint256 accrualInterval;
    uint256 lastAccrualTimestamp;
    /// @notice cumulated interest rate, update on epoch
    uint256 cumulativeInterestRate;
}

library FeeUtils {
    function calcInterest(
        Fee memory self,
        uint256 entryCumulativeInterestRate,
        uint256 size
    ) internal pure returns (uint256) {
        return (size * (self.cumulativeInterestRate - entryCumulativeInterestRate)) / INTEREST_RATE_PRECISION;
    }

    function calcPositionFee(Fee memory self, uint256 sizeChanged) internal pure returns (uint256) {
        return (sizeChanged * self.positionFee) / FEE_PRECISION;
    }

    function calcAdminFee(Fee memory self, uint256 feeAmount) internal pure returns (uint256) {
        return (feeAmount * self.adminFee) / FEE_PRECISION;
    }

    function cumulativeInterest(Fee storage self) internal {
        uint256 _now = block.timestamp;
        if (self.lastAccrualTimestamp == 0) {
            // accrue interest for the first time
            self.lastAccrualTimestamp = _now;
            return;
        }

        if (self.lastAccrualTimestamp + self.accrualInterval > _now) {
            return;
        }

        uint256 nInterval = (_now - self.lastAccrualTimestamp) / self.accrualInterval;
        self.cumulativeInterestRate += nInterval * self.interestRate;
        self.lastAccrualTimestamp += nInterval * self.accrualInterval;
    }

    function setInterestRate(
        Fee storage self,
        uint256 interestRate,
        uint256 accrualInterval
    ) internal {
        self.accrualInterval = accrualInterval;
        self.interestRate = interestRate;
    }

    function setFee(
        Fee storage self,
        uint256 positionFee,
        uint256 liquidationFee,
        uint256 adminFee
    ) internal {
        require(positionFee <= MAX_POSITION_FEE, "Fee: max position fee exceeded");
        self.positionFee = positionFee;
        self.liquidationFee = liquidationFee;
        self.adminFee = adminFee;
    }
}

uint256 constant POS = 1;
uint256 constant NEG = 0;

/// SignedInt is integer number with sign. It value range is -(2 ^ 256 - 1) to (2 ^ 256 - 1)
struct SignedInt {
    /// @dev sig = 0 -> positive, sig = 1 is negative
    /// using uint256 which take up full word to optimize gas and contract size
    uint256 sig;
    uint256 abs;
}

library SignedIntOps {
    function add(SignedInt memory a, SignedInt memory b)
        internal
        pure
        returns (SignedInt memory)
    {
        if (a.sig == b.sig) {
            return SignedInt({sig: a.sig, abs: a.abs + b.abs});
        }

        if (a.abs == b.abs) {
            return SignedInt(0, 0); // always return positive zero
        }

        (uint256 sig, uint256 abs) = a.abs > b.abs
            ? (a.sig, a.abs - b.abs)
            : (b.sig, b.abs - a.abs);
        return SignedInt(sig, abs);
    }

    function inv(SignedInt memory a) internal pure returns (SignedInt memory) {
        return a.abs == 0 ? a : (SignedInt({sig: 1 - a.sig, abs: a.abs}));
    }

    function sub(SignedInt memory a, SignedInt memory b)
        internal
        pure
        returns (SignedInt memory)
    {
        return add(a, inv(b));
    }

    function mul(SignedInt memory a, SignedInt memory b)
        internal
        pure
        returns (SignedInt memory)
    {
        uint256 sig = (a.sig + b.sig + 1) % 2;
        uint256 abs = a.abs * b.abs;
        return SignedInt(abs == 0 ? POS : sig, abs); // zero is alway positive
    }

    function div(SignedInt memory a, SignedInt memory b)
        internal
        pure
        returns (SignedInt memory)
    {
        uint256 sig = (a.sig + b.sig + 1) % 2;
        uint256 abs = a.abs / b.abs;
        return SignedInt(sig, abs);
    }

    function add(SignedInt memory a, uint256 b)
        internal
        pure
        returns (SignedInt memory)
    {
        return add(a, wrap(b));
    }

    function sub(SignedInt memory a, uint256 b)
        internal
        pure
        returns (SignedInt memory)
    {
        return sub(a, wrap(b));
    }

    function add(SignedInt memory a, int256 b)
        internal
        pure
        returns (SignedInt memory)
    {
        return add(a, wrap(b));
    }

    function sub(SignedInt memory a, int256 b)
        internal
        pure
        returns (SignedInt memory)
    {
        return sub(a, wrap(b));
    }

    function mul(SignedInt memory a, uint256 b)
        internal
        pure
        returns (SignedInt memory)
    {
        return mul(a, wrap(b));
    }

    function mul(SignedInt memory a, int256 b)
        internal
        pure
        returns (SignedInt memory)
    {
        return mul(a, wrap(b));
    }

    function div(SignedInt memory a, uint256 b)
        internal
        pure
        returns (SignedInt memory)
    {
        return div(a, wrap(b));
    }

    function div(SignedInt memory a, int256 b)
        internal
        pure
        returns (SignedInt memory)
    {
        return div(a, wrap(b));
    }

    function wrap(int256 a) internal pure returns (SignedInt memory) {
        return a >= 0 ? SignedInt(POS, uint256(a)) : SignedInt(NEG, uint256(-a));
    }

    function wrap(uint256 a) internal pure returns (SignedInt memory) {
        return SignedInt(POS, a);
    }

    function toUint(SignedInt memory a) internal pure returns (uint256) {
        require(a.sig == POS, "SignedInt: below zero");
        return a.abs;
    }

    function lt(SignedInt memory a, SignedInt memory b)
        internal
        pure
        returns (bool)
    {
        return a.sig > b.sig || a.abs < b.abs;
    }

    function lt(SignedInt memory a, uint256 b) internal pure returns (bool) {
        return a.sig == NEG || a.abs < b;
    }

    function lt(SignedInt memory a, int256 b) internal pure returns (bool) {
        return lt(a, wrap(b));
    }

    function gt(SignedInt memory a, SignedInt memory b)
        internal
        pure
        returns (bool)
    {
        return a.sig < b.sig || a.abs > b.abs;
    }

    function gt(SignedInt memory a, int256 b) internal pure returns (bool) {
        return b < 0 || a.abs > uint256(b);
    }

    function gt(SignedInt memory a, uint256 b) internal pure returns (bool) {
        return lt(a, wrap(b));
    }

    function isNeg(SignedInt memory a) internal pure returns (bool) {
        return a.sig == NEG;
    }
    function isPos(SignedInt memory a) internal pure returns (bool) {
        return a.sig == POS;
    }

    function eq(SignedInt memory a, SignedInt memory b) internal pure returns (bool) {
        return a.abs == b.abs && a.sig == b.sig;
    }

    function eq(SignedInt memory a, uint b) internal pure returns (bool) {
        return eq(a, wrap(b));
    }

    function eq(SignedInt memory a, int b) internal pure returns (bool) {
        return eq(a, wrap(b));
    }
}

uint256 constant MAX_LEVERAGE = 30;

struct Position {
    /// @dev contract size is evaluated in dollar
    uint256 size;
    /// @dev collateral value in dollar
    uint256 collateralValue;
    /// @dev contract size in indexToken
    uint256 reserveAmount;
    /// @dev average entry price
    uint256 entryPrice;
    /// @dev last cumulative interest rate
    uint256 entryInterestRate;
}

struct IncreasePositionResult {
    uint256 reserveAdded;
    uint256 collateralValueAdded;
    uint256 feeValue;
    uint256 adminFee;
}

struct DecreasePositionResult {
    uint256 collateralValueReduced;
    uint256 reserveReduced;
    uint256 feeValue;
    uint256 adminFee;
    uint256 liquidationFee;
    uint256 payout;
    SignedInt pnl;
}

library PositionUtils {
    using SignedIntOps for SignedInt;
    using FeeUtils for Fee;

    /// @notice increase position size and/or collateral
    /// @param position position to update
    /// @param fee fee config
    /// @param side long or shor
    /// @param sizeChanged value in USD
    /// @param collateralAmount value in USD
    /// @param indexPrice price of index token
    /// @param collateralPrice price of collateral token
    function increase(
        Position storage position,
        Fee memory fee,
        Side side,
        uint256 sizeChanged,
        uint256 collateralAmount,
        uint256 indexPrice,
        uint256 collateralPrice
    ) internal returns (IncreasePositionResult memory result) {
        result.collateralValueAdded = collateralPrice * collateralAmount;
        result.feeValue =
            fee.calcInterest(position.entryInterestRate, position.size) +
            fee.calcPositionFee(sizeChanged);
        result.adminFee = fee.calcAdminFee(result.feeValue) / collateralPrice;
        require(
            position.collateralValue + result.collateralValueAdded > result.feeValue,
            "Position: increase cause liquidation"
        );

        result.reserveAdded = sizeChanged / indexPrice;

        position.entryPrice = calcAveragePrice(side, position.size, sizeChanged, position.entryPrice, indexPrice);
        position.collateralValue = position.collateralValue + result.collateralValueAdded - result.feeValue;
        position.size = position.size + sizeChanged;
        position.entryInterestRate = fee.cumulativeInterestRate;
        position.reserveAmount += result.reserveAdded;

        validatePosition(position, false, MAX_LEVERAGE);
        validateLiquidation(position, fee, side, indexPrice);
    }

    /// @notice decrease position size and/or collateral
    /// @param collateralChanged collateral value in $ to reduce
    function decrease(
        Position storage position,
        Fee memory fee,
        Side side,
        uint256 sizeChanged,
        uint256 collateralChanged,
        uint256 indexPrice,
        uint256 collateralPrice
    ) internal returns (DecreasePositionResult memory result) {
        result = decreaseUnchecked(position, fee, side, sizeChanged, collateralChanged, indexPrice, collateralPrice);
        validatePosition(position, false, MAX_LEVERAGE);
        validateLiquidation(position, fee, side, indexPrice);
    }

    function liquidate(
        Position storage position,
        Fee memory fee,
        Side side,
        uint256 indexPrice,
        uint256 collateralPrice
    ) internal returns (DecreasePositionResult memory result) {
        (bool allowed, , , ) = liquidatePositionAllowed(position, fee, side, indexPrice);
        require(allowed, "Position: can not liquidate");
        result = decreaseUnchecked(position, fee, side, position.size, 0, indexPrice, collateralPrice);
        assert(position.size == 0); // double check
        assert(position.collateralValue == 0);
    }

    function decreaseUnchecked(
        Position storage position,
        Fee memory fee,
        Side side,
        uint256 sizeChanged,
        uint256 collateralChanged,
        uint256 indexPrice,
        uint256 collateralPrice
    ) internal returns (DecreasePositionResult memory result) {
        require(position.size >= sizeChanged, "Position: decrease too much");
        require(position.collateralValue >= collateralChanged, "Position: reduce collateral too much");

        result.reserveReduced = (position.reserveAmount * sizeChanged) / position.size;
        collateralChanged = collateralChanged > 0
            ? collateralChanged
            : (position.collateralValue * sizeChanged) / position.size;

        result.pnl = calcPnl(side, sizeChanged, position.entryPrice, indexPrice);
        result.feeValue =
            fee.calcInterest(position.entryInterestRate, position.size) +
            fee.calcPositionFee(sizeChanged);
        result.adminFee = fee.calcAdminFee(result.feeValue) / collateralPrice;
        result.liquidationFee = fee.liquidationFee / collateralPrice;

        SignedInt memory payoutValue = result.pnl.add(collateralChanged).sub(result.feeValue);
        SignedInt memory collateral = SignedIntOps.wrap(position.collateralValue).sub(collateralChanged);
        if (payoutValue.isNeg()) {
            // deduct uncovered lost from collateral
            collateral = collateral.add(payoutValue);
        }

        uint256 collateralValue = collateral.isNeg() ? 0 : collateral.abs;
        result.collateralValueReduced = position.collateralValue - collateralValue;
        position.collateralValue = collateralValue;
        position.size = position.size - sizeChanged;
        position.entryInterestRate = fee.cumulativeInterestRate;
        position.reserveAmount = position.reserveAmount - result.reserveReduced;
        result.payout = payoutValue.isNeg() ? 0 : payoutValue.abs / collateralPrice;
    }

    /// @notice calculate new avg entry price when increase position
    /// @dev for longs: nextAveragePrice = (nextPrice * nextSize)/ (nextSize + delta)
    ///      for shorts: nextAveragePrice = (nextPrice * nextSize) / (nextSize - delta)
    function calcAveragePrice(
        Side side,
        uint256 lastSize,
        uint256 increasedSize,
        uint256 entryPrice,
        uint256 nextPrice
    ) internal pure returns (uint256) {
        if (lastSize == 0) {
            return nextPrice;
        }
        SignedInt memory pnl = calcPnl(side, lastSize, entryPrice, nextPrice);
        SignedInt memory nextSize = SignedIntOps.wrap(lastSize + increasedSize);
        SignedInt memory divisor = side == Side.LONG ? nextSize.add(pnl) : nextSize.sub(pnl);
        return nextSize.mul(nextPrice).div(divisor).toUint();
    }

    function calcPnl(
        Side side,
        uint256 positionSize,
        uint256 entryPrice,
        uint256 indexPrice
    ) internal pure returns (SignedInt memory) {
        if (positionSize == 0) {
            return SignedIntOps.wrap(uint256(0));
        }
        if (side == Side.LONG) {
            return SignedIntOps.wrap(indexPrice).sub(entryPrice).mul(positionSize).div(entryPrice);
        } else {
            return SignedIntOps.wrap(entryPrice).sub(indexPrice).mul(positionSize).div(entryPrice);
        }
    }

    function validateLiquidation(
        Position storage position,
        Fee memory fee,
        Side side,
        uint256 indexPrice
    ) internal view {
        (bool liquidated, , , ) = liquidatePositionAllowed(position, fee, side, indexPrice);
        require(!liquidated, "Position: liquidated");
    }

    function validatePosition(
        Position storage position,
        bool isIncrease,
        uint256 maxLeverage
    ) internal view {
        if (isIncrease) {
            require(position.size >= 0, "Position: invalid size");
        }
        require(position.size >= position.collateralValue, "Position: invalid leverage");
        require(position.size <= position.collateralValue * maxLeverage, "POSITION: max leverage exceeded");
    }

    function liquidatePositionAllowed(
        Position storage position,
        Fee memory fee,
        Side side,
        uint256 indexPrice
    )
        internal
        view
        returns (
            bool allowed,
            uint256 feeValue,
            uint256 remainingCollateralValue,
            SignedInt memory pnl
        )
    {
        if (position.size == 0) {
            return (false, 0, 0, SignedIntOps.wrap(uint256(0)));
        }
        // calculate fee needed when close position
        feeValue =
            fee.calcInterest(position.entryInterestRate, position.size) +
            fee.calcPositionFee(position.size) +
            fee.liquidationFee;

        pnl = calcPnl(side, position.size, position.entryPrice, indexPrice);

        SignedInt memory remainingCollateral = pnl.add(position.collateralValue).sub(feeValue);

        (allowed, remainingCollateralValue) = remainingCollateral.isNeg()
            ? (true, 0)
            : (false, remainingCollateral.abs);
    }
}

library UniERC20 {
    using SafeERC20 for IERC20;
    /// @notice pseudo address to use inplace of native token
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function getBalance(IERC20 token, address holder)
        internal
        view
        returns (uint256)
    {
        if (isETH(token)) {
            return holder.balance;
        }
        return token.balanceOf(holder);
    }

    function transferTo(
        IERC20 token,
        address receiver,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }
        if (isETH(token)) {
            safeTransferETH(receiver, amount);
        } else {
            token.safeTransfer(receiver, amount);
        }
    }

    function isETH(IERC20 token) internal pure returns (bool) {
        return address(token) == ETH;
    }

    function safeTransferETH(address to, uint256 amount) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = to.call{value: amount}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

struct PoolAsset {
    /// @notice amount of token deposited (via add liquidity or increase long position)
    uint256 poolAmount;
    /// @notice amount of token reserved for paying out when user decrease long position
    uint256 reservedAmount;
    /// @notice amount reserved for fee
    uint256 feeReserve;
    /// @notice total borrowed (in USD) to leverage
    uint256 guaranteedValue;
    /// @notice total size of all short positions
    uint256 totalShortSize;
    /// @notice average entry price of all short position
    uint256 averageShortPrice;
    /// @notice recorded balance of token in pool
    uint256 poolBalance;
}

library PoolAssetImpl {
    using SignedIntOps for SignedInt;

    /// @notice increase reserve when increase position
    /// fee also taken to fee reserve
    function increaseReserve(
        PoolAsset storage self,
        uint256 reserveAdded,
        uint256 feeAmount
    ) internal {
        self.reservedAmount += reserveAdded;
        require(self.reservedAmount <= self.poolAmount, "PoolAsset: reserve exceed pool amount");
        self.feeReserve += feeAmount;
    }

    function decreaseReserve(
        PoolAsset storage self,
        uint256 reserveReduced,
        uint256 feeAmount
    ) internal {
        require(self.reservedAmount >= reserveReduced, "Position: reserve reduce too much");
        self.reservedAmount -= reserveReduced;
        self.feeReserve += feeAmount;
    }

    /// @notice recalculate global LONG position for collateral asset
    function increaseLongPosition(
        PoolAsset storage self,
        uint256 sizeChanged,
        uint256 collateralAmountIn,
        uint256 collateralValueIn,
        uint256 adminFee,
        uint256 feeValue
    ) internal {
        // remember pool amounts is amount of collateral token
        // the fee is deducted from collateral in, so we reduce it from poolAmount and guaranteed value
        self.poolAmount = self.poolAmount + collateralAmountIn - adminFee;
        // ajust guaranteed
        self.guaranteedValue = self.guaranteedValue + sizeChanged + feeValue - collateralValueIn;
    }

    /// @notice recalculate global short position for index asset
    function increaseShortPosition(
        PoolAsset storage self,
        uint256 sizeChanged,
        uint256 indexPrice
    ) internal {
        // recalculate total short position
        uint256 lastSize = self.totalShortSize;
        uint256 entryPrice = self.averageShortPrice;
        self.averageShortPrice = PositionUtils.calcAveragePrice(Side.SHORT, lastSize, sizeChanged, entryPrice, indexPrice);
        self.totalShortSize = lastSize + sizeChanged;
    }

    function decreaseLongPosition(
        PoolAsset storage self,
        uint256 collateralChanged,
        uint256 sizeChanged,
        uint256 payoutAmount,
        uint256 adminFee
    ) internal {
        // update guaranteed
        // guaranteed = size - collateral
        // NOTE: collateralChanged is fee excluded
        self.guaranteedValue = self.guaranteedValue + collateralChanged - sizeChanged;
        self.poolAmount -= payoutAmount + adminFee;
    }

    function decreaseShortPosition(
        PoolAsset storage self,
        SignedInt memory pnl,
        uint256 sizeChanged
    ) internal {
        SignedInt memory poolAmount = pnl.add(self.poolAmount);
        self.poolAmount = poolAmount.isNeg() ? 0 : poolAmount.abs;
        // update short position
        self.totalShortSize -= sizeChanged;
    }

    function calcManagedValue(PoolAsset storage self, uint256 price) internal view returns (SignedInt memory aum) {
        SignedInt memory shortPnl = self.totalShortSize == 0
            ? SignedIntOps.wrap(uint256(0))
            : SignedIntOps.wrap(self.averageShortPrice).sub(price).mul(self.totalShortSize).div(self.averageShortPrice);

        aum = SignedIntOps.wrap(self.poolAmount).sub(self.reservedAmount).mul(price).add(self.guaranteedValue);
        aum = aum.sub(shortPnl);
    }

    function increasePoolAmount(PoolAsset storage self, uint256 amount) internal {
        self.poolAmount += amount;
    }

    function decreasePoolAmount(PoolAsset storage self, uint256 amount) internal {
        self.poolAmount -= amount;
        require(self.poolAmount >= self.reservedAmount, "PoolAsset: reduce pool amount too much");
    }
}

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

/// @title IOracle
/// @notice Read price of various token
interface IOracle {
    function getPrice(address token) external view returns (uint256);
}

interface ILPToken is IERC20 {
    function mint(address to, uint amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// Precision used for USD value
// Oracle MUST return price with decimals of (decimal_of_this_precision - token_decimals)
uint256 constant VALUE_PRECISION = 1e30;

/// @title AssetManager
/// @notice Liquitidy controling and risk management
abstract contract AssetManager is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;
    using UniERC20 for IERC20;
    using SignedIntOps for SignedInt;
    using PoolAssetImpl for PoolAsset;

    uint256 constant LP_INITIAL_PRICE = 1e12; // init set to 1$

    IOracle public oracle;
    /// @notice stablecoin used as collateral for SHORT position
    address public stableToken;
    /// @notice A list of all whitelisted tokens
    mapping(address => bool) public whitelistedTokens;
    address[] public allWhitelistedTokens;
    mapping(address => PoolAsset) public poolAssets;
    /// @notice liquidtiy provider token
    ILPToken private lpToken;

    function AssetManager__initialize(address _lpToken, address _stableToken) internal {
        __Ownable_init();
        __ReentrancyGuard_init();
        // require(_weth != address(0), "Configuration: invalid WETH address");
        require(_stableToken != address(0), "AssetManager: invalid stable token address");
        require(_lpToken != address(0), "AssetManager: invalid LP token address");
        whitelistedTokens[_stableToken] = true;
        allWhitelistedTokens.push(_stableToken);
        // weth = _weth;
        stableToken = _stableToken;
        lpToken = ILPToken(_lpToken);
    }

    // =========== View functions ===========
    /// @notice get total value in USD of all (whitelisted) tokens in pool
    /// with profit and lost from all opening position
    /// @dev since oracle return price in precision of 10 ^ (30 - token decimals)
    /// this function will returns dollar value with decimals of 30
    function getPoolValue() external view returns (uint256) {
        return _getPoolValue();
    }

    // =========== Administrative ===========

    function addToken(address _token) external onlyOwner {
        require(!whitelistedTokens[_token], "AssetManager: token alread added");
        whitelistedTokens[_token] = true;
        allWhitelistedTokens.push(_token);
        emit TokenWhitelisted(_token);
    }

    function setOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0), "LiquidityManager::address0");
        address oldOracle = address(oracle);
        oracle = IOracle(_oracle);
        emit OracleChanged(oldOracle, _oracle);
    }

    // =========== Mutative functions ============
    function addLiquidity(
        address token,
        uint256 amount,
        uint256 minLpAmount,
        address to
    ) external payable nonReentrant {
        _requireWhitelisted(token);
        if (token != UniERC20.ETH) {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        } else {
            require(msg.value == amount, "AssetManager: invalid value sent");
        }
        _addLiquidity(token, minLpAmount, to);
    }

    function removeLiquidity(
        address tokenOut,
        uint256 lpAmount,
        uint256 minOut,
        address to
    ) external nonReentrant {
        _requireWhitelisted(tokenOut);
        require(lpAmount > 0, "AssetManager: LP amount is zero");
        uint256 totalPoolValue = _getPoolValue();
        uint256 totalSupply = lpToken.totalSupply();
        uint256 tokenOutPrice = oracle.getPrice(tokenOut);
        uint256 outAmount = (lpAmount * totalPoolValue) / totalSupply / tokenOutPrice;
        require(outAmount >= minOut, "LiquidityManager::slippage");
        poolAssets[tokenOut].decreasePoolAmount(outAmount);
        // use permit token maybe
        lpToken.burnFrom(msg.sender, lpAmount);
        IERC20(tokenOut).transferTo(to, outAmount);
    }

    // ========= internal functions =========
    function _requireWhitelisted(address token) internal virtual {
        require(whitelistedTokens[token], "Configuration: token not whitelisted");
    }

    function _getAmountIn(address token) internal returns (uint256 amount) {
        _requireWhitelisted(token);
        uint256 balance = IERC20(token).getBalance(address(this));
        amount = balance - poolAssets[token].poolBalance;
        poolAssets[token].poolBalance = balance;
    }

    function _doTransferOut(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount > 0) {
            IERC20 token = IERC20(_token);
            token.transferTo(_to, _amount);
            poolAssets[_token].poolBalance = token.getBalance(address(this));
        }
    }

    function _addLiquidity(
        address token,
        uint256 minLpAmount,
        address to
    ) internal {
        uint256 amountIn = _getAmountIn(token);
        if (amountIn == 0) {
            return;
        }
        uint256 lpAmount = _calcLpAmount(token, amountIn);
        require(lpAmount >= minLpAmount, "LPManager::>slippage");
        lpToken.mint(to, lpAmount);
        poolAssets[token].increasePoolAmount(amountIn);
    }

    function _calcLpAmount(address token, uint256 amount) internal view returns (uint256) {
        uint256 tokenPrice = oracle.getPrice(token);
        require(tokenPrice > 0, "priceNotAvailable");
        uint256 poolValue = _getPoolValue();
        uint256 lpSupply = lpToken.totalSupply();
        if (lpSupply == 0) {
            return (amount * tokenPrice) / LP_INITIAL_PRICE;
        }
        return (amount * tokenPrice * lpSupply) / poolValue;
    }

    function _getPoolValue() internal view returns (uint256 sum) {
        SignedInt memory aum = SignedIntOps.wrap(uint256(0));

        for (uint256 i = 0; i < allWhitelistedTokens.length; i++) {
            address token = allWhitelistedTokens[i];
            assert(whitelistedTokens[token]); // double check
            PoolAsset storage asset = poolAssets[token];
            uint256 price = _getPrice(token);
            if (token == stableToken) {
                aum = aum.add(asset.poolAmount * price);
            } else {
                aum = aum.add(asset.calcManagedValue(price));
            }
        }

        // aum MUST not be negative. If it is, please debug
        return aum.toUint();
    }

    function _getPrice(address token) internal view returns (uint256 price) {
        price = oracle.getPrice(token);
        require(price > 0, "PositionManager: token price not available");
    }

    // ======= Events =======
    event TokenWhitelisted(address token);
    event OracleChanged(address oldOracle, address newOracle);
}

abstract contract PositionManager is AssetManager {
    using PositionUtils for Position;
    using SignedIntOps for SignedInt;
    using FeeUtils for Fee;
    using SafeERC20 for IERC20;
    using UniERC20 for IERC20;
    using PoolAssetImpl for PoolAsset;

    Fee public fee;

    /// @notice positions tracks all open positions
    mapping(bytes32 => Position) public positions;
    mapping(address => uint256) public maxLeverages;
    address public orderBook;

    modifier onlyOrderBook() {
        require(msg.sender == orderBook, "PositionManager: only orderbook allowed");
        _;
    }

    function PositionManager__initialize(
        uint256 _positionFee,
        uint256 _liquidationFee,
        uint256 _adminFee,
        uint256 _interestRate,
        uint256 _accrualInterval
    ) internal {
        fee.positionFee = _positionFee;
        fee.liquidationFee = _liquidationFee;
        fee.adminFee = _adminFee;
        fee.interestRate = _interestRate;
        fee.accrualInterval = _accrualInterval;
    }

    /* ========= VIEW FUNCTIONS ========= */

    function validateToken(
        address _indexToken,
        Side _side,
        address _collateralToken
    ) external view returns (bool) {
        return _collateralToken == getCollateralToken(_side, _indexToken);
    }

    struct PositionView {
        uint256 size;
        uint256 collateralValue;
        uint256 entryPrice;
        uint256 pnl;
        uint256 reserveAmount;
        bool hasProfit;
    }

    function getPosition(
        address _owner,
        address _indexToken,
        Side _side
    ) external view returns (PositionView memory result) {
        address collateralToken = getCollateralToken(_side, _indexToken);
        bytes32 positionKey = getPositionKey(_owner, _indexToken, collateralToken, _side);
        Position memory position = positions[positionKey];
        uint256 indexPrice = _getPrice(_indexToken);
        SignedInt memory pnl = PositionUtils.calcPnl(_side, position.size, position.entryPrice, indexPrice);

        result.size = position.size;
        result.collateralValue = position.collateralValue;
        result.pnl = pnl.abs;
        result.hasProfit = pnl.gt(uint256(0));
        result.entryPrice = position.entryPrice;
        result.reserveAmount = position.reserveAmount;
    }

    /* ========= MUTATIVE FUNCTIONS ======= */
    /// @notice increase position long or short
    /// @dev in case of long position, we keep index token as collateral
    /// in case of short position, we keep stable coin as collateral
    function increasePosition(
        address _account,
        address _indexToken,
        uint256 _sizeChanged,
        Side _side
    ) external onlyOrderBook {
        fee.cumulativeInterest();
        address _collateralToken = getCollateralToken(_side, _indexToken);
        uint256 indexPrice = _getPrice(_indexToken);
        uint256 collateralPrice = _getPrice(_collateralToken);
        uint256 collateralAmount = _getAmountIn(_collateralToken);

        bytes32 positionKey = getPositionKey(_account, _indexToken, _collateralToken, _side);
        Position storage position = positions[positionKey];

        // increase position
        IncreasePositionResult memory result = position.increase(
            fee,
            _side,
            _sizeChanged,
            collateralAmount,
            indexPrice,
            collateralPrice
        );
        poolAssets[_collateralToken].increaseReserve(result.reserveAdded, result.adminFee);

        // update asset based on position changed
        if (_side == Side.LONG) {
            poolAssets[_collateralToken].increaseLongPosition(
                _sizeChanged,
                collateralAmount,
                result.collateralValueAdded,
                result.adminFee,
                result.feeValue
            );
        } else {
            poolAssets[_indexToken].increaseShortPosition(_sizeChanged, indexPrice);
        }

        emit IncreasePosition(
            positionKey,
            _account,
            _collateralToken,
            _indexToken,
            collateralAmount,
            _sizeChanged,
            _side,
            indexPrice,
            result.feeValue
        );

        emit UpdatePosition(
            positionKey,
            position.size,
            position.collateralValue,
            position.entryPrice,
            position.entryInterestRate,
            position.reserveAmount,
            indexPrice
        );
    }

    /// @notice decrease position long or short
    function decreasePosition(
        address _account,
        address _indexToken,
        uint256 _desiredCollateralReduce,
        uint256 _sizeChanged,
        Side _side
    ) external onlyOrderBook {
        fee.cumulativeInterest();
        address _collateralToken = getCollateralToken(_side, _indexToken);
        uint256 indexPrice = _getPrice(_indexToken);
        uint256 collateralPrice = _getPrice(_collateralToken);

        bytes32 positionKey = getPositionKey(_account, _indexToken, _collateralToken, _side);
        Position storage position = positions[positionKey];

        // decrease position
        DecreasePositionResult memory result = position.decrease(
            fee,
            _side,
            _sizeChanged,
            _desiredCollateralReduce,
            indexPrice,
            collateralPrice
        );

        // reduce reserve amounts
        poolAssets[_collateralToken].decreaseReserve(result.reserveReduced, result.adminFee);

        if (_side == Side.LONG) {
            poolAssets[_collateralToken].decreaseLongPosition(
                result.collateralValueReduced,
                _sizeChanged,
                result.payout,
                result.adminFee
            );
        } else {
            poolAssets[_indexToken].decreaseShortPosition(result.pnl, _sizeChanged);
        }

        if (position.size == 0) {
            emit DecreasePosition(
                positionKey,
                _account,
                _collateralToken,
                _indexToken,
                result.collateralValueReduced,
                _sizeChanged,
                _side,
                indexPrice,
                result.pnl,
                result.feeValue
            );
            emit ClosePosition(
                positionKey,
                position.size,
                position.collateralValue,
                position.entryPrice,
                position.entryInterestRate,
                position.reserveAmount
            );
            // delete position when closed
            delete positions[positionKey];
        } else {
            emit DecreasePosition(
                positionKey,
                _account,
                _collateralToken,
                _indexToken,
                result.collateralValueReduced,
                _sizeChanged,
                _side,
                indexPrice,
                result.pnl,
                result.feeValue
            );
            emit UpdatePosition(
                positionKey,
                position.size,
                position.collateralValue,
                position.entryPrice,
                position.entryInterestRate,
                position.reserveAmount,
                indexPrice
            );
        }
        _doTransferOut(_collateralToken, _account, result.payout);
    }

    /// @notice liquidate position
    function liquidatePosition(
        address _account,
        address _indexToken,
        Side _side
    ) external {
        fee.cumulativeInterest();
        address _collateralToken = getCollateralToken(_side, _indexToken);
        uint256 indexPrice = _getPrice(_indexToken);
        uint256 collateralPrice = _getPrice(_collateralToken);

        bytes32 positionKey = getPositionKey(_account, _indexToken, _collateralToken, _side);
        Position storage position = positions[positionKey];

        DecreasePositionResult memory result = position.liquidate(fee, _side, indexPrice, collateralPrice);
        poolAssets[_collateralToken].decreaseReserve(result.reserveReduced, result.adminFee);

        if (_side == Side.LONG) {
            // decrease full position size and pay out liquidation fee
            poolAssets[_collateralToken].decreaseLongPosition(
                position.size,
                position.collateralValue,
                result.liquidationFee,
                result.adminFee
            );
        } else {
            poolAssets[_indexToken].decreaseShortPosition(result.pnl, position.size);
        }

        emit LiquidatePosition(
            positionKey,
            _account,
            _collateralToken,
            _indexToken,
            _side,
            position.size,
            result.collateralValueReduced,
            position.reserveAmount,
            indexPrice,
            result.pnl,
            result.feeValue
        );

        delete positions[positionKey];

        _doTransferOut(_collateralToken, msg.sender, result.liquidationFee);
    }

    /* ========= PRIVATE FUNCTIONS ======== */

    /// @notice get collateral token based on side of index token
    /// collateral token is token protocol kept as reserve, in order to pay user at any given time
    /// In case of long, we should keep index token as collateral.
    function getCollateralToken(Side _side, address _indexToken) internal view returns (address) {
        require(whitelistedTokens[_indexToken], "PositionManager: onlyWhitelistedTokens");
        if (_side == Side.LONG) {
            require(_indexToken != stableToken, "PositionManager: cannot long stable token");
            return _indexToken;
        } else {
            return stableToken;
        }
    }

    /// @notice get key of position
    function getPositionKey(
        address _account,
        address _indexToken,
        address _collateralToken,
        Side side
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _indexToken, _collateralToken, side));
    }

    /* ========== EVENTS ========== */
    event SetOrderBook(address orderBook);

    event IncreasePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        uint256 collateralValue,
        uint256 sizeChanged,
        Side side,
        uint256 indexPrice,
        uint256 feeValue
    );
    event UpdatePosition(
        bytes32 key,
        uint256 size,
        uint256 collateralValue,
        uint256 entryPrice,
        uint256 entryInterestRate,
        uint256 reserveAmount,
        uint256 indexPrice
    );
    event DecreasePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        uint256 collateralChanged,
        uint256 sizeChanged,
        Side side,
        uint256 indexPrice,
        SignedInt pnl,
        uint256 feeValue
    );
    event ClosePosition(
        bytes32 key,
        uint256 size,
        uint256 collateralValue,
        uint256 entryPrice,
        uint256 entryInterestRate,
        uint256 reserveAmount
    );
    event LiquidatePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        Side side,
        uint256 size,
        uint256 collateralValue,
        uint256 reserveAmount,
        uint256 indexPrice,
        SignedInt pnl,
        uint256 feeValue
    );
}

contract Vault is Initializable, PositionManager {
    using FeeUtils for Fee;

    address public feeDistributor;

    function initialize(
        address _lpToken,
        address _stableToken,
        uint256 _positionFee,
        uint256 _liquidationFee,
        uint256 _adminFee,
        uint256 _interestRate,
        uint256 _accrualInterval
    ) external initializer {
        AssetManager__initialize(_lpToken, _stableToken);
        PositionManager__initialize(_positionFee, _liquidationFee, _adminFee, _interestRate, _accrualInterval);
    }

    function setFee(
        uint256 _positionFee,
        uint256 _liquidationFee,
        uint256 _adminFee,
        uint256 _interestRatePerYear,
        uint256 _accrualInterval
    ) external onlyOwner {
        fee.setInterestRate(_interestRatePerYear, _accrualInterval);
        fee.setFee(_positionFee, _liquidationFee, _adminFee);
    }

    function setOrderBook(address _orderBook) external onlyOwner {
        require(_orderBook != address(0), "Vault: invalid order book address");
        orderBook = _orderBook;
        emit SetOrderBook(_orderBook);
    }

    function withdrawFee(address _token, address _recipient) external {
        require(msg.sender == feeDistributor, "Vault: only fee distributor allowed");
        _requireWhitelisted(_token);
        uint256 amount = poolAssets[_token].feeReserve;
        poolAssets[_token].feeReserve = 0;
        _doTransferOut(_token, _recipient, amount);
        emit WithdrawFee(_token, _recipient, amount);
    }

    function setFeeDistributor(address _feeDistributor) external onlyOwner {
        require(_feeDistributor != address(0), "Vault: invalid fee distributor");
        feeDistributor = _feeDistributor;
        emit SetFeeDistributor(feeDistributor);
    }

    // =========== Events ===========
    event WithdrawFee(address token, address recipient, uint256 amount);
    event SetFeeDistributor(address feeDistributor);
}
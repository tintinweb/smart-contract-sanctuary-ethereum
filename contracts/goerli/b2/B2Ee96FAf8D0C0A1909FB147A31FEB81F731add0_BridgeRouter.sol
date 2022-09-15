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

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

// ============ Internal Imports ============
import {XAppConnectionClient} from "./XAppConnectionClient.sol";
// ============ External Imports ============
import {IMessageRecipient} from "../messaging/interfaces/IMessageRecipient.sol";

abstract contract Router is XAppConnectionClient, IMessageRecipient {
  // ============ Mutable Storage ============

  mapping(uint32 => bytes32) public remotes;

  // ============ Upgrade Gap ============

  uint256[49] private __GAP; // gap for upgrade safety

  // ============ Modifiers ============

  /**
   * @notice Only accept messages from a remote Router contract
   * @param _origin The domain the message is coming from
   * @param _router The address the message is coming from
   */
  modifier onlyRemoteRouter(uint32 _origin, bytes32 _router) {
    require(_isRemoteRouter(_origin, _router), "!remote router");
    _;
  }

  // ============ External functions ============

  /**
   * @notice Register the address of a Router contract for the same xApp on a remote chain
   * @param _domain The domain of the remote xApp Router
   * @param _router The address of the remote xApp Router
   */
  function enrollRemoteRouter(uint32 _domain, bytes32 _router) external onlyOwner {
    remotes[_domain] = _router;
  }

  // ============ Virtual functions ============

  function handle(
    uint32 _origin,
    uint32 _nonce,
    bytes32 _sender,
    bytes memory _message
  ) external virtual override;

  // ============ Internal functions ============
  /**
   * @notice Return true if the given domain / router is the address of a remote xApp Router
   * @param _domain The domain of the potential remote xApp Router
   * @param _router The address of the potential remote xApp Router
   */
  function _isRemoteRouter(uint32 _domain, bytes32 _router) internal view returns (bool) {
    return remotes[_domain] == _router && _router != bytes32(0);
  }

  /**
   * @notice Assert that the given domain has a xApp Router registered and return its address
   * @param _domain The domain of the chain for which to get the xApp Router
   * @return _remote The address of the remote xApp Router on _domain
   */
  function _mustHaveRemote(uint32 _domain) internal view returns (bytes32 _remote) {
    _remote = remotes[_domain];
    require(_remote != bytes32(0), "!remote");
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

// ============ External Imports ============
import {IOutbox} from "../messaging/interfaces/IOutbox.sol";
import {IConnectorManager} from "../messaging/interfaces/IConnectorManager.sol";

import {ProposedOwnableUpgradeable} from "../shared/ProposedOwnable.sol";

abstract contract XAppConnectionClient is ProposedOwnableUpgradeable {
  // ============ Mutable Storage ============

  IConnectorManager public xAppConnectionManager;

  // ============ Upgrade Gap ============

  uint256[49] private __GAP; // gap for upgrade safety

  // ============ Modifiers ============

  /**
   * @notice Only accept messages from an Nomad Replica contract
   */
  modifier onlyReplica() {
    require(_isReplica(msg.sender), "!replica");
    _;
  }

  // ======== Initializer =========

  function __XAppConnectionClient_initialize(address _xAppConnectionManager) internal initializer {
    xAppConnectionManager = IConnectorManager(_xAppConnectionManager);
    __ProposedOwnable_init();
  }

  // ============ External functions ============

  /**
   * @notice Modify the contract the xApp uses to validate Replica contracts
   * @param _xAppConnectionManager The address of the xAppConnectionManager contract
   */
  function setXAppConnectionManager(address _xAppConnectionManager) external onlyOwner {
    xAppConnectionManager = IConnectorManager(_xAppConnectionManager);
  }

  // ============ Internal functions ============

  /**
   * @notice Get the local Home contract from the xAppConnectionManager
   * @return The local Home contract
   */
  function _home() internal view returns (IOutbox) {
    return xAppConnectionManager.home();
  }

  /**
   * @notice Determine whether _potentialReplica is an enrolled Replica from the xAppConnectionManager
   * @return True if _potentialReplica is an enrolled Replica
   */
  function _isReplica(address _potentialReplica) internal view returns (bool) {
    return xAppConnectionManager.isReplica(_potentialReplica);
  }

  /**
   * @notice Get the local domain from the xAppConnectionManager
   * @return The local domain
   */
  function _localDomain() internal view virtual returns (uint32) {
    return xAppConnectionManager.localDomain();
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

// ============ External Imports ============
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITokenRegistry {
  function isLocalOrigin(address _token) external view returns (bool);

  function ensureLocalToken(uint32 _domain, bytes32 _id) external returns (address _local);

  function mustHaveLocalToken(uint32 _domain, bytes32 _id) external view returns (IERC20);

  function getLocalAddress(uint32 _domain, bytes32 _id) external view returns (address _local);

  function getTokenId(address _token) external view returns (uint32, bytes32);

  function enrollCustom(
    uint32 _domain,
    bytes32 _id,
    address _custom
  ) external;

  function oldReprToCurrentRepr(address _oldRepr) external view returns (address _currentRepr);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

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
pragma solidity 0.8.15;

interface IMessageRecipient {
  function handle(
    uint32 _origin,
    uint32 _nonce,
    bytes32 _sender,
    bytes memory _message
  ) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

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
  ) external returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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
  error ProposedOwnable__proposeNewOwner_invalidProposal();
  error ProposedOwnable__proposeNewOwner_noOwnershipChange();
  error ProposedOwnable__renounceOwnership_noProposal();
  error ProposedOwnable__renounceOwnership_delayNotElapsed();
  error ProposedOwnable__renounceOwnership_invalidProposal();
  error ProposedOwnable__acceptProposedOwner_delayNotElapsed();

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
    if (_proposed == newlyProposed && newlyProposed != address(0))
      revert ProposedOwnable__proposeNewOwner_invalidProposal();

    // Sanity check: reasonable proposal
    if (_owner == newlyProposed) revert ProposedOwnable__proposeNewOwner_noOwnershipChange();

    _setProposed(newlyProposed);
  }

  /**
   * @notice Renounces ownership of the contract after a delay
   */
  function renounceOwnership() public virtual onlyOwner {
    // Ensure there has been a proposal cycle started
    if (_proposedOwnershipTimestamp == 0) revert ProposedOwnable__renounceOwnership_noProposal();

    // Ensure delay has elapsed
    if ((block.timestamp - _proposedOwnershipTimestamp) <= _delay)
      revert ProposedOwnable__renounceOwnership_delayNotElapsed();

    // Require proposed is set to 0
    if (_proposed != address(0)) revert ProposedOwnable__renounceOwnership_invalidProposal();

    // Emit event, set new owner, reset timestamp
    _setOwner(_proposed);
  }

  /**
   * @notice Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function acceptProposedOwner() public virtual onlyProposed {
    // NOTE: no need to check if _owner == _proposed, because the _proposed
    // is 0-d out and this check is implicitly enforced by modifier

    // NOTE: no need to check if _proposedOwnershipTimestamp > 0 because
    // the only time this would happen is if the _proposed was never
    // set (will fail from modifier) or if the owner == _proposed (checked
    // above)

    // Ensure delay has elapsed
    if ((block.timestamp - _proposedOwnershipTimestamp) <= _delay)
      revert ProposedOwnable__acceptProposedOwner_delayNotElapsed();

    // Emit event, set new owner, reset timestamp
    _setOwner(_proposed);
  }

  // ======== Internal =========

  function _setOwner(address newOwner) internal {
    address oldOwner = _owner;
    _owner = newOwner;
    _proposedOwnershipTimestamp = 0;
    _proposed = address(0);
    emit OwnershipTransferred(oldOwner, newOwner);
  }

  function _setProposed(address newlyProposed) private {
    _proposedOwnershipTimestamp = block.timestamp;
    _proposed = newlyProposed;
    emit OwnershipProposed(newlyProposed);
  }
}

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
  uint256[49] private __GAP;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

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
pragma solidity 0.8.15;

import "./TypedMemView.sol";

library TypeCasts {
  using TypedMemView for bytes;
  using TypedMemView for bytes29;

  function coerceBytes32(string memory _s) internal pure returns (bytes32 _b) {
    _b = bytes(_s).ref(0).index(0, uint8(bytes(_s).length));
  }

  // treat it as a null-terminated string of max 32 bytes
  function coerceString(bytes32 _buf) internal pure returns (string memory _newStr) {
    uint8 _slen = 0;
    while (_slen < 32 && _buf[_slen] != 0) {
      _slen++;
    }

    // solhint-disable-next-line no-inline-assembly
    assembly {
      _newStr := mload(0x40)
      mstore(0x40, add(_newStr, 0x40)) // may end up with extra
      mstore(_newStr, _slen)
      mstore(add(_newStr, 0x20), _buf)
    }
  }

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
pragma solidity 0.8.15;

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
  uint8 constant TWELVE_BYTES = 96;

  /**
   * @notice      Returns the encoded hex character that represents the lower 4 bits of the argument.
   * @param _b    The byte
   * @return      char - The encoded hex character
   */
  function nibbleHex(uint8 _b) internal pure returns (uint8 char) {
    // This can probably be done more efficiently, but it's only in error
    // paths, so we don't really care :)
    uint8 _nibble = _b | 0xf0; // set top 4, keep bottom 4
    if (_nibble == 0xf0) {
      return 0x30;
    } // 0
    if (_nibble == 0xf1) {
      return 0x31;
    } // 1
    if (_nibble == 0xf2) {
      return 0x32;
    } // 2
    if (_nibble == 0xf3) {
      return 0x33;
    } // 3
    if (_nibble == 0xf4) {
      return 0x34;
    } // 4
    if (_nibble == 0xf5) {
      return 0x35;
    } // 5
    if (_nibble == 0xf6) {
      return 0x36;
    } // 6
    if (_nibble == 0xf7) {
      return 0x37;
    } // 7
    if (_nibble == 0xf8) {
      return 0x38;
    } // 8
    if (_nibble == 0xf9) {
      return 0x39;
    } // 9
    if (_nibble == 0xfa) {
      return 0x61;
    } // a
    if (_nibble == 0xfb) {
      return 0x62;
    } // b
    if (_nibble == 0xfc) {
      return 0x63;
    } // c
    if (_nibble == 0xfd) {
      return 0x64;
    } // d
    if (_nibble == 0xfe) {
      return 0x65;
    } // e
    if (_nibble == 0xff) {
      return 0x66;
    } // f
  }

  /**
   * @notice      Returns a uint16 containing the hex-encoded byte.
   * @param _b    The byte
   * @return      encoded - The hex-encoded byte
   */
  function byteHex(uint8 _b) internal pure returns (uint16 encoded) {
    encoded |= nibbleHex(_b >> 4); // top 4 bits
    encoded <<= 8;
    encoded |= nibbleHex(_b); // lower 4 bits
  }

  /**
   * @notice      Encodes the uint256 to hex. `first` contains the encoded top 16 bytes.
   *              `second` contains the encoded lower 16 bytes.
   *
   * @param _b    The 32 bytes as uint256
   * @return      first - The top 16 bytes
   * @return      second - The bottom 16 bytes
   */
  function encodeHex(uint256 _b) internal pure returns (uint256 first, uint256 second) {
    for (uint8 i = 31; i > 15; ) {
      uint8 _byte = uint8(_b >> (i * 8));
      first |= byteHex(_byte);
      if (i != 16) {
        first <<= 16;
      }
      unchecked {
        i -= 1;
      }
    }

    // abusing underflow here =_=
    for (uint8 i = 15; i < 255; ) {
      uint8 _byte = uint8(_b >> (i * 8));
      second |= byteHex(_byte);
      if (i != 0) {
        second <<= 16;
      }
      unchecked {
        i -= 1;
      }
    }
  }

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
   * @notice          Check if the view is of a valid type and points to a valid location
   *                  in memory.
   * @dev             We perform this check by examining solidity's unallocated memory
   *                  pointer and ensuring that the view's upper bound is less than that.
   * @param memView   The view
   * @return          ret - True if the view is valid
   */
  function isValid(bytes29 memView) internal pure returns (bool ret) {
    if (typeOf(memView) == 0xffffffffff) {
      return false;
    }
    uint256 _end = end(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ret := not(gt(_end, mload(0x40)))
    }
  }

  /**
   * @notice          Require that a typed memory view be valid.
   * @dev             Returns the view for easy chaining.
   * @param memView   The view
   * @return          bytes29 - The validated view
   */
  function assertValid(bytes29 memView) internal pure returns (bytes29) {
    require(isValid(memView), "Validity assertion failed");
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
      (, uint256 g) = encodeHex(uint256(typeOf(memView)));
      (, uint256 e) = encodeHex(uint256(_expected));
      string memory err = string(
        abi.encodePacked("Type assertion failed. Got 0x", uint80(g), ". Expected 0x", uint80(e))
      );
      revert(err);
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
      newView := or(newView, shr(40, shl(40, memView)))
      newView := or(newView, shl(216, _newType))
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
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      newView := shl(96, or(newView, _type)) // insert type
      newView := shl(96, or(newView, _loc)) // insert loc
      newView := shl(24, or(newView, _len)) // empty bottom 3 bytes
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
      _type := shr(216, memView) // shift out lower 24 bytes
    }
  }

  /**
   * @notice          Optimized type comparison. Checks that the 5-byte type flag is equal.
   * @param left      The first view
   * @param right     The second view
   * @return          bool - True if the 5-byte type flag is equal
   */
  function sameType(bytes29 left, bytes29 right) internal pure returns (bool) {
    return (left ^ right) >> (2 * TWELVE_BYTES) == 0;
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
   * @notice          Construct an error message for an indexing overrun.
   * @param _loc      The memory address
   * @param _len      The length
   * @param _index    The index
   * @param _slice    The slice where the overrun occurred
   * @return          err - The err
   */
  function indexErrOverrun(
    uint256 _loc,
    uint256 _len,
    uint256 _index,
    uint256 _slice
  ) internal pure returns (string memory err) {
    (, uint256 a) = encodeHex(_loc);
    (, uint256 b) = encodeHex(_len);
    (, uint256 c) = encodeHex(_index);
    (, uint256 d) = encodeHex(_slice);
    err = string(
      abi.encodePacked(
        "TypedMemView/index - Overran the view. Slice is at 0x",
        uint48(a),
        " with length 0x",
        uint48(b),
        ". Attempted to index at offset 0x",
        uint48(c),
        " with length 0x",
        uint48(d),
        "."
      )
    );
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
      revert(indexErrOverrun(loc(memView), len(memView), _index, uint256(_bytes)));
    }
    require(_bytes <= 32, "TypedMemView/index - Attempted to index more than 32 bytes");

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
   * @notice          Return the sha2 digest of the underlying memory.
   * @dev             We explicitly deallocate memory afterwards.
   * @param memView   The view
   * @return          digest - The sha2 hash of the underlying memory
   */
  function sha2(bytes29 memView) internal view returns (bytes32 digest) {
    uint256 _loc = loc(memView);
    uint256 _len = len(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      let ptr := mload(0x40)
      pop(staticcall(gas(), 2, _loc, _len, ptr, 0x20)) // sha2 #1
      digest := mload(ptr)
    }
  }

  /**
   * @notice          Implements bitcoin's hash160 (rmd160(sha2()))
   * @param memView   The pre-image
   * @return          digest - the Digest
   */
  function hash160(bytes29 memView) internal view returns (bytes20 digest) {
    uint256 _loc = loc(memView);
    uint256 _len = len(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      let ptr := mload(0x40)
      pop(staticcall(gas(), 2, _loc, _len, ptr, 0x20)) // sha2
      pop(staticcall(gas(), 3, ptr, 0x20, ptr, 0x20)) // rmd160
      digest := mload(add(ptr, 0xc)) // return value is 0-prefixed.
    }
  }

  /**
   * @notice          Implements bitcoin's hash256 (double sha2)
   * @param memView   A view of the preimage
   * @return          digest - the Digest
   */
  function hash256(bytes29 memView) internal view returns (bytes32 digest) {
    uint256 _loc = loc(memView);
    uint256 _len = len(memView);
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      let ptr := mload(0x40)
      pop(staticcall(gas(), 2, _loc, _len, ptr, 0x20)) // sha2 #1
      pop(staticcall(gas(), 2, ptr, 0x20, ptr, 0x20)) // sha2 #2
      digest := mload(ptr)
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
    require(notNull(memView), "TypedMemView/copyTo - Null pointer deref");
    require(isValid(memView), "TypedMemView/copyTo - Invalid pointer deref");
    uint256 _len = len(memView);
    uint256 _oldLoc = loc(memView);

    uint256 ptr;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ptr := mload(0x40)
      // revert if we're writing in occupied memory
      if gt(ptr, _newLoc) {
        revert(0x60, 0x20) // empty revert message
      }

      // use the identity precompile to copy
      // guaranteed not to fail, so pop the success
      pop(staticcall(gas(), 4, _oldLoc, _len, _newLoc, _len))
    }

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
    for (uint256 i = 0; i < memViews.length; i++) {
      bytes29 memView = memViews[i];
      unchecked {
        unsafeCopyTo(memView, _location + _offset);
        _offset += len(memView);
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
   * @notice          Produce the sha256 digest of the concatenated contents of multiple views.
   * @param memViews  The views
   * @return          bytes32 - The sha256 digest
   */
  function joinSha2(bytes29[] memory memViews) internal view returns (bytes32) {
    uint256 ptr;
    assembly {
      // solhint-disable-previous-line no-inline-assembly
      ptr := mload(0x40) // load unused memory pointer
    }
    return sha2(unsafeJoin(memViews, ptr));
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

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

// ============ External Imports ============
import {TypedMemView} from "../shared/libraries/TypedMemView.sol";

library BridgeMessage {
  // ============ Libraries ============

  using TypedMemView for bytes;
  using TypedMemView for bytes29;

  // ============ Enums ============

  // WARNING: do NOT re-write the numbers / order
  // of message types in an upgrade;
  // will cause in-flight messages to be mis-interpreted
  // The Types enum has to do with the TypedMemView library and it defines
  // the types of `views` that we use in BridgeMessage. A view is not interesting data
  // itself, but rather it points to a specific part of the memory where
  // the data we care about live. When we give a `type` to a view, we define what type
  // is the data it points to, so that we can do easy runtime assertions without
  // having to fetch the whole data from memory and check for ourselves. In BridgeMessage.sol
  // the types of `data` we can have are defined in this enum and may belong to different taxonomies.
  // For example, a `Message` includes a `TokenId` and an Action, either a `Transfer` or a `TransferToHook`.
  // The Message is a different TYPE of data than a TokenId or Transfer, as TokenId and Transfer live inside
  // the message. For that reason, we define them as different data types and we add them to the same enum
  // for ease of use.
  enum Types {
    Invalid, // 0
    TokenId, // 1
    Message, // 2
    Transfer, // 3
    DeprecatedFastTransfer, // 4
    TransferToHook, // 5
    ExtraData // 6
  }

  // ============ Structs ============

  // Tokens are identified by a TokenId:
  // domain - 4 byte chain ID of the chain from which the token originates
  // id - 32 byte identifier of the token address on the origin chain, in that chain's address format
  struct TokenId {
    uint32 domain;
    bytes32 id;
  }

  // ============ Constants ============

  uint256 private constant TOKEN_ID_LEN = 36; // 4 bytes domain + 32 bytes id
  uint256 private constant IDENTIFIER_LEN = 1;
  uint256 private constant TRANSFER_LEN = 97; // 1 byte identifier + 32 bytes recipient + 32 bytes amount + 32 bytes detailsHash
  uint256 private constant MIN_TRANSFER_HOOK_LEN = 129; // 1 byte identifier + 32 bytes hook address + 32 bytes amount + 32 bytes detailsHash + 32 bytes sender + X bytes extraData

  // ============ Modifiers ============

  /**
   * @notice Asserts a message is of type `_t`
   * @param _view The message
   * @param _t The expected type
   */
  modifier typeAssert(bytes29 _view, Types _t) {
    _view.assertType(uint40(_t));
    _;
  }

  // ============ Internal Functions ============

  /**
   * @notice Checks that Action is valid type
   * @param _action The action
   * @return TRUE if action is valid
   */
  function isValidAction(bytes29 _action) internal pure returns (bool) {
    return isTransfer(_action) || isTransferToHook(_action);
  }

  /**
   * @notice Checks that view is a valid message length
   * @param _view The bytes string
   * @return TRUE if message is valid
   */
  function isValidMessageLength(bytes29 _view) internal pure returns (bool) {
    uint256 _len = _view.len();
    return _len == TOKEN_ID_LEN + TRANSFER_LEN || _len >= TOKEN_ID_LEN + MIN_TRANSFER_HOOK_LEN;
  }

  /**
   * @notice Formats an action message
   * @param _tokenId The token ID
   * @param _action The action
   * @return The formatted message
   */
  function formatMessage(bytes29 _tokenId, bytes29 _action)
    internal
    view
    typeAssert(_tokenId, Types.TokenId)
    returns (bytes memory)
  {
    require(isValidAction(_action), "!action");
    bytes29[] memory _views = new bytes29[](2);
    _views[0] = _tokenId;
    _views[1] = _action;
    return TypedMemView.join(_views);
  }

  /**
   * @notice Returns the type of the message
   * @param _view The message
   * @return The type of the message
   */
  function messageType(bytes29 _view) internal pure returns (Types) {
    return Types(uint8(_view.typeOf()));
  }

  /**
   * @notice Checks that the message is of the specified type
   * @param _type the type to check for
   * @param _action The message
   * @return True if the message is of the specified type
   */
  function isType(bytes29 _action, Types _type) internal pure returns (bool) {
    return actionType(_action) == uint8(_type) && messageType(_action) == _type;
  }

  /**
   * @notice Checks that the message is of type Transfer
   * @param _action The message
   * @return True if the message is of type Transfer
   */
  function isTransfer(bytes29 _action) internal pure returns (bool) {
    return isType(_action, Types.Transfer);
  }

  /**
   * @notice Checks that the message is of type TransferToHook
   * @param _action The message
   * @return True if the message is of type TransferToHook
   */
  function isTransferToHook(bytes29 _action) internal pure returns (bool) {
    return isType(_action, Types.TransferToHook);
  }

  /**
   * @notice Formats Transfer
   * @param _to The recipient address as bytes32
   * @param _amnt The transfer amount
   * @param _detailsHash The hash of the token name, symbol, and decimals
   * @return
   */
  function formatTransfer(
    bytes32 _to,
    uint256 _amnt,
    bytes32 _detailsHash
  ) internal pure returns (bytes29) {
    return abi.encodePacked(Types.Transfer, _to, _amnt, _detailsHash).ref(uint40(Types.Transfer));
  }

  /**
   * @notice Formats TransferToHook message
   * @param _hook The hook that will handle this token transfer
   * @param _amnt The transfer amount
   * @param _detailsHash The hash of the token name, symbol, and decimals
   * @param _extraData User-provided data for the receiving hook
   * @return
   */
  function formatTransferToHook(
    bytes32 _hook,
    uint256 _amnt,
    bytes32 _detailsHash,
    bytes32 _sender,
    bytes memory _extraData
  ) internal pure returns (bytes29) {
    return
      abi.encodePacked(Types.TransferToHook, _hook, _amnt, _detailsHash, _sender, _extraData).ref(
        uint40(Types.TransferToHook)
      );
  }

  /**
   * @notice Serializes a Token ID struct
   * @param _tokenId The token id struct
   * @return The formatted Token ID
   */
  function formatTokenId(TokenId memory _tokenId) internal pure returns (bytes29) {
    return formatTokenId(_tokenId.domain, _tokenId.id);
  }

  /**
   * @notice Creates a serialized Token ID from components
   * @param _domain The domain
   * @param _id The ID
   * @return The formatted Token ID
   */
  function formatTokenId(uint32 _domain, bytes32 _id) internal pure returns (bytes29) {
    return abi.encodePacked(_domain, _id).ref(uint40(Types.TokenId));
  }

  /**
   * @notice Formats the keccak256 hash of the token details
   * Token Details Format:
   *      length of name cast to bytes - 32 bytes
   *      name - x bytes (variable)
   *      length of symbol cast to bytes - 32 bytes
   *      symbol - x bytes (variable)
   *      decimals - 1 byte
   * @param _name The name
   * @param _symbol The symbol
   * @param _decimals The decimals
   * @return The Details message
   */
  function getDetailsHash(
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(bytes(_name).length, _name, bytes(_symbol).length, _symbol, _decimals));
  }

  /**
   * @notice Retrieves the domain from a TokenID
   * @param _tokenId The message
   * @return The domain
   */
  function domain(bytes29 _tokenId) internal pure typeAssert(_tokenId, Types.TokenId) returns (uint32) {
    return uint32(_tokenId.indexUint(0, 4));
  }

  /**
   * @notice Retrieves the ID from a TokenID
   * @param _tokenId The message
   * @return The ID
   */
  function id(bytes29 _tokenId) internal pure typeAssert(_tokenId, Types.TokenId) returns (bytes32) {
    // before = 4 bytes domain
    return _tokenId.index(4, 32);
  }

  /**
   * @notice Retrieves the EVM ID
   * @param _tokenId The message
   * @return The EVM ID
   */
  function evmId(bytes29 _tokenId) internal pure typeAssert(_tokenId, Types.TokenId) returns (address) {
    // before = 4 bytes domain + 12 bytes empty to trim for address
    return _tokenId.indexAddress(16);
  }

  /**
   * @notice Retrieves the action identifier from message
   * @param _message The action
   * @return The message type
   */
  function msgType(bytes29 _message) internal pure returns (uint8) {
    return uint8(_message.indexUint(TOKEN_ID_LEN, 1));
  }

  /**
   * @notice Retrieves the identifier from action
   * @param _action The action
   * @return The action type
   */
  function actionType(bytes29 _action) internal pure returns (uint8) {
    return uint8(_action.indexUint(0, 1));
  }

  /**
   * @notice Retrieves the recipient from a Transfer
   * @param _transferAction The message
   * @return The recipient address as bytes32
   */
  function recipient(bytes29 _transferAction)
    internal
    pure
    typeAssert(_transferAction, Types.Transfer)
    returns (bytes32)
  {
    // before = 1 byte identifier
    return _transferAction.index(1, 32);
  }

  /**
   * @notice Retrieves the EVM Recipient from a Transfer
   * @param _transferAction The message
   * @return The EVM Recipient
   */
  function evmRecipient(bytes29 _transferAction)
    internal
    pure
    typeAssert(_transferAction, Types.Transfer)
    returns (address)
  {
    // before = 1 byte identifier + 12 bytes empty to trim for address = 13 bytes
    return _transferAction.indexAddress(13);
  }

  /**
   * @notice Retrieves the amount from a Transfer
   * @param _transferAction The message
   * @return The amount
   */
  function amnt(bytes29 _transferAction) internal pure returns (uint256) {
    // before = 1 byte identifier + 32 bytes ID = 33 bytes
    return _transferAction.indexUint(33, 32);
  }

  /**
   * @notice Retrieves the detailsHash from a Transfer
   * @param _transferAction The message
   * @return The detailsHash
   */
  function detailsHash(bytes29 _transferAction) internal pure returns (bytes32) {
    // before = 1 byte identifier + 32 bytes ID + 32 bytes amount = 65 bytes
    return _transferAction.index(65, 32);
  }

  /**
   * @notice Retrieves the token ID from a Message
   * @param _message The message
   * @return The ID
   */
  function tokenId(bytes29 _message) internal pure typeAssert(_message, Types.Message) returns (bytes29) {
    return _message.slice(0, TOKEN_ID_LEN, uint40(Types.TokenId));
  }

  /**
   * @notice Retrieves the hook contract EVM address from a TransferWithHook
   * @param _transferAction The message
   * @return The hook contract address
   */
  function evmHook(bytes29 _transferAction)
    internal
    pure
    typeAssert(_transferAction, Types.TransferToHook)
    returns (address)
  {
    return _transferAction.indexAddress(13);
  }

  /**
   * @notice Retrieves the sender from a TransferWithHook
   * @param _transferAction The message
   * @return The sender as bytes32
   */
  function sender(bytes29 _transferAction)
    internal
    pure
    typeAssert(_transferAction, Types.TransferToHook)
    returns (bytes32)
  {
    // before = 1 byte identifier + 32 bytes hook address + 32 bytes amount + 32 bytes detailsHash = 97
    return _transferAction.index(97, 32);
  }

  /**
   * @notice Retrieves the extra data from a TransferWithHook
   * @param _transferAction The message
   * @return A TypedMemview of extraData
   */
  function extraData(bytes29 _transferAction)
    internal
    pure
    typeAssert(_transferAction, Types.TransferToHook)
    returns (bytes29)
  {
    // anything past the end is the extradata
    return
      _transferAction.slice(
        MIN_TRANSFER_HOOK_LEN,
        _transferAction.len() - MIN_TRANSFER_HOOK_LEN,
        uint40(Types.ExtraData)
      );
  }

  /**
   * @notice Retrieves the action data from a Message
   * @param _message The message
   * @return The action
   */
  function action(bytes29 _message) internal pure typeAssert(_message, Types.Message) returns (bytes29) {
    uint256 _actionLen = _message.len() - TOKEN_ID_LEN;
    uint40 _type = uint40(msgType(_message));
    return _message.slice(TOKEN_ID_LEN, _actionLen, _type);
  }

  /**
   * @notice Converts to a Message
   * @param _message The message
   * @return The newly typed message
   */
  function tryAsMessage(bytes29 _message) internal pure returns (bytes29) {
    if (isValidMessageLength(_message)) {
      return _message.castTo(uint40(Types.Message));
    }
    return TypedMemView.nullView();
  }

  /**
   * @notice Asserts that the message is of type Message
   * @param _view The message
   * @return The message
   */
  function mustBeMessage(bytes29 _view) internal pure returns (bytes29) {
    return tryAsMessage(_view).assertValid();
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

// ============ Internal Imports ============
import {BridgeMessage} from "./BridgeMessage.sol";
import {IBridgeToken} from "./IBridgeToken.sol";
import {IBridgeHook} from "./IBridgeHook.sol";

import {ITokenRegistry} from "../core/connext/interfaces/ITokenRegistry.sol";

import {IOutbox} from "../messaging/interfaces/IOutbox.sol";

import {XAppConnectionClient} from "../core/XAppConnectionClient.sol";
import {Router} from "../core/Router.sol";

import {TypedMemView} from "../shared/libraries/TypedMemView.sol";
import {TypeCasts} from "../shared/libraries/TypeCasts.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title BridgeRouter
 */
contract BridgeRouter is Router {
  // ============ Libraries ============

  using TypedMemView for bytes;
  using TypedMemView for bytes29;
  using BridgeMessage for bytes29;
  using SafeERC20 for IERC20;

  // ============ Constants ============

  // the amount transferred to bridgoors without gas funds
  uint256 public constant DUST_AMOUNT = 0.06 ether;

  // ============ Public Storage ============

  // contract that manages registry representation tokens
  ITokenRegistry public tokenRegistry;
  // token transfer prefill ID => LP that pre-filled message to provide fast
  // liquidity
  mapping(bytes32 => address) public liquidityProvider;

  // ============ Upgrade Gap ============

  // gap for upgrade safety
  uint256[49] private __GAP;

  // ======== Events =========

  /**
   * @notice emitted when tokens are sent from this domain to another domain
   * @param token the address of the token contract
   * @param from the address sending tokens
   * @param toDomain the domain of the chain the tokens are being sent to
   * @param toId the bytes32 address of the recipient of the tokens
   * @param amount the amount of tokens sent
   * @param toHook True if sent to a hook, on the remote chain, false
   *        otherwise
   */
  event Send(
    address indexed token,
    address indexed from,
    uint32 indexed toDomain,
    bytes32 toId,
    uint256 amount,
    bool toHook
  );

  /**
   * @notice emitted when tokens are dispensed to an account on this domain
   *         emitted both when fast liquidity is provided, and when the
   *         transfer ultimately settles
   * @param originAndNonce Domain where the transfer originated and the
   *        unique identifier for the message from origin to destination,
   *        combined in a single field ((origin << 32) & nonce)
   * @param token The address of the local token contract being received
   * @param recipient The address receiving the tokens; the original
   *        recipient of the transfer
   * @param liquidityProvider The account providing liquidity
   * @param amount The amount of tokens being received
   */
  event Receive(
    uint64 indexed originAndNonce,
    address indexed token,
    address indexed recipient,
    address liquidityProvider,
    uint256 amount
  );

  // ======== Receive =======
  receive() external payable {}

  // ======== Initializer ========

  function initialize(address _tokenRegistry, address _xAppConnectionManager) public initializer {
    tokenRegistry = ITokenRegistry(_tokenRegistry);
    __XAppConnectionClient_initialize(_xAppConnectionManager);
  }

  // ======== External: Handle =========

  /**
   * @notice Handles an incoming message
   * @param _origin The origin domain
   * @param _nonce The unique identifier for the message from origin to
   *        destination
   * @param _sender The sender address
   * @param _message The message
   */
  function handle(
    uint32 _origin,
    uint32 _nonce,
    bytes32 _sender,
    bytes memory _message
  ) external override onlyReplica onlyRemoteRouter(_origin, _sender) {
    // parse tokenId and action from message
    bytes29 _msg = _message.ref(0).mustBeMessage();
    bytes29 _tokenId = _msg.tokenId();
    bytes29 _action = _msg.action();
    // handle message based on the intended action
    if (_action.isTransfer()) {
      _handleTransfer(_origin, _nonce, _tokenId, _action);
    } else if (_action.isTransferToHook()) {
      _handleTransferToHook(_origin, _nonce, _tokenId, _action);
    } else {
      require(false, "!valid action");
    }
  }

  // ======== External: Send Token =========

  /**
   * @notice Send tokens to a recipient on a remote chain
   * @param _token The token address
   * @param _amount The token amount
   * @param _destination The destination domain
   * @param _recipient The recipient address
   */
  function send(
    address _token,
    uint256 _amount,
    uint32 _destination,
    bytes32 _recipient,
    bool /*_enableFast - deprecated field, left argument for backwards compatibility */
  ) external {
    // validate inputs
    require(_recipient != bytes32(0), "!recip");
    // get the token id
    (bytes29 _tokenId, bytes32 _detailsHash, bool _isLocal) = _getTokenIdAndDetailsHash(_token);
    // debit tokens from the sender
    _takeTokens(_token, _amount, _isLocal);
    // format Transfer message
    bytes29 _action = BridgeMessage.formatTransfer(_recipient, _amount, _detailsHash);
    // send message to destination chain bridge router
    _sendTransferMessage(_destination, _tokenId, _action);
    // emit Send event to record token sender
    emit Send(_token, msg.sender, _destination, _recipient, _amount, false);
  }

  /**
   * @notice Send tokens to a hook on the remote chain
   * @param _token The token address
   * @param _amount The token amount
   * @param _destination The destination domain
   * @param _remoteHook The hook contract on the remote chain
   * @param _extraData Extra data that will be passed to the hook for
   *        execution
   */
  function sendToHook(
    address _token,
    uint256 _amount,
    uint32 _destination,
    bytes32 _remoteHook,
    bytes calldata _extraData
  ) external returns (bytes32) {
    // get the token id
    (bytes29 _tokenId, bytes32 _detailsHash, bool _isLocal) = _getTokenIdAndDetailsHash(_token);
    // debit tokens from the sender
    _takeTokens(_token, _amount, _isLocal);
    // format Hook transfer message
    bytes29 _action = BridgeMessage.formatTransferToHook(
      _remoteHook,
      _amount,
      _detailsHash,
      TypeCasts.addressToBytes32(msg.sender),
      _extraData
    );
    // send message to destination chain bridge router
    bytes32 _messageHash = _sendTransferMessage(_destination, _tokenId, _action);
    // emit Send event to record token sender
    emit Send(_token, msg.sender, _destination, _remoteHook, _amount, true);
    return _messageHash;
  }

  // ======== External: Custom Tokens =========

  /**
   * @notice Enroll a custom token. This allows projects to work with
   *         governance to specify a custom representation.
   * @param _domain the domain of the canonical Token to enroll
   * @param _id the bytes32 ID of the canonical of the Token to enroll
   * @param _custom the address of the custom implementation to use.
   */
  function enrollCustom(
    uint32 _domain,
    bytes32 _id,
    address _custom
  ) external onlyOwner {
    // Sanity check. Ensures that human error doesn't cause an
    // unpermissioned contract to be enrolled.
    IBridgeToken(_custom).mint(address(this), 1);
    IBridgeToken(_custom).burn(address(this), 1);
    tokenRegistry.enrollCustom(_domain, _id, _custom);
  }

  /**
   * @notice Migrate all tokens in a previous representation to the latest
   *         custom representation. This works by looking up local mappings
   *         and then burning old tokens and minting new tokens.
   * @dev This is explicitly opt-in to allow dapps to decide when and how to
   *      upgrade to the new representation.
   * @param _oldRepr The address of the old token to migrate
   */
  function migrate(address _oldRepr) external {
    address _currentRepr = tokenRegistry.oldReprToCurrentRepr(_oldRepr);
    require(_currentRepr != _oldRepr, "!different");
    // burn the total balance of old tokens & mint the new ones
    IBridgeToken _old = IBridgeToken(_oldRepr);
    uint256 _bal = _old.balanceOf(msg.sender);
    _old.burn(msg.sender, _bal);
    IBridgeToken(_currentRepr).mint(msg.sender, _bal);
  }

  // ============ Internal: Send ============

  /**
   * @notice Take from msg.sender as part of sending tokens across chains
   * @dev Locks canonical tokens in escrow in BridgeRouter
   *      OR Burns representation tokens
   * @param _token The token to pull from the sender
   * @param _amount The amount to pull from the sender
   * @param _isLocal Whether or not the token is locally originating
   */
  function _takeTokens(
    address _token,
    uint256 _amount,
    bool _isLocal
  ) internal {
    // Exit early if the _amount is 0
    if (_amount == 0) {
      return;
    }
    // Setup vars used in both if branches
    IBridgeToken _t = IBridgeToken(_token);
    // remove tokens from circulation on this chain
    if (_isLocal) {
      // if the token originates on this chain,
      // hold the tokens in escrow in the Router
      IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    } else {
      // if the token originates on a remote chain,
      // burn the representation tokens on this chain
      _t.burn(msg.sender, _amount);
    }
  }

  /**
   * @notice Returns the token id for a given _token
   * @param _token The token to pull ID for
   * @return _tokenId the bytes canonical token identifier
   * @return _detailsHash the hash of the canonical token details (name,
   *         symbol, decimal)
   */
  function _getTokenIdAndDetailsHash(address _token)
    internal
    returns (
      bytes29 _tokenId,
      bytes32 _detailsHash,
      bool _isLocal
    )
  {
    // get the tokenID
    (uint32 _domain, bytes32 _id) = tokenRegistry.getTokenId(_token);
    _tokenId = BridgeMessage.formatTokenId(_domain, _id);
    // handle the 0-case
    if (_token == address(0)) {
      _detailsHash = bytes32(0);
      _isLocal = false;
      return (_tokenId, _detailsHash, _isLocal);
    }
    // Setup vars used in both if branches
    IBridgeToken _t = IBridgeToken(_token);
    // get the details hash
    if (tokenRegistry.isLocalOrigin(_token)) {
      // query token contract for details and calculate detailsHash
      _detailsHash = BridgeMessage.getDetailsHash(_t.name(), _t.symbol(), _t.decimals());
      _isLocal = true;
    } else {
      _detailsHash = _t.detailsHash();
      _isLocal = false;
    }
  }

  /**
   * @notice Dispatch a message via Nomad to a destination domain
   *         addressed to the remote BridgeRouter on that chain
   * @dev Message will trigger `handle` method on the remote BridgeRouter
   *      when it is received on the destination chain
   * @param _destination The domain of the destination chain
   * @param _tokenId The canonical token identifier for the transfer message
   * @param _action The contents of the transfer message
   */
  function _sendTransferMessage(
    uint32 _destination,
    bytes29 _tokenId,
    bytes29 _action
  ) internal returns (bytes32) {
    // get remote BridgeRouter address; revert if not found
    bytes32 _remote = _mustHaveRemote(_destination);
    // send message to remote chain via Nomad
    return
      IOutbox(xAppConnectionManager.home()).dispatch(
        _destination,
        _remote,
        BridgeMessage.formatMessage(_tokenId, _action)
      );
  }

  // ============ Internal: Handle ============

  /**
   * @notice Handles an incoming Transfer message.
   *
   * If the token is of local origin, the amount is sent from escrow.
   * Otherwise, a representation token is minted.
   *
   * @param _origin The domain of the chain from which the transfer originated
   * @param _nonce The unique identifier for the message from origin to
   *        destination
   * @param _tokenId The token ID
   * @param _action The action
   */
  function _handleTransfer(
    uint32 _origin,
    uint32 _nonce,
    bytes29 _tokenId,
    bytes29 _action
  ) internal {
    // tokens will be sent to the specified recipient
    address _recipient = _action.evmRecipient();
    // send tokens
    _giveTokens(_origin, _nonce, _tokenId, _action, _recipient);
    // dust the recipient with gas tokens
    _dust(_recipient);
  }

  /**
   * @notice Handles an incoming TransferToHook message.
   *
   * @dev The hook is called AFTER tokens have been transferred to the hook
   *      contract. If this hook errors, the bridge WILL NOT revert, and the
   *      hook contract will own those tokens. Hook contracts MUST have a
   *      recovery plan in place for these situations.
   *
   * @param _origin The domain of the chain from which the transfer originated
   * @param _nonce The unique identifier for the message from origin to destination
   * @param _tokenId The token ID
   * @param _action The action
   */
  function _handleTransferToHook(
    uint32 _origin,
    uint32 _nonce,
    bytes29 _tokenId,
    bytes29 _action
  ) internal {
    // tokens will be sent to user-specified hook
    address _hook = _action.evmHook();
    // send tokens
    address _token = _giveTokens(_origin, _nonce, _tokenId, _action, _hook);
    // NOTE: in the case of 0-value transfers, the token will be empty
    // ABI-encode the calldata for a `Hook.onRecive` call
    bytes memory _call = abi.encodeWithSelector(
      IBridgeHook.onReceive.selector,
      _origin,
      _action.sender(),
      _tokenId.domain(),
      _tokenId.id(),
      _token,
      _action.amnt(),
      _action.extraData().clone()
    );
    // Call the hook with the ABI-encoded payload
    // We use a low-level call here so that solc will skip pre-call
    // and post-call checks. Specifically we want to skip
    // 1. pre-flight extcode check
    // 2. post-flight success check
    // We do this so that the hook contract need not exist, and need
    // not execute succesfully
    _hook.call(_call);
  }

  /**
   * @notice Send tokens to a specified recipient.
   * @dev Unlocks canonical tokens from escrow in BridgeRouter
   *      OR Mints representation tokens
   * @param _origin The domain of the chain from which the transfer originated
   * @param _nonce The unique identifier for the message from origin to
   *        destination
   * @param _tokenId The canonical token identifier to credit
   * @param _action The contents of the transfer message
   * @param _recipient The recipient that will receive tokens
   * @return _token The address of the local token contract
   */
  function _giveTokens(
    uint32 _origin,
    uint32 _nonce,
    bytes29 _tokenId,
    bytes29 _action,
    address _recipient
  ) internal returns (address _token) {
    // get the token contract for the given tokenId on this chain;
    // (if the token is of remote origin and there is
    // no existing representation token contract, the TokenRegistry will
    // deploy a new one)
    _token = tokenRegistry.ensureLocalToken(_tokenId.domain(), _tokenId.id());
    // load amount once
    uint256 _amount = _action.amnt();
    if (_amount == 0) {
      // emit receive event
      emit Receive(_originAndNonce(_origin, _nonce), _token, _recipient, address(0), _amount);
      // exit early
      return _token;
    }
    // send the tokens into circulation on this chain
    if (tokenRegistry.isLocalOrigin(_token)) {
      // if the token is of local origin, the tokens have been held in
      // escrow in this contract
      // while they have been circulating on remote chains;
      // transfer the tokens to the recipient
      IERC20(_token).safeTransfer(_recipient, _amount);
    } else {
      // if the token is of remote origin, mint the tokens to the
      // recipient on this chain
      IBridgeToken(_token).mint(_recipient, _amount);
      // Tell the token what its detailsHash is
      IBridgeToken(_token).setDetailsHash(_action.detailsHash());
    }
    // emit Receive event
    emit Receive(_originAndNonce(_origin, _nonce), _token, _recipient, address(0), _amount);
  }

  // ============ Internal: Dust with Gas ============

  /**
   * @notice Dust the recipient. This feature allows chain operators to use
   * the Bridge as a faucet if so desired. Any gas asset held by the
   * bridge will be slowly sent to users who need initial gas bootstrapping
   * @dev Does not dust if insufficient funds, or if user has funds already
   */
  function _dust(address _recipient) internal {
    if (_recipient.balance < DUST_AMOUNT && address(this).balance >= DUST_AMOUNT) {
      // `send` gives execution 2300 gas and returns a `success` boolean.
      // however, we do not care if the call fails. A failed call
      // indicates a smart contract attempting to execute logic, which we
      // specifically do not want.
      // While we could check EXTCODESIZE, it seems sufficient to rely on
      // the 2300 gas stipend to ensure that no state change logic can
      // be executed.
      payable(_recipient).send(DUST_AMOUNT);
    }
  }

  // ============ Internal: Utils ============

  /**
     * @notice Internal utility function that combines
     *         `_origin` and `_nonce`.
     * @dev Both origin and nonce should be less than 2^32 - 1
     * @param _origin Domain of chain where the transfer originated
     * @param _nonce The unique identifier for the message from origin to
              destination
     * @return Returns (`_origin` << 32) & `_nonce`
     */
  function _originAndNonce(uint32 _origin, uint32 _nonce) internal pure returns (uint64) {
    return (uint64(_origin) << 32) | _nonce;
  }

  /**
   * @dev should be impossible to renounce ownership;
   *      we override OpenZeppelin OwnableUpgradeable's
   *      implementation of renounceOwnership to make it a no-op
   */
  function renounceOwnership() public override onlyOwner {
    // do nothing
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

interface IBridgeHook {
  /**
   * @notice Handles an incoming bridge transfer with some tokens and extra
   * data. Takes any necessary actions for the hook's purposes.
   *
   * This function is intended to allow arbitrary post-bridge actions with
   * tokens, at a user's discretion. E.g. recollateralize a CDP, exchange for
   * other tokens, emit an event, etc.
   *
   * @dev This hook is called AFTER tokens have been transferred to the hook
   * contract. If this hook errors, the bridge WILL NOT revert, and the hook
   * contract will own those tokens. Hook contracts MUST have a recovery plan
   * in place for these situations.
   *
   * @param _origin The domain of the chain from which the transfer originated
   * @param _sender The identifier of the caller which sent the tokens over the bridge
   * @param _tokenDomain The canonical deployment domain of the token
   * @param _tokenAddress The identifier for the token on its canonical domain
   * @param _localToken The local address of the token (its canonical
   *                    address if it is local to this domain, otherwise its
   *                    the address of its local representation).
   * @param _amount The amount of token received over the bridge
   * @param _extraData Extra user-specified data passed in to the origin chain
   */
  function onReceive(
    uint32 _origin,
    bytes32 _sender,
    uint32 _tokenDomain,
    bytes32 _tokenAddress,
    address _localToken,
    uint256 _amount,
    bytes memory _extraData
  ) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.15;

interface IBridgeToken {
  function initialize() external;

  function name() external returns (string memory);

  function balanceOf(address _account) external view returns (uint256);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function detailsHash() external view returns (bytes32);

  function burn(address _from, uint256 _amnt) external;

  function mint(address _to, uint256 _amnt) external;

  function setDetailsHash(bytes32 _detailsHash) external;

  function setDetails(
    string calldata _name,
    string calldata _symbol,
    uint8 _decimals
  ) external;

  // inherited from ownable
  function transferOwnership(address _newOwner) external;
}
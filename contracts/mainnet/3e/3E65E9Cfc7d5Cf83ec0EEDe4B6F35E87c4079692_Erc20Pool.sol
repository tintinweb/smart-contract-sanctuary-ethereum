/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// SPDX-License-Identifier: GPL-3.0-or-later
// Sources flattened with hardhat v2.6.1 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
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


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;


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


// File @openzeppelin/contracts/utils/math/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

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
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
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
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
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
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
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
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
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
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
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
     * - input must fit into 8 bits.
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
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
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
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
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
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
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
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
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
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
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
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}


// File interfaces/strategies/IStrategy.sol

pragma solidity 0.8.10;

interface IStrategy {
    function deposit() external payable returns (bool);

    function withdraw(uint256 amount) external returns (bool);

    function withdrawAll() external returns (uint256);

    function harvest() external returns (uint256);

    function shutdown() external;

    function setCommunityReserve(address _communityReserve) external;

    function setStrategist(address strategist_) external;

    function name() external view returns (string memory);

    function balance() external view returns (uint256);

    function harvestable() external view returns (uint256);

    function strategist() external view returns (address);

    function hasPendingFunds() external view returns (bool);
}


// File interfaces/IVault.sol

pragma solidity 0.8.10;

/**
 * @title Interface for a Vault
 */

interface IVault {
    event StrategyActivated(address indexed strategy);

    event StrategyDeactivated(address indexed strategy);

    /**
     * @dev 'netProfit' is the profit after all fees have been deducted
     */
    event Harvest(uint256 indexed netProfit, uint256 indexed loss);

    function initialize(
        address _pool,
        uint256 _debtLimit,
        uint256 _targetAllocation,
        uint256 _bound
    ) external;

    function withdrawFromStrategyWaitingForRemoval(address strategy) external returns (uint256);

    function deposit() external payable;

    function withdraw(uint256 amount) external returns (bool);

    function withdrawAvailableToPool() external;

    function initializeStrategy(address strategy_) external;

    function shutdownStrategy() external;

    function withdrawFromReserve(uint256 amount) external;

    function updateStrategy(address newStrategy) external;

    function activateStrategy() external returns (bool);

    function deactivateStrategy() external returns (bool);

    function updatePerformanceFee(uint256 newPerformanceFee) external;

    function updateStrategistFee(uint256 newStrategistFee) external;

    function updateDebtLimit(uint256 newDebtLimit) external;

    function updateTargetAllocation(uint256 newTargetAllocation) external;

    function updateReserveFee(uint256 newReserveFee) external;

    function updateBound(uint256 newBound) external;

    function withdrawFromStrategy(uint256 amount) external returns (bool);

    function withdrawAllFromStrategy() external returns (bool);

    function harvest() external returns (bool);

    function getStrategiesWaitingForRemoval() external view returns (address[] memory);

    function getAllocatedToStrategyWaitingForRemoval(address strategy)
        external
        view
        returns (uint256);

    function getTotalUnderlying() external view returns (uint256);

    function getUnderlying() external view returns (address);

    function strategy() external view returns (IStrategy);
}


// File interfaces/IStakerVault.sol

pragma solidity 0.8.10;

interface IStakerVault {
    event Staked(address indexed account, uint256 amount);
    event Unstaked(address indexed account, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function initialize(address _token) external;

    function initializeLpGauge(address _lpGauge) external;

    function stake(uint256 amount) external;

    function stakeFor(address account, uint256 amount) external;

    function unstake(uint256 amount) external;

    function unstakeFor(
        address src,
        address dst,
        uint256 amount
    ) external;

    function approve(address spender, uint256 amount) external;

    function transfer(address account, uint256 amount) external;

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external;

    function increaseActionLockedBalance(address account, uint256 amount) external;

    function decreaseActionLockedBalance(address account, uint256 amount) external;

    function updateLpGauge(address _lpGauge) external;

    function poolCheckpoint() external returns (bool);

    function poolCheckpoint(uint256 updateEndTime) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function getToken() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function stakedAndActionLockedBalanceOf(address account) external view returns (uint256);

    function actionLockedBalanceOf(address account) external view returns (uint256);

    function getStakedByActions() external view returns (uint256);

    function getPoolTotalStaked() external view returns (uint256);

    function decimals() external view returns (uint8);

    function lpGauge() external view returns (address);
}


// File interfaces/pool/ILiquidityPool.sol

pragma solidity 0.8.10;


interface ILiquidityPool {
    event Deposit(address indexed minter, uint256 depositAmount, uint256 mintedLpTokens);

    event DepositFor(
        address indexed minter,
        address indexed mintee,
        uint256 depositAmount,
        uint256 mintedLpTokens
    );

    event Redeem(address indexed redeemer, uint256 redeemAmount, uint256 redeemTokens);

    event LpTokenSet(address indexed lpToken);

    event StakerVaultSet(address indexed stakerVault);

    event Shutdown();

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeem(uint256 redeemTokens, uint256 minRedeemAmount) external returns (uint256);

    function calcRedeem(address account, uint256 underlyingAmount) external returns (uint256);

    function deposit(uint256 mintAmount) external payable returns (uint256);

    function deposit(uint256 mintAmount, uint256 minTokenAmount) external payable returns (uint256);

    function depositAndStake(uint256 depositAmount, uint256 minTokenAmount)
        external
        payable
        returns (uint256);

    function depositFor(address account, uint256 depositAmount) external payable returns (uint256);

    function depositFor(
        address account,
        uint256 depositAmount,
        uint256 minTokenAmount
    ) external payable returns (uint256);

    function unstakeAndRedeem(uint256 redeemLpTokens, uint256 minRedeemAmount)
        external
        returns (uint256);

    function handleLpTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) external;

    function updateVault(address _vault) external;

    function setLpToken(address _lpToken) external;

    function setStaker() external;

    function shutdownPool(bool shutdownStrategy) external;

    function shutdownStrategy() external;

    function updateRequiredReserves(uint256 _newRatio) external;

    function updateReserveDeviation(uint256 newRatio) external;

    function updateMinWithdrawalFee(uint256 newFee) external;

    function updateMaxWithdrawalFee(uint256 newFee) external;

    function updateWithdrawalFeeDecreasePeriod(uint256 newPeriod) external;

    function rebalanceVault() external;

    function getNewCurrentFees(
        uint256 timeToWait,
        uint256 lastActionTimestamp,
        uint256 feeRatio
    ) external view returns (uint256);

    function vault() external view returns (IVault);

    function staker() external view returns (IStakerVault);

    function getUnderlying() external view returns (address);

    function getLpToken() external view returns (address);

    function getWithdrawalFee(address account, uint256 amount) external view returns (uint256);

    function exchangeRate() external view returns (uint256);

    function totalUnderlying() external view returns (uint256);

    function name() external view returns (string memory);

    function isShutdown() external view returns (bool);
}


// File interfaces/IGasBank.sol

pragma solidity 0.8.10;

interface IGasBank {
    event Deposit(address indexed account, uint256 value);
    event Withdraw(address indexed account, address indexed receiver, uint256 value);

    function depositFor(address account) external payable;

    function withdrawUnused(address account) external;

    function withdrawFrom(address account, uint256 amount) external;

    function withdrawFrom(
        address account,
        address payable to,
        uint256 amount
    ) external;

    function balanceOf(address account) external view returns (uint256);
}


// File interfaces/oracles/IOracleProvider.sol

pragma solidity 0.8.10;

interface IOracleProvider {
    /// @notice Checks whether the asset is supported
    /// @param baseAsset the asset of which the price is to be quoted
    /// @return true if the asset is supported
    function isAssetSupported(address baseAsset) external view returns (bool);

    /// @notice Quotes the USD price of `baseAsset`
    /// @param baseAsset the asset of which the price is to be quoted
    /// @return the USD price of the asset
    function getPriceUSD(address baseAsset) external view returns (uint256);

    /// @notice Quotes the ETH price of `baseAsset`
    /// @param baseAsset the asset of which the price is to be quoted
    /// @return the ETH price of the asset
    function getPriceETH(address baseAsset) external view returns (uint256);
}


// File libraries/AddressProviderMeta.sol

pragma solidity 0.8.10;

library AddressProviderMeta {
    struct Meta {
        bool freezable;
        bool frozen;
    }

    function fromUInt(uint256 value) internal pure returns (Meta memory) {
        Meta memory meta;
        meta.freezable = (value & 1) == 1;
        meta.frozen = ((value >> 1) & 1) == 1;
        return meta;
    }

    function toUInt(Meta memory meta) internal pure returns (uint256) {
        uint256 value;
        value |= meta.freezable ? 1 : 0;
        value |= meta.frozen ? 1 << 1 : 0;
        return value;
    }
}


// File interfaces/IAddressProvider.sol

pragma solidity 0.8.10;




// solhint-disable ordering

interface IAddressProvider {
    event KnownAddressKeyAdded(bytes32 indexed key);
    event StakerVaultListed(address indexed stakerVault);
    event StakerVaultDelisted(address indexed stakerVault);
    event ActionListed(address indexed action);
    event ActionShutdown(address indexed action);
    event PoolListed(address indexed pool);
    event VaultUpdated(address indexed previousVault, address indexed newVault);
    event FeeHandlerAdded(address feeHandler);
    event FeeHandlerRemoved(address feeHandler);

    /** Key functions */
    function getKnownAddressKeys() external view returns (bytes32[] memory);

    function freezeAddress(bytes32 key) external;

    /** Pool functions */

    function allPools() external view returns (address[] memory);

    function addPool(address pool) external;

    function poolsCount() external view returns (uint256);

    function getPoolAtIndex(uint256 index) external view returns (address);

    function isPool(address pool) external view returns (bool);

    function getPoolForToken(address token) external view returns (ILiquidityPool);

    function safeGetPoolForToken(address token) external view returns (address);

    /** Vault functions  */

    function updateVault(address previousVault, address newVault) external;

    function allVaults() external view returns (address[] memory);

    function vaultsCount() external view returns (uint256);

    function getVaultAtIndex(uint256 index) external view returns (address);

    function isVault(address vault) external view returns (bool);

    /** Action functions */

    function allActions() external view returns (address[] memory);

    function actionsCount() external view returns (uint256);

    function getActionAtIndex(uint256 index) external view returns (address);

    function allActiveActions() external view returns (address[] memory);

    function addAction(address action) external returns (bool);

    function shutdownAction(address action) external;

    function isAction(address action) external view returns (bool);

    function isActiveAction(address action) external view returns (bool);

    /** Address functions */

    function initialize(address roleManager_, address treasury_) external;

    function initializeAddress(bytes32 key, address initialAddress) external;

    function initializeAddress(
        bytes32 key,
        address initialAddress,
        bool frezable
    ) external;

    function initializeAndFreezeAddress(bytes32 key, address initialAddress) external;

    function getAddress(bytes32 key) external view returns (address);

    function getAddress(bytes32 key, bool checkExists) external view returns (address);

    function getAddressMeta(bytes32 key) external view returns (AddressProviderMeta.Meta memory);

    function updateAddress(bytes32 key, address newAddress) external;

    function initializeInflationManager(address initialAddress) external;

    /** Staker vault functions */
    function allStakerVaults() external view returns (address[] memory);

    function tryGetStakerVault(address token) external view returns (bool, address);

    function getStakerVault(address token) external view returns (address);

    function addStakerVault(address stakerVault) external;

    function isStakerVault(address stakerVault, address token) external view returns (bool);

    function isStakerVaultRegistered(address stakerVault) external view returns (bool);

    function isWhiteListedFeeHandler(address feeHandler) external view returns (bool);

    /** Fee Handler function */
    function addFeeHandler(address feeHandler) external;

    function removeFeeHandler(address feeHandler) external;
}


// File interfaces/actions/IAction.sol

pragma solidity 0.8.10;

interface IAction {
    event UsableTokenAdded(address token);
    event UsableTokenRemoved(address token);
    event Paused();
    event Unpaused();
    event Shutdown();

    function addUsableToken(address token) external;

    function removeUsableToken(address token) external;

    function updateActionFee(uint256 actionFee) external;

    function updateFeeHandler(address feeHandler) external;

    function shutdownAction() external;

    function pause() external;

    function unpause() external;

    function getEthRequiredForGas(address payer) external view returns (uint256);

    function getUsableTokens() external view returns (address[] memory);

    function isUsable(address token) external view returns (bool);

    function feeHandler() external view returns (address);

    function isShutdown() external view returns (bool);

    function isPaused() external view returns (bool);
}


// File interfaces/tokenomics/IInflationManager.sol

pragma solidity 0.8.10;

interface IInflationManager {
    event KeeperGaugeListed(address indexed pool, address indexed keeperGauge);
    event AmmGaugeListed(address indexed token, address indexed ammGauge);
    event KeeperGaugeDelisted(address indexed pool, address indexed keeperGauge);
    event AmmGaugeDelisted(address indexed token, address indexed ammGauge);

    /** Pool functions */

    function setKeeperGauge(address pool, address _keeperGauge) external returns (bool);

    function setAmmGauge(address token, address _ammGauge) external returns (bool);

    function setMinter(address _minter) external;

    function advanceKeeperGaugeEpoch(address pool) external;

    function whitelistGauge(address gauge) external;

    function removeStakerVaultFromInflation(address lpToken) external;

    function removeAmmGauge(address token) external returns (bool);

    function addGaugeForVault(address lpToken) external;

    function checkpointAllGauges(uint256 updateEndTime) external;

    function mintRewards(address beneficiary, uint256 amount) external;

    function checkPointInflation() external;

    function removeKeeperGauge(address pool) external;

    function getAllAmmGauges() external view returns (address[] memory);

    function getLpRateForStakerVault(address stakerVault) external view returns (uint256);

    function getKeeperRateForPool(address pool) external view returns (uint256);

    function getAmmRateForToken(address token) external view returns (uint256);

    function getLpPoolWeight(address pool) external view returns (uint256);

    function getKeeperGaugeForPool(address pool) external view returns (address);

    function getAmmGaugeForToken(address token) external view returns (address);

    function gauges(address lpToken) external view returns (bool);

    function ammWeights(address gauge) external view returns (uint256);

    function lpPoolWeights(address gauge) external view returns (uint256);

    function keeperPoolWeights(address gauge) external view returns (uint256);

    function minter() external view returns (address);

    function weightBasedKeeperDistributionDeactivated() external view returns (bool);

    function totalKeeperPoolWeight() external view returns (uint256);

    function totalLpPoolWeight() external view returns (uint256);

    function totalAmmTokenWeight() external view returns (uint256);

    /** Weight setter functions **/

    function updateLpPoolWeight(address lpToken, uint256 newPoolWeight) external;

    function updateAmmTokenWeight(address token, uint256 newTokenWeight) external;

    function updateKeeperPoolWeight(address pool, uint256 newPoolWeight) external;

    function batchUpdateLpPoolWeights(address[] calldata lpTokens, uint256[] calldata weights)
        external;

    function batchUpdateAmmTokenWeights(address[] calldata tokens, uint256[] calldata weights)
        external;

    function batchUpdateKeeperPoolWeights(address[] calldata pools, uint256[] calldata weights)
        external;

    function deactivateWeightBasedKeeperDistribution() external;
}


// File interfaces/IController.sol

pragma solidity 0.8.10;





// solhint-disable ordering

interface IController {
    function addressProvider() external view returns (IAddressProvider);

    function addStakerVault(address stakerVault) external;

    function shutdownPool(ILiquidityPool pool, bool shutdownStrategy) external returns (bool);

    function shutdownAction(IAction action) external;

    /** Keeper functions */
    function updateKeeperRequiredStakedMERO(uint256 amount) external;

    function canKeeperExecuteAction(address keeper) external view returns (bool);

    function keeperRequireStakedMero() external view returns (uint256);

    /** Miscellaneous functions */

    function getTotalEthRequiredForGas(address payer) external view returns (uint256);
}


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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


// File interfaces/ILpToken.sol

pragma solidity 0.8.10;

interface ILpToken is IERC20Upgradeable {
    function mint(address account, uint256 lpTokens) external;

    function burn(address account, uint256 burnAmount) external returns (uint256);

    function burn(uint256 burnAmount) external;

    function minter() external view returns (address);

    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 _decimals,
        address _minter
    ) external returns (bool);
}


// File interfaces/IVaultReserve.sol

pragma solidity 0.8.10;

interface IVaultReserve {
    event Deposit(address indexed vault, address indexed token, uint256 amount);
    event Withdraw(address indexed vault, address indexed token, uint256 amount);
    event VaultListed(address indexed vault);

    function deposit(address token, uint256 amount) external payable;

    function withdraw(address token, uint256 amount) external;

    function getBalance(address vault, address token) external view returns (uint256);

    function canWithdraw(address vault) external view returns (bool);
}


// File interfaces/IRoleManager.sol

pragma solidity 0.8.10;

interface IRoleManager {
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    function initialize() external;

    function grantRole(bytes32 role, address account) external;

    function addGovernor(address newGovernor) external;

    function renounceGovernance() external;

    function addGaugeZap(address zap) external;

    function removeGaugeZap(address zap) external;

    function revokeRole(bytes32 role, address account) external;

    function hasRole(bytes32 role, address account) external view returns (bool);

    function hasAnyRole(bytes32[] memory roles, address account) external view returns (bool);

    function hasAnyRole(
        bytes32 role1,
        bytes32 role2,
        address account
    ) external view returns (bool);

    function hasAnyRole(
        bytes32 role1,
        bytes32 role2,
        bytes32 role3,
        address account
    ) external view returns (bool);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
}


// File interfaces/IFeeBurner.sol

pragma solidity 0.8.10;

interface IFeeBurner {
    function burnToTarget(address[] memory tokens, address targetLpToken)
        external
        payable
        returns (uint256);
}


// File interfaces/tokenomics/IMeroToken.sol

pragma solidity 0.8.10;

interface IMeroToken is IERC20 {
    function mint(address account, uint256 amount) external;

    function cap() external view returns (uint256);
}


// File interfaces/ISwapperRouter.sol

pragma solidity 0.8.10;

interface ISwapperRouter {
    function swapAll(address fromToken, address toToken) external payable returns (uint256);

    function setSlippageTolerance(uint256 slippageTolerance_) external;

    function setCurvePool(address token_, address curvePool_) external;

    function swap(
        address fromToken,
        address toToken,
        uint256 amountIn
    ) external payable returns (uint256);

    function getAmountOut(
        address fromToken,
        address toToken,
        uint256 amountIn
    ) external view returns (uint256 amountOut);
}


// File libraries/AddressProviderKeys.sol

pragma solidity 0.8.10;

library AddressProviderKeys {
    bytes32 internal constant _TREASURY_KEY = "treasury";
    bytes32 internal constant _REWARD_HANDLER_KEY = "rewardHandler";
    bytes32 internal constant _GAS_BANK_KEY = "gasBank";
    bytes32 internal constant _VAULT_RESERVE_KEY = "vaultReserve";
    bytes32 internal constant _ORACLE_PROVIDER_KEY = "oracleProvider";
    bytes32 internal constant _POOL_FACTORY_KEY = "poolFactory";
    bytes32 internal constant _CONTROLLER_KEY = "controller";
    bytes32 internal constant _MERO_LOCKER_KEY = "meroLocker";
    bytes32 internal constant _INFLATION_MANAGER_KEY = "inflationManager";
    bytes32 internal constant _FEE_BURNER_KEY = "feeBurner";
    bytes32 internal constant _ROLE_MANAGER_KEY = "roleManager";
    bytes32 internal constant _SWAPPER_ROUTER_KEY = "swapperRouter";
}


// File libraries/AddressProviderHelpers.sol

pragma solidity 0.8.10;









library AddressProviderHelpers {
    /**
     * @return The address of the treasury.
     */
    function getTreasury(IAddressProvider provider) internal view returns (address) {
        return provider.getAddress(AddressProviderKeys._TREASURY_KEY);
    }

    /**
     * @return The address of the reward handler.
     */
    function getRewardHandler(IAddressProvider provider) internal view returns (address) {
        return provider.getAddress(AddressProviderKeys._REWARD_HANDLER_KEY);
    }

    /**
     * @dev Returns zero address if no reward handler is set.
     * @return The address of the reward handler.
     */
    function getSafeRewardHandler(IAddressProvider provider) internal view returns (address) {
        return provider.getAddress(AddressProviderKeys._REWARD_HANDLER_KEY, false);
    }

    /**
     * @return The address of the fee burner.
     */
    function getFeeBurner(IAddressProvider provider) internal view returns (IFeeBurner) {
        return IFeeBurner(provider.getAddress(AddressProviderKeys._FEE_BURNER_KEY));
    }

    /**
     * @return The gas bank.
     */
    function getGasBank(IAddressProvider provider) internal view returns (IGasBank) {
        return IGasBank(provider.getAddress(AddressProviderKeys._GAS_BANK_KEY));
    }

    /**
     * @return The address of the vault reserve.
     */
    function getVaultReserve(IAddressProvider provider) internal view returns (IVaultReserve) {
        return IVaultReserve(provider.getAddress(AddressProviderKeys._VAULT_RESERVE_KEY));
    }

    /**
     * @return The oracleProvider.
     */
    function getOracleProvider(IAddressProvider provider) internal view returns (IOracleProvider) {
        return IOracleProvider(provider.getAddress(AddressProviderKeys._ORACLE_PROVIDER_KEY));
    }

    /**
     * @return the address of the MERO locker
     */
    function getMEROLocker(IAddressProvider provider) internal view returns (address) {
        return provider.getAddress(AddressProviderKeys._MERO_LOCKER_KEY);
    }

    /**
     * @return the address of the MERO locker
     */
    function getRoleManager(IAddressProvider provider) internal view returns (IRoleManager) {
        return IRoleManager(provider.getAddress(AddressProviderKeys._ROLE_MANAGER_KEY));
    }

    /**
     * @return the controller
     */
    function getController(IAddressProvider provider) internal view returns (IController) {
        return IController(provider.getAddress(AddressProviderKeys._CONTROLLER_KEY));
    }

    /**
     * @return the inflation manager
     */
    function getInflationManager(IAddressProvider provider)
        internal
        view
        returns (IInflationManager)
    {
        return IInflationManager(provider.getAddress(AddressProviderKeys._INFLATION_MANAGER_KEY));
    }

    /**
     * @return the inflation manager or `address(0)` if it does not exist
     */
    function safeGetInflationManager(IAddressProvider provider)
        internal
        view
        returns (IInflationManager)
    {
        return
            IInflationManager(
                provider.getAddress(AddressProviderKeys._INFLATION_MANAGER_KEY, false)
            );
    }

    /**
     * @return the swapper router
     */
    function getSwapperRouter(IAddressProvider provider) internal view returns (ISwapperRouter) {
        return ISwapperRouter(provider.getAddress(AddressProviderKeys._SWAPPER_ROUTER_KEY));
    }
}


// File libraries/Errors.sol

pragma solidity 0.8.10;

// solhint-disable private-vars-leading-underscore

library Error {
    string internal constant ADDRESS_WHITELISTED = "address already whitelisted";
    string internal constant ADMIN_ALREADY_SET = "admin has already been set once";
    string internal constant ADDRESS_NOT_WHITELISTED = "address not whitelisted";
    string internal constant ADDRESS_NOT_FOUND = "address not found";
    string internal constant CONTRACT_INITIALIZED = "contract can only be initialized once";
    string internal constant CONTRACT_PAUSED = "contract is paused";
    string internal constant UNAUTHORIZED_PAUSE = "not authorized to pause";
    string internal constant INVALID_AMOUNT = "invalid amount";
    string internal constant INVALID_INDEX = "invalid index";
    string internal constant INVALID_VALUE = "invalid msg.value";
    string internal constant INVALID_SENDER = "invalid msg.sender";
    string internal constant INVALID_TOKEN = "token address does not match pool's LP token address";
    string internal constant INVALID_DECIMALS = "incorrect number of decimals";
    string internal constant INVALID_ARGUMENT = "invalid argument";
    string internal constant INVALID_PARAMETER_VALUE = "invalid parameter value attempted";
    string internal constant INVALID_IMPLEMENTATION = "invalid pool implementation for given coin";
    string internal constant INVALID_POOL_IMPLEMENTATION =
        "invalid pool implementation for given coin";
    string internal constant INVALID_LP_TOKEN_IMPLEMENTATION =
        "invalid LP Token implementation for given coin";
    string internal constant INVALID_VAULT_IMPLEMENTATION =
        "invalid vault implementation for given coin";
    string internal constant INVALID_STAKER_VAULT_IMPLEMENTATION =
        "invalid stakerVault implementation for given coin";
    string internal constant INSUFFICIENT_ALLOWANCE = "insufficient allowance";
    string internal constant INSUFFICIENT_BALANCE = "insufficient balance";
    string internal constant INSUFFICIENT_AMOUNT_OUT = "Amount received less than min amount";
    string internal constant PROXY_CALL_FAILED = "proxy call failed";
    string internal constant INSUFFICIENT_AMOUNT_IN = "Amount spent more than max amount";
    string internal constant ADDRESS_ALREADY_SET = "Address is already set";
    string internal constant INSUFFICIENT_STRATEGY_BALANCE = "insufficient strategy balance";
    string internal constant INSUFFICIENT_FUNDS_RECEIVED = "insufficient funds received";
    string internal constant ADDRESS_DOES_NOT_EXIST = "address does not exist";
    string internal constant ADDRESS_FROZEN = "address is frozen";
    string internal constant ROLE_EXISTS = "role already exists";
    string internal constant CANNOT_REVOKE_ROLE = "cannot revoke role";
    string internal constant UNAUTHORIZED_ACCESS = "unauthorized access";
    string internal constant SAME_ADDRESS_NOT_ALLOWED = "same address not allowed";
    string internal constant SELF_TRANSFER_NOT_ALLOWED = "self-transfer not allowed";
    string internal constant ZERO_ADDRESS_NOT_ALLOWED = "zero address not allowed";
    string internal constant ZERO_TRANSFER_NOT_ALLOWED = "zero transfer not allowed";
    string internal constant THRESHOLD_TOO_HIGH = "threshold is too high, must be under 10";
    string internal constant INSUFFICIENT_THRESHOLD = "insufficient threshold";
    string internal constant NO_POSITION_EXISTS = "no position exists";
    string internal constant POSITION_ALREADY_EXISTS = "position already exists";
    string internal constant CANNOT_EXECUTE_IN_SAME_BLOCK = "cannot execute action in same block";
    string internal constant PROTOCOL_NOT_FOUND = "protocol not found";
    string internal constant TOP_UP_FAILED = "top up failed";
    string internal constant SWAP_PATH_NOT_FOUND = "swap path not found";
    string internal constant UNDERLYING_NOT_SUPPORTED = "underlying token not supported";
    string internal constant NOT_ENOUGH_FUNDS_WITHDRAWN =
        "not enough funds were withdrawn from the pool";
    string internal constant FAILED_TRANSFER = "transfer failed";
    string internal constant FAILED_MINT = "mint failed";
    string internal constant FAILED_REPAY_BORROW = "repay borrow failed";
    string internal constant FAILED_METHOD_CALL = "method call failed";
    string internal constant NOTHING_TO_CLAIM = "there is no claimable balance";
    string internal constant ERC20_BALANCE_EXCEEDED = "ERC20: transfer amount exceeds balance";
    string internal constant INVALID_MINTER =
        "the minter address of the LP token and the pool address do not match";
    string internal constant STAKER_VAULT_EXISTS = "a staker vault already exists for the token";
    string internal constant DEADLINE_NOT_ZERO = "deadline must be 0";
    string internal constant NOTHING_PENDING = "no pending change to reset";
    string internal constant DEADLINE_NOT_SET = "deadline is 0";
    string internal constant DEADLINE_NOT_REACHED = "deadline has not been reached yet";
    string internal constant DELAY_TOO_SHORT = "delay must be at least 3 days";
    string internal constant INSUFFICIENT_UPDATE_BALANCE =
        "insufficient funds for updating the position";
    string internal constant SAME_AS_CURRENT = "value must be different to existing value";
    string internal constant NOT_CAPPED = "the pool is not currently capped";
    string internal constant ALREADY_CAPPED = "the pool is already capped";
    string internal constant ALREADY_SHUTDOWN = "already shutdown";
    string internal constant EXCEEDS_DEPOSIT_CAP = "deposit exceeds deposit cap";
    string internal constant VALUE_TOO_LOW_FOR_GAS = "value too low to cover gas";
    string internal constant NOT_ENOUGH_FUNDS = "not enough funds to withdraw";
    string internal constant ESTIMATED_GAS_TOO_HIGH = "too much ETH will be used for gas";
    string internal constant GAUGE_KILLED = "gauge killed";
    string internal constant INVALID_TARGET = "Invalid Target";
    string internal constant DEPOSIT_FAILED = "deposit failed";
    string internal constant GAS_TOO_HIGH = "too much ETH used for gas";
    string internal constant GAS_BANK_BALANCE_TOO_LOW = "not enough ETH in gas bank to cover gas";
    string internal constant INVALID_TOKEN_TO_ADD = "Invalid token to add";
    string internal constant INVALID_TOKEN_TO_REMOVE = "token can not be removed";
    string internal constant TIME_DELAY_NOT_EXPIRED = "time delay not expired yet";
    string internal constant UNDERLYING_NOT_WITHDRAWABLE =
        "pool does not support additional underlying coins to be withdrawn";
    string internal constant STRATEGY_SHUTDOWN = "Strategy is shutdown";
    string internal constant POOL_SHUTDOWN = "Pool is shutdown";
    string internal constant ACTION_SHUTDOWN = "Action is shutdown";
    string internal constant ACTION_PAUSED = "Action is paused";
    string internal constant STRATEGY_DOES_NOT_EXIST = "Strategy does not exist";
    string internal constant GAUGE_STILL_ACTIVE = "Gauge still active";
    string internal constant UNSUPPORTED_UNDERLYING = "Underlying not supported";
    string internal constant NO_DEX_SET = "no dex has been set for token";
    string internal constant INVALID_TOKEN_PAIR = "invalid token pair";
    string internal constant TOKEN_NOT_USABLE = "token not usable for the specific action";
    string internal constant ADDRESS_NOT_ACTION = "address is not registered action";
    string internal constant ACTION_NOT_ACTIVE = "address is not active action";
    string internal constant INVALID_SLIPPAGE_TOLERANCE = "Invalid slippage tolerance";
    string internal constant INVALID_MAX_FEE = "invalid max fee";
    string internal constant POOL_NOT_PAUSED = "Pool must be paused to withdraw from reserve";
    string internal constant INTERACTION_LIMIT = "Max of one deposit and withdraw per block";
    string internal constant GAUGE_EXISTS = "Gauge already exists";
    string internal constant GAUGE_DOES_NOT_EXIST = "Gauge does not exist";
    string internal constant EXCEEDS_MAX_BOOST = "Not allowed to exceed maximum boost on Convex";
    string internal constant PREPARED_WITHDRAWAL =
        "Cannot relock funds when withdrawal is being prepared";
    string internal constant ASSET_NOT_SUPPORTED = "Asset not supported";
    string internal constant STALE_PRICE = "Price is stale";
    string internal constant NEGATIVE_PRICE = "Price is negative";
    string internal constant ROUND_NOT_COMPLETE = "Round not complete";
    string internal constant NOT_ENOUGH_MERO_STAKED = "Not enough MERO tokens staked";
    string internal constant RESERVE_ACCESS_EXCEEDED = "Reserve access exceeded";
}


// File libraries/ScaledMath.sol

pragma solidity 0.8.10;

/*
 * @dev To use functions of this contract, at least one of the numbers must
 * be scaled to `DECIMAL_SCALE`. The result will scaled to `DECIMAL_SCALE`
 * if both numbers are scaled to `DECIMAL_SCALE`, otherwise to the scale
 * of the number not scaled by `DECIMAL_SCALE`
 */
library ScaledMath {
    // solhint-disable-next-line private-vars-leading-underscore
    uint256 internal constant DECIMAL_SCALE = 1e18;
    // solhint-disable-next-line private-vars-leading-underscore
    uint256 internal constant ONE = 1e18;

    /**
     * @notice Performs a multiplication between two scaled numbers
     */
    function scaledMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / DECIMAL_SCALE;
    }

    /**
     * @notice Performs a division between two scaled numbers
     */
    function scaledDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * DECIMAL_SCALE) / b;
    }

    /**
     * @notice Performs a division between two numbers, rounding up the result
     */
    function scaledDivRoundUp(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * DECIMAL_SCALE + b - 1) / b;
    }

    /**
     * @notice Performs a division between two numbers, ignoring any scaling and rounding up the result
     */
    function divRoundUp(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a + b - 1) / b;
    }
}


// File libraries/Roles.sol

pragma solidity 0.8.10;

// solhint-disable private-vars-leading-underscore

library Roles {
    bytes32 internal constant GOVERNANCE = "governance";
    bytes32 internal constant ADDRESS_PROVIDER = "address_provider";
    bytes32 internal constant POOL_FACTORY = "pool_factory";
    bytes32 internal constant CONTROLLER = "controller";
    bytes32 internal constant GAUGE_ZAP = "gauge_zap";
    bytes32 internal constant MAINTENANCE = "maintenance";
    bytes32 internal constant INFLATION_ADMIN = "inflation_admin";
    bytes32 internal constant INFLATION_MANAGER = "inflation_manager";
    bytes32 internal constant POOL = "pool";
    bytes32 internal constant VAULT = "vault";
    bytes32 internal constant ACTION = "action";
}


// File contracts/access/AuthorizationBase.sol

pragma solidity 0.8.10;


/**
 * @notice Provides modifiers for authorization
 */
abstract contract AuthorizationBase {
    /**
     * @notice Only allows a sender with `role` to perform the given action
     */
    modifier onlyRole(bytes32 role) {
        require(_roleManager().hasRole(role, msg.sender), Error.UNAUTHORIZED_ACCESS);
        _;
    }

    /**
     * @notice Only allows a sender with GOVERNANCE role to perform the given action
     */
    modifier onlyGovernance() {
        require(_roleManager().hasRole(Roles.GOVERNANCE, msg.sender), Error.UNAUTHORIZED_ACCESS);
        _;
    }

    /**
     * @notice Only allows a sender with any of `roles` to perform the given action
     */
    modifier onlyRoles2(bytes32 role1, bytes32 role2) {
        require(_roleManager().hasAnyRole(role1, role2, msg.sender), Error.UNAUTHORIZED_ACCESS);
        _;
    }

    /**
     * @notice Only allows a sender with any of `roles` to perform the given action
     */
    modifier onlyRoles3(
        bytes32 role1,
        bytes32 role2,
        bytes32 role3
    ) {
        require(
            _roleManager().hasAnyRole(role1, role2, role3, msg.sender),
            Error.UNAUTHORIZED_ACCESS
        );
        _;
    }

    function roleManager() external view virtual returns (IRoleManager) {
        return _roleManager();
    }

    function _roleManager() internal view virtual returns (IRoleManager);
}


// File contracts/access/Authorization.sol

pragma solidity 0.8.10;

contract Authorization is AuthorizationBase {
    IRoleManager internal immutable __roleManager;

    constructor(IRoleManager roleManager) {
        __roleManager = roleManager;
    }

    function _roleManager() internal view override returns (IRoleManager) {
        return __roleManager;
    }
}


// File contracts/utils/Pausable.sol

pragma solidity 0.8.10;

abstract contract Pausable {
    bool public isPaused;

    modifier notPaused() {
        require(!isPaused, Error.CONTRACT_PAUSED);
        _;
    }

    modifier onlyAuthorizedToPause() {
        require(_isAuthorizedToPause(msg.sender), Error.UNAUTHORIZED_PAUSE);
        _;
    }

    /**
     * @notice Pause the contract.
     */
    function pause() external onlyAuthorizedToPause {
        isPaused = true;
    }

    /**
     * @notice Unpause the contract.
     */
    function unpause() external onlyAuthorizedToPause {
        isPaused = false;
    }

    /**
     * @notice Returns true if `account` is authorized to pause the contract
     * @dev This should be implemented in contracts inheriting `Pausable`
     * to provide proper access control
     */
    function _isAuthorizedToPause(address account) internal view virtual returns (bool);
}


// File contracts/pool/LiquidityPool.sol

pragma solidity 0.8.10;










/**
 * @dev Pausing/unpausing the pool will disable/re-enable deposits.
 */
abstract contract LiquidityPool is ILiquidityPool, Authorization, Pausable, Initializable {
    using AddressProviderHelpers for IAddressProvider;
    using ScaledMath for uint256;
    using SafeERC20 for IERC20;
    using SafeCast for uint256;

    struct WithdrawalFeeMeta {
        uint64 timeToWait;
        uint64 feeRatio;
        uint64 lastActionTimestamp;
    }

    IVault public vault;
    uint256 public reserveDeviation = 0.005e18;
    uint256 public requiredReserves = ScaledMath.ONE;
    uint256 public maxWithdrawalFee;
    uint256 public minWithdrawalFee;
    uint256 public withdrawalFeeDecreasePeriod = 1 weeks;

    /**
     * @notice even through admin votes and later governance, the withdrawal
     * fee will never be able to go above this value
     */
    uint256 internal constant _MAX_WITHDRAWAL_FEE = 0.05e18;

    /**
     * @notice Keeps track of the withdrawal fees on a per-address basis
     */
    mapping(address => WithdrawalFeeMeta) public withdrawalFeeMetas;

    IController public immutable controller;
    IAddressProvider public immutable addressProvider;

    IStakerVault public staker;
    ILpToken public lpToken;
    string public name;

    bool internal _shutdown;

    event RequiredReservesUpdated(uint256 requireReserves);
    event ReserveDeviationUpdated(uint256 reserveDeviation);
    event MinWithdrawalFeeUpdated(uint256 minWithdrawalFee);
    event MaxWithdrawalFeeUpdated(uint256 maxWithdrawalFee);
    event WithdrawalFeeDecreasePeriodUpdated(uint256 withdrawalFeeDecreasePeriod);
    event VaultUpdated(address vault);

    modifier notShutdown() {
        require(!_shutdown, Error.POOL_SHUTDOWN);
        _;
    }

    constructor(IController _controller)
        Authorization(_controller.addressProvider().getRoleManager())
    {
        controller = IController(_controller);
        addressProvider = IController(_controller).addressProvider();
    }

    /**
     * @notice Deposit funds into liquidity pool and mint LP tokens in exchange.
     * @param depositAmount Amount of the underlying asset to supply.
     * @return The actual amount minted.
     */
    function deposit(uint256 depositAmount) external payable override returns (uint256) {
        return depositFor(msg.sender, depositAmount, 0);
    }

    /**
     * @notice Deposit funds into liquidity pool and mint LP tokens in exchange.
     * @param depositAmount Amount of the underlying asset to supply.
     * @param minTokenAmount Minimum amount of LP tokens that should be minted.
     * @return The actual amount minted.
     */
    function deposit(uint256 depositAmount, uint256 minTokenAmount)
        external
        payable
        override
        returns (uint256)
    {
        return depositFor(msg.sender, depositAmount, minTokenAmount);
    }

    /**
     * @notice Deposit funds into liquidity pool and stake LP Tokens in Staker Vault.
     * @param depositAmount Amount of the underlying asset to supply.
     * @param minTokenAmount Minimum amount of LP tokens that should be minted.
     * @return The actual amount minted and staked.
     */
    function depositAndStake(uint256 depositAmount, uint256 minTokenAmount)
        external
        payable
        override
        returns (uint256)
    {
        uint256 amountMinted_ = depositFor(address(this), depositAmount, minTokenAmount);
        staker.stakeFor(msg.sender, amountMinted_);
        return amountMinted_;
    }

    /**
     * @notice Withdraws all funds from vault.
     * @dev Should be called in case of emergencies.
     */
    function shutdownStrategy() external override onlyGovernance {
        vault.shutdownStrategy();
    }

    /**
     * @notice permanently shuts down the pool
     * @param _shutdownStrategy if true, will also shut down the strategy
     * and withdraw all the funds back to the pool
     */
    function shutdownPool(bool _shutdownStrategy) external onlyRole(Roles.CONTROLLER) {
        require(!_shutdown, Error.ALREADY_SHUTDOWN);

        _shutdown = true;
        maxWithdrawalFee = 0;
        minWithdrawalFee = 0;

        if (_shutdownStrategy) {
            vault.shutdownStrategy();
        } else {
            vault.withdrawAvailableToPool();
        }

        emit Shutdown();
    }

    function setLpToken(address _lpToken)
        external
        override
        onlyRoles2(Roles.GOVERNANCE, Roles.POOL_FACTORY)
    {
        require(address(lpToken) == address(0), Error.ADDRESS_ALREADY_SET);
        require(ILpToken(_lpToken).minter() == address(this), Error.INVALID_MINTER);
        lpToken = ILpToken(_lpToken);
        _approveStakerVaultSpendingLpTokens();
        emit LpTokenSet(_lpToken);
    }

    /**
     * @notice Checkpoint function to update a user's withdrawal fees on deposit and redeem
     * @param from Address sending from
     * @param to Address sending to
     * @param amount Amount to redeem or deposit
     */
    function handleLpTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) external override {
        require(
            msg.sender == address(lpToken) || msg.sender == address(staker),
            Error.UNAUTHORIZED_ACCESS
        );
        if (
            addressProvider.isStakerVault(to, address(lpToken)) ||
            addressProvider.isStakerVault(from, address(lpToken)) ||
            addressProvider.isAction(to) ||
            addressProvider.isAction(from) ||
            addressProvider.isWhiteListedFeeHandler(to) ||
            addressProvider.isWhiteListedFeeHandler(from)
        ) {
            return;
        }

        if (to != address(0)) {
            _updateUserFeesOnDeposit(to, from, amount);
        }
    }

    /**
     * @notice Update required reserve ratio.
     * @param requireReserves_ New required reserve ratio.
     */
    function updateRequiredReserves(uint256 requireReserves_) external override onlyGovernance {
        require(requireReserves_ <= ScaledMath.ONE, Error.INVALID_AMOUNT);
        requiredReserves = requireReserves_;
        _rebalanceVault();
        emit RequiredReservesUpdated(requireReserves_);
    }

    /**
     * @notice Update reserve deviation ratio.
     * @param reserveDeviation_ New reserve deviation ratio.
     */
    function updateReserveDeviation(uint256 reserveDeviation_) external override onlyGovernance {
        require(reserveDeviation_ <= (ScaledMath.DECIMAL_SCALE * 50) / 100, Error.INVALID_AMOUNT);
        reserveDeviation = reserveDeviation_;
        _rebalanceVault();
        emit ReserveDeviationUpdated(reserveDeviation_);
    }

    /**
     * @notice Update min withdrawal fee.
     * @param minWithdrawalFee_ New min withdrawal fee.
     */
    function updateMinWithdrawalFee(uint256 minWithdrawalFee_) external override onlyGovernance {
        _checkFeeInvariants(minWithdrawalFee_, maxWithdrawalFee);
        minWithdrawalFee = minWithdrawalFee_;
        emit MinWithdrawalFeeUpdated(minWithdrawalFee_);
    }

    /**
     * @notice Update max withdrawal fee.
     * @param maxWithdrawalFee_ New max withdrawal fee.
     */
    function updateMaxWithdrawalFee(uint256 maxWithdrawalFee_) external override onlyGovernance {
        _checkFeeInvariants(minWithdrawalFee, maxWithdrawalFee_);
        maxWithdrawalFee = maxWithdrawalFee_;
        emit MaxWithdrawalFeeUpdated(maxWithdrawalFee_);
    }

    /**
     * @notice Update withdrawal fee decrease period.
     * @param withdrawalFeeDecreasePeriod_ New withdrawal fee decrease period.
     */
    function updateWithdrawalFeeDecreasePeriod(uint256 withdrawalFeeDecreasePeriod_)
        external
        override
        onlyGovernance
    {
        withdrawalFeeDecreasePeriod = withdrawalFeeDecreasePeriod_;
        emit WithdrawalFeeDecreasePeriodUpdated(withdrawalFeeDecreasePeriod_);
    }

    /**
     * @notice Set the staker vault for this pool's LP token
     * @dev Staker vault and LP token pairs are immutable and the staker vault can only be set once for a pool.
     *      Only one vault exists per LP token. This information will be retrieved from the controller of the pool.
     */
    function setStaker() external override onlyRoles2(Roles.GOVERNANCE, Roles.POOL_FACTORY) {
        require(address(staker) == address(0), Error.ADDRESS_ALREADY_SET);
        address stakerVault = addressProvider.getStakerVault(address(lpToken));
        require(stakerVault != address(0), Error.ZERO_ADDRESS_NOT_ALLOWED);
        staker = IStakerVault(stakerVault);
        _approveStakerVaultSpendingLpTokens();
        emit StakerVaultSet(stakerVault);
    }

    /**
     * @notice Update vault.
     * @param vault_ Address of new Vault contract.
     */
    function updateVault(address vault_) external override onlyGovernance {
        IVault oldVault = IVault(vault);
        if (address(oldVault) != address(0)) oldVault.shutdownStrategy();
        vault = IVault(vault_);
        addressProvider.updateVault(address(oldVault), vault_);
        emit VaultUpdated(vault_);
    }

    /**
     * @notice Redeems the underlying asset by burning LP tokens.
     * @param redeemLpTokens Number of tokens to burn for redeeming the underlying.
     * @return Actual amount of the underlying redeemed.
     */
    function redeem(uint256 redeemLpTokens) external override returns (uint256) {
        return redeem(redeemLpTokens, 0);
    }

    /**
     * @notice Rebalance vault according to required underlying backing reserves.
     */
    function rebalanceVault() external override onlyGovernance {
        _rebalanceVault();
    }

    /**
     * @notice Deposit funds for an address into liquidity pool and mint LP tokens in exchange.
     * @param account Account to deposit for.
     * @param depositAmount Amount of the underlying asset to supply.
     * @return Actual amount minted.
     */
    function depositFor(address account, uint256 depositAmount)
        external
        payable
        override
        returns (uint256)
    {
        return depositFor(account, depositAmount, 0);
    }

    /**
     * @notice Redeems the underlying asset by burning LP tokens, unstaking any LP tokens needed.
     * @param redeemLpTokens Number of tokens to unstake and/or burn for redeeming the underlying.
     * @param minRedeemAmount Minimum amount of underlying that should be received.
     * @return Actual amount of the underlying redeemed.
     */
    function unstakeAndRedeem(uint256 redeemLpTokens, uint256 minRedeemAmount)
        external
        override
        returns (uint256)
    {
        uint256 lpBalance_ = lpToken.balanceOf(msg.sender);
        require(
            lpBalance_ + staker.balanceOf(msg.sender) >= redeemLpTokens,
            Error.INSUFFICIENT_BALANCE
        );
        if (lpBalance_ < redeemLpTokens) {
            staker.unstakeFor(msg.sender, msg.sender, redeemLpTokens - lpBalance_);
        }
        return redeem(redeemLpTokens, minRedeemAmount);
    }

    /**
     * @notice Returns the address of the LP token of this pool
     * @return The address of the LP token
     */
    function getLpToken() external view override returns (address) {
        return address(lpToken);
    }

    /**
     * @return whether the pool is shut down or not
     */
    function isShutdown() external view override returns (bool) {
        return _shutdown;
    }

    /**
     * @notice Calculates the amount of LP tokens that need to be redeemed to get a certain amount of underlying (includes fees and exchange rate)
     * @param account Address of the account redeeming.
     * @param underlyingAmount The amount of underlying desired.
     * @return Amount of LP tokens that need to be redeemed.
     */
    function calcRedeem(address account, uint256 underlyingAmount)
        external
        view
        override
        returns (uint256)
    {
        require(underlyingAmount > 0, Error.INVALID_AMOUNT);
        ILpToken lpToken_ = lpToken;
        require(lpToken_.balanceOf(account) > 0, Error.INSUFFICIENT_BALANCE);

        uint256 currentExchangeRate = exchangeRate();
        uint256 withoutFeesLpAmount = underlyingAmount.scaledDiv(currentExchangeRate);
        if (withoutFeesLpAmount == lpToken_.totalSupply()) {
            return withoutFeesLpAmount;
        }

        WithdrawalFeeMeta memory meta = withdrawalFeeMetas[account];

        uint256 currentFeeRatio;
        if (!addressProvider.isAction(account)) {
            currentFeeRatio = getNewCurrentFees(
                meta.timeToWait,
                meta.lastActionTimestamp,
                meta.feeRatio
            );
        }
        uint256 scalingFactor = currentExchangeRate.scaledMul((ScaledMath.ONE - currentFeeRatio));
        uint256 neededLpTokens = underlyingAmount.scaledDivRoundUp(scalingFactor);

        return neededLpTokens;
    }

    function getUnderlying() external view virtual override returns (address);

    /**
     * @notice Deposit funds for an address into liquidity pool and mint LP tokens in exchange.
     * @param account Account to deposit for.
     * @param depositAmount Amount of the underlying asset to supply.
     * @param minTokenAmount Minimum amount of LP tokens that should be minted.
     * @return Actual amount minted.
     */
    function depositFor(
        address account,
        uint256 depositAmount,
        uint256 minTokenAmount
    ) public payable override notPaused notShutdown returns (uint256) {
        if (depositAmount == 0) return 0;
        uint256 rate = exchangeRate();

        _doTransferInFromSender(depositAmount);
        uint256 mintedLp = depositAmount.scaledDiv(rate);
        require(mintedLp >= minTokenAmount && mintedLp > 0, Error.INVALID_AMOUNT);

        lpToken.mint(account, mintedLp);

        _rebalanceVault();

        if (msg.sender == account || address(this) == account) {
            emit Deposit(msg.sender, depositAmount, mintedLp);
        } else {
            emit DepositFor(msg.sender, account, depositAmount, mintedLp);
        }
        return mintedLp;
    }

    /**
     * @notice Redeems the underlying asset by burning LP tokens.
     * @param redeemLpTokens Number of tokens to burn for redeeming the underlying.
     * @param minRedeemAmount Minimum amount of underlying that should be received.
     * @return Actual amount of the underlying redeemed.
     */
    function redeem(uint256 redeemLpTokens, uint256 minRedeemAmount)
        public
        override
        returns (uint256)
    {
        require(redeemLpTokens > 0, Error.INVALID_AMOUNT);
        ILpToken lpToken_ = lpToken;
        require(lpToken_.balanceOf(msg.sender) >= redeemLpTokens, Error.INSUFFICIENT_BALANCE);

        uint256 withdrawalFee = addressProvider.isAction(msg.sender)
            ? 0
            : getWithdrawalFee(msg.sender, redeemLpTokens);
        uint256 redeemMinusFees = redeemLpTokens - withdrawalFee;
        // Pay no fees on the last withdrawal (avoid locking funds in the pool)
        if (redeemLpTokens == lpToken_.totalSupply()) {
            redeemMinusFees = redeemLpTokens;
        }
        uint256 redeemUnderlying = redeemMinusFees.scaledMul(exchangeRate());
        require(redeemUnderlying >= minRedeemAmount, Error.NOT_ENOUGH_FUNDS_WITHDRAWN);

        if (!_shutdown) {
            _rebalanceVault(redeemUnderlying);
        }

        lpToken_.burn(msg.sender, redeemLpTokens);
        _doTransferOut(payable(msg.sender), redeemUnderlying);
        emit Redeem(msg.sender, redeemUnderlying, redeemLpTokens);
        return redeemUnderlying;
    }

    /**
     * @notice Compute current exchange rate of LP tokens to underlying scaled to 1e18.
     * @dev Exchange rate means: underlying = LP token * exchangeRate
     * @return Current exchange rate.
     */
    function exchangeRate() public view override returns (uint256) {
        uint256 totalUnderlying_ = totalUnderlying();
        uint256 totalSupply = lpToken.totalSupply();
        if (totalSupply == 0 || totalUnderlying_ == 0) {
            return ScaledMath.ONE;
        }

        return totalUnderlying_.scaledDiv(totalSupply);
    }

    /**
     * @notice Compute total amount of underlying tokens for this pool.
     * @return Total amount of underlying in pool.
     */
    function totalUnderlying() public view override returns (uint256) {
        IVault vault_ = vault;
        if (address(vault_) == address(0)) {
            return _getBalanceUnderlying();
        }
        uint256 investedUnderlying = vault_.getTotalUnderlying();
        return investedUnderlying + _getBalanceUnderlying();
    }

    /**
     * @notice Returns the withdrawal fee for `account`
     * @param account Address to get the withdrawal fee for
     * @param amount Amount to calculate the withdrawal fee for
     * @return Withdrawal fee in LP tokens
     */
    function getWithdrawalFee(address account, uint256 amount)
        public
        view
        override
        returns (uint256)
    {
        WithdrawalFeeMeta memory meta = withdrawalFeeMetas[account];

        if (lpToken.balanceOf(account) == 0) {
            return 0;
        }
        uint256 currentFee = getNewCurrentFees(
            meta.timeToWait,
            meta.lastActionTimestamp,
            meta.feeRatio
        );
        return amount.scaledMul(currentFee);
    }

    /**
     * @notice Calculates the withdrawal fee a user would currently need to pay on currentBalance.
     * @param timeToWait The total time to wait until the withdrawal fee reached the min. fee
     * @param lastActionTimestamp Timestamp of the last fee update
     * @param feeRatio Fees that would currently be paid on the user's entire balance
     * @return Updated fee amount on the currentBalance
     */
    function getNewCurrentFees(
        uint256 timeToWait,
        uint256 lastActionTimestamp,
        uint256 feeRatio
    ) public view override returns (uint256) {
        uint256 timeElapsed = _getTime() - lastActionTimestamp;
        uint256 minFeePercentage = minWithdrawalFee;
        if (timeElapsed >= timeToWait || minFeePercentage > feeRatio) {
            return minFeePercentage;
        }
        uint256 elapsedShare = timeElapsed.scaledDiv(timeToWait);
        return feeRatio - (feeRatio - minFeePercentage).scaledMul(elapsedShare);
    }

    function _rebalanceVault() internal {
        _rebalanceVault(0);
    }

    function _initialize(
        string calldata name_,
        address vault_,
        uint256 maxWithdrawalFee_,
        uint256 minWithdrawalFee_
    ) internal initializer {
        name = name_;
        vault = IVault(vault_);
        maxWithdrawalFee = maxWithdrawalFee_;
        minWithdrawalFee = minWithdrawalFee_;
    }

    function _approveStakerVaultSpendingLpTokens() internal {
        address staker_ = address(staker);
        address lpToken_ = address(lpToken);
        if (staker_ == address(0) || lpToken_ == address(0)) return;
        if (IERC20(lpToken_).allowance(address(this), staker_) > 0) return;
        IERC20(lpToken_).safeApprove(staker_, type(uint256).max);
    }

    function _doTransferInFromSender(uint256 amount) internal virtual;

    function _doTransferOut(address payable to, uint256 amount) internal virtual;

    /**
     * @dev Rebalances the pool's allocations to the vault
     * @param underlyingToWithdraw Amount of underlying to withdraw such that after the withdrawal the pool and vault allocations are correctly balanced.
     */
    function _rebalanceVault(uint256 underlyingToWithdraw) internal {
        IVault vault_ = vault;

        if (address(vault_) == address(0)) return;
        uint256 lockedLp = staker.getStakedByActions();
        uint256 totalUnderlyingStaked = lockedLp.scaledMul(exchangeRate());

        uint256 underlyingBalance = _getBalanceUnderlying(true);
        uint256 maximumDeviation = totalUnderlyingStaked.scaledMul(reserveDeviation);

        uint256 nextTargetBalance = totalUnderlyingStaked.scaledMul(requiredReserves);

        if (
            underlyingToWithdraw > underlyingBalance ||
            (underlyingBalance - underlyingToWithdraw) + maximumDeviation < nextTargetBalance
        ) {
            uint256 requiredDeposits = nextTargetBalance + underlyingToWithdraw - underlyingBalance;
            vault_.withdraw(requiredDeposits);
        } else {
            uint256 nextBalance = underlyingBalance - underlyingToWithdraw;
            if (nextBalance > nextTargetBalance + maximumDeviation) {
                uint256 excessDeposits = nextBalance - nextTargetBalance;
                _doTransferOut(payable(address(vault_)), excessDeposits);
                vault_.deposit();
            }
        }
    }

    function _updateUserFeesOnDeposit(
        address account,
        address from,
        uint256 amountAdded
    ) internal {
        WithdrawalFeeMeta storage meta = withdrawalFeeMetas[account];
        uint256 balance = lpToken.balanceOf(account) +
            staker.stakedAndActionLockedBalanceOf(account);
        uint256 newCurrentFeeRatio = getNewCurrentFees(
            meta.timeToWait,
            meta.lastActionTimestamp,
            meta.feeRatio
        );
        uint256 shareAdded = amountAdded.scaledDiv(amountAdded + balance);
        uint256 shareExisting = ScaledMath.ONE - shareAdded;
        uint256 feeOnDeposit;
        if (from == address(0)) {
            feeOnDeposit = maxWithdrawalFee;
            meta.lastActionTimestamp = _getTime().toUint64();
        } else {
            WithdrawalFeeMeta memory fromMeta = withdrawalFeeMetas[from];
            feeOnDeposit = getNewCurrentFees(
                fromMeta.timeToWait,
                fromMeta.lastActionTimestamp,
                fromMeta.feeRatio
            );
            uint256 minTime_ = _getTime() - meta.timeToWait;
            if (meta.lastActionTimestamp < minTime_) {
                meta.lastActionTimestamp = minTime_.toUint64();
            }
            meta.lastActionTimestamp = ((shareExisting *
                uint256(meta.lastActionTimestamp) +
                shareAdded *
                _getTime()) / (shareExisting + shareAdded)).toUint64();
        }

        uint256 newFeeRatio = shareExisting.scaledMul(newCurrentFeeRatio) +
            shareAdded.scaledMul(feeOnDeposit);

        meta.feeRatio = newFeeRatio.toUint64();
        meta.timeToWait = withdrawalFeeDecreasePeriod.toUint64();
    }

    function _getBalanceUnderlying() internal view virtual returns (uint256);

    function _getBalanceUnderlying(bool transferInDone) internal view virtual returns (uint256);

    function _isAuthorizedToPause(address account) internal view override returns (bool) {
        return _roleManager().hasRole(Roles.GOVERNANCE, account);
    }

    /**
     * @dev Overridden for testing
     */
    function _getTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function _checkFeeInvariants(uint256 minFee, uint256 maxFee) internal pure {
        require(maxFee >= minFee, Error.INVALID_AMOUNT);
        require(maxFee <= _MAX_WITHDRAWAL_FEE, Error.INVALID_AMOUNT);
    }
}


// File interfaces/pool/IErc20Pool.sol

pragma solidity 0.8.10;

interface IErc20Pool {
    function initialize(
        string calldata name_,
        address underlying_,
        address vault_,
        uint256 maxWithdrawalFee_,
        uint256 minWithdrawalFee_
    ) external;
}


// File contracts/pool/Erc20Pool.sol

pragma solidity 0.8.10;


contract Erc20Pool is LiquidityPool, IErc20Pool {
    using SafeERC20 for IERC20;

    address private _underlying;

    constructor(IController _controller) LiquidityPool(_controller) {}

    function initialize(
        string calldata name_,
        address underlying_,
        address vault_,
        uint256 maxWithdrawalFee_,
        uint256 minWithdrawalFee_
    ) public override {
        require(underlying_ != address(0), Error.ZERO_ADDRESS_NOT_ALLOWED);
        _underlying = underlying_;
        _initialize(name_, vault_, maxWithdrawalFee_, minWithdrawalFee_);
    }

    function getUnderlying() public view override returns (address) {
        return _underlying;
    }

    function _doTransferInFromSender(uint256 amount) internal override {
        require(msg.value == 0, Error.INVALID_VALUE);
        IERC20(_underlying).safeTransferFrom(msg.sender, address(this), amount);
    }

    function _doTransferOut(address payable to, uint256 amount) internal override {
        IERC20(_underlying).safeTransfer(to, amount);
    }

    function _getBalanceUnderlying() internal view override returns (uint256) {
        return IERC20(_underlying).balanceOf(address(this));
    }

    function _getBalanceUnderlying(bool) internal view override returns (uint256) {
        return _getBalanceUnderlying();
    }
}
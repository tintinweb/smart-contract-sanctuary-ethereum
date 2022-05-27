// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IAccessControlAngle.sol";

/**
 * @dev This contract is fully forked from OpenZeppelin `AccessControlUpgradeable`.
 * The only difference is the removal of the ERC165 implementation as it's not
 * needed in Angle.
 *
 * Contract module that allows children to implement role-based access
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
abstract contract AccessControlAngleUpgradeable is Initializable, IAccessControlAngle {
    function __AccessControl_init() internal initializer {
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {}

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
     * bearer except when using {_setupRole}.
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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, msg.sender);
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     */
    function grantRole(bytes32 role, address account) external override onlyRole(getRoleAdmin(role)) {
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
     */
    function revokeRole(bytes32 role, address account) external override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account) external override {
        require(account == msg.sender, "71");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) internal {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes32 role, address account) internal {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

/// @title IAccessControl
/// @author Forked from OpenZeppelin
/// @notice Interface for `AccessControl` contracts
interface IAccessControlAngle {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./IAccessControlAngle.sol";

/// @title IGenericLender
/// @author Yearn with slight modifications from Angle Core Team
/// @dev Interface for the `GenericLender` contract, the base interface for contracts interacting
/// with lending and yield farming platforms
interface IGenericLender is IAccessControlAngle {
    function lenderName() external view returns (string memory);

    function nav() external view returns (uint256);

    function strategy() external view returns (address);

    function apr() external view returns (uint256);

    function weightedApr() external view returns (uint256);

    function withdraw(uint256 amount) external returns (uint256);

    function emergencyWithdraw(uint256 amount) external;

    function deposit() external;

    function withdrawAll() external returns (bool);

    function hasAssets() external view returns (bool);

    function aprAfterDeposit(uint256 amount) external view returns (uint256);

    function sweep(address _token, address to) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

// Struct for the parameters associated to a strategy interacting with a collateral `PoolManager`
// contract
struct StrategyParams {
    // Timestamp of last report made by this strategy
    // It is also used to check if a strategy has been initialized
    uint256 lastReport;
    // Total amount the strategy is expected to have
    uint256 totalStrategyDebt;
    // The share of the total assets in the `PoolManager` contract that the `strategy` can access to.
    uint256 debtRatio;
}

/// @title IPoolManagerFunctions
/// @author Angle Core Team
/// @notice Interface for the collateral poolManager contracts handling each one type of collateral for
/// a given stablecoin
/// @dev Only the functions used in other contracts of the protocol are left here
interface IPoolManagerFunctions {
    // ============================ Yield Farming ==================================

    function creditAvailable() external view returns (uint256);

    function debtOutstanding() external view returns (uint256);

    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external;

    // ============================= Getters =======================================

    function getBalance() external view returns (uint256);

    function getTotalAsset() external view returns (uint256);
}

/// @title IPoolManager
/// @author Angle Core Team
/// @notice Previous interface with additionnal getters for public variables and mappings
/// @dev Used in other contracts of the protocol
interface IPoolManager is IPoolManagerFunctions {
    function stableMaster() external view returns (address);

    function perpetualManager() external view returns (address);

    function token() external view returns (address);

    function totalDebt() external view returns (uint256);

    function strategies(address _strategy) external view returns (StrategyParams memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "./IAccessControlAngle.sol";

/// @title IStrategy
/// @author Inspired by Yearn with slight changes from Angle Core Team
/// @notice Interface for yield farming strategies
interface IStrategy is IAccessControlAngle {
    function estimatedAPR() external view returns (uint256);

    function poolManager() external view returns (address);

    function want() external view returns (address);

    function isActive() external view returns (bool);

    function estimatedTotalAssets() external view returns (uint256);

    function harvestTrigger(uint256 callCost) external view returns (bool);

    function harvest() external;

    function withdraw(uint256 _amountNeeded) external returns (uint256 amountFreed, uint256 _loss);

    function setEmergencyExit() external;

    function addGuardian(address _guardian) external;

    function revokeGuardian(address _guardian) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

import "./CTokenI.sol";

interface CErc20I is CTokenI {
    function mint(uint256 mintAmount) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function underlying() external view returns (address);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function decimals() external returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;
import "./InterestRateModel.sol";

interface CTokenI {
    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function interestRateModel() external view returns (InterestRateModel);

    function totalReserves() external view returns (uint256);

    function reserveFactorMantissa() external view returns (uint256);

    function totalBorrows() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

import "./CTokenI.sol";

interface IComptroller {
    function compSupplySpeeds(address cToken) external view returns (uint256);

    function claimComp(
        address[] memory holders,
        CTokenI[] memory cTokens,
        bool borrowers,
        bool suppliers
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

interface InterestRateModel {
    /**
     * @notice Calculates the current supply interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @param reserveFactorMantissa The current reserve factor the market has
     * @return The supply rate per block (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) external view returns (uint256);

    // Rinkeby function
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 _reserves
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "../../../interfaces/external/compound/CErc20I.sol";
import "../../../interfaces/external/compound/IComptroller.sol";
import "../../../interfaces/external/compound/InterestRateModel.sol";

import "./GenericLenderBaseUpgradeable.sol";

/// @title GenericCompoundV3
/// @author Forked from here: https://github.com/Grandthrax/yearnV2-generic-lender-strat/blob/master/contracts/GenericLender/GenericCompound.sol
contract GenericCompoundUpgradeable is GenericLenderBaseUpgradeable {
    using SafeERC20 for IERC20;
    using Address for address;

    uint256 public constant BLOCKS_PER_YEAR = 2_350_000;

    AggregatorV3Interface public constant oracle = AggregatorV3Interface(0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5);
    IComptroller public constant comptroller = IComptroller(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    address public constant comp = 0xc00e94Cb662C3520282E6f5717214004A7f26888;

    // ======================== References to contracts ============================

    CErc20I public cToken;
    uint256 private dust;

    // =============================== Errors ======================================

    error FailedToMint();
    error FailedToRecoverETH();
    error FailedToRedeem();
    error InvalidOracleValue();
    error WrongCToken();

    // ============================= Constructor ===================================

    /// @notice Initializer of the `GenericCompound`
    /// @param _strategy Reference to the strategy using this lender
    /// @param _cToken Address of the cToken
    /// @param governorList List of addresses with governor privilege
    /// @param keeperList List of addresses with keeper privilege
    /// @param guardian Address of the guardian
    function initialize(
        address _strategy,
        string memory _name,
        address _cToken,
        address[] memory governorList,
        address guardian,
        address[] memory keeperList
    ) external {
        _initialize(_strategy, _name, governorList, guardian, keeperList);

        cToken = CErc20I(_cToken);
        if (CErc20I(_cToken).underlying() != address(want)) revert WrongCToken();

        want.safeApprove(_cToken, type(uint256).max);
        IERC20(comp).safeApprove(oneInch, type(uint256).max);
    }

    // ===================== External Strategy Functions ===========================

    /// @notice Deposits the current balance of the contract to the lending platform
    function deposit() external override onlyRole(STRATEGY_ROLE) {
        uint256 balance = want.balanceOf(address(this));
        if (cToken.mint(balance) != 0) revert FailedToMint();
    }

    /// @notice Withdraws a given amount from lender
    /// @param amount The amount the caller wants to withdraw
    /// @return Amount actually withdrawn
    function withdraw(uint256 amount) external override onlyRole(STRATEGY_ROLE) returns (uint256) {
        return _withdraw(amount);
    }

    /// @notice Withdraws as much as possible from the lending platform
    /// @return Whether everything was withdrawn or not
    function withdrawAll() external override onlyRole(STRATEGY_ROLE) returns (bool) {
        uint256 invested = _nav();
        uint256 returned = _withdraw(invested);
        return returned >= invested;
    }

    // ========================== External View Functions ==========================

    /// @notice Helper function the current balance of cTokens
    function underlyingBalanceStored() public view override returns (uint256 balance) {
        uint256 currentCr = cToken.balanceOf(address(this));
        if (currentCr == 0) {
            balance = 0;
        } else {
            //The current exchange rate as an unsigned integer, scaled by 1e18.
            balance = (currentCr * cToken.exchangeRateStored()) / 1e18;
        }
    }

    /// @notice Returns an estimation of the current Annual Percentage Rate after a new deposit
    /// of `amount`
    /// @param amount Amount to add to the lending platform, and that we want to take into account
    /// in the apr computation
    function aprAfterDeposit(uint256 amount) external view override returns (uint256) {
        uint256 cashPrior = want.balanceOf(address(cToken));

        uint256 borrows = cToken.totalBorrows();

        uint256 reserves = cToken.totalReserves();

        uint256 reserverFactor = cToken.reserveFactorMantissa();

        InterestRateModel model = cToken.interestRateModel();

        // The supply rate is derived from the borrow rate, reserve factor and the amount of total borrows.
        uint256 supplyRate = model.getSupplyRate(cashPrior + amount, borrows, reserves, reserverFactor);
        // Adding the yield from comp
        return supplyRate * BLOCKS_PER_YEAR + _incentivesRate(amount);
    }

    // ================================= Governance ================================

    /// @notice Withdraws as much as possible in case of emergency and sends it to the `PoolManager`
    /// @param amount Amount to withdraw
    /// @dev Does not check if any error occurs or if the amount withdrawn is correct
    function emergencyWithdraw(uint256 amount) external override onlyRole(GUARDIAN_ROLE) {
        // Do not care about errors here, what is important is to withdraw what is possible
        cToken.redeemUnderlying(amount);

        want.safeTransfer(address(poolManager), want.balanceOf(address(this)));
    }

    /// @notice Allow to modify the dust amount
    /// @param dust_ Amount under which the contract do not try to redeem from Compouns
    /// @dev Set in a function because contract was already initalized
    function setDust(uint256 dust_) external onlyRole(GUARDIAN_ROLE) {
        dust = dust_;
    }

    // ============================= Internal Functions ============================

    /// @notice See `apr`
    function _apr() internal view override returns (uint256) {
        return cToken.supplyRatePerBlock() * BLOCKS_PER_YEAR + _incentivesRate(0);
    }

    /// @notice See `withdraw`
    function _withdraw(uint256 amount) internal returns (uint256) {
        uint256 balanceUnderlying = cToken.balanceOfUnderlying(address(this));
        uint256 looseBalance = want.balanceOf(address(this));
        uint256 total = balanceUnderlying + looseBalance;

        if (amount > total) {
            // Can't withdraw more than we own
            amount = total;
        }

        if (looseBalance >= amount) {
            want.safeTransfer(address(strategy), amount);
            return amount;
        }

        // Not state changing but OK because of previous call
        uint256 liquidity = want.balanceOf(address(cToken));

        if (liquidity > 1) {
            uint256 toWithdraw = amount - looseBalance;
            // If amount is too low then do not try to withdraw it
            // Risk being: the tx can revert because the cToken needed to be sent == 0
            if (toWithdraw >= dust) {
                if (toWithdraw <= liquidity) {
                    // We can take all
                    if (cToken.redeemUnderlying(toWithdraw) != 0) revert FailedToRedeem();
                } else {
                    // Take all we can
                    if (cToken.redeemUnderlying(liquidity) != 0) revert FailedToRedeem();
                }
            }
        }
        address[] memory holders = new address[](1);
        CTokenI[] memory cTokens = new CTokenI[](1);
        holders[0] = address(this);
        cTokens[0] = cToken;
        comptroller.claimComp(holders, cTokens, true, true);

        looseBalance = want.balanceOf(address(this));
        want.safeTransfer(address(strategy), looseBalance);
        return looseBalance;
    }

    /// @notice Calculates APR from Compound's Liquidity Mining Program
    /// @param amountToAdd Amount to add to the `totalSupplyInWant` (for the `aprAfterDeposit` function)
    function _incentivesRate(uint256 amountToAdd) internal view returns (uint256) {
        uint256 supplySpeed = comptroller.compSupplySpeeds(address(cToken));
        uint256 totalSupplyInWant = (cToken.totalSupply() * cToken.exchangeRateStored()) / 1e18 + amountToAdd;
        // `supplySpeed` is in `COMP` unit -> the following operation is going to put it in `want` unit
        supplySpeed = _comptoWant(supplySpeed);
        uint256 incentivesRate;
        // Added for testing purposes and to handle the edge case where there is nothing left in a market
        if (totalSupplyInWant == 0) {
            incentivesRate = supplySpeed * BLOCKS_PER_YEAR;
        } else {
            // `incentivesRate` is expressed in base 18 like all APR
            incentivesRate = (supplySpeed * BLOCKS_PER_YEAR * 1e18) / totalSupplyInWant;
        }
        return (incentivesRate * 9500) / 10000; // 95% of estimated APR to avoid overestimations
    }

    /// @notice Estimates the value of `_amount` COMP tokens
    /// @param _amount Amount of comp to compute the `want` price of
    /// @dev This function uses a ChainLink oracle to easily compute the price
    function _comptoWant(uint256 _amount) internal view returns (uint256) {
        if (_amount == 0) {
            return 0;
        }
        (uint80 roundId, int256 ratio, , , uint80 answeredInRound) = oracle.latestRoundData();
        if (ratio == 0 || roundId > answeredInRound) revert InvalidOracleValue();
        uint256 castedRatio = uint256(ratio);

        // Checking whether we should multiply or divide by the ratio computed
        return (_amount * castedRatio * wantBase) / 1e26;
    }

    /// @notice Specifies the token managed by this contract during normal operation
    function _protectedTokens() internal view override returns (address[] memory) {
        address[] memory protected = new address[](2);
        protected[0] = address(want);
        protected[1] = address(cToken);
        return protected;
    }

    /// @notice Recovers ETH from the contract
    /// @param amount Amount to be recovered
    function recoverETH(address to, uint256 amount) external onlyRole(GUARDIAN_ROLE) {
        if (!payable(to).send(amount)) revert FailedToRecoverETH();
    }

    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../../../external/AccessControlAngleUpgradeable.sol";

import "../../../interfaces/IGenericLender.sol";
import "../../../interfaces/IPoolManager.sol";
import "../../../interfaces/IStrategy.sol";

/// @title GenericLenderBaseUpgradeable
/// @author Forked from https://github.com/Grandthrax/yearnV2-generic-lender-strat/tree/master/contracts/GenericLender
/// @notice A base contract to build contracts that lend assets to protocols
abstract contract GenericLenderBaseUpgradeable is IGenericLender, AccessControlAngleUpgradeable {
    using SafeERC20 for IERC20;

    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
    bytes32 public constant STRATEGY_ROLE = keccak256("STRATEGY_ROLE");
    bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");

    // ======================= References to contracts =============================

    address internal constant oneInch = 0x1111111254fb6c44bAC0beD2854e76F90643097d;

    // ========================= References and Parameters =========================

    string public override lenderName;
    /// @notice Reference to the protocol's collateral poolManager
    IPoolManager public poolManager;
    /// @notice Reference to the `Strategy`
    address public override strategy;
    /// @notice Reference to the token lent
    IERC20 public want;
    /// @notice Base of the asset handled by the lender
    uint256 public wantBase;

    uint256[45] private __gapBaseLender;

    // ================================ Errors =====================================

    error ErrorSwap();
    error IncompatibleLengths();
    error ProtectedToken();
    error TooSmallAmount();

    // ================================ Initializer ================================

    /// @notice Initalizer of the `GenericLenderBase`
    /// @param _strategy Reference to the strategy using this lender
    /// @param _name Name of the lender
    /// @param governorList List of addresses with governor privilege
    /// @param guardian Address of the guardian
    /// @param keeperList List of keeper addresses
    function _initialize(
        address _strategy,
        string memory _name,
        address[] memory governorList,
        address guardian,
        address[] memory keeperList
    ) internal initializer {
        strategy = _strategy;
        // The corresponding `PoolManager` is inferred from the `Strategy`
        poolManager = IPoolManager(IStrategy(strategy).poolManager());
        want = IERC20(poolManager.token());
        lenderName = _name;

        _setupRole(GUARDIAN_ROLE, address(poolManager));
        for (uint256 i = 0; i < governorList.length; i++) {
            _setupRole(GUARDIAN_ROLE, governorList[i]);
        }

        _setupRole(KEEPER_ROLE, guardian);
        for (uint256 i = 0; i < keeperList.length; i++) {
            _setupRole(KEEPER_ROLE, keeperList[i]);
        }

        _setRoleAdmin(KEEPER_ROLE, GUARDIAN_ROLE);

        _setupRole(GUARDIAN_ROLE, guardian);
        _setupRole(STRATEGY_ROLE, _strategy);
        _setRoleAdmin(GUARDIAN_ROLE, STRATEGY_ROLE);
        _setRoleAdmin(STRATEGY_ROLE, GUARDIAN_ROLE);
        wantBase = 10**IERC20Metadata(address(want)).decimals();
        want.safeApprove(_strategy, type(uint256).max);
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    // ============================ View Functions =================================

    /// @notice Returns an estimation of the current Annual Percentage Rate
    function apr() external view override returns (uint256) {
        return _apr();
    }

    /// @notice Returns an estimation of the current Annual Percentage Rate weighted by a factor
    function weightedApr() external view override returns (uint256) {
        uint256 a = _apr();
        return a * _nav();
    }

    /// @notice Helper function to get the current total of assets managed by the lender.
    function nav() external view override returns (uint256) {
        return _nav();
    }

    /// @notice Check if assets are currently managed by the lender
    /// @dev We're considering that the strategy has no assets if it has less than 10 of the
    /// underlying asset in total to avoid the case where there is dust remaining on the lending market we cannot
    /// withdraw everything
    function hasAssets() external view override returns (bool) {
        return _nav() > 10 * wantBase;
    }

    /// @notice See `nav`
    function _nav() internal view returns (uint256) {
        return want.balanceOf(address(this)) + underlyingBalanceStored();
    }

    /// @notice See `apr`
    function _apr() internal view virtual returns (uint256);

    /// @notice Returns the current balance invested on the lender and related staking contracts
    function underlyingBalanceStored() public view virtual returns (uint256 balance);

    // ============================ Governance Functions ===========================

    /// @notice Override this to add all tokens/tokenized positions this contract
    /// manages on a *persistent* basis (e.g. not just for swapping back to
    /// want ephemerally).
    ///
    /// Example:
    /// ```
    ///    function _protectedTokens() internal override view returns (address[] memory) {
    ///      address[] memory protected = new address[](3);
    ///      protected[0] = tokenA;
    ///      protected[1] = tokenB;
    ///      protected[2] = tokenC;
    ///      return protected;
    ///    }
    /// ```
    function _protectedTokens() internal view virtual returns (address[] memory);

    /// @notice
    /// Removes tokens from this Strategy that are not the type of tokens
    /// managed by this Strategy. This may be used in case of accidentally
    /// sending the wrong kind of token to this Strategy.
    ///
    /// Tokens will be sent to `governance()`.
    ///
    /// This will fail if an attempt is made to sweep `want`, or any tokens
    /// that are protected by this Strategy.
    ///
    /// This may only be called by governance.
    /// @param _token The token to transfer out of this poolManager.
    /// @param to Address to send the tokens to.
    /// @dev
    /// Implement `_protectedTokens()` to specify any additional tokens that
    /// should be protected from sweeping in addition to `want`.
    function sweep(address _token, address to) external override onlyRole(GUARDIAN_ROLE) {
        address[] memory __protectedTokens = _protectedTokens();
        for (uint256 i = 0; i < __protectedTokens.length; i++)
            if (_token == __protectedTokens[i]) revert ProtectedToken();

        IERC20(_token).safeTransfer(to, IERC20(_token).balanceOf(address(this)));
    }

    /// @notice Changes allowance of a set of tokens to addresses
    /// @param tokens Addresses of the tokens for which approvals should be made
    /// @param spenders Addresses to approve
    /// @param amounts Approval amounts for each address
    function changeAllowance(
        IERC20[] calldata tokens,
        address[] calldata spenders,
        uint256[] calldata amounts
    ) external onlyRole(GUARDIAN_ROLE) {
        if (tokens.length != spenders.length || tokens.length != amounts.length) revert IncompatibleLengths();
        for (uint256 i = 0; i < tokens.length; i++) {
            _changeAllowance(tokens[i], spenders[i], amounts[i]);
        }
    }

    /// @notice Swap earned _stkAave or Aave for `want` through 1Inch
    /// @param minAmountOut Minimum amount of `want` to receive for the swap to happen
    /// @param payload Bytes needed for 1Inch API
    /// @dev In the case of a contract lending to Aave, tokens swapped should typically be: _stkAave -> `want` or Aave -> `want`
    function sellRewards(uint256 minAmountOut, bytes memory payload) external onlyRole(KEEPER_ROLE) {
        //solhint-disable-next-line
        (bool success, bytes memory result) = oneInch.call(payload);
        if (!success) _revertBytes(result);

        uint256 amountOut = abi.decode(result, (uint256));
        if (amountOut < minAmountOut) revert TooSmallAmount();
    }

    /// @notice Internal function used for error handling
    function _revertBytes(bytes memory errMsg) internal pure {
        if (errMsg.length > 0) {
            //solhint-disable-next-line
            assembly {
                revert(add(32, errMsg), mload(errMsg))
            }
        }
        revert ErrorSwap();
    }

    /// @notice Changes allowance of a set of tokens to addresses
    /// @param token Address of the token for which approval should be made
    /// @param spender Address to approve
    /// @param amount Approval amount
    function _changeAllowance(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = token.allowance(address(this), address(spender));
        if (currentAllowance < amount) {
            token.safeIncreaseAllowance(address(spender), amount - currentAllowance);
        } else if (currentAllowance > amount) {
            token.safeDecreaseAllowance(address(spender), currentAllowance - amount);
        }
    }
}
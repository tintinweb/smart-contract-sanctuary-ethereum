// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

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
    function transferFrom(
        address sender,
        address recipient,
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

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./extensions/Signature.sol";
import "./interfaces/IManager.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract StableFinancePool is
    Initializable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    Signature
{
    using SafeERC20 for IERC20;

    enum VestingOption {
        NoVesting,
        Lock,
        VestingReward,
        VestingAll
    }

    struct StableFinancePoolInfo { 
        IERC20 stableFinanceAcceptedToken;
        IERC20[] stableFinanceRewardToken;
        uint256 cap;
        uint256 totalStaked;
        uint256 startJoinTime;
        uint256 endJoinTime;
        uint256 minInvestment;
        uint256 maxInvestment;
        uint256[] APR;
        uint256 lockDuration;
        uint256 delayDuration;
        VestingOption option;
    }

    struct StableFinanceStakingData {
        uint256 balance;
        uint256 joinTime;
        uint256 updatedTime;
        uint256[] pendingReward;
        uint256[] claimedReward;
        uint256[] APR;
    }

    struct StableFinanceWhiteList {
        uint256 whiteListCount;
        mapping(address => bool) whitelist;
    }

    struct AdditionalPoolInfo {
        mapping(address => bool) isWhitelisted; // isWhitelisted(user_address) allow user for early redeem
        mapping(uint16 => uint16) penaltyRate; // 100% = 100
        mapping(uint16 => bool) isPenaltyEnabled; // isPenaltyEnabled(poolId)
        uint256 delayDuration; // default = 0
    }

    struct StableFinancePendingWithdrawal {
        uint256 amount;
        uint256 applicableAt;
    }

    struct LinerPendingEarlyWithdrawal {
        uint256[] reward;
        uint256 amount;
        uint256 earlyWithdrawTime;
    }

    event StableFinancePoolCreated(
        uint256 indexed poolId,
        IERC20 stableFinanceAcceptedToken,
        IERC20[] stableFinanceRewardToken,
        uint256 cap,
        uint256[] APR,
        uint256 startJoinTime,
        uint256 endJoinTime,
        uint256 minInvestment,
        uint256 maxInvestment,
        uint256 lockDuration,
        uint256 delayDuration,
        VestingOption option
    );

    event StableFinancePoolUpdated(
        uint256 indexed poolId,
        IERC20 stableFinanceAcceptedToken,
        IERC20[] stableFinanceRewardToken,
        uint256 cap,
        uint256[] APR,
        uint256 startJoinTime,
        uint256 endJoinTime,
        uint256 minInvestment,
        uint256 maxInvestment,
        uint256 lockDuration,
        uint256 delayDuration,
        VestingOption option
    );

    event StableFinanceDeposit(
        uint256 poolId,
        address account,
        uint256 amount,
        uint256 stakeTime
    );
    event StableFinanceWithdraw(
        uint256 poolId,
        address account,
        uint256 amount,
        uint256 unStakeTime
    );
    event StableFinanceRewardsHarvested(
        uint256 poolId,
        address account,
        uint256 reward,
        uint256 rewardsHarvestTime
    );
    event StableFinancePendingWithdraw(
        uint256 poolId,
        address account,
        uint256 amount,
        uint256 withdrawTime
    );
    event StableFinanceEarlyPendingWithdraw(
        uint256 indexed poolId,
        address indexed account,
        uint256 amount,
        uint256[] reward,
        uint256 withdrawTime
    );
    event StableFinanceEmergencyWithdraw(
        uint256 poolId,
        address account,
        uint256 amount
    );

    event StableFinanceSetEarlyWithdrawTier(
        uint256 poolId,
        uint16 percentageKey,
        uint16 percentageValue
    );
    event StableFinanceSetDelayDuration(uint256 poolId, uint256 duration);
    event AssignStakingData(uint256 poolId, address from, address to);
    
    event AddWhiteList(uint256 poolId, address[] addresses);
    event RemoveWhiteList(uint256 poolId, address[] addresses);

    event StableFinanceAddEarlyWhitelist(uint256 poolId, address account);
    event StableFinanceRemoveEarlyWhitelist(uint256 poolId, address account);
    event StableFinanceEarlyWithdraw(
        uint256 poolId,
        address account,
        uint256 amount,
        uint256 reward,
        uint256 fee
    );

    uint32 public constant ONE_YEAR_IN_SECONDS = 365 days;
    uint16 public constant HUNDRED_PERCENT = 100;

    address public manager;

    // The reward distribution address
    address public stableFinanceRewardDistributor;

    // Info of each pool
    StableFinancePoolInfo[] public stableFinancePoolInfo;
    // Info of each user that stakes in pools
    mapping(uint256 => mapping(address => StableFinanceStakingData))
        public stableFinanceStakingData;
    // Info of pending withdrawals.
    mapping(uint256 => mapping(address => StableFinancePendingWithdrawal))
        public stableFinancePendingWithdrawals;
    // White list user for each pool
    mapping(uint256 => StableFinanceWhiteList) public stableFinanceWhiteList;
    mapping(uint256 => AdditionalPoolInfo) public additionalPoolInfo;

    mapping(uint256 => mapping(address => uint256)) public nonce;
    mapping(uint256 => mapping(address => LinerPendingEarlyWithdrawal))
        public linerPendingEarlyWithdrawals;


    modifier onlyWhiteList(uint256 _poolId) {
        StableFinanceWhiteList storage whitelistData = stableFinanceWhiteList[
            _poolId
        ];
        require(
            whitelistData.whiteListCount == 0 ||
                whitelistData.whitelist[msg.sender],
            "StakingPool: forbidden"
        );
        _;
    }

    modifier notInBlackList(address _user) {
        require(
            !IManager(manager).isInBlackList(_user),
            "StakingPool: forbidden"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            IManager(manager).isAdmin(msg.sender),
            "StakingPool: forbidden"
        );
        _;
    }

    modifier onlySuperAdmin() {
        require(
            IManager(manager).isSuperAdmin(msg.sender),
            "StakingPool: forbidden"
        );
        _;
    }

    /**
     * @notice Validate pool by pool ID
     * @param _poolId id of the pool
     */
    modifier stableFinanceValidatePoolById(uint256 _poolId) {
        require(
            _poolId < stableFinancePoolInfo.length,
            "StakingPool: not exist"
        );
        _;
    }


    /**
     * @notice Return total tokens staked in a pool
     * @param _poolId id of the pool
     */
    function stableFinanceTotalStaked(uint256 _poolId)
        external
        view
        stableFinanceValidatePoolById(_poolId)
        returns (uint256)
    {
        return stableFinancePoolInfo[_poolId].totalStaked;
    }

    /**
     * @notice Gets number of reward tokens of a user from a pool
     * @param _poolId id of the pool
     * @param _account address of user call this function
     * @return _rewards earned reward of a user
     */
    function stableFinancePendingRewards(uint256 _poolId, address _account)
        public
        view
        stableFinanceValidatePoolById(_poolId)
        returns (uint256[] memory)
    {
        StableFinancePoolInfo storage pool = stableFinancePoolInfo[_poolId];
        StableFinanceStakingData storage user = stableFinanceStakingData[
            _poolId
        ][_account];

        uint256[] memory _rewards = new uint256[](
            pool.stableFinanceRewardToken.length
        );
        for (uint256 i; i < pool.stableFinanceRewardToken.length; i++) {
            _rewards[i] =
                _stableFinancePendingReward(_poolId, _account, pool.APR[i]) +
                user.pendingReward[i];
        }

        return _rewards;
    }

    /**
     * @notice Gets number of deposited tokens in a pool
     * @param _poolId id of the pool
     * @param _account address of a user
     * @return total token deposited in a pool by a user
     */
    function stableFinanceBalanceOf(uint256 _poolId, address _account)
        external
        view
        stableFinanceValidatePoolById(_poolId)
        returns (uint256)
    {
        return stableFinanceStakingData[_poolId][_account].balance;
    }

    /**
     * @notice Gets number of claimed tokens in a pool by an user
     * @param _poolId id of the pool
     * @param _account address of a user
     * @return total token claimed in a pool by a user
     */
    function stableFinanceClaimedRewardOf(uint256 _poolId, address _account)
        external
        view
        stableFinanceValidatePoolById(_poolId)
        returns (uint256[] memory)
    {
        return stableFinanceStakingData[_poolId][_account].claimedReward;
    }


    /**
     * @notice Gets peding withdraw token of an user in a pool
     * @param _poolId id of the pool
     * @param _account address of a user
     * @return total token deposited in a pool by a user
     */
    function stableFinanceUserPendingWithdrawalsData(
        uint256 _poolId,
        address _account
    )
        external
        view
        stableFinanceValidatePoolById(_poolId)
        returns (StableFinancePendingWithdrawal memory)
    {
        return stableFinancePendingWithdrawals[_poolId][_account];
    }

    function _stableFinancePendingReward(
        uint256 _poolId,
        address _account,
        uint256 _APR
    ) private view returns (uint256 totalReward) {
        StableFinancePoolInfo storage pool = stableFinancePoolInfo[_poolId];
        StableFinanceStakingData storage user = stableFinanceStakingData[
            _poolId
        ][_account];

        totalReward = 0;
        uint256 endTime = block.timestamp;

        uint256 startTime = user.updatedTime > 0
            ? user.updatedTime
            : block.timestamp;
        if (
            pool.lockDuration > 0 &&
            user.joinTime + pool.lockDuration < block.timestamp
        ) {
            endTime = user.joinTime + pool.lockDuration;
        }

        uint256 stakedTimeInSeconds = endTime > startTime
            ? endTime - startTime
            : 0;

        uint256 pendingReward = ((user.balance * stakedTimeInSeconds * _APR) /
            ONE_YEAR_IN_SECONDS) / 1e20;

        totalReward = pendingReward;

        return totalReward;
    }


    /**
     * @notice Initialize the contract, get called in the first time deploy
     */
    function __StableFinancePool_init(address _manager) public initializer {
        manager = _manager;
        __Pausable_init();
    }

    function setSigner(address _signer) external onlyAdmin {
        signer = _signer;
    }

    function linerSetListEarlyWithdrawTier(
        uint256 _poolId,
        uint16[] memory _percentageKeys,
        uint16[] memory _percentageValues,
        uint256 _duration
    ) external onlyAdmin stableFinanceValidatePoolById(_poolId) {
        uint256 length = _percentageKeys.length;
        require(length == _percentageValues.length);

        AdditionalPoolInfo storage pool = additionalPoolInfo[_poolId];

        for (uint256 i = 0; i < length; i++) {
            pool.penaltyRate[_percentageKeys[i]] = _percentageValues[i];
            additionalPoolInfo[_poolId].isPenaltyEnabled[
                _percentageKeys[i]
            ] = true;

            emit StableFinanceSetEarlyWithdrawTier(
                _poolId,
                _percentageKeys[i],
                _percentageValues[i]
            );
        }
        additionalPoolInfo[_poolId].delayDuration = _duration;
        emit StableFinanceSetDelayDuration(_poolId, _duration);
    }

    function stableFinanceAddEarlyWhitelist(uint256 _poolId, address[] memory _accounts)
        external
        onlyAdmin
        stableFinanceValidatePoolById(_poolId)
    {
        uint256 length = _accounts.length;
        AdditionalPoolInfo storage pool = additionalPoolInfo[_poolId];

        for(uint256 i = 0; i < length; i++) {
            if (!pool.isWhitelisted[_accounts[i]])
                pool.isWhitelisted[_accounts[i]] = true;
            emit StableFinanceAddEarlyWhitelist(_poolId, _accounts[i]);
        }

    }

    function stableFinanceRemoveEarlyWhitelist(
        uint256 _poolId,
        address[] memory _accounts
    ) external onlyAdmin stableFinanceValidatePoolById(_poolId) {
        uint256 length = _accounts.length;
        AdditionalPoolInfo storage pool = additionalPoolInfo[_poolId];

        for(uint256 i = 0; i < length; i++) {
            if (pool.isWhitelisted[_accounts[i]])
                pool.isWhitelisted[_accounts[i]] = false;
            emit StableFinanceRemoveEarlyWhitelist(_poolId, _accounts[i]);
        }
    }

    function linerEarlyWithdraw(uint256 _poolId, uint16 _percentage)
        external
        nonReentrant
        whenNotPaused
        onlyWhiteList(_poolId)
        notInBlackList(msg.sender)
        stableFinanceValidatePoolById(_poolId)
    {
        address account = msg.sender;
        StableFinancePoolInfo storage pool = stableFinancePoolInfo[_poolId];
        AdditionalPoolInfo storage poolInfo = additionalPoolInfo[_poolId];
        StableFinanceStakingData storage stakingData = stableFinanceStakingData[
            _poolId
        ][account];

        require(
            poolInfo.isPenaltyEnabled[_percentage] &&
                poolInfo.penaltyRate[_percentage] <= HUNDRED_PERCENT,
            "StakingPool: invalid percentage"
        );
        require(
            poolInfo.isWhitelisted[account],
            "StakingPool: not whitelisted"
        );

        LinerPendingEarlyWithdrawal
            storage pending = linerPendingEarlyWithdrawals[_poolId][account];

        uint256 amount = (_percentage * stakingData.balance) / HUNDRED_PERCENT;
        uint256 penaltyFee = (amount * poolInfo.penaltyRate[_percentage]) /
            HUNDRED_PERCENT;

        //  calculate new pending reward
        _stableFinanceHarvest(_poolId, account);

        uint256 reward;
        {
            uint256 percentage = _percentage;
            uint256[] memory totalReward = stakingData.pendingReward;
            if (pending.reward.length == 0) {
                pending.reward = new uint256[](totalReward.length);
            }
            if (totalReward.length > 0) {
                for (uint256 i; i < totalReward.length; i++) {
                    // claimable reward (cal by _percenteage)
                    // update user reward, send % to delay reward

                    reward = (percentage * totalReward[i]) / HUNDRED_PERCENT;
                    stakingData.pendingReward[i] = totalReward[i] - reward;
                    pending.reward[i] += reward;
                }
            }

            // penalty only for withdraw amount, not for reward
            pending.amount += (amount - penaltyFee);
            stakingData.balance -= amount;
            pending.earlyWithdrawTime = block.timestamp;

            pool.totalStaked -= amount;

            pool.stableFinanceAcceptedToken.safeTransfer(stableFinanceRewardDistributor, penaltyFee);
        }

        // emit event
        emit StableFinanceEarlyWithdraw(
            _poolId,
            account,
            amount,
            reward,
            penaltyFee
        );

        // remove user from whitelist
        delete poolInfo.isWhitelisted[account];
    }

    /**
     * @notice Add a new pool with different APR and conditions. Can only be called by the owner.
     * @param _payload struct of a pool
     */
    function stableFinanceAddPool(StableFinancePoolInfo memory _payload)
        external
        onlyAdmin
    {
        require(
            _payload.endJoinTime > _payload.startJoinTime,
            "StakingPool: invalid time"
        );

        require(
            _payload.minInvestment < _payload.maxInvestment,
            "StakingPool: invalid min max"
        );

        require(
            _payload.stableFinanceRewardToken.length == _payload.APR.length,
            "StakingPool: must match APR"
        );

        if (_payload.option == VestingOption.NoVesting) {
            require(
                _payload.lockDuration == 0,
                "StakingPool: invalid delay duration"
            );
        } else {
            require(
                _payload.lockDuration > 0,
                "StakingPool: invalid delay duration"
            );
        }

        stableFinancePoolInfo.push(
            StableFinancePoolInfo({
                stableFinanceAcceptedToken: _payload.stableFinanceAcceptedToken,
                stableFinanceRewardToken: _payload.stableFinanceRewardToken,
                cap: _payload.cap,
                totalStaked: 0,
                startJoinTime: _payload.startJoinTime,
                endJoinTime: _payload.endJoinTime,
                minInvestment: _payload.minInvestment,
                maxInvestment: _payload.maxInvestment,
                APR: _payload.APR,
                lockDuration: _payload.lockDuration,
                delayDuration: _payload.delayDuration,
                option: _payload.option
            })
        );
        emit StableFinancePoolCreated(
            stableFinancePoolInfo.length - 1,
            _payload.stableFinanceAcceptedToken,
            _payload.stableFinanceRewardToken,
            _payload.cap,
            _payload.APR,
            _payload.startJoinTime,
            _payload.endJoinTime,
            _payload.minInvestment,
            _payload.maxInvestment,
            _payload.lockDuration,
            _payload.delayDuration,
            _payload.option
        );
    }

    /**
     * @notice update a pool with different APR and conditions. Can only be called by the admin role.
     */
    function stableFinanceUpdatePool(
        uint256 _poolId,
        IERC20 stableFinanceAcceptedToken,
        IERC20[] memory stableFinanceRewardToken,
        uint256 cap,
        uint256[] memory APR,
        uint256 startJoinTime,
        uint256 endJoinTime,
        uint256 minInvestment,
        uint256 maxInvestment,
        uint256 lockDuration,
        uint256 delayDuration,
        VestingOption option
    ) external onlyAdmin {
        StableFinancePoolInfo storage pool = stableFinancePoolInfo[_poolId];

        require(
            pool.startJoinTime > block.timestamp
        );

        pool.APR = APR;
        pool.cap = cap;
        pool.delayDuration = delayDuration;
        pool.maxInvestment = maxInvestment;
        pool.lockDuration = lockDuration;
        pool.minInvestment = minInvestment;
        pool.stableFinanceAcceptedToken = stableFinanceAcceptedToken;
        pool.stableFinanceRewardToken = stableFinanceRewardToken;
        pool.startJoinTime = startJoinTime;
        pool.endJoinTime = endJoinTime;
        pool.option = option;

        emit StableFinancePoolUpdated(
            _poolId,
            stableFinanceAcceptedToken,
            stableFinanceRewardToken,
            cap,
            APR,
            startJoinTime,
            endJoinTime,
            minInvestment,
            maxInvestment,
            lockDuration,
            delayDuration,
            option
        );
    }

    /**
     * @notice update a pool with different APR and conditions. Can only be called by the admin role.
     * @param _poolId id of pool want to update
     * @param endJoinTime the time when users can't start to join the pool
     */
    function stableFinanceUpdatePoolAfterStarted(
        uint256 _poolId,
        uint256 endJoinTime
    ) external onlyAdmin {
        StableFinancePoolInfo storage pool = stableFinancePoolInfo[_poolId];

        pool.endJoinTime = endJoinTime;

        emit StableFinancePoolUpdated(
            _poolId,
            pool.stableFinanceAcceptedToken,
            pool.stableFinanceRewardToken,
            pool.cap,
            pool.APR,
            pool.startJoinTime,
            pool.endJoinTime,
            pool.minInvestment,
            pool.maxInvestment,
            pool.lockDuration,
            pool.delayDuration,
            pool.option
        );
    }

    function pause() external onlySuperAdmin {
        _pause();
    }

    function unpause() external onlySuperAdmin {
        _unpause();
    }

    /**
     * @notice Set the reward distributor. Can only be called by the owner.
     * @param _stableFinanceRewardDistributor the reward distributor
     */
    function stableFinanceSetRewardDistributor(
        address _stableFinanceRewardDistributor
    ) external onlyAdmin {
        require(
            _stableFinanceRewardDistributor != address(0)
        );
        stableFinanceRewardDistributor = _stableFinanceRewardDistributor;
    }

    /**
     * @notice Add white list user. Can only be called by the owner.
     * @param _poolId pool will add whitelist
     * @param _whitelist whitelist
     */
    function stableFinanceAddWhiteList(
        uint256 _poolId,
        address[] memory _whitelist
    ) external onlyAdmin {
        require(
            _whitelist.length > 0
        );

        StableFinanceWhiteList storage whitelistData = stableFinanceWhiteList[
            _poolId
        ];
        for (uint256 i; i < _whitelist.length; i++) {
            if (!whitelistData.whitelist[_whitelist[i]]) {
                whitelistData.whiteListCount++;
                whitelistData.whitelist[_whitelist[i]] = true;
            }
        }

        emit AddWhiteList(_poolId, _whitelist);
    }

    /**
     * @notice Remove white list user. Can only be called by the owner.
     * @param _poolId pool will remove whitelist
     * @param _whitelist whitelist
     */
    function stableFinanceRemoveWhiteList(
        uint256 _poolId,
        address[] memory _whitelist
    ) external onlyAdmin {
        require(
            _whitelist.length > 0
        );

        StableFinanceWhiteList storage whitelistData = stableFinanceWhiteList[
            _poolId
        ];
        for (uint256 i; i < _whitelist.length; i++) {
            if (whitelistData.whitelist[_whitelist[i]]) {
                whitelistData.whiteListCount--;
                whitelistData.whitelist[_whitelist[i]] = false;
            }
        }

        emit RemoveWhiteList(_poolId, _whitelist);
    }

    /**
     * @notice Claim pending withdrawal
     * @param _poolId id of the pool
     */
    function stableFinanceClaimPendingEarlyWithdraw(uint256 _poolId)
        external
        whenNotPaused
        nonReentrant
        stableFinanceValidatePoolById(_poolId)
        onlyWhiteList(_poolId)
        notInBlackList(msg.sender)
    {
        StableFinancePoolInfo storage pool = stableFinancePoolInfo[_poolId];
        AdditionalPoolInfo storage addPoolInfo = additionalPoolInfo[_poolId];
        address account = msg.sender;
        LinerPendingEarlyWithdrawal
            storage pending = linerPendingEarlyWithdrawals[_poolId][account];
        uint256 amount = pending.amount;
        uint256[] memory reward = pending.reward;

        require(amount > 0, "StakingPool: nothing");
        require(
            pending.earlyWithdrawTime + addPoolInfo.delayDuration <= block.timestamp,
            "StakingPool: not released yet"
        );
        delete linerPendingEarlyWithdrawals[_poolId][account];
        pool.stableFinanceAcceptedToken.safeTransfer(account, amount);
        for (uint256 i; i < reward.length; i++) {
            pool.stableFinanceRewardToken[i].safeTransfer(account, reward[i]);
        }

        emit StableFinanceEarlyPendingWithdraw(
            _poolId,
            account,
            amount,
            reward,
            block.timestamp
        );
    }

    /**
     * @notice Deposit token to earn rewards
     * @param _poolId id of the pool
     * @param _amount amount of token to deposit
     */
    function stableFinanceDeposit(uint256 _poolId, uint256 _amount)
        external
        whenNotPaused
        nonReentrant
        stableFinanceValidatePoolById(_poolId)
        onlyWhiteList(_poolId)
        notInBlackList(msg.sender)
    {
        address account = msg.sender;
        StableFinancePoolInfo storage pool = stableFinancePoolInfo[_poolId];

        _stableFinanceDeposit(_poolId, _amount, account);

        // transfer the amount to the pool
        pool.stableFinanceAcceptedToken.safeTransferFrom(
            account,
            address(this),
            _amount
        );

        nonce[_poolId][account]++;

        // emit event
        emit StableFinanceDeposit(_poolId, account, _amount, block.timestamp);
    }

    /**
     * @notice Withdraw token from a pool
     * @param _poolId id of the pool
     * @param _amount amount to withdraw
     */
    function stableFinanceWithdraw(
        uint256 _poolId,
        uint256 _amount,
        bytes memory _signature
    )
        external
        whenNotPaused
        nonReentrant
        stableFinanceValidatePoolById(_poolId)
        notInBlackList(msg.sender)
    {
        address account = msg.sender;
        StableFinanceStakingData storage stakingData = stableFinanceStakingData[
            _poolId
        ][account];
        StableFinancePoolInfo storage pool = stableFinancePoolInfo[_poolId];

        require(
            block.timestamp >= stakingData.joinTime + pool.lockDuration,
            "StakingPool: still locked"
        );

        require(
            _amount <= stakingData.balance,
            "StakingPool: Insufficient amount"
        );

        _stableFinanceHarvest(_poolId, account);

        if (
            pool.delayDuration == 0 && pool.option != VestingOption.VestingAll
        ) {
            pool.stableFinanceAcceptedToken.safeTransfer(account, _amount);

            emit StableFinanceWithdraw(
                _poolId,
                msg.sender,
                _amount,
                block.timestamp
            );

            stakingData.balance -= _amount;
            pool.totalStaked -= _amount;
        } else if (
            pool.delayDuration > 0 &&
            (pool.option == VestingOption.VestingReward ||
                pool.option == VestingOption.Lock)
        ) {
            StableFinancePendingWithdrawal
                storage pending = stableFinancePendingWithdrawals[_poolId][
                    account
                ];

            pending.amount += _amount;
            pending.applicableAt = block.timestamp + pool.delayDuration;

            stakingData.balance -= _amount;
            pool.totalStaked -= _amount;

            // emit withdraw event
            emit StableFinanceWithdraw(
                _poolId,
                msg.sender,
                _amount,
                block.timestamp
            );
        } else if (pool.option == VestingOption.VestingAll) {
            uint256 _nonce = nonce[_poolId][account];
            bytes32 msgHash = getMessageHash(_poolId, _amount, account, _nonce);

            require(
                _verifySignature(msgHash, _signature),
                "StakingPool: invalid signature"
            );

            pool.stableFinanceAcceptedToken.safeTransfer(account, _amount);

            emit StableFinanceWithdraw(
                _poolId,
                msg.sender,
                _amount,
                block.timestamp
            );

            stakingData.balance -= _amount;
            pool.totalStaked -= _amount;
        }

        nonce[_poolId][account]++;
    }

    function linearAssignStakedData(
        uint256 _poolId,
        address _from,
        address _to
    ) external onlyAdmin stableFinanceValidatePoolById(_poolId) {
        require(_from != address(0), "StakingPool: invalid address");
        require(_to != address(0), "StakingPool: invalid address");
        require(_from != _to, "StakingPool: invalid address");
        StableFinanceStakingData storage stakingData = stableFinanceStakingData[_poolId][_to];
        StableFinancePendingWithdrawal
            storage pendingWithdrawData = stableFinancePendingWithdrawals[
                _poolId
            ][_to];
        require(
            stakingData.balance == 0 &&
                stakingData.pendingReward.length == 0 &&
                stakingData.joinTime == 0 &&
                stakingData.updatedTime == 0 &&
                // pendingWithdrawData.reward.length == 0 &&
                pendingWithdrawData.applicableAt == 0 &&
                pendingWithdrawData.amount == 0,
            "StakingPool: user already staked"
        );

        // LinearStakingData
        stableFinanceStakingData[_poolId][_to] = stableFinanceStakingData[_poolId][_from];
        delete stableFinanceStakingData[_poolId][_from];

        // LinearPendingEarlyWithdrawal
        stableFinancePendingWithdrawals[_poolId][
            _to
        ] = stableFinancePendingWithdrawals[_poolId][_from];
        delete stableFinancePendingWithdrawals[_poolId][_from];

        linerPendingEarlyWithdrawals[_poolId][
            _to
        ] = linerPendingEarlyWithdrawals[_poolId][_from];

        delete linerPendingEarlyWithdrawals[_poolId][_from];

        // whitelist
        if (additionalPoolInfo[_poolId].isWhitelisted[_from]) {
            additionalPoolInfo[_poolId].isWhitelisted[_to] = true;
            delete additionalPoolInfo[_poolId].isWhitelisted[_from];
        }

        emit AssignStakingData(_poolId, _from, _to);
    }

    /**
     * @notice Claim pending withdrawal
     * @param _poolId id of the pool
     */
    function stableFinanceClaimPendingWithdraw(uint256 _poolId)
        external
        whenNotPaused
        nonReentrant
        stableFinanceValidatePoolById(_poolId)
        notInBlackList(msg.sender)
    {
        address account = msg.sender;
        StableFinancePoolInfo storage pool = stableFinancePoolInfo[_poolId];

        StableFinancePendingWithdrawal
            storage pending = stableFinancePendingWithdrawals[_poolId][account];

        uint256 amount = pending.amount;

        require(
            amount > 0,
            "StableFinanceStakingPool: nothing pending"
        );

        require(
            pending.applicableAt <= block.timestamp,
            "StableFinanceStakingPool: not released yet"
        );

        // transfer the amount to the user
        delete stableFinancePendingWithdrawals[_poolId][account];
        pool.stableFinanceAcceptedToken.safeTransfer(account, amount);

        emit StableFinancePendingWithdraw(
            _poolId,
            account,
            amount,
            block.timestamp
        );
    }

    function _claimReward(uint256 _poolId, uint256[] memory _amount)
        private
    {
        address account = msg.sender;

        StableFinancePoolInfo storage pool = stableFinancePoolInfo[_poolId];

        StableFinanceStakingData storage stakingData = stableFinanceStakingData[
            _poolId
        ][account];

        _stableFinanceHarvest(_poolId, account);

        require(
            stableFinanceRewardDistributor != address(0)
        );

        require(
            stakingData.pendingReward.length == _amount.length
        );

        for (uint256 i; i < stakingData.pendingReward.length; i++) {

            if(_amount[0] == 0) {               
                _amount[i] = stakingData.pendingReward[i];
            }

            require(
                stakingData.pendingReward[i] >= _amount[i],
                "StakingPool: Insufficient reward amount"
            );
            // transfer the reward to the user

            stakingData.pendingReward[i] -= _amount[i];
            stakingData.claimedReward[i] += _amount[i];
            pool.stableFinanceRewardToken[i].safeTransferFrom(
                stableFinanceRewardDistributor,
                account,
                _amount[i]
            );

            // emit ClaimedReward event
            emit StableFinanceRewardsHarvested(
                _poolId,
                account,
                _amount[i],
                block.timestamp
            );
        }
    }


    /**
     * @notice Claim reward token from a pool
     * @param _poolId id of the pool
     */
    function stableFinanceClaimReward(
        uint256 _poolId,
        uint256[] memory _amount,
        bytes memory _signature
    )
        external
        whenNotPaused
        nonReentrant
        stableFinanceValidatePoolById(_poolId)
        notInBlackList(msg.sender)
    {
        address account = msg.sender;
        StableFinancePoolInfo storage pool = stableFinancePoolInfo[_poolId];
        StableFinanceStakingData
                storage stakingData = stableFinanceStakingData[_poolId][
                    account
                ];
        uint256[] memory emptyArray = new uint256[](stakingData.pendingReward.length);

        if (pool.option == VestingOption.NoVesting) {
            _claimReward(_poolId, emptyArray);
        } else if (pool.option == VestingOption.Lock) {

            require(
                block.timestamp >= stakingData.joinTime + pool.lockDuration,
                "StakingPool: still locked"
            );

            _claimReward(_poolId, emptyArray);

            return;
        } else if (
            pool.option == VestingOption.VestingReward ||
            pool.option == VestingOption.VestingAll
        ) {
            uint256 _nonce = nonce[_poolId][msg.sender];
            bytes32 msgHash = getClaimRewardMessageHash(
                _poolId,
                _amount,
                msg.sender,
                _nonce
            );
            require(
                _verifySignature(msgHash, _signature),
                "StakingPool: invalid signature"
            );
            _claimReward(_poolId, _amount);
        }

        nonce[_poolId][msg.sender]++;
    }

    function _stableFinanceDeposit(
        uint256 _poolId,
        uint256 _amount,
        address account
    ) internal {
        StableFinancePoolInfo storage pool = stableFinancePoolInfo[_poolId];
        StableFinanceStakingData storage stakingData = stableFinanceStakingData[
            _poolId
        ][account];

        require(
            block.timestamp >= pool.startJoinTime,
            "Staking: not started yet"
        );

        require(
            block.timestamp <= pool.endJoinTime,
            "Staking: already closed"
        );

        require(
            stakingData.balance + _amount >= pool.minInvestment,
            "Staking: insufficient amount"
        );

        if (pool.maxInvestment > 0) {
            require(
                stakingData.balance + _amount <= pool.maxInvestment,
                "StakingPool: too large amount"
            );
        }

        if (pool.cap > 0) {
            require(
                pool.totalStaked + _amount <= pool.cap,
                "StakingPool: pool is full"
            );
        }

        _stableFinanceHarvest(_poolId, account);

        stakingData.balance += _amount;
        stakingData.joinTime = block.timestamp;

        pool.totalStaked += _amount;
    }

    function _stableFinanceHarvest(uint256 _poolId, address _account) private {
        StableFinancePoolInfo storage pool = stableFinancePoolInfo[_poolId];
        StableFinanceStakingData storage stakingData = stableFinanceStakingData[
            _poolId
        ][_account];

        if (stakingData.updatedTime == 0) {
            uint256[] memory _rewards = new uint256[](
                pool.stableFinanceRewardToken.length
            );
            stakingData.pendingReward = _rewards;
            stakingData.claimedReward = _rewards;
        }

        stakingData.pendingReward = stableFinancePendingRewards(
            _poolId,
            _account
        );
        stakingData.updatedTime = block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// Signature Verification
/// @title Implement off-chain whitelist and on-chain verification
/// @author HaiPham <[email protected]>

contract Signature {
    // Using Openzeppelin ECDSA cryptography library
    address public signer;

    function getMessageHash(
        uint256 _poolId,
        uint256 _amount,
        address _user,
        uint256 _nonce
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _poolId,
                    _amount,
                    _user,
                    _nonce
                )
            );
    }

    function getClaimRewardMessageHash(
        uint256 _poolId,
        uint256[] memory _amount,
        address _user,
        uint256 _nonce
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _poolId,
                    _amount,
                    _user,
                    _nonce
                )
            );
    }

    // Verify signature function
    function _verifySignature(
        bytes32 _msgHash,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(_msgHash);

        return getSignerAddress(ethSignedMessageHash, signature) == signer;
    }


    function getSignerAddress(bytes32 _messageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        return ECDSA.recover(_messageHash, _signature);
    }

    // Split signature to r, s, v
    function splitSignature(bytes memory _signature)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(_signature.length == 65, "invalid signature length");

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return ECDSA.toEthSignedMessageHash(_messageHash);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IManager {
    function isAdmin(address _user) external view returns (bool);
    function isSuperAdmin(address _user) external view returns (bool);
    function isInBlackList(address _user) external view returns( bool);
}
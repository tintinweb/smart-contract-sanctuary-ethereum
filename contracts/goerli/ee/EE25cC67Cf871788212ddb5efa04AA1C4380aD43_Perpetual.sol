// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

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
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
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
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title configuration constants
contract Config {
    /// @dev Bit mask to apply for verifier public input before verifying.
    uint256 constant INPUT_MASK = (~uint256(0) >> 3);
}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: Apache-2.0.


import "../Storage.sol";

abstract contract Custom is Storage {

    function set_accountRoot(bytes32 root) onlyGovernor external {
        accountRoot = root;
    }

    function set_userAdmin(address newAdmin) onlyGovernor external {
        userAdmin = newAdmin;
    }

    function set_orderStateHash(bytes32 root) onlyGovernor external {
        orderStateHash = root;
    }

    function set_globalConfigHash(bytes32 root) onlyGovernor external {
        globalConfigHash = root;
    }

    function set_newGlobalConfigHash(bytes32 root) onlyGovernor external {
        newGlobalConfigHash = root;
    }

    function set_pendingDeposit(uint256 l2Key, uint256 amount) onlyGovernor external {
        pendingDeposits[l2Key] = amount;
    }

    function set_systemTokenDecimal(uint8 amount) onlyGovernor external {
        systemTokenDecimal = amount;
    }

    function set_newGlobalConfigValidBlockNum(uint256 amount) onlyGovernor external {
        newGlobalConfigValidBlockNum = amount;
    }

    // function simulate_sender_updateBlock() onlyGovernor external {
    //         if (is_pending_global_config()) {
    //             resetGlobalConfigValidBlockNum();
    //             globalConfigHash = newGlobalConfigHash;
    //             emit LogNewGlobalConfigHash(newGlobalConfigHash);
    //         }
    // }

    function set_MAX_ASSETS_COUNT(uint16 amount) onlyGovernor external {
        MAX_ASSETS_COUNT = amount;
    }

}

pragma solidity >=0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0


import "./Storage.sol";

abstract contract Dac is Storage {
    function regDac(address member) external onlyGovernor {
        // TimeLock : User not trust the feeder, will be able to withdraw
        require(!DacRegisterActive, "a"); // "dac in register"
        require(!dacs[member], "ab"); // "dac already exist"
        DacRegisterActive = true;
        DacRegisterTime = block.timestamp;
        pendingDacMember = member;
    }

    function updateDac() external onlyGovernor {
        require(DacRegisterActive, "ac"); // "dac not register"
        require(block.timestamp > DacRegisterTime + TIMELOCK_DAC_REG, "ad"); // "dac register still in timelock"
        DacRegisterActive = false;

        addDac(pendingDacMember);
    }

    function cancelDacReg() external onlyGovernor {
        DacRegisterActive = false;
    }

    function addDac(address member) internal {
        require(member != address(0), "ae");
        dacs[member] = true;
        dacNum += 1;
    }

    // TODO: will valid in production
    //    function deleteDac(address member) external onlyGovernor {
    //        // Time-Lock ?
    //        require(dacs[member] != false, "af"); // "dac member not exist"
    //        require(dacNum > MIN_DAC_MEMBER, "ag");  // "dac memeber underflow"
    //        delete dacs[member];
    //        dacNum -= 1;
    //    }
}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: Apache-2.0.


import "./Storage.sol";

abstract contract Deposits is Storage {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    event LogDeposit(
        address ethAddr,
        uint160 l2Key,
        uint24 accountId,
        uint64 amount
    );

    event LogDepositCancel(uint160 l2Key, uint24 accountId);

    event LogDepositCancelReclaimed(
        uint160 l2Key,
        uint24 accountId,
        uint256 amount
    );

    function depositERC20(
        IERC20Upgradeable token,
        uint160 l2Key,
        uint24 accountId,
        uint64 amount
    ) internal {
        uint256 packedKey = (uint256(l2Key) << 24) | uint256(accountId);
        pendingDeposits[packedKey] += amount;

        // Disable the cancellationRequest timeout when users deposit into their own account.
        if (cancellationRequests[packedKey] != 0 && ethKeys[l2Key] == msg.sender)
        {
            delete cancellationRequests[packedKey];
        }

        token.safeTransferFrom(msg.sender, address(this), amount);
        emit LogDeposit(msg.sender, l2Key, accountId, amount);
    }

    function deposit(
        uint160 l2Key,
        uint24 accountId,
        uint64 amount
    ) public nonReentrant {
        require(ethKeys[l2Key] != address(0), "b");

        depositERC20(collateralToken, l2Key, accountId, amount);
    }

    function depositCancel(
        uint160 l2Key,
        uint24 accountId
    ) external onlyKeyOwner(l2Key) {
        uint256 packedKey = (uint256(l2Key) << 24) | uint256(accountId);
        cancellationRequests[packedKey] = block.timestamp;
        emit LogDepositCancel(l2Key, accountId);
    }

    function depositReclaim(
        uint160 l2Key,
        uint24 accountId
    ) external onlyKeyOwner(l2Key) nonReentrant {
        uint256 packedKey = (uint256(l2Key) << 24) | uint256(accountId);
        uint256 requestTime = cancellationRequests[packedKey];
        require(requestTime != 0, "bb");  // DEPOSIT_NOT_CANCELED
        uint256 freeTime = requestTime + DEPOSIT_CANCEL_TIMELOCK;
        require(block.timestamp >= freeTime, "bc"); // "DEPOSIT_LOCKED"

        // Clear deposit.
        uint256 amount = pendingDeposits[packedKey];
        delete pendingDeposits[packedKey];
        delete cancellationRequests[packedKey];

        collateralToken.safeTransfer(ethKeys[l2Key], amount); 
        emit LogDepositCancelReclaimed(l2Key, accountId, amount);
    }
}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: Apache-2.0.


import "./Storage.sol";

abstract contract ForcedTrade is Storage {
    event LogForcedTradeRequest(
		uint160 l2KeyA,
		uint160 l2KeyB,
		uint24 accountIdA,
		uint24 accountIdB,
		uint16 syntheticAssetId,
		uint64 amountCollateral,
        uint64 amountSynthetic,
        uint32 nonce
	);

	function getForceTradeHash(
		uint160 l2KeyA,
		uint160 l2KeyB,
		uint24 accountIdA,
		uint24 accountIdB,
		uint16 syntheticAssetId,
		uint64 amountCollateral,
        uint64 amountSynthetic,
        uint32 nonce
	) internal view returns (uint160 h) {
		uint256 m0 = (uint256(l2KeyA) << 93) | (uint256(l2KeyB) >> 67);
		uint256 m1 = ((uint256(l2KeyB) & 0x7ffffffffffffffff) << 186) | (uint256(accountIdA) << 162);
		m1 |= (uint256(accountIdB) << 138) | (uint256(syntheticAssetId) << 122);
		m1 |= (uint256(amountCollateral) << 58) |  (uint256(amountSynthetic) >> 6);
		uint256 m2 = ((uint256(amountSynthetic) & 0x3f) << 56) | (uint256(nonce) << 24);

		uint256 hashResult= hasher.rescue(m0, m1, m2);
		h = uint160(hashResult);
	}

    function forcedTradeRequest(
		uint160 l2KeyA,
		uint160 l2KeyB,
		uint24 accountIdA,
		uint24 accountIdB,
		uint16 syntheticAssetId,
		uint64 amountCollateral,
        uint64 amountSynthetic,
        uint32 nonce,	
		uint256 submissionExpirationTime,			
        bytes calldata signature	// B's signature
    ) external onlyActive onlyKeyOwner(l2KeyA) {
		require(syntheticAssetId > 0 && syntheticAssetId <= MAX_ASSETS_COUNT, "c");
		require(amountCollateral < (1 << 63), "cb");
		require(amountSynthetic < (1 << 63), "cc");
		require(submissionExpirationTime >= block.timestamp, "cd");
		require(accountIdA != accountIdB, "ca");

		uint160 req = getForceTradeHash(
			l2KeyA,
			l2KeyB,
			accountIdA,
			accountIdB,
			syntheticAssetId,
			amountCollateral,
			amountSynthetic,
        	nonce
		);
		// Verify B's signature
		verifySignature(req, submissionExpirationTime, l2KeyB, signature);

		addForcedRequest(req);

        // Log request.
        emit LogForcedTradeRequest(
			l2KeyA,
			l2KeyB,
			accountIdA,
			accountIdB,
			syntheticAssetId,
			amountCollateral,
        	amountSynthetic,
        	nonce
		);
    }

	function verifySignature(
		uint160 actionHash,
        uint256 submissionExpirationTime,
		uint160 l2Key,
        bytes memory signature
    ) internal view {
		bytes memory m = abi.encodePacked(uint256(actionHash), submissionExpirationTime);
        bytes memory message = bytes.concat(
                "\x19Ethereum Signed Message:\n130",
                "0x",
                Bytes.bytesToHexASCIIBytes(m)
        );
        address signer = ECDSA.recover(keccak256(message), signature);
        address l2KeyAddr = ethKeys[l2Key];
        require(l2KeyAddr != address(0), "ce");
        require(signer == l2KeyAddr, "cf");
    }
}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: Apache-2.0.


import "./Storage.sol";

abstract contract ForcedWithdrawals is Storage {
    event LogForcedWithdrawalRequest(uint160 l2Key, uint24 accountId, uint64 amount);

	function getForceWithdrawalHash(
     	uint160 l2Key,
		uint24 accountId,
        uint64 quantizedAmount
	) internal view returns (uint160 h) {
		// l2key(160)|| accountId(24) || quantizedAmount(64) || 0(5)
		uint256 m = (uint256(l2Key) << 93) | (uint256(accountId) << 69) | (uint256(quantizedAmount) << 5);

		uint256 hashResult= hasher.rescue(m, 0, 0);
		h = uint160(hashResult);
	}

    function forcedWithdrawalRequest(
        uint160 l2Key,
		uint24 accountId,
        uint64 quantizedAmount 
    ) external onlyActive onlyKeyOwner(l2Key) {
		require(quantizedAmount < (1 << 63), "d");

		uint160 req = getForceWithdrawalHash(
			l2Key,
			accountId,
			quantizedAmount
		);

		addForcedRequest(req);
        emit LogForcedWithdrawalRequest(l2Key, accountId, quantizedAmount);
    }
}

pragma solidity >= 0.8.12;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./Storage.sol";

abstract contract GlobalConfig is Storage {
    uint256 constant GLOBAL_CONFIG_KEY = ~uint256(0);
    event LogGlobalConfigChangeReg(bytes32 configHash);
    event LogGlobalConfigChangeApplied(bytes32 configHash, uint256 valid_layer2_block_num);
    event LogGlobalConfigChangeRemoved(bytes32 configHash);

    function encodeSyntheticAssets (
        SyntheticAssetInfo[] calldata synthetic_assets,
        uint16 _max_oracle_num
    ) internal pure returns (bytes memory config) {
        for (uint32 i=0; i< synthetic_assets.length; ++i) {
            uint256 real_oracle_num = synthetic_assets[i].oracle_price_signers_pubkey_hash.length / 20; // TODO
            bytes memory padZero = new bytes((_max_oracle_num - real_oracle_num) * 20);
            config = bytes.concat(config, 
                    abi.encodePacked(
                        synthetic_assets[i].resolution,
                        synthetic_assets[i].risk_factor,
                        synthetic_assets[i].asset_name,
                        synthetic_assets[i].oracle_price_signers_pubkey_hash
                    ), padZero);
        }
    }

    function initGlobalConfig(
        SyntheticAssetInfo[] calldata synthetic_assets,
        uint32 funding_validity_period,
        uint32 price_validity_period,
        uint64 max_funding_rate,
        uint16 _max_asset_count,
        uint16 _max_oracle_num
    ) internal pure returns (bytes32) {
        bytes memory padAsset = new bytes((_max_asset_count - synthetic_assets.length) * (24 + _max_oracle_num * 20));

        bytes memory globalConfig =bytes.concat(
            abi.encodePacked(
                uint16(synthetic_assets.length),
                funding_validity_period,
                price_validity_period,
                max_funding_rate
            ),
            encodeSyntheticAssets(synthetic_assets, _max_oracle_num),
            padAsset
        );

        return sha256(globalConfig);
        // event
    }

    function encodeOracleSigners (
        bytes20[] memory signers
    ) internal pure returns (bytes memory config) {
        for (uint32 i=0; i< signers.length; ++i) {
            config = bytes.concat(config, signers[i]);
        }
    }

    function addSyntheticAssets (
        SyntheticAssetInfo[] calldata synthetic_assets,
        bytes calldata oldGlobalConfig,
        uint256 valid_layer2_block_num
    ) external onlyGovernor {
        require(globalConfigHash == sha256(oldGlobalConfig), "e");  // "invalid oldGlobalConfig"
        require(!is_pending_global_config(), "eb"); // "PENDING_GLOBAL_CONFIG_CHANGE_EXIST"
        uint16 old_n_synthetic_assets_info = Bytes.bytesToUInt16(oldGlobalConfig[0:2], 0);
        require(old_n_synthetic_assets_info + synthetic_assets.length <= MAX_ASSETS_COUNT, "ec");   // "asset max limit"

        uint256 old_pad_zero_num = (MAX_ASSETS_COUNT - old_n_synthetic_assets_info) * (24 + MAX_NUMBER_ORACLES * 20);
        bytes memory newPadding = new bytes((MAX_ASSETS_COUNT - old_n_synthetic_assets_info - synthetic_assets.length) * (24 + MAX_NUMBER_ORACLES * 20));
        bytes memory newGlobalConfig = bytes.concat(
            bytes2(old_n_synthetic_assets_info + uint16(synthetic_assets.length)),
            oldGlobalConfig[2:oldGlobalConfig.length-old_pad_zero_num],
            encodeSyntheticAssets(synthetic_assets, MAX_NUMBER_ORACLES),
            newPadding
        );
        newGlobalConfigHash = sha256(newGlobalConfig);

        newGlobalConfigValidBlockNum = valid_layer2_block_num;
        emit LogGlobalConfigChangeApplied(newGlobalConfigHash, valid_layer2_block_num);
    }

    function regGlobalConfigChange(bytes32 configHash) external onlyGovernor
    {
        bytes32 actionKey = keccak256(bytes.concat(bytes32(GLOBAL_CONFIG_KEY), configHash));
        actionsTimeLock[actionKey] = block.timestamp + TIMELOCK_GLOBAL_CONFIG_CHANGE;
        emit LogGlobalConfigChangeReg(configHash);
    }

    function applyGlobalConfigChange(
        bytes32 configHash,
        uint256 valid_layer2_block_num)
        external onlyGovernor
    {
        bytes32 actionKey = keccak256(abi.encode(GLOBAL_CONFIG_KEY, configHash));
        uint256 activationTime = actionsTimeLock[actionKey];
        require(!is_pending_global_config(), "ed"); // "PENDING_GLOBAL_CONFIG_CHANGE_EXIST"
        require(activationTime > 0, "ef"); // "CONFIGURATION_NOT_REGSITERED"
        require(activationTime <= block.timestamp, "eg"); // "CONFIGURATION_NOT_ENABLE_YET"
        newGlobalConfigHash = configHash;
        newGlobalConfigValidBlockNum = valid_layer2_block_num;
        emit LogGlobalConfigChangeApplied(configHash, valid_layer2_block_num);
    }

    function removeGlobalConfigChange(bytes32 configHash)
        external onlyGovernor
    {
        bytes32 actionKey = keccak256(bytes.concat(bytes32(GLOBAL_CONFIG_KEY), configHash));
        require(actionsTimeLock[actionKey] > 0, "eh"); // "CONFIGURATION_NOT_REGSITERED"
        delete actionsTimeLock[actionKey];
        emit LogGlobalConfigChangeRemoved(configHash);
    }

}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title Governance Contract
abstract contract Governance {
    /// @notice Governor changed
    event NewGovernor(address newGovernor);
    event ValidatorStatusUpdate(address validatorAddress, bool isActive);

    address public networkGovernor;
    mapping(address => bool) public validators;

    function initGovernor(address governor, address validator) internal {
        networkGovernor = governor;
        validators[validator] = true;
    }

    modifier onlyGovernor() {
        require(msg.sender == networkGovernor, "f");
        _;
    }

    /// @notice Change current governor
    /// @param _newGovernor Address of the new governor
    function changeGovernor(address _newGovernor) external onlyGovernor {
        if (networkGovernor != _newGovernor) {
            networkGovernor = _newGovernor;
            emit NewGovernor(_newGovernor);
        }
    }

    function setValidator(address _validator, bool _active) external onlyGovernor {
        if (validators[_validator] != _active) {
            validators[_validator] = _active;
            emit ValidatorStatusUpdate(_validator, _active);
        }
    }

    modifier onlyValidator() {
        require(validators[msg.sender] == true, "fb");
        _;
    }

}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



interface I_Hasher {

    function rescue(
        uint256 message0,
        uint256 message1,
        uint256 message2
    ) external view returns (uint256);
}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



// Functions named bytesToX, except bytesToBytes20, where X is some type of size N < 32 (size of one word)
// implements the following algorithm:
// f(bytes memory input, uint offset) -> X out
// where byte representation of out is N bytes from input at the given offset
// 1) We compute memory location of the word W such that last N bytes of W is input[offset..offset+N]
// W_address = input + 32 (skip stored length of bytes) + offset - (32 - N) == input + offset + N
// 2) We load W from memory into out, last N bytes of W are placed into out

library Bytes {

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x2)
    function bytesToUInt16(bytes memory _bytes, uint256 _start) internal pure returns (uint16 r) {
        uint256 offset = _start + 0x2;
        require(_bytes.length >= offset, "T");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x3)
    function bytesToUInt24(bytes memory _bytes, uint256 _start) internal pure returns (uint24 r) {
        uint256 offset = _start + 0x3;
        require(_bytes.length >= offset, "U");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x4)
    function bytesToUInt32(bytes memory _bytes, uint256 _start) internal pure returns (uint32 r) {
        uint256 offset = _start + 0x4;
        require(_bytes.length >= offset, "V");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x4)
    function bytesToUInt64(bytes memory _bytes, uint256 _start) internal pure returns (uint64 r) {
        uint256 offset = _start + 0x8;
        require(_bytes.length >= offset, "V64");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x10)
    function bytesToUInt128(bytes memory _bytes, uint256 _start) internal pure returns (uint128 r) {
        uint256 offset = _start + 0x10;
        require(_bytes.length >= offset, "W");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x14)
    function bytesToUInt160(bytes memory _bytes, uint256 _start) internal pure returns (uint160 r) {
        uint256 offset = _start + 0x14;
        require(_bytes.length >= offset, "X");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x20)
    function bytesToBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32 r) {
        uint256 offset = _start + 0x20;
        require(_bytes.length >= offset, "Y");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_offset + 2)
    function readUInt16(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint16 r) {
        new_offset = _offset + 2;
        r = bytesToUInt16(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 3)
    function readUInt24(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint24 r) {
        new_offset = _offset + 3;
        r = bytesToUInt24(_data, _offset);
    }

    function readUInt64(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint64 r) {
        new_offset = _offset + 8;
        r = bytesToUInt64(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readUInt160(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint160 r) {
        new_offset = _offset + 20;
        r = bytesToUInt160(_data, _offset);
    }

    // Convert bytes to ASCII hex representation
    function bytesToHexASCIIBytes(bytes memory _input) internal pure returns (bytes memory _output) {
        bytes memory outStringBytes = new bytes(_input.length * 2);

        // code in `assembly` construction is equivalent of the next code:
        // for (uint i = 0; i < _input.length; ++i) {
        //     outStringBytes[i*2] = halfByteToHex(_input[i] >> 4);
        //     outStringBytes[i*2+1] = halfByteToHex(_input[i] & 0x0f);
        // }
        assembly {
            let input_curr := add(_input, 0x20)
            let input_end := add(input_curr, mload(_input))

            for {
                let out_curr := add(outStringBytes, 0x20)
            } lt(input_curr, input_end) {
                input_curr := add(input_curr, 0x01)
                out_curr := add(out_curr, 0x02)
            } {
                let curr_input_byte := shr(0xf8, mload(input_curr))
            // here outStringByte from each half of input byte calculates by the next:
            //
            // "FEDCBA9876543210" ASCII-encoded, shifted and automatically truncated.
            // outStringByte = byte (uint8 (0x66656463626139383736353433323130 >> (uint8 (_byteHalf) * 8)))
                mstore(
                out_curr,
                shl(0xf8, shr(mul(shr(0x04, curr_input_byte), 0x08), 0x66656463626139383736353433323130))
                )
                mstore(
                add(out_curr, 0x01),
                shl(0xf8, shr(mul(and(0x0f, curr_input_byte), 0x08), 0x66656463626139383736353433323130))
                )
            }
        }
        return outStringBytes;
    }
}

pragma solidity >=0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    /// @dev Address of lock flag variable.
    /// @dev Flag is placed at random memory location to not interfere with Storage contract.
    uint256 private constant LOCK_FLAG_ADDRESS =
        0x8e94fed44239eb2314ab7a406345e6c5a8f0ccedf3b600de3d004e672c33abf4; // keccak256("ReentrancyGuard") - 1;

    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/566a774222707e424896c0c390a84dc3c13bdcb2/contracts/security/ReentrancyGuard.sol
    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    function initializeReentrancyGuard() internal {
        uint256 lockSlotOldValue;

        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange every call to nonReentrant
        // will be cheaper.
        assembly {
            lockSlotOldValue := sload(LOCK_FLAG_ADDRESS)
            sstore(LOCK_FLAG_ADDRESS, _NOT_ENTERED)
        }

        // Check that storage slot for reentrancy guard is empty to rule out possibility of slot conflict
        require(lockSlotOldValue == 0, "1B");
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        uint256 _status;
        assembly {
            _status := sload(LOCK_FLAG_ADDRESS)
        }

        // On the first call to nonReentrant, _notEntered will be true
        require(_status == _NOT_ENTERED, "_status != _NOT_ENTERED");

        // Any calls to nonReentrant after this point will fail
        assembly {
            sstore(LOCK_FLAG_ADDRESS, _ENTERED)
        }

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        assembly {
            sstore(LOCK_FLAG_ADDRESS, _NOT_ENTERED)
        }
    }
}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./libs/Bytes.sol";

library Operations {
    /// @notice operation type
    enum OpType {
        Noop,    // 0
        Deposit,
        ForceTrade,
        ForceWithdraw,
        Withdraw,
        Trade,
        Transfer,
        ConditionalTransfer,
        FundingTick,
        OraclePriceTick,
        Liquidate,
        Deleverage
    }

    struct DepositOrWithdraw {
        uint24 accountId;
        uint160 l2Key;
        uint64 amount;
    }

    function readDepositOrWithdrawPubdata(bytes memory _data, uint256 offset) internal pure returns (DepositOrWithdraw memory parsed) {
        (offset, parsed.accountId) = Bytes.readUInt24(_data, offset);   // accountId
        (offset, parsed.l2Key) = Bytes.readUInt160(_data, offset);      // l2Key
        (offset, parsed.amount) = Bytes.readUInt64(_data, offset);      // amount
    }

    uint32 constant FORCED_OP_PUBDATA_BYTES = 21;
    // uint256 constant CONDITIONAL_TRANSFER_PUBDATA_BYTES = 54;
    uint32 constant DEPOSIT_WITHDRAW_PUBDATA_BYTES = 31 ;

    uint32 constant ACCOUNT_COLLATERAL_BALANCE_PUBDATA_BYTES = 11 ;
    uint32 constant ACCOUNT_POSITION_PUBDATA_BYTES = 13 ;

    uint8 constant OP_TYPE_BYTES = 1;

    // ForcedAction pubdata
    struct ForcedAction {
        uint8 opType;    // 0x02, 0x03
        uint160 forcedHash;
    }

    /// Deserialize ForcedAction pubdata
    function readForcedActionPubdata(bytes memory _data, uint256 offset) internal pure returns (ForcedAction memory parsed) {
        parsed.opType = uint8(_data[offset++]);
        (, parsed.forcedHash) = Bytes.readUInt160(_data, offset);
    }
}

pragma solidity >=0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0


import "./Users.sol";
import "./Deposits.sol";
import "./Withdrawals.sol";
import "./UpdateState.sol";
import "./GlobalConfig.sol";
import "./Dac.sol";
import "./custom/Custom.sol";

contract Perpetual is
    Users,
    Deposits,
    Withdrawals,
    UpdateState,
    GlobalConfig,
    Dac,
    Custom
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct perpetualParams {
        Verifier verifierAddress;
        // I_Verifier escapeVerifierAddress; // 暂时不支持
        I_Hasher hasherAddress;
        bytes32 accountRoot;
        bytes32 orderStateHash;
        //  IERC20Upgradeable collateralToken;
        uint8 innerDecimal;
        address userAdmin;
        address genesisGovernor;
        address genesisValidator;
        // address[] dacMembers; // 暂时不用
        // uint32 dac_reg_timelock; // 暂时不用
        uint32 global_config_change_timelock;
        uint32 funding_validity_period;
        uint32 price_validity_period;
        uint64 max_funding_rate;
        uint16 max_asset_num;
        uint16 max_oracle_num;
        SyntheticAssetInfo[] synthetic_assets;
        uint256 deposit_cancel_timelock;
        uint256 forced_action_expire_time; // 暂时不用
    }

    function initialize(perpetualParams calldata param) external {
        initializeReentrancyGuard();

        // genesis block state
        accountRoot = param.accountRoot;
        orderStateHash = param.orderStateHash;

        // verifier
        verifier = param.verifierAddress;
        // escapeVerifier = param.escapeVerifierAddress;
        // hasher
        hasher = param.hasherAddress;

        // governor/validator/UserAdmin
        initGovernor(param.genesisGovernor, param.genesisValidator);
        userAdmin = param.userAdmin;

        // DAC
        // MIN_DAC_MEMBER = 6;
        // TIMELOCK_DAC_REG = param.dac_reg_timelock;
        // for (uint256 i = 0; i < param.dacMembers.length; ++i) {
        //     addDac(param.dacMembers[i]);
        // }
        // require(dacNum >= MIN_DAC_MEMBER, "g");

        // global config
        MAX_ASSETS_COUNT = param.max_asset_num;
        MAX_NUMBER_ORACLES = param.max_oracle_num;
        TIMELOCK_GLOBAL_CONFIG_CHANGE = param.global_config_change_timelock;

        globalConfigHash = initGlobalConfig(
            param.synthetic_assets,
            param.funding_validity_period,
            param.price_validity_period,
            param.max_funding_rate,
            MAX_ASSETS_COUNT,
            MAX_NUMBER_ORACLES
        );
        resetGlobalConfigValidBlockNum();

        // system Token Config
        //  collateralToken = param.collateralToken;
        // innerDecimal = param.innerDecimal;
        //  (bool success, bytes memory returndata) = address(collateralToken).call(
        //      abi.encodeWithSignature("decimals()")
        //  );
        //  require(success, "not success");
        //  systemTokenDecimal = abi.decode(returndata, (uint8));
        systemTokenDecimal = 6;
        DEPOSIT_CANCEL_TIMELOCK = param.deposit_cancel_timelock;
        FORCED_ACTION_EXPIRE_TIME = param.forced_action_expire_time;
    }

    // function upgrade(bytes calldata args) onlyGovernor external {
    // }

    function registerAndDeposit(
        address ethAddr,
        uint256[] memory l2Keys,
        bytes calldata signature,
        uint24[] memory accountIds,
        uint64[] memory amounts
    ) external payable onlyActive {
        registerUser(ethAddr, l2Keys, signature);

        require(accountIds.length == amounts.length, "gb");
        require(accountIds.length == l2Keys.length, "gc");

        for (uint256 i = 0; i < accountIds.length; ++i) {
            deposit(uint160(l2Keys[i]), accountIds[i], amounts[i]);
        }
    }

    event TokenRecovery(address token, uint256 amount);

    receive() external payable {}

    // // allow to recovery wrong token sent to the contract
    // function recoverWrongToken(address token, uint256 amount) external onlyGovernor nonReentrant {
    //     require(token != address(collateralToken), "cbrst");  // "Cannot be system token"
    //     if (token == address(0)) {
    //         payable(msg.sender).transfer(amount);
    //     } else {
    //         IERC20Upgradeable(token).safeTransfer(address(msg.sender), amount);
    //     }
    //     emit TokenRecovery(token, amount);
    // }

    // ONLY for DEBUG
    function setFreeze(bool isFrozen) external onlyGovernor {
        stateFrozen = isFrozen;
    }

    function escape(
        uint24 _accountId,
        uint160 _l2Key,
        uint64 _amount
    )
        external
        // uint256[] calldata _proof
        onlyFrozen
    {
        uint184 packedKey = (uint184(_l2Key) << 24) | uint184(_accountId);
        require(!escapesUsed[packedKey], "gd");
        require(_amount < (1 << 63), "gf");

        // bool proofCorrect = escapeVerifier.verifyEscapeProof(
        //     accountRoot,
        //     orderStateHash,
        //     _accountId,
        //     _l2Key,
        //     _amount,
        //     _proof
        // );
        // require(proofCorrect, "x");

        uint256 externalAmount = _amount *
            (10 ** (systemTokenDecimal - innerDecimal));
        pendingWithdrawals[_l2Key] += externalAmount;
        emit LogWithdrawalAllowed(_l2Key, externalAmount);

        escapesUsed[packedKey] = true;
    }
}

pragma solidity >=0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0


import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SafeERC20Upgradeable, IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./verifier/Verifier.sol";
import "./libs/ReentrancyGuard.sol";
import "./hasher/I_Hasher.sol";
import "./Operations.sol";
import "./Governance.sol";

bytes32 constant EMPTY_STRING_KECCAK = keccak256("");
uint64 constant DEPOSIT_LOWER_BOUND = (1 << 63);

struct SyntheticAssetInfo {
    uint64 resolution;
    uint32 risk_factor;
    bytes12 asset_name;
    bytes oracle_price_signers_pubkey_hash;
}

/// @title Storage Contract
contract Storage is Governance, ReentrancyGuard {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event LogNewGlobalConfigHash(uint32 blockNumber, bytes32 configHash);

    /* block chain root hash */
    bytes32 public accountRoot;
    bytes32 public orderStateHash;

    mapping(address => bool) public dacs;
    uint32 public dacNum;
    uint32 constant MIN_SIGNATURE_MEMBER = 3;
    uint256 public DacRegisterTime;
    address pendingDacMember;
    bool public DacRegisterActive;

    bytes32 public globalConfigHash;

    // Mapping from layer2 public key to the Ethereum public key of its owner.
    // 1. used to valid withdraw request
    // 2. allows registering many different l2keys to same eth address ?
    //     2.1 user might wanna both validum and rollup account.
    //     2.2 API user might wanna multiple account.
    address userAdmin;
    mapping(uint256 => address) public ethKeys;
    modifier onlyKeyOwner(uint256 ownerKey) {
        require(msg.sender == ethKeys[ownerKey], "h");
        _;
    }

    Verifier internal verifier;
    I_Hasher public hasher;

    IERC20Upgradeable public collateralToken;
    uint8 public innerDecimal;
    mapping(uint256 => uint256) public pendingDeposits;
    mapping(uint256 => uint256) public pendingWithdrawals;

    // map packedKey => timestamp.
    mapping(uint256 => uint256) public cancellationRequests;

    // map forced Action Request Hash => timestatmp
    mapping(uint160 => uint256) forcedActionRequests;

    bool public stateFrozen;
    // I_Verifier public escapeVerifier;
    mapping(uint256 => bool) escapesUsed;

    function addForcedRequest(uint160 req) internal {
        require(forcedActionRequests[req] == 0, "ha");
        forcedActionRequests[req] = block.timestamp;
    }

    function removeForcedRequest(
        uint160 req,
        bool isForcedWithdrawal
    ) internal {
        require(forcedActionRequests[req] != 0, "hb");
        if (isForcedWithdrawal) {
            delete forcedActionRequests[req];
        } else {
            // forcedTrade
            require(forcedActionRequests[req] != ~uint256(0), "hc");
            forcedActionRequests[req] = ~uint256(0);
        }
    }

    function freeze(uint160 req) public {
        require(
            forcedActionRequests[req] != 0 &&
                forcedActionRequests[req] != ~uint256(0),
            "hd"
        );
        require(
            forcedActionRequests[req] + FORCED_ACTION_EXPIRE_TIME >
                block.timestamp,
            "he"
        );
        stateFrozen = true;
    }

    modifier onlyFrozen() {
        require(stateFrozen, "hf");
        _;
    }

    modifier onlyActive() {
        require(!stateFrozen, "hg");
        _;
    }

    mapping(address => bool) operators;

    // for conditional transfer
    mapping(bytes32 => bool) proofRegister;

    uint16 MAX_ASSETS_COUNT;

    bytes32 public newGlobalConfigHash;
    uint256 public newGlobalConfigValidBlockNum;

    function resetGlobalConfigValidBlockNum() internal {
        newGlobalConfigValidBlockNum = ~uint256(0);
    }

    function is_pending_global_config() internal view returns (bool) {
        return newGlobalConfigValidBlockNum != ~uint256(0);
    }

    // Mapping for timelocked actions.
    // A actionKey => activation time.
    mapping(bytes32 => uint256) actionsTimeLock;

    uint8 systemTokenDecimal;

    uint16 public MAX_NUMBER_ORACLES;
    uint32 TIMELOCK_GLOBAL_CONFIG_CHANGE;
    uint256 DEPOSIT_CANCEL_TIMELOCK;
    uint256 FORCED_ACTION_EXPIRE_TIME;

    uint32 public MIN_DAC_MEMBER;
    uint32 TIMELOCK_DAC_REG;

    // TODO: will delete in production
    function setFrozen(bool frozen) external onlyGovernor {
        require(stateFrozen != frozen, "stateFrozen equal frozen");
        stateFrozen = frozen;
    }
}

pragma solidity >=0.8.12;

// SPDX-License-Identifier: MIT OR Apache-2.0


import "./Config.sol";
import "./ForcedWithdrawals.sol";
import "./ForcedTrade.sol";
import "./Storage.sol";

abstract contract UpdateState is
    Config,
    Storage,
    ForcedTrade,
    ForcedWithdrawals
{
    event LogWithdrawalAllowed(uint256 l2Key, uint256 amount);

    event BlockUpdate(uint32 firstBlock, uint32 lastBlock);

    // struct GlobalFunding {
    //     uint64[] index; // per asset when block have funding_tick transaction
    //     uint256 indexHashOrTimeStamp; // if index.length==0, = bytes32 hash, else uint32 timestamp
    // }
    struct GlobalFunding {
        uint64[] index; // per asset when block have funding_tick transaction
        bytes32 indexHash; //  bytes32 hash
        uint32 timestamp;
    }

    struct CommitBlockInfo {
        uint32 blockNumber;
        uint32 timestamp;
        bytes32 accountRoot; // root hash of account
        bytes32 validiumAccountRoot; // for rollup merkle path, rollupAccount could be restore from pubData
        bytes32 orderRoot;
        GlobalFunding globalFunding;
        bytes32 oraclePriceHash;
        bytes32 orderStateHash; // include funding index, oracle price, orderRoot
        bytes32 all_data_commitment; // account Full Data Hash
        uint32 blockChunkSize;
        bytes collateralBalancePubData; // per account [accountId, collateral_balance]
        bytes positonPubData; // per account [accountId, asset_id, balance]
        bytes onchainPubData; // per onchain operation (deposit/withdraw/forcedWithdrawal)
        bytes forcedPubData; // per forced operation (forcedWithdrawal/forcedTrade) [op_type, ...]
    }

    struct ProofInput {
        uint256[] recursiveInput;
        uint256[] proof;
        uint256[] commitments;
        uint8[] vkIndexes;
        uint256[16] subproofsLimbs;
    }

    function getPadLen(
        uint256 realSize,
        uint32 alignSize
    ) internal pure returns (uint256 padLen) {
        padLen = realSize % alignSize;
        if (padLen != 0) {
            padLen = alignSize - padLen;
        } else if (realSize == 0) {
            padLen = alignSize;
        }
    }

    function pubdataPadCommitment(
        bytes calldata pubdata,
        uint32 alignSize
    ) internal pure returns (bytes32 commitment) {
        uint256 padLen = getPadLen(pubdata.length, alignSize);
        if (padLen != 0) {
            bytes memory padZero = new bytes(padLen);
            commitment = sha256(bytes.concat(pubdata, padZero));
        } else {
            commitment = sha256(pubdata);
        }
    }

    function createBlockCommitment(
        bytes32 oldAccountRoot,
        bytes32 oldOrderStateHash,
        bytes32 newOrderStateHash,
        CommitBlockInfo calldata newBlock
    ) internal view returns (bytes32 commitment) {
        // bytes memory h = abi.encodePacked(
        //     newBlock.blockNumber,
        //     oldAccountRoot,
        //     newBlock.accountRoot,
        //     oldOrderStateHash,
        //     newOrderStateHash,
        //     globalConfigHash
        //     // newBlock.validiumAccountRoot
        // );

        bytes32 h = sha256(
            bytes.concat(abi.encode(newBlock.blockNumber), oldAccountRoot)
        );
        h = sha256(bytes.concat(h, newBlock.accountRoot));
        h = sha256(bytes.concat(h, oldOrderStateHash));
        h = sha256(bytes.concat(h, newOrderStateHash));
        h = sha256(bytes.concat(h, globalConfigHash));

        uint32 alignSize = newBlock.blockChunkSize *
            Operations.ACCOUNT_COLLATERAL_BALANCE_PUBDATA_BYTES;
        bytes32 rollup_col_commitment = pubdataPadCommitment(
            newBlock.collateralBalancePubData,
            alignSize
        );

        alignSize =
            newBlock.blockChunkSize *
            Operations.ACCOUNT_POSITION_PUBDATA_BYTES;
        bytes32 rollup_assets_commitment = pubdataPadCommitment(
            newBlock.positonPubData,
            alignSize
        );

        bytes32 rollup_data_commitment = sha256(
            bytes.concat(rollup_col_commitment, rollup_assets_commitment)
        );
        // h = bytes.concat(h, rollup_data_commitment);
        // h = bytes.concat(h, newBlock.all_data_commitment);
        // h = sha256(bytes.concat(h, rollup_data_commitment));

        bytes32 data_commitment = sha256(
            bytes.concat(rollup_data_commitment, newBlock.all_data_commitment)
        );
        h = sha256(bytes.concat(h, data_commitment));

        alignSize =
            newBlock.blockChunkSize *
            Operations.DEPOSIT_WITHDRAW_PUBDATA_BYTES;
        bytes32 onchain_commitment = pubdataPadCommitment(
            newBlock.onchainPubData,
            alignSize
        );
        // h = bytes.concat(h, onchain_commitment);
        h = sha256(bytes.concat(h, onchain_commitment));

        alignSize =
            newBlock.blockChunkSize *
            Operations.FORCED_OP_PUBDATA_BYTES;
        bytes32 forced_commitment = pubdataPadCommitment(
            newBlock.forcedPubData,
            alignSize
        );

        commitment = sha256(bytes.concat(h, forced_commitment));
    }

    function postProcess(bytes calldata pubData) internal {
        uint256 offset = 0;
        uint256 factor = 10 ** (systemTokenDecimal - innerDecimal);

        while (offset < pubData.length) {
            Operations.DepositOrWithdraw memory op = Operations
                .readDepositOrWithdrawPubdata(pubData, offset);
            if (!(op.accountId == 0 && op.l2Key == 0 && op.amount == 0)) {
                uint256 packedKey = (uint256(op.l2Key) << 24) |
                    uint256(op.accountId);
                if (op.amount > DEPOSIT_LOWER_BOUND) {
                    uint256 innerAmount = (uint256(op.amount) -
                        DEPOSIT_LOWER_BOUND);
                    pendingDeposits[packedKey] -= innerAmount * factor;
                } else {
                    uint256 innerAmount = (DEPOSIT_LOWER_BOUND -
                        uint256(op.amount));
                    uint256 externalAmount = innerAmount * factor;
                    pendingWithdrawals[op.l2Key] += externalAmount;
                    emit LogWithdrawalAllowed(op.l2Key, externalAmount);
                }
            }

            offset += Operations.DEPOSIT_WITHDRAW_PUBDATA_BYTES;
        }
    }

    function processForcedAction(bytes calldata pubData) internal {
        uint256 offset = 0;
        while (offset < pubData.length) {
            Operations.ForcedAction memory op = Operations
                .readForcedActionPubdata(pubData, offset);
            Operations.OpType opType = Operations.OpType(op.opType);
            if (opType == Operations.OpType.ForceWithdraw) {
                removeForcedRequest(op.forcedHash, true);
            } else if (opType == Operations.OpType.ForceTrade) {
                removeForcedRequest(op.forcedHash, false);
            } else {
                revert("i"); // unsupported op
            }

            offset += Operations.FORCED_OP_PUBDATA_BYTES;
        }
    }

    function encodePackU64Array(
        uint64[] memory a,
        uint start,
        uint padLen,
        uint64 padValue
    ) internal pure returns (bytes memory data) {
        for (uint i = start; i < start + padLen; i++) {
            if (i < a.length) {
                data = abi.encodePacked(data, a[i]);
            } else {
                data = abi.encodePacked(data, padValue);
            }
        }
    }

    function getOrderStateHash(
        CommitBlockInfo calldata b,
        uint64[] memory oracle_price
    ) internal pure returns (bytes32 newOrderStateHash) {
        if (oracle_price.length == 0 && b.globalFunding.index.length == 0) {
            return b.orderStateHash;
        }

        bytes32 oraclePriceHash = b.oraclePriceHash;
        // if (oracle_price.length != 0) {
        //     bytes memory encode_data = encodePackU64Array(
        //         oracle_price,
        //         0,
        //         MAX_ASSETS_COUNT,
        //         0
        //     );
        //     oraclePriceHash = sha256(encode_data);
        // }

        bytes32 globalFundingIndexHash = b.globalFunding.indexHash;
        // if (b.globalFunding.index.length != 0) {
        //     uint32 timestamp = uint32(b.globalFunding.indexHashOrTimeStamp);
        //     bytes memory encode_data = abi.encodePacked(
        //         timestamp,
        //         encodePackU64Array(
        //             b.globalFunding.index,
        //             0,
        //             MAX_ASSETS_COUNT,
        //             1 << 63
        //         )
        //     );
        //     globalFundingIndexHash = sha256(encode_data);
        // } else {
        //     globalFundingIndexHash = bytes32(
        //         b.globalFunding.indexHashOrTimeStamp
        //     );
        // }

        bytes32 global_state_hash = sha256(
            abi.encodePacked(
                b.globalFunding.timestamp,
                globalFundingIndexHash,
                oraclePriceHash
            )
        );
        newOrderStateHash = sha256(
            bytes.concat(b.orderRoot, global_state_hash)
        );
    }

    function verifyProofCommitment(
        CommitBlockInfo[] calldata _newBlocks,
        uint256[] calldata proof_commitments,
        uint64[] calldata lastestOraclePrice
    ) internal returns (bytes32 curOrderStateHash) {
        bytes32 curAccountRoot = accountRoot;
        curOrderStateHash = orderStateHash;
        for (uint256 i = 0; i < _newBlocks.length; ++i) {
            if (
                is_pending_global_config() &&
                _newBlocks[i].blockNumber == newGlobalConfigValidBlockNum
            ) {
                resetGlobalConfigValidBlockNum();
                globalConfigHash = newGlobalConfigHash;
                emit LogNewGlobalConfigHash(
                    _newBlocks[i].blockNumber,
                    newGlobalConfigHash
                );
            }

            // Create block commitment, and check with proof commitment
            uint64[] memory oraclePrice;
            if (i == _newBlocks.length - 1) {
                oraclePrice = lastestOraclePrice;
            }
            bytes32 newOrderStateHash = getOrderStateHash(
                _newBlocks[i],
                oraclePrice
            );
            bytes32 commitment = createBlockCommitment(
                curAccountRoot,
                curOrderStateHash,
                newOrderStateHash,
                _newBlocks[i]
            );
            require(
                proof_commitments[i] & INPUT_MASK ==
                    uint256(commitment) & INPUT_MASK,
                "ia"
            );

            curAccountRoot = _newBlocks[i].accountRoot;
            curOrderStateHash = newOrderStateHash;
        }
    }

    // function verifyValidiumSignature(
    //     CommitBlockInfo[] calldata newBlocks,
    //     bytes[] calldata validium_signature
    // ) internal view {
    //     bytes32 concatValdiumHash = EMPTY_STRING_KECCAK;
    //     for (uint256 i = 0; i < newBlocks.length; ++i) {
    //         concatValdiumHash = keccak256(
    //             bytes.concat(
    //                 concatValdiumHash,
    //                 newBlocks[i].all_data_commitment
    //             )
    //         );
    //     }

    //     bytes memory message = bytes.concat(
    //         "\x19Ethereum Signed Message:\n66",
    //         "0x",
    //         Bytes.bytesToHexASCIIBytes(abi.encodePacked(concatValdiumHash))
    //     );
    //     bytes32 msgHash = keccak256(message);

    //     uint32 sig_dac_num = 0;
    //     address[MIN_SIGNATURE_MEMBER] memory signers;
    //     for (uint256 i = 0; i < validium_signature.length; ++i) {
    //         address signer = ECDSA.recover(msgHash, validium_signature[i]);
    //         require(dacs[signer], "ib");

    //         uint256 j;
    //         for (j = 0; j < sig_dac_num; ++j) {
    //             if (signers[j] == signer) {
    //                 break;
    //             }
    //         }

    //         if (j != sig_dac_num) {
    //             // ignore same signer
    //             continue;
    //         }

    //         signers[sig_dac_num++] = signer;
    //         if (sig_dac_num == MIN_SIGNATURE_MEMBER) {
    //             // ignore additional signature.
    //             break;
    //         }
    //     }
    //     require(sig_dac_num >= MIN_SIGNATURE_MEMBER, "ic");
    // }

    function updateBlocks(
        CommitBlockInfo[] calldata _newBlocks,
        // bytes[] calldata validium_signature, // 暂时不用
        ProofInput calldata _proof,
        uint64[] calldata lastestOraclePrice
    ) external onlyActive nonReentrant {
        require(_newBlocks.length >= 1, "newBlocks length less than 1");
        // verifyValidiumSignature(_newBlocks, validium_signature);
        bytes32 newOrderStateHash = verifyProofCommitment(
            _newBlocks,
            _proof.commitments,
            lastestOraclePrice
        );

        //        bool success = verifier.verifyAggregatedBlockProof(
        //            _proof.recursiveInput,
        //            _proof.proof,
        //            _proof.vkIndexes,
        //            _proof.commitments,
        //            _proof.subproofsLimbs
        //        );
        //        require(success, "p"); // Aggregated proof verification fail

        bool success = verifier.verifyAggregatedBlockProof(
            _proof.subproofsLimbs,
            _proof.recursiveInput,
            _proof.proof,
            _proof.vkIndexes,
            _proof.commitments
        );
        require(success, "p");

        //postprocess onchain and forced operation
        for (uint256 i = 0; i < _newBlocks.length; ++i) {
            postProcess(_newBlocks[i].onchainPubData);
            processForcedAction(_newBlocks[i].forcedPubData);
        }

        // update block status
        accountRoot = _newBlocks[_newBlocks.length - 1].accountRoot;
        orderStateHash = newOrderStateHash;

        emit BlockUpdate(
            _newBlocks[0].blockNumber,
            _newBlocks[_newBlocks.length - 1].blockNumber
        );
    }

    //// for test
    // function _getOrderStateHash(
    //     CommitBlockInfo calldata b,
    //     uint64[] memory oracle_price
    // ) external view returns (bytes32 newOrderStateHash) {
    //     return getOrderStateHash(b, oracle_price);
    // }

    // function _getBlockCommitment(
    //     bytes32 oldAccountRoot,
    //     bytes32 oldOrderStateHash,
    //     bytes32 newOrderStateHash,
    //     CommitBlockInfo calldata newBlock
    // )
    //     external
    //     view
    //     returns (
    //         bytes32 h4,
    //         bytes32 h5,
    //         bytes32 h6,
    //         bytes32 commitment,
    //         bytes32 rollup_col_commitment,
    //         bytes32 rollup_assets_commitment,
    //         bytes32 rollup_data_commitment,
    //         bytes32 onchain_commitment
    //     )
    // {
    //     // bytes memory h = abi.encodePacked(
    //     //     newBlock.blockNumber,
    //     //     oldAccountRoot,
    //     //     newBlock.accountRoot,
    //     //     oldOrderStateHash,
    //     //     newOrderStateHash,
    //     //     globalConfigHash
    //     //     // newBlock.validiumAccountRoot
    //     // );

    //     bytes32 h = sha256(
    //         bytes.concat(abi.encode(newBlock.blockNumber), oldAccountRoot)
    //     );
    //     h = sha256(bytes.concat(h, newBlock.accountRoot));
    //     h = sha256(bytes.concat(h, oldOrderStateHash));
    //     h = sha256(bytes.concat(h, newOrderStateHash));
    //     h4 = h;
    //     h = sha256(bytes.concat(h, globalConfigHash));
    //     h5 = h;

    //     uint32 alignSize = newBlock.blockChunkSize *
    //         Operations.ACCOUNT_COLLATERAL_BALANCE_PUBDATA_BYTES;
    //     rollup_col_commitment = pubdataPadCommitment(
    //         newBlock.collateralBalancePubData,
    //         alignSize
    //     );

    //     alignSize =
    //         newBlock.blockChunkSize *
    //         Operations.ACCOUNT_POSITION_PUBDATA_BYTES;
    //     rollup_assets_commitment = pubdataPadCommitment(
    //         newBlock.positonPubData,
    //         alignSize
    //     );

    //     rollup_data_commitment = sha256(
    //         bytes.concat(rollup_col_commitment, rollup_assets_commitment)
    //     );
    //     // h = bytes.concat(h, rollup_data_commitment);
    //     // h = bytes.concat(h, newBlock.all_data_commitment);
    //     // h = sha256(bytes.concat(h, rollup_data_commitment));

    //     bytes32 data_commitment = sha256(
    //         bytes.concat(rollup_data_commitment, newBlock.all_data_commitment)
    //     );
    //     h = sha256(bytes.concat(h, data_commitment));
    //     h6 = h;

    //     alignSize =
    //         newBlock.blockChunkSize *
    //         Operations.DEPOSIT_WITHDRAW_PUBDATA_BYTES;
    //     onchain_commitment = pubdataPadCommitment(
    //         newBlock.onchainPubData,
    //         alignSize
    //     );
    //     // h = bytes.concat(h, onchain_commitment);
    //     commitment = sha256(bytes.concat(h, onchain_commitment));

    //     // alignSize =
    //     //     newBlock.blockChunkSize *
    //     //     Operations.FORCED_OP_PUBDATA_BYTES;
    //     // forced_commitment = pubdataPadCommitment(
    //     //     newBlock.forcedPubData,
    //     //     alignSize
    //     // );

    //     // commitment = sha256(bytes.concat(h, forced_commitment));
    // }
}

pragma solidity >=0.8.12;

// SPDX-License-Identifier: Apache-2.0.


import "./Storage.sol";

// import "./libs/Bytes.sol";

abstract contract Users is Storage {
    event LogUserRegistered(address ethAddr, uint256[] l2Keys, address sender);

    function registerUser(
        address ethAddr,
        uint256[] memory l2Keys,
        bytes calldata signature
    )
        public
        view
        returns (bytes memory orig_msg_, bytes memory message_, address signer_)
    {
        for (uint32 i = 0; i < l2Keys.length; ++i) {
            require(l2Keys[i] < (1 << 160), "j");
            require(ethKeys[l2Keys[i]] == address(0), "j0");
        }

        bytes32 concatKeyHash = EMPTY_STRING_KECCAK;
        for (uint256 i = 0; i < l2Keys.length; ++i) {
            concatKeyHash = keccak256(
                abi.encodePacked(concatKeyHash, l2Keys[i])
            );
        }

        bytes memory orig_msg = bytes.concat(
            abi.encode(ethAddr),
            concatKeyHash
        );
        orig_msg_ = orig_msg;

        bytes memory message = bytes.concat(
            "\x19Ethereum Signed Message:\n130", // 10-th 130
            "0x",
            Bytes.bytesToHexASCIIBytes(orig_msg)
        );
        message_ = message;

        address signer = ECDSA.recover(keccak256(message), signature);
        signer_ = signer;
        // require(signer == userAdmin, "j1");

        // for (uint32 i = 0; i < l2Keys.length; ++i) {
        //     ethKeys[l2Keys[i]] = ethAddr;
        // }
        // emit LogUserRegistered(ethAddr, l2Keys, msg.sender);
    }
}

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./VerifierWithDeserialize.sol";

// Hardcoded constants to avoid accessing store
contract KeysWithPlonkVerifier is VerifierWithDeserialize {
    uint256 constant VK_TREE_ROOT =
        0x18bde520240bab7f5c1904dacd8585a4e6c0424b1ff2a38e0b88fb909415b8ec;
    uint8 constant VK_MAX_INDEX = 0;

    function getVkAggregated(
        uint32 _proofs
    ) internal pure returns (VerificationKey memory vk) {
        if (_proofs == uint32(1)) {
            return getVkAggregated1();
        }
    }

    function getVkAggregated1()
        internal
        pure
        returns (VerificationKey memory vk)
    {
        vk.domain_size = 4194304;
        vk.num_inputs = 1;
        vk.omega = PairingsBn254.new_fr(
            0x18c95f1ae6514e11a1b30fd7923947c5ffcec5347f16e91b4dd654168326bede
        );
        vk.gate_setup_commitments[0] = PairingsBn254.new_g1(
            0x16782f42f191b0b1841c2b6a42b7f0564af065d04818526df6c3ad41fe35f8da,
            0x125b9c68c0b931578f8a18fd23ce08e7b7c082ad76404ccece796fa9b3ec0cb0
        );
        vk.gate_setup_commitments[1] = PairingsBn254.new_g1(
            0x2511833eee308a3936b23b27c929942a60aa780747bf32143dc183e873144bfd,
            0x1b8d88d78fcc4a36ebe90fbbdc4547442411e0c8d484727d5c7c6eec27ad2df0
        );
        vk.gate_setup_commitments[2] = PairingsBn254.new_g1(
            0x2945641d0c5556aa333ef6c8431e24379b73eccbed7ff3e9425cc64aee1e92ed,
            0x25bbf079192cc83f160da9375e7aec3d3d2caac8d831a29b50f5497071fc14c6
        );
        vk.gate_setup_commitments[3] = PairingsBn254.new_g1(
            0x09b3c361e5895a8e074eb9b9a9e57af59966f0464068460adc3f64e58544afa4,
            0x0412a017f775dd05af16cf387a1e822c2a7e0f8b7cfabd0eb4eb0f67b20e4ada
        );
        vk.gate_setup_commitments[4] = PairingsBn254.new_g1(
            0x244b30447ab3e56bb5a5a7f0ef8463a4047476ea269735a887b3de568b3401a3,
            0x2ba860198d5e6e0fd93355cb5f309e7e4c1113a57222830961999b79b83d700f
        );
        vk.gate_setup_commitments[5] = PairingsBn254.new_g1(
            0x0e13af99775bf5555c366e9c8d4af25a2e195807b766b422856525c01a38b12d,
            0x1787389894222dba5371ab55d512460c5205c1baa0421fc877b183025079a472
        );
        vk.gate_setup_commitments[6] = PairingsBn254.new_g1(
            0x233a03f89c094cf39c89020772d9b912bd0c303d211002ee5afc5c59e241f02b,
            0x04fa51fca1b17399bbbf2b99f17bbce6af1f50b085add4c41ac4ea64f65f4674
        );
        vk.gate_selector_commitments[0] = PairingsBn254.new_g1(
            0x1ca088ed531e65b722c8b48568359bbe11051b86f1a8e8951eacc615d9faed3b,
            0x074b06c09de93dd79e070a9ded635e21a34d7178e9a670766e8208149c28e339
        );
        vk.gate_selector_commitments[1] = PairingsBn254.new_g1(
            0x2b4c77c0d47676559061b47968a044aec625cb907181457428e5d08df9b27ef8,
            0x1c1be561bdc3eba16162886a2943882157f98ed8246f2063028497f1c108fa93
        );
        vk.copy_permutation_commitments[0] = PairingsBn254.new_g1(
            0x238fd7f2cbc3c3e5899483633c78f051e6d6d25f31aaa6b32b863d55b20d641a,
            0x1f9877b625eaae7a084582a2ffce326a6a5558f3efdb3367037098c4ca25a647
        );
        vk.copy_permutation_commitments[1] = PairingsBn254.new_g1(
            0x0b126f60653e371f3f2a85301f16e9cf4af04922a2725fc131b17e90e13d0d84,
            0x13bc3f0c7475b74591827463943b35cfd05adb7094a79eeeee2067e8e28a8e84
        );
        vk.copy_permutation_commitments[2] = PairingsBn254.new_g1(
            0x06cae3c1e5b43afb4dda3243c99da693a27eba065fd61a873e99e2c85fd22719,
            0x14343c6bdcc85b01b053f26aa3c473cb2f24747ba6d6b90b2323b24f3dfd127e
        );
        vk.copy_permutation_commitments[3] = PairingsBn254.new_g1(
            0x217564e2c710d050161b57ef2700e1676251a6d457c4b0d94c41a4492d6dcea3,
            0x2365779642d63803d0265a7cc666b3af6ad92b7e9ef38d9113db1208b83f0732
        );
        vk.copy_permutation_non_residues[0] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000005
        );
        vk.copy_permutation_non_residues[1] = PairingsBn254.new_fr(
            0x0000000000000000000000000000000000000000000000000000000000000007
        );
        vk.copy_permutation_non_residues[2] = PairingsBn254.new_fr(
            0x000000000000000000000000000000000000000000000000000000000000000a
        );

        vk.g2_x = PairingsBn254.new_g2(
            [
                0x260e01b251f6f1c7e7ff4e580791dee8ea51d87a358e038b4efe30fac09383c1,
                0x0118c4d5b837bcc2bc89b5b398b5974e9f5944073b32078b7e231fec938883b0
            ],
            [
                0x04fc6369f7110fe3d25156c1bb9a72859cf2a04641f99ba4ee413c80da6a5fe4,
                0x22febda3c0c0632a56475b4214e5615e11e6dd3f96e6cea2854a87d4dacc5e55
            ]
        );
    }
}

pragma solidity >=0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0


library PairingsBn254 {
    uint256 constant q_mod =
        21888242871839275222246405745257275088696311157297823662689037894645226208583;
    uint256 constant r_mod =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant bn254_b_coeff = 3;

    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    struct Fr {
        uint256 value;
    }

    function new_fr(uint256 fr) internal pure returns (Fr memory) {
        require(fr < r_mod, "fr >= r_mod");
        return Fr({value: fr});
    }

    function copy(Fr memory self) internal pure returns (Fr memory n) {
        n.value = self.value;
    }

    function assign(Fr memory self, Fr memory other) internal pure {
        self.value = other.value;
    }

    function inverse(Fr memory fr) internal view returns (Fr memory) {
        require(fr.value != 0, "fr.value is zero");
        return pow(fr, r_mod - 2);
    }

    function add_assign(Fr memory self, Fr memory other) internal pure {
        self.value = addmod(self.value, other.value, r_mod);
    }

    function sub_assign(Fr memory self, Fr memory other) internal pure {
        self.value = addmod(self.value, r_mod - other.value, r_mod);
    }

    function mul_assign(Fr memory self, Fr memory other) internal pure {
        self.value = mulmod(self.value, other.value, r_mod);
    }

    function pow(
        Fr memory self,
        uint256 power
    ) internal view returns (Fr memory) {
        uint256[6] memory input = [32, 32, 32, self.value, power, r_mod];
        uint256[1] memory result;
        bool success;
        assembly {
            success := staticcall(gas(), 0x05, input, 0xc0, result, 0x20)
        }
        require(success, "not success");
        return Fr({value: result[0]});
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }

    function new_g1(
        uint256 x,
        uint256 y
    ) internal pure returns (G1Point memory) {
        return G1Point(x, y);
    }

    function new_g1_checked(
        uint256 x,
        uint256 y
    ) internal pure returns (G1Point memory) {
        if (x == 0 && y == 0) {
            // point of infinity is (0,0)
            return G1Point(x, y);
        }

        // check encoding
        require(x < q_mod, "x >= q_mod");
        require(y < q_mod, "y >= q_mod");
        // check on curve
        uint256 lhs = mulmod(y, y, q_mod); // y^2
        uint256 rhs = mulmod(x, x, q_mod); // x^2
        rhs = mulmod(rhs, x, q_mod); // x^3
        rhs = addmod(rhs, bn254_b_coeff, q_mod); // x^3 + b
        require(lhs == rhs, "lhs != rhs");

        return G1Point(x, y);
    }

    function new_g2(
        uint256[2] memory x,
        uint256[2] memory y
    ) internal pure returns (G2Point memory) {
        return G2Point(x, y);
    }

    function copy_g1(
        G1Point memory self
    ) internal pure returns (G1Point memory result) {
        result.X = self.X;
        result.Y = self.Y;
    }

    function P2() internal pure returns (G2Point memory) {
        // for some reason ethereum expects to have c1*v + c0 form

        return
            G2Point(
                [
                    0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2,
                    0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed
                ],
                [
                    0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b,
                    0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa
                ]
            );
    }

    function negate(G1Point memory self) internal pure {
        // The prime q in the base field F_q for G1
        if (self.Y == 0) {
            require(self.X == 0, "self.X is not zero");
            return;
        }

        self.Y = q_mod - self.Y;
    }

    function point_add(
        G1Point memory p1,
        G1Point memory p2
    ) internal view returns (G1Point memory r) {
        point_add_into_dest(p1, p2, r);
        return r;
    }

    function point_add_assign(
        G1Point memory p1,
        G1Point memory p2
    ) internal view {
        point_add_into_dest(p1, p2, p1);
    }

    function point_add_into_dest(
        G1Point memory p1,
        G1Point memory p2,
        G1Point memory dest
    ) internal view {
        if (p2.X == 0 && p2.Y == 0) {
            // we add zero, nothing happens
            dest.X = p1.X;
            dest.Y = p1.Y;
            return;
        } else if (p1.X == 0 && p1.Y == 0) {
            // we add into zero, and we add non-zero point
            dest.X = p2.X;
            dest.Y = p2.Y;
            return;
        } else {
            uint256[4] memory input;

            input[0] = p1.X;
            input[1] = p1.Y;
            input[2] = p2.X;
            input[3] = p2.Y;

            bool success = false;
            assembly {
                success := staticcall(gas(), 6, input, 0x80, dest, 0x40)
            }
            require(success, "not success");
        }
    }

    function point_sub_assign(
        G1Point memory p1,
        G1Point memory p2
    ) internal view {
        point_sub_into_dest(p1, p2, p1);
    }

    function point_sub_into_dest(
        G1Point memory p1,
        G1Point memory p2,
        G1Point memory dest
    ) internal view {
        if (p2.X == 0 && p2.Y == 0) {
            // we subtracted zero, nothing happens
            dest.X = p1.X;
            dest.Y = p1.Y;
            return;
        } else if (p1.X == 0 && p1.Y == 0) {
            // we subtract from zero, and we subtract non-zero point
            dest.X = p2.X;
            dest.Y = q_mod - p2.Y;
            return;
        } else {
            uint256[4] memory input;

            input[0] = p1.X;
            input[1] = p1.Y;
            input[2] = p2.X;
            input[3] = q_mod - p2.Y;

            bool success = false;
            assembly {
                success := staticcall(gas(), 6, input, 0x80, dest, 0x40)
            }
            require(success, "not success");
        }
    }

    function point_mul(
        G1Point memory p,
        Fr memory s
    ) internal view returns (G1Point memory r) {
        point_mul_into_dest(p, s, r);
        return r;
    }

    function point_mul_assign(G1Point memory p, Fr memory s) internal view {
        point_mul_into_dest(p, s, p);
    }

    function point_mul_into_dest(
        G1Point memory p,
        Fr memory s,
        G1Point memory dest
    ) internal view {
        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s.value;
        bool success;
        assembly {
            success := staticcall(gas(), 7, input, 0x60, dest, 0x40)
        }
        require(success, "not success");
    }

    function pairing(
        G1Point[] memory p1,
        G2Point[] memory p2
    ) internal view returns (bool) {
        require(p1.length == p2.length, "p1.length != p2.length");
        uint256 elements = p1.length;
        uint256 inputSize = elements * 6;
        uint256[] memory input = new uint256[](inputSize);
        for (uint256 i = 0; i < elements; i++) {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint256[1] memory out;
        bool success;
        assembly {
            success := staticcall(
                gas(),
                8,
                add(input, 0x20),
                mul(inputSize, 0x20),
                out,
                0x20
            )
        }
        require(success, "not success");
        return out[0] != 0;
    }

    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
}

pragma solidity >=0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0


import "./PairingsBn254.sol";

library TranscriptLibrary {
    // flip                    0xe000000000000000000000000000000000000000000000000000000000000000;
    uint256 constant FR_MASK =
        0x1fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    uint32 constant DST_0 = 0;
    uint32 constant DST_1 = 1;
    uint32 constant DST_CHALLENGE = 2;

    struct Transcript {
        bytes32 state_0;
        bytes32 state_1;
        uint32 challenge_counter;
    }

    function new_transcript() internal pure returns (Transcript memory t) {
        t.state_0 = bytes32(0);
        t.state_1 = bytes32(0);
        t.challenge_counter = 0;
    }

    function update_with_u256(Transcript memory self, uint256 value)
        internal
        pure
    {
        bytes32 old_state_0 = self.state_0;
        self.state_0 = keccak256(
            abi.encodePacked(DST_0, old_state_0, self.state_1, value)
        );
        self.state_1 = keccak256(
            abi.encodePacked(DST_1, old_state_0, self.state_1, value)
        );
    }

    function update_with_fr(
        Transcript memory self,
        PairingsBn254.Fr memory value
    ) internal pure {
        update_with_u256(self, value.value);
    }

    function update_with_g1(
        Transcript memory self,
        PairingsBn254.G1Point memory p
    ) internal pure {
        update_with_u256(self, p.X);
        update_with_u256(self, p.Y);
    }

    function get_challenge(Transcript memory self)
        internal
        pure
        returns (PairingsBn254.Fr memory challenge)
    {
        bytes32 query = keccak256(
            abi.encodePacked(
                DST_CHALLENGE,
                self.state_0,
                self.state_1,
                self.challenge_counter
            )
        );
        self.challenge_counter += 1;
        challenge = PairingsBn254.Fr({value: uint256(query) & FR_MASK});
    }
}

pragma solidity >=0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0


import "./libraries/TranscriptLibrary.sol";

contract Plonk4VerifierWithAccessToDNext {
    uint256 constant r_mod =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    using PairingsBn254 for PairingsBn254.G1Point;
    using PairingsBn254 for PairingsBn254.G2Point;
    using PairingsBn254 for PairingsBn254.Fr;

    using TranscriptLibrary for TranscriptLibrary.Transcript;

    uint256 constant ZERO = 0;
    uint256 constant ONE = 1;
    uint256 constant TWO = 2;
    uint256 constant THREE = 3;
    uint256 constant FOUR = 4;

    uint256 constant STATE_WIDTH = 4;
    uint256 constant NUM_DIFFERENT_GATES = 2;
    uint256 constant NUM_SETUP_POLYS_FOR_MAIN_GATE = 7;
    uint256 constant NUM_SETUP_POLYS_RANGE_CHECK_GATE = 0;
    uint256 constant ACCESSIBLE_STATE_POLYS_ON_NEXT_STEP = 1;
    uint256 constant NUM_GATE_SELECTORS_OPENED_EXPLICITLY = 1;

    uint256 constant RECURSIVE_CIRCUIT_INPUT_COMMITMENT_MASK =
        0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant LIMB_WIDTH = 68;

    struct VerificationKey {
        uint256 domain_size;
        uint256 num_inputs;
        PairingsBn254.Fr omega;
        PairingsBn254.G1Point[NUM_SETUP_POLYS_FOR_MAIN_GATE +
            NUM_SETUP_POLYS_RANGE_CHECK_GATE] gate_setup_commitments;
        PairingsBn254.G1Point[NUM_DIFFERENT_GATES] gate_selector_commitments;
        PairingsBn254.G1Point[STATE_WIDTH] copy_permutation_commitments;
        PairingsBn254.Fr[STATE_WIDTH - 1] copy_permutation_non_residues;
        PairingsBn254.G2Point g2_x;
    }

    struct Proof {
        uint256[] input_values;
        PairingsBn254.G1Point[STATE_WIDTH] wire_commitments;
        PairingsBn254.G1Point copy_permutation_grand_product_commitment;
        PairingsBn254.G1Point[STATE_WIDTH] quotient_poly_commitments;
        PairingsBn254.Fr[STATE_WIDTH] wire_values_at_z;
        PairingsBn254.Fr[ACCESSIBLE_STATE_POLYS_ON_NEXT_STEP] wire_values_at_z_omega;
        PairingsBn254.Fr[NUM_GATE_SELECTORS_OPENED_EXPLICITLY] gate_selector_values_at_z;
        PairingsBn254.Fr copy_grand_product_at_z_omega;
        PairingsBn254.Fr quotient_polynomial_at_z;
        PairingsBn254.Fr linearization_polynomial_at_z;
        PairingsBn254.Fr[STATE_WIDTH - 1] permutation_polynomials_at_z;
        PairingsBn254.G1Point opening_at_z_proof;
        PairingsBn254.G1Point opening_at_z_omega_proof;
    }

    struct PartialVerifierState {
        PairingsBn254.Fr alpha;
        PairingsBn254.Fr beta;
        PairingsBn254.Fr gamma;
        PairingsBn254.Fr v;
        PairingsBn254.Fr u;
        PairingsBn254.Fr z;
        PairingsBn254.Fr[] cached_lagrange_evals;
    }

    function evaluate_lagrange_poly_out_of_domain(
        uint256 poly_num,
        uint256 domain_size,
        PairingsBn254.Fr memory omega,
        PairingsBn254.Fr memory at
    ) internal view returns (PairingsBn254.Fr memory res) {
        require(poly_num < domain_size, "poly_num >= domain_size");
        PairingsBn254.Fr memory one = PairingsBn254.new_fr(1);
        PairingsBn254.Fr memory omega_power = omega.pow(poly_num);
        res = at.pow(domain_size);
        res.sub_assign(one);
        require(res.value != 0, "res.value is zero"); // Vanishing polynomial can not be zero at point `at`
        res.mul_assign(omega_power);

        PairingsBn254.Fr memory den = PairingsBn254.copy(at);
        den.sub_assign(omega_power);
        den.mul_assign(PairingsBn254.new_fr(domain_size));

        den = den.inverse();

        res.mul_assign(den);
    }

    function batch_evaluate_lagrange_poly_out_of_domain(
        uint256[] memory poly_nums,
        uint256 domain_size,
        PairingsBn254.Fr memory omega,
        PairingsBn254.Fr memory at
    ) internal view returns (PairingsBn254.Fr[] memory res) {
        PairingsBn254.Fr memory one = PairingsBn254.new_fr(1);
        PairingsBn254.Fr memory tmp_1 = PairingsBn254.new_fr(0);
        PairingsBn254.Fr memory tmp_2 = PairingsBn254.new_fr(domain_size);
        PairingsBn254.Fr memory vanishing_at_z = at.pow(domain_size);
        vanishing_at_z.sub_assign(one);
        // we can not have random point z be in domain
        require(vanishing_at_z.value != 0, "vanishing_at_z.value is zero");
        PairingsBn254.Fr[] memory nums = new PairingsBn254.Fr[](
            poly_nums.length
        );
        PairingsBn254.Fr[] memory dens = new PairingsBn254.Fr[](
            poly_nums.length
        );
        // numerators in a form omega^i * (z^n - 1)
        // denoms in a form (z - omega^i) * N
        for (uint256 i = 0; i < poly_nums.length; i++) {
            tmp_1 = omega.pow(poly_nums[i]); // power of omega
            nums[i].assign(vanishing_at_z);
            nums[i].mul_assign(tmp_1);

            dens[i].assign(at); // (X - omega^i) * N
            dens[i].sub_assign(tmp_1);
            dens[i].mul_assign(tmp_2); // mul by domain size
        }

        PairingsBn254.Fr[] memory partial_products = new PairingsBn254.Fr[](
            poly_nums.length
        );
        partial_products[0].assign(PairingsBn254.new_fr(1));
        for (uint256 i = 1; i < dens.length; i++) {
            partial_products[i].assign(dens[i - 1]);
            partial_products[i].mul_assign(partial_products[i - 1]);
        }

        tmp_2.assign(partial_products[partial_products.length - 1]);
        tmp_2.mul_assign(dens[dens.length - 1]);
        tmp_2 = tmp_2.inverse(); // tmp_2 contains a^-1 * b^-1 (with! the last one)

        for (uint256 i = dens.length - 1; i < dens.length; i--) {
            tmp_1.assign(tmp_2); // all inversed
            tmp_1.mul_assign(partial_products[i]); // clear lowest terms
            tmp_2.mul_assign(dens[i]);
            dens[i].assign(tmp_1);
            if (i == 0) {
                break;
            }
        }

        for (uint256 i = 0; i < nums.length; i++) {
            nums[i].mul_assign(dens[i]);
        }

        return nums;
    }

    function evaluate_vanishing(
        uint256 domain_size,
        PairingsBn254.Fr memory at
    ) internal view returns (PairingsBn254.Fr memory res) {
        res = at.pow(domain_size);
        res.sub_assign(PairingsBn254.new_fr(1));
    }

    function verify_at_z(
        PartialVerifierState memory state,
        Proof memory proof,
        VerificationKey memory vk
    ) internal view returns (bool) {
        PairingsBn254.Fr memory lhs = evaluate_vanishing(
            vk.domain_size,
            state.z
        );
        require(lhs.value != 0, "lhs.value is zero"); // we can not check a polynomial relationship if point `z` is in the domain
        lhs.mul_assign(proof.quotient_polynomial_at_z);

        PairingsBn254.Fr memory quotient_challenge = PairingsBn254.new_fr(1);
        PairingsBn254.Fr memory rhs = PairingsBn254.copy(
            proof.linearization_polynomial_at_z
        );

        // public inputs
        PairingsBn254.Fr memory tmp = PairingsBn254.new_fr(0);
        PairingsBn254.Fr memory inputs_term = PairingsBn254.new_fr(0);
        for (uint256 i = 0; i < proof.input_values.length; i++) {
            tmp.assign(state.cached_lagrange_evals[i]);
            tmp.mul_assign(PairingsBn254.new_fr(proof.input_values[i]));
            inputs_term.add_assign(tmp);
        }

        inputs_term.mul_assign(proof.gate_selector_values_at_z[0]);
        rhs.add_assign(inputs_term);

        // now we need 5th power
        quotient_challenge.mul_assign(state.alpha);
        quotient_challenge.mul_assign(state.alpha);
        quotient_challenge.mul_assign(state.alpha);
        quotient_challenge.mul_assign(state.alpha);
        quotient_challenge.mul_assign(state.alpha);

        PairingsBn254.Fr memory z_part = PairingsBn254.copy(
            proof.copy_grand_product_at_z_omega
        );
        for (
            uint256 i = 0;
            i < proof.permutation_polynomials_at_z.length;
            i++
        ) {
            tmp.assign(proof.permutation_polynomials_at_z[i]);
            tmp.mul_assign(state.beta);
            tmp.add_assign(state.gamma);
            tmp.add_assign(proof.wire_values_at_z[i]);

            z_part.mul_assign(tmp);
        }

        tmp.assign(state.gamma);
        // we need a wire value of the last polynomial in enumeration
        tmp.add_assign(proof.wire_values_at_z[STATE_WIDTH - 1]);

        z_part.mul_assign(tmp);
        z_part.mul_assign(quotient_challenge);

        rhs.sub_assign(z_part);

        quotient_challenge.mul_assign(state.alpha);

        tmp.assign(state.cached_lagrange_evals[0]);
        tmp.mul_assign(quotient_challenge);

        rhs.sub_assign(tmp);

        return lhs.value == rhs.value;
    }

    function add_contribution_from_range_constraint_gates(
        PartialVerifierState memory state,
        Proof memory proof,
        PairingsBn254.Fr memory current_alpha
    ) internal pure returns (PairingsBn254.Fr memory res) {
        // now add contribution from range constraint gate
        // we multiply selector commitment by all the factors (alpha*(c - 4d)(c - 4d - 1)(..-2)(..-3) + alpha^2 * (4b - c)()()() + {} + {})

        PairingsBn254.Fr memory one_fr = PairingsBn254.new_fr(ONE);
        PairingsBn254.Fr memory two_fr = PairingsBn254.new_fr(TWO);
        PairingsBn254.Fr memory three_fr = PairingsBn254.new_fr(THREE);
        PairingsBn254.Fr memory four_fr = PairingsBn254.new_fr(FOUR);

        res = PairingsBn254.new_fr(0);
        PairingsBn254.Fr memory t0 = PairingsBn254.new_fr(0);
        PairingsBn254.Fr memory t1 = PairingsBn254.new_fr(0);
        PairingsBn254.Fr memory t2 = PairingsBn254.new_fr(0);

        for (uint256 i = 0; i < 3; i++) {
            current_alpha.mul_assign(state.alpha);

            // high - 4*low

            // this is 4*low
            t0 = PairingsBn254.copy(proof.wire_values_at_z[3 - i]);
            t0.mul_assign(four_fr);

            // high
            t1 = PairingsBn254.copy(proof.wire_values_at_z[2 - i]);
            t1.sub_assign(t0);

            // t0 is now t1 - {0,1,2,3}

            // first unroll manually for -0;
            t2 = PairingsBn254.copy(t1);

            // -1
            t0 = PairingsBn254.copy(t1);
            t0.sub_assign(one_fr);
            t2.mul_assign(t0);

            // -2
            t0 = PairingsBn254.copy(t1);
            t0.sub_assign(two_fr);
            t2.mul_assign(t0);

            // -3
            t0 = PairingsBn254.copy(t1);
            t0.sub_assign(three_fr);
            t2.mul_assign(t0);

            t2.mul_assign(current_alpha);

            res.add_assign(t2);
        }

        // now also d_next - 4a

        current_alpha.mul_assign(state.alpha);

        // high - 4*low

        // this is 4*low
        t0 = PairingsBn254.copy(proof.wire_values_at_z[0]);
        t0.mul_assign(four_fr);

        // high
        t1 = PairingsBn254.copy(proof.wire_values_at_z_omega[0]);
        t1.sub_assign(t0);

        // t0 is now t1 - {0,1,2,3}

        // first unroll manually for -0;
        t2 = PairingsBn254.copy(t1);

        // -1
        t0 = PairingsBn254.copy(t1);
        t0.sub_assign(one_fr);
        t2.mul_assign(t0);

        // -2
        t0 = PairingsBn254.copy(t1);
        t0.sub_assign(two_fr);
        t2.mul_assign(t0);

        // -3
        t0 = PairingsBn254.copy(t1);
        t0.sub_assign(three_fr);
        t2.mul_assign(t0);

        t2.mul_assign(current_alpha);

        res.add_assign(t2);

        return res;
    }

    function reconstruct_linearization_commitment(
        PartialVerifierState memory state,
        Proof memory proof,
        VerificationKey memory vk
    ) internal view returns (PairingsBn254.G1Point memory res) {
        // we compute what power of v is used as a delinearization factor in batch opening of
        // commitments. Let's label W(x) = 1 / (x - z) *
        // [
        // t_0(x) + z^n * t_1(x) + z^2n * t_2(x) + z^3n * t_3(x) - t(z)
        // + v (r(x) - r(z))
        // + v^{2..5} * (witness(x) - witness(z))
        // + v^{6} * (selector(x) - selector(z))
        // + v^{7..9} * (permutation(x) - permutation(z))
        // ]
        // W'(x) = 1 / (x - z*omega) *
        // [
        // + v^10 (z(x) - z(z*omega)) <- we need this power
        // + v^11 * (d(x) - d(z*omega))
        // ]
        //

        // we reconstruct linearization polynomial virtual selector
        // for that purpose we first linearize over main gate (over all it's selectors)
        // and multiply them by value(!) of the corresponding main gate selector
        res = PairingsBn254.copy_g1(vk.gate_setup_commitments[STATE_WIDTH + 1]); // index of q_const(x)

        PairingsBn254.G1Point memory tmp_g1 = PairingsBn254.P1();
        PairingsBn254.Fr memory tmp_fr = PairingsBn254.new_fr(0);

        // addition gates
        for (uint256 i = 0; i < STATE_WIDTH; i++) {
            tmp_g1 = vk.gate_setup_commitments[i].point_mul(
                proof.wire_values_at_z[i]
            );
            res.point_add_assign(tmp_g1);
        }

        // multiplication gate
        tmp_fr.assign(proof.wire_values_at_z[0]);
        tmp_fr.mul_assign(proof.wire_values_at_z[1]);
        tmp_g1 = vk.gate_setup_commitments[STATE_WIDTH].point_mul(tmp_fr);
        res.point_add_assign(tmp_g1);

        // d_next
        tmp_g1 = vk.gate_setup_commitments[STATE_WIDTH + 2].point_mul(
            proof.wire_values_at_z_omega[0]
        ); // index of q_d_next(x)
        res.point_add_assign(tmp_g1);

        // multiply by main gate selector(z)
        res.point_mul_assign(proof.gate_selector_values_at_z[0]); // these is only one explicitly opened selector

        PairingsBn254.Fr memory current_alpha = PairingsBn254.new_fr(ONE);

        // calculate scalar contribution from the range check gate
        tmp_fr = add_contribution_from_range_constraint_gates(
            state,
            proof,
            current_alpha
        );
        tmp_g1 = vk.gate_selector_commitments[1].point_mul(tmp_fr); // selector commitment for range constraint gate * scalar
        res.point_add_assign(tmp_g1);

        // proceed as normal to copy permutation
        current_alpha.mul_assign(state.alpha); // alpha^5

        PairingsBn254.Fr memory alpha_for_grand_product = PairingsBn254.copy(
            current_alpha
        );

        // z * non_res * beta + gamma + a
        PairingsBn254.Fr memory grand_product_part_at_z = PairingsBn254.copy(
            state.z
        );
        grand_product_part_at_z.mul_assign(state.beta);
        grand_product_part_at_z.add_assign(proof.wire_values_at_z[0]);
        grand_product_part_at_z.add_assign(state.gamma);
        for (uint256 i = 0; i < vk.copy_permutation_non_residues.length; i++) {
            tmp_fr.assign(state.z);
            tmp_fr.mul_assign(vk.copy_permutation_non_residues[i]);
            tmp_fr.mul_assign(state.beta);
            tmp_fr.add_assign(state.gamma);
            tmp_fr.add_assign(proof.wire_values_at_z[i + 1]);

            grand_product_part_at_z.mul_assign(tmp_fr);
        }

        grand_product_part_at_z.mul_assign(alpha_for_grand_product);

        // alpha^n & L_{0}(z), and we bump current_alpha
        current_alpha.mul_assign(state.alpha);

        tmp_fr.assign(state.cached_lagrange_evals[0]);
        tmp_fr.mul_assign(current_alpha);

        grand_product_part_at_z.add_assign(tmp_fr);

        // prefactor for grand_product(x) is complete

        // add to the linearization a part from the term
        // - (a(z) + beta*perm_a + gamma)*()*()*z(z*omega) * beta * perm_d(X)
        PairingsBn254.Fr memory last_permutation_part_at_z = PairingsBn254
            .new_fr(1);
        for (
            uint256 i = 0;
            i < proof.permutation_polynomials_at_z.length;
            i++
        ) {
            tmp_fr.assign(state.beta);
            tmp_fr.mul_assign(proof.permutation_polynomials_at_z[i]);
            tmp_fr.add_assign(state.gamma);
            tmp_fr.add_assign(proof.wire_values_at_z[i]);

            last_permutation_part_at_z.mul_assign(tmp_fr);
        }

        last_permutation_part_at_z.mul_assign(state.beta);
        last_permutation_part_at_z.mul_assign(
            proof.copy_grand_product_at_z_omega
        );
        last_permutation_part_at_z.mul_assign(alpha_for_grand_product); // we multiply by the power of alpha from the argument

        // actually multiply prefactors by z(x) and perm_d(x) and combine them
        tmp_g1 = proof.copy_permutation_grand_product_commitment.point_mul(
            grand_product_part_at_z
        );
        tmp_g1.point_sub_assign(
            vk.copy_permutation_commitments[STATE_WIDTH - 1].point_mul(
                last_permutation_part_at_z
            )
        );

        res.point_add_assign(tmp_g1);
        // multiply them by v immedately as linearization has a factor of v^1
        res.point_mul_assign(state.v);
        // res now contains contribution from the gates linearization and
        // copy permutation part

        // now we need to add a part that is the rest
        // for z(x*omega):
        // - (a(z) + beta*perm_a + gamma)*()*()*(d(z) + gamma) * z(x*omega)
    }

    function aggregate_commitments(
        PartialVerifierState memory state,
        Proof memory proof,
        VerificationKey memory vk
    ) internal view returns (PairingsBn254.G1Point[2] memory res) {
        PairingsBn254.G1Point memory d = reconstruct_linearization_commitment(
            state,
            proof,
            vk
        );

        PairingsBn254.Fr memory z_in_domain_size = state.z.pow(vk.domain_size);

        PairingsBn254.G1Point memory tmp_g1 = PairingsBn254.P1();

        PairingsBn254.Fr memory aggregation_challenge = PairingsBn254.new_fr(1);

        PairingsBn254.G1Point memory commitment_aggregation = PairingsBn254
            .copy_g1(proof.quotient_poly_commitments[0]);
        PairingsBn254.Fr memory tmp_fr = PairingsBn254.new_fr(1);
        for (uint256 i = 1; i < proof.quotient_poly_commitments.length; i++) {
            tmp_fr.mul_assign(z_in_domain_size);
            tmp_g1 = proof.quotient_poly_commitments[i].point_mul(tmp_fr);
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        aggregation_challenge.mul_assign(state.v);
        commitment_aggregation.point_add_assign(d);

        for (uint256 i = 0; i < proof.wire_commitments.length; i++) {
            aggregation_challenge.mul_assign(state.v);
            tmp_g1 = proof.wire_commitments[i].point_mul(aggregation_challenge);
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        for (uint256 i = 0; i < NUM_GATE_SELECTORS_OPENED_EXPLICITLY; i++) {
            aggregation_challenge.mul_assign(state.v);
            tmp_g1 = vk.gate_selector_commitments[0].point_mul(
                aggregation_challenge
            );
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        for (
            uint256 i = 0;
            i < vk.copy_permutation_commitments.length - 1;
            i++
        ) {
            aggregation_challenge.mul_assign(state.v);
            tmp_g1 = vk.copy_permutation_commitments[i].point_mul(
                aggregation_challenge
            );
            commitment_aggregation.point_add_assign(tmp_g1);
        }

        aggregation_challenge.mul_assign(state.v);
        // now do prefactor for grand_product(x*omega)
        tmp_fr.assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        commitment_aggregation.point_add_assign(
            proof.copy_permutation_grand_product_commitment.point_mul(tmp_fr)
        );

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        tmp_g1 = proof.wire_commitments[STATE_WIDTH - 1].point_mul(tmp_fr);
        commitment_aggregation.point_add_assign(tmp_g1);

        // collect opening values
        aggregation_challenge = PairingsBn254.new_fr(1);

        PairingsBn254.Fr memory aggregated_value = PairingsBn254.copy(
            proof.quotient_polynomial_at_z
        );

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(proof.linearization_polynomial_at_z);
        tmp_fr.mul_assign(aggregation_challenge);
        aggregated_value.add_assign(tmp_fr);

        for (uint256 i = 0; i < proof.wire_values_at_z.length; i++) {
            aggregation_challenge.mul_assign(state.v);

            tmp_fr.assign(proof.wire_values_at_z[i]);
            tmp_fr.mul_assign(aggregation_challenge);
            aggregated_value.add_assign(tmp_fr);
        }

        for (uint256 i = 0; i < proof.gate_selector_values_at_z.length; i++) {
            aggregation_challenge.mul_assign(state.v);
            tmp_fr.assign(proof.gate_selector_values_at_z[i]);
            tmp_fr.mul_assign(aggregation_challenge);
            aggregated_value.add_assign(tmp_fr);
        }

        for (
            uint256 i = 0;
            i < proof.permutation_polynomials_at_z.length;
            i++
        ) {
            aggregation_challenge.mul_assign(state.v);

            tmp_fr.assign(proof.permutation_polynomials_at_z[i]);
            tmp_fr.mul_assign(aggregation_challenge);
            aggregated_value.add_assign(tmp_fr);
        }

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(proof.copy_grand_product_at_z_omega);
        tmp_fr.mul_assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        aggregated_value.add_assign(tmp_fr);

        aggregation_challenge.mul_assign(state.v);

        tmp_fr.assign(proof.wire_values_at_z_omega[0]);
        tmp_fr.mul_assign(aggregation_challenge);
        tmp_fr.mul_assign(state.u);
        aggregated_value.add_assign(tmp_fr);

        commitment_aggregation.point_sub_assign(
            PairingsBn254.P1().point_mul(aggregated_value)
        );

        PairingsBn254.G1Point
            memory pair_with_generator = commitment_aggregation;
        pair_with_generator.point_add_assign(
            proof.opening_at_z_proof.point_mul(state.z)
        );

        tmp_fr.assign(state.z);
        tmp_fr.mul_assign(vk.omega);
        tmp_fr.mul_assign(state.u);
        pair_with_generator.point_add_assign(
            proof.opening_at_z_omega_proof.point_mul(tmp_fr)
        );

        PairingsBn254.G1Point memory pair_with_x = proof
            .opening_at_z_omega_proof
            .point_mul(state.u);
        pair_with_x.point_add_assign(proof.opening_at_z_proof);
        pair_with_x.negate();

        res[0] = pair_with_generator;
        res[1] = pair_with_x;

        return res;
    }

    function verify_initial(
        PartialVerifierState memory state,
        Proof memory proof,
        VerificationKey memory vk
    ) internal view returns (bool) {
        require(
            proof.input_values.length == vk.num_inputs,
            "length not the same"
        );
        require(vk.num_inputs >= 1, "vk.num_inputs not >= 1");
        TranscriptLibrary.Transcript memory transcript = TranscriptLibrary
            .new_transcript();
        for (uint256 i = 0; i < vk.num_inputs; i++) {
            transcript.update_with_u256(proof.input_values[i]);
        }

        for (uint256 i = 0; i < proof.wire_commitments.length; i++) {
            transcript.update_with_g1(proof.wire_commitments[i]);
        }

        state.beta = transcript.get_challenge();
        state.gamma = transcript.get_challenge();

        transcript.update_with_g1(
            proof.copy_permutation_grand_product_commitment
        );
        state.alpha = transcript.get_challenge();

        for (uint256 i = 0; i < proof.quotient_poly_commitments.length; i++) {
            transcript.update_with_g1(proof.quotient_poly_commitments[i]);
        }

        state.z = transcript.get_challenge();

        uint256[] memory lagrange_poly_numbers = new uint256[](vk.num_inputs);
        for (uint256 i = 0; i < lagrange_poly_numbers.length; i++) {
            lagrange_poly_numbers[i] = i;
        }

        state
            .cached_lagrange_evals = batch_evaluate_lagrange_poly_out_of_domain(
            lagrange_poly_numbers,
            vk.domain_size,
            vk.omega,
            state.z
        );

        bool valid = verify_at_z(state, proof, vk);

        if (valid == false) {
            return false;
        }

        transcript.update_with_fr(proof.quotient_polynomial_at_z);

        for (uint256 i = 0; i < proof.wire_values_at_z.length; i++) {
            transcript.update_with_fr(proof.wire_values_at_z[i]);
        }

        for (uint256 i = 0; i < proof.wire_values_at_z_omega.length; i++) {
            transcript.update_with_fr(proof.wire_values_at_z_omega[i]);
        }

        transcript.update_with_fr(proof.gate_selector_values_at_z[0]);

        for (
            uint256 i = 0;
            i < proof.permutation_polynomials_at_z.length;
            i++
        ) {
            transcript.update_with_fr(proof.permutation_polynomials_at_z[i]);
        }

        transcript.update_with_fr(proof.copy_grand_product_at_z_omega);
        transcript.update_with_fr(proof.linearization_polynomial_at_z);

        state.v = transcript.get_challenge();
        transcript.update_with_g1(proof.opening_at_z_proof);
        transcript.update_with_g1(proof.opening_at_z_omega_proof);
        state.u = transcript.get_challenge();

        return true;
    }

    // This verifier is for a PLONK with a state width 4
    // and main gate equation
    // q_a(X) * a(X) +
    // q_b(X) * b(X) +
    // q_c(X) * c(X) +
    // q_d(X) * d(X) +
    // q_m(X) * a(X) * b(X) +
    // q_constants(X)+
    // q_d_next(X) * d(X*omega)
    // where q_{}(X) are selectors a, b, c, d - state (witness) polynomials
    // q_d_next(X) "peeks" into the next row of the trace, so it takes
    // the same d(X) polynomial, but shifted

    function aggregate_for_verification(
        Proof memory proof,
        VerificationKey memory vk
    ) internal view returns (bool valid, PairingsBn254.G1Point[2] memory part) {
        PartialVerifierState memory state;

        valid = verify_initial(state, proof, vk);

        if (valid == false) {
            return (valid, part);
        }

        part = aggregate_commitments(state, proof, vk);

        (valid, part);
    }

    function verify(
        Proof memory proof,
        VerificationKey memory vk
    ) internal view returns (bool) {
        (
            bool valid,
            PairingsBn254.G1Point[2] memory recursive_proof_part
        ) = aggregate_for_verification(proof, vk);
        if (valid == false) {
            return false;
        }

        valid = PairingsBn254.pairingProd2(
            recursive_proof_part[0],
            PairingsBn254.P2(),
            recursive_proof_part[1],
            vk.g2_x
        );

        return valid;
    }

    function verify_recursive(
        Proof memory proof,
        VerificationKey memory vk,
        uint256 recursive_vks_root,
        uint8 max_valid_index,
        uint8[] memory recursive_vks_indexes,
        uint256[] memory individual_vks_inputs,
        uint256[16] memory subproofs_limbs
    ) internal view returns (bool) {
        (
            uint256 recursive_input,
            PairingsBn254.G1Point[2] memory aggregated_g1s
        ) = reconstruct_recursive_public_input(
                recursive_vks_root,
                max_valid_index,
                recursive_vks_indexes,
                individual_vks_inputs,
                subproofs_limbs
            );

        require(
            recursive_input == proof.input_values[0],
            "recursive_input != proof.input_values[0]"
        );

        (
            bool valid,
            PairingsBn254.G1Point[2] memory recursive_proof_part
        ) = aggregate_for_verification(proof, vk);
        if (valid == false) {
            return false;
        }

        // aggregated_g1s = inner
        // recursive_proof_part = outer
        PairingsBn254.G1Point[2] memory combined = combine_inner_and_outer(
            aggregated_g1s,
            recursive_proof_part
        );

        valid = PairingsBn254.pairingProd2(
            combined[0],
            PairingsBn254.P2(),
            combined[1],
            vk.g2_x
        );

        return valid;
    }

    function combine_inner_and_outer(
        PairingsBn254.G1Point[2] memory inner,
        PairingsBn254.G1Point[2] memory outer
    ) internal view returns (PairingsBn254.G1Point[2] memory result) {
        // reuse the transcript primitive
        TranscriptLibrary.Transcript memory transcript = TranscriptLibrary
            .new_transcript();
        transcript.update_with_g1(inner[0]);
        transcript.update_with_g1(inner[1]);
        transcript.update_with_g1(outer[0]);
        transcript.update_with_g1(outer[1]);
        PairingsBn254.Fr memory challenge = transcript.get_challenge();
        // 1 * inner + challenge * outer
        result[0] = PairingsBn254.copy_g1(inner[0]);
        result[1] = PairingsBn254.copy_g1(inner[1]);
        PairingsBn254.G1Point memory tmp = outer[0].point_mul(challenge);
        result[0].point_add_assign(tmp);
        tmp = outer[1].point_mul(challenge);
        result[1].point_add_assign(tmp);

        return result;
    }

    function reconstruct_recursive_public_input(
        uint256 recursive_vks_root,
        uint8 max_valid_index,
        uint8[] memory recursive_vks_indexes,
        uint256[] memory individual_vks_inputs,
        uint256[16] memory subproofs_aggregated
    )
        internal
        pure
        returns (
            uint256 recursive_input,
            PairingsBn254.G1Point[2] memory reconstructed_g1s
        )
    {
        require(
            recursive_vks_indexes.length == individual_vks_inputs.length,
            "vks indexes length not the same"
        );
        bytes memory concatenated = abi.encodePacked(recursive_vks_root);
        uint8 index;
        for (uint256 i = 0; i < recursive_vks_indexes.length; i++) {
            index = recursive_vks_indexes[i];
            require(index <= max_valid_index, "index > max_valid_index");
            concatenated = abi.encodePacked(concatenated, index);
        }
        uint256 input;
        for (uint256 i = 0; i < recursive_vks_indexes.length; i++) {
            input = individual_vks_inputs[i];
            require(input < r_mod, "input >= r_mod");
            concatenated = abi.encodePacked(concatenated, input);
        }

        concatenated = abi.encodePacked(concatenated, subproofs_aggregated);

        bytes32 commitment = sha256(concatenated);
        recursive_input =
            uint256(commitment) &
            RECURSIVE_CIRCUIT_INPUT_COMMITMENT_MASK;

        reconstructed_g1s[0] = PairingsBn254.new_g1_checked(
            subproofs_aggregated[0] +
                (subproofs_aggregated[1] << LIMB_WIDTH) +
                (subproofs_aggregated[2] << (2 * LIMB_WIDTH)) +
                (subproofs_aggregated[3] << (3 * LIMB_WIDTH)),
            subproofs_aggregated[4] +
                (subproofs_aggregated[5] << LIMB_WIDTH) +
                (subproofs_aggregated[6] << (2 * LIMB_WIDTH)) +
                (subproofs_aggregated[7] << (3 * LIMB_WIDTH))
        );

        reconstructed_g1s[1] = PairingsBn254.new_g1_checked(
            subproofs_aggregated[8] +
                (subproofs_aggregated[9] << LIMB_WIDTH) +
                (subproofs_aggregated[10] << (2 * LIMB_WIDTH)) +
                (subproofs_aggregated[11] << (3 * LIMB_WIDTH)),
            subproofs_aggregated[12] +
                (subproofs_aggregated[13] << LIMB_WIDTH) +
                (subproofs_aggregated[14] << (2 * LIMB_WIDTH)) +
                (subproofs_aggregated[15] << (3 * LIMB_WIDTH))
        );

        return (recursive_input, reconstructed_g1s);
    }
}

pragma solidity >=0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0


import "./Plonk4VerifierWithAccessToDNext.sol";

contract VerifierWithDeserialize is Plonk4VerifierWithAccessToDNext {
    uint256 constant SERIALIZED_PROOF_LENGTH = 34;

    function deserialize_proof(
        uint256[] memory public_inputs,
        uint256[] memory serialized_proof
    ) internal pure returns (Proof memory proof) {
        require(
            serialized_proof.length == SERIALIZED_PROOF_LENGTH,
            "deserialize_proof length error"
        );
        proof.input_values = new uint256[](public_inputs.length);
        for (uint256 i = 0; i < public_inputs.length; i++) {
            proof.input_values[i] = public_inputs[i];
        }

        uint256 j = 0;
        for (uint256 i = 0; i < STATE_WIDTH; i++) {
            proof.wire_commitments[i] = PairingsBn254.new_g1_checked(
                serialized_proof[j],
                serialized_proof[j + 1]
            );

            j += 2;
        }

        proof.copy_permutation_grand_product_commitment = PairingsBn254
            .new_g1_checked(serialized_proof[j], serialized_proof[j + 1]);
        j += 2;

        for (uint256 i = 0; i < STATE_WIDTH; i++) {
            proof.quotient_poly_commitments[i] = PairingsBn254.new_g1_checked(
                serialized_proof[j],
                serialized_proof[j + 1]
            );

            j += 2;
        }

        for (uint256 i = 0; i < STATE_WIDTH; i++) {
            proof.wire_values_at_z[i] = PairingsBn254.new_fr(
                serialized_proof[j]
            );

            j += 1;
        }

        for (uint256 i = 0; i < proof.wire_values_at_z_omega.length; i++) {
            proof.wire_values_at_z_omega[i] = PairingsBn254.new_fr(
                serialized_proof[j]
            );

            j += 1;
        }

        for (uint256 i = 0; i < proof.gate_selector_values_at_z.length; i++) {
            proof.gate_selector_values_at_z[i] = PairingsBn254.new_fr(
                serialized_proof[j]
            );

            j += 1;
        }

        for (
            uint256 i = 0;
            i < proof.permutation_polynomials_at_z.length;
            i++
        ) {
            proof.permutation_polynomials_at_z[i] = PairingsBn254.new_fr(
                serialized_proof[j]
            );

            j += 1;
        }

        proof.copy_grand_product_at_z_omega = PairingsBn254.new_fr(
            serialized_proof[j]
        );

        j += 1;

        proof.quotient_polynomial_at_z = PairingsBn254.new_fr(
            serialized_proof[j]
        );

        j += 1;

        proof.linearization_polynomial_at_z = PairingsBn254.new_fr(
            serialized_proof[j]
        );

        j += 1;

        proof.opening_at_z_proof = PairingsBn254.new_g1_checked(
            serialized_proof[j],
            serialized_proof[j + 1]
        );
        j += 2;

        proof.opening_at_z_omega_proof = PairingsBn254.new_g1_checked(
            serialized_proof[j],
            serialized_proof[j + 1]
        );
    }

    function verify_serialized_proof(
        uint256[] memory public_inputs,
        uint256[] memory serialized_proof,
        VerificationKey memory vk
    ) public view returns (bool) {
        require(
            vk.num_inputs == public_inputs.length,
            "verify_serialized_proof input error"
        );

        Proof memory proof = deserialize_proof(public_inputs, serialized_proof);

        bool valid = verify(proof, vk);

        return valid;
    }

    function verify_serialized_proof_with_recursion(
        uint256[] memory public_inputs,
        uint256[] memory serialized_proof,
        uint256 recursive_vks_root,
        uint8 max_valid_index,
        uint8[] memory recursive_vks_indexes,
        uint256[] memory individual_vks_inputs,
        uint256[16] memory subproofs_limbs,
        VerificationKey memory vk
    ) public view returns (bool) {
        require(
            vk.num_inputs == public_inputs.length,
            "vefify proof input length error"
        );

        Proof memory proof = deserialize_proof(public_inputs, serialized_proof);

        bool valid = verify_recursive(
            proof,
            vk,
            recursive_vks_root,
            max_valid_index,
            recursive_vks_indexes,
            individual_vks_inputs,
            subproofs_limbs
        );

        return valid;
    }
}

pragma solidity >= 0.8.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT OR Apache-2.0




import "./plonk/KeysWithPlonkVerifier.sol";
import "../Config.sol";

// Hardcoded constants to avoid accessing store
contract Verifier is KeysWithPlonkVerifier, Config {


    function initialize() external {}

    function verifyAggregatedBlockProof(
        uint256[16] memory _subproofs_limbs,
        uint256[] memory _recursiveInput,
        uint256[] memory _proof,
        uint8[] memory _vkIndexes,
        uint256[] memory _individual_vks_inputs
    ) external view returns (bool) {
        for (uint256 i = 0; i < _individual_vks_inputs.length; ++i) {
            uint256 commitment = _individual_vks_inputs[i];
            _individual_vks_inputs[i] = commitment & INPUT_MASK;
        }
        VerificationKey memory vk = getVkAggregated(uint32(_vkIndexes.length));

        bool res =  verify_serialized_proof_with_recursion(
            _recursiveInput,
            _proof,
            VK_TREE_ROOT,
            VK_MAX_INDEX,
            _vkIndexes,
            _individual_vks_inputs,
            _subproofs_limbs,
            vk
        );

        return res;
    }
}

pragma solidity >= 0.8.0;

// SPDX-License-Identifier: Apache-2.0.


import "./Storage.sol";

abstract contract Withdrawals is Storage {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event LogWithdrawalPerformed(
        uint256 ownerKey,
        uint256 amount,
        address recipient
    );

    function withdrawERC20(IERC20Upgradeable token, uint256 ownerKey, address payable recipient) internal {
        require(recipient != address(0), "k");
        uint256 amount = pendingWithdrawals[ownerKey];
        pendingWithdrawals[ownerKey] = 0;

        token.safeTransfer(recipient, amount); 

        emit LogWithdrawalPerformed(
            ownerKey,
            amount,
            recipient
        );
    }

    function withdraw(uint256 ownerKey) external nonReentrant {
        address payable recipient = payable(ethKeys[ownerKey]);
        withdrawERC20(collateralToken, ownerKey, recipient);
    }

    function withdrawTo(
        uint256 ownerKey, address payable recipient)
        external onlyKeyOwner(ownerKey) nonReentrant
    {
        withdrawERC20(collateralToken, ownerKey, recipient);
    }

}
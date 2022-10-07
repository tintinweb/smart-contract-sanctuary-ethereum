/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

// SPDX-License-Identifier: MIT
// File: contracts/ExenoTokenMintable.sol


pragma solidity 0.8.16;

interface ExenoTokenMintable {
    function manager() external view returns(address);
    function mint(address, uint256) external;
    function burn(uint256) external;
}

// File: erc-payable-token/contracts/token/ERC1363/IERC1363Spender.sol



pragma solidity ^0.8.0;

/**
 * @title IERC1363Spender Interface
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Interface for any contract that wants to support approveAndCall
 *  from ERC1363 token contracts as defined in
 *  https://eips.ethereum.org/EIPS/eip-1363
 */
interface IERC1363Spender {
    /**
     * @notice Handle the approval of ERC1363 tokens
     * @dev Any ERC1363 smart contract calls this function on the recipient
     * after an `approve`. This function MAY throw to revert and reject the
     * approval. Return of other than the magic value MUST result in the
     * transaction being reverted.
     * Note: the token contract address is always the message sender.
     * @param sender address The address which called `approveAndCall` function
     * @param amount uint256 The amount of tokens to be spent
     * @param data bytes Additional data with no specified format
     * @return `bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))` unless throwing
     */
    function onApprovalReceived(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);
}

// File: erc-payable-token/contracts/token/ERC1363/IERC1363Receiver.sol



pragma solidity ^0.8.0;

/**
 * @title IERC1363Receiver Interface
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Interface for any contract that wants to support transferAndCall or transferFromAndCall
 *  from ERC1363 token contracts as defined in
 *  https://eips.ethereum.org/EIPS/eip-1363
 */
interface IERC1363Receiver {
    /**
     * @notice Handle the receipt of ERC1363 tokens
     * @dev Any ERC1363 smart contract calls this function on the recipient
     * after a `transfer` or a `transferFrom`. This function MAY throw to revert and reject the
     * transfer. Return of other than the magic value MUST result in the
     * transaction being reverted.
     * Note: the token contract address is always the message sender.
     * @param spender address The address which called `transferAndCall` or `transferFromAndCall` function
     * @param sender address The address which are token transferred from
     * @param amount uint256 The amount of tokens transferred
     * @param data bytes Additional data with no specified format
     * @return `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))` unless throwing
     */
    function onTransferReceived(
        address spender,
        address sender,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165Checker.sol


// OpenZeppelin Contracts (last updated v4.7.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;


/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: @openzeppelin/contracts/utils/cryptography/ECDSA.sol


// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

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
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
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

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: erc-payable-token/contracts/token/ERC1363/IERC1363.sol



pragma solidity ^0.8.0;



/**
 * @title IERC1363 Interface
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Interface for a Payable Token contract as defined in
 *  https://eips.ethereum.org/EIPS/eip-1363
 */
interface IERC1363 is IERC20, IERC165 {
    /**
     * @notice Transfer tokens from `msg.sender` to another address and then call `onTransferReceived` on receiver
     * @param to address The address which you want to transfer to
     * @param amount uint256 The amount of tokens to be transferred
     * @return true unless throwing
     */
    function transferAndCall(address to, uint256 amount) external returns (bool);

    /**
     * @notice Transfer tokens from `msg.sender` to another address and then call `onTransferReceived` on receiver
     * @param to address The address which you want to transfer to
     * @param amount uint256 The amount of tokens to be transferred
     * @param data bytes Additional data with no specified format, sent in call to `to`
     * @return true unless throwing
     */
    function transferAndCall(
        address to,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);

    /**
     * @notice Transfer tokens from one address to another and then call `onTransferReceived` on receiver
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param amount uint256 The amount of tokens to be transferred
     * @return true unless throwing
     */
    function transferFromAndCall(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice Transfer tokens from one address to another and then call `onTransferReceived` on receiver
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param amount uint256 The amount of tokens to be transferred
     * @param data bytes Additional data with no specified format, sent in call to `to`
     * @return true unless throwing
     */
    function transferFromAndCall(
        address from,
        address to,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);

    /**
     * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
     * and then call `onApprovalReceived` on spender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender address The address which will spend the funds
     * @param amount uint256 The amount of tokens to be spent
     */
    function approveAndCall(address spender, uint256 amount) external returns (bool);

    /**
     * @notice Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
     * and then call `onApprovalReceived` on spender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender address The address which will spend the funds
     * @param amount uint256 The amount of tokens to be spent
     * @param data bytes Additional data with no specified format, sent in call to `spender`
     */
    function approveAndCall(
        address spender,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// File: erc-payable-token/contracts/payment/ERC1363Payable.sol



pragma solidity ^0.8.0;







/**
 * @title ERC1363Payable
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev Implementation proposal of a contract that wants to accept ERC1363 payments
 */
contract ERC1363Payable is IERC1363Receiver, IERC1363Spender, ERC165, Context {
    using ERC165Checker for address;

    /**
     * @dev Emitted when `amount` tokens are moved from one account (`sender`) to
     * this by spender (`operator`) using {transferAndCall} or {transferFromAndCall}.
     */
    event TokensReceived(address indexed operator, address indexed sender, uint256 amount, bytes data);

    /**
     * @dev Emitted when the allowance of this for a `sender` is set by
     * a call to {approveAndCall}. `amount` is the new allowance.
     */
    event TokensApproved(address indexed sender, uint256 amount, bytes data);

    // The ERC1363 token accepted
    IERC1363 private _acceptedToken;

    /**
     * @param acceptedToken_ Address of the token being accepted
     */
    constructor(IERC1363 acceptedToken_) {
        require(address(acceptedToken_) != address(0), "ERC1363Payable: acceptedToken is zero address");
        require(acceptedToken_.supportsInterface(type(IERC1363).interfaceId));

        _acceptedToken = acceptedToken_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(IERC1363Receiver).interfaceId ||
            interfaceId == type(IERC1363Spender).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /*
     * @dev Note: remember that the token contract address is always the message sender.
     * @param spender The address which called `transferAndCall` or `transferFromAndCall` function
     * @param sender The address which are token transferred from
     * @param amount The amount of tokens transferred
     * @param data Additional data with no specified format
     */
    function onTransferReceived(
        address spender,
        address sender,
        uint256 amount,
        bytes memory data
    ) public override returns (bytes4) {
        require(_msgSender() == address(_acceptedToken), "ERC1363Payable: acceptedToken is not message sender");

        emit TokensReceived(spender, sender, amount, data);

        _transferReceived(spender, sender, amount, data);

        return IERC1363Receiver.onTransferReceived.selector;
    }

    /*
     * @dev Note: remember that the token contract address is always the message sender.
     * @param sender The address which called `approveAndCall` function
     * @param amount The amount of tokens to be spent
     * @param data Additional data with no specified format
     */
    function onApprovalReceived(
        address sender,
        uint256 amount,
        bytes memory data
    ) public override returns (bytes4) {
        require(_msgSender() == address(_acceptedToken), "ERC1363Payable: acceptedToken is not message sender");

        emit TokensApproved(sender, amount, data);

        _approvalReceived(sender, amount, data);

        return IERC1363Spender.onApprovalReceived.selector;
    }

    /**
     * @dev The ERC1363 token accepted
     */
    function acceptedToken() public view returns (IERC1363) {
        return _acceptedToken;
    }

    /**
     * @dev Called after validating a `onTransferReceived`. Override this method to
     * make your stuffs within your contract.
     * @param spender The address which called `transferAndCall` or `transferFromAndCall` function
     * @param sender The address which are token transferred from
     * @param amount The amount of tokens transferred
     * @param data Additional data with no specified format
     */
    function _transferReceived(
        address spender,
        address sender,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        // optional override
    }

    /**
     * @dev Called after validating a `onApprovalReceived`. Override this method to
     * make your stuffs within your contract.
     * @param sender The address which called `approveAndCall` function
     * @param amount The amount of tokens to be spent
     * @param data Additional data with no specified format
     */
    function _approvalReceived(
        address sender,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        // optional override
    }
}

// File: @openzeppelin/contracts/utils/math/Math.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// File: contracts/ExenoBridgeNode.sol


pragma solidity 0.8.16;











/**
 * This contract facilitates cross-chain bridging of ERC20 tokens (including EXN token) and native currencies.
 * Users (referred to as 'beneficiaries') are expected to make a deposit on one chain (i.e. origin chain) 
 * and then receive a payout denominated in corresponding tokens (or native currency) on another chain (i.e. destination chain),
 * whereas all transfers are coordinated and authorized by Exeno's off-chain cloud infrastructure.
 */

contract ExenoBridgeNode is 
    Ownable,
    Pausable,
    ReentrancyGuard,
    ERC1363Payable
{
    enum Class { DEPOSIT, WITHDRAW, EXCHANGE }
    
    bytes32 private constant CLASS_DEPOSIT = bytes32("deposit");
    bytes32 private constant CLASS_WITHDRAW = bytes32("withdraw");
    bytes32 private constant CLASS_EXCHANGE = bytes32("exchange");

    bytes32 private constant METHOD_MINT = bytes32("mint");
    bytes32 private constant METHOD_BURN = bytes32("burn");
    bytes32 private constant METHOD_FREEZE = bytes32("freeze");
    bytes32 private constant METHOD_UNFREEZE = bytes32("unfreeze");
    bytes32 private constant METHOD_ACCEPT = bytes32("accept");
    bytes32 private constant METHOD_RELEASE = bytes32("release");
    
    // Number of router addresses whose private keys are used for signing playloads
    uint8 public constant ROUTER_SIZE = 5;
    
    // Encoded name of the blockchain network where this contract is deployed
    bytes32 public immutable NETWORK;
    
    // Address where funds are sent when they are extracted from this contract
    address public immutable WALLET;

    // Amount of frozen EXN tokens corresponding to the amount of EXN tokens minted on other blockchains
    uint256 public frozenTokens;
    
    // List of routers
    address[ROUTER_SIZE] public routerList;

    // Map of routers
    mapping(address => bool) public routers;

    // Amount of accumulated fees: first value is denominated in cash (i.e. native currency), while the second value is denominated in core token (i.e. EXN token)
    mapping(address => uint256[2]) public earnedFee;

    // Amount of overpaid fees: first value is denominated in cash (i.e. native currency), while the second value is denominated in core token (i.e. EXN token)
    mapping(address => uint256[2]) public extraFee;

    // Map of already used nonces for deposits
    mapping(bytes32 => bool) public depositIds;

    // Map of already used nonces for withdrawals
    mapping(bytes32 => bool) public withdrawIds;

    // Indicates a deposit transaction has been made - to be captured and acted upon by the cloud infrastructure
    event Deposit(
        bytes32 indexed id,
        address indexed platform,
        bytes32[2] network,
        address[2] beneficiary,
        address[2] token,
        uint256[2] amount,
        uint256[2] timeout,
        bytes32[2] method
    );

    // Indicates a withdraw transaction has been made - only for informational purposes, not intended to be acted upon by the cloud infrastructure
    event Withdraw(
        bytes32 indexed id,
        address indexed platform,
        bytes32[2] network,
        address[2] beneficiary,
        address[2] token,
        uint256[2] amount,
        uint256[2] timeout,
        bytes32[2] method
    );

    // Indicates an exchange transaction has been made - only for informational purposes, not intended to be acted upon by the cloud infrastructure
    event Exchange(
        bytes32 indexed id,
        address indexed platform,
        bytes32[2] network,
        address[2] beneficiary,
        address[2] token,
        uint256[2] amount,
        uint256[2] timeout,
        bytes32[2] method
    );

    // Indicates that new routers have been set
    event SetRouters(
        address[ROUTER_SIZE] routers
    );

    // Indicates that funds have been released
    event ReleaseFunds (
        address token,
        uint256 amount
    );

    // Indicates that a platform's earned fees have been reset
    event ResetEarnedFees (
        address indexed platform,
        uint256[2] fee
    );

    // Indicates that a platform's extra fees have been released
    event ReleaseExtraFees (
        address indexed platform,
        uint256[2] fee
    );

    // Indicates that core tokens have been frozen
    event FreezeTokens (
        uint256 amount
    );

    // Indicates that core tokens have been unfrozen
    event UnfreezeTokens (
        uint256 amount
    );

    /**
        Data payload describing the entire cross-blockchain transfer
        The first value in a pair refers to what happens on the origin chain, the second value refers to what happens on the destination chain
        method[0] - allowed values: "burn" | "freeze" | "accept"
        method[1] - allowed values: "mint" | "unfreeze" | "release"
     */
    struct Data {
        bytes32 id;
        address platform;
        bytes32[2] network;
        address[2] beneficiary;
        address[2] token;
        uint256[2] amount;
        uint256[2] timeout;
        bytes32[2] method;
    }

    modifier onlyOwnerOrPlatform(address platform) {
        require(msg.sender == owner() || msg.sender == platform,
            "ExenoBridgeNode: unauthorized owner or platform");
        _;
    }

    modifier validAddress(address a) {
        require(a != address(0),
            "ExenoBridgeNode: address cannot be zero");
        require(a != address(this),
            "ExenoBridgeNode: invalid address");
        _;
    }

    constructor(
        bytes32 network,
        address token,
        address wallet
    )
        validAddress(token)
        validAddress(wallet)
        ERC1363Payable(IERC1363(token))
    {
        NETWORK = network;
        WALLET = wallet;
    }

    /**
     * Gateway for deposit transactions to be executed by the beneficiary - with arguments listed explicitly
     * @param signature - all arguments need to be signed by a single router, indicating the router's acceptance for the deposit's execution
     */
    function deposit(
        bytes32 id,
        address platform,
        bytes32[2] calldata network,
        address[2] calldata beneficiary,
        address[2] calldata token,
        uint256[2] calldata amount,
        uint256[2] calldata timeout,
        bytes32[2] calldata method,
        uint256[2] calldata fee,
        bytes32 operation,
        bytes calldata signature
    )
        external payable nonReentrant whenNotPaused
    {
        Data memory data = Data(id, platform, network, beneficiary, token, amount, timeout, method);
        _verifySingleSignature(data, fee, operation, signature);
        _validateClass(data, operation, Class.DEPOSIT);
        _validateDeposit(data, fee);
        _processDeposit(data, false);
    }

    /**
     * Gateway for deposit transactions to be executed by the beneficiary - with arguments packed into a single encoding
     */
    function deposit(
        bytes calldata encodedData
    )
        external payable nonReentrant whenNotPaused
    {
        (bytes32 operation, bytes memory payload) = abi.decode(encodedData, (bytes32, bytes));
        (Data memory data, uint256[2] memory fee, bytes memory signature) = _unpackSingleSignedData(payload);
        _verifySingleSignature(data, fee, operation, signature);
        _validateClass(data, operation, Class.DEPOSIT);
        _validateDeposit(data, fee);
        _processDeposit(data, false);
    }

    /**
     * Gateway for withdraw transacions to be executed by the beneficiary - with arguments listed explicitly
     * @param signature - all arguments need to be signed by 3 routers, indicating their acceptance for the withdrawal's execution
     */
    function withdraw(
        bytes32 id,
        address platform,
        bytes32[2] calldata network,
        address[2] calldata beneficiary,
        address[2] calldata token,
        uint256[2] calldata amount,
        uint256[2] calldata timeout,
        bytes32[2] calldata method,
        uint256[2] calldata fee,
        bytes32 operation,
        bytes[3] calldata signature
    )
        external payable nonReentrant whenNotPaused
    {
        Data memory data = Data(id, platform, network, beneficiary, token, amount, timeout, method);
        _verifyTrippleSignature(data, fee, operation, signature);
        _validateClass(data, operation, Class.WITHDRAW);
        _validateWithdraw(data, fee);
        _processWithdraw(data, false);
    }

    /**
     * Gateway for withdraw transacions to be executed by the beneficiary - with arguments packed into a single encoding
     */
    function withdraw(
        bytes calldata encodedData
    )
        external payable nonReentrant whenNotPaused
    {
        (bytes32 operation, bytes memory payload) = abi.decode(encodedData, (bytes32, bytes));
        (Data memory data, uint256[2] memory fee, bytes[3] memory signature) = _unpackTrippleSignedData(payload);
        _verifyTrippleSignature(data, fee, operation, signature);
        _validateClass(data, operation, Class.WITHDRAW);
        _validateWithdraw(data, fee);
        _processWithdraw(data, false);
    }

    /**
     * Gateway for exchange transactions to be executed by the beneficiary - with arguments listed explicitly
     * @param signature - all arguments need to be signed by 3 routers, indicating their acceptance for the deposit's execution
     */
    function exchange(
        bytes32 id,
        address platform,
        bytes32[2] calldata network,
        address[2] calldata beneficiary,
        address[2] calldata token,
        uint256[2] calldata amount,
        uint256[2] calldata timeout,
        bytes32[2] calldata method,
        uint256[2] calldata fee,
        bytes32 operation,
        bytes[3] calldata signature
    )
        external payable nonReentrant whenNotPaused
    {
        Data memory data = Data(id, platform, network, beneficiary, token, amount, timeout, method);
        _verifyTrippleSignature(data, fee, operation, signature);
        _validateClass(data, operation, Class.EXCHANGE);
        _validateDeposit(data, fee);
        _processDeposit(data, true);
        _processWithdraw(data, true);
    }

    /**
     * Gateway for exchange transactions to be executed by the beneficiary - with arguments packed into a single encoding
     */
    function exchange(
        bytes calldata encodedData
    )
        external payable nonReentrant whenNotPaused
    {
        (bytes32 operation, bytes memory payload) = abi.decode(encodedData, (bytes32, bytes));
        (Data memory data, uint256[2] memory fee, bytes[3] memory signature) = _unpackTrippleSignedData(payload);
        _verifyTrippleSignature(data, fee, operation, signature);
        _validateClass(data, operation, Class.EXCHANGE);
        _validateDeposit(data, fee);
        _processDeposit(data, true);
        _processWithdraw(data, true);
    }

    /**
     * Dry-run probe for a deposit payload
     */
    function depositDryRun(
        bytes calldata encodedData
    )
        external view returns(bool)
    {
        (bytes32 operation, bytes memory payload) = abi.decode(encodedData, (bytes32, bytes));
        (Data memory data, uint256[2] memory fee, bytes memory signature) = _unpackSingleSignedData(payload);
        _verifySingleSignature(data, fee, operation, signature);
        _validateClass(data, operation, Class.DEPOSIT);
        require(!depositIds[data.id],
            "ExenoBridgeNode: deposit already processed");
        require(data.network[0] == NETWORK,
            "ExenoBridgeNode: network mismatch");
        if (data.method[0] == METHOD_BURN) {
            require(_isMintable(data.token[0]),
                "ExenoBridgeNode: burn method cannot be applied to a non-mintable token");
        } else if (data.method[0] == METHOD_FREEZE) {
            require(_isCore(data.token[0]),
                "ExenoBridgeNode: freeze method cannot be applied to a non-core token");
        }
        return data.timeout[0] == 0 || block.timestamp <= data.timeout[0];
    }

    /**
     * Dry-run probe for a withdraw payload
     */
    function withdrawDryRun(
        bytes calldata encodedData
    )
        external view returns(bool)
    {
        (bytes32 operation, bytes memory payload) = abi.decode(encodedData, (bytes32, bytes));
        (Data memory data, uint256[2] memory fee, bytes[3] memory signature) = _unpackTrippleSignedData(payload);
        _verifyTrippleSignature(data, fee, operation, signature);
        _validateClass(data, operation, Class.WITHDRAW);
        require(!withdrawIds[data.id],
            "ExenoBridgeNode: withdraw already processed");
        require(data.network[1] == NETWORK,
            "ExenoBridgeNode: network mismatch");
        if (data.method[1] == METHOD_MINT) {
            require(_isMintable(data.token[1]),
                "ExenoBridgeNode: mint method cannot be applied to a non-mintable token");
        } else if (data.method[1] == METHOD_UNFREEZE) {
            require(_isCore(data.token[1]),
                "ExenoBridgeNode: unfreeze method cannot be applied to a non-core token");
            require(ownedTokens(data.token[1]) >= data.amount[1],
                "ExenoBridgeNode: not enough owned tokens");
            require(frozenTokens >= data.amount[1],
                "ExenoBridgeNode: not enough frozen tokens");
        } else {
            if (_isNative(data.token[1])) {
                require(availableCash() >= data.amount[1],
                    "ExenoBridgeNode: not enough available cash");
            } else {
                require(availableTokens(data.token[1]) >= data.amount[1],
                    "ExenoBridgeNode: not enough available tokens");
            }
        }
        return data.timeout[1] == 0 || block.timestamp >= data.timeout[1];
    }

    /**
     * Dry-run probe for an exchange payload
     */
    function exchangeDryRun(
        bytes calldata encodedData
    )
        external view returns(bool)
    {
        (bytes32 operation, bytes memory payload) = abi.decode(encodedData, (bytes32, bytes));
        (Data memory data, uint256[2] memory fee, bytes[3] memory signature) = _unpackTrippleSignedData(payload);
        _verifyTrippleSignature(data, fee, operation, signature);
        _validateClass(data, operation, Class.EXCHANGE);
        require(!depositIds[data.id],
            "ExenoBridgeNode: deposit already processed");
        require(!withdrawIds[data.id],
            "ExenoBridgeNode: withdraw already processed");
        require(data.network[0] == NETWORK,
            "ExenoBridgeNode: network mismatch");
        if (data.method[0] == METHOD_BURN) {
            require(_isMintable(data.token[0]),
                "ExenoBridgeNode: burn method cannot be applied to a non-mintable token");
        } else if (data.method[0] == METHOD_FREEZE) {
            require(_isCore(data.token[0]),
                "ExenoBridgeNode: freeze method cannot be applied to a non-core token");
        }
        if (data.method[1] == METHOD_MINT) {
            require(_isMintable(data.token[1]),
                "ExenoBridgeNode: mint method cannot be applied to a non-mintable token");
        } else if (data.method[1] == METHOD_UNFREEZE) {
            require(_isCore(data.token[1]),
                "ExenoBridgeNode: unfreeze method cannot be applied to a non-core token");
            require(ownedTokens(data.token[1]) >= data.amount[1],
                "ExenoBridgeNode: not enough owned tokens");
            require(frozenTokens >= data.amount[1],
                "ExenoBridgeNode: not enough frozen tokens");
        } else {
            if (_isNative(data.token[1])) {
                require(availableCash() >= data.amount[1],
                    "ExenoBridgeNode: not enough available cash");
            } else {
                require(availableTokens(data.token[1]) >= data.amount[1],
                    "ExenoBridgeNode: not enough available tokens");
            }
        }
        return data.timeout[0] == 0 || block.timestamp <= data.timeout[0];
    }

    /**
     * Gateway for payouts executed by the router - with arguments listed explicitly
     */
    function payout(
        bytes32 id,
        address platform,
        bytes32[2] calldata network,
        address[2] calldata beneficiary,
        address[2] calldata token,
        uint256[2] calldata amount,
        uint256[2] calldata timeout,
        bytes32[2] calldata method
    )
        external onlyOwner
    {
        _processWithdraw(Data(id, platform, network, beneficiary, token, amount, timeout, method), false);
    }

    /**
     * Gateway for payouts to be executed by the router - with arguments packed into a single encoding
     */
    function payout(
        bytes calldata payload
    )
        external onlyOwner
    {
        _processWithdraw(_unpackPayload(payload), false);
    }

    /**
     * We want the contract to be able to receive native currency - it's needed when we want to add liquidity to it
     */
    receive()
        external payable
    {}

    /**
     * Implementation of ERC1363Payable
     * When EXN tokens are sent to this contract via `transferAndCall` they are interpreted as an act of depositing or withdrawing
     * @param sender The address performing the action
     * @param amount The amount of tokens transferred
     * @param encodedData Encoded payload which specifies the intended deposit or withdrawal
     */
    function _transferReceived(
        address,
        address sender,
        uint256 amount,
        bytes memory encodedData
    )
        internal override nonReentrant whenNotPaused
    {
        (bytes32 operation, bytes memory payload) = abi.decode(encodedData, (bytes32, bytes));
        
        // In case of a deposit transaction we treat tokens sent to this contract as a deposit and/or fee payment
        if (operation == CLASS_DEPOSIT) {
            (Data memory data, uint256[2] memory fee, bytes memory signature) = _unpackSingleSignedData(payload);
            _verifySingleSignature(data, fee, operation, signature);
            _validateClass(data, operation, Class.DEPOSIT);
            _validateDeposit(data, fee, sender, amount);
            _processDeposit(data, false);
            return;
        }
        
        // In case of a withdraw transaction we treat tokens sent to this contract as a fee payment
        if (operation == CLASS_WITHDRAW) {
            (Data memory data, uint256[2] memory fee, bytes[3] memory signature) = _unpackTrippleSignedData(payload);
            _verifyTrippleSignature(data, fee, operation, signature);
            _validateClass(data, operation, Class.WITHDRAW);
            _validateWithdraw(data, fee, amount);
            _processWithdraw(data, false);
            return;
        }

        // In case of an exchange transaction we treat tokens sent to this contract as a deposit and/or fee payment
        if (operation == CLASS_EXCHANGE) {
            (Data memory data, uint256[2] memory fee, bytes[3] memory signature) = _unpackTrippleSignedData(payload);
            _verifyTrippleSignature(data, fee, operation, signature);
            _validateClass(data, operation, Class.EXCHANGE);
            _validateDeposit(data, fee, sender, amount);
            _processDeposit(data, true);
            _processWithdraw(data, true);
            return;
        }

        revert("ExenoBridgeNode: transfer received with an unexpected class");
    }

    /**
     * For deposits, only payloads signed by the router should be accepted
     * Make sure that arguments contained in the payload match the arguments encoded in the signed message
     */
    function _verifySingleSignature(
        Data memory d,
        uint256[2] memory fee,
        bytes32 operation,
        bytes memory signature
    )
        internal view
    {
        bytes memory payload = abi.encodePacked(d.id, d.platform, d.network, d.beneficiary, d.token, d.amount, d.timeout, d.method, fee, operation);
        address signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(payload)), signature);
        require(routers[signer],
            "ExenoBridgeNode: unauthorized signer");
    }

    /**
     * For withdrawals, only payloads signed by 3 routers should be accepted
     * Make sure that arguments contained in the payload match the arguments encoded in the signed message
     */
    function _verifyTrippleSignature(
        Data memory d,
        uint256[2] memory fee,
        bytes32 operation,
        bytes[3] memory signature
    )
        internal view
    {
        bytes memory payload = abi.encodePacked(d.id, d.platform, d.network, d.beneficiary, d.token, d.amount, d.timeout, d.method, fee, operation);
        address[3] memory signer = [
            ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(payload)), signature[0]),
            ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(payload)), signature[1]),
            ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(payload)), signature[2])
        ];
        require(signer[0] != signer[1] && signer[0] != signer[2] && signer[1] != signer[2],
            "ExenoBridgeNode: signers are required to be unique");
        require(routers[signer[0]] && routers[signer[1]] && routers[signer[2]],
            "ExenoBridgeNode: unauthorized signer");
    }

    /**
     * Validate payload class
     */
    function _validateClass(
        Data memory d,
        bytes32 operation,
        Class class
    )
        internal pure
    {
        if (class == Class.DEPOSIT) {
            require(operation == CLASS_DEPOSIT,
                "ExenoBridgeNode: operation mismatch for deposit transaction");
            return;
        }
        if (class == Class.WITHDRAW) {
            require(operation == CLASS_WITHDRAW,
                "ExenoBridgeNode: operation mismatch for withdraw transaction");
            return;
        }
        if (class == Class.EXCHANGE) {
            require(operation == CLASS_EXCHANGE,
                "ExenoBridgeNode: operation mismatch for exchange transaction");
            require(d.method[0] == METHOD_ACCEPT && d.method[1] == METHOD_RELEASE,
                "ExenoBridgeNode: method mismatch for exchange transaction");
            require(d.network[0] == d.network[1],
                "ExenoBridgeNode: exchange is only allowed within the same network");
            require(d.timeout[1] == 0,
                "ExenoBridgeNode: exchange requires immediate payout");
            return;
        }
        revert("ExenoBridgeNode: unexpected class");
    }

    /**
     * When fee is paid in cash (i.e. native currency), validate the following aspects of a deposit:
     * (a) the sender matches the beneficiary
     * (b) the attached payment and/or allowance match the values defined in the payload
     */
    function _validateDeposit(
        Data memory d,
        uint256[2] memory fee
    )
        internal
    {
        require(msg.sender == d.beneficiary[0],
            "ExenoBridgeNode: unexpected sender");
        if (_isNative(d.token[0])) {
            require(msg.value >= d.amount[0] + fee[0],
                "ExenoBridgeNode: not enough cash attached to cover amount and fee");
            earnedFee[d.platform][0] += fee[0];
            extraFee[d.platform][0] += msg.value - d.amount[0] - fee[0];
        } else {
            require(msg.value >= fee[0],
                "ExenoBridgeNode: not enough cash attached to cover fee");
            require(IERC20(d.token[0]).allowance(msg.sender, address(this)) >= d.amount[0],
                "ExenoBridgeNode: before depositing user must approve amount");
            require(IERC20(d.token[0]).transferFrom(msg.sender, address(this), d.amount[0]),
                "ExenoBridgeNode: ERC20 transferFrom failed");
            earnedFee[d.platform][0] += fee[0];
            extraFee[d.platform][0] += msg.value - fee[0];
        }
    }

    /**
     * When fee is paid in core tokens, validate the following aspects of a deposit:
     * (a) the sender matches the beneficiary
     * (b) the transferred amount and/or allowance match the values defined in the payload
     */
    function _validateDeposit(
        Data memory d,
        uint256[2] memory fee,
        address sender,
        uint256 amount
    )
        internal
    {
        require(sender == d.beneficiary[0],
            "ExenoBridgeNode: unexpected sender");
        if (_isCore(d.token[0])) {
            require(amount >= d.amount[0] + fee[1],
                "ExenoBridgeNode: not enough core tokens transferred to cover amount and fee");
            earnedFee[d.platform][1] += fee[1];
            extraFee[d.platform][1] += amount - d.amount[0] - fee[1];
        } else {
            require(amount >= fee[1],
                "ExenoBridgeNode: not enough core tokens transferred to cover fee");
            require(IERC20(d.token[0]).allowance(sender, address(this)) >= d.amount[0],
                "ExenoBridgeNode: before depositing user must approve amount");
            require(IERC20(d.token[0]).transferFrom(sender, address(this), d.amount[0]),
                "ExenoBridgeNode: ERC20 transferFrom failed");
            earnedFee[d.platform][1] += fee[1];
            extraFee[d.platform][1] += amount - fee[1];
        }
    }

    /**
     * Process a deposit according to the instruction defined in the `method[0]` parameter
     * There are 3 options: 
     * (a) "burn" - in case the token on the origin chain is mintable
     * (b) "freeze" - in case the token on the destination chain is mintable
     * (c) "accept" - in all other cases
     */
    function _processDeposit(
        Data memory d,
        bool isExchange
    )
        internal
    {
        require(!depositIds[d.id],
            "ExenoBridgeNode: deposit already processed");
        depositIds[d.id] = true;
        require(d.network[0] == NETWORK,
            "ExenoBridgeNode: network mismatch");
        require(d.timeout[0] == 0 || block.timestamp <= d.timeout[0],
            "ExenoBridgeNode: time-window for deposit has already expired");
        if (d.method[0] == METHOD_BURN) {
            require(_isMintable(d.token[0]),
                "ExenoBridgeNode: burn method cannot be applied to a non-mintable token");
            ExenoTokenMintable(d.token[0]).burn(d.amount[0]);
        } else if (d.method[0] == METHOD_FREEZE) {
            require(_isCore(d.token[0]),
                "ExenoBridgeNode: freeze method cannot be applied to a non-core token");
            frozenTokens += d.amount[0];
        }
        if (!isExchange) {
            emit Deposit(d.id, d.platform, d.network, d.beneficiary, d.token, d.amount, d.timeout, d.method);
        }
    }

    /**
     * When fee is paid in cash (i.e. native currency), validate that the attached payment matches the value defined in the payload
     */
    function _validateWithdraw(
        Data memory d,
        uint256[2] memory fee
    )
        internal
    {
        require(msg.value >= fee[0],
            "ExenoBridgeNode: not enough cash attached to cover fee");
        earnedFee[d.platform][0] += fee[0];
        extraFee[d.platform][0] += msg.value - fee[0];
    }

    /**
     * When fee is paid in core tokens, validate that the transferred amount matches the value defined in the payload
     */
    function _validateWithdraw(
        Data memory d,
        uint256[2] memory fee,
        uint256 amount
    )
        internal
    {
        require(amount >= fee[1],
            "ExenoBridgeNode: not enough core tokens transferred to cover fee");
        earnedFee[d.platform][1] += fee[1];
        extraFee[d.platform][1] += amount - fee[1];
    }

    /**
     * Process a withdrawal according to the instruction defined in the `method[1]` parameter
     * There are 3 options: 
     * (a) "mint" - in case the token on the destination chain is mintable
     * (b) "unfreeze" - in case the token on the origin chain is mintable
     * (c) "release" - in all other cases
     */
    function _processWithdraw(
        Data memory d,
        bool isExchange
    )
        internal
    {
        require(!withdrawIds[d.id],
            "ExenoBridgeNode: withdraw already processed");
        withdrawIds[d.id] = true;
        require(d.network[1] == NETWORK,
            "ExenoBridgeNode: network mismatch");
        require(d.timeout[1] == 0 || block.timestamp >= d.timeout[1],
            "ExenoBridgeNode: time-window for withdraw has not started yet");
        if (d.method[1] == METHOD_MINT) {
            require(_isMintable(d.token[1]),
                "ExenoBridgeNode: mint method cannot be applied to a non-mintable token");
            ExenoTokenMintable(d.token[1]).mint(d.beneficiary[1], d.amount[1]);
        } else if (d.method[1] == METHOD_UNFREEZE) {
            require(_isCore(d.token[1]),
                "ExenoBridgeNode: unfreeze method cannot be applied to a non-core token");
            require(ownedTokens(d.token[1]) >= d.amount[1],
                "ExenoBridgeNode: not enough owned tokens");
            require(frozenTokens >= d.amount[1],
                "ExenoBridgeNode: not enough frozen tokens");
            require(IERC20(d.token[1]).transfer(d.beneficiary[1], d.amount[1]),
                "ExenoBridgeNode: ERC20 transfer failed");
            frozenTokens -= d.amount[1];
        } else {
            if (_isNative(d.token[1])) {
                require(availableCash() >= d.amount[1],
                    "ExenoBridgeNode: not enough available cash");
                Address.sendValue(payable(d.beneficiary[1]), d.amount[1]);
            } else {
                require(availableTokens(d.token[1]) >= d.amount[1],
                    "ExenoBridgeNode: not enough available tokens");
                require(IERC20(d.token[1]).transfer(d.beneficiary[1], d.amount[1]),
                    "ExenoBridgeNode: ERC20 transfer failed");
            }
        }
        if (isExchange) {
            emit Exchange(d.id, d.platform, d.network, d.beneficiary, d.token, d.amount, d.timeout, d.method);
        } else {
            emit Withdraw(d.id, d.platform, d.network, d.beneficiary, d.token, d.amount, d.timeout, d.method);
        }
    }

    /**
     * Unpack encoded unsigned payload
     */
    function _unpackPayload(bytes memory payload)
        internal pure returns(Data memory)
    {
        (
            bytes32 id,
            address platform,
            bytes32[2] memory network,
            address[2] memory beneficiary,
            address[2] memory token,
            uint256[2] memory amount,
            uint256[2] memory timeout,
            bytes32[2] memory method
        ) = abi.decode(payload, (bytes32, address, bytes32[2], address[2], address[2],  uint256[2], uint256[2], bytes32[2]));
        return Data(id, platform, network, beneficiary, token, amount, timeout, method);
    }

    /**
     * Unpack encoded signed data for deposit transactions
     */
    function _unpackSingleSignedData(bytes memory encodedData)
        internal pure returns(Data memory, uint256[2] memory, bytes memory)
    {
        (
            bytes memory payload,
            uint256[2] memory fee,
            bytes memory signature
        ) = abi.decode(encodedData, (bytes, uint256[2], bytes));
        return (_unpackPayload(payload), fee, signature);
    }
    
    /**
     * Unpack encoded signed data for withdraw and exchange transactions
     */
    function _unpackTrippleSignedData(bytes memory encodedData)
        internal pure returns(Data memory, uint256[2] memory, bytes[3] memory)
    {
        (
            bytes memory payload,
            uint256[2] memory fee,
            bytes[3] memory signature
        ) = abi.decode(encodedData, (bytes, uint256[2], bytes[3]));
        return (_unpackPayload(payload), fee, signature);
    }

    /**
     * Returns the IERC1363 token associated with this contract, i.e. EXN token
     */
    function _coreToken()
        internal view returns(address)
    {
        return address(acceptedToken());
    }

    /**
     * Checks whether we are dealing with the core token (i.e. EXN token)
     */
    function _isCore(address token)
        internal view returns(bool)
    {
        return token == _coreToken();
    }

    /**
     * Checks whether we are dealing with the native currency (indicated as zero address)
     */
    function _isNative(address token)
        internal pure returns(bool)
    {
        return token == address(0);
    }

    /**
     * Checks whether we are dealing with a mintable core token (not all incarnations of the EXN token are mintable)
     */
    function _isMintable(address token)
        internal view returns(bool)
    {
        if (!_isCore(token)) {
            return false;
        }
        ExenoTokenMintable mintable = ExenoTokenMintable(token);
        try mintable.manager() returns(address manager) {
            return manager == address(this);
        } catch (bytes memory) {
            return false;
        }
    }

    /**
     * Current balance of native currency
     */
    function ownedCash()
        public view returns(uint256)
    {
        return address(this).balance;
    }

    /**
     * Current balance of the core token (i.e. EXN token)
     */
    function ownedTokens()
        external view returns(uint256)
    {
        return ownedTokens(_coreToken());
    }

    /**
     * Current balance of any ERC20 token
     */
    function ownedTokens(address token)
        public view returns(uint256)
    {
        return IERC20(token).balanceOf(address(this));
    }

    /**
     * How much native currency is available for withdrawals/payouts
     */
    function availableCash()
        public view returns(uint256)
    {
        return ownedCash();
    }

    /**
     * How many core tokens (i.e. EXN tokens) are available for withdrawals/payouts
     */
    function availableTokens()
        external view returns(uint256)
    {
        return availableTokens(_coreToken());
    }

    /**
     * How many ERC20 tokens are available for withdrawals/payouts
     */
    function availableTokens(address token)
        public view returns(uint256)
    {
        // Frozen tokens are not meant to be part of the liquidity pool
        // They should only be released as a result of burning of EXN tokens on some other chain
        if (_isCore(token)) {
            return Math.max(ownedTokens(_coreToken()) - frozenTokens, 0);
        }
        return ownedTokens(token);
    }

    /**
     * Release all available funds in native currency
     */
    function releaseAvailableCash()
        external onlyOwner
    {
        uint256 balance = availableCash();
        require(balance > 0,
            "ExenoBridgeNode: there is no available cash to release");
        releaseAvailableCash(balance);
    }

    /**
     * Release a specified amount of available funds in native currency
     */
    function releaseAvailableCash(uint256 amount)
        public onlyOwner
    {
        require(amount <= availableCash(),
            "ExenoBridgeNode: amount to release is more than available");
        Address.sendValue(payable(WALLET), amount);
        emit ReleaseFunds(address(0), amount);
    }

    /**
     * Release all available funds in the core token (i.e. EXN token)
     */
    function releaseAvailableTokens()
        external onlyOwner
    {
        releaseAvailableTokens(_coreToken());
    }

    /**
     * Release a specified amount of the core token (i.e. EXN token)
     */
    function releaseAvailableTokens(uint256 amount)
        external onlyOwner
    {
        releaseAvailableTokens(_coreToken(), amount);
    }

    /**
     * Release all available funds in an ERC20 token
     */
    function releaseAvailableTokens(address token)
        public onlyOwner
    {
        uint256 balance = availableTokens(token);
        require(balance > 0,
            "ExenoBridgeNode: there are no available tokens to release");
       releaseAvailableTokens(token, balance);
    }

    /**
     * Release a specified amount of an ERC20 token
     */
    function releaseAvailableTokens(
        address token,
        uint256 amount
    )
        public onlyOwner nonReentrant
    {
        require(amount <= availableTokens(token),
            "ExenoBridgeNode: amount to release is more than available");
        require(IERC20(token).transfer(WALLET, amount),
            "ExenoBridgeNode: ERC20 transfer failed");
        emit ReleaseFunds(token, amount);
    }

    /**
     * Reset earned fees for a platform 
     */
    function resetEarnedFees(address platform)
        external onlyOwnerOrPlatform(platform)
    {
        require(earnedFee[platform][0] > 0 || earnedFee[platform][1] > 0,
            "ExenoBridgeNode: there are no fees to reset");
        emit ResetEarnedFees(platform, earnedFee[platform]);
        earnedFee[platform][0] = 0;
        earnedFee[platform][1] = 0;
    }

    /**
     * Release extra fees for a platform 
     */
    function releaseExtraFees(address platform)
        external onlyOwnerOrPlatform(platform) nonReentrant
    {
        require(extraFee[platform][0] > 0 || extraFee[platform][1] > 0,
            "ExenoBridgeNode: there are no fees to release");
        emit ReleaseExtraFees(platform, extraFee[platform]);
        if (extraFee[platform][0] > 0) {
            Address.sendValue(payable(platform), extraFee[platform][0]);
            extraFee[platform][0] = 0;
        }
        if (extraFee[platform][1] > 0) {
            require(IERC20(_coreToken()).transfer(platform, extraFee[platform][1]),
                "ExenoBridgeNode: ERC20 transfer failed");
            extraFee[platform][1] = 0;
        }
    }

    /**
     * Configure routers
     */
    function setRouters(address[ROUTER_SIZE] calldata newRouters)
        external onlyOwner
    {
        for (uint8 i = 0; i < ROUTER_SIZE; i++) {
            routers[routerList[i]] = false;
        }
        for (uint8 i = 0; i < ROUTER_SIZE; i++) {
            routers[newRouters[i]] = true;
            routerList[i] = newRouters[i];
        }
        emit SetRouters(newRouters);
    }

    /**
     * Freeze core tokens - only to be used when initializing the contract
     */
    function freezeTokens(address fromAccount, uint256 amount)
        external onlyOwner nonReentrant
    {
        require(IERC20(_coreToken()).allowance(fromAccount, address(this)) >= amount,
            "ExenoBridgeNode: before freezing account must approve amount");
        require(IERC20(_coreToken()).transferFrom(fromAccount, address(this), amount),
            "ExenoBridgeNode: ERC20 transferFrom failed");
        frozenTokens += amount;
        emit FreezeTokens(amount);
    }

    /**
     * Unfreeze core tokens - only to be used when decommissioning the contract
     */
    function unfreezeTokens(uint256 amount)
        external onlyOwner nonReentrant
    {
        require(amount <= frozenTokens,
            "ExenoBridgeNode: amount to unfreeze is more than frozen");
        require(IERC20(_coreToken()).transfer(WALLET, amount),
            "ExenoBridgeNode: ERC20 transfer failed");
        frozenTokens -= amount;
        emit UnfreezeTokens(amount);
    }

    /**
     * Pause all deposit and withdrawal operations
     */
    function pause()
        external onlyOwner
    {
        _pause();
    }
    
    /**
     * Unpause all deposit and withdrawal operations
     */
    function unpause()
        external onlyOwner
    {
        _unpause();
    }

    /**
     * Decommission this contract
     */
    function decommission()
        external onlyOwner
    {
        selfdestruct(payable(WALLET));
    }
}
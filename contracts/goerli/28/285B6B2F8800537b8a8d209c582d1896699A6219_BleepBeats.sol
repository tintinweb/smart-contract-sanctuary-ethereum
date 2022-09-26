// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.1) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length == 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector));
    }
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-1.0
pragma solidity 0.8.16;

import "./ERC721/implementations/ERC721.sol";
import "./ERC721/ERC4494/implementations/UsingERC4494PermitWithDynamicChainId.sol";
import "./Multicall/UsingMulticall.sol";
import "./ERC721/implementations/UsingExternalMinter.sol";
import "./ERC2981/implementations/UsingGlobalRoyalties.sol";
import "./Guardian/implementations/UsingGuardian.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";


contract BleepBeats is ERC721, UsingERC4494PermitWithDynamicChainId, UsingMulticall, UsingGuardian, UsingExternalMinter, UsingGlobalRoyalties {

    /// @dev Setup the roles
    /// @param initialMinterAdmin admin able to set the minter contract.
    /// @param initialRoyaltyAdmin admin able to update the royalty receiver and rates.
    /// @param initialGuardian guardian able to immortalize rules
    /// @param initialRoyaltyReceiver receiver of royalties
    /// @param imitialRoyaltyPer10Thousands amount of royalty in 10,000 basis point
    constructor(
        address initialGuardian,
        address initialMinterAdmin,
        address initialRoyaltyReceiver,
        uint96 imitialRoyaltyPer10Thousands,
        address initialRoyaltyAdmin
    ) UsingExternalMinter(initialMinterAdmin) UsingGlobalRoyalties(initialRoyaltyReceiver, imitialRoyaltyPer10Thousands, initialRoyaltyAdmin) UsingGuardian(initialGuardian){

    }

     /// @notice A descriptive name for a collection of NFTs in this contract.
    function name() public pure override returns (string memory) {
        return "The Bleep Machine";
    }

    /// @notice An abbreviated name for NFTs in this contract.
    function symbol() external pure returns (string memory) {
        return "EVM";
    }


    function supportsInterface(bytes4 id) public view virtual override(ERC721, UsingERC4494Permit, UsingGlobalRoyalties) returns (bool) {
        return super.supportsInterface(id);
    }


    // ----------------------------------------------------------------------------------------------------------------
    // MAGIC
    // ----------------------------------------------------------------------------------------------------------------

    using Strings for uint256;

    // 1F403 = 128003 = 16.000375 seconds
    // 186A258 = 25600600 = 3200.075 seconds
    // offset of 6s :BB80";
    // bytes constant DEFAULT_PARAMS = hex"0000000000000000000000000001F40300000000000000000000000000000000";
    // bytes constant DEFAULT_PARAMS = hex"0000000000000000000000000186A25800000000000000000000000000000000";
    bytes constant DEFAULT_PARAMS = hex"000000000000000000000000000186A000000000000000000000000000000000"; // 100000

    bytes32 constant HEX = "0123456789abcdef0000000000000000";

    // TODO get rid of it
    mapping(uint256 => bytes32) musicByteCodes;


    function mint(address to, bytes memory musicBytecode) external {
        // TODO require(msg.sender == minter, "NOT_AUTHORIZED");
        bytes
			memory executorCreation = hex"606d600c600039606d6000f36000358060801b806000529060801c60205260006040525b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b60ff9016604051806080019091905360010180604052602051600051600101806000529110601757602051806060526020016060f3";

        uint256 len = musicBytecode.length;
        uint256 mask = 256**(32 - len) - 1;
        assembly {
            let src := add(musicBytecode, 32)
            let dest := add(executorCreation, 68) // 32 + 36 where JUMPSET start (second one)
            for {} gt(len, 31) {
                len := sub(len, 32)
                dest := add(dest, 32)
                src := add(src, 32)
            } {
                mstore(dest, mload(src))
            }

            let srcpart := and(mload(src), not(mask)) // NOTE can remove that step by ensuring the length is a multiple of 32 bytes
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }


        uint256 executor;
        assembly {
            executor := create(0, add(executorCreation, 32), mload(executorCreation))
        }
        require(executor != 0, "CREATE_FAILS");
        _mint(executor, to);

        // TODO get rid of it
        bytes32 b;
        assembly {
            b := mload(add(musicBytecode,32))
        }
        musicByteCodes[executor] = b;
    }

	function tokenURI(uint256 id) public view override returns (string memory) {
        // TODO fails on non owner ?
		// address owner = _ownerOf(id);
		return _tokenURI(id);
	}


	function _tokenURI(uint256 id) internal view returns (string memory str) {
        (, bytes memory buffer) = address(uint160(id)).staticcall(DEFAULT_PARAMS);

        bytes memory header = hex"52494646c486010057415645666d74201000000001000100401f0000401f00000100080064617461a0860100";
		str =
			string(
				bytes.concat(
					'data:application/json,{"name":"The%20Bleep%20Machine","description":"The%20Bleep%20Machine%20produces%20music%20from%20EVM%20bytecode.","external_url":"TODO","image":"',
					"data:image/svg+xml;charset=utf8,<svg%2520xmlns='http://www.w3.org/2000/svg'%2520shape-rendering='crispEdges'%2520width='512'%2520height='512'><style>*{background-color:white}.b{animation:ba%25201s%2520steps(5,start)%2520infinite;-webkit-animation:ba%25201s%2520steps(5,start)%2520infinite;}@keyframes%2520ba{to{visibility: hidden;}}@-webkit-keyframes%2520ba{to{visibility:hidden;}}.b01{ animation-delay:.031s}.b02{animation-delay:.062s}.b03{animation-delay:.093s}.b04{animation-delay:.124s}.b05{animation-delay:.155s}.b06{animation-delay:.186s}.b07{animation-delay:.217s}.b08{animation-delay:.248s}.b09{animation-delay:.279s}.b10{animation-delay:.310s}.b11{animation-delay:.342s}.b12{animation-delay:.373s}.b13{animation-delay:.403s}.b14{animation-delay:.434s}.b15{animation-delay:.465s}.b16{animation-delay:.496s}.b17{animation-delay:.527s}.b18{animation-delay:.558s}.b19{animation-delay:.589s}.b20{animation-delay:.620s}.b21{animation-delay:.651s}.b22{animation-delay:.682s}.b23{animation-delay:.713s}.b24{animation-delay:.744s}.b25{animation-delay:.775s}.b26{animation-delay:.806s}.b27{animation-delay:.837s}.b28{animation-delay:.868s}.b29{animation-delay:.899s}.b30{animation-delay:.930s}.b31{animation-delay:.961s}.b32{animation-delay:.992s}</style><defs><path%2520id='Z'%2520d='M0,0h1v1h-1z'/><use%2520id='0'%2520href='%2523Z'%2520fill='%2523000c24'/><use%2520id='1'%2520href='%2523Z'%2520fill='%25239e0962'/><use%2520id='2'%2520href='%2523Z'%2520fill='%2523ff1c3a'/><use%2520id='3'%2520href='%2523Z'%2520fill='%2523bc0b22'/><use%2520id='4'%2520href='%2523Z'%2520fill='%2523ff991c'/><use%2520id='5'%2520href='%2523Z'%2520fill='%2523c16a00'/><use%2520id='6'%2520href='%2523Z'%2520fill='%2523ffe81c'/><use%2520id='7'%2520href='%2523Z'%2520fill='%25239e8b00'/><use%2520id='8'%2520href='%2523Z'%2520fill='%252323e423'/><use%2520id='9'%2520href='%2523Z'%2520fill='%2523009900'/><use%2520id='a'%2520href='%2523Z'%2520fill='%25231adde0'/><use%2520id='b'%2520href='%2523Z'%2520fill='%2523008789'/><use%2520id='c'%2520href='%2523Z'%2520fill='%25233d97ff'/><use%2520id='d'%2520href='%2523Z'%2520fill='%25233e5ca0'/><use%2520id='e'%2520href='%2523Z'%2520fill='%2523831bf9'/><use%2520id='f'%2520href='%2523Z'%2520fill='%2523522982'/></defs><g%2520transform='scale(64)'><use%2520x='00'%2520class='b%2520b01'%2520y='00'%2520href='%25230'/><use%2520x='01'%2520y='00'%2520href='%25230'/><use%2520x='02'%2520class='b%2520b02'%2520y='00'%2520href='%25230'/><use%2520x='03'%2520y='00'%2520href='%25230'/><use%2520x='04'%2520class='b%2520b03'%2520y='00'%2520href='%25230'/><use%2520x='05'%2520y='00'%2520href='%25230'/><use%2520x='06'%2520class='b%2520b04'%2520y='00'%2520href='%25230'/><use%2520x='07'%2520y='00'%2520href='%25230'/><use%2520x='00'%2520class='b%2520b05'%2520y='01'%2520href='%25230'/><use%2520x='01'%2520y='01'%2520href='%25230'/><use%2520x='02'%2520class='b%2520b06'%2520y='01'%2520href='%25230'/><use%2520x='03'%2520y='01'%2520href='%25230'/><use%2520x='04'%2520class='b%2520b07'%2520y='01'%2520href='%25230'/><use%2520x='05'%2520y='01'%2520href='%25230'/><use%2520x='06'%2520class='b%2520b08'%2520y='01'%2520href='%25230'/><use%2520x='07'%2520y='01'%2520href='%25230'/><use%2520x='00'%2520class='b%2520b09'%2520y='02'%2520href='%25230'/><use%2520x='01'%2520y='02'%2520href='%25230'/><use%2520x='02'%2520class='b%2520b10'%2520y='02'%2520href='%25230'/><use%2520x='03'%2520y='02'%2520href='%25230'/><use%2520x='04'%2520class='b%2520b11'%2520y='02'%2520href='%25230'/><use%2520x='05'%2520y='02'%2520href='%25230'/><use%2520x='06'%2520class='b%2520b12'%2520y='02'%2520href='%25230'/><use%2520x='07'%2520y='02'%2520href='%25230'/><use%2520x='00'%2520class='b%2520b13'%2520y='03'%2520href='%25230'/><use%2520x='01'%2520y='03'%2520href='%25230'/><use%2520x='02'%2520class='b%2520b14'%2520y='03'%2520href='%25230'/><use%2520x='03'%2520y='03'%2520href='%25230'/><use%2520x='04'%2520class='b%2520b15'%2520y='03'%2520href='%25230'/><use%2520x='05'%2520y='03'%2520href='%25230'/><use%2520x='06'%2520class='b%2520b16'%2520y='03'%2520href='%25230'/><use%2520x='07'%2520y='03'%2520href='%25230'/><use%2520x='00'%2520class='b%2520b17'%2520y='04'%2520href='%25230'/><use%2520x='01'%2520y='04'%2520href='%25230'/><use%2520x='02'%2520class='b%2520b18'%2520y='04'%2520href='%25230'/><use%2520x='03'%2520y='04'%2520href='%25230'/><use%2520x='04'%2520class='b%2520b19'%2520y='04'%2520href='%25230'/><use%2520x='05'%2520y='04'%2520href='%25230'/><use%2520x='06'%2520class='b%2520b20'%2520y='04'%2520href='%25230'/><use%2520x='07'%2520y='04'%2520href='%25230'/><use%2520x='00'%2520class='b%2520b21'%2520y='05'%2520href='%25230'/><use%2520x='01'%2520y='05'%2520href='%25230'/><use%2520x='02'%2520class='b%2520b22'%2520y='05'%2520href='%25230'/><use%2520x='03'%2520y='05'%2520href='%25230'/><use%2520x='04'%2520class='b%2520b23'%2520y='05'%2520href='%25230'/><use%2520x='05'%2520y='05'%2520href='%25230'/><use%2520x='06'%2520class='b%2520b24'%2520y='05'%2520href='%25230'/><use%2520x='07'%2520y='05'%2520href='%25230'/><use%2520x='00'%2520class='b%2520b25'%2520y='06'%2520href='%25230'/><use%2520x='01'%2520y='06'%2520href='%25230'/><use%2520x='02'%2520class='b%2520b26'%2520y='06'%2520href='%25230'/><use%2520x='03'%2520y='06'%2520href='%25230'/><use%2520x='04'%2520class='b%2520b27'%2520y='06'%2520href='%25230'/><use%2520x='05'%2520y='06'%2520href='%25230'/><use%2520x='06'%2520class='b%2520b28'%2520y='06'%2520href='%25230'/><use%2520x='07'%2520y='06'%2520href='%25230'/><use%2520x='00'%2520class='b%2520b29'%2520y='07'%2520href='%25230'/><use%2520x='01'%2520y='07'%2520href='%25230'/><use%2520x='02'%2520class='b%2520b30'%2520y='07'%2520href='%25230'/><use%2520x='03'%2520y='07'%2520href='%25230'/><use%2520x='04'%2520class='b%2520b31'%2520y='07'%2520href='%25230'/><use%2520x='05'%2520y='07'%2520href='%25230'/><use%2520x='06'%2520class='b%2520b32'%2520y='07'%2520href='%25230'/><use%2520x='07'%2520y='07'%2520href='%25230'/></g></svg>",
					'","animation_url":"data:audio/wav;base64,',
                    bytes(Base64.encode(bytes.concat(header, buffer))),
					'"}'
				)
			);


        // TODO get rid of it
        bytes32 musicByteCode = musicByteCodes[id];

        for (uint256 i = 0; i < 64; i +=2) {
            uint256 pre = i / 2;
            uint8 v = uint8(musicByteCode[pre]);
            bytes(str)[(pre *22) + 167 + 2327 + i*46] = HEX[uint8(v >> 4)];
            bytes(str)[(pre *22) + 167 + 2327 + 46 + i*46 ] = HEX[uint8(v & 0x0F)];
        }
	}

	function play(
		bytes memory musicBytecode,
		uint256 start,
		uint256 length
	) external returns (string memory) {
        bytes memory dynHeader = hex"524946460000000057415645666d74201000000001000100401f0000401f0000010008006461746100000000";
        assembly {
            let t := add(length, 36)
            mstore8(add(dynHeader, 36), and(t, 0xFF))
            mstore8(add(dynHeader, 37), and(shr(8,t), 0xFF))
            mstore8(add(dynHeader, 38), and(shr(16,t), 0xFF))

            mstore8(add(dynHeader, 72), and(length, 0xFF))
            mstore8(add(dynHeader, 73), and(shr(8,length), 0xFF))
            mstore8(add(dynHeader, 74), and(shr(16, length), 0xFF))
        }

            return string(
            bytes.concat(
                'data:audio/wav;base64,',
                bytes(Base64.encode(
                    bytes.concat(
                        dynHeader,
                        _execute(musicBytecode, start, length)
                    )
                ))
            ));
	}

    function _execute(bytes memory musicBytecode, uint256 start,
		uint256 length) internal returns (bytes memory) {
        bytes memory executorCreation = hex"606d600c600039606d6000f36000358060801b806000529060801c60205260006040525b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b5b60ff9016604051806080019091905360010180604052602051600051600101806000529110601757602051806060526020016060f3";

        uint256 len = musicBytecode.length;
        uint256 mask = 256**(32 - len) - 1;
        assembly {
            let src := add(musicBytecode, 32)
            let dest := add(executorCreation, 68) // 32 + 36 where JUMPSET start (second one)
            for {} gt(len, 31) {
                len := sub(len, 32)
                dest := add(dest, 32)
                src := add(src, 32)
            } {
                mstore(dest, mload(src))
            }

            let srcpart := and(mload(src), not(mask)) // NOTE can remove that step by ensuring the length is a multiple of 32 bytes
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }


        address executor;
        assembly {
            executor := create(0, add(executorCreation, 32), mload(executorCreation))
        }
        require(executor != address(0), "CREATE_FAILS");

        (bool success, bytes memory buffer) = executor.staticcall(abi.encode(start | (length << 128)));
        require(success, 'CALL_FAILS');

        return buffer;
    }


    function _mint(uint256 id, address to) internal {
        require(to != address(0), "NOT_TO_ZEROADDRESS");
        require(to != address(this), "NOT_TO_THIS");
        address owner = _ownerOf(id);
        require(owner == address(0), "ALREADY_CREATED");
        _safeTransferFrom(address(0), to, id, "");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

abstract contract UsingERC165Internal {
	function supportsInterface(bytes4) public view virtual returns (bool) {
		return false;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../interfaces/IERC2981.sol";
import "../../ERC165/UsingERC165Internal.sol";
import "../../Guardian/libraries/Guarded.sol";

contract UsingGlobalRoyalties is IERC2981, UsingERC165Internal {
	event RoyaltySet(address receiver, uint256 royaltyPer10Thousands);
	event RoyaltyAdminSet(address newRoyaltyAdmin);

	struct Royalty {
		address receiver;
		uint96 per10Thousands;
	}

	Royalty internal _royalty;

	/// @notice address allowed to set royalty parameters
	address public royaltyAdmin;

	/// @param initialRoyaltyReceiver receiver of royalties
	/// @param imitialRoyaltyPer10Thousands amount of royalty in 10,000 basis point
	/// @param initialRoyaltyAdmin admin able to update the royalty receiver and rates
	constructor(
		address initialRoyaltyReceiver,
		uint96 imitialRoyaltyPer10Thousands,
		address initialRoyaltyAdmin
	) {
		if (initialRoyaltyAdmin != address(0)) {
			royaltyAdmin = initialRoyaltyAdmin;
			emit RoyaltyAdminSet(initialRoyaltyAdmin);
		}

		_royalty.receiver = initialRoyaltyReceiver;
		_royalty.per10Thousands = imitialRoyaltyPer10Thousands;
		emit RoyaltySet(initialRoyaltyReceiver, imitialRoyaltyPer10Thousands);
	}

	/// @notice Called with the sale price to determine how much royalty is owed and to whom.
	/// @param //id - the token queried for royalty information.
	/// @param salePrice - the sale price of the token specified by id.
	/// @return receiver - address of who should be sent the royalty payment.
	/// @return royaltyAmount - the royalty payment amount for salePrice.
	function royaltyInfo(
		uint256, /*id*/
		uint256 salePrice
	) external view returns (address receiver, uint256 royaltyAmount) {
		receiver = _royalty.receiver;
		royaltyAmount = (salePrice * uint256(_royalty.per10Thousands)) / 10000;
	}

	/// @notice set a new royalty receiver and rate, Can only be set by the `royaltyAdmin`.
	/// @param newReceiver the address that should receive the royalty proceeds.
	/// @param royaltyPer10Thousands the share of the salePrice (in 1/10000) given to the receiver.
	function setRoyaltyParameters(address newReceiver, uint96 royaltyPer10Thousands) external {
		require(msg.sender == royaltyAdmin, "NOT_AUTHORIZED");
		require(royaltyPer10Thousands <= 50, "ROYALTY_TOO_HIGH");
		if (_royalty.receiver != newReceiver || _royalty.per10Thousands != royaltyPer10Thousands) {
			_royalty.receiver = newReceiver;
			_royalty.per10Thousands = royaltyPer10Thousands;
			emit RoyaltySet(newReceiver, royaltyPer10Thousands);
		}
	}

	/**
	 * @notice set the new royaltyAdmin that can change the royalties
	 * Can only be called by the current royalty admin.
	 */
	function setRoyaltyAdmin(address newRoyaltyAdmin) external {
		require(msg.sender == royaltyAdmin || Guarded.isGuardian(msg.sender, newRoyaltyAdmin), "NOT_AUTHORIZED");
		if (royaltyAdmin != newRoyaltyAdmin) {
			royaltyAdmin = newRoyaltyAdmin;
			emit RoyaltyAdminSet(newRoyaltyAdmin);
		}
	}

	/// @notice Check if the contract supports an interface.
	/// @param id The id of the interface.
	/// @return Whether the interface is supported.
	function supportsInterface(bytes4 id) public view virtual override(IERC165, UsingERC165Internal) returns (bool) {
		return super.supportsInterface(id) || id == 0x2a55205a; /// 0x2a55205a is ERC2981 (royalty standard)
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

interface IERC2981 is IERC165 {
	function royaltyInfo(uint256 id, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

abstract contract ImplementingExternalDomainSeparator {
	function DOMAIN_SEPARATOR() public view virtual returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

abstract contract Named {
	function name() public view virtual returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../interfaces/IERC5267.sol";

abstract contract UsingERC712 is IERC5267 {}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./UsingERC712.sol";
import "./Named.sol";

abstract contract UsingERC712WithDynamicChainId is UsingERC712, Named {
	uint256 private immutable _deploymentChainId;
	bytes32 private immutable _deploymentDomainSeparator;

	constructor() {
		uint256 chainId;
		assembly {
			chainId := chainid()
		}

		_deploymentChainId = chainId;
		_deploymentDomainSeparator = _calculateDomainSeparator(chainId);
	}

	function _currentDomainSeparator() internal view returns (bytes32) {
		uint256 chainId;
		assembly {
			chainId := chainid()
		}

		// in case a fork happen, to support the chain that had to change its chainId, we compute the domain operator
		return chainId == _deploymentChainId ? _deploymentDomainSeparator : _calculateDomainSeparator(chainId);
	}

	/// @dev Calculate the Domain Separator used to compute ERC712 hash
	function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
		return
			keccak256(
				abi.encode(
					keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)"),
					keccak256(bytes(name())),
					chainId,
					address(this)
				)
			);
	}

	function eip712Domain()
		external
		view
		virtual
		override
		returns (
			bytes1,
			string memory,
			string memory,
			uint256,
			address,
			bytes32,
			uint256[] memory
		)
	{
		uint256 chainId;
		assembly {
			chainId := chainid()
		}
		// 0x0D == 01101 (name, , chainId, verifyingContract)
		return (0x0D, name(), "", chainId, address(this), bytes32(0), new uint256[](0));
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IERC5267 {
	function eip712Domain()
		external
		view
		returns (
			bytes1 fields,
			string memory name,
			string memory version,
			uint256 chainId,
			address verifyingContract,
			bytes32 salt,
			uint256[] memory extensions
		);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../../implementations/ImplementingERC721Internal.sol";
import "../../../ERC165/UsingERC165Internal.sol";
import "../interfaces/IERC4494.sol";
import "../../../ERC712/implementations/UsingERC712WithDynamicChainId.sol";
import "../../../ERC712/implementations/ImplementingExternalDomainSeparator.sol";

import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/Address.sol";

abstract contract UsingERC4494Permit is
	IERC4494,
	ImplementingERC721Internal,
	UsingERC165Internal,
	ImplementingExternalDomainSeparator,
	UsingERC712
{
	bytes32 public constant PERMIT_TYPEHASH =
		keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");
	bytes32 public constant PERMIT_FOR_ALL_TYPEHASH =
		keccak256("PermitForAll(address spender,uint256 nonce,uint256 deadline)");

	mapping(address => uint256) internal _userNonces;

	/// @notice return the account nonce, used for approvalForAll permit or other account related matter
	/// @param account the account to query
	/// @return nonce
	function nonces(address account) external view virtual returns (uint256 nonce) {
		return _userNonces[account];
	}

	/// @notice return the token nonce, used for individual approve permit or other token related matter
	/// @param id token id to query
	/// @return nonce
	function nonces(uint256 id) public view virtual returns (uint256 nonce) {
		(address owner, uint256 blockNumber) = _ownerAndBlockNumberOf(id);
		require(owner != address(0), "NONEXISTENT_TOKEN");
		return blockNumber;
	}

	/// @notice return the token nonce, used for individual approve permit or other token related matter
	/// @param id token id to query
	/// @return nonce
	function tokenNonces(uint256 id) external view returns (uint256 nonce) {
		return nonces(id);
	}

	function permit(
		address spender,
		uint256 tokenId,
		uint256 deadline,
		bytes memory sig
	) external {
		require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

		(address owner, uint256 blockNumber) = _ownerAndBlockNumberOf(tokenId);
		require(owner != address(0), "NONEXISTENT_TOKEN");

		// We use blockNumber as nonce as we already store it per tokens. It can thus act as an increasing transfer counter.
		// while technically multiple transfer could happen in the same block, the signed message would be using a previous block.
		// And the transfer would use then a more recent blockNumber, invalidating that message when transfer is executed.
		_requireValidPermit(owner, spender, tokenId, deadline, blockNumber, sig);

		_approveFor(owner, blockNumber, spender, tokenId);
	}

	function permitForAll(
		address signer,
		address spender,
		uint256 deadline,
		bytes memory sig
	) external {
		require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

		_requireValidPermitForAll(signer, spender, deadline, _userNonces[signer]++, sig);

		_setApprovalForAll(signer, spender, true);
	}

	/// @notice Check if the contract supports an interface.
	/// @param id The id of the interface.
	/// @return Whether the interface is supported.
	function supportsInterface(bytes4 id) public view virtual override(IERC165, UsingERC165Internal) returns (bool) {
		return
			super.supportsInterface(id) ||
			id == type(IERC4494).interfaceId ||
			id == type(IERC4494Alternative).interfaceId;
	}

	function DOMAIN_SEPARATOR()
		public
		view
		virtual
		override(IERC4494, ImplementingExternalDomainSeparator)
		returns (bytes32);

	// -------------------------------------------------------- INTERNAL --------------------------------------------------------------------

	function _requireValidPermit(
		address signer,
		address spender,
		uint256 id,
		uint256 deadline,
		uint256 nonce,
		bytes memory sig
	) internal view {
		bytes32 digest = keccak256(
			abi.encodePacked(
				"\x19\x01",
				DOMAIN_SEPARATOR(),
				keccak256(abi.encode(PERMIT_TYPEHASH, spender, id, nonce, deadline))
			)
		);
		require(SignatureChecker.isValidSignatureNow(signer, digest, sig), "INVALID_SIGNATURE");
	}

	function _requireValidPermitForAll(
		address signer,
		address spender,
		uint256 deadline,
		uint256 nonce,
		bytes memory sig
	) internal view {
		bytes32 digest = keccak256(
			abi.encodePacked(
				"\x19\x01",
				DOMAIN_SEPARATOR(),
				keccak256(abi.encode(PERMIT_FOR_ALL_TYPEHASH, spender, nonce, deadline))
			)
		);
		require(SignatureChecker.isValidSignatureNow(signer, digest, sig), "INVALID_SIGNATURE");
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./UsingERC4494Permit.sol";

abstract contract UsingERC4494PermitWithDynamicChainId is UsingERC4494Permit, UsingERC712WithDynamicChainId {
	function DOMAIN_SEPARATOR() public view virtual override returns (bytes32) {
		return _currentDomainSeparator();
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

interface IERC4494 is IERC165 {
	function DOMAIN_SEPARATOR() external view returns (bytes32);

	/// @notice Allows to retrieve current nonce for token
	/// @param tokenId token id
	/// @return current token nonce
	function nonces(uint256 tokenId) external view returns (uint256);

	/// @notice function to be called by anyone to approve `spender` using a Permit signature
	/// @dev Anyone can call this to approve `spender`, even a third-party
	/// @param spender the actor to approve
	/// @param tokenId the token id
	/// @param deadline the deadline for the permit to be used
	/// @param signature permit
	function permit(
		address spender,
		uint256 tokenId,
		uint256 deadline,
		bytes memory signature
	) external;
}

interface IERC4494Alternative is IERC165 {
	function DOMAIN_SEPARATOR() external view returns (bytes32);

	/// @notice Allows to retrieve current nonce for token
	/// @param tokenId token id
	/// @return current token nonce
	function tokenNonces(uint256 tokenId) external view returns (uint256);

	/// @notice function to be called by anyone to approve `spender` using a Permit signature
	/// @dev Anyone can call this to approve `spender`, even a third-party
	/// @param spender the actor to approve
	/// @param tokenId the token id
	/// @param deadline the deadline for the permit to be used
	/// @param signature permit
	function permit(
		address spender,
		uint256 tokenId,
		uint256 deadline,
		bytes memory signature
	) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./ImplementingERC721Internal.sol";

abstract contract ERC721 is IERC721, ImplementingERC721Internal {
	using Address for address;

	bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;
	bytes4 internal constant ERC165ID = 0x01ffc9a7;

	uint256 internal constant OPERATOR_FLAG = 0x8000000000000000000000000000000000000000000000000000000000000000;
	uint256 internal constant NOT_OPERATOR_FLAG = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

	mapping(uint256 => uint256) internal _owners;
	mapping(address => uint256) internal _balances;
	mapping(address => mapping(address => bool)) internal _operatorsForAll;
	mapping(uint256 => address) internal _operators;

	/// @notice Approve an operator to transfer a specific token on the senders behalf.
	/// @param operator The address receiving the approval.
	/// @param id The id of the token.
	function approve(address operator, uint256 id) external override {
		(address owner, uint256 blockNumber) = _ownerAndBlockNumberOf(id);
		require(owner != address(0), "NONEXISTENT_TOKEN");
		require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "UNAUTHORIZED_APPROVAL");
		_approveFor(owner, blockNumber, operator, id);
	}

	/// @notice Transfer a token between 2 addresses.
	/// @param from The sender of the token.
	/// @param to The recipient of the token.
	/// @param id The id of the token.
	function transferFrom(
		address from,
		address to,
		uint256 id
	) external override {
		(address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
		require(owner != address(0), "NONEXISTENT_TOKEN");
		require(owner == from, "NOT_OWNER");
		require(to != address(0), "NOT_TO_ZEROADDRESS");
		require(to != address(this), "NOT_TO_THIS");
		if (msg.sender != from) {
			require(
				(operatorEnabled && _operators[id] == msg.sender) || isApprovedForAll(from, msg.sender),
				"UNAUTHORIZED_TRANSFER"
			);
		}
		_transferFrom(from, to, id);
	}

	/// @notice Transfer a token between 2 addresses letting the receiver know of the transfer.
	/// @param from The send of the token.
	/// @param to The recipient of the token.
	/// @param id The id of the token.
	function safeTransferFrom(
		address from,
		address to,
		uint256 id
	) external override {
		safeTransferFrom(from, to, id, "");
	}

	/// @notice Set the approval for an operator to manage all the tokens of the sender.
	/// @param operator The address receiving the approval.
	/// @param approved The determination of the approval.
	function setApprovalForAll(address operator, bool approved) external override {
		_setApprovalForAll(msg.sender, operator, approved);
	}

	/// @notice Get the number of tokens owned by an address.
	/// @param owner The address to look for.
	/// @return balance The number of tokens owned by the address.
	function balanceOf(address owner) public view override returns (uint256 balance) {
		require(owner != address(0), "ZERO_ADDRESS_OWNER");
		balance = _balances[owner];
	}

	/// @notice Get the owner of a token.
	/// @param id The id of the token.
	/// @return owner The address of the token owner.
	function ownerOf(uint256 id) external view override returns (address owner) {
		owner = _ownerOf(id);
		require(owner != address(0), "NONEXISTENT_TOKEN");
	}

	/// @notice Get the owner of a token and the blockNumber of the last transfer, useful to voting mechanism.
	/// @param id The id of the token.
	/// @return owner The address of the token owner.
	/// @return blockNumber The blocknumber at which the last transfer of that id happened.
	function ownerAndLastTransferBlockNumberOf(uint256 id) internal view returns (address owner, uint256 blockNumber) {
		return _ownerAndBlockNumberOf(id);
	}

	struct OwnerData {
		address owner;
		uint256 lastTransferBlockNumber;
	}

	/// @notice Get the list of owner of a token and the blockNumber of its last transfer, useful to voting mechanism.
	/// @param ids The list of token ids to check.
	/// @return ownersData The list of (owner, lastTransferBlockNumber) for each ids given as input.
	function ownerAndLastTransferBlockNumberList(uint256[] calldata ids)
		external
		view
		returns (OwnerData[] memory ownersData)
	{
		ownersData = new OwnerData[](ids.length);
		for (uint256 i = 0; i < ids.length; i++) {
			uint256 data = _owners[ids[i]];
			ownersData[i].owner = address(uint160(data));
			ownersData[i].lastTransferBlockNumber = (data >> 160) & 0xFFFFFFFFFFFFFFFFFFFFFF;
		}
	}

	/// @notice Get the approved operator for a specific token.
	/// @param id The id of the token.
	/// @return The address of the operator.
	function getApproved(uint256 id) external view override returns (address) {
		(address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
		require(owner != address(0), "NONEXISTENT_TOKEN");
		if (operatorEnabled) {
			return _operators[id];
		} else {
			return address(0);
		}
	}

	/// @notice Check if the sender approved the operator.
	/// @param owner The address of the owner.
	/// @param operator The address of the operator.
	/// @return isOperator The status of the approval.
	function isApprovedForAll(address owner, address operator) public view virtual override returns (bool isOperator) {
		return _operatorsForAll[owner][operator];
	}

	/// @notice Transfer a token between 2 addresses letting the receiver knows of the transfer.
	/// @param from The sender of the token.
	/// @param to The recipient of the token.
	/// @param id The id of the token.
	/// @param data Additional data.
	function safeTransferFrom(
		address from,
		address to,
		uint256 id,
		bytes memory data
	) public override {
		(address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
		require(owner != address(0), "NONEXISTENT_TOKEN");
		require(owner == from, "NOT_OWNER");
		require(to != address(0), "NOT_TO_ZEROADDRESS");
		require(to != address(this), "NOT_TO_THIS");
		if (msg.sender != from) {
			require(
				(operatorEnabled && _operators[id] == msg.sender) || isApprovedForAll(from, msg.sender),
				"UNAUTHORIZED_TRANSFER"
			);
		}
		_safeTransferFrom(from, to, id, data);
	}

	/// @notice Check if the contract supports an interface.
	/// @param id The id of the interface.
	/// @return Whether the interface is supported.
	function supportsInterface(bytes4 id) public view virtual override returns (bool) {
		/// 0x01ffc9a7 is ERC165.
		/// 0x80ac58cd is ERC721
		/// 0x5b5e139f is for ERC721 metadata
		return id == 0x01ffc9a7 || id == 0x80ac58cd || id == 0x5b5e139f;
	}

	function tokenURI(uint256 id) external view virtual returns (string memory);

	function _safeTransferFrom(
		address from,
		address to,
		uint256 id,
		bytes memory data
	) internal {
		_transferFrom(from, to, id);
		if (to.isContract()) {
			require(_checkOnERC721Received(msg.sender, from, to, id, data), "ERC721_TRANSFER_REJECTED");
		}
	}

	function _transferFrom(
		address from,
		address to,
		uint256 id
	) internal {
		unchecked {
			_balances[to]++;
			if (from != address(0)) {
				_balances[from]--;
			}
		}
		_owners[id] = (block.number << 160) | uint256(uint160(to));
		emit Transfer(from, to, id);
	}

	/// @dev See approve.
	function _approveFor(
		address owner,
		uint256 blockNumber,
		address operator,
		uint256 id
	) internal override {
		if (operator == address(0)) {
			_owners[id] = (blockNumber << 160) | uint256(uint160(owner));
		} else {
			_owners[id] = OPERATOR_FLAG | (blockNumber << 160) | uint256(uint160(owner));
			_operators[id] = operator;
		}
		emit Approval(owner, operator, id);
	}

	/// @dev See setApprovalForAll.
	function _setApprovalForAll(
		address sender,
		address operator,
		bool approved
	) internal override {
		_operatorsForAll[sender][operator] = approved;

		emit ApprovalForAll(sender, operator, approved);
	}

	/// @dev Check if receiving contract accepts erc721 transfers.
	/// @param operator The address of the operator.
	/// @param from The from address, may be different from msg.sender.
	/// @param to The adddress we want to transfer to.
	/// @param id The id of the token we would like to transfer.
	/// @param _data Any additional data to send with the transfer.
	/// @return Whether the expected value of 0x150b7a02 is returned.
	function _checkOnERC721Received(
		address operator,
		address from,
		address to,
		uint256 id,
		bytes memory _data
	) internal returns (bool) {
		bytes4 retval = IERC721Receiver(to).onERC721Received(operator, from, id, _data);
		return (retval == ERC721_RECEIVED);
	}

	/// @dev See ownerOf
	function _ownerOf(uint256 id) internal view returns (address owner) {
		return address(uint160(_owners[id]));
	}

	/// @dev Get the owner and operatorEnabled status of a token.
	/// @param id The token to query.
	/// @return owner The owner of the token.
	/// @return operatorEnabled Whether or not operators are enabled for this token.
	function _ownerAndOperatorEnabledOf(uint256 id) internal view returns (address owner, bool operatorEnabled) {
		uint256 data = _owners[id];
		owner = address(uint160(data));
		operatorEnabled = (data & OPERATOR_FLAG) == OPERATOR_FLAG;
	}

	// @dev Get the owner and operatorEnabled status of a token.
	/// @param id The token to query.
	/// @return owner The owner of the token.
	/// @return blockNumber the blockNumber at which the owner became the owner (last transfer).
	function _ownerAndBlockNumberOf(uint256 id) internal view override returns (address owner, uint256 blockNumber) {
		uint256 data = _owners[id];
		owner = address(uint160(data));
		blockNumber = (data >> 160) & 0xFFFFFFFFFFFFFFFFFFFFFF;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

abstract contract ImplementingERC721Internal {
	function _ownerAndBlockNumberOf(uint256 id) internal view virtual returns (address owner, uint256 blockNumber);

	function _approveFor(
		address owner,
		uint256 blockNumber,
		address operator,
		uint256 id
	) internal virtual;

	function _setApprovalForAll(
		address sender,
		address operator,
		bool approved
	) internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../../Guardian/libraries/Guarded.sol";

contract UsingExternalMinter {
	event MinterAdminSet(address newMinterAdmin);
	event MinterSet(address newMinter);

	/// @notice minterAdmin can update the minter. At the time being there is 576 Bleeps but there is space for extra instrument and the upper limit is 1024.
	/// could be given to the DAO later so instrument can be added, the sale of these new bleeps could benenfit the DAO too and add new members.
	address public minterAdmin;

	/// @notice address allowed to mint, allow the sale contract to be separated from the token contract that can focus on the core logic
	/// Once all 1024 potential bleeps (there could be less, at minimum there are 576 bleeps) are minted, no minter can mint anymore
	address public minter;

	constructor(address initialMinterAdmin) {
		if (initialMinterAdmin != address(0)) {
			minterAdmin = initialMinterAdmin;
			emit MinterAdminSet(initialMinterAdmin);
		}
	}

	/**
	 * @notice set the new minterAdmin that can set the minter for Bleeps
	 * Can only be called by the current minter admin.
	 */
	function setMinterAdmin(address newMinterAdmin) external {
		require(msg.sender == minterAdmin || Guarded.isGuardian(msg.sender, newMinterAdmin), "NOT_AUTHORIZED");
		if (newMinterAdmin != minterAdmin) {
			minterAdmin = newMinterAdmin;
			emit MinterAdminSet(newMinterAdmin);
		}
	}

	/**
	 * @notice set the new minter that can mint
	 * Can only be called by the minter admin.
	 */
	function setMinter(address newMinter) external {
		require(msg.sender == minterAdmin, "NOT_AUTHORIZED");
		if (minter != newMinter) {
			minter = newMinter;
			emit MinterSet(newMinter);
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract UsingGuardian {
	event GuardianSet(address newGuardian);

	// bytes32 GUARDIAN_SLOT = bytes32(uint256(keccak256('guardian')) - 1); // 0x8fbcb4375b910093bcf636b6b2f26b26eda2a29ef5a8ee7de44b5743c3bf9a27

	constructor(address initialGuardian) {
		if (initialGuardian != address(0)) {
			assembly {
				sstore(0x8fbcb4375b910093bcf636b6b2f26b26eda2a29ef5a8ee7de44b5743c3bf9a27, initialGuardian)
			}
			emit GuardianSet(initialGuardian);
		}
	}

	/// @notice guardian has some special vetoing power to guide the direction of the DAO. It can only remove rights from the DAO. It could be used to immortalize rules.
	/// For example: the royalty setup could be frozen.
	function guardian() external view returns (address g) {
		assembly {
			g := sload(0x8fbcb4375b910093bcf636b6b2f26b26eda2a29ef5a8ee7de44b5743c3bf9a27)
		}
	}

	/**
	 * @notice set the new guardian that can freeze the other admins (except owner).
	 * Can only be called by the current guardian.
	 */
	function setGuardian(address newGuardian) external {
		address currentGuardian;
		assembly {
			currentGuardian := sload(0x8fbcb4375b910093bcf636b6b2f26b26eda2a29ef5a8ee7de44b5743c3bf9a27)
		}
		require(msg.sender == currentGuardian, "NOT_AUTHORIZED");
		if (currentGuardian != newGuardian) {
			assembly {
				sstore(0x8fbcb4375b910093bcf636b6b2f26b26eda2a29ef5a8ee7de44b5743c3bf9a27, newGuardian)
			}
			emit GuardianSet(newGuardian);
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

library Guarded {
	function isGuardian(address sender, address newValue) internal view returns (bool) {
		address guardian;
		assembly {
			guardian := sload(0x8fbcb4375b910093bcf636b6b2f26b26eda2a29ef5a8ee7de44b5743c3bf9a27)
		}
		return guardian != address(0) && sender == guardian && newValue == address(0);
	}

	function isGuardian(address sender, uint256 newValue) internal view returns (bool) {
		address guardian;
		assembly {
			guardian := sload(0x8fbcb4375b910093bcf636b6b2f26b26eda2a29ef5a8ee7de44b5743c3bf9a27)
		}
		return guardian != address(0) && sender == guardian && newValue == 0;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";

contract UsingMulticall {
	using Address for address;

	// from https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol
	/// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed.
	/// @dev The `msg.value` should not be trusted for any method callable from multicall.
	/// @param data The encoded function data for each of the calls to make to this contract.
	/// @return results The results from each of the calls passed in via data.
	function multicall(bytes[] calldata data) public payable returns (bytes[] memory results) {
		results = new bytes[](data.length);
		for (uint256 i = 0; i < data.length; i++) {
			(bool success, bytes memory result) = address(this).delegatecall(data[i]);

			if (!success) {
				// Next 5 lines from https://ethereum.stackexchange.com/a/83577
				if (result.length < 68) revert();
				assembly {
					result := add(result, 0x04)
				}
				revert(abi.decode(result, (string)));
			}

			results[i] = result;
		}
	}
}
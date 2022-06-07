/**
 *Submitted for verification at Etherscan.io on 2022-06-06
*/

// File: @openzeppelin/contracts/interfaces/IERC1271.sol


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

// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: @openzeppelin/contracts/utils/cryptography/ECDSA.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

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

// File: @openzeppelin/contracts/utils/cryptography/SignatureChecker.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;




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
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
    }
}

// File: @openzeppelin/contracts/utils/Multicall.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;


/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
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


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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

// File: storefront/first_sale_storefront/FirstSaleStorefrontERC721.sol



pragma solidity ^0.8.0;






interface IToken is IERC721 {
    function owner() external view returns (address);

    function mint(address to, uint256 tokenId) external;
}

/**
 * Storeforn Sales contract. Corresponding NFT contract must be compatible with Storefront.
 * It allows to setup sales logic flexibly. Supports fixed price sale, dutch auction and various
 * whitelists. Sends payouts to NFT creators directly in buy transction, so funds are not accumulated
 * on the contract.
 */
contract FirstSaleStorfrontERC721 is Pausable, Multicall {
    struct Payout {
        address recipient;
        uint256 share;
    }

    struct Payouts {
        uint256 count;
        Payout[] payoutList;
    }

    struct ConfinesForTime {
        uint256 startTimestampInSeconds;
        uint256 endTimestampInSeconds;
    }

    enum ConfinesForTokensKind {
        NONE,
        LIST,
        INTERVAL
    }

    struct ListConfinesForTokens {
        uint256 count;
        uint256[] tokenIdList;
    }

    struct IntervalConfinesForTokens {
        uint256 startOfInterval;
        uint256 endOfInterval;
    }

    struct SignConfinesForCustomers {
        address key;
        uint128 kind;
    }

    struct TokenConfinesForCustomers {
        uint256 count;
        address token;
        uint256[] tokenIdList;
    }

    struct TokenListConfinesForCustomers {
        uint256 count;
        TokenConfinesForCustomers[] confineList;
    }

    enum SaleKind {
        NONE,
        PURCHASE,
        DUTCH_AUCTION
    }

    struct Purchase {
        uint256 price;
    }

    struct DutchAuction {
        uint256 tickCount;
        uint256 startPrice;
        uint256 priceLossPerTick;
        uint256 tickSizeInSeconds;
        uint256 startTimestampInSeconds;
    }

    struct Sale {
        SaleKind kind;
        address payToken;
        address payRecipient;
        Purchase purchase;
        DutchAuction dutchAuction;
    }

    uint256 public constant SHARE = 100_000; //100% = 100_000

    /**
     * @dev The address of the token
     */
    IToken public token;

    /**
     * @dev The scheme of payouts to NFT creators
     */
    Payouts public payouts;

    /**
     * @dev The time restrictions for NFT sale
     */
    ConfinesForTime public confinesForTime;

    /**
     * @dev List of tokens that can be sold on this sale
     */
    ListConfinesForTokens public listConfinesForTokens;
    /**
     * @dev Interval of tokens by ID that can be sold on this sale
     */
    IntervalConfinesForTokens public intervalConfinesForTokens;
    /**
     * @dev Whitelist by signature restrictions for the sale
     */
    SignConfinesForCustomers public signConfinesForCustomers;
    /**
     * @dev Whitelist by access token restrictions for the sale
     */
    TokenListConfinesForCustomers public tokenListConfinesForCustomers;
    /**
     * @dev Sale conditions
     */
    Sale public sale;

    modifier onlyTokenOwner() {
        if (_msgSender() != token.owner()) {
            revert(""); //todo
        }
        _;
    }

    /**
     * @dev Initialize the contract
     * @param token_ The address of NFT token being sold
     */
    constructor(IToken token_) {
        token = token_;
    }
    
    /**
     * @dev Returns token restriction type
     * @return It can be eiser list, interval or none restrictions.
     */
    function confinesForTokensKind()
        public
        view
        returns (ConfinesForTokensKind)
    {
        if (listConfinesForTokens.count == 0) {
            return ConfinesForTokensKind.LIST;
        }

        if (
            intervalConfinesForTokens.startOfInterval ==
            intervalConfinesForTokens.endOfInterval
        ) {
            return ConfinesForTokensKind.INTERVAL;
        }

        return ConfinesForTokensKind.NONE;
    }

    /**
     * @dev Check if signature whitelist restrictions on customer were set
     * @return True if restrictions imposed, false otherwise
     */
    function isSignConfinesForCustomersSet() public view returns (bool) {
        return signConfinesForCustomers.key != address(0);
    }

    /**
     * @dev Check if token access restrictions on customer were set
     * @return True if restrictions imposed, false otherwise
     */
    function isTokenListConfinesForCustomersSet()
        public
        view
        returns (bool)
    {
        return tokenListConfinesForCustomers.count != 0;
    }

    /**
     * @dev Calculate the price of the token in the given timestamp
     * @dev If the sale if fixed price, then returns constant. In the case of
     * @dev dutch auction sale, calculates price according to the logic of auction
     * @param timestampInSeconds The timestamp when the price should be calculated
     */
    function priceOf(uint256 timestampInSeconds) public view returns (uint256) {
        if (sale.kind == SaleKind.PURCHASE) {
            return sale.purchase.price;
        }

        if (sale.kind == SaleKind.DUTCH_AUCTION) {
            DutchAuction storage auction = sale.dutchAuction;

            if (timestampInSeconds < auction.startTimestampInSeconds) {
                return auction.startPrice;
            }

            uint256 currentTick = 1 +
                (timestampInSeconds - auction.startTimestampInSeconds) /
                auction.tickSizeInSeconds;

            uint256 tick = auction.tickCount < currentTick
                ? auction.tickCount
                : currentTick;

            return auction.startPrice - tick * auction.priceLossPerTick;
        }

        return 0;
    }

    /**
     * @dev Pause contract. Admin method.
     */
    function pause() external onlyTokenOwner {
        _pause();
    }

    /**
     * @dev Unpause contract. Admin method.
     */
    function unpause() external onlyTokenOwner {
        _unpause();
    }

    /**
     * @dev Set addresses and their shares for the payouts.
     */
    function setPayouts(
        address[] calldata recipients,
        uint256[] calldata shares
    ) external onlyTokenOwner {
        if (recipients.length == 0) {
            revert("Can't set payouts to 0 addresses");
        }
        if (recipients.length != shares.length) {
            revert("Address list and shares list must be of the same length");
        }

        //TODO: add check that payout shares sums up to 1

        Payout[] storage payoutList = payouts.payoutList;

        uint256 length = payoutList.length < recipients.length
            ? payoutList.length
            : recipients.length;

        if (0 < length) {
            for (uint256 i = 0; i < length; ++i) {
                Payout storage payout = payoutList[i];
                payout.recipient = recipients[i];
                payout.share = shares[i];
            }
        }

        if (length < recipients.length) {
            for (uint256 i = 1 + length; i < recipients.length; ++i) {
                payoutList.push(Payout(recipients[i], shares[i]));
            }
        }
    }

    /**
     * @dev Remove time conditions for sale. Admin method
     */
    function turnOffConfinesForTime() external onlyTokenOwner {
        _setConfinesForTime(0, 0);
    }

    /**
     * @dev Set start time and end time for sale. Admin method
     * @param startTimestampInSeconds The timestamp for sale start
     * @param endTimestampInSeconds The timestamp for sale end
     */
    function setConfinesForTime(
        uint256 startTimestampInSeconds,
        uint256 endTimestampInSeconds
    ) external onlyTokenOwner {
        _setConfinesForTime(startTimestampInSeconds, endTimestampInSeconds);
    }

    /**
     * @dev Set start time and end time for sale. Private method
     * @param startTimestampInSeconds The timestamp for sale start
     * @param endTimestampInSeconds The timestamp for sale end
     */
    function _setConfinesForTime(
        uint256 startTimestampInSeconds,
        uint256 endTimestampInSeconds
    ) private {
        confinesForTime.startTimestampInSeconds = startTimestampInSeconds;
        confinesForTime.endTimestampInSeconds = endTimestampInSeconds;
    }

    /**
     * @dev Remove token conditions for sale. Admin method
     */
    function turnOffConfinesForTokens() external onlyTokenOwner {
        listConfinesForTokens.count = 0;
        _setIntervalConfinesForTokens(0, 0);
    }

    /**
     * @dev Set the list of tokens by ID listed for sale. Admin method
     * @param tokenIdList The list of token IDs
     */
    function setListConfinesForTokens(uint256[] memory tokenIdList)
        external
        onlyTokenOwner
    {
        _setIntervalConfinesForTokens(0, 0);

        listConfinesForTokens.count = tokenIdList.length;

        uint256[] storage idList = listConfinesForTokens.tokenIdList;

        uint256 length = idList.length < tokenIdList.length
            ? idList.length
            : tokenIdList.length;

        if (0 < length) {
            for (uint256 i = 0; i < length; ++i) {
                idList[i] = tokenIdList[i];
            }
        }

        if (length < tokenIdList.length) {
            for (uint256 i = 1 + length; i < tokenIdList.length; ++i) {
                idList.push(tokenIdList[i]);
            }
        }
    }

    /**
     * @dev Set interval of tokens by ID listed for sale. Admin method
     * @param startOfInterval The ID of the first token being sold
     * @param endOfInterval The ID of the last token being sold
     */
    function setIntervalConfinesForTokens(
        uint256 startOfInterval,
        uint256 endOfInterval
    ) external onlyTokenOwner {
        if (endOfInterval <= startOfInterval) {
            revert("");
        }

        listConfinesForTokens.count = 0;
        _setIntervalConfinesForTokens(startOfInterval, endOfInterval);
    }

    /**
     * @dev Set interval of tokens by ID listed for sale. Private method
     * @param startOfInterval The ID of the first token being sold
     * @param endOfInterval The ID of the last token being sold
     */
    function _setIntervalConfinesForTokens(
        uint256 startOfInterval,
        uint256 endOfInterval
    ) private {
        intervalConfinesForTokens.startOfInterval = startOfInterval;
        intervalConfinesForTokens.endOfInterval = endOfInterval;
    }

    /**
     * @dev Remove customers' signature whitelist restrictions for sale. Admin method
     */
    function turnOffSignConfinesForCustomers() external onlyTokenOwner {
        _setSignConfinesForCustomers(address(0), 0);
    }

    /**
     * @dev Set the whitelist sale, defining nonce and pubkey for whitelist's signature check. Admin method
     * @param key The address for signature checking
     * @param kind The number (or nonce) of the whitelist. Prohibits reusage of old signatures.
     */
    function setSignConfinesForCustomers(address key, uint128 kind)
        external
        onlyTokenOwner
    {
        if (key == address(0)) {
            revert("");
        }

        _setSignConfinesForCustomers(key, kind);
    }

    /**
     * @dev Set the whitelist sale, defining nonce and pubkey for whitelist's signature check. Private method
     * @param key The address for signature checking
     * @param kind The number (or nonce) of the whitelist. Prohibits reusage of old signatures.
     */
    function _setSignConfinesForCustomers(address key, uint128 kind) private {
        signConfinesForCustomers.key = key;
        signConfinesForCustomers.kind = kind;
    }

    /**
     * @dev Remove customers' access token restrictions for sale. Admin method
     */
    function turnOffTokenListConfinesForCustomers() external onlyTokenOwner {
        tokenListConfinesForCustomers.count = 0;
    }

    /**
     * @dev Set the whitelist based on the possession criteria of other NFT(s). Admin method
     * @param tokenList The list of access token addresses
     * @param tokenIdList The 2D array of tokens' ID's used as access to the whitelist
     */
    function setTokenListConfinesForCustomers(
        address[] calldata tokenList,
        uint256[][] calldata tokenIdList
    ) external onlyTokenOwner {
        if (tokenList.length == 0) {
            revert("List of tokens can't be empty");
        }

        if (tokenList.length != tokenIdList.length) {
            revert("Lists must be of the same length");
        }

        tokenListConfinesForCustomers.count = tokenList.length;

        TokenConfinesForCustomers[]
            storage confineList = tokenListConfinesForCustomers.confineList;

        uint256 length = confineList.length < tokenList.length
            ? confineList.length
            : tokenList.length;

        if (0 < length) {
            for (uint256 i = 0; i < length; ++i) {
                uint256[] calldata idList = tokenIdList[i];

                TokenConfinesForCustomers storage confine = confineList[i];
                confine.count = idList.length;
                confine.token = tokenList[i];

                uint256[] storage ids = confine.tokenIdList;

                uint256 le = ids.length < idList.length
                    ? ids.length
                    : idList.length;

                if (0 < le) {
                    for (uint256 j = 0; j < le; ++j) {
                        ids[j] = idList[j];
                    }
                }

                if (le < idList.length) {
                    for (uint256 j = 1 + le; j < idList.length; ++j) {
                        ids.push(idList[j]);
                    }
                }
            }
        }

        if (length < tokenList.length) {
            for (uint256 i = 1 + length; i < tokenList.length; ++i) {
                uint256[] calldata idList = tokenIdList[i];
                confineList.push(
                    TokenConfinesForCustomers(
                        idList.length,
                        tokenList[i],
                        idList
                    )
                );
            }
        }
    }

    /**
     * @dev Remove sale conditions. Effectively stops the sale. Admin method
     */
    function turnOffSale() external onlyTokenOwner {
        sale.kind = SaleKind.NONE;
    }

    /**
     * @dev Set the purchase logic for fixed price sale. Admin method
     * @param payToken The address of payment ERC-20 currency.
     * @param payRecipient The address of payments recipient.
     * @param price The price for token sale.
     */
    function setPurchase(
        address payToken,
        address payRecipient,
        uint256 price
    ) external onlyTokenOwner {
        sale.kind = SaleKind.PURCHASE;

        sale.payToken = payToken;
        sale.payRecipient = payRecipient;

        sale.purchase.price = price;
    }

    /**
     * @dev Set the Dutch auction purchase logic (the price linearly decays with time). Admin method
     * @param payToken The address of payment ERC-20 currency.
     * @param payRecipient The address of payments recipient.
     * @param startPrice The largest price for token sale.
     * @param startPrice The lowest price for token sale.
     * @param tickSizeInSeconds Size of the step when price is recalculated, in seconds
     */
    function setDutchAuction(
        address payToken,
        address payRecipient,
        uint256 startPrice,
        uint256 priceLossPerTick,
        uint256 tickSizeInSeconds,
        uint256 startTimestampInSeconds
    ) external onlyTokenOwner {
        sale.kind = SaleKind.DUTCH_AUCTION;

        sale.payToken = payToken;
        sale.payRecipient = payRecipient;

        DutchAuction storage dutchAuction = sale.dutchAuction;
        dutchAuction.startPrice = startPrice;
        dutchAuction.priceLossPerTick = priceLossPerTick;
        dutchAuction.tickSizeInSeconds = tickSizeInSeconds;
        dutchAuction.startTimestampInSeconds = startTimestampInSeconds;
    }

    /**
     * @dev Buy method. Called by customer to buy specific token, regardless type of the sale.
     * @param id Id of the token that customer is willing to buy.
     * @param tokenIdList The IDs of the access token, if any. Can be set to 0, if not used.
     * @param sign Signature that proves user's participation in whitelist.
     */
    function buy(
        uint256 id,
        bytes calldata sign,
        uint256[] calldata tokenIdList
    ) external payable whenNotPaused {
        if (sale.kind == SaleKind.NONE) {
            revert("");
        }

        address sender = _msgSender();

        _checkConfinesForTime(block.timestamp);
        _checkConfinesForTokens(id);
        _checkConfinesForCustomers(sender, sign, tokenIdList);

        _pay(sender, block.timestamp, msg.value);

        token.mint(sender, id);
    }

    /**
     * @dev Check if the given timestamp is within sales timeframe. Reverts in case of failure. Internal function
     * @param timestampIsSeconds The timestamp being tested
     */
    function _checkConfinesForTime(uint256 timestampIsSeconds) private view {
        if (
            confinesForTime.startTimestampInSeconds != 0 &&
            timestampIsSeconds < confinesForTime.startTimestampInSeconds
        ) {
            revert("Timestamp is out of the sales timeframe"); //todo
        }

        if (
            confinesForTime.endTimestampInSeconds != 0 &&
            confinesForTime.endTimestampInSeconds <= timestampIsSeconds
        ) {
            revert("Timestamp is out of the sales timeframe"); //todo
        }
    }

    /**
     * @dev Check if the given token Id is listed for sale. Reverts in case of failure. Internal function.
     * @param id The Id of token being tested
     */
    function _checkConfinesForTokens(uint256 id) private view {
        ConfinesForTokensKind kind = confinesForTokensKind();

        if (
            kind == ConfinesForTokensKind.INTERVAL &&
            (id < intervalConfinesForTokens.startOfInterval ||
                intervalConfinesForTokens.endOfInterval <= id)
        ) {
            revert("Token is not lisetd for sale"); //todo
        }

        if (
            kind == ConfinesForTokensKind.LIST &&
            !_isInclude(
                listConfinesForTokens.count,
                listConfinesForTokens.tokenIdList,
                id
            )
        ) {
            revert("Token is not lisetd for sale"); //todo
        }
    }

    /**
     * @dev Check if the given customer is authorized to buy. Reverts in case of failure. Private function
     * @param sender The address of potential buyer
     * @param sign Whitelist authorization signature
     * @param tokenIdList The list of IDs of access tokens
     */
    //TODO: token list must follow logic at least one, not all of them?
    function _checkConfinesForCustomers(
        address sender,
        bytes calldata sign,
        uint256[] calldata tokenIdList
    ) private view {
        if (
            isSignConfinesForCustomersSet() &&
            !SignatureChecker.isValidSignatureNow(
                signConfinesForCustomers.key,
                _signHash(sender),
                sign
            )
        ) {
            revert("not authorized");
        }

        if (isTokenListConfinesForCustomersSet()) {
            if (tokenListConfinesForCustomers.count != tokenIdList.length) {
                revert("lists sizes do not match");
            }

            TokenConfinesForCustomers[]
                storage confineList = tokenListConfinesForCustomers.confineList;
            for (uint256 i = 0; i < tokenListConfinesForCustomers.count; ++i) {
                TokenConfinesForCustomers storage confine = confineList[i];

                uint256 id = tokenIdList[i];
                if (sender != IToken(confine.token).ownerOf(id)) {
                    revert("not authorized");
                }

                if (confine.count == 0) {
                    continue;
                }

                if (!_isInclude(confine.count, confine.tokenIdList, id)) {
                    revert("not authorized");
                }
            }
        }
    }

    /**
     * @dev Performs payment in a given timestamp. Refund customer with change in case of Dutch auction.
     * @dev Private function
     * @param sender The address of potential buyer
     * @param timestamp The timestamp for price calculation
     * @param coinValue size of the payment.
     */
    function _pay(
        address sender,
        uint256 timestamp,
        uint256 coinValue
    ) private {
        uint256 price = priceOf(timestamp);
        uint256 ownerAmount = price;

        Payout[] storage payoutList = payouts.payoutList;
        if (sale.payToken != address(0)) {
            IERC20 t = IERC20(sale.payToken);

            for (uint256 i = 0; i < payouts.count; ++i) {
                Payout storage payout = payoutList[i];

                uint256 amount = (price * payout.share) / SHARE;
                t.transferFrom(sender, payout.recipient, amount);

                ownerAmount -= amount;
            }

            t.transferFrom(sender, sale.payRecipient, ownerAmount);
        } else {
            if (coinValue < price) {
                revert("payment not enough");
            }

            for (uint256 i = 0; i < payouts.count; ++i) {
                Payout storage payout = payoutList[i];

                uint256 amount = (price * payout.share) / SHARE;
                _sendCoin(payout.recipient, amount);
                coinValue -= amount;

                ownerAmount -= amount;
            }

            _sendCoin(sale.payRecipient, ownerAmount);
            coinValue -= ownerAmount;
        }

        if (coinValue != 0) {
            _sendCoin(sender, coinValue);
        }
    }

    /**
     * @dev check if the element in the array prefix
     * @dev private function
     * @param count The size of the prefix
     * @param array The array
     * @param element The element being searched
     */
    function _isInclude(
        uint256 count,
        uint256[] storage array,
        uint256 element
    ) private view returns (bool) {
        for (uint256 i = 0; i < count; ++i) {
            if (element == array[i]) {
                return true;
            }
        }

        return false;
    }

    /**
     * @dev Builds the hash for signature check
     * @dev private function
     * @param sender The address of user in whitelist
     * @return Hash that is signed to prove customer inclusion in whitelist
     */
    function _signHash(address sender) private view returns (bytes32) {
        return
            keccak256(
                abi.encodeWithSignature(
                    "SignHash(address,address,uin128)",
                    sender,
                    address(token),
                    signConfinesForCustomers.kind
                )
            );
    }

    /**
     * @dev Sends ETH. Reverts in case of paymet failure. Prevents callbacks from ETH transfer.
     * @dev private function
     * @param recipient The address of payment recipient
     * @param amount The amount of payment
     */
    function _sendCoin(address recipient, uint256 amount) private {
        (bool success, ) = recipient.call{value: amount}("");

        if (!success) {
            revert("ETH transfer failed"); //todo
        }
    }
}
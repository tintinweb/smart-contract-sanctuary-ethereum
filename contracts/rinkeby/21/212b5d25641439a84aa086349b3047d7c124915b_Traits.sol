/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// Sources flattened with hardhat v2.8.2 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

// SPDX-License-Identifier: MIT

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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


// File @openzeppelin/contracts/security/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/utils/cryptography/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

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


// File base64-sol/[email protected]


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


// File contracts/Traits.sol


pragma solidity ^0.8.7;


interface IWacky {
    function balanceOf(address account) external view returns (uint256);
    function burn(address from, uint256 amount) external;
    function mint(address to, uint256 amount) external;
}

interface IHero {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract Traits is Ownable, ReentrancyGuard {
    using Address for address;
    using ECDSA for bytes32;
    using Strings for uint256;

    string META_NAME;
    string META_DESC;
    string META_URI;

    bool public ACTIVE;
    uint16 public MAX_SUPPLY;
    uint16 public UPGRADE_COST;

    address public signatureAddress;

    IWacky public wackyAddress;
    IHero public heroAddress;

    // Model for how the traits will be hydrated.
    struct TraitData {
        uint8 background;
        uint8 clothes;
        uint8 face;
        uint8 hair;
        uint8 shoes;
        uint8 weapons;
        uint8 attack;
        uint8 defense;
        uint8 hp;
        uint8 sp;
        uint8 xp;
        uint8 gold;
        uint8 kibble;
        uint8 spr;
        uint8 healing;
    }

    // Model for how the attributes will be mutated.
    struct AttributeData {
        string background;
        string clothes;
        string face;
        string hair;
        string shoes;
        string weapons;
        uint8 attack;
        uint8 defense;
        uint8 hp;
        uint8 sp;
        uint8 xp;
        uint8 gold;
        uint8 kibble;
        uint8 spr;
        uint8 healing;
    }

    // Mapping of administrator addresses authorized
    mapping(address => bool) private _admins;

    // Mapping address to nonce counter used for signatures
    mapping(address => uint256) private _nonces;

    // Array of TraitData data for each token.
    //TraitData[10000] private _traitData;
    mapping(uint256 => uint256) private _traitData;

    // Mapping of index to string for trait labels
    mapping(uint256 => string) private _traitStrings;

    /**
     * @dev Emitted when trait data has been upgraded
     */
    event Upgraded(uint256 indexed tokenId, TraitData traitData);

    constructor(string memory name, string memory desc, string memory uri, address hero, address wacky) {
        unchecked {
            META_NAME = name;
            META_DESC = desc;
            META_URI = uri;

            wackyAddress = IWacky(wacky);
            heroAddress = IHero(hero);

            MAX_SUPPLY = 10000;
            UPGRADE_COST = 100;
        }
    }

    /**
     * @dev Retrieve the AttributeData model for the `tokenId`
     */
    function attributes(uint256 tokenId) public view virtual returns (AttributeData memory) {
        require(tokenId < MAX_SUPPLY, 'Nonexistent token');

        TraitData memory trait = _unpackTraits(_traitData[tokenId]);

        return AttributeData(
            label(uint256(trait.background)),
            label(uint256(trait.clothes)),
            label(uint256(trait.face)),
            label(uint256(trait.hair)),
            label(uint256(trait.shoes)),
            label(uint256(trait.weapons)),
            trait.attack,
            trait.defense,
            trait.hp,
            trait.sp,
            trait.xp,
            trait.gold,
            trait.kibble,
            trait.spr,
            trait.healing
        );
    }

    /**
     * @dev Turn the state of the contract on/off
     */
    function flipState() external onlyOwner {
        ACTIVE = !ACTIVE;
    }

    /**
     * @dev Initialize the traits entry for the token id during minting
     */
    function initTraits(uint256 tokenId) external onlyAdmin {
        unchecked{
            _traitData[tokenId] = uint256(0x01);
        }
    }

    /**
     * @dev Retrieve the integer => string mapping (label) for TraitData by `index`
     */
    function label(uint256 index) public view virtual returns (string memory) {
        return _traitStrings[index];
    }

    /**
     * @dev Build base64 encoded metadata with all traits for `tokenId`
     *
     * The associated ERC-721 contract can return this value as part of the tokenURI function.
     *
     * See https://docs.opensea.io/docs/metadata-standards
     */
    function metadata(uint256 tokenId) external view virtual returns (string memory) {
        require(tokenId < MAX_SUPPLY, 'Nonexistent token');

        AttributeData memory attribute = attributes(tokenId);

        if (!ACTIVE) {
            return string(abi.encodePacked("data:application/json;base64,", Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"', META_NAME, ' #', tokenId.toString(), '",',
                            '"description":"', META_DESC, '",',
                            '"image":"', META_URI, '"}'
                        )
                    )
                )));
        }

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(
                bytes(
                    abi.encodePacked(
                        '{"name":"', META_NAME, ' #', tokenId.toString(), '",',
                        '"description":"', META_DESC, '",',
                        '"image":"', META_URI, tokenId.toString(), '",',
                        '"attributes":[',
                            _metadataStrings(attribute),
                            _metadataValues(attribute),
                        ']}'
                    )
                )
            )));
    }

    /**
     * @dev Grant access to admin to upgrade metadata on users behalf
     */
    function setAdmin(address admin, bool approved) external onlyOwner {
        _admins[admin] = approved;
    }

    /**
     * @dev Sets the metadata description `desc` used when rendering json
     */
    function setMetaDesc(string memory desc) external onlyOwner {
        META_DESC = desc;
    }

    /**
     * @dev Sets the metadata project name `name` used when rendering json
     */
    function setMetaName(string memory name) external onlyOwner {
        META_NAME = name;
    }

    /**
     * @dev Sets the metadata base URI `uri` used when rendering json
     */
    function setMetaUri(string memory uri) external onlyOwner {
        META_URI = uri;
    }

    /**
     * @dev Sets the address used to for the hero interface
     */
    function setHeroAddress(address hero) external onlyOwner {
        heroAddress = IHero(hero);
    }

    /**
     * @dev Sets a label string used in metadata by integer index
     */
    function setLabel(string memory label_, uint256 index) external onlyOwner {
        require(index > 0, 'Index must not by zero');
        _traitStrings[index] = label_;
    }

    /**
     * @dev Sets the label strings used in metadata which are keyed by integer index
     */
    function setLabels(string[] calldata labels, uint256 startingIndex) external onlyOwner {
        require(startingIndex > 0, 'Index must not by zero');
        for (uint256 i = 0; i < labels.length; i++) {
            _traitStrings[startingIndex + i] = labels[i];
        }
    }

    /**
     * @dev Sets the address used to verify signatures
     */
    function setSignatureAddress(address signature) external onlyOwner {
        signatureAddress = signature;
    }

    /**
     * @dev Sets
     */
    function setTraits(uint256[] calldata data, uint256 startingTokenIndex) external onlyOwner {
        require(data.length + startingTokenIndex < 10000, 'Will exceed max supply');
        for (uint256 i = 0; i < data.length; i++) {
            unchecked{
                _traitData[startingTokenIndex + i] = data[i];
            }
        }
    }

    /**
     * @dev Sets the address used to for the wacky interface
     */
    function setWackyAddress(address wacky) external onlyOwner {
        wackyAddress = IWacky(wacky);
    }
    /**
     * @dev Sets the base burn cost for upgrades
     */
    function setUpgradeCost(uint16 amount) external onlyOwner {
        UPGRADE_COST = amount;
    }

    /**
     * @dev Retrieve the TraitData model for the `tokenId`
     */
    function traits(uint256 tokenId) public view virtual returns (TraitData memory) {
        require(tokenId < MAX_SUPPLY, 'Nonexistent token');
        return _unpackTraits(_traitData[tokenId]);
    }

    /**
     * @dev Retrieve the trait data as bytes32 `tokenId`
     */
    function traitBytes(uint256 tokenId) public view virtual returns (bytes32) {
        require(tokenId < MAX_SUPPLY, 'Nonexistent token');
        return bytes32(_traitData[tokenId]);
    }

    /**
     * @dev Upgrades the `tokenId`s trait data
     *
     * Emits a {Upgraded} event.
     */
    function upgradeBySignature(uint256 tokenId, uint256 data, uint256 nonce, bytes calldata signature) external nonReentrant {
        require(signatureAddress != address(0), "Signature address not defined");
        require(tokenId < MAX_SUPPLY, 'Nonexistent token');
        require(_validateSignature(signature, abi.encodePacked(tokenId, data, nonce, _msgSender())), "Invalid signature");
        require(_nonces[_msgSender()] < nonce, "Signature has expired");
        _nonces[_msgSender()] = nonce;

        // Unpacking and then packing again allows us to perform data integrity checks and it's not much gas at all
        TraitData memory trait = _unpackTraits(data);
        _traitData[tokenId] = _packTraits(trait);
        emit Upgraded(tokenId, trait);
    }

    /**
     * @dev Upgrades the `tokenId`s TraitData stat
     *
     * Emits a {Upgraded} event.
     */
    function upgradeBoost(uint8 boost, address recipient, uint8 quantity, uint256 tokenId) external nonReentrant {
        require(tokenId < MAX_SUPPLY, 'Nonexistent token');
        require(boost <= 8, 'Nonexistent boost');
        require(heroAddress.ownerOf(tokenId) == recipient, 'Recipient does not own tokenId');
        require(_admins[msg.sender] || recipient == _msgSender(), "Unauthorized");

        if (quantity == 0) quantity = 1;

        uint256 burnCost = uint256(quantity) * (uint256(UPGRADE_COST) * 10 ** 18);

        if (recipient == _msgSender()) {
            require(wackyAddress.balanceOf(recipient) >= burnCost, "Wallet does not have enough $WACKY to burn.");
            wackyAddress.burn(recipient, burnCost);
        }

        TraitData memory trait = _unpackTraits(_traitData[tokenId]);

        if (boost == 0) {
            require(trait.attack + quantity <= 25, 'Upgrade would exceed max value');
            trait.attack += quantity;
        }
        else if (boost == 1) {
            require(trait.defense + quantity <= 25, 'Upgrade would exceed max value');
            trait.defense += quantity;
        }
        else if (boost == 2) {
            require(trait.hp + quantity <= 25, 'Upgrade would exceed max value');
            trait.hp += quantity;
        }
        else if (boost == 3) {
            require(trait.sp + quantity <= 25, 'Upgrade would exceed max value');
            trait.sp += quantity;
        }
        else if (boost == 4) {
            require(trait.xp + quantity <= 25, 'Upgrade would exceed max value');
            trait.xp += quantity;
        }
        else if (boost == 5) {
            require(trait.gold + quantity <= 25, 'Upgrade would exceed max value');
            trait.gold += quantity;
        }
        else if (boost == 6) {
            require(trait.kibble + quantity <= 25, 'Upgrade would exceed max value');
            trait.kibble += quantity;
        }
        else if (boost == 7) {
            require(trait.spr + quantity <= 25, 'Upgrade would exceed max value');
            trait.spr += quantity;
        }
        else if (boost == 8) {
            require(trait.healing + quantity <= 25, 'Upgrade would exceed max value');
            trait.healing += quantity;
        }

        _traitData[tokenId] = _packTraits(trait);

        emit Upgraded(tokenId, trait);
    }

    /**
     * @dev Should not be anything to withdraw, but just in case
     */
    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Exceeds balance");
        Address.sendValue(payable(_msgSender()), amount);
    }

    /**
     * @dev Pack several strings for metadata rendering
     */
    function _metadataStrings(AttributeData memory attribute) internal pure returns (bytes memory) {
        return abi.encodePacked(
            _metaString('Background', attribute.background), ',',
            _metaString('Clothes', attribute.clothes), ',',
            _metaString('Face', attribute.face), ',',
            _metaString('Hair', attribute.hair), ',',
            _metaString('Shoes', attribute.shoes), ',',
            _metaString('Weapons', attribute.weapons), ','
        );
    }

    /**
     * @dev Pack several numbers for metadata rendering
     *
     * Had to split this out due to stack limits
     */
    function _metadataValues(AttributeData memory attribute) internal pure returns (bytes memory) {
        return abi.encodePacked(
            _metaValue('Attack Boost', 'boost_number', attribute.attack, 25), ',',
            _metaValue('Defense Boost', 'boost_number', attribute.defense, 25), ',',
            _metaValue('HP Boost', 'boost_number', attribute.hp, 25), ',',
            _metaValue('SP Boost', 'boost_number', attribute.sp, 25), ',',
            _metaValue('XP Boost', 'boost_number', attribute.xp, 25), ',',
            _metaValue('Gold Boost', 'boost_number', attribute.gold, 25), ',',
            _metaValue('Kibble Boost', 'boost_number', attribute.kibble, 25), ',',
            _metaValue('SP Usage Reduction', 'boost_number', attribute.spr, 25), ',',
            _metaValue('Healing Boost', 'boost_number', attribute.healing, 25)
        );
    }

    /**
     * @dev Build trait object for JSON metadata attribute strings.
     *
     * Wraps value with double quotes so that values show as "Properties".
     */
    function _metaString(string memory traitType, string memory value) internal pure returns (bytes memory) {
        return abi.encodePacked('{"trait_type":"', traitType, '","value":"', value, '"}');
    }

    /**
     * @dev Build trait object for JSON metadata attribute numbers.
     *
     * Possible `displayType` values should be:
     *  - (empty string): when displaying number as "Ranking" - E.g. 2 of 45
     *  - boost_number: when displaying number as a +X Boost - E.g. +40 power
     *  - boost_percentage: when displaying number as a +X% Boost - E.g. +15% stamina
     *  - number: when displaying number as "Stats" - E.g. 5 - priority out of 10
     *  - date: when displaying timestamp as "Date" - E.g. - January 1, 1980
     *
     * An optional `maxValue` may be used to help with displaying traits
     */
    function _metaValue(string memory traitType, string memory displayType, uint256 value, uint256 maxValue) internal pure returns (bytes memory) {
        return abi.encodePacked('{"trait_type":"', traitType, bytes(displayType).length > 0 ? '","display_type":"' : '', displayType, '","value":', value.toString(), maxValue > 0 ? string(abi.encodePacked(',"max_value":', maxValue.toString())) : '' ,'}');
    }

    function _metaValue(string memory traitType, string memory displayType, uint256 value) internal pure returns (bytes memory) {
        return _metaValue(traitType, displayType, value, 0);
    }

    /**
     * @dev Packs the TraitData struct back to uint256
     */
    function _packTraits(TraitData memory trait) internal pure returns (uint256) {
        return
            uint256(0x01) |
            uint256(trait.background) << 8 |
            uint256(trait.clothes) << 16 |
            uint256(trait.face) << 24 |
            uint256(trait.hair) << 32 |
            uint256(trait.shoes) << 40 |
            uint256(trait.weapons) << 48 |
            _packTraitsValues(trait);
    }

    /**
     * @dev Handle packing of numerical values so that we can verify the data
     */
    function _packTraitsValues(TraitData memory trait) internal pure returns (uint256) {
        return
            uint256(trait.attack > 25 ? 25 : trait.attack) << 56 |
            uint256(trait.defense > 25 ? 25 : trait.defense) << 64 |
            uint256(trait.hp > 25 ? 25 : trait.hp) << 72 |
            uint256(trait.sp > 25 ? 25 : trait.sp) << 80 |
            uint256(trait.xp > 25 ? 25 : trait.xp) << 88 |
            uint256(trait.gold > 25 ? 25 : trait.gold) << 96 |
            uint256(trait.kibble > 25 ? 25 : trait.kibble) << 104 |
            uint256(trait.spr > 25 ? 25 : trait.spr) << 112 |
            uint256(trait.healing > 25 ? 25 : trait.healing) << 120;
    }

    /**
     * @dev Unpacks the traits hash into a TraitData struct
     */
    function _unpackTraits(uint256 data) internal pure returns (TraitData memory) {
        return TraitData(
            {
                background: uint8(data >> 8),
                clothes: uint8(data >> 16),
                face: uint8(data >> 24),
                hair: uint8(data >> 32),
                shoes: uint8(data >> 40),
                weapons: uint8(data >> 48),
                attack: uint8(data >> 56),
                defense: uint8(data >> 64),
                hp: uint8(data >> 72),
                sp: uint8(data >> 80),
                xp: uint8(data >> 88),
                gold: uint8(data >> 96),
                kibble: uint8(data >> 104),
                spr: uint8(data >> 112),
                healing: uint8(data >> 120)
            }
        );
    }

    /**
     * @dev Validates that the signature used matches the hash by extracting the signature address
     */
    function _validateSignature(bytes calldata signature, bytes memory hash) internal view returns (bool) {
        bytes32 dataHash = keccak256(hash);
        bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);
        address receivedAddress = ECDSA.recover(message, signature);
        return (receivedAddress != address(0) && receivedAddress == signatureAddress);
    }

    /**
     * @dev Throws if called by any account other than an authorized admin.
     */
    modifier onlyAdmin() {
        require(_admins[msg.sender] || owner() == _msgSender(), "Unauthorized");
        _;
    }
}
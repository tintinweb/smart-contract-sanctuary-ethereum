/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// File: contracts/NaftyDolls/NaftyDolls.sol

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;





contract NaftyDolls is ERC721, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    uint256 public MAX_PRESALE = 1000;
    uint256 public MAX_FREE = 1696;
    uint256 public maxSupply = 6969;

    uint256 public currentSupply = 0;
    uint256 public maxPerWallet = 5;

    uint256 public salePrice = 0.025 ether;
    uint256 public presalePrice = 0.02 ether;

    uint256 public presaleCount;

    uint256 public freeMinted;

    //Placeholders
    address private presaleAddress = address(0x0d9555EEa2835eE438219374dd97F0Cbe51bf0bc);
    address private freeAddress = address(0x642D7B2F8CaC6b7DA136D1fe8C2C912EEF32564c);
    address private wallet = address(0x9C86fC37EB0054f38D29C44Ba374E6e712e40F9f);

    string private baseURI;
    string private notRevealedUri = "ipfs://QmYSLyMYTPKjgavj4ZkxP8U8epdDP6mwKypg5S5UFi7it7";

    bool public revealed = false;
    bool public baseLocked = false;
    bool public marketOpened = false;
    bool public freeMintOpened = false;

    enum WorkflowStatus {
        Before,
        Presale,
        Sale,
        Paused,
        Reveal
    }

    WorkflowStatus public workflow;

    mapping(address => uint256) public freeMintAccess;
    mapping(address => uint256) public presaleMintLog;
    mapping(address => uint256) public freeMintLog;

    constructor()
        ERC721("NaftyDolls", "DOLLS")
    {
        transferOwnership(msg.sender);
        workflow = WorkflowStatus.Before;

        initFree();
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(marketOpened, 'The sale of NFTs on the marketplaces has not been opened yet.');
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        require(marketOpened, 'The sale of NFTs on the marketplaces has not been opened yet.');
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address( this ).balance;
        
        payable( wallet ).transfer( _balance );
    }

    //GETTERS
    function getSaleStatus() public view returns (WorkflowStatus) {
        return workflow;
    }

    function totalSupply() public view returns (uint256) {
        return currentSupply;
    }

    function getFreeMintAmount( address _acc ) public view returns (uint256) {
        return freeMintAccess[ _acc ];
    }

    function getFreeMintLog( address _acc ) public view returns (uint256) {
        return freeMintLog[ _acc ];
    }

    function validateSignature( address _addr, bytes memory _s ) internal view returns (bool){
        bytes32 messageHash = keccak256(
            abi.encodePacked( address(this), msg.sender)
        );

        address signer = messageHash.toEthSignedMessageHash().recover(_s);

        if( _addr == signer ) {
            return true;
        } else {
            return false;
        }
    }

    //Batch minting
    function mintBatch(
        address to,
        uint256 baseId,
        uint256 number
    ) internal {

        for (uint256 i = 0; i < number; i++) {
            _safeMint(to, baseId + i);
        }

    }

    /**
        Claims tokens for free paying only gas fees
     */
    function freeMint(uint256 _amount, bytes calldata signature) external {
        //Free mint check
        require( 
            freeMintOpened, 
            "Free mint is not opened yet." 
        );

        //Check free mint signature
        require(
            validateSignature(
                freeAddress,
                signature
            ),
            "SIGNATURE_VALIDATION_FAILED"
        );

        uint256 supply = currentSupply;
        uint256 allowedAmount = 1;

        if( freeMintAccess[ msg.sender ] > 0 ) {
            allowedAmount = freeMintAccess[ msg.sender ];
        } 

        require( 
            freeMintLog[ msg.sender ] + _amount <= allowedAmount, 
            "You dont have permision to free mint that amount." 
        );

        require(
            supply + _amount <= maxSupply,
            "NaftyDolls: Mint too large, exceeding the maxSupply"
        );

        require(
            freeMinted + _amount <= MAX_FREE,
            "NaftyDolls: Mint too large, exceeding the free mint amount"
        );


        freeMintLog[ msg.sender ] += _amount;
        freeMinted += _amount;
        currentSupply += _amount;

        mintBatch(msg.sender, supply, _amount);
    }


    function presaleMint(
        uint256 amount,
        bytes calldata signature
    ) external payable {
        
        require(
            workflow == WorkflowStatus.Presale,
            "NaftyDolls: Presale is not currently active."
        );

        require(
            validateSignature(
                presaleAddress,
                signature
            ),
            "SIGNATURE_VALIDATION_FAILED"
        );

        require(amount > 0, "You must mint at least one token");

        //Max per wallet check
        require(
            presaleMintLog[ msg.sender ] + amount <= maxPerWallet,
            "NaftyDolls: You have exceeded the max per wallet amount!"
        );

        //Price check
        require(
            msg.value >= presalePrice * amount,
            "NaftyDolls: Insuficient ETH amount sent."
        );
        
        require(
            presaleCount + amount <= MAX_PRESALE,
            "NaftyDolls: Selected amount exceeds the max presale supply"
        );

        presaleCount += amount;
        currentSupply += amount;
        presaleMintLog[ msg.sender ] += amount;

        mintBatch(msg.sender, currentSupply - amount, amount);
    }

    function publicSaleMint(uint256 amount) external payable {
        require( amount > 0, "You must mint at least one NFT.");
        
        uint256 supply = currentSupply;

        require( supply < maxSupply, "NaftyDolls: Sold out!" );
        require( supply + amount <= maxSupply, "NaftyDolls: Selected amount exceeds the max supply.");

        require(
            workflow == WorkflowStatus.Sale,
            "NaftyDolls: Public sale has not active."
        );

        require(
            msg.value >= salePrice * amount,
            "NaftyDolls: Insuficient ETH amount sent."
        );

        currentSupply += amount;

        mintBatch(msg.sender, supply, amount);
    }

    function forceMint(uint256 number, address receiver) external onlyOwner {
        uint256 supply = currentSupply;

        require(
            supply + number <= maxSupply,
            "NaftyDolls: You can't mint more than max supply"
        );

        currentSupply += number;

        mintBatch( receiver, supply, number);
    }

    function ownerMint(uint256 number) external onlyOwner {
        uint256 supply = currentSupply;

        require(
            supply + number <= maxSupply,
            "NaftyDolls: You can't mint more than max supply"
        );

        currentSupply += number;

        mintBatch(msg.sender, supply, number);
    }

    function airdrop(address[] calldata addresses) external onlyOwner {
        uint256 supply = currentSupply;
        require(
            supply + addresses.length <= maxSupply,
            "NaftyDolls: You can't mint more than max supply"
        );

        currentSupply += addresses.length;

        for (uint256 i = 0; i < addresses.length; i++) {
            _safeMint(addresses[i], supply + i);
        }
    }

    function setUpBefore() external onlyOwner {
        workflow = WorkflowStatus.Before;
    }

    function setUpPresale() external onlyOwner {
        workflow = WorkflowStatus.Presale;
    }

    function setUpSale() external onlyOwner {
        workflow = WorkflowStatus.Sale;
    }

    function pauseSale() external onlyOwner {
        workflow = WorkflowStatus.Paused;
    }

    function setMaxPerWallet( uint256 _amount ) external onlyOwner {
        maxPerWallet = _amount;
    }

    function setMaxPresale( uint256 _amount ) external onlyOwner {
        MAX_PRESALE = _amount;
    }

    function setMaxFree( uint256 _amount ) external onlyOwner {
        MAX_FREE = _amount;
    }

    function openFreeMint() public onlyOwner {
        freeMintOpened = true;
    }
    
    function stopFreeMint() public onlyOwner {
        freeMintOpened = false;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        require( baseLocked == false, "Base URI change has been disabled permanently");

        baseURI = _newBaseURI;
    }

    function setPresaleAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "CAN'T PUT 0 ADDRESS");
        presaleAddress = _newAddress;
    }

    function setWallet(address _newWallet) public onlyOwner {
        wallet = _newWallet;
    }

    function setSalePrice(uint256 _newPrice) public onlyOwner {
        salePrice = _newPrice;
    }
    
    function setPresalePrice(uint256 _newPrice) public onlyOwner {
        presalePrice = _newPrice;
    }
    
    function setFreeMintAccess(address _acc, uint256 _am ) public onlyOwner {
        freeMintAccess[ _acc ] = _am;
    }

    //Lock base security - your nfts can never be changed.
    function lockBase() public onlyOwner {
        baseLocked = true;
    }

    //Once opened, it can not be closed again
    function openMarket() public onlyOwner {
        marketOpened = true;
    }

    // FACTORY
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(),'.json'))
                : "";
    }

    function initFree() internal {
        freeMintAccess[ address(0x9C86fC37EB0054f38D29C44Ba374E6e712e40F9f) ] = 168;
        freeMintAccess[ address(0x49c72c829B2aa1Ae2526fAEE29461E6cb7Efe0E6) ] = 102;
        freeMintAccess[ address(0x522dC68b2fd2da341d1d25595101E27118B232bD) ] = 73;
        freeMintAccess[ address(0xA21f8534E9521C02981a0956106d6074abE9c60f) ] = 61;
        freeMintAccess[ address(0xbF1aE3F91EC24B5Da2d85F2bD95a9E2a0F632d47) ] = 48;
        freeMintAccess[ address(0x0Cb7Dbc3837Ce16661BeC77e1Db239AAA6d4F0b4) ] = 40;
        freeMintAccess[ address(0xa7B463a13EF0657F0ab7b6DD03A923563e503Aea) ] = 39;
        freeMintAccess[ address(0x6E84a7EB0c34A757652A2474f4D2c73e288347c3) ] = 35;
        freeMintAccess[ address(0x883AB33f8270015102afeCBD03872458b12bf9c5) ] = 29;
        freeMintAccess[ address(0xb41e212b047f7A8e3961d52001ADE9413f7D0C70) ] = 24;
        freeMintAccess[ address(0x666e1b05Bf965b09B6D598C26Fa2Bdc27C5d3f4f) ] = 21;
        freeMintAccess[ address(0x0C319880d4296207b82F463B979b4923E5F9AD07) ] = 20;
        freeMintAccess[ address(0x86E453d8c94bc0ADC4f4B05b2b4E451e17Be8abe) ] = 20;
        freeMintAccess[ address(0xb0e41D26Cc795Da7220e3FBaaa0c92E6Baf65db2) ] = 20;
        freeMintAccess[ address(0xfB72c1a0500E18D757f722d1F71191503e937f1F) ] = 20;
        freeMintAccess[ address(0x1A18A57567EB571E29F14F7ae59c6fFEf2398157) ] = 13;
        freeMintAccess[ address(0xFaeFb5433b70f5D0857cc7f65b32eeae0316aBcb) ] = 12;
        freeMintAccess[ address(0x0Df8bFD2628A4b90cf8967167D0bd0F1E9969D55) ] = 11;
        freeMintAccess[ address(0x40E3c1262445fc6A5A8AEF06610dc44F7532c291) ] = 11;
        freeMintAccess[ address(0xC23e1145356A9dd3aa6Af8d7766281984ec24B76) ] = 11;
        freeMintAccess[ address(0x0e279033eA931f98908cc52E1ABFCa60118CAeBA) ] = 10;
        freeMintAccess[ address(0x9E75aa8Da215804fa82c8C6b5F24bBb7fF069541) ] = 10;
        freeMintAccess[ address(0x396EB23e3C593F0cD705fBA2Fb6F75c66CaAAd7a) ] = 9;
        freeMintAccess[ address(0x06a91aEcF753fF023033FFc6afD79904Dc6Dd22f) ] = 8;
        freeMintAccess[ address(0x617011B79F0761DD82Acc026F796650f5e767e84) ] = 8;
        freeMintAccess[ address(0x6571cb1fc92d71238aE992271D4Fca16e950a40A) ] = 8;
        freeMintAccess[ address(0xa2681553681a6A317F33BdCA233C510e7E9A94fC) ] = 8;
        freeMintAccess[ address(0xC6Ac567b250b986acAE49A842Dad7865dA4be3a0) ] = 8;
        freeMintAccess[ address(0xe78ec69BF9f6546fB7167f9F04B8B561e41456B3) ] = 8;
        freeMintAccess[ address(0x25840805c7B742488f2E5566398C99d0c39A373B) ] = 7;
        freeMintAccess[ address(0xA5f83912B9A8B0a6ac0DDbd24c68F88954E4C414) ] = 7;
        freeMintAccess[ address(0xAdBe5D005Dde820018e66D76E1295596C08E46B6) ] = 7;
        freeMintAccess[ address(0xbff3041A372573f65557CB58239f945b61021ee2) ] = 7;
        freeMintAccess[ address(0xF73931eF77Cb25dE6A06dAB426e592ED96eFe6b0) ] = 7;
        freeMintAccess[ address(0x1F23E7b50677C921663AA4e0c9964229fd144Df6) ] = 6;
        freeMintAccess[ address(0x9Aa9851eB948F1aE54388df486D45EE96fB90079) ] = 6;
        freeMintAccess[ address(0xD0BB6e64e1C6dEbADD41298E0fF39676630F03a8) ] = 6;
        freeMintAccess[ address(0x029AdC78D419072Ab70EC984C7b677BE51b0e121) ] = 5;
        freeMintAccess[ address(0x0fd24D3737831DcE1bbf70bEA0c66d7652e7e9Fd) ] = 5;
        freeMintAccess[ address(0x11eFD8579B24e49F0ff2c14Be23241045c8f7C01) ] = 5;
        freeMintAccess[ address(0x29425A1f1172628450c2d915317a5e2A2Ae9e8D8) ] = 5;
        freeMintAccess[ address(0x31B9A8347e5086B2D9C4bcA33B46CDcb04914fb1) ] = 5;
        freeMintAccess[ address(0x41C3BD08f55a1279C3c596449eB42e00A2E86823) ] = 5;
        freeMintAccess[ address(0x4e0D6e9081EEA4B76489EE135387bD99AA5e808E) ] = 5;
        freeMintAccess[ address(0x85EB1C61734d92d915cb54296E85473e35603ecF) ] = 5;
        freeMintAccess[ address(0x89EFf4ACa6aEC1e93E48DcCAF9098aD09E8A11F9) ] = 5;
        freeMintAccess[ address(0x8Eb0a8aa228148690313FBAfA4A7805aB304F9ce) ] = 5;
        freeMintAccess[ address(0xa953Ca657Eea71E5d6591B62551026E0CD6733c8) ] = 5;
        freeMintAccess[ address(0xB1F8D4D0eD25282A96B9D407944d69c9a988C2Ed) ] = 5;
        freeMintAccess[ address(0xb3caedA9DED7930a5485F6a36326B789C33c6c1e) ] = 5;
        freeMintAccess[ address(0xBBDCEDCC7cDac2F336d5F8f2C31cf35a29b5e4f7) ] = 5;
        freeMintAccess[ address(0xbfdA5CAEbFaA57871a14611F8d182d51e144C699) ] = 5;
        freeMintAccess[ address(0xc3C0465798ce9071513E21Ef244df6AD5f1B2eAB) ] = 5;
        freeMintAccess[ address(0xC53A22e8c57B7d1fecf9ec90973ea9B4C887b507) ] = 5;
        freeMintAccess[ address(0xCFF9Dd2C80140A8c72B9d6A04fb68A8A845c46e5) ] = 5;
        freeMintAccess[ address(0xE0F6Bb10e17Ae2fEcD114d43603482fcEa5A9654) ] = 9;
        freeMintAccess[ address(0xEa0bC5d9E7e7209Db6d154589EcB5A9eC834789B) ] = 5;
        freeMintAccess[ address(0xEbdE91900cC5D8B21e54Cf22200bC0BcfF797A3f) ] = 5;
        freeMintAccess[ address(0xfcEDD0aF38ee1F6D868Ee15ec3407A7ea4fBbDc0) ] = 5;
        freeMintAccess[ address(0x0783FD17d11589b59Ef7837803Bfb046c025C5Af) ] = 4;
        freeMintAccess[ address(0x11CfD3FAA2c11DE05B03D2bAA8720Ed650FDcfFF) ] = 4;
        freeMintAccess[ address(0x237f5828F189a57B0c41c260faD26fB3AabcBdB3) ] = 4;
        freeMintAccess[ address(0x2b2aAA6777Bd6BB6F3d0DDA951e8cd72382850A9) ] = 4;
        freeMintAccess[ address(0x3817Ee9AAe5Fe0260294B32D7feE557A12CaDf20) ] = 4;
        freeMintAccess[ address(0x55A2F801dC8C599510ffb87818dB0d5110dca971) ] = 4;
        freeMintAccess[ address(0x55f82Ab0Db89Fa58259fD08cf53Ab49a513d94B9) ] = 4;
        freeMintAccess[ address(0x611769a86D9AF4ECc50D96F62D5638F7b9a2C8b0) ] = 4;
        freeMintAccess[ address(0x773823a2122dC67422D80dE9F7171ed735073c99) ] = 4;
        freeMintAccess[ address(0x7B34328fCee7412409b2d2154b30A69603D4B1b3) ] = 4;
        freeMintAccess[ address(0x858dcFf3A742Ece5BF9AE20D7b1785d71097ED13) ] = 4;
        freeMintAccess[ address(0x9B767B0F52E63ED2CF964E7AC6f560090A90dAfB) ] = 4;
        freeMintAccess[ address(0xa6A7b9c9395AF131414b9d2a8500F3A9bEe4b666) ] = 4;
        freeMintAccess[ address(0xC28ADD98Fe22898B95267766D728bB604a9f84A4) ] = 4;
        freeMintAccess[ address(0xCB4DB3f102F0F505a4D545f8be593364B1c66A3C) ] = 4;
        freeMintAccess[ address(0xDc72374CE12BB418Aad6D6ccE5c18bE8A542D6a8) ] = 4;
        freeMintAccess[ address(0xE0687e41123fC40797136F4cdBC199DB6f25A807) ] = 4;
        freeMintAccess[ address(0x00E101ffd6eF0217fdA6d5226e5a213E216b332b) ] = 3;
        freeMintAccess[ address(0x02098bf554A48707579FcB28182D42947c013cfA) ] = 3;
        freeMintAccess[ address(0x0668f77dD7AA869AaDA6aA79bC2066B04402f33D) ] = 3;
        freeMintAccess[ address(0x278868be49d73284e6415d68b8583211eE96ce1F) ] = 3;
        freeMintAccess[ address(0x2b617e50120131172cb4f83B003C2B9870181a4b) ] = 3;
        freeMintAccess[ address(0x2bD89Adf988609Ba5bB91CDc4250230dDC3D9dA7) ] = 3;
        freeMintAccess[ address(0x2f8fb999B325FCb5182Df1a2d94801B8C8C09800) ] = 3;
        freeMintAccess[ address(0x316A35eBc7bFb945aB84E8BF6167585602306192) ] = 3;
        freeMintAccess[ address(0x34e5f6E7b84345d81d86Ae1afc213528b1F8FDA8) ] = 3;
        freeMintAccess[ address(0x34EDC7ab60f6cBD2005Ac07C543e19CA48B23b30) ] = 3;
        freeMintAccess[ address(0x39b2B1D665f018f3eE2e46947f41A83f4806e159) ] = 3;
        freeMintAccess[ address(0x426709Ab969F9901654942af0eAd1966Ad111a9D) ] = 3;
        freeMintAccess[ address(0x44539fbBC413c07b133d310f7713d354F3D55f0a) ] = 3;
        freeMintAccess[ address(0x5a1726eC746a9c63bB699AF5d9e8eAa0007567Ed) ] = 3;
        freeMintAccess[ address(0x5c8aD9343c76CCE594cB3B663410DD2fa1aC0e78) ] = 3;
        freeMintAccess[ address(0x62E45D439547602F36e0879fa66600b9EdD196B0) ] = 3;
        freeMintAccess[ address(0x642aB18dEbdf0A516083097b056489029D607530) ] = 3;
        freeMintAccess[ address(0x69e69571d0d07EdBEde6c43849e8d877573eE6bf) ] = 3;
        freeMintAccess[ address(0x6a4e2bC8529c43Bc02e7007762eBA16fe5bDBd6F) ] = 3;
        freeMintAccess[ address(0x6B6f0B36Ae5B19f9D0c1BD62DFF3E0bEDaA0C039) ] = 3;
        freeMintAccess[ address(0x76cAD91850548726F41FABedDA8119fd133ae2d9) ] = 3;
        freeMintAccess[ address(0x7C922CDC663367ed2ba6E84c074385121AA79291) ] = 3;
        freeMintAccess[ address(0x7D259bb55d3481aD0b3A39FaDd9bAf1e1E66FbB7) ] = 3;
        freeMintAccess[ address(0x81fA49241483A6eFB50E540b1185ED54Aa7fb5E4) ] = 3;
        freeMintAccess[ address(0x88acF47cdF0030F7E52e82C49606E0B7078D5E6A) ] = 3;
        freeMintAccess[ address(0x936c80387b8ba716FbB0Ea889BE3C37C45Dd255B) ] = 3;
        freeMintAccess[ address(0x9CA6103A2c7Ca4028aC7ff7163D58fFDad6aa5A1) ] = 3;
        freeMintAccess[ address(0x9f873b00048CbF31004968579D8beE032A509F7b) ] = 3;
        freeMintAccess[ address(0xA0F9Ae81cD597A889BA519f20e06C5dE63162146) ] = 3;
        freeMintAccess[ address(0xA9Eaa007aAE4924D650c50381b278841Ee4d4e01) ] = 3;
        freeMintAccess[ address(0xad1f11c7c621e628E47E164A87d97D5A048Cb2E5) ] = 3;
        freeMintAccess[ address(0xAeA9E80d59831660814A98109102bA1DD7A3DB0b) ] = 3;
        freeMintAccess[ address(0xB320cd14bCf767d2Be6831686fFf2AB8DF5B68A5) ] = 3;
        freeMintAccess[ address(0xB50b39a360D664D2b9e48404A0C7a64Af6eE2714) ] = 3;
        freeMintAccess[ address(0xB82f8752410eFb54aAeBAE73EDae3e763e95FF53) ] = 3;
        freeMintAccess[ address(0xc91D7378ADfF02593f5d67991C6B9721d3Bc244d) ] = 3;
        freeMintAccess[ address(0xcb6dBC850121BffbF43B6A9DF3C609FC8F42a111) ] = 3;
        freeMintAccess[ address(0xcBaECfE19E1CCb9B48eC729Ffd82AC1a0F7112eD) ] = 3;
        freeMintAccess[ address(0xcFEF2A369dBdFF9Ae1E632013E34ea33285969d6) ] = 3;
        freeMintAccess[ address(0xD0c4ADd4eD42b02443CEF35Ab64B670b8D81f5bC) ] = 3;
        freeMintAccess[ address(0xE15F465a129e9B7E26fC1E4e71a13D118c10cE33) ] = 3;
        freeMintAccess[ address(0xe4458edE9a736AEc5dB456d04B3386313a29dC46) ] = 3;
        freeMintAccess[ address(0xF6a7629CB1DB16B4F12DFa73085d794483771514) ] = 3;
        freeMintAccess[ address(0x00651B9E2924f1a5B63F6460832ab211E5829190) ] = 2;
        freeMintAccess[ address(0x01F3a298eb502dB16E298e31CF5Ae8974Fc2de12) ] = 2;
        freeMintAccess[ address(0x0360beFfdc22278fd5198e2608f5759EB9B40be4) ] = 2;
        freeMintAccess[ address(0x05635698333c7bD541E20d212B201d8f464D286a) ] = 2;
        freeMintAccess[ address(0x063972361f92495B2A3d91614B6E18711e8C765D) ] = 2;
        freeMintAccess[ address(0x08c85509e3B4bC0b08eB39D7acC06A1D9CDE7B1F) ] = 2;
        freeMintAccess[ address(0x0Eb1e0118CCc4E329c9e88efF8c2f6AD14325309) ] = 2;
        freeMintAccess[ address(0x142E4B0C91aD69Da00b89e01Bef41f66dE8DA45c) ] = 2;
        freeMintAccess[ address(0x14D4c369B7792EE9A1BeaDa5eb8D25555aD246BF) ] = 2;
        freeMintAccess[ address(0x18A5862eC62C95B3b370aEdAF40e8971dfAAF7E4) ] = 2;
        freeMintAccess[ address(0x1Ee67146295bEB4F64ED72BBb00d00C455D75003) ] = 2;
        freeMintAccess[ address(0x1FB7e0cA57d8a22dCc3a8A8FCeB7827eFe7AaBFc) ] = 2;
        freeMintAccess[ address(0x203073d988EA2f651f7363CC4468Ae8076BaF84D) ] = 2;
        freeMintAccess[ address(0x2110A3BC29CAb77062540fe613952994665406d5) ] = 2;
        freeMintAccess[ address(0x21AE1e7524c340709D5734185a89fEb1040a4393) ] = 2;
        freeMintAccess[ address(0x242263064cEB2Be99A376C990A52110F6472d879) ] = 2;
        freeMintAccess[ address(0x285bB8B9B7331e78B6aAcAd72Ae62a61Db2EAAb2) ] = 2;
        freeMintAccess[ address(0x297EA7fa152614C6e65E0c177A8F8c5A52BA2F14) ] = 2;
        freeMintAccess[ address(0x2Af6D6ec3a49443d71729f184C3Df65b827411D9) ] = 2;
        freeMintAccess[ address(0x2e16ee698B05BDFc0125DD0de5C8913004F5E5c3) ] = 2;
        freeMintAccess[ address(0x3172d85857E1ae86F4Fdb6e3143C0b4529e71084) ] = 2;
        freeMintAccess[ address(0x323A4e8BD47c9cF0275A31D8a23c8Bbc23367Fcc) ] = 2;
        freeMintAccess[ address(0x3364906e33d47B3770A0Db4C6f81824f1881c63a) ] = 2;
        freeMintAccess[ address(0x356f221097C5FEB632BB23A9E52eaE8C8a5Fe54B) ] = 2;
        freeMintAccess[ address(0x35C663401DC5B007974fcDcc3317596d1378b910) ] = 2;
        freeMintAccess[ address(0x35f12c7c6Ad9f23CC0D9Adc2D0f2E7254B03169F) ] = 2;
        freeMintAccess[ address(0x35F8aAFEd6658e4A85Eb7431761B4E82E0275d4B) ] = 2;
        freeMintAccess[ address(0x383cf70da21bbF077320B1398dFda88f48B7e80F) ] = 2;
        freeMintAccess[ address(0x3fA4682DfdC0768f338C4Ac6FADb20379Cf9d3e2) ] = 2;
        freeMintAccess[ address(0x4441FD519053AC38601358dC51EF91f672AF1bB9) ] = 2;
        freeMintAccess[ address(0x4537628215a44154ea1f9C33c544B3329721E9a6) ] = 2;
        freeMintAccess[ address(0x4a9b4cea73531Ebbe64922639683574104e72E4E) ] = 2;
        freeMintAccess[ address(0x4b427cC127371621b82a89a02301ef5ee45EA1ED) ] = 2;
        freeMintAccess[ address(0x4B71b5420e68Ff460A8154C311cD94aE12222300) ] = 2;
        freeMintAccess[ address(0x4Ce304754Bbd6Bfe8643ebba72Cf494ccb089d8e) ] = 2;
        freeMintAccess[ address(0x51D0eAA18e9dc6b236a14521a1462bd202894913) ] = 2;
        freeMintAccess[ address(0x5226060F20bD813d4fCdc9E3344e493959726648) ] = 2;
        freeMintAccess[ address(0x541a62d184c8A00AaaCA48fAd3ad5f1E2ABD1B6C) ] = 2;
        freeMintAccess[ address(0x56bF222b0e3a78ad594DB4CcD851706BCCb35eC7) ] = 2;
        freeMintAccess[ address(0x56E48cad4419A8a27DE6444f5839d85bCdBAfA27) ] = 2;
        freeMintAccess[ address(0x578E141720128EAFFf1261815C85cDFEd438b1Cd) ] = 2;
        freeMintAccess[ address(0x59D7F9858a959fD555BF4E81646EE425aAdFE8CE) ] = 2;
        freeMintAccess[ address(0x5B50AD735b4B70a764861478545AF6e2CE1Aaafe) ] = 2;
        freeMintAccess[ address(0x5c6141CeF1e7eee4778358E4485146fA3d503959) ] = 2;
        freeMintAccess[ address(0x5Db8AD9A84AeEAe718C8B225737B2c3C78BdcA59) ] = 2;
        freeMintAccess[ address(0x60Fc4A8Db5447EcF020c803464f2aDf5E9647C66) ] = 2;
        freeMintAccess[ address(0x612800D4Fc2ea61d24564c9d921a3018647B3d7c) ] = 2;
        freeMintAccess[ address(0x64026c16426F07D8B43c1fd37C133EBF7B92dEB4) ] = 2;
        freeMintAccess[ address(0x64D479a9326552bCea6F9284ca627CE6F18B5a28) ] = 2;
        freeMintAccess[ address(0x64fC6C7CAd57482844f239D9910336a03E6Ce831) ] = 2;
        freeMintAccess[ address(0x65EE7980da550072805A12d158Bf14406572F6A8) ] = 2;
        freeMintAccess[ address(0x68B7eA5BAB27c42be609AC02505E1120CEd72A7d) ] = 2;
        freeMintAccess[ address(0x690ae2e0adf1d939d0Dc9EB757ffC5AcA5a16d00) ] = 2;
        freeMintAccess[ address(0x6b37Cc92c7653D4c33d144Cb8284c48a02968fd2) ] = 2;
        freeMintAccess[ address(0x6d22E1F7060D78C753A4498C2d48fE71643Fa1d6) ] = 2;
        freeMintAccess[ address(0x705AB1Ff5205216e3d49B53223B56A5E159e7835) ] = 2;
        freeMintAccess[ address(0x70C01b34BC0B8963FD747100430aeD647F4dDcdC) ] = 2;
        freeMintAccess[ address(0x77AEeA17E3e367A0966a8b8BE8eC912797F4A929) ] = 2;
        freeMintAccess[ address(0x7E7CfF0bE2A2baD0e5e879Ff17eD9B615dFe3Ab4) ] = 2;
        freeMintAccess[ address(0x80C56dE765ebDFBB5b2992337B1F247C7F728dFC) ] = 2;
        freeMintAccess[ address(0x816F81C3fA8368CDB1EaaD755ca50c62fdA9b60D) ] = 2;
        freeMintAccess[ address(0x8205EB5Ed2D325e6381f62e4c0e6537F5B968bD5) ] = 2;
        freeMintAccess[ address(0x821fD4c8f28B47619811A7825540A7B0049B0f66) ] = 2;
        freeMintAccess[ address(0x8364E59631d012EaD8a4DB965df4f174DA05A260) ] = 2;
        freeMintAccess[ address(0x848573085b783511a47850f7C0475F3224a0fc2D) ] = 2;
        freeMintAccess[ address(0x866241207F759B646Dad2C9416d55045aE55Bc0B) ] = 2;
        freeMintAccess[ address(0x8b835e35838448a8A29Be15E926D99E9FB040822) ] = 2;
        freeMintAccess[ address(0x8Dc047Ce563680D2553a95Cb357EE321c164aFe0) ] = 2;
        freeMintAccess[ address(0x95631A17dd0F4D19eb90Cc6A0a7e330C987a5139) ] = 2;
        freeMintAccess[ address(0x986eAa8d5a0EC0a0f0433BBB249D15E5430CF550) ] = 2;
        freeMintAccess[ address(0x990450d56c41ef5e7d818E0453c2f813FEb9448A) ] = 2;
        freeMintAccess[ address(0x996d25fc973756cA9a177510C28afa18BEf27499) ] = 2;
        freeMintAccess[ address(0x9EC02aAE4653bd59aC2cE64A135c22Ade5c1856A) ] = 2;
        freeMintAccess[ address(0xA22F59899BFa6D3d24a0b488fBD830f6B922e1dA) ] = 2;
        freeMintAccess[ address(0xa6B59f2d1409B2240c4a7A02B2d27d8b15Bd2248) ] = 2;
        freeMintAccess[ address(0xa8f6deDCAe4D391Eaa009CB6f848bB31fDB47D02) ] = 2;
        freeMintAccess[ address(0xa91A55e5EfEB84Ce3d7f0Eac207B175f4c1940Ca) ] = 2;
        freeMintAccess[ address(0xb4C69Cf41894F7c372f349C35F0477511881bDEF) ] = 2;
        freeMintAccess[ address(0xB631f4eA32A8876ae37ee475C6912e94AB853694) ] = 2;
        freeMintAccess[ address(0xB7c6020f4A7B4ef1b4a621E48B5bA0284f2BEee1) ] = 2;
        freeMintAccess[ address(0xBc48d0cb0f85434186b83263dcBbA6bfE79CAa10) ] = 2;
        freeMintAccess[ address(0xbC4afF27c74e76e4639993679e243f80f8F455fc) ] = 2;
        freeMintAccess[ address(0xBd03118971755fC60e769C05067061ebf97064ba) ] = 2;
        freeMintAccess[ address(0xBF7FD93Fe70Fd6126c6f06DfBCe4EcA9Ac09e050) ] = 2;
        freeMintAccess[ address(0xC5301285da585125B1dc8CCCedD1de1845b68c0F) ] = 2;
        freeMintAccess[ address(0xC58BD7961088bC22Bb26232b7973973322E272f5) ] = 2;
        freeMintAccess[ address(0xC7fbAda2D0596377B748a73428749874BD037c39) ] = 2;
        freeMintAccess[ address(0xCbC0A5724626618EA59dfcc1923f16FB370E602b) ] = 2;
        freeMintAccess[ address(0xCf81AfD911E4c86fe1c3396776eDAa4972c4033c) ] = 2;
        freeMintAccess[ address(0xd10C4a705bB5eDA3498EC9a1eBFf1fDBfE265352) ] = 2;
        freeMintAccess[ address(0xda51c29BA453229eb2A606AB771800E341EDE8c8) ] = 2;
        freeMintAccess[ address(0xdEe435A6d24bed1c5391515417692239f3d5951f) ] = 2;
        freeMintAccess[ address(0xdFDBca65041662139e87555646967B5aBb628c5c) ] = 2;
        freeMintAccess[ address(0xe324C2f2524c0a7288866F9D132d5b43ef038349) ] = 2;
        freeMintAccess[ address(0xe3b29c5794Ac8C9c7c9fdE346209d1927A1E7B33) ] = 2;
        freeMintAccess[ address(0xE8eb3Ab24b9770a9A7ab9e245D21F4D6F607c651) ] = 2;
        freeMintAccess[ address(0xea6A7C8064e528205f36b1971CDAcf114762e1Ee) ] = 2;
        freeMintAccess[ address(0xeB96B4217DA1221054F9f40d47191a2CD900285c) ] = 2;
        freeMintAccess[ address(0xeD176ef200Ac42bDdDB95983815265b8063fcA48) ] = 2;
        freeMintAccess[ address(0xeE4B71C36d17b1c70E438F8204907C5e068229cc) ] = 2;
        freeMintAccess[ address(0xEeA5F603558a2b700291511B030fF1F5edFb1287) ] = 2;
        freeMintAccess[ address(0xf208A854d8dd608Ad95644e7ca3A59a31aAcDE9E) ] = 2;
        freeMintAccess[ address(0xF27f990990803513D65710c6615664Ed8F6830b8) ] = 2;
        freeMintAccess[ address(0xff4Ca96eD50cd35e165Ac65a56b3524BBD30BfE1) ] = 2;
    }

}
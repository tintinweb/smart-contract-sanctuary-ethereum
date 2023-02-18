/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a 'uint256' to its ASCII 'string' decimal representation.
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
     * @dev Converts a 'uint256' to its ASCII 'string' hexadecimal representation.
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
     * @dev Converts a 'uint256' to its ASCII 'string' hexadecimal representation with fixed length.
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
     * @dev Converts an 'address' with fixed length of 20 bytes to its not checksummed ASCII 'string' hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

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

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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
     * 'interfaceId'. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721Permit {
  /// ERC165 bytes to add to interface array - set in parent contract
  ///
  /// _INTERFACE_ID_ERC4494 = 0x5604e225

  /// @notice Function to approve by way of owner signature
  /// @param spender the address to approve
  /// @param tokenId the index of the NFT to approve the spender on
  /// @param deadline a timestamp expiry for the permit
  /// @param sig a traditional or EIP-2098 signature
  function permit(
    address spender,
    uint256 tokenId,
    uint256 deadline,
    bytes memory sig
  ) external;
}

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     * The royalty receivers[] will split the royaltyAmount the addresses.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

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

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}


/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

abstract contract SignatureChecker is EIP712 {
    bytes32 private immutable _ORDER_TYPEHASH =
    keccak256(
      "Order(address token,uint256 tokenId,address paymentToken,uint256 buyNowPrice,uint256 deadline)"
    );

    constructor(string memory name, string memory version)
        EIP712(name, version)
    {
        this;
    }
    function _isValidSignature(
        bytes32 hash,
        bytes memory signature,
        address account
    ) internal pure returns (bool) {
        (address signer, ) = ECDSA.tryRecover(hash, signature);
        return signer == account;
    }
    
    function _getHash(
        address token,
        uint256 tokenId,
        address paymentToken,
        uint256 price,
        uint256 deadline
    ) internal view returns (bytes32) {
        bytes32 orderHash = keccak256(abi.encode(
                _ORDER_TYPEHASH,
                token, 
                tokenId, 
                paymentToken, 
                price, 
                deadline
            ));
        bytes32 hash = _hashTypedDataV4(orderHash);
        return hash;
    }
}

/* 
* @title ERC20Support
* @dev Implements the functionality of ERC20Support for Marketplace
* @author Wisdom A. https://abkabioye.me
* @notice use at your own risk
*/
contract ERC20Support is Ownable {
    mapping(address => bool) private supportedERC20;

    constructor() {
        supportedERC20[address(0)] = true; // ETH
    }

    function addSupportedERC20(address _token) public onlyOwner {
        supportedERC20[_token] = true;
    }

    function removeSupportedERC20(address _token) public onlyOwner {
        supportedERC20[_token] = false;
    }

    function isSupportedERC20(address _token) public view returns (bool) {
        return supportedERC20[_token];
    }

    modifier onlySupportedERC20(address _token) {
        require(isSupportedERC20(_token), "Token not supported");
        _;
    }

    function _transferERC20From(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal onlySupportedERC20(_token) {
        // check for deflationary tokens
        uint256 balanceBefore = IERC20(_token).balanceOf(_to);
        IERC20(_token).transferFrom(_from, _to, _amount);
        require(
            IERC20(_token).balanceOf(_to) == balanceBefore + _amount,
            "Amount transferred does not match"
        );
    }
}

contract RoyaltyManager {
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    // bytes4 private constant _INTERFACE_ID_ERC4494 = 0x5604e225;

    function _checkRoyalties(address _contract) internal view returns (bool) {
        (bool success) = IERC2981(_contract).supportsInterface(_INTERFACE_ID_ERC2981);
        return success;
    }

    function getRoyaltyInfo(address tokenContract, uint tokenId, uint256 salePrice) public view returns (address, uint256) {
        if (_checkRoyalties(tokenContract)) {
            return IERC2981(tokenContract).royaltyInfo(tokenId, salePrice);
        } else {
            return (address(0), 0);
        }
    }
}

contract FeeManager is Ownable {
    uint96 public constant MAX_FEE = 369; // 3.69% * feeBase
    uint96 public constant _feeBase = 10000; // 100%
    uint96 private _fee = 0; // 0.1% = 10
    address payable private _feeReceiver;

    constructor(address payable feeReceiver_, uint96 fee_) {
        setFeeReceiver(feeReceiver_);
        setFee(fee_);
    }

    function setFee(uint96 fee_) public onlyOwner {
        require(fee_ <= MAX_FEE, "Max fee is 369 - 3.69%");
        _fee = fee_;
    }

    function setFeeReceiver(address payable feeReceiver_) public onlyOwner {
        require(feeReceiver_ != address(0), "Fee address cannot be zero address");
        _feeReceiver = feeReceiver_;
    }

    function fee() public view returns (uint256) {
        return _fee;
    }

    function feeReceiver() public view returns (address payable) {
        return _feeReceiver;
    }

    function _payFeeETH(uint256 feeAmount) internal {
        _feeReceiver.transfer(feeAmount);
    }

    function _payFeeERC20(address token, uint256 feeAmount) internal {
        IERC20(token).transfer(_feeReceiver, feeAmount);
    }

    function _calculateFee(uint256 amount) internal view returns (uint256) {
        return (amount * _fee) / _feeBase;
    }
}

/* 
* @title Marketplace
* @dev Implements the functionality of a marketplace for NFTs
* @author Wisdom A. https://abkabioye.me
* @notice use at your own risk
*/
contract ERC721Marketplace is ERC20Support, FeeManager, RoyaltyManager, SignatureChecker, ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _itemsSold;

    enum SaleType { Fixed, Auction }
    enum OrderSide { Buy, Sell }

    struct Bid {
        address payable bidder;
        uint256 price;
    }

    struct MarketOrder {
        OrderSide side;
        address payable seller;
        address payable buyer;
        address paymentToken; // address(0) for ETH
        uint256 startPrice; // always 0 for fixed order
        uint256 buyNowPrice;
        uint256 duration; // always 0 for fixed order
        uint256 deadline;
    }

    mapping(IERC721 => mapping(uint256 => MarketOrder)) private _idToMarketItem;
    mapping(IERC721 => mapping(uint256 => Bid)) private _idToBid; // we keep only the highest bid

    string public name = "Adors Marketplace";
    string public symbol = "ADORS";
    string public version = "1.0";

    constructor(address payable _feeAddress, uint96 _fee) 
    FeeManager(_feeAddress, _fee) 
    SignatureChecker(name, version){}

    event NewListing(
        IERC721 indexed token,
        uint256 tokenId,
        address indexed seller,
        uint256 price,
        address paymentToken,
        SaleType saleType
    );

    event ListingCancelled(
        IERC721 indexed token,
        uint256 tokenId,
        address seller
    );

    event NewSale(
        IERC721 indexed token,
        uint256 tokenId,
        address indexed seller,
        address indexed buyer,
        uint256 price
    );

    event NewBid(
        IERC721 indexed token,
        uint256 tokenId,
        address indexed bidder,
        uint256 price
    );

    function getListing(
        IERC721 token,
        uint256 tokenId
    ) public view returns (MarketOrder memory) {
        return _idToMarketItem[token][tokenId];
    }

    function getBid(
        IERC721 token,
        uint256 tokenId
    ) public view returns (Bid memory) {
        return _idToBid[token][tokenId];
    }

    /* 
    * CREATE FIXED LISTING
    * CREATE BATCH FIXED LISTING
    * BUY WITH ETH OR ERC20
    */
    function createFixedListing(
        IERC721 token, 
        uint256 tokenId, 
        uint256 buyNowPrice,
        address paymentToken
    ) public onlySupportedERC20(paymentToken) {
        address sender = _msgSender();
        require(_idToMarketItem[token][tokenId].seller == address(0), "Item is already on sale");
        require(buyNowPrice > 0, "Price must be at least 1 wei");

        token.transferFrom(
            sender, 
            address(this), 
            tokenId
        );

        _idToMarketItem[token][tokenId] = MarketOrder({
            side: OrderSide.Sell,
            seller: payable(sender),
            buyer: payable(address(0)),
            paymentToken: paymentToken,
            startPrice: 0,
            buyNowPrice: buyNowPrice,
            duration: 0,
            deadline: 0
        });

        emit NewListing(
            token, 
            tokenId, 
            sender, 
            buyNowPrice, 
            paymentToken, 
            SaleType.Fixed
        );
    }

    function bulkFixedListing(
        IERC721 token, 
        uint256[] calldata tokenIds,
        uint256[] calldata buyNowPrices,
        address[] calldata paymentTokens
    ) external {
        require(tokenIds.length == buyNowPrices.length, "Token Id and price must be same length");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            createFixedListing(token, tokenIds[i], buyNowPrices[i], paymentTokens[i]);
        }
    }

    function buyWithETH(
        IERC721 token,
        uint256 tokenId
    ) public payable {
        address sender = _msgSender();
        uint incomingBidPrice = msg.value;

        MarketOrder memory item = _idToMarketItem[token][tokenId];
        require(item.seller != sender, "You cannot buy your own item");
        require(item.duration == 0, "Item is not a fixed listing");
        require(incomingBidPrice == item.buyNowPrice, "Incorrect price");
        require(item.paymentToken == address(0), "Item is not an ETH listing");

        _finaliseSale(
            token, 
            tokenId, 
            item, 
            Bid(
                payable(sender), 
                incomingBidPrice
            )
        );
    }

    function buyWithERC20(
        IERC721 token,
        uint256 tokenId
    ) public nonReentrant {
        address sender = _msgSender();
        MarketOrder memory item = _idToMarketItem[token][tokenId];
        require(item.seller != sender, "You cannot buy your own item");
        require(item.duration == 0, "Item is not a fixed listing");

        _transferERC20From(
            item.paymentToken, 
            sender, 
            address(this),
            item.buyNowPrice
        );

        _finaliseSale(
            token, 
            tokenId, 
            item, 
            Bid(
                payable(sender), 
                item.buyNowPrice
            )
        );
    }

    /* 
    * CREATE AUCTION LISTING
    * CREATE BATCH AUCTION LISTING
    * BID WITH ETH OR ERC20
    * ACCEPT BID
    */
    function createAuctionListing(
        IERC721 token, 
        uint256 tokenId, 
        uint256 startPrice, 
        uint256 buyNowPrice, 
        uint256 duration,
        address paymentToken
    ) public onlySupportedERC20(paymentToken) {
        address sender = _msgSender();
        require(_idToMarketItem[token][tokenId].seller == address(0), "Item is already on sale");
        require(buyNowPrice > startPrice, "Buy now price must be higher than start price");
        require(duration > 0, "Duration must be greater than zero");

        token.transferFrom(
            sender, 
            address(this), 
            tokenId
        );

        uint256 deadline = block.timestamp + duration;
        _idToMarketItem[token][tokenId] = MarketOrder({
            side: OrderSide.Sell,
            seller: payable(sender),
            buyer: payable(address(0)),
            paymentToken: paymentToken,
            startPrice: startPrice,
            buyNowPrice: buyNowPrice,
            duration: duration,
            deadline: deadline
        });

        emit NewListing(
            token, 
            tokenId, 
            sender, 
            startPrice, 
            paymentToken,
            SaleType.Auction
        );
    }

    function bulkAuction(
        IERC721 token,
        uint256[] calldata tokenIds,
        uint256[] calldata startPrices,
        uint256[] calldata buyNowPrices,
        uint256[] calldata durations,
        address[] calldata paymentTokens
    ) external {
        uint tokenIdLength = tokenIds.length;

        require(tokenIdLength == startPrices.length, "Token id and start prices must be same length");
        require(tokenIdLength == buyNowPrices.length, "Token id and buy now prices must be same length");
        require(tokenIdLength == durations.length, "Token id and duration must be same length");
        require(tokenIdLength == paymentTokens.length, "Token id and payment token must be same length");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            createAuctionListing(token, tokenIds[i], startPrices[i], buyNowPrices[i], durations[i], paymentTokens[i]);
        }
    }

    function createBidETH(
        IERC721 token, 
        uint256 tokenId
    ) public payable {
        address sender = _msgSender();
        uint incomingBidPrice = msg.value; // expected to be greater than the last bid or start price
        MarketOrder memory item = _idToMarketItem[token][tokenId];
        
        require(item.seller != sender, "You cannot bid on your own item");
        require(item.deadline > block.timestamp, "Auction has ended"); 
        require(item.paymentToken == address(0), "Item is not an ETH auction");

        Bid memory bid = _idToBid[token][tokenId];
        uint256 lastBidPrice = bid.price != 0 ? bid.price : item.startPrice;

        require(incomingBidPrice > lastBidPrice, "Bid must be higher than the last bid");

        if (bid.bidder != address(0)) {
            bid.bidder.transfer(bid.price);
        }

        // TODO: Fair bidding algorithm in the future
        if (incomingBidPrice >= item.buyNowPrice) {
            // finalise auction immediately
            _finaliseSale(
                token, 
                tokenId, 
                item, 
                Bid({
                    bidder: payable(sender), 
                    price: incomingBidPrice
                })
            );
        } else {
            _idToBid[token][tokenId] = Bid({
                bidder: payable(sender),
                price: incomingBidPrice
            });
            emit NewBid(
                token, 
                tokenId, 
                sender, 
                incomingBidPrice
            );
        }
    }
    
    function createBidERC20(
        IERC721 token, 
        uint256 tokenId, 
        uint256 bidAmount
    ) public nonReentrant {
        address sender = _msgSender();
        MarketOrder memory item = _idToMarketItem[token][tokenId];
        
        require(item.seller != sender, "You cannot bid on your own item");
        require(item.deadline > block.timestamp, "Auction ended"); 
    
        Bid memory bid = _idToBid[token][tokenId];
        uint256 lastBidPrice = bid.price != 0 ? bid.price : item.startPrice;

        require(bidAmount > lastBidPrice, "Bid must be higher than the last bid");

        _transferERC20From(
            item.paymentToken,
            sender, 
            address(this), 
            bidAmount 
        );
    
        if (bid.bidder != address(0)) {
            _transferERC20From(
                item.paymentToken, 
                address(this), 
                bid.bidder, 
                bid.price
            );
        }

        // TODO: Fair bidding algorithm in the future
        if (bidAmount >= item.buyNowPrice) {
            // finalise auction immediately
            _finaliseSale(
                token, 
                tokenId, 
                item, 
                Bid({
                    bidder: payable(sender), 
                    price: bidAmount
                })
            );
        } else {
            _idToBid[token][tokenId] = Bid({
                bidder: payable(sender),
                price: bidAmount
            });
            emit NewBid(
                token, 
                tokenId, 
                sender, 
                bidAmount
            );
        }
    }
    
    // Accept bid if current bid satisfies the seller
    function acceptBid(
        IERC721 token, 
        uint256 tokenId
    ) public nonReentrant {
        MarketOrder memory item = _idToMarketItem[token][tokenId];
        require(item.seller == _msgSender(), "not seller");
        require(item.duration != 0, "Not an auction");

        Bid memory bid = _idToBid[token][tokenId];
        require(bid.price > 0, "Zero bid");
 
        _finaliseSale(
            token, 
            tokenId, 
            item, 
            bid
        );
    }

    /* 
    * Anyone can call this function to finalise an auction
    * This is useful if the auction has ended and the seller has not called acceptBid
    * Auction must have ended, and there must be a bid
    */
    function finaliseAuction(
        IERC721 token, 
        uint256 tokenId
    ) public nonReentrant {
        MarketOrder memory item = _idToMarketItem[token][tokenId];
        Bid memory bid = _idToBid[token][tokenId];
        
        require(item.deadline < block.timestamp, "Auction not ended");
        require(bid.price > 0, "Zero bid");
        
        _finaliseSale(
            token, 
            tokenId, 
            item, 
            bid
        );
    }

    /* 
    * CANCEL LISTING - Cannot cancel auction if there is a bid
    */
    function cancelListing(
        IERC721 token, 
        uint256 tokenId
    ) external {
        address sender = _msgSender();
        MarketOrder memory item = _idToMarketItem[token][tokenId];
        require(item.seller == sender, "not seller");

        if (item.duration != 0) {
            // item is an auction
            // cannot cancel if there is a bid
            require(_idToBid[token][tokenId].bidder == address(0), "Auction has a bid");
        }
    
        delete _idToMarketItem[token][tokenId];
        // delete _idToBid[token][tokenId];
        token.transferFrom(
            address(this), 
            item.seller, 
            tokenId
        );
        emit ListingCancelled(
            token, 
            tokenId, 
            sender
        );
    }
    
    /* 
    * Atomic functions
    * Offchain listing creation and order matching
    */
    // buyer executes offchain order signed by seller
    function atomicBuyETH(
        address token,
        uint256 tokenId,
        MarketOrder memory order,
        bytes memory orderSignature, // order signature
        bytes memory signature // permit signature
    ) public payable nonReentrant {
        address sender = _msgSender();
        uint incomingBidPrice = msg.value;

        require(order.buyer == sender, "You must be the buyer of the token");
        require(order.side == OrderSide.Buy, "Wrong order side");
        require(incomingBidPrice == order.buyNowPrice, "Incorrect price");

        bool isValidSignature = _isValidSignature(
            _getHash(
                token,
                tokenId,
                order.paymentToken,
                order.buyNowPrice,
                order.deadline
            ),
            orderSignature,
            order.seller
        );

        require(isValidSignature, "Invalid order signature");

        IERC721Permit(token)
        .permit(
            address(this), 
            tokenId, 
            order.deadline, 
            signature
        );

        _finaliseSale(
            IERC721(token), 
            tokenId, 
            order, 
            Bid(
                payable(sender), 
                incomingBidPrice
            )
        );
    }

    // buyer executes offchain order signed by seller
    function atomicBuyERC20(
        address token,
        uint256 tokenId,
        MarketOrder memory order,
        bytes memory orderSignature, // order signature
        bytes memory signature // permit signature
    ) public nonReentrant onlySupportedERC20(order.paymentToken) {
        address sender = _msgSender();

        require(order.buyer == sender, "You must be the buyer of the token");
        require(order.side == OrderSide.Buy, "Wrong order side");

        bool isValidOrderSignature = _isValidSignature(
            _getHash(
                token,
                tokenId,
                order.paymentToken,
                order.buyNowPrice,
                order.deadline
            ),
            orderSignature,
            order.seller
        );

        require(isValidOrderSignature, "Invalid order signature");

        _transferERC20From(
            order.paymentToken, 
            sender, 
            address(this), 
            order.buyNowPrice
        );

        IERC721Permit(token)
        .permit(
            address(this), 
            tokenId, 
            order.deadline, 
            signature
        );

        _finaliseSale(
            IERC721(token), 
            tokenId, 
            order, 
            Bid(
                payable(sender),
                 order.buyNowPrice
            )
        );
    }

    // Seller accepts offer from buyer's approval offchain
    function atomicSellERC20(
        address token,
        uint256 tokenId,
        MarketOrder memory order, 
        bytes memory orderSignature // 
    ) public nonReentrant {
        address sender = _msgSender();

        require(order.seller == sender, "You must be the seller of the token");
        require(order.side == OrderSide.Sell, "Wrong order side");

        bool isValidOrderSignature = _isValidSignature(
            _getHash(
                token,
                tokenId,
                order.paymentToken,
                order.buyNowPrice,
                order.deadline
            ),
            orderSignature,
            order.buyer
        );

        require(isValidOrderSignature, "Invalid order signature");

        _transferERC20From(
            order.paymentToken, 
            order.buyer, 
            address(this), 
            order.buyNowPrice
        );

        IERC721(token)
        .transferFrom(
            sender, 
            address(this), // could be sent to order.buyer to save gas but _finaliseSale will need to be modified
            tokenId
        );

        _finaliseSale(
            IERC721(token), 
            tokenId, 
            order, 
            Bid(
                payable(order.buyer), 
                order.buyNowPrice
            )
        );
    }

    /* 
    * INTERNAL FUNCTION
    */    
    function _finaliseSale(
        IERC721 token,
        uint256 tokenId,
        MarketOrder memory item,
        Bid memory sale
    ) internal {       
        delete _idToMarketItem[token][tokenId];
        delete _idToBid[token][tokenId];

        (address _royaltyAddress, uint256 _royaltyAmount) = getRoyaltyInfo(address(token), tokenId, sale.price);
        uint256 _mfee = _calculateFee(sale.price);
        uint256 _sellAmount = sale.price - (_mfee + _royaltyAmount);
        
        token.transferFrom(address(this), sale.bidder, tokenId);
        
        if (item.paymentToken == address(0)) {
            // payment in ETH
            item.seller.transfer(_sellAmount);
            _payFeeETH(_mfee);
            if (_royaltyAddress != address(0) && _royaltyAmount > 0) {
                payable(_royaltyAddress).transfer(_royaltyAmount);
            }
        } else {
            // payment in ERC20
            _transferERC20From(
                item.paymentToken, 
                address(this), 
                item.seller, 
                _sellAmount
            );
            _payFeeERC20(item.paymentToken, _mfee);
            if (_royaltyAddress != address(0) && _royaltyAmount > 0) {
                _transferERC20From(
                    item.paymentToken, 
                    address(this), 
                    _royaltyAddress, 
                    _royaltyAmount
                );
            }
        }

        _itemsSold.increment();
        emit NewSale(
            token, 
            tokenId, 
            item.seller, 
            sale.bidder, 
            sale.price
        );
    }
}
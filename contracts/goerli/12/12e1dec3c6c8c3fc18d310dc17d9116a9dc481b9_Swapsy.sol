//SPDX-License-Identifier: MIT
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


// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

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
        InvalidSignatureV // Deprecated in v4.8
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

// File: @openzeppelin/contracts/utils/cryptography/EIP712.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/cryptography/draft-EIP712.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

// EIP-712 is Final as of 2022-08-11. This file is deprecated.


// File: ISwapsyManager.sol


pragma solidity ^0.8.17;

interface ISwapsyManager {
    function getFeeForSeller() external returns (uint256);

    function getFeeForBuyer() external returns (uint256);
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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.16;


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

// File: Whitelist.sol


pragma solidity >=0.4.22 <0.9.0;




contract Whitelist is Ownable, EIP712 {
    bytes32 public constant WHITELIST_TYPEHASH =
        keccak256("Whitelist(bytes32 amountIn,bytes32 amountOut,address tokenIn,address tokenOut,bytes32 totalAmountInEth,bytes32 totalAmountOutEth,bytes32 swapId,uint256 timeout)");
    address public whitelistSigner;
/*
    function _isSenderWhitelisted(
        uint256 amountIn,
        uint256 amountOut,
        address tokenIn, 
        address tokenOut,
        bytes32 totalAmountInEth,
        bytes32 totalAmountOutEth, 
        bytes32 swapId,
        uint256 timeout,
        bytes memory _signature
    ) public view {
        require(
            getSigner(amountIn, amountOut, tokenIn, tokenOut, totalAmountInEth, totalAmountOutEth, swapId, timeout, _signature) ==
                whitelistSigner,
            "Whitelist: Invalid signature"
        ); 
    
    } */
 
    modifier isSenderWhitelisted(
        bytes32 amountIn,
        bytes32 amountOut,
        address tokenIn, 
        address tokenOut,
        bytes32 totalAmountInEth,
        bytes32 totalAmountOutEth,
        bytes32 swapId,
        uint256 timeout,
        bytes memory _signature
    ) {
        require(
            getSigner(amountIn, amountOut, tokenIn, tokenOut, totalAmountInEth, totalAmountOutEth, swapId, timeout, _signature) ==
                whitelistSigner,
            "Whitelist: Invalid signature"
        );
        _;
    } 

    constructor(string memory name, string memory version)
        EIP712(name, version)
    {}

    function setWhitelistSigner(address _address) external onlyOwner {
        whitelistSigner = _address;
    }

    function getSigner(
        bytes32 amountIn,
        bytes32 amountOut,
        address tokenIn, 
        address tokenOut,
        bytes32 totalAmountInEth,
        bytes32 totalAmountOutEth,
        bytes32 swapId,
        uint256 timeout,
        bytes memory _signature
    ) public view returns (address) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(WHITELIST_TYPEHASH, amountIn, amountOut, tokenIn, tokenOut, totalAmountInEth, totalAmountOutEth, swapId, timeout)
            )
        );
        return ECDSA.recover(digest, _signature);
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

// File: Swapsy.sol


pragma solidity ^0.8.17;


contract Swapsy is ReentrancyGuard, Ownable, Whitelist {
    enum STATUS {
        OPEN,
        CANCELLED,
        EXPIRED,
        SUCCESS
    }

    struct SWAPS {
        address seller;
        uint256 amountIn;
        uint256 amountOut;
        address tokenIn;
        address tokenOut;
        uint256 totalAmountInEth;
        uint256 totalAmountOutEth; 
        uint256 sellerFeeEth;
        bytes32 swapId;
        uint256 timeout;
        uint256 deadline;
        STATUS status;
    }

    struct USER_SWAPS {
        uint256 id;
        SWAPS swap;
    }

    uint256 public totalSwaps;
    ISwapsyManager public swapsyManager;
    mapping(uint256 => SWAPS) private _allSwaps;
    mapping(address => uint256[]) private _swapsByUser;
    mapping(address => uint256) private _revenue;

    event Sell(
        address indexed seller,
        address indexed tokenIn, 
        address indexed tokenOut, 
        uint256 amountIn, 
        uint256 amountOut, 
        uint256 totalAmountInEth,
        uint256 totalAmountOutEth,
        uint256 sellerFeeEth,
        bytes32 swapId,
        uint256 timeout,
        uint256 id, 
        uint256 deadline
    );
    event Buy(
        address indexed buyer,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 totalAmountOutEth,
        uint256 id,
        bytes32 swapId
    );
    event Cancel(
        address indexed seller,
        address indexed tokenIn,
        uint256 amountIn,
        uint256 sellerFeeEth,
        uint256 id,
        bytes32 swapId
    );
    event Refund(
        address indexed seller,
        address indexed tokenIn,
        uint256 amountIn,
        uint256 sellerFeeEth,
        uint256 id,
        bytes32 swapId
    );

    constructor(address _swapsyManager) Whitelist("Swapsy", "1") {
        swapsyManager = ISwapsyManager(_swapsyManager);
    }

    function sellETH(
        bytes32 amountIn,
        bytes32 amountOut,
        address tokenIn,
        address tokenOut,
        bytes32 totalAmountInEth,
        bytes32 totalAmountOutEth,
        bytes32 swapId,
        uint256 timeout,
        uint256 deadline,
        bytes memory _signature
    ) public payable nonReentrant isSenderWhitelisted(amountIn, amountOut, tokenIn, tokenOut, totalAmountInEth, totalAmountOutEth, swapId, timeout, _signature)
    {
        uint256 _amountIn = bytes32ToString(amountIn);
        uint256 _amountOut = bytes32ToString(amountOut);
        uint256 _totalAmountInEth = bytes32ToString(totalAmountInEth);
        uint256 _totalAmountOutEth = bytes32ToString(totalAmountOutEth);

        require(timeout > block.timestamp, "Swapsy: signature expired");
        require(deadline > block.timestamp, "Swapsy: past timestamp");
        require((_amountIn > 0) && (_amountOut > 0), "Swapsy: zero I/O amount");
        
        uint256 sellerFee = ISwapsyManager(swapsyManager).getFeeForSeller();
        uint256 sellerFeeAmt = (_totalAmountInEth * sellerFee) / 1000;
        
        require(_amountIn + sellerFeeAmt == msg.value, "Swapsy: sell order failed");

        _sell(msg.sender, _amountIn, _amountOut, address(0), tokenOut, _totalAmountInEth, _totalAmountOutEth, sellerFeeAmt, swapId, timeout, deadline);
    }

    function sellToken(
        bytes32 amountIn,
        bytes32 amountOut,
        address tokenIn,
        address tokenOut,
        bytes32 totalAmountInEth,
        bytes32 totalAmountOutEth,
        bytes32 swapId,
        uint256 timeout,
        uint256 deadline,
        bytes memory _signature
    ) public payable nonReentrant isSenderWhitelisted(amountIn, amountOut, tokenIn, tokenOut, totalAmountInEth, totalAmountOutEth, swapId, timeout, _signature)
    {

        uint256 _amountIn = bytes32ToString(amountIn);
        uint256 _amountOut = bytes32ToString(amountOut);
        uint256 _totalAmountInEth = bytes32ToString(totalAmountInEth);
        uint256 _totalAmountOutEth = bytes32ToString(totalAmountOutEth);

        require(timeout > block.timestamp, "Swapsy: signature expired");
        require(deadline > block.timestamp, "Swapsy: past timestamp");
        require((_amountIn > 0) && (_amountOut > 0), "Swapsy: zero I/O amount");
        
        uint256 sellerFee = ISwapsyManager(swapsyManager).getFeeForSeller();
        uint256 sellerFeeAmt = (_totalAmountInEth * sellerFee) / 1000;

        require(IERC20(tokenIn).transferFrom(msg.sender, address(this), _amountIn) && msg.value == sellerFeeAmt ,"Swapsy: sell order failed");

        _sell(msg.sender, _amountIn, _amountOut, tokenIn, tokenOut, _totalAmountInEth, _totalAmountOutEth, sellerFeeAmt, swapId, timeout, deadline);
    }



    function _sell(
        address seller,
        uint256 amountIn,
        uint256 amountOut,
        address tokenIn,
        address tokenOut,
        uint256 totalAmountInEth,
        uint256 totalAmountOutEth,
        uint256 sellerFeeEth,
        bytes32 swapId,
        uint256 timeout,
        uint256 deadline
    ) internal 
    {
        
        require(deadline > block.timestamp, "Swapsy: old time set");

        _allSwaps[totalSwaps] = SWAPS(
            seller,
            amountIn,
            amountOut,
            tokenIn,
            tokenOut,
            totalAmountInEth,
            totalAmountOutEth,
            sellerFeeEth,
            swapId,
            timeout,
            deadline,
            STATUS.OPEN
        );
        _swapsByUser[seller].push(totalSwaps);

        emit Sell(
            seller,
            tokenIn,
            tokenOut,
            amountIn,
            amountOut,
            totalAmountInEth,
            totalAmountOutEth,
            sellerFeeEth,
            swapId,
            timeout,
            totalSwaps++,
            deadline
        );
    }

    function buyWithETH(uint256 id) public payable nonReentrant {
        
        uint256 buyerFee = ISwapsyManager(swapsyManager).getFeeForSeller();
        uint256 buyerFeeAmt = (_allSwaps[id].totalAmountOutEth * buyerFee) / 1000;
        
        require(
            msg.value == _allSwaps[id].amountOut + buyerFeeAmt,
            "Swapsy: incorrect price"
        );
        require(
            _allSwaps[id].tokenOut == address(0),
            "Swapsy: only for ether price"
        );

        _buy(id);
    }

    function buyWithToken(uint256 id) public payable nonReentrant {

        uint256 buyerFee = ISwapsyManager(swapsyManager).getFeeForSeller();
        uint256 buyerFeeAmt = (_allSwaps[id].totalAmountOutEth * buyerFee) / 1000;

        require(
            _allSwaps[id].tokenOut != address(0),
            "Swapsy: only for token price"
        );
        require(
            msg.value == buyerFeeAmt,
            "Swapsy: incorrect price"
        );

        _buy(id);
    }

        function _buy(uint256 id) internal {
        SWAPS memory _swaps = _allSwaps[id];
        require(_swaps.status == STATUS.OPEN, "Swapsy: unavailable swap");
        require(_swaps.deadline >= block.timestamp, "Swapsy: expired swap");

        /* Buyer pays and transfers amount to the seller 
        uint256 sellerFee = ISwapsyManager(swapsyManager).getFeeForSeller();
        uint256 sellerFeeAmt = (_swaps.amountOut * sellerFee) / 1000;
        uint256 sellerTransAmt = _swaps.amountOut - sellerFeeAmt; */

        _revenue[_swaps.tokenOut] += _swaps.sellerFeeEth;
        if (_swaps.tokenOut == address(0)) {
            require(
                msg.value == _swaps.amountOut + _swaps.sellerFeeEth,
                "Swapsy: check of platform fee failed"
            );

            (bool toSeller, ) = payable(_swaps.seller).call{
                value: _swaps.amountOut
            }("");
            require(toSeller, "Swapsy: Eth transfer to seller failed");
        } else {
            /*require(
                IERC20(_swaps.tokenOut).transferFrom(
                    msg.sender,
                    address(this),
                    sellerFeeAmt
                ),
                "Swapsy: platform fee failed"
            );*/

            require(
                IERC20(_swaps.tokenOut).transferFrom(
                    msg.sender,
                    _swaps.seller,
                    _swaps.amountOut
                ),
                "Swapsy: Token transfer to seller failed"
            );
        } 
                
        /* Buyer gets the purchased item 
        uint256 buyerFee = ISwapsyManager(swapsyManager).getFeeForBuyer();
        uint256 buyerFeeAmt = (_swaps.amountIn * buyerFee) / 1000;
        uint256 buyerTransAmt = _swaps.amountIn - buyerFeeAmt; */

        uint256 buyerFee = ISwapsyManager(swapsyManager).getFeeForSeller();
        uint256 buyerFeeAmt = (_swaps.totalAmountInEth * buyerFee) / 1000;

        _revenue[_swaps.tokenOut] += buyerFeeAmt;
        if (_swaps.tokenIn == address(0)) {
            (bool sent, ) = payable(msg.sender).call{value: _swaps.amountIn}("");
            require(sent, "Swapsy: ETH Transfer to buyer failed");
        } else {
            require(
                IERC20(_swaps.tokenIn).transfer(msg.sender, _swaps.amountIn),
                "Swapsy: Token Transfer to buyer failed"
            );
        }

        _allSwaps[id].status = STATUS.SUCCESS;
        emit Buy(
            msg.sender,
            _swaps.tokenIn,
            _swaps.tokenOut,
            _swaps.amountIn,
            _swaps.amountOut,
            _swaps.totalAmountOutEth,
            id,
            _swaps.swapId


        ); 
    } 

    function cancel(uint256 id) external nonReentrant {
        _cancel(id);
    }

    function _cancel(uint256 id) internal {
        SWAPS memory _swaps = _allSwaps[id];
        require(_swaps.seller == msg.sender, "Swapsy: not seller");
        require(_swaps.status == STATUS.OPEN, "Swapsy: unavailable swap");
        require(_swaps.deadline >= block.timestamp, "Swapsy: swap expired");

        /* Instead using claim(), let's do direct refund to seller for minimize gas */
        if (_swaps.tokenIn == address(0)) {
            (bool sent, ) = payable(msg.sender).call{value: _swaps.amountIn + _swaps.sellerFeeEth}(
                ""
            );
            require(sent, "Swapsy: cancellation failed");
        } else {
            require(
                IERC20(_swaps.tokenIn).transfer(msg.sender, _swaps.amountIn),
                "Swapsy: cancellation failed"
            );
            (bool sent,) = msg.sender.call{value: _swaps.sellerFeeEth}("");
            require(sent, "Failed to send Ether");
        }

        _allSwaps[id].status = STATUS.CANCELLED;
        emit Cancel(_swaps.seller, _swaps.tokenIn, _swaps.amountIn, _swaps.sellerFeeEth, id, _swaps.swapId);
    }

    function refund(uint256 id) external nonReentrant {
        _refund(id);
    }

    function _refund(uint256 id) internal {
        SWAPS memory _swaps = _allSwaps[id];
        require(_swaps.seller == msg.sender, "Swapsy: not seller");
        require(
            (_swaps.status == STATUS.OPEN) &&
                (_swaps.deadline < block.timestamp),
            "Swapsy: cannot be refund"
        );

        if (_swaps.tokenIn == address(0)) {
            (bool sent, ) = payable(_swaps.seller).call{value: _swaps.amountIn + _swaps.sellerFeeEth}(
                ""
            );
            require(sent, "Swapsy: refund failed");
        } else {
            require(
                IERC20(_swaps.tokenIn).transfer(_swaps.seller, _swaps.amountIn),
                "Swapsy: refund failed"
            );
            (bool sent,) = msg.sender.call{value: _swaps.sellerFeeEth}("");
            require(sent, "Failed to send Ether");
        }

        _swaps.status = STATUS.EXPIRED;
        emit Refund(_swaps.seller, _swaps.tokenIn, _swaps.amountIn, _swaps.sellerFeeEth, id, _swaps.swapId);
    }

    function getSwapById(uint256 id) public view returns (SWAPS memory) {
        return _allSwaps[id];
    }

    function getSwapsByUser(address user) public view returns (USER_SWAPS[] memory) {
        USER_SWAPS[] memory swaps = new USER_SWAPS[](_swapsByUser[user].length);
        for (uint256 i = 0; i < _swapsByUser[user].length; i++) {
            swaps[i] = USER_SWAPS(
                _swapsByUser[user][i],
                _allSwaps[_swapsByUser[user][i]]
            );
        }
        return swaps;
    }

    function getRevenue(address token) external view returns (uint256 amount) {
        return _revenue[token];
    }

    function withdraw(address token, uint256 amount) external onlyOwner nonReentrant {
        require(
            amount > 0 && _revenue[token] >= amount,
            "Swapsy: incorrect amount to withdraw"
        );

        _revenue[token] -= amount;
        if (token == address(0)) {
            payable(msg.sender).transfer(amount);
        } else {
            require(
                IERC20(token).transfer(msg.sender, amount),
                "Swapsy: withdraw failed"
            );
        }
    }

    function setSwapsyManager(address _swapsyManager) external onlyOwner {
        require(
            _swapsyManager != address(0),
            "Swapsy: impossible manager address"
        );

        swapsyManager = ISwapsyManager(_swapsyManager);
    }

function bytes32ToString(bytes32 _bytes32) public pure returns (uint256) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        string memory newString = string(bytesArray);

        uint X = stringToUint(newString);

        return X;
    }

function stringToUint(string memory s) public pure returns (uint) {
        bytes memory b = bytes(s);
        uint result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            uint256 c = uint256(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
        return result;
    }
}
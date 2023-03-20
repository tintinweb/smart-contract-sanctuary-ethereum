//SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Strings.sol
/*
░██████╗░██╗░░░░░░░██╗░█████╗░██████╗░░██████╗██╗░░░██╗  ██╗░░░██╗░░███╗░░
██╔════╝░██║░░██╗░░██║██╔══██╗██╔══██╗██╔════╝╚██╗░██╔╝  ██║░░░██║░████║░░
╚█████╗░░╚██╗████╗██╔╝███████║██████╔╝╚█████╗░░╚████╔╝░  ╚██╗░██╔╝██╔██║░░
░╚═══██╗░░████╔═████║░██╔══██║██╔═══╝░░╚═══██╗░░╚██╔╝░░  ░╚████╔╝░╚═╝██║░░
██████╔╝░░╚██╔╝░╚██╔╝░██║░░██║██║░░░░░██████╔╝░░░██║░░░  ░░╚██╔╝░░███████╗
╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝╚═╝░░░░░╚═════╝░░░░╚═╝░░░  ░░░╚═╝░░░╚══════╝
*/
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `u
     int256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT 
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

pragma solidity ^0.8.0;

contract Whitelist is Ownable, EIP712 {
    bytes32 public constant WHITELIST_TYPEHASH =
        keccak256("Whitelist(bytes32 amountIn,bytes32 amountOut,address tokenIn,address tokenOut,bytes32 totalAmountInEth,bytes32 totalAmountOutEth,bytes32 swapId,uint256 timeout,address sender)");
    address public whitelistSigner;
    mapping(bytes32 => bool) public usedHashes;
    mapping(address => uint256) public nonces;
 
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
        address sender = msg.sender;
        uint256 nonce = nonces[sender]++;
        bytes32 hash = getHash(amountIn, amountOut, tokenIn, tokenOut, totalAmountInEth, totalAmountOutEth, swapId, timeout, msg.sender, nonce);
        require(!usedHashes[hash], "Whitelist: signature reused");
        usedHashes[hash] = true;
        require(getSigner(hash, _signature) == whitelistSigner, "Whitelist: Invalid signature");
        _;
    } 

    constructor(string memory name, string memory version)
        EIP712(name, version)
    {}

    function setWhitelistSigner(address _address) external onlyOwner {
        whitelistSigner = _address;
    }

    function getSigner(
        bytes32 hash,
        bytes memory _signature
    ) public pure returns (address) {
        return ECDSA.recover(hash, _signature);
    }

    function getHash(
        bytes32 amountIn,
        bytes32 amountOut,
        address tokenIn, 
        address tokenOut,
        bytes32 totalAmountInEth,
        bytes32 totalAmountOutEth,
        bytes32 swapId,
        uint256 timeout,
        address sender,
        uint256 nonce
    ) public view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(WHITELIST_TYPEHASH, amountIn, amountOut, tokenIn, tokenOut, totalAmountInEth, totalAmountOutEth, swapId, timeout, sender, nonce)
            )
        );
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

interface ERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Permit.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File: SafeMath.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}



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
        uint256 deadline;
        STATUS status;
    }

    struct USER_SWAPS {
        uint256 id;
        SWAPS swap;
    }

    struct SWAPID_SWAPS {
        uint256 id;
        SWAPS swap;
    }

    uint256 internal withdrawnRevenue;
    uint256 internal revenue;
    uint256 public totalSwaps;
    ISwapsyManager public swapsyManager;
    mapping(uint256 => SWAPS) private _allSwaps;
    mapping(address => uint256[]) private _swapsByUser;
    mapping(bytes32 => uint256[]) private _swapsBySwapId;
    ERC721 public NFT = NFT;

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
        uint256 buyerFeeAmt,
        uint256 sellerFee,   
        uint256 id,
        bytes32 swapId
    );
    event Cancel(
        address indexed seller,
        address indexed tokenIn,
        uint256 refundedAmount,
        uint256 totalAmountInEth,
        uint256 refundedFeeEth,
        uint256 id,
        bytes32 swapId
    );
    event Refund(
        address indexed seller,
        address indexed tokenIn,
        uint256 amountIn,
        uint256 totalAmountInEth,
        uint256 sellerFeeEth,
        uint256 id,
        bytes32 swapId
    );
    event SwapsyManagerUpdate(
        address indexed newManager
    );
    event newNftCollection(
        ERC721 indexed newNftAddr
    );

    constructor(address _swapsyManager, ERC721 _nftAddress) Whitelist("Swapsy", "1") {
        swapsyManager = ISwapsyManager(_swapsyManager);
        NFT = _nftAddress;

    }


    /* As Swapsy, we are not constrained by market prices, 
    which is why we have made the decision to calculate both the Seller Fee and Buyer Fee at the time of creating a swap.
    */

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
        
    
        try ISwapsyManager(swapsyManager).getFeeForSeller() returns (uint256 fee) {
            if (fee > 50) {
                // Handle the case where the fee is greater than 50
                    revert("Seller fee is greater than 5%");
        }
        } catch {
                // Handle any errors that occur while calling getFeeForSeller()
                    revert("Error retrieving seller fee");
        }
                  
        uint256 sellerFeeAmt;  

        if(ERC721(NFT).balanceOf(msg.sender) > 0){
            sellerFeeAmt = 0;
            require(_amountIn == msg.value, "Swapsy: Only ETH");
        } else {
            
            sellerFeeAmt = (_amountIn * ISwapsyManager(swapsyManager).getFeeForSeller()) / 1000;
            require(_amountIn + sellerFeeAmt == msg.value, "Swapsy: ETH + FEE");
        }


        _sell(msg.sender, _amountIn, _amountOut, address(0), tokenOut, _totalAmountInEth, _totalAmountOutEth, sellerFeeAmt, swapId, deadline);
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

        /* Casting  bytes32 to uint256 is needed to support the complexity in our backend to handle the signature */
        uint256 _amountIn = bytes32ToString(amountIn);
        uint256 _amountOut = bytes32ToString(amountOut);
        uint256 _totalAmountInEth = bytes32ToString(totalAmountInEth);
        uint256 _totalAmountOutEth = bytes32ToString(totalAmountOutEth);

        require(timeout > block.timestamp, "Swapsy: signature expired");
        require(deadline > block.timestamp, "Swapsy: past timestamp");
        require((_amountIn > 0) && (_amountOut > 0), "Swapsy: zero I/O amount");
        
        
       
        try ISwapsyManager(swapsyManager).getFeeForSeller() returns (uint256 fee) {
            if (fee > 50) {
                // Handle the case where the fee is greater than 50
                    revert("Seller fee is greater than 5%");
        }
        } catch {
                // Handle any errors that occur while calling getFeeForSeller()
                    revert("Error retrieving seller fee");
        }
        
        
        
        uint256 sellerFeeAmt;

         if(ERC721(NFT).balanceOf(msg.sender) > 0){

            require(msg.value == 0); 
            sellerFeeAmt = 0;

        } else {
            
            sellerFeeAmt = (_totalAmountInEth * ISwapsyManager(swapsyManager).getFeeForSeller()) / 1000;
            require(sellerFeeAmt == msg.value ,"Swapsy: ETH - Platform Fee wrong");
        }

        SafeERC20.safeTransferFrom(IERC20(tokenIn), msg.sender, address(this), _amountIn);
        

        _sell(msg.sender, _amountIn, _amountOut, tokenIn, tokenOut, _totalAmountInEth, _totalAmountOutEth, sellerFeeAmt, swapId, deadline);
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
        uint256 deadline
    ) internal 
    {
       
        
        uint256 currentTotalSwaps = totalSwaps;

        _allSwaps[currentTotalSwaps] = SWAPS(
            seller,
            amountIn,
            amountOut,
            tokenIn,
            tokenOut,
            totalAmountInEth,
            totalAmountOutEth,
            sellerFeeEth,
            swapId,
            deadline,
            STATUS.OPEN
        );

        _swapsByUser[seller].push(currentTotalSwaps);
        _swapsBySwapId[swapId].push(currentTotalSwaps);


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
            totalSwaps++,
            deadline
        );
    }

    function buyWithETH(uint256 id) public payable nonReentrant {
        
        try ISwapsyManager(swapsyManager).getFeeForBuyer() returns (uint256 fee) {
            if (fee > 50) {
             // Handle the case where the fee is greater than 50
                revert("Buyer fee is greater than 5%");
            }
            } catch {
                // Handle any errors that occur while calling getFeeForBuyer()
                revert("Error retrieving buyer fee");
                }

        
        uint256 buyerFeeAmt;
        
         if(ERC721(NFT).balanceOf(msg.sender) > 0){

            buyerFeeAmt = 0;
            require(msg.value == _allSwaps[id].amountOut,
            "Swapsy: incorrect amount");

        } else {
            
            buyerFeeAmt = (_allSwaps[id].totalAmountOutEth * ISwapsyManager(swapsyManager).getFeeForBuyer()) / 1000;
            require(
            msg.value == _allSwaps[id].amountOut + buyerFeeAmt,
            "Swapsy: incorrect amount");
        }

        require(
            _allSwaps[id].tokenOut == address(0),
            "Swapsy: only for eth transfer"
        );
    
        _buy(id, buyerFeeAmt);
    }

    function buyWithToken(uint256 id) public payable nonReentrant {
        
        try ISwapsyManager(swapsyManager).getFeeForBuyer() returns (uint256 fee) {
            if (fee > 50) {
                // Handle the case where the fee is greater than 50
                revert("Buyer fee is greater than 5%");
            }
            } catch {
                // Handle any errors that occur while calling getFeeForBuyer()
                revert("Error retrieving buyer fee");
            }
        
        
        uint256 buyerFeeAmt;

        if(ERC721(NFT).balanceOf(msg.sender) > 0){

            buyerFeeAmt = 0;

        } else {
            
            buyerFeeAmt = (_allSwaps[id].totalAmountOutEth * ISwapsyManager(swapsyManager).getFeeForBuyer()) / 1000;
            require(
            msg.value == buyerFeeAmt,
            "Swapsy: incorrect amount");
        }

        require(
            _allSwaps[id].tokenOut != address(0),
            "Swapsy: only for token swap"
        );
        
        _buy(id, buyerFeeAmt);
    }

        function _buy(uint256 id, uint256 buyerFeeAmt) internal {
        SWAPS memory _swaps = _allSwaps[id];
        require(_swaps.status == STATUS.OPEN, "Swapsy: unavailable swap");
        require(_swaps.deadline >= block.timestamp, "Swapsy: expired swap");


        
        uint256 sellerFee = _swaps.sellerFeeEth;

        if (sellerFee > 0) {
                revenue += sellerFee;
            }   
            
        
        

        _allSwaps[id].status = STATUS.SUCCESS;

        if (_swaps.tokenOut == address(0)) {
         

            (bool toSeller, ) = payable(_swaps.seller).call{
                value: _swaps.amountOut
            }("");
            require(toSeller, "Swapsy: Eth transfer to seller failed");
        } else {
            
            SafeERC20.safeTransferFrom(IERC20(_swaps.tokenOut), msg.sender, _swaps.seller, _swaps.amountOut);
           
        } 
                

        if(buyerFeeAmt > 0){
            revenue += buyerFeeAmt;
        } 

        if (_swaps.tokenIn == address(0)) {
            (bool sent, ) = payable(msg.sender).call{value: _swaps.amountIn}("");
            require(sent, "Swapsy: ETH Transfer to buyer failed");
        } else {
            
            SafeERC20.safeTransfer(IERC20(_swaps.tokenIn), msg.sender, _swaps.amountIn);
            
        }

        emit Buy(
            msg.sender,
            _swaps.tokenIn,
            _swaps.tokenOut,
            _swaps.amountIn,
            _swaps.amountOut,
            _swaps.totalAmountOutEth,
            buyerFeeAmt,
            sellerFee,
            id,
            _swaps.swapId
        ); 
    } 


    /* The Swap can only be canceled if not expired, expired swaps are handled further bellow */
    function cancel(uint256 id) external nonReentrant {
        _cancel(id);
    }

    function _cancel(uint256 id) internal {
        SWAPS memory _swaps = _allSwaps[id];
        require(_swaps.seller == msg.sender, "Swapsy: not the seller");
        require(_swaps.status == STATUS.OPEN, "Swapsy: unavailable swap");
        require(_swaps.deadline >= block.timestamp, "Swapsy: swap expired");

        _allSwaps[id].status = STATUS.CANCELLED;

        if (_swaps.tokenIn == address(0)) {
            (bool sent, ) = payable(msg.sender).call{value: _swaps.amountIn + _swaps.sellerFeeEth}(
                ""
            );
            require(sent, "Swapsy: cancellation failed to send ETH");
        } else {
            
            IERC20 token = IERC20(_swaps.tokenIn);
            SafeERC20.safeTransfer(token, msg.sender, _swaps.amountIn);
            (bool sent,) = msg.sender.call{value: _swaps.sellerFeeEth}("");
            require(sent, "Swapsy: cancellation failed to send Tokens"); 
            
            }

        emit Cancel(_swaps.seller, _swaps.tokenIn, _swaps.amountIn, _swaps.totalAmountInEth, _swaps.sellerFeeEth, id, _swaps.swapId);
    }


    /* These functions are called in order to get the Tokens refunded after the Swap is expired */

    function refund(uint256 id) external nonReentrant {
        _refund(id);
    }

    function _refund(uint256 id) internal {
        SWAPS memory _swaps = _allSwaps[id];
        require(_swaps.seller == msg.sender, "Swapsy: not the seller");
        require(
            (_swaps.status == STATUS.OPEN) &&
                (_swaps.deadline < block.timestamp),
            "Swapsy: Swap is not expired"
        );

        _allSwaps[id].status = STATUS.EXPIRED;

        if (_swaps.tokenIn == address(0)) {
            (bool sent, ) = payable(_swaps.seller).call{value: _swaps.amountIn + _swaps.sellerFeeEth}(
                ""
            );
            require(sent, "Swapsy: ETH refund failed");
        } else {

                IERC20 token = IERC20(_swaps.tokenIn);
                
                SafeERC20.safeTransfer(token, msg.sender, _swaps.amountIn);
                (bool sent,) = msg.sender.call{value: _swaps.sellerFeeEth}("");
                require(sent, "Swapsy: Token refund failed"); 
                }

        emit Refund(_swaps.seller, _swaps.tokenIn, _swaps.amountIn, _swaps.totalAmountInEth, _swaps.sellerFeeEth, id, _swaps.swapId);
    }


    /* Search Swapsy BY user or ID */  

    function getSwapById(uint256 id) public view returns (SWAPS memory) {
        return _allSwaps[id];
    }
    
    function getSwapsByUser(address user) public view returns (USER_SWAPS[] memory) {
        uint256 length = _swapsByUser[user].length; 
            USER_SWAPS[] memory swaps = new USER_SWAPS[](length);
                for (uint256 i = 0; i < length; i++) {
                    swaps[i] = USER_SWAPS(
                    _swapsByUser[user][i],
                    _allSwaps[_swapsByUser[user][i]]
                    );
            }
        return swaps;
    }

    
    function getSwapsBySwapId(bytes32 swapId) public view returns (SWAPID_SWAPS[] memory) {
        uint256 length = _swapsBySwapId[swapId].length; 
            SWAPID_SWAPS[] memory swaps = new SWAPID_SWAPS[](length);
                for (uint256 i = 0; i < length; i++) {
                    swaps[i] = SWAPID_SWAPS(
                    _swapsBySwapId[swapId][i],
                    _allSwaps[_swapsBySwapId[swapId][i]]
                );
            }
        return swaps;
    }

    /* Check and Withdraw the available Fee Revenue */
    function getRevenue() external view onlyOwner returns(uint256) {
        return revenue;
    }

    function getRevenueWithdrawn() external view onlyOwner returns(uint256) {
        return withdrawnRevenue;
    }


    function withdraw(uint256 amount) external onlyOwner nonReentrant {
        uint256 currentRevenue = revenue; 
            require(
                    amount > 0 && currentRevenue >= amount,
                    "Swapsy: incorrect amount to withdraw"
                    );

            revenue -= amount;
            withdrawnRevenue += amount;

                (bool sent, ) = payable(msg.sender).call{value: amount}("");
                require(sent, "Swapsy: withdraw failed");
        }


    /* Change the Swapsy Manager Contract Address */

    function setSwapsyManager(address _swapsyManager) external onlyOwner {
        require(
            _swapsyManager != address(0),
            "Swapsy: Wrong manager address"
        );

        swapsyManager = ISwapsyManager(_swapsyManager);

        emit SwapsyManagerUpdate(_swapsyManager);
    }


    /* Helper Functions, needed for the Signature */

    function bytes32ToString(bytes32 _bytes32) internal pure returns (uint256) {
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

    function stringToUint(string memory s) internal pure returns (uint) {
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

    function updateNft(ERC721 _newNftAddress) public onlyOwner {
        NFT = _newNftAddress;
        emit newNftCollection(NFT);
    }

    function walletHoldsToken() public view returns (bool) {
        return ERC721(NFT).balanceOf(msg.sender) > 0;
    }

    
}
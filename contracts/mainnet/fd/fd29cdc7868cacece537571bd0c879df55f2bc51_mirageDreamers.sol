/**
 *Submitted for verification at Etherscan.io on 2022-08-21
*/

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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


// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

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
            /// @solidity memory-safe-assembly
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
            /// @solidity memory-safe-assembly
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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/finance/PaymentSplitter.sol


// OpenZeppelin Contracts (last updated v4.7.0) (finance/PaymentSplitter.sol)

pragma solidity ^0.8.0;




/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned. The distribution of shares is set at the
 * time of contract deployment and can't be updated thereafter.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract PaymentSplitter is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Getter for the amount of payee's releasable Ether.
     */
    function releasable(address account) public view returns (uint256) {
        uint256 totalReceived = address(this).balance + totalReleased();
        return _pendingPayment(account, totalReceived, released(account));
    }

    /**
     * @dev Getter for the amount of payee's releasable `token` tokens. `token` should be the address of an
     * IERC20 contract.
     */
    function releasable(IERC20 token, address account) public view returns (uint256) {
        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        return _pendingPayment(account, totalReceived, released(token, account));
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 payment = releasable(account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token, address account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 payment = releasable(token, account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

// File: tinyERC721_ID.sol


pragma solidity ^0.8.0;








error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error TokenDataQueryForNonexistentToken();
error OwnerQueryForNonexistentToken();
error OperatorQueryForNonexistentToken();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

contract TinyERC721 is Context, ERC165, IERC721, IERC721Metadata {
  using Address for address;
  using Strings for uint256;

  struct TokenData {
    address owner;
    bytes12 aux;
  }

  uint256 private immutable _maxBatchSize;

  mapping(uint256 => TokenData) private _tokens;
  uint256 private _mintCounter = 151;
  uint256 private _claimCounter;

  string private _name;
  string private _symbol;

  mapping(uint256 => address) private _tokenApprovals;
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxBatchSize_
  ) {
    _name = name_;
    _symbol = symbol_;
    _maxBatchSize = maxBatchSize_;
  }

  function totalSupply() public view virtual returns (uint256) {
    return (_mintCounter - 151 + _claimCounter);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function name() public view virtual override returns (string memory) {
    return _name;
  }

  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
  }

  function _baseURI() internal view virtual returns (string memory) {
    return '';
  }

  function balanceOf(address owner) public view virtual override returns (uint256) {
    if (owner == address(0)) revert BalanceQueryForZeroAddress();

    uint256 total = totalSupply() + 150 - _claimCounter;
    uint256 count;
    address lastOwner;
    for (uint256 i; i <= total; ++i) {
      if(_exists(i)) {
        address tokenOwner = _tokens[i].owner;
        if (tokenOwner != address(0)) lastOwner = tokenOwner;
        if (lastOwner == owner) ++count;
      }
    }

    return count;
  }

  function _tokenData(uint256 tokenId) internal view returns (TokenData storage) {
    if (!_exists(tokenId)) revert TokenDataQueryForNonexistentToken();

    TokenData storage token = _tokens[tokenId];
    uint256 currentIndex = tokenId;
    while (token.owner == address(0)) {
      unchecked {
        --currentIndex;
      }
      token = _tokens[currentIndex];
    }

    return token;
  }

  function ownerOf(uint256 tokenId) public view virtual override returns (address) {
    if (!_exists(tokenId)) revert OwnerQueryForNonexistentToken();
    return _tokenData(tokenId).owner;
  }

  function approve(address to, uint256 tokenId) public virtual override {
    TokenData memory token = _tokenData(tokenId);
    address owner = token.owner;
    if (to == owner) revert ApprovalToCurrentOwner();

    if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
      revert ApprovalCallerNotOwnerNorApproved();
    }

    _approve(to, tokenId, token);
  }

  function getApproved(uint256 tokenId) public view virtual override returns (address) {
    if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

    return _tokenApprovals[tokenId];
  }

  function setApprovalForAll(address operator, bool approved) public virtual override {
    if (operator == _msgSender()) revert ApproveToCaller();

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    TokenData memory token = _tokenData(tokenId);
    if (!_isApprovedOrOwner(_msgSender(), tokenId, token)) revert TransferCallerNotOwnerNorApproved();

    _transfer(from, to, tokenId, token);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    safeTransferFrom(from, to, tokenId, '');
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual override {
    TokenData memory token = _tokenData(tokenId);
    if (!_isApprovedOrOwner(_msgSender(), tokenId, token)) revert TransferCallerNotOwnerNorApproved();

    _safeTransfer(from, to, tokenId, token, _data);
  }

  function _safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    TokenData memory token,
    bytes memory _data
  ) internal virtual {
    _transfer(from, to, tokenId, token);

    if (to.isContract() && !_checkOnERC721Received(from, to, tokenId, _data))
      revert TransferToNonERC721ReceiverImplementer();
  }

  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    if (tokenId > 150) {
      return tokenId < _mintCounter;
    } else if (tokenId <= 150) {
      return tokenId <= _claimCounter;
    } else {
      return false;
    }
  }

  function _isApprovedOrOwner(
    address spender,
    uint256 tokenId,
    TokenData memory token
  ) internal view virtual returns (bool) {
    address owner = token.owner;
    return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
  }

  function _safeMint(address to, uint256 quantity) internal virtual {
    _safeMint(to, quantity, '');
  }

  function _safeMintID(address to, uint256 _id, uint256 quantity) internal virtual {
    _safeMintID(to, _id, quantity, '');
  }

  function _safeMint(
    address to,
    uint256 quantity,
    bytes memory _data
  ) internal virtual {
    uint256 startTokenId = _mintCounter;
    _mint(to, quantity);

    if (to.isContract()) {
      unchecked {
        for (uint256 i; i < quantity; ++i) {
          if (!_checkOnERC721Received(address(0), to, startTokenId + i, _data))
            revert TransferToNonERC721ReceiverImplementer();
        }
      }
    }
  }

  function _safeMintID(
    address to,
    uint256 _id,
    uint256 quantity,
    bytes memory _data
  ) internal virtual {
    _mintID(to, _id, quantity);
    _claimCounter += quantity;
    if (to.isContract()) {
      unchecked {
        if (!_checkOnERC721Received(address(0), to, _id, _data))
            revert TransferToNonERC721ReceiverImplementer();
      }
    }
  }

  function _mint(address to, uint256 quantity) internal virtual {
    if (to == address(0)) revert MintToZeroAddress();
    if (quantity == 0) revert MintZeroQuantity();

    uint256 startTokenId = _mintCounter;
    _beforeTokenTransfers(address(0), to, startTokenId, quantity);

    unchecked {
      for (uint256 i; i < quantity; ++i) {
        if (_maxBatchSize == 0 ? i == 0 : i % _maxBatchSize == 0) {
          TokenData storage token = _tokens[startTokenId + i];
          token.owner = to;
          token.aux = _calculateAux(address(0), to, startTokenId + i, 0);
        }

        emit Transfer(address(0), to, startTokenId + i);
      }
      _mintCounter += quantity;
    }

    _afterTokenTransfers(address(0), to, startTokenId, quantity);
  }

  function _mintID(address to, uint256 _id, uint256 quantity) internal virtual {
    if (to == address(0)) revert MintToZeroAddress();
    if (quantity == 0) revert MintZeroQuantity();

    uint256 startTokenId = _id;
    _beforeTokenTransfers(address(0), to, startTokenId, quantity);

    unchecked {
      for (uint256 i; i < quantity; ++i) {
        if (_maxBatchSize == 0 ? i == 0 : i % _maxBatchSize == 0) {
          TokenData storage token = _tokens[startTokenId + i];
          token.owner = to;
          token.aux = _calculateAux(address(0), to, startTokenId + i, 0);
        }

        emit Transfer(address(0), to, startTokenId + i);
      }
    }

    _afterTokenTransfers(address(0), to, startTokenId, quantity);
  }

  function _transfer(
    address from,
    address to,
    uint256 tokenId,
    TokenData memory token
  ) internal virtual {
    if (token.owner != from) revert TransferFromIncorrectOwner();
    if (to == address(0)) revert TransferToZeroAddress();

    _beforeTokenTransfers(from, to, tokenId, 1);

    _approve(address(0), tokenId, token);

    unchecked {
      uint256 nextTokenId = tokenId + 1;
      if (_exists(nextTokenId)) {
        TokenData storage nextToken = _tokens[nextTokenId];
        if (nextToken.owner == address(0)) {
          nextToken.owner = token.owner;
          nextToken.aux = token.aux;
        }
      }
    }

    TokenData storage newToken = _tokens[tokenId];
    newToken.owner = to;
    newToken.aux = _calculateAux(from, to, tokenId, token.aux);

    emit Transfer(from, to, tokenId);

    _afterTokenTransfers(from, to, tokenId, 1);
  }

  function _calculateAux(
    address from,
    address to,
    uint256 tokenId,
    bytes12 current
  ) internal view virtual returns (bytes12) {}

  function _approve(
    address to,
    uint256 tokenId,
    TokenData memory token
  ) internal virtual {
    _tokenApprovals[tokenId] = to;
    emit Approval(token.owner, to, tokenId);
  }

  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
      return retval == IERC721Receiver.onERC721Received.selector;
    } catch (bytes memory reason) {
      if (reason.length == 0) {
        revert TransferToNonERC721ReceiverImplementer();
      } else {
        assembly {
          revert(add(32, reason), mload(reason))
        }
      }
    }
  }

  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}

  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}
}
// File: dreamers.sol

/*
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMNOOXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXO0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMk,'lKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc.,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMNo...cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc...lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMK:....cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc....:0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMk,.....cKMMMMMMMMMMMMMMMMMMMMMMMMMMWKc.....,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMNd.......cKWMMMMMMMMMMMMMMMMMMMMMMMKkc.......oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMKc........cKMMMMMMMMMMMMMMMMMMMMMMKc'........cKMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMO,.........cKMMMMMMMMMMMMMMMMMMMMKc..........,OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMWd'..........cKWMMMMMMMMMMMMMMMMMKl............dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMXc...;;.......cKMMMMMMMMMMMMMMMMKc...'co,......cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMO;..,x0:.......cKMMMMMMMMMMMMMMKl...cxKKc......;OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMWd'..;0W0:.......cKWMMMMMMMMMMMKc...cKWMNo......'xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMXl...lXMW0:.......c0WMMMMMMMMMKl...cKMMMWx'......lXXkxxddddoddddxxxkO0KXXNWWWMMMMMMMMMMM
MMMMMMMMMMMM0;...dWMMW0:.......c0WMMMMMMMKl...cKMMMMMO;......;0k,.'''',,''.......'',;::cxXMMMMMMMMMM
MMMMMMMMMMMWx'..,kMMMMW0:.......c0WMMMMMKl...cKMMMMWWKc......'xXOO00KKKKK00Okdoc,'......cKMMMMMMMMMM
MMMMMMMMMMMXl...:0MMMMMW0:.......:0WMMMKl...cKMMWKkdxKd.......oNMMMMMMMMMMMMMMMWXOd:'...lXMMMMMMMMMM
MMMMMMMMMMM0:...lXMMMMMMWO:.......:0MMKl...cKMWKo,..;0k,......:KMMMMMMMMMMMMMMMMMMWNOc'.oNMMMMMMMMMM
MMMMMMMMMMWx'..'dWMMMMMMMW0:.......:0Kl...cKMNk;....,k0:......,kMMMMMMMMMMMMMMMMMMMMMXl'oNMMMMMMMMMM
MMMMMMMMMMNl...,OMMMMMMMMMW0:.......;;...cKWXo'......dKl.......oNMMMMMMMMMMMMMMMMMMMMM0:dWMMMMMMMMMM
MMMMMMMMMM0:...:KMMMMMMMMMMW0c..........lKMNo'.......oXd'......cKMMMMMMMMMMMMMMMMMMMMMNKXMMMMMMMMMMM
MMMMMMMMMWk,...lXMMMMMMMMMMMWKc........cKMWx,.......,kWk,......,OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMNo...'dWMMMMMMMMMMMMMKl......lKMMK:........:KMK:.......dNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMWO;...'xWMMMMMMMMMMMMMMXl'...lKMMWx'........lXMXl.......;OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMNKOOd;.....;dkO0NMMMMMMMMMMMXo''lXMMMNo.........lNW0:........,lxkO0XWMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMN0kkkkkkkkkkxxkOXWMMMMMMMMMMMN0ONMMMMNo.........lXWXOkkkkxxxxxxxxxk0WMXOkkkkkkkkkkkkkkkkkOXMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo.........:0MMMMMMMMMMMMMMMMMMMMN0OOxl,........,lxO0NMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx'........'xWMMMMMMMMMMMMMMMMMMMMMMMMNd'......'dNMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0:.........:KMMMMMMMMMMMMMMMMMMMMMMMMMk,......'xWMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd'.........oXMMMMMMMMMMMMMMMMMMMMMMMMO,......'kWMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo.........'oXMMMMMMMMMMMMMMMMMMMMMMMO,......'kMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo'.........c0WMMMMMMMMMMMMMMMMMMMMMO,......'kMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx;.........,dXWMMMMMMMMMMMMMMMMMMMO,......'kMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKo;'........;d0NMMMMMMMMMMMMMMMMMO,......'kWMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKOxc'.......':dOKNWMMMMMMMMMMMWk,......'kWMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0xl;'.......,:ldxkO00KK00Od:.......;OMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0kdl:;''.......''''''....',;cox0NMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXK0OkxxddddddddxxkkO0XNWMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
*/

// Contract authored by August Rosedale (@augustfr)
// https://miragegallery.ai

// TinyERC721 used (https://github.com/tajigen/tiny-erc721)
// Modifications were made to the TinyERC721 contract in order to allow for 'Sentient' members to claim from the first 150 tokens at any point in time.

pragma solidity ^0.8.16;






interface mirageContracts {
    function balanceOf(address owner, uint256 _id) external view returns (uint256);
}

interface mirageProjects {
  function balanceOf(address owner) external view returns (uint256);
}


contract mirageDreamers is TinyERC721, ReentrancyGuard, Ownable {

  using Strings for uint256;

  mapping(uint256 => uint256) public sentientClaimed;

  uint256 private maxSentientClaim = 3;

  uint256 public publicPrice = 0.06 ether;
  uint256 public holderPrice = 0.04 ether;
  uint256 public memberPrice = 0.02 ether;

  uint256 private maxMemberMint = 20;
  uint256 private maxHolderMint = 5;
  uint256 private maxPartnerMint = 5;
  address[] private mulIntelHolders;
  uint256[] private numIntelHeld;

  uint256 public maxSupply = 8000;

  bool private revealed;
  string private unrevealedURI = "ipfs://QmQoBSSf8ZvvPbUfVBnbKBZim9pJvgEvJS5zpfwCkp2HgW";

  uint256 public claimCounter;

  string public baseURI;

  bool private paused;

  bool public metadataFrozen;

  mirageProjects private curated;
  mirageProjects private cryptoNative;
  mirageProjects private AlejandroAndTaylor;
  mirageProjects private earlyWorks;

  salePhase public phase = salePhase.unOpened;

  address private immutable _adminSigner;

   struct Coupon {
      bytes32 r;
      bytes32 s;
      uint8 v;
  }

  struct Minted {
      uint256 member;
      uint256 id;
      uint256 holder;
      uint256 partner;
  }

  struct intelAllotment {
    uint256 maxMint;
    uint256 numMinted;
  }

  enum salePhase {
      unOpened,
      memberSale,
      presale,
      openSale,
      publicSale,
      closed
  }

  mirageContracts public membershipContract;

  mapping(address => Minted) numMinted;
  mapping(uint256 => Minted) idMinted;
  mapping(address => intelAllotment) intelQuantity;

  constructor(string memory name, string memory symbol, address adminSigner, address membershipAddress) TinyERC721(name, symbol, 0) {
      membershipContract = mirageContracts(membershipAddress);
      _adminSigner = adminSigner;
      cryptoNative = mirageProjects(0x89568Fc8d04B3f833209144b77F39b71078e3CB0);
      AlejandroAndTaylor = mirageProjects(0x63400da86a6b42dac41075667cF871a5Ef93802F);
      earlyWorks = mirageProjects(0x3Cf6e4ff99D616d44Be53E90F74eAE5D150Cb726);
      curated = mirageProjects(0xb7eC7bbd2d2193B47027247FC666fB342D23c4B5);

    //   cryptoNative = mirageProjects(0x662508A2767A1A978DF4CFd16f77A3358C613599);
    //   AlejandroAndTaylor = mirageProjects(0x662508A2767A1A978DF4CFd16f77A3358C613599);
    //   earlyWorks = mirageProjects(0x662508A2767A1A978DF4CFd16f77A3358C613599);
    //   curated = mirageProjects(0x662508A2767A1A978DF4CFd16f77A3358C613599);
  }

  function updateMintStatus(salePhase phase_) external onlyOwner {
      require(uint8(phase_) > uint8(phase), "Increase only");
      phase = phase_;
  }

  function updateMintLimits(uint256 _maxMember, uint256 _maxHolder, uint256 _maxPartner) public onlyOwner {
      maxMemberMint = _maxMember;
      maxHolderMint = _maxHolder;
      maxPartnerMint = _maxPartner;
      for(uint i = 0; i < mulIntelHolders.length; i++) {
          intelQuantity[mulIntelHolders[i]].maxMint = numIntelHeld[i] * maxMemberMint;
      }
  }

  function updateMintPrices(uint256 _public, uint256 _holder, uint256 _member) public onlyOwner {
      //input prices in wei
      publicPrice = _public;
      holderPrice = _holder;
      memberPrice = _member;
  }

  function togglePause() public onlyOwner {
      paused = !paused;
  }

  function sentientMint(uint256 numberOfTokens, uint256 _membershipId) public payable nonReentrant {
      require(_membershipId < 50, "Not a valid Sentient ID");
      require(!paused, "Minting paused");
      require(phase >= salePhase.memberSale && phase < salePhase.publicSale, "Not in member sale phase");
      require(membershipContract.balanceOf(msg.sender,_membershipId) > 0, "No membership tokens in this wallet");
      require(msg.value >= numberOfTokens * memberPrice, "Insufficient Payment: Amount of Ether sent is not correct.");
      require(numberOfTokens + totalSupply() <= 7850 + claimCounter, "Minting would exceed max supply");
      require(idMinted[_membershipId].id + numberOfTokens <= maxMemberMint, "Would exceed max allotment for this phase");
      idMinted[_membershipId].id += numberOfTokens;
      _safeMint(msg.sender,numberOfTokens);
  }

  function setIntelAllotment(address[] memory _addresses, uint256[] memory numHeld) public onlyOwner {
    require(_addresses.length == numHeld.length, "Array lengths don't match");
    //input number of intelligent memberships held by a single address
    mulIntelHolders = _addresses;
    numIntelHeld = numHeld;
    for(uint i = 0; i < _addresses.length; i++) {
        intelQuantity[mulIntelHolders[i]].maxMint = numIntelHeld[i] * maxMemberMint;
    }
  }

  function intelligentMint(uint256 numberOfTokens, Coupon memory coupon) public payable nonReentrant{
    require(!paused, "Minting paused");
    require(msg.value >= numberOfTokens * memberPrice, "Must send minimum value to mint!");
    require(phase >= salePhase.memberSale && phase < salePhase.publicSale, "Not in member sale phase");
    require(numberOfTokens + totalSupply() <= 7850 + claimCounter, "Minting would exceed max supply");
    bytes32 digest = keccak256(abi.encode(msg.sender,"member"));
    require(_isVerifiedCoupon(digest, coupon), "Invalid coupon");
    uint256 maxMint = intelQuantity[msg.sender].maxMint;
    if (maxMint == 0) {
        maxMint = maxMemberMint;
    }
    require(intelQuantity[msg.sender].numMinted + numberOfTokens <= maxMint, "Would exceed allotment");
    intelQuantity[msg.sender].numMinted += numberOfTokens;
    _safeMint(msg.sender,numberOfTokens);
  }

   function holderMint(uint256 numberOfTokens, Coupon memory coupon) public payable nonReentrant {
        require(!paused, "Minting paused");
        require(phase >= salePhase.presale && phase < salePhase.publicSale, "Not in presale phase");
        require(msg.value >= numberOfTokens * holderPrice, "Insufficient Payment: Amount of Ether sent is not correct.");
        require(numberOfTokens + totalSupply() <= 7850 + claimCounter, "Minting would exceed max supply");
        require(numMinted[msg.sender].holder + numberOfTokens <= maxHolderMint, "Minted max allotment for this sale phase");
        bytes32 digest = keccak256(abi.encode(msg.sender,"standard"));
        require(_isVerifiedCoupon(digest, coupon), "Invalid coupon");
        numMinted[msg.sender].holder += numberOfTokens;
        _safeMint(msg.sender,numberOfTokens);
  }

  function partnerMint(uint256 numberOfTokens, Coupon memory coupon) public payable nonReentrant {
      require(!paused, "Minting paused");
      require(phase >= salePhase.presale && phase < salePhase.publicSale, "Not in presale phase");
      require(msg.value >= numberOfTokens * publicPrice, "Insufficient Payment: Amount of Ether sent is not correct.");
      require(numberOfTokens + totalSupply() <= 7850 + claimCounter, "Minting would exceed max supply");
      require(numMinted[msg.sender].partner + numberOfTokens <= maxPartnerMint, "Minted max allotment for this sale phase");
      bytes32 digest = keccak256(abi.encode(msg.sender,"secondary"));
      require(_isVerifiedCoupon(digest, coupon), "Invalid coupon");
      numMinted[msg.sender].partner += numberOfTokens;
      _safeMint(msg.sender,numberOfTokens);
  }

  function openHolderPresale(uint256 numberOfTokens) public payable nonReentrant {
      require(!paused, "Minting paused");
      require(numberOfTokens <= 10, "Can't mint more than 10 tokens per transaction");
      require(phase >= salePhase.openSale && phase < salePhase.publicSale, "Not in presale phase");
      require(msg.value >= numberOfTokens * holderPrice, "Insufficient Payment: Amount of Ether sent is not correct.");
      require(numberOfTokens + totalSupply() <= 7850 + claimCounter, "Minting would exceed max supply");
      require(cryptoNative.balanceOf(msg.sender) > 0 || AlejandroAndTaylor.balanceOf(msg.sender) > 0 || earlyWorks.balanceOf(msg.sender) > 0 || curated.balanceOf(msg.sender) > 0, "No MG tokens held");
      _safeMint(msg.sender,numberOfTokens);
  }

  function publicMint(uint256 numberOfTokens) public payable nonReentrant {
      require(!paused, "Minting paused");
      require(phase == salePhase.publicSale, "Not in public sale phase");
      require(numberOfTokens <= 10, "Can't mint more than 10 tokens per transaction");
      require(msg.value >= numberOfTokens * publicPrice, "Insufficient Payment: Amount of Ether sent is not correct.");
      require(numberOfTokens + totalSupply() <= 7850 + claimCounter, "Minting would exceed max supply");
      _safeMint(msg.sender,numberOfTokens);
  }

  function _isVerifiedCoupon(bytes32 digest, Coupon memory coupon) internal view returns (bool) {
      address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
      require(signer != address(0), "ECDSA: invalid signature"); // Added check for zero address
      return signer == _adminSigner;
  }

  function claimSentient(uint256 membershipId, uint256 numberOfTokens) public {
      require(phase >= salePhase.memberSale, "Claiming not open");
      require(membershipId < 50, "Must be a Sentient Membership ID (0-49)");
      require(membershipContract.balanceOf(msg.sender, membershipId) == 1, "Wallet does not own this membership ID");
      require(sentientClaimed[membershipId] + numberOfTokens <= maxSentientClaim, "Sentient Memberships can only claim 3 in total");
      require(claimCounter + numberOfTokens <= 150, "All have been claimed");
      sentientClaimed[membershipId] += numberOfTokens;
      _safeMintID(msg.sender,claimCounter + 1, numberOfTokens);
      claimCounter += numberOfTokens;
  }

  function airdrop(address[] memory addresses, uint256 numberOfTokens) public onlyOwner {
      require(totalSupply() + numberOfTokens <= 7850 + claimCounter, "Exceeds maximum token supply.");
      for (uint256 i = 0; i < addresses.length; i++) {
          _safeMint(addresses[i],numberOfTokens);
      }
  }

  function freezeMetadata() public onlyOwner {
      require(!metadataFrozen, "Already frozen");
      metadataFrozen = true;
  }

  function reveal(string memory _URI) public onlyOwner {
      baseURI = _URI;
      revealed = true;
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
  }

  function tokenURI(uint256 tokenID) public override view returns (string memory) {
      if (!_exists(tokenID)) revert URIQueryForNonexistentToken();
      if (!revealed) {
          return unrevealedURI;
      } else {
          return string.concat(baseURI,Strings.toString(tokenID));
      }
  }

  function updateURI(string memory _baseTokenURI, string memory _unrevealedURI) external onlyOwner {
      require(!metadataFrozen, "Metadata is frozen");
      baseURI = _baseTokenURI;
      unrevealedURI = _unrevealedURI;
  }

  function withdraw(address secondaryPayee) public onlyOwner {
      uint mainBalance = address(this).balance * 9 / 10;
      uint secondaryBalance = address(this).balance / 10;
      payable(msg.sender).transfer(mainBalance);
      payable(secondaryPayee).transfer(secondaryBalance);
  }

  function withdrawERC20(IERC20 token, address to) external onlyOwner {
      token.transfer(to, token.balanceOf(address(this)));
  }
}
 
/*
.....,:ldxxxkkkkkkxxdl:,'....,coxxkkkkkkxxdo:,'........................'''''''''''''''''.......................;:lloooool:;,'...........................................................................
......',lxkkxkxxkkkkkxoc;''...':oxkkkkkkkkkxdc;,'........................''''''',,,,,,,,,''....................;cloodoooooll:;,'........................................................................
........'cdkkxkkkkkkkxxxl;'.....,cdxxxkkkkkkkxo:,'.......................'''',;;;:::::::::;,''.................,:ldddoooolooolc:;;,'....................................................................
..........,cdkkkkkkkkkkxxo:'.....';lxkkkkkkxkkxdl;'......................'',;:cllllloooollllc:;'''....'.........,:ooooolcccloolllcc:,''''...............................................................
............;lxkkkkkkkkkkxdl;......,cdxkkkkkkkkkxo:'.....................',;clooddddddooooooooll:,,;:clcc:;'.....'cllccc::;;:cloooolllc:;,''............................................................
.............':oxkkkkkkkkxxxdc'.....';oxxkkkkkkkkkdc,'..................',;:loooddoooooooollllol;.',;::ccllc;'...,cllc::::;;;;;clllloooolc;,,'....................''''''''..............................
..............',cxkkkkkkkxxxxko:'.....,cdxkkkkkkkkkkdc,................''';clloooolllllllllllllc;.',,,,;;::c::;:::clolcc:::::;;;:::cllolllcc:;,''',,...........',;;;;;,,,,'.............................
................';okkkkkkkxxkkkko;.....';lxkkkkkkkkkkxo:'.............''',,;:cloolllcclllccllccc;''',,,,,,;::::lol:;;:c::c::::::::::ccccccccclc:::cc,'.',;,...,:ccccc::;;;,'............................
..................':dkkkkkkkkkkkkdc'.....':oxkkkkkkkkkxdc,..........';ccloolc::ccllllccllcclcccc:,,,,,'''',;:clodd:,',,,;;::::::::::::::ccccllllllol;',,,,;,,,:cllllllc:::;,............................
....................,cdkkkkkkkxxxkxl,.....';lxkkkkkkkkkkxl:;'.......:ooxOkkkkxol:;:cccllllllllloc;,;;,'..',;:cldxd:,;;,,,,;;::c:ccc::::::ccccccllllc;';ll:;,,;clooooollccc::,...........................
....................'',ldxxkkkkkkxxxd:'...'',:dkkkkkkkkkkxdl:,'....'ldoxOOOOkkkxdo:;,;;::::::ccl:,,,,'....',:cclllc;,,,,;;;:::cc:cccc:::::c::::cclll:,,ldoc;,;cllooollcccccc;...........................
......................'';ldxxkkkkkkkkxo;'..'..,cdkkkkkkkkkxxdc;'...;oddxxxxxxxkkkxdol:;,,,,',,,,,,;,,'....,;:::cccc:;,,;ccccccccc:ccc::ccccc::cccccc:;;lddl:;;:ccllllccccccc:'..........................
........................',:ldkkkkkkkxxxdc'......,lxkkkkkkkkkkxl:,.':loddddddddddxxxxxxdoc:;,,'',,,;;;,'.'';::::cclccc:::cllllloollccc::;:::ccccllllllcloddolc;;ccccccc::c::c:'..........................
..........................',coxkkkkkkxxxxl,......'cxkkkkkkkkkkxol:,:lddddddddooooddoodk0Okkdlll::cllcccc::::;;:clllccclllloolllloooooll::::c::cccclllodxdooooc;;clc::cccc::c:'..........................
............................',cdxkkxkkkxkxl;'.....';dkkkkkkkkkkxddl:clxxdddollllllloodk000OOOxl:cddddddoolcclloxxddollllllllllllloodddoolcc::;;:cloolooddollooc:;:llccllcccc:'..........................
..............................':oxkkkkkkkkkdc,'.....,cxkkkkkkkkkxddollddoolllllodooodxO000OkxoclodxdddooddxxkkOO00OOxdlllllccllllloodddoollcc:clooollloooollllll:;lolllllccc:'..........................
...............................';oxkxkkkxxkkkd:,......:okkkkkkkkkxdddddolllllloddxxxkO0K00kdoloddxkxddoodk00O00000000Oxoccllcllllllooddddoooooooooollloooollclloo:coddollcc:;'..........................
................................';coxkkxxkkkkkxl;'.....,lxkkkkkkkxxxddddolldddddddxO0000OOkdc;cdxkkxxdddxkO000000000000Oxdoooooooooodxkkkxxxkkxddddoooollllllllodl:lddolcc::;'..........',,,'...........
..................................';ldxkkxxkkkkkxl;.....';okkkkkkxxxxxxdddxxxxxxddxO00000Okxl:lkkkkxxxxkkkO0000000000000000OOOOkkkOOO000OOOOOOkkxdddooollccccllokd;:ddllccc:,'.....'',;;:cll:,'''.......
...................................'';lxxxkkkkkkkkdl,..'..':dkxxxxxxxxkkxdxxddxxddxOKKKKK0OxdoxOOOkkxxkkOOO000K000000000000000K0000000OOOOOOOOOOkxxdddolccccclloxkl:lddolll:,''',,;::ccllloll:;,,'......
...................................''',:oxkkkkkkkkkko:''...,cdxxddxxddxkkxxxxxxxdddk000K0K00OOO00000OOO000000KK000000000000000KKK0000000O00OO00OOOOkkxdlccllllloddl:cxxxdddl:;;;::cclllcclllc:;;;,,'....
......................................'',cdxkxkkxxkkxdl:,..,cxkxxdxxdddxkxxxxxxxddxO0KK00000000000KK0K000000KKKK000KKKK000000000KKK00000O00000000000000kdoolllloxko:cdkkkkxdlccccc:::::ccccc:::;;;,'....
......................................'''',cdkkkkkkkxxxdl:;;lxkkxxdxxdddxxxxxxxkkO0KK00K0000000000KK000000KKKKKKKKKKKKKKKK000000000000OkkO00KK00KKKK0000kdolllodxko:cldxkkkxoc:;,,,,,,;:c::::::;;,'.....
.......................................'''',coxkkkkkkxkkkdoodxkOkxddxxxdddddxkkO0KKKK000000000000000000000000KKK00KKK0KKKK00K000000O0OkddxkO0000KKKK0000Oxooooodxxo;:llodddolc:;;;;:c:;;;:::::;;;,'.....
........................................''''';cdkkOkkkkkkkkxxkOOkkxddxxdddddddxkOO00000000000000000000000000000000000000000KK000KK000OOkxxxxxxkO0K0K0000Oxdoooodxxdc;ccclloollccc:;;::;,;:::::;;,.......
..........................................'''',;ldkkkkkxxxkkkkkOOOkdodddxxxdddddxxkO0O0000000000000000000000000000000000KK00000KKK00000OOkkxxddxxO0000000Okkxddxdddoccccloooooolc:;'''',;::::;;;,.......
............................................'''',:oxkxxxxxxxxxkkOOkxoloddxxxddddoddxkO0000000000000000000000000000000000KK00000K00OOOO000000OkkxddkO00K00K000OOkkxdoolccccccllollc;'...,:c:c:;;;;'......
...............................................''';ldxxxdxxxxxxkkOOkdcclddxxxddddoodddkO000000000000OO000000000000000000000000000OOOOOOOOO0000Okkxdk00000KKKK0OOkxdlcccc:ccclllllc:,'.';cccc:;,;;'......
................................................'',:okkxxxxdxxdxxkkkxocclodxxdddddooooodk00000000000O000000000000OOOO00O000000000OOOOOOOOOO00K00Okxxk00KKKKKK00Oxolccccc::ccccccc::,'',clc:::,,,'.......
...............................................'..',lxkkxdxddxxxxdoldxdollloddddddddoooooxO0O0000000O00000000OOOOOOOOOOOOOOOOOOOOOOOOOOOOOO00KK00OOxxkOKKKKKK00Oxolcccc:::cccc::::;,'':cc::;;'''........
..............................................''''',cdkOkdoddxxddolcdOkkkdooooodxdddddooooxOOO00OO0OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO00K00OkkkO0KKKKK0Oxocccccc:::cccc:::,'';::;;;;,...........
..............................................'''',;ck0OkocloddoooodO0OkkkkkxdoooxxxddooooodkOOkkkOOkOOOOOkkkkkkkkkkOOOOOOOOOOOOOOOOOOOOOOOOOkOO0K00OOkkkO00KKK0Okkxxollclllccc::;,,,:::;;,''...........
.............................................''''';ldkOOOkdodddddkO000OOOOkkkOkolodxxdddoooodxxddddddxxkkkkkkkOOkkkkkOOOkkkOOOOOOOOOOOOOOOOOOOOOO00000OkkkO00K0KK00Okkxooodolc:::;,,:::::,'.............
.............................................'..';lddxxkO00K0000000000OOkkkkxkxdllodxxdddooooddddddddddxxxxxxkkkkkkkkkkkkkkkkkkOOkkkkkkkkkkkkkkOOO0000OOkkkOO0KK00Oxxkddddolc:::;,,:c:::;,..............
.............................................'..,:ldollok00000000OOOOOkkkkkkxxdlclodddxdddoooodxkkO00OkkxxxddddxxxkkxxxxxxxxxxxxxkxxxxxxxkkkkkkkkkOOOOOkxkOOk0KK00Oxxdooddoc:::;,,;cc:::;'..............
............................................','';codlc:coxkkkkOOkkkkkkkkkkkkxdllloxOOkkxxxdddoodxkO000000OkxdddooddxkkxxxxxxxxxxxxxxxxxxxxxxxxxxxkkkkkkxxkkkO00K0Okxdooodocc:::;,;:cc:::;'..............
...........................................'cl,';clc:::::loodxxkkkkkxxxkkkxdolloxO00000kxxddddoloxkkkxxkkO0OOkxddoooddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxkkxxkxxxOKK0OOkxdoodddlcc::;,;:ccc:::;...............
...........................................;oc;;:cc::::::ccccoxkkkxxxxxxddolldxO00KK0000OkxddxdoooodddoddxkO00Okkxdooooddddxxxxxxxxxxxxxxxxxxxxxxxxkdldkxxk0K0Okkxdoodddlccc:;,,:cccc::;'...............
.........................................';cl:;:cc:::::c::c::lxxxxxxxdoolodxO0000000000000kkxddddooooodoooodkO000OOOkxdooooddxxxxxxxxxxxxxxxxxxxxxkxllxxxO0000Okkxdodxdlc:c:;;,;:c:::::,'...............
..........................................;;;:cccccccccccc:ccoolllllllodxOO000000O00000K000Okkxdxxdooodoollldxk00000OOkxddoloodxxxxxxxxxxxxxxxxxxxxocdkxOK00Oxxxdddddolccc::;;,;:cc:::;,'...............
...........'.............................,;::looolccc::::::cc:::::cldkkO00000000000000KK0000OOkxxxxdddddollloodkO00000O0Okxdlloodxxxxxxxxxxxxxxxxxdodddk0000Oxdddoddolcccc:;,,',:cc:;::;'...............
........................................,;:loxxxdoc::;;;;:ccc:clodxO0000000000000000K000000000OkxxxxxddxdooooooddkO00000000OkdooodxkkkxxxxxxxxxxxxdddcoO0000Oxddoodol::ccc:;,,',:ll:;:c;'...............
.......................................';:ldxxxddlc:;::cccclldxkO000000000000000O00000K0O000000kxxxxxdooooodxdooodk00000000000OkkkkOOOOkkkkxxxxxxdxdlcxO00OOkddddddolc:ccc:;,,',:llc:::,................
......................................';codxxxdlllc::cccloxkk00000000000000000O0OOO0OO0OOO0O0K0OkdooooooodkO0OkxdodxO000000KK0000000000Okkkxxxxxxxxoox000Okkkddddddolccccc:;,,,;:cc:::;'.............'''
......................................,:oxxxxxdllccccccoxkk0000000000000000000O00OO0OOOkkO0O00000OkkkkkkkO00000kxdooodkO00000000000000OOkkkxxxxxxxxdx000OOkkxxxxddoooccclc;,,,,;ccc:::;'...............'
.....................................,;ldxkkkkkxdollccccloodxxkO000OO00000OO00OOOOOOOkkkkOOOOO0000000000KK00000OOxddddkO0000000000000OOOkkxxxxxxxkkkO00000Okkkkxxddoolccllc,,;;:clcc::;'................
..................................',,,;codO00O00OOkdolc:cc::cclldxkO000000OOkOOOOOOkkxxxxkkkkkO0000000000K00K00000OOOOO00000000000000OOOkkxxxxxkxxkOO0K00K0OOOOkxddoooolooc;,;:ccccc::;,''..............
..................................;:;,,;:ldkO00000K0OOkxxolcc::::cok00000OOkkkkOOOOOkxdodddxkxxOO0000KKK0000K000000000000000000000O00OOOkkxxxxxxkkkO0000KKK00K0Oxdoodooddoc;;;clllcc::;,'''''...........
.................................,loc:,,',:okkO0000K000000OkkxxdocldO000Okkkkkkkkkkkxddooolloolodk00KKKKKKK000K00000000000000000000OOOOOOkxxxxxxkOOOO000KKKKKKK0kddddooddc:;;cllllc::;;,,''''...........
..................................,lxkxl;,',cdOOO00000O000000000Oxdxk00OkkkkkkkkkkkkxdolllllllllloxOO00KK00000000000000000000000000OOOOOkkxxxxxxxxxkOO00KKKKKKXKkxxxdooooc;,:lolllc:;;,,,,,''...........
....................................;okOx:,,,lk00000OxooxO000000000OO000Okkkkkkkxxxxxdoolcc:ccccccloddxkOOOOO0K00000000000000000OOOOOOOOkxxxxxxxxoodkOkO0KKKKXXKOkkkddool:,':oollc::;;;;;,,'''..........
......................................lOOo;;;ck00OkOxc,':dOOOO00OO000000OkkkkkkkkxxxdoolllccccclcccloooodkOOOO00OOOO0OOOOOOO0000OOOOOOOkkkxxxxxxxdddxkkxk0KKKKXK00Oxdddol:,',::::::;;;;;;,,,''..........
.......................................lko;,,ck00OOkd;'',:c::ldO000000K0OkkkkkkkxkkkxdoooooollcllcccllllodxkOOOOOOOOOOOOOOOOOOOOOOOOkkkOOOkkkkkkkxxkkOOdld0KKKKK0Okxddol:;''',;;;;;;;;;;;,,,''..........
........................................;c;,,:x0OOOkkl;;;;;''';dO0000000OkkkkkkkkkkOOkxxxxxxkxdooolllcllldxkkkkkkkkkkOOOOOkkkkOOOOkkkkkOOOOOOOkkkkkOO0OxlldkKKXKOkxxddoc:;,'.',;;;;:;;;;,,''''..........
..........................................,,';d0Okkxdlclddc,'',cdO000KK0OkkkkkkkkkkkkkkkkkOkkkxxxxxdddddxxxxxxxxxkkkkkkkkkkkkkkOOkkkkkkkOOOOOOOOkOOO0Oxc:cokKKXK0kkxxxdoc;,'.',;;;;;;;,,,''''...........
...........................................,''l00dllllccoolc;,,,:ldk0K0OOkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxkkxxxxxxxxkkkkkkkkkOOOOOOOOOOOOO0OOOdc::lk0KKKK0Okkkxxdl:;,''',,,,',,''''..............
............................................''cOOl;;clllc:;:clc:;,,cxK0OOkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxxxxxxxxkkkkkkkkkkOOO0OkOOkOOOkO000kocldxk0K0000Okxxxddlcc:;,,,;;;,'''..................
.............................................'lkOo;,,;;,,:cldxxdlc:cx0OkkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxxxxxxxxxxxxxxxxxkkkkkkkkkO0OO0O0OOOkOOOkkO0OxoclodkO00OOkxdlllccccccccccccc:'....'................
.............................................,lO0xooc:::lodxxxxxxxxOOkxkkxkkkkkkkkkkkkkkkkkkkkkkxxxxxxxxkkkkkkkxxxxkkkkkkkkOOOO0K00OO00K0OOkkxolc;:loddxkkkxddolc:::;::c::cclllc::'....'................
.............................................'ck00OkkxxxxxxkkxkkkkOOkxkxxxkkkkkkkkkkkkkkkkkkkkkkxxkkkkkkkkkkkkkkkkkkkkkkOOOOOxddxxdddddddol:;,,,;:loollollllccc::::;;;:::cccllc:;;,....'................
.............................................,lk0OOkkkkkxxxxxkkkkkkkkxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOkxl:;:;;,;;;;::::c:cloodddlcccccccccc::::;;;;;;;;:::;,'.....'.................
............................................'cdxxxxxxxkkkkkkkkkkxxkkkxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOkkdlcloxollcccllllooodddddxdoccccccccccc::::;;;;;;;::;,...''....'...............
...........................................'cdxxxxxxxxxxxxxxxxxxxxxkxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOkxdoodxkOkxddooooooooddddddddolllcccc:::;;::ccc:::::cllc,'..'....................
..........................................'cdxxxxxxxxxxxxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOOOOxlclodkkOkxdodddddddddddddddoollccccc:;;;;;;:::::::::ccc;,..'....................
.........................................;ldkkxxxxxxxxxxxxxxxxxxxxxxxxxdxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkOkOkd::odxkkkkkxddxxdxxxxxxxxxxxxxolccccc::c:;,,;;;;::::::::::,''''..................
........................................'cxkkkkkkxxxxxxxxxxxxxxxxxxxxxddxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxl;,cdxkkkkOOkkkOOOOOOOOOOOOOOkkdlccc:::ccc;,,,,,;;::::::::::;,''..................
........................................,cdxxkkxxxxxxxxxxxxxxxxxxxxxxddxkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxxoc;'.,lxxkkOO0OOOOO000KKKKKKKK0K0Okdlcc::;;::;;,,,,,;:::::::::;;;,'..................
........................................';ldxxkkxxxxxkkxxxxxxxxxxxxxxxxkkkkkkkxkkkkkkkkkkkkkkkkkkkkkkkkkOOOkkxxdolc:;,';ldkkOOOOOOO000KKKKKKKKK000000Oxoolc:;;;;;;;,,,,;;:::::;;;;;;'...................
........................................';:ldoodoooodddddxkxxxxxxxxxxxkkkkkkkkkkkkkkkkkkOkkkkkkkkkOOkkxddollllllccccc::ldkOkkxxxkO0000KKKKKKK0OOOOkkkxddolc::;;;;;;;,,,;;::::;;;;;,'....................
.........................................';:lol::ccccc::cldxxxxxxxxxkkkkkkkkkkkkkkkOOOOOOkkkxxxdoolllc:;;:loodxxxxxxxddxkOOkxxxkkO0KKKK0KKK0OOOOkkdddxdooolcc:;,',;;,,;;::::;,,,,,'.....................
...........................................';cc,.';,,::;;;:odxxxxkkkkkkkkkkkkkkkkkkOOkkkxxdooc:;;;:ccloddxkkkkkkkkOOkkkkkkxxxkkkOO0KK00KK0OkkOOkxxdooooolooolcc;;;;;;;:::::;,'''''......................
......................................................,,,,;:cdxxkkkkkkkkOOkkkkkkxxddoolc::;:clloddxkkkkkkkkkkkkkkkOkkkkkkxxxkOOOO00000KKKK0Okkxxxxxddolllloooolc:;;;:;;;;:;,''''........................
.........................................................',,;oxxkkkkkkkOkkxddoollcc::::::lodxxkkkkkkkkkkkkkkkkkkkkkkOOkxxddxk00000KK00KK0000Okxxdollollccllooollc:;;;,'',;;;,''.........................
.............................................................,coxxxxdoolcc:::ccloooodddxxxxkkkkkkkkkkkkkkkkkkkkkkOOOOOkxdoodxkO000KK0KKK000kxxxdoccclcccccloooolc::;,,,'',:c:,'.........................
...............................................................;cc:;:::clooodxxxxxxxxxxxxxxkkkxxkkxxxkkkkkkkkOOOOOkkOOxdoodddxkO00K0000KKOxddxdolclllllcclooooollc:;:;;::cllc:,.........................
................................................................'';;:codxxxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkkOO00kxkkkdollooooxO0000000000Okxddolccllclcccloolloollccllllllllllc,........................
..................................................................''':ldkxxxxxxxxxxxxxxxxxkkkkkkkkkkkkkkkkkOO00OdoxdollllllloxO0000000000Okdolcccclccc::clllccllllllllllcllcccc;'.......................
....................................................................',:dkkxxxxxdxddxxxxxxkkkkkkkkkkkkkkkkkOO00OkolllccllllllooxO00000000Okdolcccccccccccclllcc:cccllolcccccc:c::,.......................
....................................................................'''cdxkxxxxxxxxxxxkkkkkkkkkkkkkkkkkkkOOO00Okl:cccccccccllloxk00K00K00kxdxdoolcccccloooollcccccclllcccc::::::;'......................
......................................................................';cdxxxxxxxxxxxxkkkkkkkkkkkkkkkkkkOO00000Ol;:cccccccccclldk0K000KKK0kxxkxxoloddoxxxxddolcclcc:cccccc::::::,.......................
.......................................................................,:ldxxxxxxxxxxxkkkkkkkkkkkkkkkkkOOO000000x::::::ccccccllldOKK00KKK00OOOOOkkkkOkOOkkkxddoollc:ccccc:::;,,'........................
.......................................................................',:ldxxxxxxxxxxkkkkkkkkkkkkkkkkOOO0000000kl;,,;::ccc:cloooxO0KKKKK00KKKKKKK000OOkkkkxxdddolc:;:ccc:,'''..........................
.......................................................................'',;lxxxxxxxxxxkkkkkkkkkkkkkkkkOOO00000000ko:,,;:::::::coodxOKKKK0OO00OOOOOkkxxxxxddddoooollc:;;::;'.............................
........................................................................''':dxxxxxxxxxkkkkkkkkkkkkkkOOOO0000000000Okxoooc;;;::ccloxO00K0Oxdddddddooddddddooolllllooodolc;,'.............................
...........................................................................;ldxxxxxxxdxkkkkkkkkkkkkOOOOOO000K000000OOOO0Ooccc::ccldk000kddooooolllllollclloolllooddxkxoc,...............................
..........................................................................',:lddxxxxxdxkkkkkkkkkkkkOOOOO0000K000K000OOO00OkkxollccldO0Oxoooollllllccllcclooooooddxxdo:,.................................
...........................................................................',:odxxxxxxxxkkkkkkkkkkkOOOOOO0000000000000000000Oxoolllldkxdoooolllccccllllloooolc:::::;;,'.................................
.............................................................................,codxxxxxxxxkkkkkkkkkkOOOOOO000000000000000000O0Okxololoddoooooolllllooodddddol:,..........................................
.............................................................................';lodxxxxxxxkkkkkkkkkOOOOOOO00000000000K000000O00OOkdllllddddooooooddxxxkOxxdol;'..........................................
..............................................................................,:cdxxxxxxxxkkkkkkkkOOOOOOO000000000KKK000000000O00Oxdl:;:looooooodxxxkxdoc;::'...........................................
...............................................................................';codxxxxxxxkkkkkkkkOOOOOO000000000K0K0000000000000OOxl:,,;;:::cccllccc;',,,'............................................
.................................................................................,:odxxxxxxxkkkkkOOOOOOOOO00000000000000000000000000OOxo:,''',,;;:llldddddxxoc,.........................................
.................................................................................',:oxxxxxxxxkkkkkOOOOOOO00000000K0000000000000000000000Odl:,''''',;:cloddooddo,........................................
..................................................................................',;cdkxxxxxxkkkkOOOOOOO00000000000000K00K000000000000000OOxollc:;,,,,,,,,,,,:;........................................
..........................................................................'......',,;;:dxxxxxxkkkOOOOOOOOO0000KKK00KKK0K00000000000000KK000000000Okdol:;,'.''.'.........................................
.....................................................................',,;:ccllllcccc;,:ldxkxxxkkkOOOOOOOOO00000KK000KK00000000K00K0000K0000000000KKK00Oxdl:'......'.....................................
...............................................................'';:clooddkOOOOO0Oxdlc;,:oxxxxxxkkOOOOOOO00O0000000K000K00000000KKK0000KKK00000000K0KKKKKK0Od:'..........................................
................................................''.....''.'',;:lodxxxxkxkkkkOOOOOOxdc:;;lxxxkxxkkkOOOOOO00O000000000K0000K00000KKK0000K0K0000000000KK0KKK000ko:'........................................
..............................................'''''',,'';:looxxxkkkkkkkkkkkkOO000K0Ooc:;coxxxxxkkOOOOOOO00O00000000000K0000000000K00000000KK000KKK0KKKK0000000Oxl;',,,..................................
..................................................';;::coxxkkkkkkkkkkkkkkkOO0KKK00XX0o::clxkxxxxkkOOOOOO00O0000000KKKKKKK000K0000000000000KK0000KKKKKKKKXK0000OO0Ol:olc;'...............................
*/
/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// File: contracts/IAwooClaiming.sol



pragma solidity 0.8.12;

interface IAwooClaiming{
    function overrideTokenAccrualBaseRate(address contractAddress, uint32 tokenId, uint256 newBaseRate) external;
}
// File: contracts/AwooModels.sol



pragma solidity 0.8.12;

struct AccrualDetails{
    address ContractAddress;
    uint256[] TokenIds;
    uint256[] Accruals;
    uint256 TotalAccrued;
}

struct ClaimDetails{
    address ContractAddress;
    uint32[] TokenIds;
}

struct SupportedContractDetails{
    address ContractAddress;
    uint256 BaseRate;
    bool Active;
}
// File: contracts/IAwooClaimingV2.sol



pragma solidity 0.8.12;


interface IAwooClaimingV2{
    function overrideTokenAccrualBaseRate(address contractAddress, uint32 tokenId, uint256 newBaseRate) external;
    function claim(address holder, ClaimDetails[] calldata requestedClaims) external;
}
// File: contracts/AddressChecksumStringUtil.sol


pragma solidity ^0.8.0;

// Derived from https://ethereum.stackexchange.com/a/63953, no license specified
// Modified to remove unnecessary functionality and prepend the checksummed string address with "0x"

/**
 * @dev This contract provides a set of pure functions for computing the EIP-55
 * checksum of an account in formats friendly to both off-chain and on-chain
 * callers, as well as for checking if a given string hex representation of an
 * address has a valid checksum. These helper functions could also be repurposed
 * as a library that extends the `address` type.
 */
contract AddressChecksumStringUtil {

    function toChecksumString(address account) internal pure returns (string memory asciiString) {
        // convert the account argument from address to bytes.
        bytes20 data = bytes20(account);

        // create an in-memory fixed-size bytes array.
        bytes memory asciiBytes = new bytes(40);

        // declare variable types.
        uint8 b;
        uint8 leftNibble;
        uint8 rightNibble;
        bool leftCaps;
        bool rightCaps;
        uint8 asciiOffset;

        // get the capitalized characters in the actual checksum.
        bool[40] memory caps = _toChecksumCapsFlags(account);

        // iterate over bytes, processing left and right nibble in each iteration.
        for (uint256 i = 0; i < data.length; i++) {
            // locate the byte and extract each nibble.
            b = uint8(uint160(data) / (2**(8*(19 - i))));
            leftNibble = b / 16;
            rightNibble = b - 16 * leftNibble;

            // locate and extract each capitalization status.
            leftCaps = caps[2*i];
            rightCaps = caps[2*i + 1];

            // get the offset from nibble value to ascii character for left nibble.
            asciiOffset = _getAsciiOffset(leftNibble, leftCaps);

            // add the converted character to the byte array.
            asciiBytes[2 * i] = bytes1(leftNibble + asciiOffset);

            // get the offset from nibble value to ascii character for right nibble.
            asciiOffset = _getAsciiOffset(rightNibble, rightCaps);

            // add the converted character to the byte array.
            asciiBytes[2 * i + 1] = bytes1(rightNibble + asciiOffset);
        }

        return string(abi.encodePacked("0x", string(asciiBytes)));
    }

    function _getAsciiOffset(uint8 nibble, bool caps) internal pure returns (uint8 offset) {
        // to convert to ascii characters, add 48 to 0-9, 55 to A-F, & 87 to a-f.
        if (nibble < 10) {
            offset = 48;
        } else if (caps) {
            offset = 55;
        } else {
            offset = 87;
        }
    }

    function _toChecksumCapsFlags(address account) internal pure returns (bool[40] memory characterCapitalized) {
        // convert the address to bytes.
        bytes20 a = bytes20(account);

        // hash the address (used to calculate checksum).
        bytes32 b = keccak256(abi.encodePacked(_toAsciiString(a)));

        // declare variable types.
        uint8 leftNibbleAddress;
        uint8 rightNibbleAddress;
        uint8 leftNibbleHash;
        uint8 rightNibbleHash;

        // iterate over bytes, processing left and right nibble in each iteration.
        for (uint256 i; i < a.length; i++) {
            // locate the byte and extract each nibble for the address and the hash.
            rightNibbleAddress = uint8(a[i]) % 16;
            leftNibbleAddress = (uint8(a[i]) - rightNibbleAddress) / 16;
            rightNibbleHash = uint8(b[i]) % 16;
            leftNibbleHash = (uint8(b[i]) - rightNibbleHash) / 16;

            characterCapitalized[2 * i] = (leftNibbleAddress > 9 && leftNibbleHash > 7);
            characterCapitalized[2 * i + 1] = (rightNibbleAddress > 9 && rightNibbleHash > 7);
        }
    }

    // based on https://ethereum.stackexchange.com/a/56499/48410
    function _toAsciiString(bytes20 data) internal pure returns (string memory asciiString) {
        // create an in-memory fixed-size bytes array.
        bytes memory asciiBytes = new bytes(40);

        // declare variable types.
        uint8 b;
        uint8 leftNibble;
        uint8 rightNibble;

        // iterate over bytes, processing left and right nibble in each iteration.
        for (uint256 i = 0; i < data.length; i++) {
            // locate the byte and extract each nibble.
            b = uint8(uint160(data) / (2 ** (8 * (19 - i))));
            leftNibble = b / 16;
            rightNibble = b - 16 * leftNibble;

            // to convert to ascii characters, add 48 to 0-9 and 87 to a-f.
            asciiBytes[2 * i] = bytes1(leftNibble + (leftNibble < 10 ? 48 : 87));
            asciiBytes[2 * i + 1] = bytes1(rightNibble + (rightNibble < 10 ? 48 : 87));
        }

        return string(asciiBytes);
    }
}
// File: @openzeppelin/[email protected]/utils/Strings.sol


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

// File: @openzeppelin/[email protected]/utils/cryptography/ECDSA.sol


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

// File: @openzeppelin/[email protected]/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// File: contracts/IAwooToken.sol



pragma solidity 0.8.12;


interface IAwooToken is IERC20 {
    function increaseVirtualBalance(address account, uint256 amount) external;
    function mint(address account, uint256 amount) external;
    function balanceOfVirtual(address account) external view returns(uint256);
    function spendVirtualAwoo(bytes32 hash, bytes memory sig, string calldata nonce, address account, uint256 amount) external;
}
// File: @openzeppelin/[email protected]/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/[email protected]/security/ReentrancyGuard.sol


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

// File: @openzeppelin/[email protected]/utils/Context.sol


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

// File: @openzeppelin/[email protected]/access/Ownable.sol


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

// File: contracts/OwnerAdminGuard.sol



pragma solidity 0.8.12;


contract OwnerAdminGuard is Ownable {
    address[2] private _admins;
    bool private _adminsSet;

    /// @notice Allows the owner to specify two addresses allowed to administer this contract
    /// @param admins A 2 item array of addresses
    function setAdmins(address[2] calldata admins) public {
        require(admins[0] != address(0) && admins[1] != address(0), "Invalid admin address");
        _admins = admins;
        _adminsSet = true;
    }

    function _isOwnerOrAdmin(address addr) internal virtual view returns(bool){
        return addr == owner() || (
            _adminsSet && (
                addr == _admins[0] || addr == _admins[1]
            )
        );
    }

    modifier onlyOwnerOrAdmin() {
        require(_isOwnerOrAdmin(msg.sender), "Not an owner or admin");
        _;
    }
}
// File: contracts/AuthorizedCallerGuard.sol



pragma solidity 0.8.12;


contract AuthorizedCallerGuard is OwnerAdminGuard {

    /// @dev Keeps track of which contracts are explicitly allowed to interact with certain super contract functionality
    mapping(address => bool) public authorizedContracts;

    event AuthorizedContractAdded(address contractAddress, address addedBy);
    event AuthorizedContractRemoved(address contractAddress, address removedBy);

    /// @notice Allows the owner or an admin to authorize another contract to override token accruals on an individual token level
    /// @param contractAddress The authorized contract address
    function addAuthorizedContract(address contractAddress) public onlyOwnerOrAdmin {
        require(_isContract(contractAddress), "Invalid contractAddress");
        authorizedContracts[contractAddress] = true;
        emit AuthorizedContractAdded(contractAddress, _msgSender());
    }

    /// @notice Allows the owner or an admin to remove an authorized contract
    /// @param contractAddress The contract address which should have its authorization revoked
    function removeAuthorizedContract(address contractAddress) public onlyOwnerOrAdmin {
        authorizedContracts[contractAddress] = false;
        emit AuthorizedContractRemoved(contractAddress, _msgSender());
    }

    /// @dev Derived from @openzeppelin/contracts/utils/Address.sol
    function _isContract(address account) internal virtual view returns (bool) {
        if(account == address(0)) return false;
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _isAuthorizedContract(address addr) internal virtual view returns(bool){
        return authorizedContracts[addr];
    }

    modifier onlyAuthorizedCaller() {
        require(_isOwnerOrAdmin(_msgSender()) || _isAuthorizedContract(_msgSender()), "Sender is not authorized");
        _;
    }

    modifier onlyAuthorizedContract() {
        require(_isAuthorizedContract(_msgSender()), "Sender is not authorized");
        _;
    }

}
// File: contracts/AwooClaiming.sol



pragma solidity 0.8.12;
pragma experimental ABIEncoderV2;








interface ISupportedContract {
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function exists(uint256 tokenId) external view returns (bool);
}

contract AwooClaiming is IAwooClaiming, Ownable, ReentrancyGuard {
    uint256 public accrualStart = 1646006400; //2022-02-28 00:00 UTC
	uint256 public accrualEnd;
	
    bool public claimingActive;

    /// @dev A collection of supported contracts. These are typically ERC-721, with the addition of the tokensOfOwner function.
    /// @dev These contracts can be deactivated but cannot be re-activated.  Reactivating can be done by adding the same
    /// contract through addSupportedContract
    SupportedContractDetails[] public supportedContracts;

    /// @dev Keeps track of the last time a claim was made for each tokenId within the supported contract collection
    mapping(address => mapping(uint256 => uint256)) public lastClaims;
    /// @dev Allows the base accrual rates to be overridden on a per-tokenId level to support things like upgrades
    mapping(address => mapping(uint256 => uint256)) public baseRateTokenOverrides;

    address[2] private _admins;    
    bool private _adminsSet;
    
    IAwooToken private _awooContract;    

    /// @dev Base accrual rates are set a per-day rate so we change them to per-minute to allow for more frequent claiming
    uint64 private _baseRateDivisor = 1440;

    /// @dev Faciliates the maintence and functionality related to supportedContracts
    uint8 private _activeSupportedContractCount;     
    mapping(address => uint8) private _supportedContractIds;
    
    /// @dev Keeps track of which contracts are explicitly allowed to override the base accrual rates
    mapping(address => bool) private _authorizedContracts;

    event TokensClaimed(address indexed claimedBy, uint256 qty);
    event ClaimingStatusChanged(bool newStatus, address changedBy);
    event AuthorizedContractAdded(address contractAddress, address addedBy);
    event AuthorizedContractRemoved(address contractAddress, address removedBy);

    constructor(uint256 accrualStartTimestamp) {
        require(accrualStartTimestamp > 0, "Invalid accrualStartTimestamp");
        accrualStart = accrualStartTimestamp;
    }

    /// @notice Determines the amount of accrued virtual AWOO for the specified address, based on the
    /// base accural rates for each supported contract and how long has elapsed (in minutes) since the
    /// last claim was made for a give supported contract tokenId
    /// @param owner The address of the owner/holder of tokens for a supported contract
    /// @return A collection of accrued virtual AWOO and the tokens it was accrued on for each supported contract, and the total AWOO accrued
    function getTotalAccruals(address owner) public view returns (AccrualDetails[] memory, uint256) {
        // Initialize the array length based on the number of _active_ supported contracts
        AccrualDetails[] memory totalAccruals = new AccrualDetails[](_activeSupportedContractCount);

        uint256 totalAccrued;
        uint8 contractCount; // Helps us keep track of the index to use when setting the values for totalAccruals
        for(uint8 i = 0; i < supportedContracts.length; i++) {
            SupportedContractDetails memory contractDetails = supportedContracts[i];

            if(contractDetails.Active){
                contractCount++;
                
                // Get an array of tokenIds held by the owner for the supported contract
                uint256[] memory tokenIds = ISupportedContract(contractDetails.ContractAddress).tokensOfOwner(owner);
                uint256[] memory accruals = new uint256[](tokenIds.length);
                
                uint256 totalAccruedByContract;

                for (uint16 x = 0; x < tokenIds.length; x++) {
                    uint32 tokenId = uint32(tokenIds[x]);
                    uint256 accrued = getContractTokenAccruals(contractDetails.ContractAddress, contractDetails.BaseRate, tokenId);

                    totalAccruedByContract+=accrued;
                    totalAccrued+=accrued;

                    tokenIds[x] = tokenId;
                    accruals[x] = accrued;
                }

                AccrualDetails memory accrual = AccrualDetails(contractDetails.ContractAddress, tokenIds, accruals, totalAccruedByContract);

                totalAccruals[contractCount-1] = accrual;
            }
        }
        return (totalAccruals, totalAccrued);
    }

    /// @notice Claims all virtual AWOO accrued by the message sender, assuming the sender holds any supported contracts tokenIds
    function claimAll() external nonReentrant {
        require(claimingActive, "Claiming is inactive");
        require(isValidHolder(), "No supported tokens held");

        (AccrualDetails[] memory accruals, uint256 totalAccrued) = getTotalAccruals(_msgSender());
        require(totalAccrued > 0, "No tokens have been accrued");
        
        for(uint8 i = 0; i < accruals.length; i++){
            AccrualDetails memory accrual = accruals[i];

            if(accrual.TotalAccrued > 0){
                for(uint16 x = 0; x < accrual.TokenIds.length;x++){
                    // Update the time that this token was last claimed
                    lastClaims[accrual.ContractAddress][accrual.TokenIds[x]] = block.timestamp;
                }
            }
        }
    
        // A holder's virtual AWOO balance is stored in the $AWOO ERC-20 contract
        _awooContract.increaseVirtualBalance(_msgSender(), totalAccrued);
        emit TokensClaimed(_msgSender(), totalAccrued);
    }

    /// @notice Claims the accrued virtual AWOO from the specified supported contract tokenIds
    /// @param requestedClaims A collection of supported contract addresses and the specific tokenIds to claim from
    function claim(ClaimDetails[] calldata requestedClaims) external nonReentrant {
        require(claimingActive, "Claiming is inactive");
        require(isValidHolder(), "No supported tokens held");

        uint256 totalClaimed;

        for(uint8 i = 0; i < requestedClaims.length; i++){
            ClaimDetails calldata requestedClaim = requestedClaims[i];

            uint8 contractId = _supportedContractIds[requestedClaim.ContractAddress];
            if(contractId == 0) revert("Unsupported contract");

            SupportedContractDetails memory contractDetails = supportedContracts[contractId-1];
            if(!contractDetails.Active) revert("Inactive contract");

            for(uint16 x = 0; x < requestedClaim.TokenIds.length; x++){
                uint32 tokenId = requestedClaim.TokenIds[x];

                address tokenOwner = ISupportedContract(address(contractDetails.ContractAddress)).ownerOf(tokenId);
                if(tokenOwner != _msgSender()) revert("Invalid owner claim attempt");

                uint256 claimableAmount = getContractTokenAccruals(contractDetails.ContractAddress, contractDetails.BaseRate, tokenId);

                if(claimableAmount > 0){
                    totalClaimed+=claimableAmount;

                    // Update the time that this token was last claimed
                    lastClaims[contractDetails.ContractAddress][tokenId] = block.timestamp;
                }
            }
        }

        if(totalClaimed > 0){
            _awooContract.increaseVirtualBalance(_msgSender(), totalClaimed);
            emit TokensClaimed(_msgSender(), totalClaimed);
        }
    }

    /// @dev Calculates the accrued amount of virtual AWOO for the specified supported contract and tokenId
    function getContractTokenAccruals(address contractAddress, uint256 contractBaseRate, uint32 tokenId) private view returns(uint256){
        uint256 lastClaimTime = lastClaims[contractAddress][tokenId];
        uint256 accruedUntil = accrualEnd == 0 || block.timestamp < accrualEnd 
            ? block.timestamp 
            : accrualEnd;
        
        uint256 baseRate = baseRateTokenOverrides[contractAddress][tokenId] > 0 
            ? baseRateTokenOverrides[contractAddress][tokenId] 
            : contractBaseRate;

        if (lastClaimTime > 0){
            return (baseRate*(accruedUntil-lastClaimTime))/60;
        } else {
             return (baseRate*(accruedUntil-accrualStart))/60;
        }
    }

    /// @notice Allows an authorized contract to increase the base accrual rate for particular NFTs
    /// when, for example, upgrades for that NFT were purchased
    /// @param contractAddress The address of the supported contract
    /// @param tokenId The id of the token from the supported contract whose base accrual rate will be updated
    /// @param newBaseRate The new accrual base rate
    function overrideTokenAccrualBaseRate(address contractAddress, uint32 tokenId, uint256 newBaseRate)
        external onlyAuthorizedContract isValidBaseRate(newBaseRate) {
            require(tokenId > 0, "Invalid tokenId");

            uint8 contractId = _supportedContractIds[contractAddress];
            require(contractId > 0, "Unsupported contract");
            require(supportedContracts[contractId-1].Active, "Inactive contract");

            baseRateTokenOverrides[contractAddress][tokenId] = (newBaseRate/_baseRateDivisor);
    }

    /// @notice Allows the owner or an admin to set a reference to the $AWOO ERC-20 contract
    /// @param awooToken An instance of IAwooToken
    function setAwooTokenContract(IAwooToken awooToken) external onlyOwnerOrAdmin {
        _awooContract = awooToken;
    }

    /// @notice Allows the owner or an admin to set the date and time at which virtual AWOO accruing will stop
    /// @notice This will only be used if absolutely necessary and any AWOO that accrued before the end date will still be claimable
    /// @param timestamp The Epoch time at which accrual should end
    function setAccrualEndTimestamp(uint256 timestamp) external onlyOwnerOrAdmin {
        accrualEnd = timestamp;
    }

    /// @notice Allows the owner or an admin to add a contract whose tokens are eligible to accrue virtual AWOO
    /// @param contractAddress The contract address of the collection (typically ERC-721, with the addition of the tokensOfOwner function)
    /// @param baseRate The base accrual rate in wei units
    function addSupportedContract(address contractAddress, uint256 baseRate) external onlyOwnerOrAdmin isValidBaseRate(baseRate) {
        require(isContract(contractAddress), "Invalid contractAddress");
        require(_supportedContractIds[contractAddress] == 0, "Contract already supported");

        supportedContracts.push(SupportedContractDetails(contractAddress, baseRate/_baseRateDivisor, true));
        _supportedContractIds[contractAddress] = uint8(supportedContracts.length);
        _activeSupportedContractCount++;
    }

    /// @notice Allows the owner or an admin to deactivate a supported contract so it no longer accrues virtual AWOO
    /// @param contractAddress The contract address that should be deactivated
    function deactivateSupportedContract(address contractAddress) external onlyOwnerOrAdmin {
        require(_supportedContractIds[contractAddress] > 0, "Unsupported contract");

        supportedContracts[_supportedContractIds[contractAddress]-1].Active = false;
        supportedContracts[_supportedContractIds[contractAddress]-1].BaseRate = 0;
        _supportedContractIds[contractAddress] = 0;
        _activeSupportedContractCount--;
    }

    /// @notice Allows the owner or an admin to authorize another contract to override token accruals on an individual token level
    /// @param contractAddress The authorized contract address
    function addAuthorizedContract(address contractAddress) external onlyOwnerOrAdmin {
        require(isContract(contractAddress), "Invalid contractAddress");
        _authorizedContracts[contractAddress] = true;
        emit AuthorizedContractAdded(contractAddress, _msgSender());
    }

    /// @notice Allows the owner or an admin to remove an authorized contract
    /// @param contractAddress The contract address which should have its authorization revoked
    function removeAuthorizedContract(address contractAddress) external onlyOwnerOrAdmin {
        _authorizedContracts[contractAddress] = false;
        emit AuthorizedContractRemoved(contractAddress, _msgSender());
    }

    /// @notice Allows the owner or an admin to set the base accrual rate for a support contract
    /// @param contractAddress The address of the supported contract
    /// @param baseRate The new base accrual rate in wei units
    function setBaseRate(address contractAddress, uint256 baseRate) external onlyOwnerOrAdmin isValidBaseRate(baseRate) {
        require(_supportedContractIds[contractAddress] > 0, "Unsupported contract");
        supportedContracts[_supportedContractIds[contractAddress]-1].BaseRate = baseRate/_baseRateDivisor;
    }

    /// @notice Allows the owner to specify two addresses allowed to administer this contract
    /// @param adminAddresses A 2 item array of addresses
    function setAdmins(address[2] calldata adminAddresses) external onlyOwner {
        require(adminAddresses[0] != address(0) && adminAddresses[1] != address(0), "Invalid admin address");

        _admins = adminAddresses;
        _adminsSet = true;
    }

    /// @notice Allows the owner or an admin to activate/deactivate claiming ability
    /// @param active The value specifiying whether or not claiming should be allowed
    function setClaimingActive(bool active) external onlyOwnerOrAdmin {
        claimingActive = active;
        emit ClaimingStatusChanged(active, _msgSender());
    }

    /// @dev Derived from @openzeppelin/contracts/utils/Address.sol
    function isContract(address account) private view returns (bool) {
        if(account == address(0)) return false;
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /// @notice Determines whether or not the caller holds tokens for any of the supported contracts
    function isValidHolder() private view returns(bool) {
        for(uint8 i = 0; i < supportedContracts.length; i++){
            SupportedContractDetails memory contractDetails = supportedContracts[i];
            if(contractDetails.Active){
                if(ISupportedContract(contractDetails.ContractAddress).balanceOf(_msgSender()) > 0) {
                    return true; // No need to continue checking other collections if the holder has any of the supported tokens
                } 
            }
        }
        return false;
    }

    modifier onlyAuthorizedContract() {
        require(_authorizedContracts[_msgSender()], "Sender is not authorized");
        _;
    }

    modifier onlyOwnerOrAdmin() {
        require(
            _msgSender() == owner() || (
                _adminsSet && (
                    _msgSender() == _admins[0] || _msgSender() == _admins[1]
                )
            ), "Not an owner or admin");
        _;
    }

    /// @dev To minimize the amount of unit conversion we have to do for comparing $AWOO (ERC-20) to virtual AWOO, we store
    /// virtual AWOO with 18 implied decimal places, so this modifier prevents us from accidentally using the wrong unit
    /// for base rates.  For example, if holders of FangGang NFTs accrue at a rate of 1000 AWOO per fang, pre day, then
    /// the base rate should be 1000000000000000000000
    modifier isValidBaseRate(uint256 baseRate) {
        require(baseRate >= 1 ether, "Base rate must be in wei units");
        _;
    }
}
// File: @openzeppelin/[email protected]/token/ERC20/ERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: contracts/AwooToken.sol



pragma solidity 0.8.12;









contract AwooToken is IAwooToken, ERC20, ReentrancyGuard, Ownable, AddressChecksumStringUtil {
    using ECDSA for bytes32;
    using Strings for uint256;

    /// @dev Controls whether or not the deposit/withdraw functionality is enabled
    bool public isActive = true;

    /// @dev The percentage of spent virtual AWOO taken as a fee
    uint256 public awooFeePercentage = 10;
    /// @dev The Awoo Studios account where fees are sent
    address public awooStudiosAccount;

    address[2] private _admins;
    bool private _adminsSet;   

    /// @dev Keeps track of which contracts are explicitly allowed to add virtual AWOO to a holder's address, spend from it, or
    /// in the future, mint ERC-20 tokens
    mapping(address => bool) private _authorizedContracts;
    /// @dev Keeps track of each holders virtual AWOO balance
    mapping(address => uint256) private _virtualBalance;
    /// @dev Keeps track of nonces used for spending events to prevent double spends
    mapping(string => bool) private _usedNonces;

    event AuthorizedContractAdded(address contractAddress, address addedBy);
    event AuthorizedContractRemoved(address contractAddress, address removedBy);
    event VirtualAwooSpent(address spender, uint256 amount);

    constructor(address awooAccount) ERC20("Awoo Token", "AWOO") {
        require(awooAccount != address(0), "Invalid awooAccount");
        awooStudiosAccount = awooAccount;
    }

    /// @notice Allows an authorized contract to mint $AWOO
    /// @param account The account to receive the minted $AWOO tokens
    /// @param amount The amount of $AWOO to mint
    function mint(address account, uint256 amount) external nonReentrant onlyAuthorizedContract {
        require(account != address(0), "Cannot mint to the zero address");
        require(amount > 0, "Amount cannot be zero");
        _mint(account, amount);
    }

    /// @notice Allows the owner or an admin to add authorized contracts
    /// @param contractAddress The address of the contract to authorize
    function addAuthorizedContract(address contractAddress) external onlyOwnerOrAdmin {
        require(isContract(contractAddress), "Not a contract address");
        _authorizedContracts[contractAddress] = true;
        emit AuthorizedContractAdded(contractAddress, _msgSender());
    }

    /// @notice Allows the owner or an admin to remove authorized contracts
    /// @param contractAddress The address of the contract to revoke authorization for
    function removeAuthorizedContract(address contractAddress) external onlyOwnerOrAdmin {
        _authorizedContracts[contractAddress] = false;
        emit AuthorizedContractRemoved(contractAddress, _msgSender());
    }

    /// @notice Exchanges virtual AWOO for ERC-20 $AWOO
    /// @param amount The amount of virtual AWOO to withdraw
    function withdraw(uint256 amount) external whenActive hasBalance(amount, _virtualBalance[_msgSender()]) nonReentrant {
        _mint(_msgSender(), amount);
        _virtualBalance[_msgSender()] -= amount;
    }

    /// @notice Exchanges ERC-20 $AWOO for virtual AWOO to be used in the Awoo Studios ecosystem
    /// @param amount The amount of $AWOO to deposit
    function deposit(uint256 amount) external whenActive hasBalance(amount, balanceOf(_msgSender())) nonReentrant {
        _burn(_msgSender(), amount);
        _virtualBalance[_msgSender()] += amount;
    }

    /// @notice Returns the amount of virtual AWOO held by the specified address
    /// @param account The holder account to check
    function balanceOfVirtual(address account) external view returns(uint256) {
        return _virtualBalance[account];
    }

    /// @notice Returns the amount of ERC-20 $AWOO held by the specified address
    /// @param account The holder account to check
    function totalBalanceOf(address account) external view returns(uint256) {
        return _virtualBalance[account] + balanceOf(account);
    }

    /// @notice Allows authorized contracts to increase a holders virtual AWOO
    /// @param account The account to increase
    /// @param amount The amount of virtual AWOO to increase the account by
    function increaseVirtualBalance(address account, uint256 amount) external onlyAuthorizedContract {
        _virtualBalance[account] += amount;
    }

    /// @notice Allows authorized contracts to faciliate the spending of virtual AWOO, and fees to be paid to
    /// Awoo Studios.
    /// @notice Only amounts that have been signed and verified by the token holder can be spent
    /// @param hash The hash of the message displayed to and signed by the holder
    /// @param sig The signature of the messages that was signed by the holder
    /// @param nonce The unique code used to prevent double spends
    /// @param account The account of the holder to debit
    /// @param amount The amount of virtual AWOO to debit
    function spendVirtualAwoo(bytes32 hash, bytes memory sig, string calldata nonce, address account, uint256 amount)
        external onlyAuthorizedContract hasBalance(amount, _virtualBalance[account]) nonReentrant {
            require(_usedNonces[nonce] == false, "Duplicate nonce");
            require(matchAddresSigner(account, hash, sig), "Message signer mismatch"); // Make sure that the spend request was authorized (signed) by the holder
            require(hashTransaction(account, amount) == hash, "Hash check failed"); // Make sure that only the amount authorized by the holder can be spent
        
            // debit the holder's virtual AWOO account
            _virtualBalance[account]-=amount;

            // Mint the spending fee to the Awoo Studios account
            _mint(awooStudiosAccount, ((amount * awooFeePercentage)/100));

            _usedNonces[nonce] = true;

            emit VirtualAwooSpent(account, amount);
    }

    /// @notice Allows the owner to specify two addresses allowed to administer this contract
    /// @param adminAddresses A 2 item array of addresses
    function setAdmins(address[2] calldata adminAddresses) external onlyOwner {
        require(adminAddresses[0] != address(0) && adminAddresses[1] != address(0), "Invalid admin address");
        _admins = adminAddresses;
        _adminsSet = true;
    }

    /// @notice Allows the owner or an admin to activate/deactivate deposit and withdraw functionality
    /// @notice This will only be used to disable functionality as a worst case scenario
    /// @param active The value specifiying whether or not deposits/withdraws should be allowed
    function setActiveState(bool active) external onlyOwnerOrAdmin {
        isActive = active;
    }

    /// @notice Allows the owner to change the account used for collecting spending fees
    /// @param awooAccount The new account
    function setAwooStudiosAccount(address awooAccount) external onlyOwner {
        require(awooAccount != address(0), "Invalid awooAccount");
        awooStudiosAccount = awooAccount;
    }

    /// @notice Allows the owner to change the spending fee percentage
    /// @param feePercentage The new fee percentage
    function setFeePercentage(uint256 feePercentage) external onlyOwner {
        awooFeePercentage = feePercentage; // We're intentionally allowing the fee percentage to be set to 0%, incase no fees need to be collected
    }

    /// @notice Allows the owner to withdraw any Ethereum that was accidentally sent to this contract
    function rescueEth() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /// @dev Derived from @openzeppelin/contracts/utils/Address.sol
    function isContract(address account) private view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /// @dev Validates the specified account against the account that signed the message
    function matchAddresSigner(address account, bytes32 hash, bytes memory signature) private pure returns (bool) {
        return account == hash.recover(signature);
    }

    /// @dev Hashes the message we expected the spender to sign so we can compare the hashes to ensure that the owner
    /// of the specified address signed the same message
    /// @dev fractional ether unit amounts aren't supported
    function hashTransaction(address sender, uint256 amount) private pure returns (bytes32) {
        require(amount == ((amount/1e18)*1e18), "Invalid amount");
        // Virtual $AWOO, much like the ERC-20 $AWOO is stored with 18 implied decimal places.
        // For user-friendliness, when prompting the user to sign the message, the amount is
        // _displayed_ without the implied decimals, but it is charged with the implied decimals,
        // so when validating the hash, we have to use the same value we displayed to the user.
        // This only affects the display value, nothing else
        amount = amount/1e18;
        
        string memory message = string(abi.encodePacked(
            "As the owner of Ethereum address\r\n",
            toChecksumString(sender),
            "\r\nI authorize the spending of ",
            amount.toString()," virtual $AWOO"
        ));
        uint256 messageLength = bytes(message).length;

        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n",messageLength.toString(),
                message
            )
        );
        return hash;
    }
    
    modifier onlyAuthorizedContract() {
        require(_authorizedContracts[_msgSender()], "Sender is not authorized");
        _;
    }

    modifier whenActive() {
        require(isActive, "Contract is not active");
        _;
    }

    modifier hasBalance(uint256 amount, uint256 balance) {
        require(amount > 0, "Amount cannot be zero");
        require(balance >= amount, "Insufficient Balance");
        _;
    }

    modifier onlyOwnerOrAdmin() {
        require(
            _msgSender() == owner() ||
                (_adminsSet &&
                    (_msgSender() == _admins[0] || _msgSender() == _admins[1])),
            "Caller is not the owner or an admin"
        );
        _;
    }
}
// File: contracts/AwooClaimingV2.sol



pragma solidity 0.8.12;







contract AwooClaimingV2 is IAwooClaimingV2, AuthorizedCallerGuard, ReentrancyGuard {
    uint256 public accrualStart;
	uint256 public accrualEnd;
	
    bool public claimingActive;

    /// @dev A collection of supported contracts. These are typically ERC-721, with the addition of the tokensOfOwner function.
    /// @dev These contracts can be deactivated but cannot be re-activated.  Reactivating can be done by adding the same
    /// contract through addSupportedContract
    SupportedContractDetails[] public supportedContracts;

    /// @dev Keeps track of the last time a claim was made for each tokenId within the supported contract collection
    mapping(address => mapping(uint256 => uint256)) public lastClaims;
    /// @dev Allows the base accrual rates to be overridden on a per-tokenId level to support things like upgrades
    mapping(address => mapping(uint256 => uint256)) public baseRateTokenOverrides;

    AwooClaiming public v1ClaimingContract;
    AwooToken public awooContract;

    /// @dev Base accrual rates are set a per-day rate so we change them to per-minute to allow for more frequent claiming
    uint64 private _baseRateDivisor = 1440;

    /// @dev Faciliates the maintence and functionality related to supportedContracts
    uint8 private _activeSupportedContractCount;     
    mapping(address => uint8) private _supportedContractIds;
    
    event TokensClaimed(address indexed claimedBy, uint256 qty);
    event ClaimingStatusChanged(bool newStatus, address changedBy);

    constructor(AwooClaiming v1Contract) {
        v1ClaimingContract = v1Contract;
        accrualStart = v1ClaimingContract.accrualStart();
    }

    /// @notice Sets the first version of the claiming contract, which has been replaced with this one
    /// @param v1Contract A reference to the v1 claiming contract
    function setV1ClaimingContract(AwooClaiming v1Contract) external onlyOwnerOrAdmin {
        v1ClaimingContract = v1Contract;
        accrualStart = v1ClaimingContract.accrualStart();
    }

    /// @notice Determines the amount of accrued virtual AWOO for the specified address, based on the
    /// base accural rates for each supported contract and how long has elapsed (in minutes) since the
    /// last claim was made for a give supported contract tokenId
    /// @param owner The address of the owner/holder of tokens for a supported contract
    /// @return A collection of accrued virtual AWOO and the tokens it was accrued on for each supported contract, and the total AWOO accrued
    function getTotalAccruals(address owner) public view returns (AccrualDetails[] memory, uint256) {
        // Initialize the array length based on the number of _active_ supported contracts
        AccrualDetails[] memory totalAccruals = new AccrualDetails[](_activeSupportedContractCount);

        uint256 totalAccrued;
        uint8 contractCount; // Helps us keep track of the index to use when setting the values for totalAccruals
        for(uint8 i = 0; i < supportedContracts.length; i++) {
            SupportedContractDetails memory contractDetails = supportedContracts[i];

            if(contractDetails.Active){
                contractCount++;
                
                // Get an array of tokenIds held by the owner for the supported contract
                uint256[] memory tokenIds = ISupportedContract(contractDetails.ContractAddress).tokensOfOwner(owner);
                uint256[] memory accruals = new uint256[](tokenIds.length);
                
                uint256 totalAccruedByContract;

                for (uint16 x = 0; x < tokenIds.length; x++) {
                    uint32 tokenId = uint32(tokenIds[x]);
                    uint256 accrued = getContractTokenAccruals(contractDetails.ContractAddress, tokenId);

                    totalAccruedByContract+=accrued;
                    totalAccrued+=accrued;

                    tokenIds[x] = tokenId;
                    accruals[x] = accrued;
                }

                AccrualDetails memory accrual = AccrualDetails(contractDetails.ContractAddress, tokenIds, accruals, totalAccruedByContract);

                totalAccruals[contractCount-1] = accrual;
            }
        }
        return (totalAccruals, totalAccrued);
    }

    /// @notice Claims all virtual AWOO accrued by the message sender, assuming the sender holds any supported contracts tokenIds
    function claimAll(address holder) external nonReentrant {
        require(claimingActive, "Claiming is inactive");
        require(_isAuthorizedContract(_msgSender()) || holder == _msgSender(), "Unauthorized claim attempt");

        (AccrualDetails[] memory accruals, uint256 totalAccrued) = getTotalAccruals(holder);
        require(totalAccrued > 0, "No tokens have been accrued");
        
        for(uint8 i = 0; i < accruals.length; i++){
            AccrualDetails memory accrual = accruals[i];

            if(accrual.TotalAccrued > 0){
                for(uint16 x = 0; x < accrual.TokenIds.length;x++){
                    // Update the time that this token was last claimed
                    lastClaims[accrual.ContractAddress][accrual.TokenIds[x]] = block.timestamp;
                }
            }
        }
    
        // A holder's virtual AWOO balance is stored in the $AWOO ERC-20 contract
        awooContract.increaseVirtualBalance(holder, totalAccrued);
        emit TokensClaimed(holder, totalAccrued);
    }

    /// @notice Claims the accrued virtual AWOO from the specified supported contract tokenIds
    /// @param requestedClaims A collection of supported contract addresses and the specific tokenIds to claim from
    function claim(address holder, ClaimDetails[] calldata requestedClaims) external nonReentrant {
        require(claimingActive, "Claiming is inactive");
        require(_isAuthorizedContract(_msgSender()) || holder == _msgSender(), "Unauthorized claim attempt");

        uint256 totalClaimed;

        for(uint8 i = 0; i < requestedClaims.length; i++){
            ClaimDetails calldata requestedClaim = requestedClaims[i];

            uint8 contractId = _supportedContractIds[requestedClaim.ContractAddress];
            if(contractId == 0) revert("Unsupported contract");

            SupportedContractDetails memory contractDetails = supportedContracts[contractId-1];
            if(!contractDetails.Active) revert("Inactive contract");

            for(uint16 x = 0; x < requestedClaim.TokenIds.length; x++){
                uint32 tokenId = requestedClaim.TokenIds[x];

                address tokenOwner = ISupportedContract(address(contractDetails.ContractAddress)).ownerOf(tokenId);
                if(tokenOwner != holder) revert("Invalid owner claim attempt");

                uint256 claimableAmount = getContractTokenAccruals(contractDetails.ContractAddress, tokenId);

                if(claimableAmount > 0){
                    totalClaimed+=claimableAmount;

                    // Update the time that this token was last claimed
                    lastClaims[contractDetails.ContractAddress][tokenId] = block.timestamp;
                }
            }
        }

        if(totalClaimed > 0){
            awooContract.increaseVirtualBalance(holder, totalClaimed);
            emit TokensClaimed(holder, totalClaimed);
        }
    }

    /// @notice Calculates the accrued amount of virtual AWOO for the specified supported contract and tokenId
    /// @dev To save gas, we don't validate the existence of the token within the specified collection as this is done
    /// within the claiming functions
    /// @dev The first time a claim is made in this contract, we use the v1 contract's last claim time so we don't
    /// accrue based on accruals that were claimed through the v1 contract
    /// @param contractAddress The contract address of the supported collection
    /// @param tokenId The id of the token/NFT
    /// @return The amount of virtual AWOO accrued for the specified token and collection
    function getContractTokenAccruals(address contractAddress, uint32 tokenId) public view returns(uint256){
        uint8 contractId = _supportedContractIds[contractAddress];
        if(contractId == 0) revert("Unsupported contract");

        SupportedContractDetails memory contractDetails = supportedContracts[contractId-1];
        if(!contractDetails.Active) revert("Inactive contract");

        uint256 lastClaimTime = lastClaims[contractAddress][tokenId] > 0
            ? lastClaims[contractAddress][tokenId]
            : v1ClaimingContract.lastClaims(contractAddress, tokenId);

        uint256 accruedUntil = accrualEnd == 0 || block.timestamp < accrualEnd 
            ? block.timestamp 
            : accrualEnd;
        
        uint256 baseRate = getContractTokenBaseAccrualRate(contractDetails, tokenId);

        if (lastClaimTime > 0){
            return (baseRate*(accruedUntil-lastClaimTime))/60;
        } else {
             return (baseRate*(accruedUntil-accrualStart))/60;
        }
    }

    /// @notice Returns the current base accrual rate for the specified token, taking overrides into account
    /// @dev This is mostly to support testing
    /// @param contractDetails The details of the supported contract
    /// @param tokenId The id of the token/NFT
    /// @return The base accrual rate
    function getContractTokenBaseAccrualRate(SupportedContractDetails memory contractDetails, uint32 tokenId
    ) public view returns(uint256){
        return baseRateTokenOverrides[contractDetails.ContractAddress][tokenId] > 0 
            ? baseRateTokenOverrides[contractDetails.ContractAddress][tokenId] 
            : contractDetails.BaseRate;
    }

    /// @notice Allows an authorized contract to increase the base accrual rate for particular NFTs
    /// when, for example, upgrades for that NFT were purchased
    /// @param contractAddress The address of the supported contract
    /// @param tokenId The id of the token from the supported contract whose base accrual rate will be updated
    /// @param newBaseRate The new accrual base rate
    function overrideTokenAccrualBaseRate(address contractAddress, uint32 tokenId, uint256 newBaseRate)
        external onlyAuthorizedContract isValidBaseRate(newBaseRate) {
            require(tokenId > 0, "Invalid tokenId");

            uint8 contractId = _supportedContractIds[contractAddress];
            require(contractId > 0, "Unsupported contract");
            require(supportedContracts[contractId-1].Active, "Inactive contract");

            baseRateTokenOverrides[contractAddress][tokenId] = (newBaseRate/_baseRateDivisor);
    }

    /// @notice Allows the owner or an admin to set a reference to the $AWOO ERC-20 contract
    /// @param awooToken An instance of IAwooToken
    function setAwooTokenContract(AwooToken awooToken) external onlyOwnerOrAdmin {
        awooContract = awooToken;
    }

    /// @notice Allows the owner or an admin to set the date and time at which virtual AWOO accruing will stop
    /// @notice This will only be used if absolutely necessary and any AWOO that accrued before the end date will still be claimable
    /// @param timestamp The Epoch time at which accrual should end
    function setAccrualEndTimestamp(uint256 timestamp) external onlyOwnerOrAdmin {
        accrualEnd = timestamp;
    }

    /// @notice Allows the owner or an admin to add a contract whose tokens are eligible to accrue virtual AWOO
    /// @param contractAddress The contract address of the collection (typically ERC-721, with the addition of the tokensOfOwner function)
    /// @param baseRate The base accrual rate in wei units
    function addSupportedContract(address contractAddress, uint256 baseRate) public onlyOwnerOrAdmin isValidBaseRate(baseRate) {
        require(_isContract(contractAddress), "Invalid contractAddress");
        require(_supportedContractIds[contractAddress] == 0, "Contract already supported");

        supportedContracts.push(SupportedContractDetails(contractAddress, baseRate/_baseRateDivisor, true));
        _supportedContractIds[contractAddress] = uint8(supportedContracts.length);
        _activeSupportedContractCount++;
    }

    /// @notice Allows the owner or an admin to deactivate a supported contract so it no longer accrues virtual AWOO
    /// @param contractAddress The contract address that should be deactivated
    function deactivateSupportedContract(address contractAddress) external onlyOwnerOrAdmin {
        require(_supportedContractIds[contractAddress] > 0, "Unsupported contract");

        supportedContracts[_supportedContractIds[contractAddress]-1].Active = false;
        supportedContracts[_supportedContractIds[contractAddress]-1].BaseRate = 0;
        _supportedContractIds[contractAddress] = 0;
        _activeSupportedContractCount--;
    }

    /// @notice Allows the owner or an admin to set the base accrual rate for a support contract
    /// @param contractAddress The address of the supported contract
    /// @param baseRate The new base accrual rate in wei units
    function setBaseRate(address contractAddress, uint256 baseRate) external onlyOwnerOrAdmin isValidBaseRate(baseRate) {
        require(_supportedContractIds[contractAddress] > 0, "Unsupported contract");
        supportedContracts[_supportedContractIds[contractAddress]-1].BaseRate = baseRate/_baseRateDivisor;
    }

    /// @notice Allows the owner or an admin to activate/deactivate claiming ability
    /// @param active The value specifiying whether or not claiming should be allowed
    function setClaimingActive(bool active) external onlyOwnerOrAdmin {
        claimingActive = active;
        emit ClaimingStatusChanged(active, _msgSender());
    }

    /// @dev To minimize the amount of unit conversion we have to do for comparing $AWOO (ERC-20) to virtual AWOO, we store
    /// virtual AWOO with 18 implied decimal places, so this modifier prevents us from accidentally using the wrong unit
    /// for base rates.  For example, if holders of FangGang NFTs accrue at a rate of 1000 AWOO per fang, pre day, then
    /// the base rate should be 1000000000000000000000
    modifier isValidBaseRate(uint256 baseRate) {
        require(baseRate >= 1 ether, "Base rate must be in wei units");
        _;
    }
}
// File: contracts/AwooClaimingV3.sol



pragma solidity 0.8.12;







contract AwooClaimingV3 is IAwooClaimingV2, AuthorizedCallerGuard, ReentrancyGuard {
    uint256 public accrualStart;
	uint256 public accrualEnd;
	
    bool public claimingActive = false;

    /// @dev A collection of supported contracts. These are typically ERC-721, with the addition of the tokensOfOwner function.
    /// @dev These contracts can be deactivated but cannot be re-activated.  Reactivating can be done by adding the same
    /// contract through addSupportedContract
    SupportedContractDetails[] public supportedContracts;

    /// @dev Keeps track of the last time a claim was made for each tokenId within the supported contract collection
    // contractAddress => (tokenId, lastClaimTimestamp)
    mapping(address => mapping(uint256 => uint48)) public lastClaims;
    /// @dev Allows the base accrual rates to be overridden on a per-tokenId level to support things like upgrades
    mapping(address => mapping(uint256 => uint256)) public baseRateTokenOverrides;

    // contractAddress => (tokenId, accruedAmount)
    mapping(address => mapping(uint256 => uint256)) public unclaimedSnapshot;

    AwooClaiming public v1ClaimingContract;
    AwooClaimingV2 public v2ClaimingContract;
    AwooToken public awooContract;

    /// @dev Base accrual rates are set a per-day rate so we change them to per-minute to allow for more frequent claiming
    uint64 private _baseRateDivisor = 1440;

    /// @dev Faciliates the maintence and functionality related to supportedContracts
    uint8 private _activeSupportedContractCount;     
    mapping(address => uint8) private _supportedContractIds;
    
    event TokensClaimed(address indexed claimedBy, uint256 qty);
    event ClaimingStatusChanged(bool newStatus, address changedBy);

    constructor(AwooToken awooTokenContract, AwooClaimingV2 v2Contract, AwooClaiming v1Contract) {
        awooContract = awooTokenContract;
        v2ClaimingContract = v2Contract;
        accrualStart = v2ClaimingContract.accrualStart();
        v1ClaimingContract = v1Contract;
    }

    /// @notice Sets the previous versions of the claiming contracts, which have been replaced with this one
    function setContracts(AwooClaimingV2 v2Contract, AwooClaiming v1Contract) external onlyOwnerOrAdmin {
        v2ClaimingContract = v2Contract;
        accrualStart = v2ClaimingContract.accrualStart();
        v1ClaimingContract = v1Contract;
    }

    /// @notice Determines the amount of accrued virtual AWOO for the specified address, based on the
    /// base accural rates for each supported contract and how long has elapsed (in minutes) since the
    /// last claim was made for a give supported contract tokenId
    /// @param owner The address of the owner/holder of tokens for a supported contract
    /// @return A collection of accrued virtual AWOO and the tokens it was accrued on for each supported contract, and the total AWOO accrued
    function getTotalAccruals(address owner) public view returns (AccrualDetails[] memory, uint256) {
        // Initialize the array length based on the number of _active_ supported contracts
        AccrualDetails[] memory totalAccruals = new AccrualDetails[](_activeSupportedContractCount);

        uint256 totalAccrued;
        uint8 contractCount; // Helps us keep track of the index to use when setting the values for totalAccruals
        for(uint8 i = 0; i < supportedContracts.length; i++) {
            SupportedContractDetails memory contractDetails = supportedContracts[i];

            if(contractDetails.Active){
                contractCount++;
                
                // Get an array of tokenIds held by the owner for the supported contract
                uint256[] memory tokenIds = ISupportedContract(contractDetails.ContractAddress).tokensOfOwner(owner);
                uint256[] memory accruals = new uint256[](tokenIds.length);
                
                uint256 totalAccruedByContract;

                for (uint16 x = 0; x < tokenIds.length; x++) {
                    uint256 tokenId = tokenIds[x];
                    uint256 accrued = getContractTokenAccruals(contractDetails.ContractAddress, tokenId);

                    totalAccruedByContract+=accrued;
                    totalAccrued+=accrued;

                    tokenIds[x] = tokenId;
                    accruals[x] = accrued;
                }

                AccrualDetails memory accrual = AccrualDetails(contractDetails.ContractAddress, tokenIds, accruals, totalAccruedByContract);

                totalAccruals[contractCount-1] = accrual;
            }
        }
        return (totalAccruals, totalAccrued);
    }

    /// @notice Claims all virtual AWOO accrued by the message sender, assuming the sender holds any supported contracts tokenIds
    function claimAll(address holder) external nonReentrant {
        require(claimingActive, "Claiming is inactive");
        require(_isAuthorizedContract(_msgSender()) || holder == _msgSender(), "Unauthorized claim attempt");

        (AccrualDetails[] memory accruals, uint256 totalAccrued) = getTotalAccruals(holder);
        require(totalAccrued > 0, "No tokens have been accrued");
        
        for(uint8 i = 0; i < accruals.length; i++){
            AccrualDetails memory accrual = accruals[i];

            if(accrual.TotalAccrued > 0){
                for(uint16 x = 0; x < accrual.TokenIds.length;x++){
                    // Update the time that this token was last claimed
                    lastClaims[accrual.ContractAddress][accrual.TokenIds[x]] = uint48(block.timestamp);
                    // Any amount from the unclaimed snapshot are now claimed because they were returned by getContractTokenAccruals
                    // so dump it
                    delete unclaimedSnapshot[accrual.ContractAddress][accrual.TokenIds[x]];
                }
            }
        }
    
        // A holder's virtual AWOO balance is stored in the $AWOO ERC-20 contract
        awooContract.increaseVirtualBalance(holder, totalAccrued);
        emit TokensClaimed(holder, totalAccrued);
    }

    /// @notice Claims the accrued virtual AWOO from the specified supported contract tokenIds
    /// @param requestedClaims A collection of supported contract addresses and the specific tokenIds to claim from
    function claim(address holder, ClaimDetails[] calldata requestedClaims) external nonReentrant {
        require(claimingActive, "Claiming is inactive");
        require(_isAuthorizedContract(_msgSender()) || holder == _msgSender(), "Unauthorized claim attempt");

        uint256 totalClaimed;

        for(uint8 i = 0; i < requestedClaims.length; i++){
            ClaimDetails calldata requestedClaim = requestedClaims[i];

            uint8 contractId = _supportedContractIds[requestedClaim.ContractAddress];
            if(contractId == 0) revert("Unsupported contract");

            SupportedContractDetails memory contractDetails = supportedContracts[contractId-1];
            if(!contractDetails.Active) revert("Inactive contract");

            for(uint16 x = 0; x < requestedClaim.TokenIds.length; x++){
                uint32 tokenId = requestedClaim.TokenIds[x];

                address tokenOwner = ISupportedContract(address(contractDetails.ContractAddress)).ownerOf(tokenId);
                if(tokenOwner != holder) revert("Invalid owner claim attempt");

                uint256 claimableAmount = getContractTokenAccruals(contractDetails.ContractAddress, tokenId);

                if(claimableAmount > 0){
                    totalClaimed+=claimableAmount;

                    // Update the time that this token was last claimed
                    lastClaims[contractDetails.ContractAddress][tokenId] = uint48(block.timestamp);
                    // Any amount from the unclaimed snapshot are now claimed because they were returned by getContractTokenAccruals
                    // so dump it
                    delete unclaimedSnapshot[contractDetails.ContractAddress][tokenId];
                }
            }
        }

        if(totalClaimed > 0){
            awooContract.increaseVirtualBalance(holder, totalClaimed);
            emit TokensClaimed(holder, totalClaimed);
        }
    }

    /// @notice Calculates the accrued amount of virtual AWOO for the specified supported contract and tokenId
    /// @dev To save gas, we don't validate the existence of the token within the specified collection as this is done
    /// within the claiming functions
    /// @dev The first time a claim is made in this contract, we use the v1 contract's last claim time so we don't
    /// accrue based on accruals that were claimed through the v1 contract
    /// @param contractAddress The contract address of the supported collection
    /// @param tokenId The id of the token/NFT
    /// @return The amount of virtual AWOO accrued for the specified token and collection
    function getContractTokenAccruals(address contractAddress, uint256 tokenId) public view returns(uint256){
        uint8 contractId = _supportedContractIds[contractAddress];
        if(contractId == 0) revert("Unsupported contract");

        SupportedContractDetails memory contractDetails = supportedContracts[contractId-1];
        if(!contractDetails.Active) revert("Inactive contract");

        return getContractTokenAccruals(contractDetails, tokenId, uint48(block.timestamp));
    }

    /// @notice Calculates the accrued amount of virtual AWOO for the specified supported contract and tokenId, at the point in time specified
    /// @dev To save gas, we don't validate the existence of the token within the specified collection as this is done
    /// within the claiming functions
    /// @dev The first time a claim is made in this contract, we use the v1 contract's last claim time so we don't
    /// accrue based on accruals that were claimed through the v1 contract
    /// @param contractDetails The contract details of the supported collection
    /// @param tokenId The id of the token/NFT
    /// @param accruedUntilTimestamp The timestamp to calculate accruals from
    /// @return The amount of virtual AWOO accrued for the specified token and collection
    function getContractTokenAccruals(SupportedContractDetails memory contractDetails, 
        uint256 tokenId, uint48 accruedUntilTimestamp
    ) private view returns(uint256){
        uint48 lastClaimTime = getLastClaimTime(contractDetails.ContractAddress, tokenId);

        uint256 accruedUntil = accrualEnd == 0 || accruedUntilTimestamp < accrualEnd 
            ? accruedUntilTimestamp
            : accrualEnd;
        
        uint256 existingSnapshotAmount = unclaimedSnapshot[contractDetails.ContractAddress][tokenId];
        uint256 baseRate = getContractTokenBaseAccrualRate(contractDetails, tokenId);

        if (lastClaimTime > 0){
            return existingSnapshotAmount + ((baseRate*(accruedUntil-lastClaimTime))/60);
        } else {
            return existingSnapshotAmount + ((baseRate*(accruedUntil-accrualStart))/60);
        }
    }

    function getLastClaimTime(address contractAddress, uint256 tokenId) public view returns(uint48){
        uint48 lastClaim = lastClaims[contractAddress][tokenId];
        
        // If a claim has already been made through this contract, return the time of that claim
        if(lastClaim > 0) {
            return lastClaim;
        }
        
        // If not claims have been made through this contract, check V2
        lastClaim = uint48(v2ClaimingContract.lastClaims(contractAddress, tokenId));
        if(lastClaim > 0) {
            return lastClaim;
        }

        // If not claims have been made through the V2 contract, check the OG
        return uint48(v1ClaimingContract.lastClaims(contractAddress, tokenId));
    }

    /// @notice Returns the current base accrual rate for the specified token, taking overrides into account
    /// @dev This is mostly to support testing
    /// @param contractDetails The details of the supported contract
    /// @param tokenId The id of the token/NFT
    /// @return The base accrual rate
    function getContractTokenBaseAccrualRate(SupportedContractDetails memory contractDetails, uint256 tokenId
    ) public view returns(uint256){
        return baseRateTokenOverrides[contractDetails.ContractAddress][tokenId] > 0 
            ? baseRateTokenOverrides[contractDetails.ContractAddress][tokenId] 
            : contractDetails.BaseRate;
    }

    /// @notice Allows an authorized contract to increase the base accrual rate for particular NFTs
    /// when, for example, upgrades for that NFT were purchased
    /// @param contractAddress The address of the supported contract
    /// @param tokenId The id of the token from the supported contract whose base accrual rate will be updated
    /// @param newBaseRate The new accrual base rate
    function overrideTokenAccrualBaseRate(address contractAddress, uint32 tokenId, uint256 newBaseRate
    ) external onlyAuthorizedContract isValidBaseRate(newBaseRate) {
        require(tokenId > 0, "Invalid tokenId");

        uint8 contractId = _supportedContractIds[contractAddress];
        require(contractId > 0, "Unsupported contract");
        require(supportedContracts[contractId-1].Active, "Inactive contract");

        // Before overriding the accrual rate, take a snapshot of what the current unclaimed amount is
        // so that when `claim` or `claimAll` is called, the snapshot amount will be included so 
        // it doesn't get lost
        // @dev IMPORTANT: The snapshot must be taken _before_ baseRateTokenOverrides is set 
        unclaimedSnapshot[contractAddress][tokenId] = getContractTokenAccruals(contractAddress, tokenId);
        lastClaims[contractAddress][tokenId] = uint48(block.timestamp);
        baseRateTokenOverrides[contractAddress][tokenId] = (newBaseRate/_baseRateDivisor);
    }

    /// @notice Allows an authorized individual to manually create point-in-time snapshots of AWOO that
    /// was accrued up until a particular point in time.  This is only necessary to correct a bug in the
    /// V2 claiming contract that caused unclaimed AWOO to double when the base rates were overridden,
    /// rather than accruing with the new rate from that point in time
    function fixPreAccrualOverrideSnapshot(address contractAddress, uint256[] calldata tokenIds, 
        uint48[] calldata accruedUntilTimestamps
    ) external onlyOwnerOrAdmin {
        require(tokenIds.length == accruedUntilTimestamps.length, "Array length mismatch");

        uint8 contractId = _supportedContractIds[contractAddress];
        SupportedContractDetails memory contractDetails = supportedContracts[contractId-1];

        for(uint16 i; i < tokenIds.length; i++) {
            if(getLastClaimTime(contractAddress, tokenIds[i]) < accruedUntilTimestamps[i]) {
                unclaimedSnapshot[contractAddress][tokenIds[i]] = getContractTokenAccruals(contractDetails, tokenIds[i], accruedUntilTimestamps[i]);
                lastClaims[contractAddress][tokenIds[i]] = accruedUntilTimestamps[i];
            }
        }
    }

    /// @notice Allows the owner or an admin to set a reference to the $AWOO ERC-20 contract
    /// @param awooToken An instance of IAwooToken
    function setAwooTokenContract(AwooToken awooToken) external onlyOwnerOrAdmin {
        awooContract = awooToken;
    }

    /// @notice Allows the owner or an admin to set the date and time at which virtual AWOO accruing will stop
    /// @notice This will only be used if absolutely necessary and any AWOO that accrued before the end date will still be claimable
    /// @param timestamp The Epoch time at which accrual should end
    function setAccrualEndTimestamp(uint256 timestamp) external onlyOwnerOrAdmin {
        accrualEnd = timestamp;
    }

    /// @notice Allows the owner or an admin to add a contract whose tokens are eligible to accrue virtual AWOO
    /// @param contractAddress The contract address of the collection (typically ERC-721, with the addition of the tokensOfOwner function)
    /// @param baseRate The base accrual rate in wei units
    function addSupportedContract(address contractAddress, uint256 baseRate) public onlyOwnerOrAdmin isValidBaseRate(baseRate) {
        require(_isContract(contractAddress), "Invalid contractAddress");
        require(_supportedContractIds[contractAddress] == 0, "Contract already supported");

        supportedContracts.push(SupportedContractDetails(contractAddress, baseRate/_baseRateDivisor, true));
        _supportedContractIds[contractAddress] = uint8(supportedContracts.length);
        _activeSupportedContractCount++;
    }

    /// @notice Allows the owner or an admin to deactivate a supported contract so it no longer accrues virtual AWOO
    /// @param contractAddress The contract address that should be deactivated
    function deactivateSupportedContract(address contractAddress) external onlyOwnerOrAdmin {
        require(_supportedContractIds[contractAddress] > 0, "Unsupported contract");

        supportedContracts[_supportedContractIds[contractAddress]-1].Active = false;
        supportedContracts[_supportedContractIds[contractAddress]-1].BaseRate = 0;
        _supportedContractIds[contractAddress] = 0;
        _activeSupportedContractCount--;
    }

    /// @notice Allows the owner or an admin to set the base accrual rate for a support contract
    /// @param contractAddress The address of the supported contract
    /// @param baseRate The new base accrual rate in wei units
    function setBaseRate(address contractAddress, uint256 baseRate) external onlyOwnerOrAdmin isValidBaseRate(baseRate) {
        require(_supportedContractIds[contractAddress] > 0, "Unsupported contract");
        supportedContracts[_supportedContractIds[contractAddress]-1].BaseRate = baseRate/_baseRateDivisor;
    }

    /// @notice Allows the owner or an admin to activate/deactivate claiming ability
    /// @param active The value specifiying whether or not claiming should be allowed
    function setClaimingActive(bool active) external onlyOwnerOrAdmin {
        claimingActive = active;
        emit ClaimingStatusChanged(active, _msgSender());
    }

    /// @dev To minimize the amount of unit conversion we have to do for comparing $AWOO (ERC-20) to virtual AWOO, we store
    /// virtual AWOO with 18 implied decimal places, so this modifier prevents us from accidentally using the wrong unit
    /// for base rates.  For example, if holders of FangGang NFTs accrue at a rate of 1000 AWOO per fang, pre day, then
    /// the base rate should be 1000000000000000000000
    modifier isValidBaseRate(uint256 baseRate) {
        require(baseRate >= 1 ether, "Base rate must be in wei units");
        _;
    }
}
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: NONE
/** =========================================================================
 *                                   LICENSE
 * 1. The Source code developed by the Owner, may be used in interaction with
 *    any smart contract only within the logium.org platform on which all
 *    transactions using the Source code shall be conducted. The source code may
 *    be also used to develop tools for trading at logium.org platform.
 * 2. It is unacceptable for third parties to undertake any actions aiming to
 *    modify the Source code of logium.org in order to adapt it to work with a
 *    different smart contract than the one indicated by the Owner by default,
 *    without prior notification to the Owner and obtaining its written consent.
 * 3. It is prohibited to copy, distribute, or modify the Source code without
 *    the prior written consent of the Owner.
 * 4. Source code is subject to copyright, and therefore constitutes the subject
 *    to legal protection. It is unacceptable for third parties to use all or
 *    any parts of the Source code for any purpose without the Owner's prior
 *    written consent.
 * 5. All content within the framework of the Source code, including any
 *    modifications and changes to the Source code provided by the Owner,
 *    constitute the subject to copyright and is therefore protected by law. It
 *    is unacceptable for third parties to use contents found within the
 *    framework of the product without the Owner’s prior written consent.
 * 6. To the extent permitted by applicable law, the Source code is provided on
 *    an "as is" basis. The Owner hereby disclaims all warranties and
 *    conditions, express or implied, including (without limitation) warranties
 *    of merchantability or fitness for a particular purpose.
 * =========================================================================
 * Template Smart Contract Code is legally protected and is the exclusive
 * intellectual property of the Owner. It is prohibited to copy, distribute, or
 * modify the Template Smart Contract Code without the prior written consent of
 * the Owner, except for the purpose for which the Template Smart Contract Code
 * was created, i.e., to reference the Template Smart Contract Code in order to
 * enter into transactions on the LOGIUM platform, under the current terms and
 * conditions permitted by the Owner at the time of entering into the particular
 * smart contract.
 *
 * LOGIUM creates the Template Smart Contract Code, which is provided to the
 * issuer and taker but LOGIUM has no control over the contract they sign. The
 * contract they entered into specifies all the transaction terms, which LOGIUM
 * has no influence on.
 *
 * Users enter into futures contracts - options - with each other, and LOGIUM
 * does not act as a broker in this legal relationship, but only as a provider
 * of the Template Smart Contract Code.
 *
 * Trading is conducted only between users, LOGIUM does not participate in it as
 * a party. LOGIUM's only profit is the commission on a transaction, which is
 * always calculated only on winnings, and is not in the legal nature of a stock
 * exchange commission. The final real value of the fee depends on the amount of
 * leverage set by the user.
 * ========================================================================= */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./libraries/Constants.BinaryBet.sol";
import "./libraries/OracleLibrary.sol";
import "./libraries/Market.sol";
import "./libraries/RatioMath.sol";
import "./libraries/Ticket.sol";
import "./libraries/TicketBinaryBet.sol";
import "./interfaces/ILogiumBinaryBet.sol";
import "./interfaces/ILogiumCore.sol";

/// @title Binary Bet Logium contract
/// @notice This contract is meant to be deployed as a "masterBet" contract for Logium exchange
/// This contract implements binary bet logic and serves as Template Smart Contract Code
contract LogiumBinaryBet is ILogiumBinaryBet {
    using SafeCast for uint256;
    using TicketBinaryBet for TicketBinaryBet.Details;
    using TicketBinaryBet for bytes;
    using Ticket for Ticket.Immutable;

    /// structure describing bet take(-s) by one trader in one block
    /// Properties:
    /// - amount - total amount in smallest units as described by the RatioMath library
    /// - end - timestamp of expiry
    struct Trade {
        uint128 amount; // bet amount
        uint128 end; // timestamp
    }

    /// Dynamic bet state

    /// @notice expiry of last trade
    uint128 private lastEnd;

    /// @notice total issuer collateral
    uint128 private issued;

    /// @dev map from tradeId as defined by tradeId function to amount and expiry time of each trade/take
    /// @inheritdoc ILogiumBinaryBetState
    mapping(uint256 => Trade) public override traders;

    /// @notice Address of Logium master
    /// @dev immutable values are stored in bytecode, this is inherited by all clones
    address public immutable coreInstance;

    address private immutable betImplementation;

    /// address for transferring collected fees
    /// @dev immutable values are stored in bytecode, this is inherited by all clones
    address public immutable feeCollector;

    /// @dev only allow LogiumCore to call decorated function
    modifier onlyCore() {
        require(msg.sender == coreInstance, "Unauthorized");
        _;
    }

    modifier properTicket(Ticket.Immutable calldata ticket) {
        bytes32 hashVal = ticket.hashValImmutable();
        address expectedAddress = Clones.predictDeterministicAddress(
            betImplementation,
            hashVal,
            coreInstance
        );
        require(address(this) == expectedAddress, "Invalid ticket");
        _;
    }

    constructor(address _coreInstance, address _feeCollector) {
        require(_feeCollector != address(0x0), "Fee collector must be valid");
        coreInstance = _coreInstance;
        feeCollector = _feeCollector;
        lastEnd = type(uint128).max; // prevent expiration on master instance
        betImplementation = address(this);
    }

    function initAndIssue(
        bytes32 detailsHash,
        address trader,
        bytes32 takeParams,
        uint128 volume,
        bytes calldata detailsEnc
    ) external override returns (uint256 issuerPrice, uint256 traderPrice) {
        require(lastEnd == 0, "Already initialized"); // check if uninitialized
        // lastEnd is initialized in issue
        return issue(detailsHash, trader, takeParams, volume, detailsEnc);
    }

    function issue(
        bytes32 detailsHash,
        address trader,
        bytes32 takeParams,
        uint128 volume,
        bytes calldata detailsEnc
    )
        public
        override
        onlyCore
        returns (uint256 issuerPrice, uint256 traderPrice)
    {
        uint256 amount = uint256(takeParams); //decode takeParams
        TicketBinaryBet.Details memory details = detailsEnc
            .unpackBinaryBetDetails();
        (issuerPrice, traderPrice) = RatioMath.priceFromRatio(
            amount,
            details.ratio
        );
        uint128 newIssuedTotal = issued + issuerPrice.toUint128();
        uint128 end = (block.timestamp + details.period).toUint128();
        uint256 _tradeId = tradeId(trader, block.number);

        require(newIssuedTotal <= volume, "Volume not available");
        require(details.hashDetails() == detailsHash, "Invalid detailsHash");
        require(
            details.issuerWinFee <= Constants.MAX_FEE_X9,
            "Invalid issuer win fee"
        );
        require(
            details.traderWinFee <= Constants.MAX_FEE_X9,
            "Invalid trader win fee"
        );

        (issued, lastEnd) = (newIssuedTotal, end);
        traders[_tradeId] = Trade({
            amount: traders[_tradeId].amount + amount.toUint128(),
            end: end
        });
    }

    function claim(Ticket.Immutable calldata ticket)
        external
        override
        properTicket(ticket)
    {
        require(block.timestamp > lastEnd, "Not expired");
        TicketBinaryBet.Details memory details = ticket
            .details
            .unpackBinaryBetDetails();

        // Recover win amount
        uint256 balance = Constants.USDC.balanceOf(address(this));
        require(balance > 0, "Nothing to claim");
        (uint256 issuerCollateral, uint256 issuerWin) = RatioMath
            .totalStakeToPrice(balance, details.ratio);

        // IssuerWinFee can't be > 10**9 (1 with 9 decimals) due to check in issue,
        // thus this will not overflow for any "issuerWin" under ~10**68.
        // For USDC base currency this is 10**62 USD in value. We do not expect to see such stakes.
        uint256 fee = (issuerWin * details.issuerWinFee) / (10**9);
        uint256 issuerTransfer = issuerCollateral + issuerWin - fee;
        if (details.claimTo != address(0x0)) {
            Constants.USDC.transfer(details.claimTo, issuerTransfer);
        } else {
            Constants.USDC.approve(coreInstance, issuerTransfer);
            ILogiumCore(coreInstance).depositTo(
                ticket.maker,
                issuerTransfer.toUint128()
            );
        }
        if (fee > 0) {
            Constants.USDC.transfer(feeCollector, fee);
        }

        emit Claim();
    }

    function claimableFrom() external view override returns (uint256) {
        return lastEnd;
    }

    function exercise(Ticket.Immutable calldata ticket, uint256 blockNumber)
        external
        override
        properTicket(ticket)
    {
        _doExercise(ticket, tradeId(msg.sender, blockNumber), false);
    }

    function exerciseOther(
        Ticket.Immutable calldata ticket,
        uint256 id,
        bool gasFee
    ) external override properTicket(ticket) {
        _doExercise(ticket, id, gasFee);
    }

    function exerciseWindowDuration(Ticket.Immutable calldata ticket)
        public
        view
        override
        properTicket(ticket)
        returns (uint256)
    {
        return ticket.details.unpackBinaryBetDetails().exerciseWindowDuration;
    }

    function marketTick(Ticket.Immutable calldata ticket)
        public
        view
        override
        properTicket(ticket)
        returns (int24)
    {
        return
            Market.getMarketTickvsUSDC(
                ticket.details.unpackBinaryBetDetails().pool
            );
    }

    function issuerTotal() external view override returns (uint256) {
        return issued;
    }

    function tradersTotal(Ticket.Immutable calldata ticket)
        external
        view
        override
        properTicket(ticket)
        returns (uint256)
    {
        return
            RatioMath.issuerToTrader(
                issued,
                ticket.details.unpackBinaryBetDetails().ratio
            );
    }

    /// @notice Exercise the given trade
    /// @param id trade id
    function _doExercise(
        Ticket.Immutable calldata ticket,
        uint256 id,
        bool gasFee
    ) internal {
        TicketBinaryBet.Details memory details = ticket
            .details
            .unpackBinaryBetDetails();
        (uint256 trader_amount, uint256 trader_end) = (
            traders[id].amount,
            traders[id].end
        );

        require(
            trader_end - details.exerciseWindowDuration < block.timestamp,
            "Too soon to exercise"
        );
        require(trader_amount > 0, "Amount is 0");
        require(block.timestamp <= trader_end, "Contract expired");

        // solhint-disable-next-line var-name-mixedcase
        int24 USDC_WETHTick;
        int24 marketTickVal;
        if (gasFee) {
            (marketTickVal, USDC_WETHTick) = Market
                .getMarketTickvsUSDCwithUSDCWETHTick(details.pool);
        } else {
            marketTickVal = Market.getMarketTickvsUSDC(details.pool);
        }

        if (details.isUp) {
            require(
                marketTickVal >= details.strikeUniswapTick,
                "Strike not passed"
            );
        } else {
            require(
                marketTickVal <= details.strikeUniswapTick,
                "Strike not passed"
            );
        }

        // TraderWinFee can't be > 10**9 (1 with 9 decimals) due to check in issue,
        // thus this will not overflow for any "traderWin" under ~10**68.
        // For USDC base currency this is 10**62 USD in value. We do not expect to see such stakes.
        (uint256 traderWin, uint256 traderCollateral) = RatioMath
            .priceFromRatio(trader_amount, details.ratio);
        uint256 fee = (traderWin * details.traderWinFee) / (10**9);
        if (gasFee) {
            uint256 totalEtherForGas = block.basefee * Constants.EXERCISE_GAS;

            uint160 sqrtRatioX96 = OracleLibrary.getSqrtRatioAtTick(
                USDC_WETHTick
            );
            if (sqrtRatioX96 > 1 << 96) sqrtRatioX96 = (1 << 96) - 1; //cap ratio at "1". This is equivalent to 1ETH = 10^12 USDC (due to decimal point difference)

            uint256 ratioX128 = uint128(
                (uint256(sqrtRatioX96) * uint256(sqrtRatioX96)) >> 64
            ); // doesn't overflow due to above cap

            fee += (ratioX128 * totalEtherForGas) >> 128; //not expected to overflow as this would be equivalent to total USDC cost of transaction > 1e32

            require(
                traderCollateral + traderWin > fee,
                "Exercise would result in loss"
            );
        }

        traders[id].amount = 0;
        traders[id].end = 0;

        Constants.USDC.transfer(
            addressFromId(id),
            traderCollateral + traderWin - fee
        );
        if (fee > 0) {
            Constants.USDC.transfer(feeCollector, fee);
        }
        emit Exercise(id);
    }

    function tradeId(address trader, uint256 blockNumber)
        public
        pure
        override
        returns (uint256)
    {
        require(blockNumber < (1 << 64), "blockNumber too high");
        return (uint256(uint160(trader)) << 64) | blockNumber;
    }

    /// @notice Recover address from trade id
    /// @param id the trade id
    /// @return trader address
    function addressFromId(uint256 id) internal pure returns (address) {
        return address(uint160(id >> 64));
    }

    // solhint-disable-next-line func-name-mixedcase
    function DETAILS_TYPE() external pure override returns (bytes memory) {
        return TicketBinaryBet.DETAILS_TYPE;
    }
}

// SPDX-License-Identifier: NONE
/** =========================================================================
 *                                   LICENSE
 * 1. The Source code developed by the Owner, may be used in interaction with
 *    any smart contract only within the logium.org platform on which all
 *    transactions using the Source code shall be conducted. The source code may
 *    be also used to develop tools for trading at logium.org platform.
 * 2. It is unacceptable for third parties to undertake any actions aiming to
 *    modify the Source code of logium.org in order to adapt it to work with a
 *    different smart contract than the one indicated by the Owner by default,
 *    without prior notification to the Owner and obtaining its written consent.
 * 3. It is prohibited to copy, distribute, or modify the Source code without
 *    the prior written consent of the Owner.
 * 4. Source code is subject to copyright, and therefore constitutes the subject
 *    to legal protection. It is unacceptable for third parties to use all or
 *    any parts of the Source code for any purpose without the Owner's prior
 *    written consent.
 * 5. All content within the framework of the Source code, including any
 *    modifications and changes to the Source code provided by the Owner,
 *    constitute the subject to copyright and is therefore protected by law. It
 *    is unacceptable for third parties to use contents found within the
 *    framework of the product without the Owner’s prior written consent.
 * 6. To the extent permitted by applicable law, the Source code is provided on
 *    an "as is" basis. The Owner hereby disclaims all warranties and
 *    conditions, express or implied, including (without limitation) warranties
 *    of merchantability or fitness for a particular purpose.
 * ========================================================================= */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./logiumBinaryBet/ILogiumBinaryBetIssuer.sol";
import "./logiumBinaryBet/ILogiumBinaryBetTrade.sol";
import "./logiumBinaryBet/ILogiumBinaryBetCore.sol";
import "./logiumBinaryBet/ILogiumBinaryBetState.sol";

/// @title Interface of LogiumBinaryBet contract
/// @notice Each binary bet contract follows this interface.
/// For tickets with equal hashVal there exist at most one bet contract
interface ILogiumBinaryBet is
    ILogiumBinaryBetIssuer,
    ILogiumBinaryBetTrade,
    ILogiumBinaryBetCore,
    ILogiumBinaryBetState
{
    // Needed here as issued is declared in two interfaces
    /// @inheritdoc ILogiumBinaryBetCore
    function issuerTotal()
        external
        view
        override(ILogiumBinaryBetCore, ILogiumBinaryBetState)
        returns (uint256);
}

// SPDX-License-Identifier: NONE
/** =========================================================================
 *                                   LICENSE
 * 1. The Source code developed by the Owner, may be used in interaction with
 *    any smart contract only within the logium.org platform on which all
 *    transactions using the Source code shall be conducted. The source code may
 *    be also used to develop tools for trading at logium.org platform.
 * 2. It is unacceptable for third parties to undertake any actions aiming to
 *    modify the Source code of logium.org in order to adapt it to work with a
 *    different smart contract than the one indicated by the Owner by default,
 *    without prior notification to the Owner and obtaining its written consent.
 * 3. It is prohibited to copy, distribute, or modify the Source code without
 *    the prior written consent of the Owner.
 * 4. Source code is subject to copyright, and therefore constitutes the subject
 *    to legal protection. It is unacceptable for third parties to use all or
 *    any parts of the Source code for any purpose without the Owner's prior
 *    written consent.
 * 5. All content within the framework of the Source code, including any
 *    modifications and changes to the Source code provided by the Owner,
 *    constitute the subject to copyright and is therefore protected by law. It
 *    is unacceptable for third parties to use contents found within the
 *    framework of the product without the Owner’s prior written consent.
 * 6. To the extent permitted by applicable law, the Source code is provided on
 *    an "as is" basis. The Owner hereby disclaims all warranties and
 *    conditions, express or implied, including (without limitation) warranties
 *    of merchantability or fitness for a particular purpose.
 * ========================================================================= */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../libraries/Ticket.sol";
import "./logiumCore/ILogiumCoreIssuer.sol";
import "./logiumCore/ILogiumCoreTrader.sol";
import "./logiumCore/ILogiumCoreState.sol";
import "./logiumCore/ILogiumCoreOwner.sol";

/// @title Logium master contract interface
/// @notice This interface is split into multiple small parts
// solhint-disable-next-line no-empty-blocks
interface ILogiumCore is
    ILogiumCoreIssuer,
    ILogiumCoreTrader,
    ILogiumCoreState,
    ILogiumCoreOwner
{

}

// SPDX-License-Identifier: NONE
/** =========================================================================
 *                                   LICENSE
 * 1. The Source code developed by the Owner, may be used in interaction with
 *    any smart contract only within the logium.org platform on which all
 *    transactions using the Source code shall be conducted. The source code may
 *    be also used to develop tools for trading at logium.org platform.
 * 2. It is unacceptable for third parties to undertake any actions aiming to
 *    modify the Source code of logium.org in order to adapt it to work with a
 *    different smart contract than the one indicated by the Owner by default,
 *    without prior notification to the Owner and obtaining its written consent.
 * 3. It is prohibited to copy, distribute, or modify the Source code without
 *    the prior written consent of the Owner.
 * 4. Source code is subject to copyright, and therefore constitutes the subject
 *    to legal protection. It is unacceptable for third parties to use all or
 *    any parts of the Source code for any purpose without the Owner's prior
 *    written consent.
 * 5. All content within the framework of the Source code, including any
 *    modifications and changes to the Source code provided by the Owner,
 *    constitute the subject to copyright and is therefore protected by law. It
 *    is unacceptable for third parties to use contents found within the
 *    framework of the product without the Owner’s prior written consent.
 * 6. To the extent permitted by applicable law, the Source code is provided on
 *    an "as is" basis. The Owner hereby disclaims all warranties and
 *    conditions, express or implied, including (without limitation) warranties
 *    of merchantability or fitness for a particular purpose.
 * ========================================================================= */
pragma solidity ^0.8.0;
pragma abicoder v2;

/// @title Bet interface required by the Logium master contract
/// @notice All non view functions here can only be called by LogiumCore
interface ILogiumBinaryBetCore {
    /// @notice Initialization function. Initializes AND issues a bet. Will be called by the master contract once on only the first take of a given bet instance.
    /// Master MUST transfer returned collaterals or revert.
    /// @param detailsHash expected EIP-712 hash of decoded details implementation must validate this hash
    /// @param trader trader address for the issuing bet
    /// @param takeParams BetImplementation implementation specific ticket take parameters e.g. amount of bet units to open
    /// @param volume total ticket volume, BetImplementation implementation should check issuer volume will not be exceeded
    /// @param detailsEnc BetImplementation implementation specific ticket details
    /// @return issuerPrice issuer USDC collateral expected
    /// @return traderPrice trader USDC collateral expected
    function initAndIssue(
        bytes32 detailsHash,
        address trader,
        bytes32 takeParams,
        uint128 volume,
        bytes calldata detailsEnc
    ) external returns (uint256 issuerPrice, uint256 traderPrice);

    /// @notice Issue a bet to a trader. Master will transfer returned collaterals or revert.
    /// @param detailsHash expected EIP-712 hash of decoded details implementation must validate this hash
    /// @param trader trader address
    /// @param takeParams BetImplementation implementation specific ticket take parameters eg. amount of bet units to open
    /// @param volume total ticket volume, BetImplementation implementation should check issuer volume will not be exceeded
    /// @param detailsEnc BetImplementation implementation specific ticket details
    /// @return issuerPrice issuer USDC collateral expected
    /// @return traderPrice trader USDC collateral expected
    function issue(
        bytes32 detailsHash,
        address trader,
        bytes32 takeParams,
        uint128 volume,
        bytes calldata detailsEnc
    ) external returns (uint256 issuerPrice, uint256 traderPrice);

    /// @notice Query total issuer used volume
    /// @return the total USDC usage
    function issuerTotal() external view returns (uint256);

    /// @notice EIP712 type string of decoded details
    /// @dev used by Core for calculation of Ticket type hash
    /// @return the details type, must contain a definition of "Details"
    // solhint-disable-next-line func-name-mixedcase
    function DETAILS_TYPE() external pure returns (bytes memory);
}

// SPDX-License-Identifier: NONE
/** =========================================================================
 *                                   LICENSE
 * 1. The Source code developed by the Owner, may be used in interaction with
 *    any smart contract only within the logium.org platform on which all
 *    transactions using the Source code shall be conducted. The source code may
 *    be also used to develop tools for trading at logium.org platform.
 * 2. It is unacceptable for third parties to undertake any actions aiming to
 *    modify the Source code of logium.org in order to adapt it to work with a
 *    different smart contract than the one indicated by the Owner by default,
 *    without prior notification to the Owner and obtaining its written consent.
 * 3. It is prohibited to copy, distribute, or modify the Source code without
 *    the prior written consent of the Owner.
 * 4. Source code is subject to copyright, and therefore constitutes the subject
 *    to legal protection. It is unacceptable for third parties to use all or
 *    any parts of the Source code for any purpose without the Owner's prior
 *    written consent.
 * 5. All content within the framework of the Source code, including any
 *    modifications and changes to the Source code provided by the Owner,
 *    constitute the subject to copyright and is therefore protected by law. It
 *    is unacceptable for third parties to use contents found within the
 *    framework of the product without the Owner’s prior written consent.
 * 6. To the extent permitted by applicable law, the Source code is provided on
 *    an "as is" basis. The Owner hereby disclaims all warranties and
 *    conditions, express or implied, including (without limitation) warranties
 *    of merchantability or fitness for a particular purpose.
 * ========================================================================= */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../../libraries/Ticket.sol";

/// @title Issuer functionality of LogiumBinaryBet
interface ILogiumBinaryBetIssuer {
    /// @notice Emitted on claim
    event Claim();

    /// @notice Transfer all issuer winnings to the issuer. Requires that all traders' bets have expired
    /// This function can be called by anyone, but the profit will always be sent to the issuer address
    /// @param ticket ticket immutable structure, validated by the contract
    function claim(Ticket.Immutable calldata ticket) external;

    /// @notice Check expiry of the last trade/take, profits can only be claimed after the returned time
    /// @return expiry of the last trade in block.timestamp (secs since epoch)
    function claimableFrom() external returns (uint256);
}

// SPDX-License-Identifier: NONE
/** =========================================================================
 *                                   LICENSE
 * 1. The Source code developed by the Owner, may be used in interaction with
 *    any smart contract only within the logium.org platform on which all
 *    transactions using the Source code shall be conducted. The source code may
 *    be also used to develop tools for trading at logium.org platform.
 * 2. It is unacceptable for third parties to undertake any actions aiming to
 *    modify the Source code of logium.org in order to adapt it to work with a
 *    different smart contract than the one indicated by the Owner by default,
 *    without prior notification to the Owner and obtaining its written consent.
 * 3. It is prohibited to copy, distribute, or modify the Source code without
 *    the prior written consent of the Owner.
 * 4. Source code is subject to copyright, and therefore constitutes the subject
 *    to legal protection. It is unacceptable for third parties to use all or
 *    any parts of the Source code for any purpose without the Owner's prior
 *    written consent.
 * 5. All content within the framework of the Source code, including any
 *    modifications and changes to the Source code provided by the Owner,
 *    constitute the subject to copyright and is therefore protected by law. It
 *    is unacceptable for third parties to use contents found within the
 *    framework of the product without the Owner’s prior written consent.
 * 6. To the extent permitted by applicable law, the Source code is provided on
 *    an "as is" basis. The Owner hereby disclaims all warranties and
 *    conditions, express or implied, including (without limitation) warranties
 *    of merchantability or fitness for a particular purpose.
 * ========================================================================= */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../../libraries/Ticket.sol";

/// @title State of a LogiumBinaryBet
/// @notice view functions exposing LogiumBinaryBet state, may not be available in other types of bets
interface ILogiumBinaryBetState {
    /// @notice Query details of a trade. Empty after the trade is exercised
    /// @param _0 the tradeId
    /// @return amount trade/bet amount in smallest units as described by the RatioMath library
    /// @return end expiry of the trade/bet
    function traders(uint256 _0)
        external
        view
        returns (uint128 amount, uint128 end);

    /// @notice Query total stake of the issuer. Note: returned value DOES NOT take into account any "exercised" bets, it's only a total of deposited collateral.
    /// @return the total USDC stake value
    function issuerTotal() external view returns (uint256);

    /// @notice Query all traders total stake. Note: returned value DOES NOT take into account any "exercised" bets, it's only a total of deposited collateral.
    /// @param ticket ticket immutable structure, validated by the contract
    /// @return the total USDC stake value
    function tradersTotal(Ticket.Immutable calldata ticket)
        external
        view
        returns (uint256);

    /// @notice current marketTick as used for determining passing strikePrice. Uses Market library.
    /// @param ticket ticket immutable structure, validated by the contract
    /// @return tick = log_1.0001(asset_price_in_usdc)
    function marketTick(Ticket.Immutable calldata ticket)
        external
        view
        returns (int24);

    /// @notice Provides bet exercisability window size
    /// @return exercise window duration in secs
    /// @param ticket ticket immutable structure, validated by the contract
    function exerciseWindowDuration(Ticket.Immutable calldata ticket)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: NONE
/** =========================================================================
 *                                   LICENSE
 * 1. The Source code developed by the Owner, may be used in interaction with
 *    any smart contract only within the logium.org platform on which all
 *    transactions using the Source code shall be conducted. The source code may
 *    be also used to develop tools for trading at logium.org platform.
 * 2. It is unacceptable for third parties to undertake any actions aiming to
 *    modify the Source code of logium.org in order to adapt it to work with a
 *    different smart contract than the one indicated by the Owner by default,
 *    without prior notification to the Owner and obtaining its written consent.
 * 3. It is prohibited to copy, distribute, or modify the Source code without
 *    the prior written consent of the Owner.
 * 4. Source code is subject to copyright, and therefore constitutes the subject
 *    to legal protection. It is unacceptable for third parties to use all or
 *    any parts of the Source code for any purpose without the Owner's prior
 *    written consent.
 * 5. All content within the framework of the Source code, including any
 *    modifications and changes to the Source code provided by the Owner,
 *    constitute the subject to copyright and is therefore protected by law. It
 *    is unacceptable for third parties to use contents found within the
 *    framework of the product without the Owner’s prior written consent.
 * 6. To the extent permitted by applicable law, the Source code is provided on
 *    an "as is" basis. The Owner hereby disclaims all warranties and
 *    conditions, express or implied, including (without limitation) warranties
 *    of merchantability or fitness for a particular purpose.
 * ========================================================================= */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../../libraries/Ticket.sol";

/// @title Trade/Take related interface of ILogiumBinaryBet
interface ILogiumBinaryBetTrade {
    /// @notice Emitted on (successful) exercise of a bet/trade
    /// @param id the exercised trade id
    event Exercise(uint256 indexed id);

    /// @notice Exercises own (msg.sender) bet. Requires strike price to be passed and the bet to be in window.
    /// "strike price passed" is defined as: marketTick() >= strike for UP bets or marketTick() <= strike for down bets
    /// "in window" is defined as: expiry - exerciseWindowDuration() < block.timestamp <= expiry where "expiry" is take time + period
    /// @param ticket ticket immutable structure, validated by the contract
    /// @param blockNumber block number of the take to exercise
    function exercise(Ticket.Immutable calldata ticket, uint256 blockNumber)
        external;

    /// @notice Exercises a different party bet. Execution conditions are the same as exercise()
    /// @param ticket ticket immutable structure, validated by the contract
    /// @param id trade/bet id
    /// @param gasFee if extra USDC fee should be taken to reflect gas usage of this call. Set to true by the auto-exercise bot. Should be set to false in other call scenarios.
    function exerciseOther(
        Ticket.Immutable calldata ticket,
        uint256 id,
        bool gasFee
    ) external;

    /// @notice Get tradeId for given trader on given blockNumber
    /// @dev tradeId = trader << 64 | blockNumber
    /// @param trader trader/ticket taker address
    /// @param blockNumber blockNumber of the ticket take transaction
    /// @return tradeId
    function tradeId(address trader, uint256 blockNumber)
        external
        pure
        returns (uint256);
}

// SPDX-License-Identifier: NONE
/** =========================================================================
 *                                   LICENSE
 * 1. The Source code developed by the Owner, may be used in interaction with
 *    any smart contract only within the logium.org platform on which all
 *    transactions using the Source code shall be conducted. The source code may
 *    be also used to develop tools for trading at logium.org platform.
 * 2. It is unacceptable for third parties to undertake any actions aiming to
 *    modify the Source code of logium.org in order to adapt it to work with a
 *    different smart contract than the one indicated by the Owner by default,
 *    without prior notification to the Owner and obtaining its written consent.
 * 3. It is prohibited to copy, distribute, or modify the Source code without
 *    the prior written consent of the Owner.
 * 4. Source code is subject to copyright, and therefore constitutes the subject
 *    to legal protection. It is unacceptable for third parties to use all or
 *    any parts of the Source code for any purpose without the Owner's prior
 *    written consent.
 * 5. All content within the framework of the Source code, including any
 *    modifications and changes to the Source code provided by the Owner,
 *    constitute the subject to copyright and is therefore protected by law. It
 *    is unacceptable for third parties to use contents found within the
 *    framework of the product without the Owner’s prior written consent.
 * 6. To the extent permitted by applicable law, the Source code is provided on
 *    an "as is" basis. The Owner hereby disclaims all warranties and
 *    conditions, express or implied, including (without limitation) warranties
 *    of merchantability or fitness for a particular purpose.
 * ========================================================================= */
pragma solidity ^0.8.0;
pragma abicoder v2;

/// @title Issuer functionality of LogiumCore
/// @notice functions specified here are executed with msg.sender treated as issuer
interface ILogiumCoreIssuer {
    /// Structure signed by an issuer that authorizes another account to withdraw all free collateral
    /// - to - the address authorized to withdraw
    /// - expiry - timestamp of authorization expiry
    struct WithdrawAuthorization {
        address to;
        uint256 expiry;
    }

    /// Structure signed by an issuer that allows delegated invalidation increase
    struct InvalidationMessage {
        uint64 newInvalidation;
    }

    /// @notice emitted on any free collateral change (deposit, withdraw and takeTicket)
    /// @param issuer issuer address whose free collateral is changing
    /// @param change the change to free collateral positive on deposit, negative on withdrawal and takeTicket
    event CollateralChange(address indexed issuer, int128 change);

    /// @notice emitted on change of invalidation value
    /// @param issuer issuer address who changed their invalidation value
    /// @param newValue new invalidation value
    event Invalidation(address indexed issuer, uint64 newValue);

    /// @notice Withdraw caller USDC from free collateral
    /// @param amount to withdraw. Reverts if amount exceeds balance.
    function withdraw(uint128 amount) external;

    /// @notice Withdraw all caller USDC from free collateral
    /// @return _0 amount actually withdrawn
    function withdrawAll() external returns (uint256);

    /// @notice Withdraw free collateral from another issuer to the caller
    /// @param amount to withdraw. Reverts if amount exceeds balance.
    /// @param authorization authorization created and signed by the other account
    /// @param signature signature of authorization by the from account
    /// @return _0 recovered address of issuer account
    function withdrawFrom(
        uint128 amount,
        WithdrawAuthorization calldata authorization,
        bytes calldata signature
    ) external returns (address);

    /// @notice Withdraw all from other issuer account freeCollateral USDC to caller address
    /// @param authorization authorization created and signed by the other account
    /// @param signature signature of authorization by the from account
    /// @return _0 recovered address of issuer account
    /// @return _1 amount actually withdrawn
    function withdrawAllFrom(
        WithdrawAuthorization calldata authorization,
        bytes calldata signature
    ) external returns (address, uint256);

    /// @notice Deposit caller USDC to free collateral. Requires approval on USDC contract
    /// @param amount amount to deposit
    function deposit(uint128 amount) external;

    /// @notice Deposit from sender to target user freeCollateral
    /// @param target target address for freeCollateral deposit
    /// @param amount amount to deposit
    function depositTo(address target, uint128 amount) external;

    /// @notice Change caller invalidation value. Invalidation value can be only increased
    /// @param newInvalidation new invalidation value
    function invalidate(uint64 newInvalidation) external;

    /// @notice Change other issuer invalidation value using an invalidation message signed by them. Invalidation value can be only increased
    /// @param invalidationMsg the invalidation message containing new invalidation value
    /// @param signature issuer signature over invalidation message
    function invalidateOther(
        InvalidationMessage calldata invalidationMsg,
        bytes calldata signature
    ) external;
}

// SPDX-License-Identifier: NONE
/** =========================================================================
 *                                   LICENSE
 * 1. The Source code developed by the Owner, may be used in interaction with
 *    any smart contract only within the logium.org platform on which all
 *    transactions using the Source code shall be conducted. The source code may
 *    be also used to develop tools for trading at logium.org platform.
 * 2. It is unacceptable for third parties to undertake any actions aiming to
 *    modify the Source code of logium.org in order to adapt it to work with a
 *    different smart contract than the one indicated by the Owner by default,
 *    without prior notification to the Owner and obtaining its written consent.
 * 3. It is prohibited to copy, distribute, or modify the Source code without
 *    the prior written consent of the Owner.
 * 4. Source code is subject to copyright, and therefore constitutes the subject
 *    to legal protection. It is unacceptable for third parties to use all or
 *    any parts of the Source code for any purpose without the Owner's prior
 *    written consent.
 * 5. All content within the framework of the Source code, including any
 *    modifications and changes to the Source code provided by the Owner,
 *    constitute the subject to copyright and is therefore protected by law. It
 *    is unacceptable for third parties to use contents found within the
 *    framework of the product without the Owner’s prior written consent.
 * 6. To the extent permitted by applicable law, the Source code is provided on
 *    an "as is" basis. The Owner hereby disclaims all warranties and
 *    conditions, express or implied, including (without limitation) warranties
 *    of merchantability or fitness for a particular purpose.
 * ========================================================================= */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../logiumBinaryBet/ILogiumBinaryBetCore.sol";

/// @title LogiumCore owner interface for changing system parameters
/// @notice Functions specified here can only be called by the Owner of the Logium master contract
interface ILogiumCoreOwner {
    /// @notice emitted when a new master bet contract address is allowed
    /// @param newBetImplementation new address of the master bet contract
    event AllowedBetImplementation(ILogiumBinaryBetCore newBetImplementation);

    /// @notice emitted when a master bet contract address is blocked
    /// @param blockedBetImplementation the address of the master bet contract
    event DisallowedBetImplementation(
        ILogiumBinaryBetCore blockedBetImplementation
    );

    /// @notice Allows a master bet contract address for use to create bet contract clones
    /// @param newBetImplementation the new address, the contract under this address MUST follow ILogiumBinaryBetCore interface
    function allowBetImplementation(ILogiumBinaryBetCore newBetImplementation)
        external;

    /// @notice Disallows a master bet contract address for use to create bet contract clones
    /// @param blockedBetImplementation the previously allowed master bet contract address
    function disallowBetImplementation(
        ILogiumBinaryBetCore blockedBetImplementation
    ) external;
}

// SPDX-License-Identifier: NONE
/** =========================================================================
 *                                   LICENSE
 * 1. The Source code developed by the Owner, may be used in interaction with
 *    any smart contract only within the logium.org platform on which all
 *    transactions using the Source code shall be conducted. The source code may
 *    be also used to develop tools for trading at logium.org platform.
 * 2. It is unacceptable for third parties to undertake any actions aiming to
 *    modify the Source code of logium.org in order to adapt it to work with a
 *    different smart contract than the one indicated by the Owner by default,
 *    without prior notification to the Owner and obtaining its written consent.
 * 3. It is prohibited to copy, distribute, or modify the Source code without
 *    the prior written consent of the Owner.
 * 4. Source code is subject to copyright, and therefore constitutes the subject
 *    to legal protection. It is unacceptable for third parties to use all or
 *    any parts of the Source code for any purpose without the Owner's prior
 *    written consent.
 * 5. All content within the framework of the Source code, including any
 *    modifications and changes to the Source code provided by the Owner,
 *    constitute the subject to copyright and is therefore protected by law. It
 *    is unacceptable for third parties to use contents found within the
 *    framework of the product without the Owner’s prior written consent.
 * 6. To the extent permitted by applicable law, the Source code is provided on
 *    an "as is" basis. The Owner hereby disclaims all warranties and
 *    conditions, express or implied, including (without limitation) warranties
 *    of merchantability or fitness for a particular purpose.
 * ========================================================================= */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../logiumBinaryBet/ILogiumBinaryBetCore.sol";

/// @title Functions for querying the state of the Logium master contract
/// @notice All of these functions are "view". Some directly describe public state variables
interface ILogiumCoreState {
    /// @notice Query all properties stored for a issuer/user
    /// @dev To save gas all user properties fit in a single 256 bit storage slot
    /// @param _0 the queries issuer/user address
    /// @return freeUSDCCollateral free collateral for use with issued tickets
    /// @return invalidation value for ticket invalidation
    /// @return exists whether issuer/user has ever used our protocol
    function users(address _0)
        external
        view
        returns (
            uint128 freeUSDCCollateral,
            uint64 invalidation,
            bool exists
        );

    /// @notice Check if a master bet contract can be used for creating bets
    /// @param betImplementation the address of the contract
    /// @return boolean if it can be used
    function isAllowedBetImplementation(ILogiumBinaryBetCore betImplementation)
        external
        view
        returns (bool);

    /// Get a bet contract for ticket if it exists.
    /// Returned contract is a thin clone of provided logiumBinaryBetImplementation
    /// reverts if the provided logiumBinaryBetImplementation is not allowed
    /// Note: LogiumBinaryBetImplementation may be upgraded/replaced and in the future it
    /// MAY NOT follow ILogiumBinaryBet interface, but it will always follow ILogiumBinaryBetCore interface.
    /// @param hashVal ticket hashVal (do not confuse with ticket hash for signing)
    /// @param logiumBinaryBetImplementation address of bet_implementation of the ticket
    /// @return address of the existing bet contract or 0x0 if the ticket was never taken
    function contractFromTicketHash(
        bytes32 hashVal,
        ILogiumBinaryBetCore logiumBinaryBetImplementation
    ) external view returns (ILogiumBinaryBetCore);
}

// SPDX-License-Identifier: NONE
/** =========================================================================
 *                                   LICENSE
 * 1. The Source code developed by the Owner, may be used in interaction with
 *    any smart contract only within the logium.org platform on which all
 *    transactions using the Source code shall be conducted. The source code may
 *    be also used to develop tools for trading at logium.org platform.
 * 2. It is unacceptable for third parties to undertake any actions aiming to
 *    modify the Source code of logium.org in order to adapt it to work with a
 *    different smart contract than the one indicated by the Owner by default,
 *    without prior notification to the Owner and obtaining its written consent.
 * 3. It is prohibited to copy, distribute, or modify the Source code without
 *    the prior written consent of the Owner.
 * 4. Source code is subject to copyright, and therefore constitutes the subject
 *    to legal protection. It is unacceptable for third parties to use all or
 *    any parts of the Source code for any purpose without the Owner's prior
 *    written consent.
 * 5. All content within the framework of the Source code, including any
 *    modifications and changes to the Source code provided by the Owner,
 *    constitute the subject to copyright and is therefore protected by law. It
 *    is unacceptable for third parties to use contents found within the
 *    framework of the product without the Owner’s prior written consent.
 * 6. To the extent permitted by applicable law, the Source code is provided on
 *    an "as is" basis. The Owner hereby disclaims all warranties and
 *    conditions, express or implied, including (without limitation) warranties
 *    of merchantability or fitness for a particular purpose.
 * ========================================================================= */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "../../libraries/Ticket.sol";
import "../logiumBinaryBet/ILogiumBinaryBetCore.sol";

/// @title Trader functionality of LogiumCore
/// @notice functions specified here are executed with msg.sender treated as trader
interface ILogiumCoreTrader {
    /// @notice Emitted when a bet is taken (take ticket is successfully called)
    /// @param issuer issuer/maker of the ticket/offer
    /// @param trader trader/taker of the bet
    /// @param betImplementation address of the bet master contract used
    /// @param takeParams betImplementation dependent take params eg. "fraction" of the ticket to take
    /// @param details betImplementation specific details of the ticket
    event BetEmitted(
        address indexed issuer,
        address indexed trader,
        ILogiumBinaryBetCore betImplementation,
        bytes32 takeParams,
        bytes details
    );

    /// @notice Take a specified amount of the ticket. Emits BetEmitted and CollateralChange events.
    /// @param detailsHash EIP-712 hash of decoded Payload.details. Will be validated
    /// @param payload ticket payload of the ticket to take
    /// @param signature ticket signature of the ticket to take
    /// @param takeParams BetImplementation implementation specific ticket take parameters e.g. amount of bet units to open
    /// @return address of the bet contract.
    /// Note: although after taking the implementation of a bet contract will not change, masterBetContract is subject to change and its interface MAY change
    function takeTicket(
        bytes memory signature,
        Ticket.Payload memory payload,
        bytes32 detailsHash,
        bytes32 takeParams
    ) external returns (address);
}

// SPDX-License-Identifier: NONE
/** =========================================================================
 *                                   LICENSE
 * 1. The Source code developed by the Owner, may be used in interaction with
 *    any smart contract only within the logium.org platform on which all
 *    transactions using the Source code shall be conducted. The source code may
 *    be also used to develop tools for trading at logium.org platform.
 * 2. It is unacceptable for third parties to undertake any actions aiming to
 *    modify the Source code of logium.org in order to adapt it to work with a
 *    different smart contract than the one indicated by the Owner by default,
 *    without prior notification to the Owner and obtaining its written consent.
 * 3. It is prohibited to copy, distribute, or modify the Source code without
 *    the prior written consent of the Owner.
 * 4. Source code is subject to copyright, and therefore constitutes the subject
 *    to legal protection. It is unacceptable for third parties to use all or
 *    any parts of the Source code for any purpose without the Owner's prior
 *    written consent.
 * 5. All content within the framework of the Source code, including any
 *    modifications and changes to the Source code provided by the Owner,
 *    constitute the subject to copyright and is therefore protected by law. It
 *    is unacceptable for third parties to use contents found within the
 *    framework of the product without the Owner’s prior written consent.
 * 6. To the extent permitted by applicable law, the Source code is provided on
 *    an "as is" basis. The Owner hereby disclaims all warranties and
 *    conditions, express or implied, including (without limitation) warranties
 *    of merchantability or fitness for a particular purpose.
 * ========================================================================= */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

/// @title Logium constants
/// @notice All constants relevant in Logium for ex. USDC address
/// @dev This library contains only "public constant" state variables
library Constants {
    /// USDC contract
    /// Same as used by app.compound.finance
    IERC20 public constant USDC =
        IERC20(address(0x07865c6E87B9F70255377e024ace6630C1Eaa37F));

    /// Wrapped ETH contract
    IERC20 public constant WETH =
        IERC20(address(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6));

    /// DAI contract
    /// Same as used by app.compound.finance
    IERC20 public constant DAI =
        IERC20(address(0x2899a03ffDab5C90BADc5920b4f53B0884EB13cC));

    /// USDT contract
    /// Same as used by app.compound.finance
    IERC20 public constant USDT =
        IERC20(address(0x79C950C7446B234a6Ad53B908fBF342b01c4d446));

    /// Uniswap V3 Pool for conversion rate between ETH & USDC
    IUniswapV3Pool public constant ETH_USDC_POOL =
        IUniswapV3Pool(address(0x6337B3caf9C5236c7f3D1694410776119eDaF9FA));

    /// Estimated gas usage of bet exerciseOther, used for extra gas fee when exercising with bot
    /// @dev same as for rinkeby
    uint256 public constant EXERCISE_GAS = 90400;

    /// Max Fee with 9 decimal places
    uint256 public constant MAX_FEE_X9 = 20 * 10**7; //20%
}

// SPDX-License-Identifier: NONE
/** =========================================================================
 *                                   LICENSE
 * 1. The Source code developed by the Owner, may be used in interaction with
 *    any smart contract only within the logium.org platform on which all
 *    transactions using the Source code shall be conducted. The source code may
 *    be also used to develop tools for trading at logium.org platform.
 * 2. It is unacceptable for third parties to undertake any actions aiming to
 *    modify the Source code of logium.org in order to adapt it to work with a
 *    different smart contract than the one indicated by the Owner by default,
 *    without prior notification to the Owner and obtaining its written consent.
 * 3. It is prohibited to copy, distribute, or modify the Source code without
 *    the prior written consent of the Owner.
 * 4. Source code is subject to copyright, and therefore constitutes the subject
 *    to legal protection. It is unacceptable for third parties to use all or
 *    any parts of the Source code for any purpose without the Owner's prior
 *    written consent.
 * 5. All content within the framework of the Source code, including any
 *    modifications and changes to the Source code provided by the Owner,
 *    constitute the subject to copyright and is therefore protected by law. It
 *    is unacceptable for third parties to use contents found within the
 *    framework of the product without the Owner’s prior written consent.
 * 6. To the extent permitted by applicable law, the Source code is provided on
 *    an "as is" basis. The Owner hereby disclaims all warranties and
 *    conditions, express or implied, including (without limitation) warranties
 *    of merchantability or fitness for a particular purpose.
 * ========================================================================= */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "./Constants.BinaryBet.sol";
import "./OracleLibrary.sol";

/// @title Library for interacting with uniswap V3 pools
/// @notice Provides function to get a "tick" vs USDC for a given pool Note: do not confuse this with pool tick
library Market {
    /// @notice Queries current "tick" vs USDC on a pool.
    /// tick = log_1.0001(token_price), where token price numerator is **always** USDC and denominator is pool token.
    /// Pool token is defined as the token of the pool that is not USDC or WETH, if the pool is USDC-WETH than token is WETH.
    /// Base token is the other token that is not pool token.
    /// If base token is not USDC, then Constants.ETH_USDC_POOL is used for conversion of the token denominated price.
    /// Behavior for non USDC-WETH pool is undefined.
    /// Query is performed using the uniswap pool oracle functionality (observations buffer) to prevent the price from being affected by flash loans
    /// @param pool the uniswap v3 pool to query
    /// @return Documents the return variables of a contract’s function state variable
    function getMarketTickvsUSDC(IUniswapV3Pool pool)
        internal
        view
        returns (int24)
    {
        (IERC20 refToken, IERC20 assetToken) = getPair(pool);
        // sortedTick = ref / token
        int24 sortedTick = getSortedTick(pool, refToken, assetToken);
        if (refToken != Constants.WETH) {
            // refToken is a stable coin. We assume value of all stable coins is the same. Tokens here: USDC, USDT, DAI
            return sortedTick; // sortedTick = USD / token
        } else {
            // refToken == WETH
            // solhint-disable-next-line var-name-mixedcase
            int24 sortedUSDC_ETH = getSortedTick(
                Constants.ETH_USDC_POOL,
                Constants.USDC,
                Constants.WETH
            );
            // sortedTick = WETH / token
            // sortedTick + sortedUSDC_ETH = (WETH / token) * (USDC / WETH) = USD(C) / token
            return sortedTick + sortedUSDC_ETH;
        }
    }

    function getMarketTickvsUSDCwithUSDCWETHTick(IUniswapV3Pool pool)
        internal
        view
        returns (int24, int24)
    {
        (IERC20 refToken, IERC20 assetToken) = getPair(pool);
        // sortedTick = ref / token
        int24 sortedTick = getSortedTick(pool, refToken, assetToken);
        // solhint-disable-next-line var-name-mixedcase
        int24 sortedUSDC_ETH = getSortedTick(
            Constants.ETH_USDC_POOL,
            Constants.USDC,
            Constants.WETH
        );
        if (refToken != Constants.WETH) {
            // refToken is a stable coin. We assume value of all stable coins is the same. Tokens here: USDC, USDT, DAI
            return (sortedTick, sortedUSDC_ETH); // sortedTick = USD / token
        } else {
            // refToken == WETH
            // sortedTick = WETH / token
            // sortedTick + sortedUSDC_ETH = (WETH / token) * (USDC / WETH) = USDC / token
            return (sortedTick + sortedUSDC_ETH, sortedUSDC_ETH);
        }
    }

    /// @notice gets uniswap tick on a pool sorted such that
    /// returned tick = log_1.0001(price) where price is denominated in provided "denominator"
    /// @dev Uniswap ticks on a pool are between "token0" and "token1" which are always sorted depending on address value.
    /// @dev This function gets tick of given pool using OracleLibrary and possibly inverts (*-1) such that returned tick is as expected
    /// @dev correctness of pool, numerator and denominator is assumed
    /// @param pool the pool
    /// @param numerator one of token0 & token1 of pool
    /// @param denominator one of token0 & token1 of pool but not "numerator"
    /// @return the sorted tick
    function getSortedTick(
        IUniswapV3Pool pool,
        IERC20 numerator,
        IERC20 denominator
    ) internal view returns (int24) {
        int24 timeWeightedTick = OracleLibrary.consult(pool);
        if (numerator > denominator) {
            return timeWeightedTick;
        } else {
            return -timeWeightedTick;
        }
    }

    /// @notice Returns pair of tokens of supplied uniswap pools
    /// sorted such that the first/base token is always USDC, DAI, USDT or WETH.
    /// if both tokens qualify to be a base token then we use the following ordering.
    /// Order (earlier is preferred): USDC, WETH, DAI, USDT
    /// Reverts for pool that is not vs a base token
    /// @param pool the uniswapV3 pool to query
    /// @return base base token (USDC, WETH, DAI or USDT)
    /// @return asset the other token
    function getPair(IUniswapV3Pool pool)
        internal
        view
        returns (IERC20 base, IERC20 asset)
    {
        IERC20 token0 = IERC20(pool.token0());
        IERC20 token1 = IERC20(pool.token1());

        bool found;
        (found, base, asset) = ifOneSort(token0, token1, Constants.USDC);
        if (found) return (base, asset);
        (found, base, asset) = ifOneSort(token0, token1, Constants.WETH);
        if (found) return (base, asset);
        (found, base, asset) = ifOneSort(token0, token1, Constants.DAI);
        if (found) return (base, asset);
        (found, base, asset) = ifOneSort(token0, token1, Constants.USDT);
        if (found) return (base, asset);
        revert("Invalid pool");
    }

    // @dev helper for getPair
    function ifOneSort(
        IERC20 token0,
        IERC20 token1,
        IERC20 search
    )
        private
        pure
        returns (
            bool isOne,
            IERC20 base,
            IERC20 asset
        )
    {
        if (token0 == search) return (true, token0, token1);
        else if (token1 == search) return (true, token1, token0);
        else return (false, IERC20(address(0)), IERC20(address(0)));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Altered implementation from https://github.com/Uniswap/v3-periphery/blob/ee7982942e4397f67e32c291ebed6bcf7210a8f5/contracts/libraries/OracleLibrary.sol
// including elements of https://github.com/Uniswap/v3-core/tree/fc2107bd5709cdee6742d5164c1eb998566bcb75/contracts libraries and interfaces (only licensed "GPL-2.0-or-later")
pragma solidity ^0.8.0;
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

/// @title Oracle Library
/// @notice redone implementation consult function of official Uniswap/v3-periphery OracleLibrary for solidity 0.8
library OracleLibrary {
    /// @dev uniswap min tick value
    int24 internal constant MIN_TICK = -887272;
    /// @dev uniswap max tick value
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @notice Calculates current tick for a given Uniswap V3 pool using oracle data/observations buffer to avoid flash-loan possibility
    /// @param pool Address of the pool that we want to observe
    /// @return tick The tick
    function consult(IUniswapV3Pool pool) internal view returns (int24) {
        (
            ,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            ,
            ,

        ) = pool.slot0();
        (
            uint32 o1blockTimestamp,
            int56 o1tickCumulative,
            ,
            bool o1initialized
        ) = pool.observations(observationIndex);
        require(o1initialized, "Oracle uninitialized"); // sanity check
        // if newest observation.timestamp is not from current block
        // than there were no swaps on this pool in current block and we can use slot0 tick
        if (o1blockTimestamp != uint32(block.timestamp)) return tick;
        else {
            // if there were any swaps in the current block, we use the oracle UniV3 feature
            // this is only possible if there are at least 2 observations available
            require(observationCardinality > 1, "OLD"); // same as uniswap impl. error
            uint16 prevObservation = observationIndex > 0
                ? observationIndex - 1
                : observationCardinality - 1;
            (
                uint32 o2blockTimestamp,
                int56 o2tickCumulative,
                ,
                bool o2initialized
            ) = pool.observations(prevObservation);
            require(o2initialized, "Oracle uninitialized"); // sanity check
            require(
                o2blockTimestamp != 0 && o1blockTimestamp > o2blockTimestamp,
                "Invalid oracle state"
            ); // sanity check
            uint32 delta = o1blockTimestamp - o2blockTimestamp;
            int56 result = (o1tickCumulative - o2tickCumulative) /
                int56(uint56(delta));
            require(result >= MIN_TICK, "TLM"); // sanity check
            require(result <= MAX_TICK, "TUM"); // sanity check
            return int24(result);
        }
    }

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick)
        internal
        pure
        returns (uint160 sqrtPriceX96)
    {
        unchecked {
            uint256 absTick = tick < 0
                ? uint256(-int256(tick))
                : uint256(int256(tick));
            require(absTick <= uint256(int256(MAX_TICK)), "T");

            uint256 ratio = absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0)
                ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0)
                ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0)
                ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0)
                ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0)
                ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0)
                ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0)
                ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0)
                ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0)
                ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0)
                ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0)
                ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0)
                ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0)
                ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0)
                ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0)
                ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0)
                ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0)
                ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0)
                ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0)
                ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96 = uint160(
                (ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1)
            );
        }
    }
}

// SPDX-License-Identifier: NONE
/** =========================================================================
 *                                   LICENSE
 * 1. The Source code developed by the Owner, may be used in interaction with
 *    any smart contract only within the logium.org platform on which all
 *    transactions using the Source code shall be conducted. The source code may
 *    be also used to develop tools for trading at logium.org platform.
 * 2. It is unacceptable for third parties to undertake any actions aiming to
 *    modify the Source code of logium.org in order to adapt it to work with a
 *    different smart contract than the one indicated by the Owner by default,
 *    without prior notification to the Owner and obtaining its written consent.
 * 3. It is prohibited to copy, distribute, or modify the Source code without
 *    the prior written consent of the Owner.
 * 4. Source code is subject to copyright, and therefore constitutes the subject
 *    to legal protection. It is unacceptable for third parties to use all or
 *    any parts of the Source code for any purpose without the Owner's prior
 *    written consent.
 * 5. All content within the framework of the Source code, including any
 *    modifications and changes to the Source code provided by the Owner,
 *    constitute the subject to copyright and is therefore protected by law. It
 *    is unacceptable for third parties to use contents found within the
 *    framework of the product without the Owner’s prior written consent.
 * 6. To the extent permitted by applicable law, the Source code is provided on
 *    an "as is" basis. The Owner hereby disclaims all warranties and
 *    conditions, express or implied, including (without limitation) warranties
 *    of merchantability or fitness for a particular purpose.
 * ========================================================================= */
pragma solidity ^0.8.0;
pragma abicoder v2;

/// @title Ratio Math - helper function for calculations related to ratios
/// @notice ratio specifies proportion of issuer to trader stakes
/// - positive ratio: issuer puts "ratio", trader puts "1"
/// - negative ratio: issuer puts "1", trader puts "ratio"
/// zero is an invalid value
///
/// Amount is the smallest unit of a bet. It's equal to min(issuerStake, traderStake) which avoids division.
/// For a given ratio total stake is always amount*(abs(ratio)+1)
library RatioMath {
    /// @notice Calculate issuerStake and traderStake for a given amount of bet and ratio
    /// @param amount number of smallest bet units (=min(issuerStake, traderStake))
    /// @param ratio bet ratio
    /// @return pair (issuerStake, traderStake)
    function priceFromRatio(uint256 amount, int24 ratio)
        internal
        pure
        returns (uint256, uint256)
    {
        require(ratio != 0, "Ratio can't be zero");
        if (ratio > 0) {
            return (amount * (uint24(ratio)), amount);
        } else {
            return (amount, amount * (uint24(-ratio)));
        }
    }

    function issuerToTrader(uint128 issuer, int24 ratio)
        internal
        pure
        returns (uint128)
    {
        require(ratio != 0, "Ratio can't be zero");
        if (ratio > 0) return issuer / uint24(ratio);
        else {
            return issuer * uint24(-ratio);
        }
    }

    /// @notice Calculates totalStake of a bet based on amount issued and ratio
    /// @param amount number of smallest bet units issued in a bet
    /// @param ratio bet ratio
    /// @return totalStake = issuerStake + traderStake
    function totalStake(uint256 amount, int24 ratio)
        internal
        pure
        returns (uint256)
    {
        require(ratio != 0, "Ratio can't be zero");
        if (ratio > 0) {
            return amount * (uint24(ratio) + 1);
        } else {
            return amount * (uint24(-ratio) + 1);
        }
    }

    function totalStakeToPrice(uint256 total, int24 ratio)
        internal
        pure
        returns (uint256 issuerPrice, uint256 traderPrice)
    {
        require(ratio != 0, "Ratio can't be zero");
        uint256 totalMultiplier;
        if (ratio > 0) {
            totalMultiplier = (uint256(uint24(ratio)) + 1);
        } else {
            totalMultiplier = (uint256(uint24(-ratio)) + 1);
        }
        uint256 extra = total % totalMultiplier;
        uint256 baseUnits = total / totalMultiplier;
        (issuerPrice, traderPrice) = priceFromRatio(baseUnits, ratio);
        traderPrice += extra;
    }
}

// SPDX-License-Identifier: NONE
/** =========================================================================
 *                                   LICENSE
 * 1. The Source code developed by the Owner, may be used in interaction with
 *    any smart contract only within the logium.org platform on which all
 *    transactions using the Source code shall be conducted. The source code may
 *    be also used to develop tools for trading at logium.org platform.
 * 2. It is unacceptable for third parties to undertake any actions aiming to
 *    modify the Source code of logium.org in order to adapt it to work with a
 *    different smart contract than the one indicated by the Owner by default,
 *    without prior notification to the Owner and obtaining its written consent.
 * 3. It is prohibited to copy, distribute, or modify the Source code without
 *    the prior written consent of the Owner.
 * 4. Source code is subject to copyright, and therefore constitutes the subject
 *    to legal protection. It is unacceptable for third parties to use all or
 *    any parts of the Source code for any purpose without the Owner's prior
 *    written consent.
 * 5. All content within the framework of the Source code, including any
 *    modifications and changes to the Source code provided by the Owner,
 *    constitute the subject to copyright and is therefore protected by law. It
 *    is unacceptable for third parties to use contents found within the
 *    framework of the product without the Owner’s prior written consent.
 * 6. To the extent permitted by applicable law, the Source code is provided on
 *    an "as is" basis. The Owner hereby disclaims all warranties and
 *    conditions, express or implied, including (without limitation) warranties
 *    of merchantability or fitness for a particular purpose.
 * ========================================================================= */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../interfaces/logiumBinaryBet/ILogiumBinaryBetCore.sol";

/// @title Ticket library with structure and helper functions
/// @notice allows calculation of ticket properties and validation of an ticket
/// @dev It's recommended to use all of this function throw `using Ticket for Ticket.Payload;`
library Ticket {
    using ECDSA for bytes32;
    using Ticket for Payload;

    /// Ticket structure as signed by issuer
    /// Ticket parameters:
    /// - nonce - ticket is only valid for taking if nonce > user.invalidation
    /// - deadline - unix secs timestamp, ticket is only valid for taking if blocktime is < deadline
    /// - volume - max issuer collateral allowed to be used by this ticket
    /// - betImplementation - betImplementation that's code will govern this ticket
    /// - details - extra ticket parameters interpreted by betImplementation
    struct Payload {
        uint128 volume;
        uint64 nonce;
        uint256 deadline;
        ILogiumBinaryBetCore betImplementation;
        bytes details;
    }

    /// Structure with ticket properties that affect hashVal
    struct Immutable {
        address maker;
        bytes details;
    }

    /// @notice Calculates hashVal of a maker's ticket. For each unique HashVal only one BetContract is created.
    /// Nonce, volume, deadline or betImplementation do not affect the hashVal. Ticket "details" and signer (signing by a different party) do.
    /// @param self details
    /// @param maker the maker/issuer address
    /// @return the hashVal
    function hashVal(bytes memory self, address maker)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(maker, self));
    }

    function hashValImmutable(Immutable memory self)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(self.maker, self.details));
    }

    function fullTypeHash(bytes memory detailsType)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                bytes.concat(
                    "Ticket(uint128 volume,uint64 nonce,uint256 deadline,address betImplementation,Details details)",
                    detailsType
                )
            );
    }
}

// SPDX-License-Identifier: NONE
/** =========================================================================
 *                                   LICENSE
 * 1. The Source code developed by the Owner, may be used in interaction with
 *    any smart contract only within the logium.org platform on which all
 *    transactions using the Source code shall be conducted. The source code may
 *    be also used to develop tools for trading at logium.org platform.
 * 2. It is unacceptable for third parties to undertake any actions aiming to
 *    modify the Source code of logium.org in order to adapt it to work with a
 *    different smart contract than the one indicated by the Owner by default,
 *    without prior notification to the Owner and obtaining its written consent.
 * 3. It is prohibited to copy, distribute, or modify the Source code without
 *    the prior written consent of the Owner.
 * 4. Source code is subject to copyright, and therefore constitutes the subject
 *    to legal protection. It is unacceptable for third parties to use all or
 *    any parts of the Source code for any purpose without the Owner's prior
 *    written consent.
 * 5. All content within the framework of the Source code, including any
 *    modifications and changes to the Source code provided by the Owner,
 *    constitute the subject to copyright and is therefore protected by law. It
 *    is unacceptable for third parties to use contents found within the
 *    framework of the product without the Owner’s prior written consent.
 * 6. To the extent permitted by applicable law, the Source code is provided on
 *    an "as is" basis. The Owner hereby disclaims all warranties and
 *    conditions, express or implied, including (without limitation) warranties
 *    of merchantability or fitness for a particular purpose.
 * ========================================================================= */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

/// @title TicketBinaryBet structure for LogiumBinaryBet
/// @notice details structure for binary bets
library TicketBinaryBet {
    /// Ticket details specific to LogiumBinaryBet implementation
    /// Bet parameters:
    /// - isUp - true for UP bet, false for DOWN bet
    /// - pool - uniswap pool for bet strike check. Either an USDC-token or WETH-token pool
    /// - strikeUniswapTick - token/USDC sorted tick (see Market library), if passed bet can be exercised in exercised window
    /// - period - bet period in secs
    /// - ratio - issuer to taker stake proportion encoded as specified in RatioMath library
    /// - issuerWinFee - fee taken from issuer profit on claim and transferred to feeCollector, encoded with 9 decimal points
    /// - traderWinFee - fee taken from trader profit on exercise and transferred to feeCollector, encoded with 9 decimal points
    /// - exerciseWindowDuration - exercise window duration in sec, exercise window is from take "time + period - exerciseWindowDuration" to "time + period"
    /// - claim - address to transfer profit on claim, if 0x0 profit is transferred to freeCollateral
    struct Details {
        bool isUp;
        IUniswapV3Pool pool;
        int24 strikeUniswapTick;
        uint32 period;
        int24 ratio;
        uint32 issuerWinFee;
        uint32 traderWinFee;
        uint32 exerciseWindowDuration;
        address claimTo;
    }

    /// EIP712 type of Details struct
    bytes public constant DETAILS_TYPE =
        "Details(bool isUp,address pool,int24 strikeUniswapTick,uint32 period,int24 ratio,uint32 issuerWinFee,uint32 traderWinFee,uint32 exerciseWindowDuration,address claimTo)";

    function unpackBinaryBetDetails(bytes calldata self)
        internal
        pure
        returns (Details memory out)
    {
        require(self.length == 63, "Invalid details length");
        bytes1 isUpEnc = self[0];
        require(
            (isUpEnc == 0) || (isUpEnc == bytes1(uint8(1))),
            "Invalid bool encoding"
        );
        out.isUp = bool(isUpEnc == bytes1(uint8(1)));
        // solhint-disable no-inline-assembly
        assembly {
            // isUp is decoded above
            calldatacopy(add(out, sub(0x40, 20)), add(self.offset, 1), 20) // pool
            let strike := sar(sub(256, 24), calldataload(add(self.offset, 21)))
            mstore(add(out, sub(0x60, 0x20)), strike)
            calldatacopy(add(out, sub(0x80, 4)), add(self.offset, 24), 4) // period
            let ratio := sar(sub(256, 24), calldataload(add(self.offset, 28)))
            mstore(add(out, sub(0xa0, 0x20)), ratio)
            calldatacopy(add(out, sub(0xc0, 4)), add(self.offset, 31), 4) // issuerWinFee
            calldatacopy(add(out, sub(0xe0, 4)), add(self.offset, 35), 4) // traderWinFee
            calldatacopy(add(out, sub(0x100, 4)), add(self.offset, 39), 4) // exerciseWindowDuration
            calldatacopy(add(out, sub(0x120, 20)), add(self.offset, 43), 20) // claimTo
        }
    }

    function packBinaryBetDetails(Details memory self)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                self.isUp,
                self.pool,
                self.strikeUniswapTick,
                self.period,
                self.ratio,
                self.issuerWinFee,
                self.traderWinFee,
                self.exerciseWindowDuration,
                self.claimTo
            );
    }

    function hashDetails(Details memory self) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(DETAILS_TYPE),
                    self.isUp,
                    self.pool,
                    self.strikeUniswapTick,
                    self.period,
                    self.ratio,
                    self.issuerWinFee,
                    self.traderWinFee,
                    self.exerciseWindowDuration,
                    self.claimTo
                )
            );
    }
}
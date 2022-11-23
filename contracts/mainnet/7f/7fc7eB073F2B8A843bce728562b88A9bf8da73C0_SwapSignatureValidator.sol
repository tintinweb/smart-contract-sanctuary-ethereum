// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.16;

import {Swap, SwapStep, StealthSwap} from "./Swap.sol";

interface ISwapSignatureValidator {
    function validateSwapSignature(Swap calldata swap, bytes calldata swapSignature) external view;

    function validateStealthSwapStepSignature(
        SwapStep calldata swapStep,
        StealthSwap calldata stealthSwap,
        bytes calldata stealthSwapSignature
    ) external view returns (uint256 stepIndex);

    function findStealthSwapStepIndex(
        SwapStep calldata swapStep,
        StealthSwap calldata stealthSwap
    ) external view returns (uint256 stepIndex);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

struct TokenCheck {
    address token;
    uint256 minAmount;
    uint256 maxAmount;
}

struct TokenUse {
    address protocol;
    uint256 chain;
    address account;
    uint256[] inIndices;
    TokenCheck[] outs;
    bytes args; // Example of reserved value: 0x44796E616D6963 ("Dynamic")
}

struct SwapStep {
    uint256 chain;
    address swapper;
    address account;
    bool useDelegate;
    uint256 nonce;
    uint256 deadline;
    TokenCheck[] ins;
    TokenCheck[] outs;
    TokenUse[] uses;
}

struct Swap {
    SwapStep[] steps;
}

struct StealthSwap {
    uint256 chain;
    address swapper;
    address account;
    bytes32[] stepHashes;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {EIP712D} from "../../lib/draft-EIP712D.sol";
import {ECDSA} from "../../lib/ECDSA.sol";

import {ISwapSignatureValidator} from "./ISwapSignatureValidator.sol";
// prettier-ignore
import {
    TokenCheck,
    TokenUse,
    SwapStep,
    Swap,
    StealthSwap
} from "./Swap.sol";
// prettier-ignore
import {
    TOKEN_CHECK_TYPE_HASH,
    TOKEN_USE_TYPE_HASH,
    SWAP_STEP_TYPE_HASH,
    SWAP_TYPE_HASH,
    STEALTH_SWAP_TYPE_HASH
} from "./SwapTypeHash.sol";

contract SwapSignatureValidator is ISwapSignatureValidator, EIP712D {
    // prettier-ignore
    constructor()
        EIP712D("xSwap", "1")
    {} // solhint-disable-line no-empty-blocks

    /**
     * @dev Validates swap signature
     *
     * The function fails if swap signature is not valid for any reason
     */
    function validateSwapSignature(Swap calldata swap_, bytes calldata swapSignature_) public view {
        require(swap_.steps.length > 0, "SV: swap has no steps");

        bytes32 swapHash = _hashSwap(swap_);
        bytes32 hash = _hashTypedDataV4D(swapHash, swap_.steps[0].chain, swap_.steps[0].swapper);
        address signer = ECDSA.recover(hash, swapSignature_);
        require(signer == swap_.steps[0].account, "SV: invalid swap signature");
    }

    function validateStealthSwapStepSignature(
        SwapStep calldata swapStep_,
        StealthSwap calldata stealthSwap_,
        bytes calldata stealthSwapSignature_
    ) public view returns (uint256 stepIndex) {
        bytes32 swapHash = _hashStealthSwap(stealthSwap_);
        bytes32 hash = _hashTypedDataV4D(swapHash, stealthSwap_.chain, stealthSwap_.swapper);
        address signer = ECDSA.recover(hash, stealthSwapSignature_);
        require(signer == stealthSwap_.account, "SV: invalid s-swap signature");

        return findStealthSwapStepIndex(swapStep_, stealthSwap_);
    }

    function findStealthSwapStepIndex(
        SwapStep calldata swapStep_,
        StealthSwap calldata stealthSwap_
    ) public pure returns (uint256 stepIndex) {
        bytes32 stepHash = _hashSwapStep(swapStep_);
        for (uint256 i = 0; i < stealthSwap_.stepHashes.length; i++) {
            if (stealthSwap_.stepHashes[i] == stepHash) {
                return i;
            }
        }
        revert("SV: no step hash match in s-swap");
    }

    function _hashSwap(Swap calldata swap_) private pure returns (bytes32 swapHash) {
        // prettier-ignore
        swapHash = keccak256(abi.encode(
            SWAP_TYPE_HASH,
            _hashSwapSteps(swap_.steps)
        ));
    }

    function _hashSwapSteps(SwapStep[] calldata swapSteps_) private pure returns (bytes32 swapStepsHash) {
        bytes memory bytesToHash = new bytes(swapSteps_.length << 5); // * 0x20
        uint256 offset;
        assembly {
            offset := add(bytesToHash, 0x20)
        }
        for (uint256 i = 0; i < swapSteps_.length; i++) {
            bytes32 hash = _hashSwapStep(swapSteps_[i]);
            assembly {
                mstore(offset, hash)
                offset := add(offset, 0x20)
            }
        }
        swapStepsHash = keccak256(bytesToHash);
    }

    function _hashSwapStep(SwapStep calldata swapStep_) private pure returns (bytes32 swapStepHash) {
        // prettier-ignore
        swapStepHash = keccak256(abi.encode(
            SWAP_STEP_TYPE_HASH,
            swapStep_.chain,
            swapStep_.swapper,
            swapStep_.account,
            swapStep_.useDelegate,
            swapStep_.nonce,
            swapStep_.deadline,
            _hashTokenChecks(swapStep_.ins),
            _hashTokenChecks(swapStep_.outs),
            _hashTokenUses(swapStep_.uses)
        ));
    }

    function _hashTokenChecks(TokenCheck[] calldata tokenChecks_) private pure returns (bytes32 tokenChecksHash) {
        bytes memory bytesToHash = new bytes(tokenChecks_.length << 5); // * 0x20
        uint256 offset;
        assembly {
            offset := add(bytesToHash, 0x20)
        }
        for (uint256 i = 0; i < tokenChecks_.length; i++) {
            bytes32 hash = _hashTokenCheck(tokenChecks_[i]);
            assembly {
                mstore(offset, hash)
                offset := add(offset, 0x20)
            }
        }
        tokenChecksHash = keccak256(bytesToHash);
    }

    function _hashTokenCheck(TokenCheck calldata tokenCheck_) private pure returns (bytes32 tokenCheckHash) {
        // prettier-ignore
        tokenCheckHash = keccak256(abi.encode(
            TOKEN_CHECK_TYPE_HASH,
            tokenCheck_.token,
            tokenCheck_.minAmount,
            tokenCheck_.maxAmount
        ));
    }

    function _hashTokenUses(TokenUse[] calldata tokenUses_) private pure returns (bytes32 tokenUsesHash) {
        bytes memory bytesToHash = new bytes(tokenUses_.length << 5); // * 0x20
        uint256 offset;
        assembly {
            offset := add(bytesToHash, 0x20)
        }
        for (uint256 i = 0; i < tokenUses_.length; i++) {
            bytes32 hash = _hashTokenUse(tokenUses_[i]);
            assembly {
                mstore(offset, hash)
                offset := add(offset, 0x20)
            }
        }
        tokenUsesHash = keccak256(bytesToHash);
    }

    function _hashTokenUse(TokenUse calldata tokenUse_) private pure returns (bytes32 tokenUseHash) {
        // prettier-ignore
        tokenUseHash = keccak256(abi.encode(
            TOKEN_USE_TYPE_HASH,
            tokenUse_.protocol,
            tokenUse_.chain,
            tokenUse_.account,
            _hashUint256Array(tokenUse_.inIndices),
            _hashTokenChecks(tokenUse_.outs),
            _hashBytes(tokenUse_.args)
        ));
    }

    function _hashStealthSwap(StealthSwap calldata stealthSwap_) private pure returns (bytes32 stealthSwapHash) {
        bytes32 stepsHash = _hashBytes32Array(stealthSwap_.stepHashes);

        stealthSwapHash = keccak256(
            abi.encode(
                STEALTH_SWAP_TYPE_HASH,
                stealthSwap_.chain,
                stealthSwap_.swapper,
                stealthSwap_.account,
                stepsHash
            )
        );
    }

    function _hashBytes(bytes calldata bytes_) private pure returns (bytes32 bytesHash) {
        bytesHash = keccak256(bytes_);
    }

    function _hashBytes32Array(bytes32[] calldata array_) private pure returns (bytes32 arrayHash) {
        arrayHash = keccak256(abi.encodePacked(array_));
    }

    function _hashUint256Array(uint256[] calldata array_) private pure returns (bytes32 arrayHash) {
        arrayHash = keccak256(abi.encodePacked(array_));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

/**
 * @dev Reflects types from "./Swap.sol"
 */

// prettier-ignore
string constant _TOKEN_CHECK_TYPE =
    "TokenCheck("
        "address token,"
        "uint256 minAmount,"
        "uint256 maxAmount"
    ")";

// prettier-ignore
string constant _TOKEN_USE_TYPE =
    "TokenUse("
        "address protocol,"
        "uint256 chain,"
        "address account,"
        "uint256[] inIndices,"
        "TokenCheck[] outs,"
        "bytes args"
    ")";

// prettier-ignore
string constant _SWAP_STEP_TYPE =
    "SwapStep("
        "uint256 chain,"
        "address swapper,"
        "address account,"
        "bool useDelegate,"
        "uint256 nonce,"
        "uint256 deadline,"
        "TokenCheck[] ins,"
        "TokenCheck[] outs,"
        "TokenUse[] uses"
    ")";

// prettier-ignore
string constant _SWAP_TYPE =
    "Swap("
        "SwapStep[] steps"
    ")";

// prettier-ignore
string constant _STEALTH_SWAP_TYPE =
    "StealthSwap("
        "uint256 chain,"
        "address swapper,"
        "address account,"
        "bytes32[] stepHashes"
    ")";

/**
 * @dev Hashes of the types above
 *
 * Remember that:
 * - Main hashed type goes first
 * - Subtypes go next in alphabetical order (specified in EIP-712)
 */

// prettier-ignore
bytes32 constant _TOKEN_CHECK_TYPE_HASH = keccak256(abi.encodePacked(
    _TOKEN_CHECK_TYPE
));

// prettier-ignore
bytes32 constant _TOKEN_USE_TYPE_HASH = keccak256(abi.encodePacked(
    _TOKEN_USE_TYPE,
    _TOKEN_CHECK_TYPE
));

// prettier-ignore
bytes32 constant _SWAP_STEP_TYPE_HASH = keccak256(abi.encodePacked(
    _SWAP_STEP_TYPE,
    _TOKEN_CHECK_TYPE,
    _TOKEN_USE_TYPE
));

// prettier-ignore
bytes32 constant _SWAP_TYPE_HASH = keccak256(abi.encodePacked(
    _SWAP_TYPE,
    _SWAP_STEP_TYPE,
    _TOKEN_CHECK_TYPE,
    _TOKEN_USE_TYPE
));

// prettier-ignore
bytes32 constant _STEALTH_SWAP_TYPE_HASH = keccak256(abi.encodePacked(
    _STEALTH_SWAP_TYPE
));

/**
 * @dev Hash values pre-calculated w/ `tools/hash` to reduce contract size
 */

// bytes32 constant TOKEN_CHECK_TYPE_HASH = _TOKEN_CHECK_TYPE_HASH;
bytes32 constant TOKEN_CHECK_TYPE_HASH = 0x382391664c9ae06333b02668b6d763ab547bd70c71636e236fdafaacf1e55bdd;

// bytes32 constant TOKEN_USE_TYPE_HASH = _TOKEN_USE_TYPE_HASH;
bytes32 constant TOKEN_USE_TYPE_HASH = 0x192f17c5e66907915b200bca0d866184770ff7faf25a0b4ccd2ef26ebd21725a;

// bytes32 constant SWAP_STEP_TYPE_HASH = _SWAP_STEP_TYPE_HASH;
bytes32 constant SWAP_STEP_TYPE_HASH = 0x973db6284d4ead3ce5e0ee0d446a483b1b5ff8cd93a2b86dbd0a9f03a6cefc8a;

// bytes32 constant SWAP_TYPE_HASH = _SWAP_TYPE_HASH;
bytes32 constant SWAP_TYPE_HASH = 0xba1e9d0b1bee57631ad5f99eac149c1229822508d3dfc4f8fa2c5089bb99c874;

// bytes32 constant STEALTH_SWAP_TYPE_HASH = _STEALTH_SWAP_TYPE_HASH;
bytes32 constant STEALTH_SWAP_TYPE_HASH = 0x0f2b1c8dae54aa1b96d626d678ec60a7c6d113b80ccaf635737a6f003d1cbaf5;

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

/**
 * @dev xSwap fork of the original OpenZeppelin's {EIP712} implementation
 *
 * The fork allows typed data hashing with arbitrary chainId & verifyingContract for domain separator
 */

pragma solidity ^0.8.16;

import "./ECDSA.sol";

abstract contract EIP712D {
    /* solhint-disable var-name-mixedcase */

    // bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant _TYPE_HASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    bytes32 private immutable _NAME_HASH;
    bytes32 private immutable _VERSION_HASH;

    /* solhint-enable var-name-mixedcase */

    constructor(string memory name, string memory version) {
        _NAME_HASH = keccak256(bytes(name));
        _VERSION_HASH = keccak256(bytes(version));
    }

    function _domainSeparatorV4D(uint256 chainId, address verifyingContract) internal view returns (bytes32) {
        return keccak256(abi.encode(_TYPE_HASH, _NAME_HASH, _VERSION_HASH, chainId, verifyingContract));
    }

    function _hashTypedDataV4D(
        bytes32 structHash,
        uint256 chainId,
        address verifyingContract
    ) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4D(chainId, verifyingContract), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {ECDSA} implementation:
 * - bump `pragma solidity` (`^0.8.0` -> `^0.8.16`)
 * - adjust OpenZeppelin's {Strings} import (use `library` implementation)
 * - shortify `require` messages (`ECDSA:` -> `EC:`)
 * - extract `decompress(bytes32 vs)` private function from `tryRecover(bytes32 hash, bytes32 r, bytes32 vs)`
 * - extract `tryDecompose(bytes memory signature)` private function from `tryRecover(bytes32 hash, bytes memory signature)`
 */

pragma solidity ^0.8.16;

import "./Strings.sol";

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
            revert("EC: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("EC: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("EC: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("EC: invalid signature 'v' value");
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
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address signer, RecoverError err) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        (r, s, v, err) = tryDecompose(signature);
        if (err == RecoverError.NoError) {
            (signer, err) = tryRecover(hash, v, r, s);
        }
    }

    /**
     * @dev Extracted from {ECDSA-tryRecover} (bytes32 hash, bytes memory signature) for xSwap needs
     */
    function tryDecompose(
        bytes memory signature
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v, RecoverError err) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            (s, v) = decompress(vs);
        } else {
            err = RecoverError.InvalidSignatureLength;
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
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        (bytes32 s, uint8 v) = decompress(vs);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Extracted from {ECDSA-tryRecover} (bytes32 hash, bytes32 r, bytes32 vs) for xSwap needs
     */
    function decompress(bytes32 vs) private pure returns (bytes32 s, uint8 v) {
        s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        v = uint8((uint256(vs) >> 255) + 27);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
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
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
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
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

/**
 * @dev xSwap modifications of original OpenZeppelin's {Strings} implementation:
 * - bump `pragma solidity` (`^0.8.0` -> `^0.8.16`)
 */

pragma solidity ^0.8.16;

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
/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// SPDX-License-Identifier: MIT

/**
 * .----------------.  .----------------.  .----------------.  .----------------.  .----------------. 
 * | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
 * | |  ____  ____  | || |  _________   | || |   _____      | || |     _____    | || |  ____  ____  | |
 * | | |_   ||   _| | || | |_   ___  |  | || |  |_   _|     | || |    |_   _|   | || | |_  _||_  _| | |
 * | |   | |__| |   | || |   | |_  \_|  | || |    | |       | || |      | |     | || |   \ \  / /   | |
 * | |   |  __  |   | || |   |  _|  _   | || |    | |   _   | || |      | |     | || |    > `' <    | |
 * | |  _| |  | |_  | || |  _| |___/ |  | || |   _| |__/ |  | || |     _| |_    | || |  _/ /'`\ \_  | |
 * | | |____||____| | || | |_________|  | || |  |________|  | || |    |_____|   | || | |____||____| | |
 * | |              | || |              | || |              | || |              | || |              | |
 * | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
 *  '----------------'  '----------------'  '----------------'  '----------------'  '----------------' '
 * 
 * https://helixbridge.app/
 *
 * 9/27/2022
 **/

pragma solidity ^0.8.10;

// File @zeppelin-solidity-4.4.0/contracts/utils/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)


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

// File @zeppelin-solidity-4.4.0/contracts/utils/cryptography/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)


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

// File contracts/mapping-token/v2/GuardRegistry.sol
// License-Identifier: Apache-2.0

pragma experimental ABIEncoderV2;

/**
 * @title Manages a set of guards and a threshold to double-check BEEFY commitment
 * @dev Stores the guards and a threshold
 * @author echo
 */
contract GuardRegistry {
    event AddedGuard(address guard);
    event RemovedGuard(address guard);
    event ChangedThreshold(uint256 threshold);

    // keccak256(
    //     "EIP712Domain(uint256 chainId,address verifyingContract)"
    // );
    bytes32 internal constant DOMAIN_SEPARATOR_TYPEHASH = 0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218;

    address internal constant SENTINEL_GUARDS = address(0x1);

    /**
     * @dev Nonce to prevent replay of update operations
     */
    uint256 public nonce;
    /**
     * @dev Store all guards in the linked list
     */
    mapping(address => address) internal guards;
    /**
     * @dev Count of all guards
     */
    uint256 internal guardCount;
    /**
     * @dev Number of required confirmations for update operations
     */
    uint256 internal threshold;

    /**
     * @dev Sets initial storage of contract.
     * @param _guards List of Safe guards.
     * @param _threshold Number of required confirmations for check commitment or change guards.
     */
    function initialize(address[] memory _guards, uint256 _threshold) internal {
        // Threshold can only be 0 at initialization.
        // Check ensures that setup function can only be called once.
        require(threshold == 0, "Guard: Guards have already been setup");
        // Validate that threshold is smaller than number of added guards.
        require(_threshold <= _guards.length, "Guard: Threshold cannot exceed guard count");
        // There has to be at least one Safe guard.
        require(_threshold >= 1, "Guard: Threshold needs to be greater than 0");
        // Initializing Safe guards.
        address currentGuard = SENTINEL_GUARDS;
        for (uint256 i = 0; i < _guards.length; i++) {
            // Guard address cannot be null.
            address guard = _guards[i];
            require(guard != address(0) && guard != SENTINEL_GUARDS && guard != address(this) && currentGuard != guard, "Guard: Invalid guard address provided");
            // No duplicate guards allowed.
            require(guards[guard] == address(0), "Guard: Address is already an guard");
            guards[currentGuard] = guard;
            currentGuard = guard;
            emit AddedGuard(guard);
        }
        guards[currentGuard] = SENTINEL_GUARDS;
        guardCount = _guards.length;
        threshold = _threshold;
    }

    /**
     * @dev Allows to add a new guard to the registry and update the threshold at the same time.
     *      This can only be done via multi-sig.
     * @notice Adds the guard `guard` to the registry and updates the threshold to `_threshold`.
     * @param guard New guard address.
     * @param _threshold New threshold.
     * @param signatures The signatures of the guards which to add new guard and update the `threshold` .
     */
    function addGuardWithThreshold(
        address guard,
        uint256 _threshold,
        bytes[] memory signatures
    ) public {
        // Guard address cannot be null, the sentinel or the registry itself.
        require(guard != address(0) && guard != SENTINEL_GUARDS && guard != address(this), "Guard: Invalid guard address provided");
        // No duplicate guards allowed.
        require(guards[guard] == address(0), "Guard: Address is already an guard");
        verifyGuardSignatures(msg.sig, abi.encode(guard, _threshold), signatures);
        guards[guard] = guards[SENTINEL_GUARDS];
        guards[SENTINEL_GUARDS] = guard;
        guardCount++;
        emit AddedGuard(guard);
        // Change threshold if threshold was changed.
        if (threshold != _threshold) _changeThreshold(_threshold);
    }

    /**
     * @dev Allows to remove an guard from the registry and update the threshold at the same time.
     *      This can only be done via multi-sig.
     * @notice Removes the guard `guard` from the registry and updates the threshold to `_threshold`.
     * @param prevGuard Guard that pointed to the guard to be removed in the linked list
     * @param guard Guard address to be removed.
     * @param _threshold New threshold.
     * @param signatures The signatures of the guards which to remove a guard and update the `threshold` .
     */
    function removeGuard(
        address prevGuard,
        address guard,
        uint256 _threshold,
        bytes[] memory signatures
    ) public {
        // Only allow to remove an guard, if threshold can still be reached.
        require(guardCount - 1 >= _threshold, "Guard: Threshold cannot exceed guard count");
        // Validate guard address and check that it corresponds to guard index.
        require(guard != address(0) && guard != SENTINEL_GUARDS, "Guard: Invalid guard address provided");
        require(guards[prevGuard] == guard, "Guard: Invalid prevGuard, guard pair provided");
        verifyGuardSignatures(msg.sig, abi.encode(prevGuard, guard, _threshold), signatures);
        guards[prevGuard] = guards[guard];
        guards[guard] = address(0);
        guardCount--;
        emit RemovedGuard(guard);
        // Change threshold if threshold was changed.
        if (threshold != _threshold) _changeThreshold(_threshold);
    }

    /**
     * @dev Allows to swap/replace a guard from the registry with another address.
     *      This can only be done via multi-sig.
     * @notice Replaces the guard `oldGuard` in the registry with `newGuard`.
     * @param prevGuard guard that pointed to the guard to be replaced in the linked list
     * @param oldGuard guard address to be replaced.
     * @param newGuard New guard address.
     * @param signatures The signatures of the guards which to swap/replace a guard and update the `threshold` .
     */
    function swapGuard(
        address prevGuard,
        address oldGuard,
        address newGuard,
        bytes[] memory signatures
    ) public {
        // Guard address cannot be null, the sentinel or the registry itself.
        require(newGuard != address(0) && newGuard != SENTINEL_GUARDS && newGuard != address(this), "Guard: Invalid guard address provided");
        // No duplicate guards allowed.
        require(guards[newGuard] == address(0), "Guard: Address is already an guard");
        // Validate oldGuard address and check that it corresponds to guard index.
        require(oldGuard != address(0) && oldGuard != SENTINEL_GUARDS, "Guard: Invalid guard address provided");
        require(guards[prevGuard] == oldGuard, "Guard: Invalid prevGuard, guard pair provided");
        verifyGuardSignatures(msg.sig, abi.encode(prevGuard, oldGuard, newGuard), signatures);
        guards[newGuard] = guards[oldGuard];
        guards[prevGuard] = newGuard;
        guards[oldGuard] = address(0);
        emit RemovedGuard(oldGuard);
        emit AddedGuard(newGuard);
    }

    /**
     * @dev Allows to update the number of required confirmations by guards.
     *      This can only be done via multi-sig.
     * @notice Changes the threshold of the registry to `_threshold`.
     * @param _threshold New threshold.
     * @param signatures The signatures of the guards which to update the `threshold` .
     */
    function changeThreshold(uint256 _threshold, bytes[] memory signatures) public {
        verifyGuardSignatures(msg.sig, abi.encode(_threshold), signatures);
        _changeThreshold(_threshold);
    }

    function _changeThreshold(uint256 _threshold) internal {
        // Validate that threshold is smaller than number of owners.
        require(_threshold <= guardCount, "Guard: Threshold cannot exceed guard count");
        // There has to be at least one guard.
        require(_threshold >= 1, "Guard: Threshold needs to be greater than 0");
        threshold = _threshold;
        emit ChangedThreshold(threshold);
    }

    function getThreshold() public view returns (uint256) {
        return threshold;
    }

    function isGuard(address guard) public view returns (bool) {
        return guard != SENTINEL_GUARDS && guards[guard] != address(0);
    }

    /**
     * @dev Returns array of guards.
     * @return Array of guards.
     */
    function getGuards() public view returns (address[] memory) {
        address[] memory array = new address[](guardCount);

        // populate return array
        uint256 index = 0;
        address currentGuard = guards[SENTINEL_GUARDS];
        while (currentGuard != SENTINEL_GUARDS) {
            array[index] = currentGuard;
            currentGuard = guards[currentGuard];
            index++;
        }
        return array;
    }

    function verifyGuardSignatures(
        bytes4 methodID,
        bytes memory params,
        bytes[] memory signatures
    ) internal {
        bytes32 structHash =
            keccak256(
                abi.encode(
                    methodID,
                    params,
                    nonce
                )
            );
        checkGuardSignatures(structHash, signatures);
        nonce++;
    }

    function verifyGuardSignaturesWithoutNonce(
        bytes4 methodID,
        bytes memory params,
        bytes[] memory signatures
    ) view internal {
        bytes32 structHash =
            keccak256(
                abi.encode(
                    methodID,
                    params
                )
            );
        checkGuardSignatures(structHash, signatures);
    }

    /**
     * @dev Checks whether the signature provided is valid for the provided data, hash. Will revert otherwise.
     * @param structHash The struct Hash of the data (could be either a message/commitment hash).
     * @param signatures Signature data that should be verified. only ECDSA signature.
     * Signers need to be sorted in ascending order
     */
    function checkGuardSignatures(
        bytes32 structHash,
        bytes[] memory signatures
    ) public view {
        // Load threshold to avoid multiple storage loads
        uint256 _threshold = threshold;
        // Check that a threshold is set
        require(_threshold > 0, "Guard: Threshold needs to be defined");
        bytes32 dataHash = encodeDataHash(structHash);
        checkNSignatures(dataHash, signatures, _threshold);
    }

    /**
     * @dev Checks whether the signature provided is valid for the provided data, hash. Will revert otherwise.
     * @param dataHash Hash of the data (could be either a message hash or transaction hash).
     * @param signatures Signature data that should be verified. only ECDSA signature.
     * Signers need to be sorted in ascending order
     * @param requiredSignatures Amount of required valid signatures.
     */
    function checkNSignatures(
        bytes32 dataHash,
        bytes[] memory signatures,
        uint256 requiredSignatures
    ) public view {
        // Check that the provided signature data is not too short
        require(signatures.length >= requiredSignatures, "GS020");
        // There cannot be an owner with address 0.
        address lastGuard = address(0);
        address currentGuard;
        for (uint256 i = 0; i < requiredSignatures; i++) {
            currentGuard = ECDSA.recover(dataHash, signatures[i]);
            require(currentGuard > lastGuard && guards[currentGuard] != address(0) && currentGuard != SENTINEL_GUARDS, "Guard: Invalid guard provided");
            lastGuard = currentGuard;
        }
    }

    /**
     * @dev Returns the chain id used by this contract.
     */
    function getChainId() public view returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }

    function domainSeparator() public view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, getChainId(), address(this)));
    }

    function encodeDataHash(bytes32 structHash) public view returns (bytes32) {
        return keccak256(abi.encodePacked(hex"1901", domainSeparator(), structHash));
    }
}

// File contracts/mapping-token/interfaces/IWToken.sol
// License-Identifier: MIT


interface IWToken {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

// File @zeppelin-solidity-4.4.0/contracts/utils/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)


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

// File @zeppelin-solidity-4.4.0/contracts/security/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)


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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// File @zeppelin-solidity-4.4.0/contracts/token/ERC20/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)


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

// File @zeppelin-solidity-4.4.0/contracts/utils/math/[email protected]
// License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)


// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File contracts/mapping-token/v2/Guard.sol
// License-Identifier: Apache-2.0






contract Guard is GuardRegistry, Pausable {
    using SafeMath for uint256;

    mapping(uint256 => bytes32) depositors;

    uint256 public maxUnclaimableTime;
    address public depositor;
    address public operator;

    event TokenDeposit(uint256 id, address token, address recipient, uint256 amount);
    event TokenClaimed(uint256 id);

    constructor(address[] memory _guards, uint256 _threshold, uint256 _maxUnclaimableTime, address _depositor) {
        maxUnclaimableTime = _maxUnclaimableTime;
        depositor = _depositor;
        operator = msg.sender;
        initialize(_guards, _threshold);
    }

    modifier onlyDepositor() {
        require(msg.sender == depositor, "Guard: Invalid depositor");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "Guard: Invalid operator");
        _;
    }

    function unpause() external onlyOperator {
        _unpause();
    }

    function pause() external onlyOperator {
        _pause();
    }

    function setOperator(address newOperator, bytes[] memory signatures) external {
        verifyGuardSignatures(msg.sig, abi.encode(newOperator), signatures);
        operator = newOperator;
    }

    function setMaxUnclaimableTime(uint256 _maxUnclaimableTime) external onlyOperator {
        maxUnclaimableTime = _maxUnclaimableTime;
    }

    /**
      * @dev deposit token to guard, waiting to claim, only allowed depositor
      * @param id the id of the operation, should be siged later by guards
      * @param token the erc20 token address
      * @param recipient the recipient of the token
      * @param amount the amount of the token
      */
    function deposit(
        uint256 id,
        address token,
        address recipient,
        uint256 amount
    ) public onlyDepositor whenNotPaused {
        depositors[id] = hash(abi.encodePacked(block.timestamp, token, recipient, amount));
        emit TokenDeposit(id, token, recipient, amount);
    }

    function claimById(
        uint256 id,
        uint256 timestamp,
        address token,
        address recipient,
        uint256 amount,
        bool isNative
    ) internal {
        require(hash(abi.encodePacked(timestamp, token, recipient, amount)) == depositors[id], "Guard: Invalid id to claim");
        require(amount > 0, "Guard: Invalid amount to claim");
        if (isNative) {
            require(IERC20(token).transferFrom(depositor, address(this), amount), "Guard: claim native token failed");
            uint256 balanceBefore = address(this).balance;
            IWToken(token).withdraw(amount);
            require(address(this).balance == balanceBefore.add(amount), "Guard: token is not wrapped by native token");
            payable(recipient).transfer(amount);
        } else {
            require(IERC20(token).transferFrom(depositor, recipient, amount), "Guard: claim token failed");
        }
        delete depositors[id];
        emit TokenClaimed(id);
    }

    /**
      * @dev claim the tokens in the contract saved by deposit, this acquire signatures from guards
      * @param id the id to be claimed
      * @param signatures the signatures of the guards which to claim tokens.
      */
    function claim(
        uint256 id,
        uint256 timestamp,
        address token,
        address recipient,
        uint256 amount,
        bytes[] memory signatures
    ) public {
        verifyGuardSignaturesWithoutNonce(msg.sig, abi.encode(id, timestamp, token, recipient, amount), signatures);
        claimById(id, timestamp, token, recipient, amount, false);
    }

    /**
      * @dev claimNative the tokens in the contract saved by deposit, this acquire signatures from guards
      * @param id the id to be claimed
      * @param signatures the signatures of the guards which to claim tokens.
      */
    function claimNative(
        uint256 id,
        uint256 timestamp,
        address token,
        address recipient,
        uint256 amount,
        bytes[] memory signatures
    ) public {
        verifyGuardSignaturesWithoutNonce(msg.sig, abi.encode(id, timestamp, token, recipient, amount), signatures);
        claimById(id, timestamp, token, recipient, amount, true);
    }

    /**
      * @dev claim the tokens without signatures, this only allowed when timeout
      * @param id the id to be claimed
      */
    function claimByTimeout(
        uint256 id,
        uint256 timestamp,
        address token,
        address recipient,
        uint256 amount,
        bool isNative
    ) public whenNotPaused {
        require(timestamp < block.timestamp && block.timestamp - timestamp > maxUnclaimableTime, "Guard: claim at invalid time");
        claimById(id, timestamp, token, recipient, amount, isNative);
    }

    function hash(bytes memory value) public pure returns (bytes32) {
        return sha256(value);
    }
}
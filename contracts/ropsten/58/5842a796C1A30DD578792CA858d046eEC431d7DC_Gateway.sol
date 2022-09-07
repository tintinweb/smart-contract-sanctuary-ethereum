// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
// import "hardhat/console.sol";

error InvalidValsetNonce(uint256 newNonce, uint256 currentNonce);
error IncorrectCheckpoint();
error MalformedNewValidatorSet();
error MalformedCurrentValidatorSet();
error InsufficientPower(uint256 cumulativePower, uint256 powerThreshold);

// This is used purely to avoid stack too deep errors
// represents everything about a given validator set
struct ValsetArgs {
    // the validators in this set, represented by an Ethereum address
    address[] validators;
    // the powers of the given validators in the same order as above
    uint256[] powers;
    // the nonce of this validator set
    uint256 valsetNonce;
}

// This is being used purely to avoid stack too deep errors
struct RouterRequestPayload {
    // the sender address
    string sender;
    string chainId;
    uint256 chainType;
    uint256 relayerFee;
    uint256 outgoingTxFee;
    bool isAtomic;
    uint64 expTimestamp;
    // The user contract address
    bytes[] handlers;
    bytes[] payloads;
    uint256 nonce;
}

// This represents a validator signature
struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

contract Gateway is ReentrancyGuard {
    error InvalidSignature();
    // constants
    string private constant MSG_PREFIX = "\x19Ethereum Signed Message:\n32";
    // The number of 'votes' required to execute a valset
    // update or batch execution, set to 2/3 of 2^32
    uint256 constant constantPowerThreshold = 2863311530;

    // states
    // chain id
    string public chainId;
    // chain Type
    uint256 public chainType;
    // nonce for requestToRouter Messages
    uint256 public eventNonce;
    // last validated ValSet Checkpoint
    bytes32 public stateLastValsetCheckpoint;

    uint256 public stateLastValsetNonce = 0;

    mapping(string => mapping(uint256 => uint8)) public outboundNonceMapping;

    event SendToRouterEvent(
        address indexed _sender,
        string routerBridgeContract,
        bytes payload,
        uint256 _eventNonce,
        string chainId,
        uint256 chainType
    );
    event RequestFromRouterEvent(address indexed _handlerContract, bytes32 messageHash, bool success);
    event ValsetUpdatedEvent(uint256 indexed _newValsetNonce, address[] _validators, uint256[] _powers);

    // This is OutBound Request Acknowledgement event
    event EventOutboundAck(
        uint256 ChainType,        
        string  ChainId,                 
        uint256 OutboundTxNonce,                 
        bytes   contractAckResponses,
        uint8   exeCode,
        bool    status
    );
    // Utility function to verify geth style signatures
    function verifySig(
        address _signer,
        bytes32 _messageDigest,
        Signature calldata _sig
    ) private pure returns (bool) {
        return _signer == ECDSA.recover(_messageDigest, _sig.v, _sig.r, _sig.s);
    }

    // Utility function to determine that a validator set and signatures are well formed
    function validateValset(ValsetArgs calldata _valset, Signature[] calldata _sigs) private pure {
        // Check that current validators, powers, and signatures (v,r,s) set is well-formed
        if (_valset.validators.length != _valset.powers.length || _valset.validators.length != _sigs.length) {
            revert MalformedCurrentValidatorSet();
        }
    }

    // Make a new checkpoint from the supplied validator set
    // A checkpoint is a hash of all relevant information about the valset. This is stored by the contract,
    // instead of storing the information directly. This saves on storage and gas.
    // The format of the checkpoint is:
    // h(_chainId, "checkpoint", valsetNonce, validators[], powers[])
    // Where h is the keccak256 hash function.
    // The validator powers must be decreasing or equal. This is important for checking the signatures on the
    // next valset, since it allows the caller to stop verifying signatures once a quorum of signatures have been verified.
    function makeCheckpoint(ValsetArgs memory _valsetArgs, string memory _chainId) private pure returns (bytes32) {
        // bytes32 encoding of the string "checkpoint"
        bytes32 methodName = 0x636865636b706f696e7400000000000000000000000000000000000000000000;

        bytes32 checkpoint = keccak256(
            abi.encode(_chainId, methodName, _valsetArgs.valsetNonce, _valsetArgs.validators, _valsetArgs.powers)
        );

        return checkpoint;
    }

    function checkValidatorSignatures(
        // The current validator set and their powers
        ValsetArgs calldata _currentValset,
        // The current validator's signatures
        Signature[] calldata _sigs,
        // This is what we are checking they have signed
        bytes32 _theHash,
        uint256 _powerThreshold
    ) private pure {
        uint256 cumulativePower = 0;

        for (uint256 i = 0; i < _currentValset.validators.length; i++) {
            // If v is set to 0, this signifies that it was not possible to get a signature
            // from this validator and we skip evaluation
            // (In a valid signature, it is either 27 or 28)
            if (_sigs[i].v != 0) {
                // Check that the current validator has signed off on the hash
                if (!verifySig(_currentValset.validators[i], _theHash, _sigs[i])) {
                    revert InvalidSignature();
                }

                // Sum up cumulative power
                cumulativePower = cumulativePower + _currentValset.powers[i];

                // Break early to avoid wasting gas
                if (cumulativePower > _powerThreshold) {
                    break;
                }
            }
        }

        // Check that there was enough power
        if (cumulativePower <= _powerThreshold) {
            revert InsufficientPower(cumulativePower, _powerThreshold);
        }
        // Success
    }

    // This updates the valset by checking that the validators in the current valset have signed off on the
    // new valset. The signatures supplied are the signatures of the current valset over the checkpoint hash
    // generated from the new valset.
    // Anyone can call this function, but they must supply valid signatures of constantPowerThreshold of the current valset over
    // the new valset.
    function updateValset(
        // The new version of the validator set
        ValsetArgs calldata _newValset,
        // The current validators that approve the change
        ValsetArgs calldata _currentValset,
        // These are arrays of the parts of the current validator's signatures
        Signature[] calldata _sigs
    ) external {
        // CHECKS

        // Check that the valset nonce is greater than the old one
        if (_newValset.valsetNonce <= _currentValset.valsetNonce) {
            revert InvalidValsetNonce({ newNonce: _newValset.valsetNonce, currentNonce: _currentValset.valsetNonce });
        }

        // Check that the valset nonce is less than a million nonces forward from the old one
        // this makes it difficult for an attacker to lock out the contract by getting a single
        // bad validator set through with uint256 max nonce
        if (_newValset.valsetNonce > _currentValset.valsetNonce + 1000000) {
            revert InvalidValsetNonce({ newNonce: _newValset.valsetNonce, currentNonce: _currentValset.valsetNonce });
        }

        // Check that new validators and powers set is well-formed
        if (_newValset.validators.length != _newValset.powers.length || _newValset.validators.length == 0) {
            revert MalformedNewValidatorSet();
        }

        // Check that current validators, powers, and signatures (v,r,s) set is well-formed
        validateValset(_currentValset, _sigs);

        // Check cumulative power to ensure the contract has sufficient power to actually
        // pass a vote
        uint256 cumulativePower = 0;
        for (uint256 i = 0; i < _newValset.powers.length; i++) {
            cumulativePower = cumulativePower + _newValset.powers[i];
            if (cumulativePower > constantPowerThreshold) {
                break;
            }
        }
        if (cumulativePower <= constantPowerThreshold) {
            revert InsufficientPower({ cumulativePower: cumulativePower, powerThreshold: constantPowerThreshold });
        }

        // Check that the supplied current validator set matches the saved checkpoint
        if (makeCheckpoint(_currentValset, chainId) != stateLastValsetCheckpoint) {
            revert IncorrectCheckpoint();
        }

        // Check that enough current validators have signed off on the new validator set
        bytes32 newCheckpoint = makeCheckpoint(_newValset, chainId);
        bytes32 digest = _make_digest(newCheckpoint);
        checkValidatorSignatures(_currentValset, _sigs, digest, constantPowerThreshold);

        // ACTIONS

        // Stored to be used next time to validate that the valset
        // supplied by the caller is correct.
        stateLastValsetCheckpoint = newCheckpoint;

        // Store new nonce
        stateLastValsetNonce = _newValset.valsetNonce;

        emit ValsetUpdatedEvent(_newValset.valsetNonce, _newValset.validators, _newValset.powers);
    }

    constructor(
        string memory _chainId,
        uint256 _chainType,
        address[] memory _validators,
        uint256[] memory _powers
    ) {
        // CHECKS

        // Check that validators, powers, and signatures (v,r,s) set is well-formed
        if (_validators.length != _powers.length || _validators.length == 0) {
            revert MalformedCurrentValidatorSet();
        }

        // Check cumulative power to ensure the contract has sufficient power to actually
        // pass a vote
        // point -> if due to special order our set to
        uint256 cumulativePower = 0;
        for (uint256 i = 0; i < _powers.length; i++) {
            cumulativePower = cumulativePower + _powers[i];
            if (cumulativePower > constantPowerThreshold) {
                break;
            }
        }
        if (cumulativePower <= constantPowerThreshold) {
            revert InsufficientPower({ cumulativePower: cumulativePower, powerThreshold: constantPowerThreshold });
        }

        ValsetArgs memory _valset;
        _valset = ValsetArgs(_validators, _powers, 0);

        bytes32 newCheckpoint = makeCheckpoint(_valset, _chainId);

        // ACTIONS

        chainId = _chainId;
        chainType = _chainType;
        eventNonce = 0;
        stateLastValsetCheckpoint = newCheckpoint;

        emit ValsetUpdatedEvent(stateLastValsetNonce, _validators, _powers);
    }

    function requestToRouter(bytes memory payload, string memory routerBridgeContract) external {
        eventNonce++;
        emit SendToRouterEvent(msg.sender, routerBridgeContract, payload, eventNonce, chainId, chainType);
    }

    function _make_digest(bytes32 data) private pure returns (bytes32 _digest) {
        _digest = keccak256(abi.encodePacked(MSG_PREFIX, data));
    }

    function requestFromRouter(
        // The validators that approve the call
        ValsetArgs calldata _currentValset,
        // These are arrays of the parts of the validators signatures
        Signature[] calldata _sigs,
        RouterRequestPayload memory requestPayload
    ) external {
        // TODO: can store keccak256(abi.encodePacked(chainId)) as state at contract level
        require(
            keccak256(abi.encodePacked(chainId)) == keccak256(abi.encodePacked(requestPayload.chainId)),
            "Chain Id should match"
        );
        require(chainType == requestPayload.chainType, "Chain Type should match");
        require(
            outboundNonceMapping[requestPayload.sender][requestPayload.nonce] == 0,
            "request message already handled"
        );
        require(
            requestPayload.handlers.length == requestPayload.payloads.length,
            "handler array & payload array should have same length"
        );
        require(requestPayload.handlers.length != 0, "handler array should not have zero length");
        if (block.timestamp > requestPayload.expTimestamp) {
            outboundNonceMapping[requestPayload.sender][requestPayload.nonce] = 1;
			
            bytes memory emptyData = "";
            emit EventOutboundAck(
                chainType,        
                chainId,                 
                requestPayload.nonce,                 
                emptyData,
                3,
                false
            );
            return;
        }
        outboundNonceMapping[requestPayload.sender][requestPayload.nonce] = 1;

        // Check that current validators, powers, and signatures (v,r,s) set is well-formed
        validateValset(_currentValset, _sigs);

        // this will validate the checkpoint, thus verify the signers
        if (makeCheckpoint(_currentValset, chainId) != stateLastValsetCheckpoint) {
            revert IncorrectCheckpoint();
        }

        bytes memory encodedABI = abi.encode(
            // bytes32 encoding of "requestFromRouter"
            0x7265717565737446726f6d526f75746572000000000000000000000000000000,
            chainType,
            chainId,
            requestPayload.sender,
            requestPayload.nonce,
            requestPayload.relayerFee,
            requestPayload.outgoingTxFee,
            requestPayload.isAtomic,
            requestPayload.expTimestamp,
            requestPayload.handlers,
            requestPayload.payloads
        );

        bytes32 messagehash = keccak256(encodedABI);

        bytes32 digest = _make_digest(messagehash);
        checkValidatorSignatures(_currentValset, _sigs, digest, constantPowerThreshold);

        (bool success, bytes memory data) = address(this).call(
            abi.encodeWithSignature(
                "executeHandlerCalls(bytes[],bytes[],bool)",
                requestPayload.handlers,
                requestPayload.payloads,
                requestPayload.isAtomic
            )
        );
        emit EventOutboundAck(
            chainType,        
            chainId,                 
            requestPayload.nonce,                 
            data,
            0,
            success
        );
    }

    function executeHandlerCalls(
        bytes[] memory handlers,
        bytes[] memory payloads,
        bool isAtomic
    ) external returns (bool[] memory) {
        bool[] memory successFlags = new bool[](handlers.length);
        for (uint8 i = 0; i < handlers.length; i++) {
            address handler = toAddress(handlers[i]);
            (bool success, ) = address(handler).call(
                abi.encodeWithSignature("handleRequestFromRouter(bytes)", payloads[i])
            );
            successFlags[i] = success;
            if (isAtomic && !success) {
                bytes memory encodedData = abi.encodePacked(successFlags);
                // console.logBytes(encodedData);
                string memory returnString = string(encodedData);
                // console.logString(returnString);
                revert(returnString);
            }
        }
        return successFlags;
    }

    function toAddress(bytes memory _bytes) internal pure returns (address contractAddress) {
        contractAddress = abi.decode(_bytes, (address));
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

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

// SPDX-License-Identifier: MIT
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
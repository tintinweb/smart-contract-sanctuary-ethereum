// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IBridge.sol";

/// @title Root network bridge contract on ethereum
/// @author Root Network
/// @notice Provides methods for verifying messages from the validator set
contract Bridge is IBridge, IBridgeReceiver, Ownable, ReentrancyGuard, ERC165 {
    using ECDSA for bytes32;

    // map from validator set nonce to keccak256 digest of validator ECDSA addresses (i.e bridge session keys)
    // these should be encoded in sorted order matching `pallet_session::Module<T>::validators()` to create the digest
    // signatures from a threshold of these addresses are considered approved by the protocol
    mapping(uint => bytes32) public validatorSetDigests;
    // Nonce for validator set changes
    uint32 public activeValidatorSetId;
    // Nonce of the next outgoing event
    uint public sentEventId;
    // Map of verified incoming event nonces
    // will only validate one event per nonce.
    // Verification/submission out of order is ok.
    mapping(uint => bool) public verifiedEventIds;
    // Fee for message verification
    // Offsets bridge upkeep costs i.e updating the validator set
    uint public bridgeFee = 4e15; // 0.004 ether
    // Acceptance threshold in %
    uint public thresholdPercent = 60;
    // Number of staking eras before a bridge message will be considered expired
    uint public proofTTL = 7;
    // Whether the bridge is active or not
    bool public active = false;
    // Max reward paid out to successful caller of `setValidator`
    uint public maxRewardPayout = 1 ether;
    // The bridge pallet (pseudo) address this contract is paired with
    address public palletAddress =
        address(0x6D6f646C65746879627264670000000000000000);
    // Max message length allowed
    uint public maxMessageLength = 1024; // 1kb
    // Fee required to be paid for SendMessage calls
    uint256 internal _sendMessageFee = 3e14; // 0.0003 ether
    // Message fees accumulated by the bridge
    uint public accumulatedMessageFees;

    event MessageReceived(
        uint indexed eventId,
        address indexed source,
        address indexed destinate,
        bytes message
    );
    event SetValidators(
        bytes32 indexed validatorSetDigest,
        uint256 indexed reward,
        uint32 indexed validatorSetId
    );
    event ForceSetActiveValidators(
        bytes32 indexed validatorSetDigest,
        uint32 indexed validatorSetId
    );
    event ForceSetHistoricValidators(
        bytes32 indexed validatorSetDigest,
        uint32 indexed validatorSetId
    );
    event BridgeFeeUpdated(uint indexed bridgeFee);
    event ThresholdUpdated(uint indexed thresholdPercent);
    event ProofTTLUpdated(uint indexed proofTTL);
    event BridgeActiveUpdated(bool indexed active);
    event MaxRewardPayoutUpdated(uint indexed maxRewardPayout);
    event PalletAddressUpdated(address indexed palletAddress);
    event MaxMessageLengthUpdated(uint indexed maxMessageLength);
    event SentEventIdUpdated(uint indexed _newId);
    event Endowed(uint256 indexed amount);
    event EtherWithdrawn(address _to, uint256 _amount);
    event WithdrawnMessageFees(address indexed recipient, uint indexed amount);
    event SendMessageFeeUpdated(uint256 indexed sendMessageFee);

    /// @notice Emit an event for the remote chain
    function sendMessage(address destination, bytes calldata message)
        external
        payable
        override
    {
        require(active, "Bridge: bridge inactive");
        require(message.length <= maxMessageLength, "Bridge: msg exceeds max length");
        require(msg.value >= _sendMessageFee, "Bridge: insufficient message fee");
        accumulatedMessageFees += msg.value;
        emit SendMessage(sentEventId++, msg.sender, destination, message, msg.value);
    }

    function sendMessageFee() external override view returns (uint256) {
        return _sendMessageFee;
    }

    /// @notice Receive a message from the remote chain
    /// @param proof contains a list of validator signature data and respective addresses - retrieved via RPC call from the remote chain
    function receiveMessage(
        address source,
        address destination,
        bytes calldata appMessage,
        EventProof calldata proof
    ) external payable override {
        require(
            msg.value >= bridgeFee || destination == address(this),
            "Bridge: must supply bridge fee"
        );
        require(appMessage.length > 0, "Bridge: empty message");

        bytes memory preimage = abi.encode(
            source,
            destination,
            appMessage,
            proof.validatorSetId,
            proof.eventId
        );
        _verifyMessage(preimage, proof);

        emit MessageReceived(proof.eventId, source, destination, appMessage);

        // call bridge receiver
        IBridgeReceiver(destination).onMessageReceived(source, appMessage);
    }

    /// @notice Verify a message was authorised by validators.
    /// - Callable by anyone.
    /// - Caller must provide `bridgeFee`.
    /// - Requires signatures from a threshold validators at proof.validatorSetId.
    /// - Requires proof is not older than `proofTTL` eras
    /// - Halts on failure
    ///
    /// @dev Parameters:
    /// - preimage: the unhashed message data packed wide w source, dest, validatorSetId & eventId e.g. `abi.encode(source, dest, message, validatorSetId, eventId);`
    /// - proof: Signed witness material generated by proving 'message'
    ///     - v,r,s are sparse arrays expected to align w public key in 'validators'
    ///     - i.e. v[i], r[i], s[i] matches the i-th validator[i]
    function _verifyMessage(bytes memory preimage, EventProof calldata proof)
        internal
    {
        // gas savings
        uint256 _eventId = proof.eventId;
        uint32 _validatorSetId = proof.validatorSetId;
        address[] memory _validators = proof.validators;

        require(active, "Bridge: bridge inactive");
        require(!verifiedEventIds[_eventId], "Bridge: eventId replayed");
        require(
            _validatorSetId <= activeValidatorSetId,
            "Bridge: future validator set"
        );
        require(
            activeValidatorSetId - _validatorSetId <= proofTTL,
            "Bridge: expired proof"
        );
        // audit item #1
        require(_validators.length > 0, "Bridge: invalid validator set");
        require(
            keccak256(abi.encode(_validators)) ==
                validatorSetDigests[_validatorSetId],
            "Bridge: unexpected validator digest"
        );

        bytes32 digest = keccak256(preimage);
        uint acceptanceTreshold = ((_validators.length * thresholdPercent) /
            100);
        uint witnessCount; // uint256(0)
        bytes32 ommited; // bytes32(0)

        for (uint i; i < _validators.length; ++i) {
            if (proof.r[i] != ommited) { // check signature omitted == bytes32(0)
                // check signature
                require(
                    _validators[i] == digest.recover(proof.v[i], proof.r[i], proof.s[i]),
                    "Bridge: signature invalid"
                );
                witnessCount += 1;
                // have we got proven consensus?
                if (witnessCount >= acceptanceTreshold) {
                    break;
                }
            }
        }

        require(witnessCount >= acceptanceTreshold, "Bridge: not enough signatures");
        verifiedEventIds[_eventId] = true;
    }

    /// @notice Handle a verified message provided by 'receiveMessage` to update the next validator set
    /// i.e. The bridge contract is itself a bridge app contract
    function onMessageReceived(address source, bytes calldata message)
        external
        override
    {
        require(msg.sender == address(this), "Bridge: only bridge can call");
        require(source == palletAddress, "Bridge: source must be pallet");
        (address[] memory newValidators, uint32 newValidatorSetId) = abi.decode(
            message,
            (address[], uint32)
        );
        _setValidators(newValidators, newValidatorSetId);
    }

    /// @dev Update the known validator set (must be called via 'relayMessage' with a valid proof of new validator set)
    function _setValidators(
        address[] memory newValidators,
        uint32 newValidatorSetId
    ) internal nonReentrant {
        require(newValidators.length > 0, "Bridge: empty validator set"); // also checked in _verifyMessage
        require(
            newValidatorSetId > activeValidatorSetId,
            "Bridge: validator set id replayed"
        );

        // update set digest and active id
        bytes32 validatorSetDigest = keccak256(abi.encode(newValidators));
        validatorSetDigests[newValidatorSetId] = validatorSetDigest;
        activeValidatorSetId = newValidatorSetId;

        // return accumulated fees to the sender as a reward, capped at `maxRewardPayout`
        uint reward = Math.min(address(this).balance - accumulatedMessageFees, maxRewardPayout);
        (bool sent, ) = tx.origin.call{value: reward}("");
        require(sent, "Bridge: Failed to send reward");

        emit SetValidators(validatorSetDigest, reward, newValidatorSetId);
    }

    /// @dev See {IERC165-supportsInterface}. Docs: https://docs.openzeppelin.com/contracts/4.x/api/utils#IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IBridge).interfaceId ||
            interfaceId == type(IBridgeReceiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // ============================================================================================================= //
    // ============================================== Admin functions ============================================== //
    // ============================================================================================================= //

    /// @notice force set the active validator set
    /// @dev newValidatorSetId can be equal to current activeValidatorSetId - to override current validators
    function forceActiveValidatorSet(
        address[] calldata newValidators,
        uint32 newValidatorSetId
    ) external onlyOwner {
        require(newValidators.length > 0, "Bridge: empty validator set");
        require(newValidatorSetId >= activeValidatorSetId, "Bridge: set is historic");
        bytes32 validatorSetDigest = keccak256(abi.encode(newValidators));
        validatorSetDigests[newValidatorSetId] = validatorSetDigest;
        activeValidatorSetId = newValidatorSetId;
        emit ForceSetActiveValidators(validatorSetDigest, newValidatorSetId);
    }

    /// @notice Force set a historic validator set
    /// @dev Sets older than proofTTL are not modifiable (since they cannot produce valid proofs any longer)
    function forceHistoricValidatorSet(
        address[] calldata _validators,
        uint32 validatorSetId
    ) external onlyOwner {
        require(_validators.length > 0, "Bridge: empty validator set");
        require(
            validatorSetId + proofTTL > activeValidatorSetId,
            "Bridge: set is inactive"
        );
        bytes32 validatorSetDigest = keccak256(abi.encode(_validators));
        validatorSetDigests[validatorSetId] = validatorSetDigest;
        emit ForceSetHistoricValidators(validatorSetDigest, validatorSetId);
    }

    /// @notice Set the TTL for historic validator set proofs
    function setProofTTL(uint256 _proofTTL) external onlyOwner {
        proofTTL = _proofTTL;
        emit ProofTTLUpdated(_proofTTL);
    }

    /// @notice Set the max reward payout for `setValidator` incentive
    function setMaxRewardPayout(uint256 _maxRewardPayout) external onlyOwner {
        maxRewardPayout = _maxRewardPayout;
        emit MaxRewardPayoutUpdated(_maxRewardPayout);
    }

    /// @notice Set the sentEventId for the contract to start with
    function setSentEventId(uint _newId) external onlyOwner {
        sentEventId = _newId;
        emit SentEventIdUpdated(_newId);
    }

    /// @notice Set the fee for verify messages
    function setBridgeFee(uint256 _bridgeFee) external onlyOwner {
        bridgeFee = _bridgeFee;
        emit BridgeFeeUpdated(_bridgeFee);
    }

    /// @notice Set the threshold % required for proof verification
    function setThreshold(uint256 _thresholdPercent) external onlyOwner {
        require(_thresholdPercent <= 100, "Bridge: percent must be <= 100");
        thresholdPercent = _thresholdPercent;
        emit ThresholdUpdated(_thresholdPercent);
    }

    /// @notice Set the pallet address
    function setPalletAddress(address _palletAddress) external onlyOwner {
        palletAddress = _palletAddress;
        emit PalletAddressUpdated(_palletAddress);
    }

    /// @notice Activate/deactivate the bridge
    function setActive(bool _active) external onlyOwner {
        active = _active;
        emit BridgeActiveUpdated(_active);
    }

    /// @dev Reset max message length
    function setMaxMessageLength(uint256 _maxMessageLength) external onlyOwner {
        maxMessageLength = _maxMessageLength;
        emit MaxMessageLengthUpdated(_maxMessageLength);
    }

    /// @dev Endow the contract with ether
    function endow() external payable {
        require(msg.value > 0, "Bridge: must endow nonzero");
        emit Endowed(msg.value);
    }

    /// @dev Owner can withdraw ether from the contract (primarily to support contract upgradability)
    function withdrawAll(address payable _to) public onlyOwner {
        uint256 balance = address(this).balance;
        (bool sent,) = _to.call{value: balance}("");
        require(sent, "Bridge: failed to send Ether");
        emit EtherWithdrawn(_to, balance);
    }

    /// @dev Set _sendMessageFee
    function setSendMessageFee(uint256 _fee) external onlyOwner {
        _sendMessageFee = _fee;
        emit SendMessageFeeUpdated(_fee);
    }

    /// @dev Owner can withdraw accumulates msg fees from the contract
    function withdrawMsgFees(address payable _to, uint256 _amount) public onlyOwner {
        accumulatedMessageFees -= _amount; // prevent re-entrancy protection
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Bridge: Failed to send msg fees");
        emit WithdrawnMessageFees(_to, _amount);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

// Proof of a witnessed event by validators
struct EventProof {
    // The Id (nonce) of the event
    uint256 eventId;
    // The validator set Id which witnessed the event
    uint32 validatorSetId;
    // v,r,s are sparse arrays expected to align w public key in 'validators'
    // i.e. v[i], r[i], s[i] matches the i-th validator[i]
    // v part of validator signatures
    uint8[] v;
    // r part of validator signatures
    bytes32[] r;
    // s part of validator signatures
    bytes32[] s;
    // The validator addresses
    address[] validators;
}

interface IBridge {
    // A sent message event
    event SendMessage(uint messageId, address source, address destination, bytes message, uint256 fee);
    // Receive a bridge message from the remote chain
    function receiveMessage(address source, address destination, bytes calldata message, EventProof calldata proof) external payable;
    // Send a bridge message to the remote chain
    function sendMessage(address destination, bytes calldata message) external payable;
    // Send message fee - used by sendMessage caller to obtain required fee for sendMessage
    function sendMessageFee() external view returns (uint256);
}

interface IBridgeReceiver {
    // Handle a bridge message received from the remote chain
    // It is guaranteed to be valid
    function onMessageReceived(address source, bytes calldata message) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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
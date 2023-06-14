// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./SCProofVerifierBase.sol";
import "../interface/IStateConnector.sol";

contract SCProofVerifier is SCProofVerifierBase {
    IStateConnector public stateConnector;

    constructor(IStateConnector _stateConnector) {
        stateConnector = _stateConnector;
    }

    function merkleRootForRound(uint256 _stateConnectorRound) public view override returns (bytes32 _merkleRoot) {
        return stateConnector.merkleRoots(_stateConnectorRound % stateConnector.TOTAL_STORED_PROOFS());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

//////////////////////////////////////////////////////////////
// This file is auto generated. Do not edit.
//////////////////////////////////////////////////////////////

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "../interface/ISCProofVerifier.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

abstract contract SCProofVerifierBase is ISCProofVerifier {
    using MerkleProof for bytes32[];

    // possible attestationType values
    uint16 public constant PAYMENT = 1;
    uint16 public constant BALANCE_DECREASING_TRANSACTION = 2;
    uint16 public constant CONFIRMED_BLOCK_HEIGHT_EXISTS = 3;
    uint16 public constant REFERENCED_PAYMENT_NONEXISTENCE = 4;

    function verifyPayment(
        uint32 _chainId,
        Payment calldata _data
    ) external view override returns (bool _proved) {
        return
            _verifyMerkleProof(
                _data.merkleProof,
                merkleRootForRound(_data.stateConnectorRound),
                _hashPayment(_chainId, _data)
            );
    }

    function verifyBalanceDecreasingTransaction(
        uint32 _chainId,
        BalanceDecreasingTransaction calldata _data
    ) external view override returns (bool _proved) {
        return
            _verifyMerkleProof(
                _data.merkleProof,
                merkleRootForRound(_data.stateConnectorRound),
                _hashBalanceDecreasingTransaction(_chainId, _data)
            );
    }

    function verifyConfirmedBlockHeightExists(
        uint32 _chainId,
        ConfirmedBlockHeightExists calldata _data
    ) external view override returns (bool _proved) {
        return
            _verifyMerkleProof(
                _data.merkleProof,
                merkleRootForRound(_data.stateConnectorRound),
                _hashConfirmedBlockHeightExists(_chainId, _data)
            );
    }

    function verifyReferencedPaymentNonexistence(
        uint32 _chainId,
        ReferencedPaymentNonexistence calldata _data
    ) external view override returns (bool _proved) {
        return
            _verifyMerkleProof(
                _data.merkleProof,
                merkleRootForRound(_data.stateConnectorRound),
                _hashReferencedPaymentNonexistence(_chainId, _data)
            );
    }

    function merkleRootForRound(
        uint256 _stateConnectorRound
    ) public view virtual returns (bytes32 _merkleRoot);

    function hashPayment(
        uint32 _chainId,
        Payment calldata _data
    ) public pure returns (bytes32 _hash) {
        return _hashPayment(_chainId, _data);
    }

    function _hashPayment(
        uint32 _chainId,
        Payment calldata _data
    ) private pure returns (bytes32) {
        return
            keccak256(
                bytes.concat(
                    // split into parts of length 8 to avoid 'stack too deep' errors
                    abi.encode(
                        PAYMENT,
                        _chainId,
                        _data.stateConnectorRound,
                        _data.blockNumber,
                        _data.blockTimestamp,
                        _data.transactionHash,
                        _data.inUtxo,
                        _data.utxo
                    ),
                    abi.encode(
                        _data.sourceAddressHash,
                        _data.intendedSourceAddressHash,
                        _data.receivingAddressHash,
                        _data.intendedReceivingAddressHash,
                        _data.spentAmount,
                        _data.intendedSpentAmount,
                        _data.receivedAmount,
                        _data.intendedReceivedAmount
                    ),
                    abi.encode(
                        _data.paymentReference,
                        _data.oneToOne,
                        _data.status
                    )
                )
            );
    }

    function _hashBalanceDecreasingTransaction(
        uint32 _chainId,
        BalanceDecreasingTransaction calldata _data
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    BALANCE_DECREASING_TRANSACTION,
                    _chainId,
                    _data.stateConnectorRound,
                    _data.blockNumber,
                    _data.blockTimestamp,
                    _data.transactionHash,
                    _data.sourceAddressIndicator,
                    _data.sourceAddressHash,
                    _data.spentAmount,
                    _data.paymentReference
                )
            );
    }

    function _hashConfirmedBlockHeightExists(
        uint32 _chainId,
        ConfirmedBlockHeightExists calldata _data
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    CONFIRMED_BLOCK_HEIGHT_EXISTS,
                    _chainId,
                    _data.stateConnectorRound,
                    _data.blockNumber,
                    _data.blockTimestamp,
                    _data.numberOfConfirmations,
                    _data.lowestQueryWindowBlockNumber,
                    _data.lowestQueryWindowBlockTimestamp
                )
            );
    }

    function _hashReferencedPaymentNonexistence(
        uint32 _chainId,
        ReferencedPaymentNonexistence calldata _data
    ) private pure returns (bytes32) {
        return
            keccak256(
                bytes.concat(
                    // split into parts of length 8 to avoid 'stack too deep' errors
                    abi.encode(
                        REFERENCED_PAYMENT_NONEXISTENCE,
                        _chainId,
                        _data.stateConnectorRound,
                        _data.deadlineBlockNumber,
                        _data.deadlineTimestamp,
                        _data.destinationAddressHash,
                        _data.paymentReference,
                        _data.amount
                    ),
                    abi.encode(
                        _data.lowerBoundaryBlockNumber,
                        _data.lowerBoundaryBlockTimestamp,
                        _data.firstOverflowBlockNumber,
                        _data.firstOverflowBlockTimestamp
                    )
                )
            );
    }

    function _verifyMerkleProof(
        bytes32[] memory proof,
        bytes32 merkleRoot,
        bytes32 leaf
    ) internal pure returns (bool) {
        return proof.verify(merkleRoot, leaf);
    }
}

//////////////////////////////////////////////////////////////
// This file is auto generated. Do not edit.
//////////////////////////////////////////////////////////////

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6 <0.9;

interface ISCProofVerifier {
    struct Payment {
        // Merkle proof needed to verify the existence of transaction with the below fields.
        bytes32[] merkleProof;
        // Round id in which the attestation request was validated.
        uint256 stateConnectorRound;
        // Number of the transaction block on the underlying chain.
        uint64 blockNumber;
        // Timestamp of the transaction block on the underlying chain.
        uint64 blockTimestamp;
        // Hash of the transaction on the underlying chain.
        bytes32 transactionHash;
        // Index of the transaction input indicating source address on UTXO chains, 0 on non-UTXO chains.
        uint8 inUtxo;
        // Output index for a transaction with multiple outputs on UTXO chains, 0 on non-UTXO chains.
        // The same as in the 'utxo' parameter from the request.
        uint8 utxo;
        // Standardized address hash of the source address viewed as a string (the one indicated by the 'inUtxo' parameter for UTXO blockchains).
        bytes32 sourceAddressHash;
        // Standardized address hash of the intended source address viewed as a string (the one indicated by the 'inUtxo' parameter for UTXO blockchains).
        bytes32 intendedSourceAddressHash;
        // Standardized address hash of the receiving address as a string (the one indicated by the 'utxo' parameter for UTXO blockchains).
        bytes32 receivingAddressHash;
        // Standardized address hash of the intended receiving address as a string (the one indicated by the 'utxo' parameter for UTXO blockchains).
        bytes32 intendedReceivingAddressHash;
        // The amount that went out of the source address, in the smallest underlying units.
        // In non-UTXO chains it includes both payment value and fee (gas).
        // Calculation for UTXO chains depends on the existence of standardized payment reference.
        // If it exists, it is calculated as 'outgoing_amount - returned_amount' and can be negative.
        // If the standardized payment reference does not exist, then it is just the spent amount
        // on the input indicated by 'inUtxo'.
        int256 spentAmount;
        // The amount that was intended to go out of the source address, in the smallest underlying units.
        // If the transaction status is successful the value matches 'spentAmount'.
        // If the transaction status is not successful, the value is the amount that was intended to be spent by the source address.
        int256 intendedSpentAmount;
        // The amount received to the receiving address, in smallest underlying units. Can be negative in UTXO chains.
        int256 receivedAmount;
        // The intended amount to be received by the receiving address, in smallest underlying units.
        // For transactions that are successful, this is the same as 'receivedAmount'.
        // If the transaction status is not successful, the value is the amount that was intended to be received by the receiving address.
        int256 intendedReceivedAmount;
        // Standardized payment reference, if it exists, 0 otherwise.
        bytes32 paymentReference;
        // 'true' if the transaction has exactly one source address and
        // exactly one receiving address (different from source).
        bool oneToOne;
        // Transaction success status, can have 3 values:
        //   - 0 - Success
        //   - 1 - Failure due to sender (this is the default failure)
        //   - 2 - Failure due to receiver (bad destination address)
        uint8 status;
    }

    struct BalanceDecreasingTransaction {
        // Merkle proof needed to verify the existence of transaction with the below fields.
        bytes32[] merkleProof;
        // Round id in which the attestation request was validated.
        uint256 stateConnectorRound;
        // Number of the transaction block on the underlying chain.
        uint64 blockNumber;
        // Timestamp of the transaction block on the underlying chain.
        uint64 blockTimestamp;
        // Hash of the transaction on the underlying chain.
        bytes32 transactionHash;
        // Either standardized hash of a source address or UTXO vin index in hex format (as provided in the request).
        bytes32 sourceAddressIndicator;
        // Standardized hash of the source address viewed as a string (the one indicated by the 'sourceAddressIndicator' (vin input index) parameter for UTXO blockchains).
        bytes32 sourceAddressHash;
        // The amount that went out of the source address, in the smallest underlying units. In non-UTXO chains it includes both payment value and fee (gas). Calculation for UTXO chains depends on the existence of standardized payment reference. If it exists, it is calculated as 'total_outgoing_amount - returned_amount' from the address indicated by 'sourceAddressIndicator', and can be negative. If the standardized payment reference does not exist, then it is just the spent amount on the input indicated by 'sourceAddressIndicator'.
        int256 spentAmount;
        // Standardized payment reference, if it exists, 0 otherwise.
        bytes32 paymentReference;
    }

    struct ConfirmedBlockHeightExists {
        // Merkle proof needed to verify the existence of transaction with the below fields.
        bytes32[] merkleProof;
        // Round id in which the attestation request was validated.
        uint256 stateConnectorRound;
        // Number of the highest confirmed block that was proved to exist.
        uint64 blockNumber;
        // Timestamp of the confirmed block that was proved to exist.
        uint64 blockTimestamp;
        // Number of confirmations for the blockchain.
        uint8 numberOfConfirmations;
        // Lowest query window block number.
        uint64 lowestQueryWindowBlockNumber;
        // Lowest query window block timestamp.
        uint64 lowestQueryWindowBlockTimestamp;
    }

    struct ReferencedPaymentNonexistence {
        // Merkle proof needed to verify the existence of transaction with the below fields.
        bytes32[] merkleProof;
        // Round id in which the attestation request was validated.
        uint256 stateConnectorRound;
        // Deadline block number specified in the attestation request.
        uint64 deadlineBlockNumber;
        // Deadline timestamp specified in the attestation request.
        uint64 deadlineTimestamp;
        // Standardized address hash of the destination address searched for.
        bytes32 destinationAddressHash;
        // The payment reference searched for.
        bytes32 paymentReference;
        // The minimal amount intended to be paid to the destination address. The actual amount should match or exceed this value.
        uint128 amount;
        // The first confirmed block that gets checked. It is exactly 'minimalBlockNumber' from the request.
        uint64 lowerBoundaryBlockNumber;
        // Timestamp of the 'lowerBoundaryBlockNumber'.
        uint64 lowerBoundaryBlockTimestamp;
        // The first (lowest) confirmed block with 'timestamp > deadlineTimestamp'
        // and 'blockNumber  > deadlineBlockNumber'.
        uint64 firstOverflowBlockNumber;
        // Timestamp of the firstOverflowBlock.
        uint64 firstOverflowBlockTimestamp;
    }

    // When verifying state connector proofs, the data verified will be
    // `keccak256(abi.encode(attestationType, _chainId, all _data fields except merkleProof, stateConnectorRound))`
    // where `attestationType` (`uint16`) is a different constant for each of the methods below
    // (possible values are defined in attestation specs).

    function verifyPayment(uint32 _chainId, Payment calldata _data) external view returns (bool _proved);

    function verifyBalanceDecreasingTransaction(uint32 _chainId, BalanceDecreasingTransaction calldata _data) external view returns (bool _proved);

    function verifyConfirmedBlockHeightExists(uint32 _chainId, ConfirmedBlockHeightExists calldata _data) external view returns (bool _proved);

    function verifyReferencedPaymentNonexistence(uint32 _chainId, ReferencedPaymentNonexistence calldata _data) external view returns (bool _proved);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6 <0.9;


interface IStateConnector {
    function merkleRoots(uint256 _index) external view returns (bytes32);
    // solhint-disable-next-line func-name-mixedcase
    function TOTAL_STORED_PROOFS() external view returns (uint256);
}
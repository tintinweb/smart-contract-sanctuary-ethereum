// SPDX-License-Identifier: Apache-2.0
pragma solidity =0.8.13;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./libraries/Bits.sol";
import "./libraries/Bitfield.sol";
import "./libraries/ScaleCodec.sol";
import "./interfaces/ISimplifiedMMRProof.sol";
import "./interfaces/IValidatorRegistry.sol";
import "./interfaces/ISimplifiedMMRVerification.sol";

/**
 * @title A entry contract for the Ethereum light client
 */
contract BeefyLightClient is ISimplifiedMMRProof {
    using Bits for uint256;
    using Bitfield for uint256[];
    using ScaleCodec for uint256;
    using ScaleCodec for uint64;
    using ScaleCodec for uint32;
    using ScaleCodec for uint16;

    /* Events */
    /**
     * @notice Notifies an observer that the complete verification process has
     *  finished successfuly and the new commitmentHash will be accepted
     * @param prover The address of the successful prover
     * @param blockNumber commitment block number
     */
    event VerificationSuccessful(address prover, uint32 blockNumber);

    event NewMMRRoot(bytes32 mmrRoot, uint64 blockNumber);

    /* Types */

    /**
     * The Commitment, with its payload, is the core thing we are trying to verify with
     * this contract. It contains a MMR root that commits to the polkadot history, including
     * past blocks and parachain blocks and can be used to verify both polkadot and parachain blocks.
     * @param payload the payload of the new commitment in beefy justifications (in
     * our case, this is a new MMR root for all past polkadot blocks)
     * @param blockNumber block number for the given commitment
     * @param validatorSetId validator set id that signed the given commitment
     */
    struct Commitment {
        bytes payloadPrefix;
        bytes32 payload;
        bytes payloadSuffix;
        uint32 blockNumber;
        uint64 validatorSetId;
    }

    /**
     * The ValidatorProof is a collection of proofs used to verify the signatures from the validators signing
     * each new justification.
     * @param signatures an array of signatures from the randomly chosen validators
     * @param positions an array of the positions of the randomly chosen validators
     * @param publicKeys an array of the public key of each signer
     * @param publicKeyMerkleProofs an array of merkle proofs from the chosen validators proving that their public
     * keys are in the validator set
     */
    struct ValidatorProof {
        uint256[] validatorClaimsBitfield;
        bytes[] signatures;
        uint256[] positions;
        address[] publicKeys;
        bytes32[][] publicKeyMerkleProofs;
    }

    /**
     * The BeefyMMRLeaf is the structure of each leaf in each MMR that each commitment's payload commits to.
     * @param version version of the leaf type
     * @param parentNumber parent number of the block this leaf describes
     * @param parentHash parent hash of the block this leaf describes
     * @param nextAuthoritySetId validator set id that will be part of consensus for the next block
     * @param nextAuthoritySetLen length of that validator set
     * @param nextAuthoritySetRoot merkle root of all public keys in that validator set
     * @param randomHash BABE VRF randomness for the block this leaf describes
     * @param digestHash hash of the latest finalized block
     */
    struct BeefyMMRLeaf {
        uint8 version;
        uint32 parentNumber;
        uint64 nextAuthoritySetId;
        uint32 nextAuthoritySetLen; // More tightly packed, `version` 1byte, `parentNumber` 4byte, 
                                    // `nextAuthoritySetId` 8byte, 
                                    // `nextAuthoritySetLen` 4byte now use single storage slot. 
        bytes32 parentHash;
        bytes32 nextAuthoritySetRoot;
        bytes32 randomSeed;
        bytes32 digestHash;
    }

    /* State */
    IValidatorRegistry public validatorRegistry;
    ISimplifiedMMRVerification public mmrVerification;

    // Ring buffer of latest MMR Roots
    mapping(uint256 => bytes32) public latestMMRRoots;
    uint32 public latestMMRRootIndex; // default value is 0
    uint32 public constant MMR_ROOT_HISTORY_SIZE = 30;

    uint64 public latestBeefyBlock;
    bytes32 public latestRandomSeed;

    /* Constants */

    // THRESHOLD_NUMERATOR - numerator for percent of validator signatures required
    // THRESHOLD_DENOMINATOR - denominator for percent of validator signatures required
    uint256 public constant THRESHOLD_NUMERATOR = 22;
    uint256 public constant THRESHOLD_DENOMINATOR = 59;

    // We must ensure at least one block is processed every session,
    // so these constants are checked to enforce a maximum gap between commitments.
    uint64 public constant NUMBER_OF_BLOCKS_PER_SESSION = 600;
    uint64 public constant ERROR_AND_SAFETY_BUFFER = 10;
    uint64 public constant MAXIMUM_BLOCK_GAP =
        NUMBER_OF_BLOCKS_PER_SESSION - ERROR_AND_SAFETY_BUFFER;

    bytes2 public constant MMR_ROOT_ID = 0x6d68;

    /**
     * @notice Deploys the BeefyLightClient contract
     * @param _validatorRegistry The contract to be used as the validator registry
     * @param _mmrVerification The contract to be used for MMR verification
     */
    constructor(
        IValidatorRegistry _validatorRegistry,
        ISimplifiedMMRVerification _mmrVerification,
        uint64 _startingBeefyBlock
    ) {
        validatorRegistry = _validatorRegistry;
        mmrVerification = _mmrVerification;
        latestRandomSeed = bytes32(uint(42));
        latestBeefyBlock = _startingBeefyBlock;
    }

    /* Public Functions */

    /**
     * @notice Adds MMR root to the known last roots history.
     */
    function addKnownMMRRoot(bytes32 root) public returns (uint32 index) {
        uint32 newRootIndex = (latestMMRRootIndex + 1) % MMR_ROOT_HISTORY_SIZE;
        latestMMRRoots[newRootIndex] = root;
        latestMMRRootIndex = newRootIndex;
        return latestMMRRootIndex;
    }

    /**
     * @notice Whether the root is present in the root history
     */
    function isKnownRoot(bytes32 root) public view returns (bool) {
        if (root == 0) {
            return false;
        }
        uint32 i = latestMMRRootIndex;
        do {
            if (root == latestMMRRoots[i]) {
                return true;
            }
            if (i == 0) {
                i = MMR_ROOT_HISTORY_SIZE;
            }
            i--;
        } while (i != latestMMRRootIndex);
        return false;
    }

    /**
     *@notice Returns the last added root
     */
    function getLatestMMRRoot() public view returns (bytes32) {
        return latestMMRRoots[latestMMRRootIndex];
    }

    /**
     * @notice Executed by the incoming channel in order to verify commitment
     * @param beefyMMRLeaf contains the merkle leaf to be verified
     * @param proof contains simplified MMR proof
     */
    function verifyBeefyMerkleLeaf(
        bytes32 beefyMMRLeaf,
        SimplifiedMMRProof memory proof
    ) external view returns (bool) {
        bytes32 proofRoot = mmrVerification.calculateMerkleRoot(
            beefyMMRLeaf,
            proof.merkleProofItems,
            proof.merkleProofOrderBitField
        );

        return isKnownRoot(proofRoot);
    }

    // changed to external view since it's not called anywhere else inside the contract
    function createRandomBitfield(uint256[] memory validatorClaimsBitfield)
        external
        view
        returns (uint256[] memory)
    {
        uint256 numberOfValidators = validatorRegistry.numOfValidators();

        return
            Bitfield.randomNBitsWithPriorCheck(
                getSeed(),
                validatorClaimsBitfield,
                requiredNumberOfSignatures(numberOfValidators),
                numberOfValidators
            );
    }

    function createInitialBitfield(uint256[] calldata bitsToSet, uint256 length)
        external
        pure
        returns (uint256[] memory)
    {
        return Bitfield.createBitfield(bitsToSet, length);
    }

    /**
     * @notice Submit a new BEEFY commitment to the light client
     * @param commitment contains the full commitment that was used for the commitmentHash
     * @param validatorProof a struct containing the data needed to verify all validator signatures
     * @param latestMMRLeaf the merkle leaf that was used to create the latestMMRRoot
     * @param proof contains the simplified MMR proof for the latestMMRLeaf
     */
     // changed to external view since it's not called anywhere else inside the contract
    function submitSignatureCommitment(
        Commitment calldata commitment,
        ValidatorProof calldata validatorProof,
        BeefyMMRLeaf calldata latestMMRLeaf,
        SimplifiedMMRProof calldata proof
    ) external {
        verifyCommitment(commitment, validatorProof);
        verifyNewestMMRLeaf(latestMMRLeaf, commitment.payload, proof);

        processPayload(commitment.payload, commitment.blockNumber);

        latestRandomSeed = latestMMRLeaf.randomSeed;

        applyValidatorSetChanges(
            latestMMRLeaf.nextAuthoritySetId,
            latestMMRLeaf.nextAuthoritySetLen,
            latestMMRLeaf.nextAuthoritySetRoot
        );

        emit VerificationSuccessful(msg.sender, commitment.blockNumber);
    }

    /* Private Functions */

    /**
     * @return onChainRandNums an array storing the random numbers generated inside this function
     */
    function getSeed() private view returns (uint256) {
        // @note Create hash of block number and random seed
        bytes32 randomSeedWithBlockNumber = keccak256(
            bytes.concat(latestRandomSeed, bytes8(latestBeefyBlock))
        );

        return uint256(randomSeedWithBlockNumber);
    }

    function verifyNewestMMRLeaf(
        BeefyMMRLeaf calldata leaf,
        bytes32 root,
        SimplifiedMMRProof calldata proof
    ) public view {
        bytes memory encodedLeaf = encodeMMRLeaf(leaf);
        bytes32 hashedLeaf = hashMMRLeaf(encodedLeaf);

        require(
            mmrVerification.verifyInclusionProof(root, hashedLeaf, proof),
            "invalid mmr proof"
        );
    }

    /**
     * @notice Perform some operation[s] using the payload
     * @param payload The payload variable passed in via the initial function
     */
    function processPayload(bytes32 payload, uint64 blockNumber) private {
        // Check that payload.leaf.block_number is > last_known_block_number;
        require(
            blockNumber > latestBeefyBlock,
            "Payload blocknumber is too old"
        );

        // Check that payload is within the current or next session
        // to ensure we get at least one payload each session
        require(
            blockNumber < latestBeefyBlock + MAXIMUM_BLOCK_GAP,
            "Payload blocknumber is too new"
        );

        addKnownMMRRoot(payload);
        latestBeefyBlock = blockNumber;
        emit NewMMRRoot(payload, blockNumber);
    }

    /**
     * @notice Check if the payload includes a new validator set,
     * and if it does then update the new validator set
     * @dev This function should call out to the validator registry contract
     * @param nextAuthoritySetId The id of the next authority set
     * @param nextAuthoritySetLen The number of validators in the next authority set
     * @param nextAuthoritySetRoot The merkle root of the merkle tree of the next validators
     */
    function applyValidatorSetChanges(
        uint64 nextAuthoritySetId,
        uint32 nextAuthoritySetLen,
        bytes32 nextAuthoritySetRoot
    ) internal {
        if (nextAuthoritySetId != validatorRegistry.id()) {
            require(
                nextAuthoritySetId > validatorRegistry.id(),
                "Error: Cannot switch to old validator set"
            );
            validatorRegistry.update(
                nextAuthoritySetRoot,
                nextAuthoritySetLen,
                nextAuthoritySetId
            );
        }
    }

    function requiredNumberOfSignatures() public view returns (uint256) {
        return
            (validatorRegistry.numOfValidators() *
                THRESHOLD_NUMERATOR +
                THRESHOLD_DENOMINATOR -
                1) / THRESHOLD_DENOMINATOR;
    }

    function requiredNumberOfSignatures(uint256 numValidators)
        public
        pure
        returns (uint256)
    {
        return
            (numValidators * THRESHOLD_NUMERATOR + THRESHOLD_DENOMINATOR - 1) /
            THRESHOLD_DENOMINATOR;
    }

    /**
     * @dev https://github.com/sora-xor/substrate/blob/7d914ce3ed34a27d7bb213caed374d64cde8cfa8/client/beefy/src/round.rs#L62
     */
    function checkCommitmentSignaturesThreshold(
        uint256 numOfValidators,
        uint256[] calldata validatorClaimsBitfield
    ) public pure {
        uint256 threshold = numOfValidators - (numOfValidators - 1) / 3;
        require(
            Bitfield.countSetBits(validatorClaimsBitfield) >= threshold,
            "Error: Not enough validator signatures"
        );
    }

    function verifyCommitment(
        Commitment calldata commitment,
        ValidatorProof calldata proof
    ) internal view {
        uint256 numberOfValidators = validatorRegistry.numOfValidators();
        uint256 requiredNumOfSignatures = requiredNumberOfSignatures(
            numberOfValidators
        );

        checkCommitmentSignaturesThreshold(
            numberOfValidators,
            proof.validatorClaimsBitfield
        );

        uint256[] memory randomBitfield = Bitfield.randomNBitsWithPriorCheck(
            getSeed(),
            proof.validatorClaimsBitfield,
            requiredNumOfSignatures,
            numberOfValidators
        );

        verifyValidatorProofLengths(requiredNumOfSignatures, proof);

        // Encode and hash the commitment
        bytes32 commitmentHash = createCommitmentHash(commitment);

        verifyValidatorProofSignatures(
            randomBitfield,
            proof,
            requiredNumOfSignatures,
            commitmentHash
        );
    }

    function verifyValidatorProofLengths(
        uint256 requiredNumOfSignatures,
        ValidatorProof calldata proof
    ) internal pure {
        /**
         * @dev verify that required number of signatures, positions, public keys and merkle proofs are
         * submitted
         */
        require(
            proof.signatures.length == requiredNumOfSignatures,
            "Error: Number of signatures does not match required"
        );
        require(
            proof.positions.length == requiredNumOfSignatures,
            "Error: Number of validator positions does not match required"
        );
        require(
            proof.publicKeys.length == requiredNumOfSignatures,
            "Error: Number of validator public keys does not match required"
        );
        require(
            proof.publicKeyMerkleProofs.length == requiredNumOfSignatures,
            "Error: Number of validator public keys does not match required"
        );
    }

    function verifyValidatorProofSignatures(
        uint256[] memory randomBitfield,
        ValidatorProof calldata proof,
        uint256 requiredNumOfSignatures,
        bytes32 commitmentHash
    ) internal view {
        /**
         *  @dev For each randomSignature, do:
         */
        for (uint256 i = 0; i < requiredNumOfSignatures; i++) {
            verifyValidatorSignature(
                randomBitfield,
                proof.signatures[i],
                proof.positions[i],
                proof.publicKeys[i],
                proof.publicKeyMerkleProofs[i],
                commitmentHash
            );
        }
    }

    function verifyValidatorSignature(
        uint256[] memory randomBitfield,
        bytes calldata signature,
        uint256 position,
        address publicKey,
        bytes32[] calldata publicKeyMerkleProof,
        bytes32 commitmentHash
    ) internal view {
        /**
         * @dev Check if validator in randomBitfield
         */
        require(
            randomBitfield.isSet(position),
            "Error: Validator must be once in bitfield"
        );

        /**
         * @dev Remove validator from randomBitfield such that no validator can appear twice in signatures
         */
        randomBitfield.clear(position);

        /**
         * @dev Check if merkle proof is valid
         */
        require(
            validatorRegistry.checkValidatorInSet(
                publicKey,
                position,
                publicKeyMerkleProof
            ),
            "Error: Validator must be in validator set at correct position"
        );

        /**
         * @dev Check if signature is correct
         */
        require(
            ECDSA.recover(commitmentHash, signature) == publicKey,
            "Error: Invalid Signature"
        );
    }

    function createCommitmentHash(Commitment calldata commitment)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                bytes.concat(
                    commitment.payloadPrefix,
                    MMR_ROOT_ID,
                    bytes1(0x80), // Vec len: 32
                    commitment.payload,
                    commitment.payloadSuffix,
                    commitment.blockNumber.encode32(),
                    commitment.validatorSetId.encode64()
                )
            );
    }

    function encodeMMRLeaf(BeefyMMRLeaf calldata leaf)
        public
        pure
        returns (bytes memory)
    {
        bytes memory scaleEncodedMMRLeaf = abi.encodePacked(
            ScaleCodec.encode8(leaf.version),
            ScaleCodec.encode32(leaf.parentNumber),
            leaf.parentHash,
            ScaleCodec.encode64(leaf.nextAuthoritySetId),
            ScaleCodec.encode32(leaf.nextAuthoritySetLen),
            leaf.nextAuthoritySetRoot,
            leaf.randomSeed,
            leaf.digestHash
        );

        return scaleEncodedMMRLeaf;
    }

    function hashMMRLeaf(bytes memory leaf) public pure returns (bytes32) {
        return keccak256(leaf);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: Apache-2.0
// Code from https://github.com/ethereum/solidity-examples
pragma solidity =0.8.13;

library Bits {
    uint256 internal constant ONE = uint256(1);
    uint256 internal constant ONES = type(uint256).max;

    // Sets the bit at the given 'index' in 'self' to '1'.
    // Returns the modified value.
    function setBit(uint256 self, uint8 index) internal pure returns (uint256) {
        return self | (ONE << index);
    }

    // Sets the bit at the given 'index' in 'self' to '0'.
    // Returns the modified value.
    function clearBit(uint256 self, uint8 index)
        internal
        pure
        returns (uint256)
    {
        return self & ~(ONE << index);
    }

    // Sets the bit at the given 'index' in 'self' to:
    //  '1' - if the bit is '0'
    //  '0' - if the bit is '1'
    // Returns the modified value.
    function toggleBit(uint256 self, uint8 index)
        internal
        pure
        returns (uint256)
    {
        return self ^ (ONE << index);
    }

    // Get the value of the bit at the given 'index' in 'self'.
    function bit(uint256 self, uint8 index) internal pure returns (uint8) {
        return uint8((self >> index) & 1);
    }

    // Check if the bit at the given 'index' in 'self' is set.
    // Returns:
    //  'true' - if the value of the bit is '1'
    //  'false' - if the value of the bit is '0'
    function bitSet(uint256 self, uint8 index) internal pure returns (bool) {
        return (self >> index) & 1 == 1;
    }

    // Checks if the bit at the given 'index' in 'self' is equal to the corresponding
    // bit in 'other'.
    // Returns:
    //  'true' - if both bits are '0' or both bits are '1'
    //  'false' - otherwise
    function bitEqual(
        uint256 self,
        uint256 other,
        uint8 index
    ) internal pure returns (bool) {
        return ((self ^ other) >> index) & 1 == 0;
    }

    // Get the bitwise NOT of the bit at the given 'index' in 'self'.
    function bitNot(uint256 self, uint8 index) internal pure returns (uint8) {
        return uint8(1 - ((self >> index) & 1));
    }

    // Computes the bitwise AND of the bit at the given 'index' in 'self', and the
    // corresponding bit in 'other', and returns the value.
    function bitAnd(
        uint256 self,
        uint256 other,
        uint8 index
    ) internal pure returns (uint8) {
        return uint8(((self & other) >> index) & 1);
    }

    // Computes the bitwise OR of the bit at the given 'index' in 'self', and the
    // corresponding bit in 'other', and returns the value.
    function bitOr(
        uint256 self,
        uint256 other,
        uint8 index
    ) internal pure returns (uint8) {
        return uint8(((self | other) >> index) & 1);
    }

    // Computes the bitwise XOR of the bit at the given 'index' in 'self', and the
    // corresponding bit in 'other', and returns the value.
    function bitXor(
        uint256 self,
        uint256 other,
        uint8 index
    ) internal pure returns (uint8) {
        return uint8(((self ^ other) >> index) & 1);
    }

    // Gets 'numBits' consecutive bits from 'self', starting from the bit at 'startIndex'.
    // Returns the bits as a 'uint'.
    // Requires that:
    //  - '0 < numBits <= 256'
    //  - 'startIndex < 256'
    //  - 'numBits + startIndex <= 256'
    function bits(
        uint256 self,
        uint8 startIndex,
        uint16 numBits
    ) internal pure returns (uint256) {
        require(0 < numBits && startIndex < 256 && startIndex + numBits <= 256);
        return (self >> startIndex) & (ONES >> (256 - numBits));
    }

    // Computes the index of the highest bit set in 'self'.
    // Returns the highest bit set as an 'uint8'.
    // Requires that 'self != 0'.
    function highestBitSet(uint256 self) internal pure returns (uint8 highest) {
        require(self != 0);
        uint256 val = self;
        for (uint8 i = 128; i >= 1; i >>= 1) {
            if (val & (((ONE << i) - 1) << i) != 0) {
                highest += i;
                val >>= i;
            }
        }
    }

    // Computes the index of the lowest bit set in 'self'.
    // Returns the lowest bit set as an 'uint8'.
    // Requires that 'self != 0'.
    function lowestBitSet(uint256 self) internal pure returns (uint8 lowest) {
        require(self != 0);
        uint256 val = self;
        for (uint8 i = 128; i >= 1; i >>= 1) {
            if (val & ((ONE << i) - 1) == 0) {
                lowest += i;
                val >>= i;
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity =0.8.13;

import "./Bits.sol";

library Bitfield {
    /**
     * @dev Constants used to efficiently calculate the hamming weight of a bitfield. See
     * https://en.wikipedia.org/wiki/Hamming_weight#Efficient_implementation for an explanation of those constants.
     */
    uint256 internal constant M1 =
        0x5555555555555555555555555555555555555555555555555555555555555555;
    uint256 internal constant M2 =
        0x3333333333333333333333333333333333333333333333333333333333333333;
    uint256 internal constant M4 =
        0x0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f;
    uint256 internal constant M8 =
        0x00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff;
    uint256 internal constant M16 =
        0x0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff0000ffff;
    uint256 internal constant M32 =
        0x00000000ffffffff00000000ffffffff00000000ffffffff00000000ffffffff;
    uint256 internal constant M64 =
        0x0000000000000000ffffffffffffffff0000000000000000ffffffffffffffff;
    uint256 internal constant M128 =
        0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;

    uint256 internal constant ONE = uint256(1);
    using Bits for uint256;

    /**
     * @notice Draws a random number, derives an index in the bitfield, and sets the bit if it is in the `prior` and not
     * yet set. Repeats that `n` times.
     */
    function randomNBitsWithPriorCheck(
        uint256 seed,
        uint256[] memory prior,
        uint256 n,
        uint256 length
    ) public pure returns (uint256[] memory bitfield) {
        require(
            n <= countSetBits(prior),
            "`n` must be <= number of set bits in `prior`"
        );

        bitfield = new uint256[](prior.length);
        uint256 found;

        for (uint256 i = 0; found < n; i++) {
            bytes32 randomness = keccak256(abi.encode(seed + i));
            uint256 index = uint256(randomness) % length;

            // require randomly seclected bit to be set in prior
            if (!isSet(prior, index)) {
                continue;
            }

            // require a not yet set (new) bit to be set
            if (isSet(bitfield, index)) {
                continue;
            }

            set(bitfield, index);

            found++;
        }

        return bitfield;
    }

    function createBitfield(uint256[] calldata bitsToSet, uint256 length)
        public
        pure
        returns (uint256[] memory bitfield)
    {
        // Calculate length of uint256 array based on rounding up to number of uint256 needed
        uint256 arrayLength = (length + 255) / 256;

        bitfield = new uint256[](arrayLength);

        for (uint256 i = 0; i < bitsToSet.length; i++) {
            set(bitfield, bitsToSet[i]);
        }

        return bitfield;
    }

    /**
     * @notice Calculates the number of set bits by using the hamming weight of the bitfield.
     * The alogrithm below is implemented after https://en.wikipedia.org/wiki/Hamming_weight#Efficient_implementation.
     * Further improvements are possible, see the article above.
     */
    function countSetBits(uint256[] memory self) public pure returns (uint256) {
        uint256 count;
        for (uint256 i = 0; i < self.length; i++) {
            uint256 x = self[i];

            x = (x & M1) + ((x >> 1) & M1); //put count of each  2 bits into those  2 bits
            x = (x & M2) + ((x >> 2) & M2); //put count of each  4 bits into those  4 bits
            x = (x & M4) + ((x >> 4) & M4); //put count of each  8 bits into those  8 bits
            x = (x & M8) + ((x >> 8) & M8); //put count of each 16 bits into those 16 bits
            x = (x & M16) + ((x >> 16) & M16); //put count of each 32 bits into those 32 bits
            x = (x & M32) + ((x >> 32) & M32); //put count of each 64 bits into those 64 bits
            x = (x & M64) + ((x >> 64) & M64); //put count of each 128 bits into those 128 bits
            x = (x & M128) + ((x >> 128) & M128); //put count of each 256 bits into those 256 bits
            count += x;
        }
        return count;
    }

    function isSet(uint256[] memory self, uint256 index)
        internal
        pure
        returns (bool)
    {
        uint256 element = index / 256;
        uint8 within = uint8(index % 256);
        return self[element].bit(within) == 1;
    }

    function set(uint256[] memory self, uint256 index) internal pure {
        uint256 element = index / 256;
        uint8 within = uint8(index % 256);
        self[element] = self[element].setBit(within);
    }

    function clear(uint256[] memory self, uint256 index) internal pure {
        uint256 element = index / 256;
        uint8 within = uint8(index % 256);
        self[element] = self[element].clearBit(within);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity =0.8.13;

library ScaleCodec {
    // Decodes a SCALE encoded uint256 by converting bytes (bid endian) to little endian format
    function decodeUint256(bytes memory data) public pure returns (uint256) {
        uint256 number;
        for (uint256 i = data.length; i > 0; i--) {
            number = number + uint256(uint8(data[i - 1])) * (2**(8 * (i - 1)));
        }
        return number;
    }

    // Decodes a SCALE encoded compact unsigned integer
    function decodeUintCompact(bytes memory data)
        public
        pure
        returns (uint256 v)
    {
        uint8 b = readByteAtIndex(data, 0); // read the first byte
        uint8 mode = b & 3; // bitwise operation

        if (mode == 0) {
            // [0, 63]
            return b >> 2; // right shift to remove mode bits
        } else if (mode == 1) {
            // [64, 16383]
            uint8 bb = readByteAtIndex(data, 1); // read the second byte
            uint64 r = bb; // convert to uint64
            r <<= 6; // multiply by * 2^6
            r += b >> 2; // right shift to remove mode bits
            return r;
        } else if (mode == 2) {
            // [16384, 1073741823]
            uint8 b2 = readByteAtIndex(data, 1); // read the next 3 bytes
            uint8 b3 = readByteAtIndex(data, 2);
            uint8 b4 = readByteAtIndex(data, 3);

            uint32 x1 = uint32(b) | (uint32(b2) << 8); // convert to little endian
            uint32 x2 = x1 | (uint32(b3) << 16);
            uint32 x3 = x2 | (uint32(b4) << 24);

            x3 >>= 2; // remove the last 2 mode bits
            return uint256(x3);
        } else if (mode == 3) {
            // [1073741824, 4503599627370496]
            uint8 l = b >> 2; // remove mode bits
            require(
                l > 32,
                "Not supported: number cannot be greater than 32 bytes"
            );
        } else {
            revert("Code should be unreachable");
        }
    }

    // Read a byte at a specific index and return it as type uint8
    function readByteAtIndex(bytes memory data, uint8 index)
        internal
        pure
        returns (uint8)
    {
        return uint8(data[index]);
    }

    // Sources:
    //   * https://ethereum.stackexchange.com/questions/15350/how-to-convert-an-bytes-to-address-in-solidity/50528
    //   * https://graphics.stanford.edu/~seander/bithacks.html#ReverseParallel

    function reverse256(uint256 input) internal pure returns (uint256 v) {
        v = input;

        // swap bytes
        v =
            ((v &
                0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00) >>
                8) |
            ((v &
                0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) <<
                8);

        // swap 2-byte long pairs
        v =
            ((v &
                0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >>
                16) |
            ((v &
                0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) <<
                16);

        // swap 4-byte long pairs
        v =
            ((v &
                0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000) >>
                32) |
            ((v &
                0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) <<
                32);

        // swap 8-byte long pairs
        v =
            ((v &
                0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000) >>
                64) |
            ((v &
                0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) <<
                64);

        // swap 16-byte long pairs
        v = (v >> 128) | (v << 128);
    }

    function reverse128(uint128 input) internal pure returns (uint128 v) {
        v = input;

        // swap bytes
        v =
            ((v & 0xFF00FF00FF00FF00FF00FF00FF00FF00) >> 8) |
            ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v =
            ((v & 0xFFFF0000FFFF0000FFFF0000FFFF0000) >> 16) |
            ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v =
            ((v & 0xFFFFFFFF00000000FFFFFFFF00000000) >> 32) |
            ((v & 0x00000000FFFFFFFF00000000FFFFFFFF) << 32);

        // swap 8-byte long pairs
        v = (v >> 64) | (v << 64);
    }

    function reverse64(uint64 input) internal pure returns (uint64 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00FF00FF00) >> 8) | ((v & 0x00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v = ((v & 0xFFFF0000FFFF0000) >> 16) | ((v & 0x0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v = (v >> 32) | (v << 32);
    }

    function reverse32(uint32 input) internal pure returns (uint32 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00) >> 8) | ((v & 0x00FF00FF) << 8);

        // swap 2-byte long pairs
        v = (v >> 16) | (v << 16);
    }

    function reverse16(uint16 input) internal pure returns (uint16 v) {
        v = input;

        // swap bytes
        v = (v >> 8) | (v << 8);
    }

    function encode256(uint256 input) public pure returns (bytes32) {
        return bytes32(reverse256(input));
    }

    function encode128(uint128 input) public pure returns (bytes16) {
        return bytes16(reverse128(input));
    }

    function encode64(uint64 input) public pure returns (bytes8) {
        return bytes8(reverse64(input));
    }

    function encode32(uint32 input) public pure returns (bytes4) {
        return bytes4(reverse32(input));
    }

    function encode16(uint16 input) public pure returns (bytes2) {
        return bytes2(reverse16(input));
    }

    function encode8(uint8 input) public pure returns (bytes1) {
        return bytes1(input);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity =0.8.13;

// Something that can reward a relayer
interface ISimplifiedMMRProof {
    struct SimplifiedMMRProof {
        bytes32[] merkleProofItems;
        uint64 merkleProofOrderBitField;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity =0.8.13;

interface IValidatorRegistry {
    /* Events */
    event ValidatorRegistryUpdated(
        bytes32 root,
        uint256 numOfValidators,
        uint64 id
    );

    function update(
        bytes32 _root,
        uint256 _numOfValidators,
        uint64 _id
    ) external;

    function checkValidatorInSet(
        address addr,
        uint256 pos,
        bytes32[] memory proof
    ) external view returns (bool);

    function numOfValidators() external view returns (uint);
    function root() external view returns (bytes32);
    function id() external view returns (uint64);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity =0.8.13;

import "./ISimplifiedMMRProof.sol";

interface ISimplifiedMMRVerification is ISimplifiedMMRProof{
    function verifyInclusionProof(
        bytes32 root,
        bytes32 leafNodeHash,
        SimplifiedMMRProof memory proof
    ) external pure returns (bool);

    function calculateMerkleRoot(
        bytes32 leafNodeHash,
        bytes32[] memory merkleProofItems,
        uint64 merkleProofOrderBitField
    ) external pure returns (bytes32 currentHash);
}
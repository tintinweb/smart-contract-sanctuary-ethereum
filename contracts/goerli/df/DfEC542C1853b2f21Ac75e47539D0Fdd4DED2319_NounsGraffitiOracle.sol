// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface ILightClient {
    function consistent() external view returns (bool);

    function head() external view returns (uint256);

    function headers(uint256 slot) external view returns (bytes32);

    function executionStateRoots(uint256 slot) external view returns (bytes32);

    function timestamps(uint256 slot) external view returns (uint256);
}

library BeaconChainForks {
    function getCapellaSlot(uint32 sourceChainId) internal pure returns (uint256) {
        // Returns CAPELLA_FORK_EPOCH * SLOTS_PER_EPOCH for the corresponding beacon chain.
        if (sourceChainId == 1) {
            // https://github.com/ethereum/consensus-specs/blob/dev/specs/capella/fork.md?plain=1#L30
            return 6209536;
        } else if (sourceChainId == 5) {
            // https://blog.ethereum.org/2023/03/08/goerli-shapella-announcement
            // https://github.com/eth-clients/goerli/blob/main/prater/config.yaml#L43
            return 5193728;
        } else {
            // We don't know the exact value for Gnosis Chain yet so we return max uint256
            // and fallback to bellatrix logic.
            return 2 ** 256 - 1;
        }
    }
}

struct BeaconBlockHeader {
    uint64 slot;
    uint64 proposerIndex;
    bytes32 parentRoot;
    bytes32 stateRoot;
    bytes32 bodyRoot;
}

library SSZ {
    uint256 internal constant HISTORICAL_ROOTS_LIMIT = 16777216;
    uint256 internal constant SLOTS_PER_HISTORICAL_ROOT = 8192;

    function toLittleEndian(uint256 v) internal pure returns (bytes32) {
        v = ((v & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00) >> 8)
            | ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);
        v = ((v & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >> 16)
            | ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);
        v = ((v & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000) >> 32)
            | ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);
        v = ((v & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000) >> 64)
            | ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);
        v = (v >> 128) | (v << 128);
        return bytes32(v);
    }

    function restoreMerkleRoot(bytes32 leaf, uint256 index, bytes32[] memory branch)
        internal
        pure
        returns (bytes32)
    {
        require(2 ** (branch.length + 1) > index);
        bytes32 value = leaf;
        uint256 i = 0;
        while (index != 1) {
            if (index % 2 == 1) {
                value = sha256(bytes.concat(branch[i], value));
            } else {
                value = sha256(bytes.concat(value, branch[i]));
            }
            index /= 2;
            i++;
        }
        return value;
    }

    function isValidMerkleBranch(bytes32 leaf, uint256 index, bytes32[] memory branch, bytes32 root)
        internal
        pure
        returns (bool)
    {
        bytes32 restoredMerkleRoot = restoreMerkleRoot(leaf, index, branch);
        return root == restoredMerkleRoot;
    }

    function sszBeaconBlockHeader(BeaconBlockHeader memory header)
        internal
        pure
        returns (bytes32)
    {
        bytes32 left = sha256(
            bytes.concat(
                sha256(
                    bytes.concat(toLittleEndian(header.slot), toLittleEndian(header.proposerIndex))
                ),
                sha256(bytes.concat(header.parentRoot, header.stateRoot))
            )
        );
        bytes32 right = sha256(
            bytes.concat(
                sha256(bytes.concat(header.bodyRoot, bytes32(0))),
                sha256(bytes.concat(bytes32(0), bytes32(0)))
            )
        );

        return sha256(bytes.concat(left, right));
    }

    function computeDomain(bytes4 forkVersion, bytes32 genesisValidatorsRoot)
        internal
        pure
        returns (bytes32)
    {
        return bytes32(uint256(0x07 << 248))
            | (sha256(abi.encode(forkVersion, genesisValidatorsRoot)) >> 32);
    }

    function verifyReceiptsRoot(
        bytes32 receiptsRoot,
        bytes32[] memory receiptsRootProof,
        bytes32 headerRoot,
        uint64 srcSlot,
        uint64 txSlot,
        uint32 sourceChainId
    ) internal pure returns (bool) {
        uint256 capellaForkSlot = BeaconChainForks.getCapellaSlot(sourceChainId);

        // In Bellatrix we use state.historical_roots, in Capella we use state.historical_summaries
        // We use < here because capellaForkSlot is the last slot processed using Bellatrix logic;
        // the last batch in state.historical_roots contains the 8192 slots *before* capellaForkSlot.
        uint256 stateToHistoricalGIndex = txSlot < capellaForkSlot ? 7 : 27;

        // The list state.historical_summaries is empty at the beginning of Capella
        uint256 historicalListIndex = txSlot < capellaForkSlot
            ? txSlot / SLOTS_PER_HISTORICAL_ROOT
            : (txSlot - capellaForkSlot) / SLOTS_PER_HISTORICAL_ROOT;

        uint256 index;
        if (srcSlot == txSlot) {
            index = 8 + 3;
            index = index * 2 ** 9 + 387;
        } else if (srcSlot - txSlot <= SLOTS_PER_HISTORICAL_ROOT) {
            index = 8 + 3;
            index = index * 2 ** 5 + 6;
            index = index * SLOTS_PER_HISTORICAL_ROOT + txSlot % SLOTS_PER_HISTORICAL_ROOT;
            index = index * 2 ** 9 + 387;
        } else if (txSlot < srcSlot) {
            index = 8 + 3;
            index = index * 2 ** 5 + stateToHistoricalGIndex;
            index = index * 2 + 0;
            index = index * HISTORICAL_ROOTS_LIMIT + historicalListIndex;
            index = index * 2 + 1;
            index = index * SLOTS_PER_HISTORICAL_ROOT + txSlot % SLOTS_PER_HISTORICAL_ROOT;
            index = index * 2 ** 9 + 387;
        } else {
            revert("TargetAMB: invalid target slot");
        }
        return isValidMerkleBranch(receiptsRoot, index, receiptsRootProof, headerRoot);
    }
}

library BeaconOracleHelper {
    /// @notice Beacon block constants
    uint256 internal constant PROPOSER_INDEX_IDX = 9;
    uint256 internal constant BEACON_STATE_ROOT_IDX = 11;
    uint256 internal constant GRAFFITI_IDX = 194;
    uint256 internal constant BASE_DEPOSIT_IDX = 6336;
    uint256 internal constant BASE_WITHDRAWAL_IDX = 103360;
    uint256 internal constant EXECUTION_PAYLOAD_BLOCK_NUMBER_IDX = 3222;

    /// @notice Beacon state constants
    uint256 internal constant BASE_BEACON_BLOCK_ROOTS_IDX = 303104;
    uint256 internal constant BASE_BEACON_STATE_ROOTS_IDX = 311296;
    uint256 public constant SLOTS_PER_HISTORICAL_ROOT = 8192;

    /// @notice Validator proof constants
    uint256 internal constant BASE_VALIDATOR_IDX = 94557999988736;
    uint256 internal constant VALIDATOR_FIELDS_LENGTH = 8;
    uint256 internal constant PUBKEY_IDX = 0;
    uint256 internal constant WITHDRAWAL_CREDENTIALS_IDX = 1;
    uint256 internal constant EFFECTIVE_BALANCE_IDX = 2;
    uint256 internal constant SLASHED_IDX = 3;
    uint256 internal constant ACTIVATION_ELIGIBILITY_EPOCH_IDX = 4;
    uint256 internal constant ACTIVATION_EPOCH_IDX = 5;
    uint256 internal constant EXIT_EPOCH_IDX = 6;
    uint256 internal constant WITHDRAWABLE_EPOCH_IDX = 7;

    /// @notice Balance constants
    uint256 internal constant BASE_BALANCE_IDX = 24189255811072;

    /// @notice Errors
    // Beacon State Proof Errors
    error InvalidValidatorProof(uint256 validatorIndex);
    error InvalidCompleteValidatorProof(uint256 validatorIndex);
    error InvalidValidatorFieldProof(ValidatorField field, uint256 validatorIndex);
    error InvalidBalanceProof(uint256 validatorIndex);
    error InvalidTargetBeaconBlockProof();
    error InvalidTargetBeaconStateProof();

    // Beacon Block Proof Errors
    error InvalidBeaconStateRootProof();
    error InvalidGraffitiProof();
    error InvalidBlockNumberProof();
    error InvalidProposerIndexProof();
    error InvalidDepositProof(bytes32 validatorPubkeyHash);
    error InvalidWithdrawalProofIndex(uint256 validatorIndex);
    error InvalidWithdrawalProofAmount(uint256 validatorIndex);

    struct BeaconStateRootProofInfo {
        uint256 slot;
        bytes32 beaconStateRoot;
        bytes32[] beaconStateRootProof;
    }

    struct TargetBeaconBlockRootProofInfo {
        uint256 targetSlot;
        bytes32 targetBeaconBlockRoot;
        bytes32[] targetBeaconBlockRootProof;
    }

    struct ValidatorProofInfo {
        uint256 validatorIndex;
        bytes32 validatorRoot;
        bytes32[] validatorProof;
    }

    struct Validator {
        // TODO: Can divide this into pubkey1, pubkey2 (48 bytes total)
        bytes32 pubkeyHash;
        bytes32 withdrawalCredentials;
        // Not to be confused with the validator's balance (effective balance capped at 32ETH)
        uint64 effectiveBalance;
        bool slashed;
        uint64 activationEligibilityEpoch;
        uint64 activationEpoch;
        // If null, type(uint64).max
        uint64 exitEpoch;
        // If null, type(uint64).max
        uint64 withdrawableEpoch;
    }

    struct ValidatorStatus {
        Validator validator;
        uint256 balance;
        bool exists;
    }

    enum ValidatorField {
        Pubkey,
        WithdrawalCredentials,
        // Not to be confused with the validator's balance (effective balance capped at 32ETH)
        EffectiveBalance,
        Slashed,
        ActivationEligibilityEpoch,
        ActivationEpoch,
        ExitEpoch,
        WithdrawableEpoch
    }

    function _verifyBlockNumber(
        uint256 _blockNumber,
        bytes32[] memory _blockNumberProof,
        bytes32 _blockHeaderRoot
    ) internal pure {
        if (
            !SSZ.isValidMerkleBranch(
                SSZ.toLittleEndian(_blockNumber),
                EXECUTION_PAYLOAD_BLOCK_NUMBER_IDX,
                _blockNumberProof,
                _blockHeaderRoot
            )
        ) {
            revert InvalidBlockNumberProof();
        }
    }

    function _verifyBeaconStateRoot(
        BeaconStateRootProofInfo calldata _beaconStateRootProofInfo,
        bytes32 _blockHeaderRoot
    ) internal pure {
        if (
            !SSZ.isValidMerkleBranch(
                _beaconStateRootProofInfo.beaconStateRoot,
                BEACON_STATE_ROOT_IDX,
                _beaconStateRootProofInfo.beaconStateRootProof,
                _blockHeaderRoot
            )
        ) {
            revert InvalidBeaconStateRootProof();
        }
    }

    function _verifyProposerIndex(
        uint256 _proposerIndex,
        bytes32[] memory _proposerIndexProof,
        bytes32 _beaconBlockRoot
    ) internal pure {
        if (
            !SSZ.isValidMerkleBranch(
                SSZ.toLittleEndian(_proposerIndex),
                PROPOSER_INDEX_IDX,
                _proposerIndexProof,
                _beaconBlockRoot
            )
        ) {
            revert InvalidProposerIndexProof();
        }
    }

    function _verifyTargetBeaconBlockRoot(TargetBeaconBlockRootProofInfo calldata _targetBeaconBlockRootProofInfo, bytes32 _beaconStateRoot)
        internal
        pure
    {
        if (!SSZ.isValidMerkleBranch(
            _targetBeaconBlockRootProofInfo.targetBeaconBlockRoot,
            BASE_BEACON_BLOCK_ROOTS_IDX + _targetBeaconBlockRootProofInfo.targetSlot % SLOTS_PER_HISTORICAL_ROOT,
            _targetBeaconBlockRootProofInfo.targetBeaconBlockRootProof,
            _beaconStateRoot
        )) {
            revert InvalidTargetBeaconBlockProof();
        }
    }

    function _verifyTargetBeaconStateRoot(bytes32[] calldata _targetBeaconStateRootProof, uint256 _targetSlot, bytes32 _targetBeaconStateRoot, bytes32 _beaconStateRoot)
        internal
        pure
    {
        if (!SSZ.isValidMerkleBranch(
            _targetBeaconStateRoot,
            BASE_BEACON_STATE_ROOTS_IDX + _targetSlot % SLOTS_PER_HISTORICAL_ROOT,
            _targetBeaconStateRootProof,
            _beaconStateRoot
        )) {
            revert InvalidTargetBeaconStateProof();
        }
    }

    function _verifyGraffiti(bytes32 _graffiti, bytes32[] calldata _graffitiProof, bytes32 _blockHeaderRoot)
        internal
        pure
    {
        if (!SSZ.isValidMerkleBranch(
            _graffiti,
            GRAFFITI_IDX,
            _graffitiProof,
            _blockHeaderRoot
        )) {
            revert InvalidGraffitiProof();
        }
    }

    function _verifyValidatorRoot(
        BeaconStateRootProofInfo calldata _beaconStateRootProofInfo,
        ValidatorProofInfo calldata _validatorProofInfo,
        bytes32 _blockHeaderRoot
    ) internal pure {
        _verifyBeaconStateRoot(_beaconStateRootProofInfo, _blockHeaderRoot);

        _verifyValidatorRoot(_validatorProofInfo, _beaconStateRootProofInfo.beaconStateRoot);
    }

    function _verifyValidatorRoot(
        ValidatorProofInfo calldata _validatorProofInfo,
        bytes32 _beaconStateRoot
    ) internal pure {
        if (
            !SSZ.isValidMerkleBranch(
                _validatorProofInfo.validatorRoot,
                BASE_VALIDATOR_IDX + _validatorProofInfo.validatorIndex,
                _validatorProofInfo.validatorProof,
                _beaconStateRoot
            )
        ) {
            revert InvalidValidatorProof(_validatorProofInfo.validatorIndex);
        }
    }

    /// @notice Proves the gindex for the specified pubkey at _depositIndex
    function _verifyValidatorDeposited(
        uint256 _depositIndex,
        bytes32 _pubkeyHash,
        bytes32[] memory _depositedPubkeyProof,
        bytes32 _blockHeaderRoot
    ) internal pure {
        if (
            !SSZ.isValidMerkleBranch(
                _pubkeyHash,
                ((((BASE_DEPOSIT_IDX + _depositIndex) * 2) + 1) * 4) + 0,
                _depositedPubkeyProof,
                _blockHeaderRoot
            )
        ) {
            revert InvalidDepositProof(_pubkeyHash);
        }
    }

    /// @notice Proves the amount that a specified validator withdrew at _withdrawalIndex
    function _verifyValidatorWithdrawal(
        uint256 _withdrawalIndex,
        uint256 _validatorIndex,
        uint256 _amount,
        bytes32[] memory _withdrawalValidatorIndexProof,
        bytes32[] memory _withdrawalAmountProof,
        bytes32 _blockHeaderRoot
    ) internal pure {
        // 1) Verify the validator index
        if (!SSZ.isValidMerkleBranch(
            SSZ.toLittleEndian(_validatorIndex),
            ((BASE_WITHDRAWAL_IDX + _withdrawalIndex) * 4) + 1,
            _withdrawalValidatorIndexProof,
            _blockHeaderRoot
        )) {
            revert InvalidWithdrawalProofIndex(_validatorIndex);
        }
        // 2) Verify the amount withdrawn
        if (!SSZ.isValidMerkleBranch(
            SSZ.toLittleEndian(_amount),
            ((BASE_WITHDRAWAL_IDX + _withdrawalIndex) * 4) + 3,
            _withdrawalAmountProof,
            _blockHeaderRoot
        )) {
            revert InvalidWithdrawalProofAmount(_validatorIndex);
        }
    }

    /// @notice Proves the validator balance against the beacon state root
    /// @dev The validator balance is stored in a packed array of 4 64-bit integers, so we prove the combined balance at gindex (BASE_BALANCE_IDX + (validatorIndex / 4)
    function _verifyValidatorBalance(
        bytes32[] memory _balanceProof,
        uint256 _validatorIndex,
        bytes32 _combinedBalance,
        bytes32 _beaconStateRoot
    ) internal pure {
        if (
            !SSZ.isValidMerkleBranch(
                _combinedBalance,
                BASE_BALANCE_IDX + (_validatorIndex / 4),
                _balanceProof,
                _beaconStateRoot
            )
        ) {
            revert InvalidBalanceProof(_validatorIndex);
        }
    }

    /// @notice Proves a validator field against the validator root
    function _verifyValidatorField(
        bytes32 _validatorRoot,
        uint256 _validatorIndex,
        bytes32 _leaf,
        bytes32[] memory _validatorFieldProof,
        ValidatorField _field
    ) internal pure {
        if (
            !SSZ.isValidMerkleBranch(
                _leaf, _getFieldGIndex(_field), _validatorFieldProof, _validatorRoot
            )
        ) {
            revert InvalidValidatorFieldProof(_field, _validatorIndex);
        }
    }

    /// @notice Checks complete validator struct against validator root
    function _verifyCompleteValidatorStruct(
        bytes32 validatorRoot,
        uint256 validatorIndex,
        Validator calldata validatorData
    ) internal pure {
        bytes32 h1 =
            sha256(abi.encodePacked(validatorData.pubkeyHash, validatorData.withdrawalCredentials));
        bytes32 h2 = sha256(
            abi.encodePacked(
                SSZ.toLittleEndian(validatorData.effectiveBalance),
                SSZ.toLittleEndian(validatorData.slashed ? 1 : 0)
            )
        );
        bytes32 h3 = sha256(
            abi.encodePacked(
                SSZ.toLittleEndian(validatorData.activationEligibilityEpoch),
                SSZ.toLittleEndian(validatorData.activationEpoch)
            )
        );
        bytes32 h4 = sha256(
            abi.encodePacked(
                SSZ.toLittleEndian(validatorData.exitEpoch),
                SSZ.toLittleEndian(validatorData.withdrawableEpoch)
            )
        );

        bytes32 h5 = sha256(abi.encodePacked(h1, h2));
        bytes32 h6 = sha256(abi.encodePacked(h3, h4));
        bytes32 h7 = sha256(abi.encodePacked(h5, h6));

        if (h7 != validatorRoot) {
            revert InvalidCompleteValidatorProof(validatorIndex);
        }
    }

    /// @notice Proves the balance of a validator against combined balances array
    /// @return Validator balance
    function _proveValidatorBalance(
        uint256 _validatorIndex,
        bytes32 _beaconStateRoot,
        // Combined balances of 4 validators packed into same gindex
        bytes32 _combinedBalance,
        bytes32[] calldata _balanceProof
    ) internal pure returns (uint256) {
        _verifyValidatorBalance(_balanceProof, _validatorIndex, _combinedBalance, _beaconStateRoot);

        return _getBalanceFromCombinedBalance(_validatorIndex, _combinedBalance);
    }

    /// @notice Validator balances are stored in an array of 4 64-bit integers, we extract the validator's balance
    function _getBalanceFromCombinedBalance(uint256 _validatorIndex, bytes32 _combinedBalance)
        internal
        pure
        returns (uint256)
    {
        uint256 modBalance = _validatorIndex % 4;

        bytes32 mask = bytes32(0xFFFFFFFFFFFFFFFF << ((3 - modBalance) * 64));
        bytes32 leBytes = (_combinedBalance & mask) << (modBalance * 64);
        uint256 result = 0;
        for (uint256 i = 0; i < leBytes.length; i++) {
            result += uint256(uint8(leBytes[i])) * 2 ** (8 * i);
        }
        return result;
    }

    /// @notice Returns the gindex for a validator field
    function _getFieldGIndex(ValidatorField _field) internal pure returns (uint256) {
        if (_field == ValidatorField.Pubkey) {
            return VALIDATOR_FIELDS_LENGTH + PUBKEY_IDX;
        } else if (_field == ValidatorField.WithdrawalCredentials) {
            return VALIDATOR_FIELDS_LENGTH + WITHDRAWAL_CREDENTIALS_IDX;
        } else if (_field == ValidatorField.Slashed) {
            return VALIDATOR_FIELDS_LENGTH + SLASHED_IDX;
        } else if (_field == ValidatorField.ActivationEligibilityEpoch) {
            return VALIDATOR_FIELDS_LENGTH + ACTIVATION_ELIGIBILITY_EPOCH_IDX;
        } else if (_field == ValidatorField.ActivationEpoch) {
            return VALIDATOR_FIELDS_LENGTH + ACTIVATION_EPOCH_IDX;
        } else if (_field == ValidatorField.ExitEpoch) {
            return VALIDATOR_FIELDS_LENGTH + EXIT_EPOCH_IDX;
        } else {
            return VALIDATOR_FIELDS_LENGTH + WITHDRAWABLE_EPOCH_IDX;
        }
    }
}

/**
 *
 * @notice Verification of verifiable-random-function (VRF) proofs, following
 * @notice https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.3
 * @notice See https://eprint.iacr.org/2017/099.pdf for security proofs.
 *
 * @dev Bibliographic references:
 *
 * @dev Goldberg, et al., "Verifiable Random Functions (VRFs)", Internet Draft
 * @dev draft-irtf-cfrg-vrf-05, IETF, Aug 11 2019,
 * @dev https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05
 *
 * @dev Papadopoulos, et al., "Making NSEC5 Practical for DNSSEC", Cryptology
 * @dev ePrint Archive, Report 2017/099, https://eprint.iacr.org/2017/099.pdf
 * ****************************************************************************
 * @dev USAGE
 *
 * @dev The main entry point is randomValueFromVRFProof. See its docstring.
 * *************************f***************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is computationally indistinguishable to her from a uniform
 * @dev random sample from the output space.
 *
 * @dev The purpose of this contract is to perform that verification.
 * ****************************************************************************
 * @dev DESIGN NOTES
 *
 * @dev The VRF algorithm verified here satisfies the full uniqueness, full
 * @dev collision resistance, and full pseudo-randomness security properties.
 * @dev See "SECURITY PROPERTIES" below, and
 * @dev https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-3
 *
 * @dev An elliptic curve point is generally represented in the solidity code
 * @dev as a uint256[2], corresponding to its affine coordinates in
 * @dev GF(FIELD_SIZE).
 *
 * @dev For the sake of efficiency, this implementation deviates from the spec
 * @dev in some minor ways:
 *
 * @dev - Keccak hash rather than the SHA256 hash recommended in
 * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.5
 * @dev   Keccak costs much less gas on the EVM, and provides similar security.
 *
 * @dev - Secp256k1 curve instead of the P-256 or ED25519 curves recommended in
 * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.5
 * @dev   For curve-point multiplication, it's much cheaper to abuse ECRECOVER
 *
 * @dev - hashToCurve recursively hashes until it finds a curve x-ordinate. On
 * @dev   the EVM, this is slightly more efficient than the recommendation in
 * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.4.1.1
 * @dev   step 5, to concatenate with a nonce then hash, and rehash with the
 * @dev   nonce updated until a valid x-ordinate is found.
 *
 * @dev - hashToCurve does not include a cipher version string or the byte 0x1
 * @dev   in the hash message, as recommended in step 5.B of the draft
 * @dev   standard. They are unnecessary here because no variation in the
 * @dev   cipher suite is allowed.
 *
 * @dev - Similarly, the hash input in scalarFromCurvePoints does not include a
 * @dev   commitment to the cipher suite, either, which differs from step 2 of
 * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.4.3
 * @dev   . Also, the hash input is the concatenation of the uncompressed
 * @dev   points, not the compressed points as recommended in step 3.
 *
 * @dev - In the calculation of the challenge value "c", the "u" value (i.e.
 * @dev   the value computed by Reggie as the nonce times the secp256k1
 * @dev   generator point, see steps 5 and 7 of
 * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.3
 * @dev   ) is replaced by its ethereum address, i.e. the lower 160 bits of the
 * @dev   keccak hash of the original u. This is because we only verify the
 * @dev   calculation of u up to its address, by abusing ECRECOVER.
 * ****************************************************************************
 * @dev   SECURITY PROPERTIES
 *
 * @dev Here are the security properties for this VRF:
 *
 * @dev Full uniqueness: For any seed and valid VRF public key, there is
 * @dev   exactly one VRF output which can be proved to come from that seed, in
 * @dev   the sense that the proof will pass verifyVRFProof.
 *
 * @dev Full collision resistance: It's cryptographically infeasible to find
 * @dev   two seeds with same VRF output from a fixed, valid VRF key
 *
 * @dev Full pseudorandomness: Absent the proofs that the VRF outputs are
 * @dev   derived from a given seed, the outputs are computationally
 * @dev   indistinguishable from randomness.
 *
 * @dev https://eprint.iacr.org/2017/099.pdf, Appendix B contains the proofs
 * @dev for these properties.
 *
 * @dev For secp256k1, the key validation described in section
 * @dev https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.6
 * @dev is unnecessary, because secp256k1 has cofactor 1, and the
 * @dev representation of the public key used here (affine x- and y-ordinates
 * @dev of the secp256k1 point on the standard y^2=x^3+7 curve) cannot refer to
 * @dev the point at infinity.
 * ****************************************************************************
 * @dev OTHER SECURITY CONSIDERATIONS
 *
 * @dev The seed input to the VRF could in principle force an arbitrary amount
 * @dev of work in hashToCurve, by requiring extra rounds of hashing and
 * @dev checking whether that's yielded the x ordinate of a secp256k1 point.
 * @dev However, under the Random Oracle Model the probability of choosing a
 * @dev point which forces n extra rounds in hashToCurve is 2⁻ⁿ. The base cost
 * @dev for calling hashToCurve is about 25,000 gas, and each round of checking
 * @dev for a valid x ordinate costs about 15,555 gas, so to find a seed for
 * @dev which hashToCurve would cost more than 2,017,000 gas, one would have to
 * @dev try, in expectation, about 2¹²⁸ seeds, which is infeasible for any
 * @dev foreseeable computational resources. (25,000 + 128 * 15,555 < 2,017,000.)
 *
 * @dev Since the gas block limit for the Ethereum main net is 10,000,000 gas,
 * @dev this means it is infeasible for an adversary to prevent correct
 * @dev operation of this contract by choosing an adverse seed.
 *
 * @dev (See TestMeasureHashToCurveGasCost for verification of the gas cost for
 * @dev hashToCurve.)
 *
 * @dev It may be possible to make a secure constant-time hashToCurve function.
 * @dev See notes in hashToCurve docstring.
 */
contract VRF {
    // See https://www.secg.org/sec2-v2.pdf, section 2.4.1, for these constants.
    // Number of points in Secp256k1
    uint256 private constant GROUP_ORDER = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
    // Prime characteristic of the galois field over which Secp256k1 is defined
    uint256 private constant FIELD_SIZE =
    // solium-disable-next-line indentation
     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
    uint256 private constant WORD_LENGTH_BYTES = 0x20;

    // (base^exponent) % FIELD_SIZE
    // Cribbed from https://medium.com/@rbkhmrcr/precompiles-solidity-e5d29bd428c4
    function bigModExp(uint256 base, uint256 exponent) internal view returns (uint256 exponentiation) {
        uint256 callResult;
        uint256[6] memory bigModExpContractInputs;
        bigModExpContractInputs[0] = WORD_LENGTH_BYTES; // Length of base
        bigModExpContractInputs[1] = WORD_LENGTH_BYTES; // Length of exponent
        bigModExpContractInputs[2] = WORD_LENGTH_BYTES; // Length of modulus
        bigModExpContractInputs[3] = base;
        bigModExpContractInputs[4] = exponent;
        bigModExpContractInputs[5] = FIELD_SIZE;
        uint256[1] memory output;
        assembly {
            // solhint-disable-line no-inline-assembly
            callResult :=
                staticcall(
                    not(0), // Gas cost: no limit
                    0x05, // Bigmodexp contract address
                    bigModExpContractInputs,
                    0xc0, // Length of input segment: 6*0x20-bytes
                    output,
                    0x20 // Length of output segment
                )
        }
        if (callResult == 0) {
            revert("bigModExp failure!");
        }
        return output[0];
    }

    // Let q=FIELD_SIZE. q % 4 = 3, ∴ x≡r^2 mod q ⇒ x^SQRT_POWER≡±r mod q.  See
    // https://en.wikipedia.org/wiki/Modular_square_root#Prime_or_prime_power_modulus
    uint256 private constant SQRT_POWER = (FIELD_SIZE + 1) >> 2;

    // Computes a s.t. a^2 = x in the field. Assumes a exists
    function squareRoot(uint256 x) internal view returns (uint256) {
        return bigModExp(x, SQRT_POWER);
    }

    // The value of y^2 given that (x,y) is on secp256k1.
    function ySquared(uint256 x) internal pure returns (uint256) {
        // Curve is y^2=x^3+7. See section 2.4.1 of https://www.secg.org/sec2-v2.pdf
        uint256 xCubed = mulmod(x, mulmod(x, x, FIELD_SIZE), FIELD_SIZE);
        return addmod(xCubed, 7, FIELD_SIZE);
    }

    // True iff p is on secp256k1
    function isOnCurve(uint256[2] memory p) internal pure returns (bool) {
        // Section 2.3.6. in https://www.secg.org/sec1-v2.pdf
        // requires each ordinate to be in [0, ..., FIELD_SIZE-1]
        require(p[0] < FIELD_SIZE, "invalid x-ordinate");
        require(p[1] < FIELD_SIZE, "invalid y-ordinate");
        return ySquared(p[0]) == mulmod(p[1], p[1], FIELD_SIZE);
    }

    // Hash x uniformly into {0, ..., FIELD_SIZE-1}.
    function fieldHash(bytes memory b) internal pure returns (uint256 x_) {
        x_ = uint256(keccak256(b));
        // Rejecting if x >= FIELD_SIZE corresponds to step 2.1 in section 2.3.4 of
        // http://www.secg.org/sec1-v2.pdf , which is part of the definition of
        // string_to_point in the IETF draft
        while (x_ >= FIELD_SIZE) {
            x_ = uint256(keccak256(abi.encodePacked(x_)));
        }
    }

    // Hash b to a random point which hopefully lies on secp256k1. The y ordinate
    // is always even, due to
    // https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.4.1.1
    // step 5.C, which references arbitrary_string_to_point, defined in
    // https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.5 as
    // returning the point with given x ordinate, and even y ordinate.
    function newCandidateSecp256k1Point(bytes memory b) internal view returns (uint256[2] memory p) {
        unchecked {
            p[0] = fieldHash(b);
            p[1] = squareRoot(ySquared(p[0]));
            if (p[1] % 2 == 1) {
                // Note that 0 <= p[1] < FIELD_SIZE
                // so this cannot wrap, we use unchecked to save gas.
                p[1] = FIELD_SIZE - p[1];
            }
        }
    }

    // Domain-separation tag for initial hash in hashToCurve. Corresponds to
    // vrf.go/hashToCurveHashPrefix
    uint256 internal constant HASH_TO_CURVE_HASH_PREFIX = 1;

    // Cryptographic hash function onto the curve.
    //
    // Corresponds to algorithm in section 5.4.1.1 of the draft standard. (But see
    // DESIGN NOTES above for slight differences.)
    //
    // TODO(alx): Implement a bounded-computation hash-to-curve, as described in
    // "Construction of Rational Points on Elliptic Curves over Finite Fields"
    // http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.831.5299&rep=rep1&type=pdf
    // and suggested by
    // https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-hash-to-curve-01#section-5.2.2
    // (Though we can't used exactly that because secp256k1's j-invariant is 0.)
    //
    // This would greatly simplify the analysis in "OTHER SECURITY CONSIDERATIONS"
    // https://www.pivotaltracker.com/story/show/171120900
    function hashToCurve(uint256[2] memory pk, uint256 input) internal view returns (uint256[2] memory rv) {
        rv = newCandidateSecp256k1Point(abi.encodePacked(HASH_TO_CURVE_HASH_PREFIX, pk, input));
        while (!isOnCurve(rv)) {
            rv = newCandidateSecp256k1Point(abi.encodePacked(rv[0]));
        }
    }

    /**
     *
     * @notice Check that product==scalar*multiplicand
     *
     * @dev Based on Vitalik Buterin's idea in ethresear.ch post cited below.
     *
     * @param multiplicand: secp256k1 point
     * @param scalar: non-zero GF(GROUP_ORDER) scalar
     * @param product: secp256k1 expected to be multiplier * multiplicand
     * @return verifies true iff product==scalar*multiplicand, with cryptographically high probability
     */
    function ecmulVerify(uint256[2] memory multiplicand, uint256 scalar, uint256[2] memory product)
        internal
        pure
        returns (bool verifies)
    {
        require(scalar != 0, "zero scalar"); // Rules out an ecrecover failure case
        uint256 x = multiplicand[0]; // x ordinate of multiplicand
        uint8 v = multiplicand[1] % 2 == 0 ? 27 : 28; // parity of y ordinate
        // https://ethresear.ch/t/you-can-kinda-abuse-ecrecover-to-do-ecmul-in-secp256k1-today/2384/9
        // Point corresponding to address ecrecover(0, v, x, s=scalar*x) is
        // (x⁻¹ mod GROUP_ORDER) * (scalar * x * multiplicand - 0 * g), i.e.
        // scalar*multiplicand. See https://crypto.stackexchange.com/a/18106
        bytes32 scalarTimesX = bytes32(mulmod(scalar, x, GROUP_ORDER));
        address actual = ecrecover(bytes32(0), v, bytes32(x), scalarTimesX);
        // Explicit conversion to address takes bottom 160 bits
        address expected = address(uint160(uint256(keccak256(abi.encodePacked(product)))));
        return (actual == expected);
    }

    // Returns x1/z1-x2/z2=(x1z2-x2z1)/(z1z2) in projective coordinates on P¹(𝔽ₙ)
    function projectiveSub(uint256 x1, uint256 z1, uint256 x2, uint256 z2)
        internal
        pure
        returns (uint256 x3, uint256 z3)
    {
        unchecked {
            uint256 num1 = mulmod(z2, x1, FIELD_SIZE);
            // Note this cannot wrap since x2 is a point in [0, FIELD_SIZE-1]
            // we use unchecked to save gas.
            uint256 num2 = mulmod(FIELD_SIZE - x2, z1, FIELD_SIZE);
            (x3, z3) = (addmod(num1, num2, FIELD_SIZE), mulmod(z1, z2, FIELD_SIZE));
        }
    }

    // Returns x1/z1*x2/z2=(x1x2)/(z1z2), in projective coordinates on P¹(𝔽ₙ)
    function projectiveMul(uint256 x1, uint256 z1, uint256 x2, uint256 z2)
        internal
        pure
        returns (uint256 x3, uint256 z3)
    {
        (x3, z3) = (mulmod(x1, x2, FIELD_SIZE), mulmod(z1, z2, FIELD_SIZE));
    }

    /**
     *
     *     @notice Computes elliptic-curve sum, in projective co-ordinates
     *
     *     @dev Using projective coordinates avoids costly divisions
     *
     *     @dev To use this with p and q in affine coordinates, call
     *     @dev projectiveECAdd(px, py, qx, qy). This will return
     *     @dev the addition of (px, py, 1) and (qx, qy, 1), in the
     *     @dev secp256k1 group.
     *
     *     @dev This can be used to calculate the z which is the inverse to zInv
     *     @dev in isValidVRFOutput. But consider using a faster
     *     @dev re-implementation such as ProjectiveECAdd in the golang vrf package.
     *
     *     @dev This function assumes [px,py,1],[qx,qy,1] are valid projective
     *          coordinates of secp256k1 points. That is safe in this contract,
     *          because this method is only used by linearCombination, which checks
     *          points are on the curve via ecrecover.
     *
     *     @param px The first affine coordinate of the first summand
     *     @param py The second affine coordinate of the first summand
     *     @param qx The first affine coordinate of the second summand
     *     @param qy The second affine coordinate of the second summand
     *
     *     (px,py) and (qx,qy) must be distinct, valid secp256k1 points.
     *
     *     Return values are projective coordinates of [px,py,1]+[qx,qy,1] as points
     *     on secp256k1, in P²(𝔽ₙ)
     *     @return sx
     *     @return sy
     *     @return sz
     */
    function projectiveECAdd(uint256 px, uint256 py, uint256 qx, uint256 qy)
        internal
        pure
        returns (uint256 sx, uint256 sy, uint256 sz)
    {
        unchecked {
            // See "Group law for E/K : y^2 = x^3 + ax + b", in section 3.1.2, p. 80,
            // "Guide to Elliptic Curve Cryptography" by Hankerson, Menezes and Vanstone
            // We take the equations there for (sx,sy), and homogenize them to
            // projective coordinates. That way, no inverses are required, here, and we
            // only need the one inverse in affineECAdd.

            // We only need the "point addition" equations from Hankerson et al. Can
            // skip the "point doubling" equations because p1 == p2 is cryptographically
            // impossible, and required not to be the case in linearCombination.

            // Add extra "projective coordinate" to the two points
            (uint256 z1, uint256 z2) = (1, 1);

            // (lx, lz) = (qy-py)/(qx-px), i.e., gradient of secant line.
            // Cannot wrap since px and py are in [0, FIELD_SIZE-1]
            uint256 lx = addmod(qy, FIELD_SIZE - py, FIELD_SIZE);
            uint256 lz = addmod(qx, FIELD_SIZE - px, FIELD_SIZE);

            uint256 dx; // Accumulates denominator from sx calculation
            // sx=((qy-py)/(qx-px))^2-px-qx
            (sx, dx) = projectiveMul(lx, lz, lx, lz); // ((qy-py)/(qx-px))^2
            (sx, dx) = projectiveSub(sx, dx, px, z1); // ((qy-py)/(qx-px))^2-px
            (sx, dx) = projectiveSub(sx, dx, qx, z2); // ((qy-py)/(qx-px))^2-px-qx

            uint256 dy; // Accumulates denominator from sy calculation
            // sy=((qy-py)/(qx-px))(px-sx)-py
            (sy, dy) = projectiveSub(px, z1, sx, dx); // px-sx
            (sy, dy) = projectiveMul(sy, dy, lx, lz); // ((qy-py)/(qx-px))(px-sx)
            (sy, dy) = projectiveSub(sy, dy, py, z1); // ((qy-py)/(qx-px))(px-sx)-py

            if (dx != dy) {
                // Cross-multiply to put everything over a common denominator
                sx = mulmod(sx, dy, FIELD_SIZE);
                sy = mulmod(sy, dx, FIELD_SIZE);
                sz = mulmod(dx, dy, FIELD_SIZE);
            } else {
                // Already over a common denominator, use that for z ordinate
                sz = dx;
            }
        }
    }

    // p1+p2, as affine points on secp256k1.
    //
    // invZ must be the inverse of the z returned by projectiveECAdd(p1, p2).
    // It is computed off-chain to save gas.
    //
    // p1 and p2 must be distinct, because projectiveECAdd doesn't handle
    // point doubling.
    function affineECAdd(uint256[2] memory p1, uint256[2] memory p2, uint256 invZ)
        internal
        pure
        returns (uint256[2] memory)
    {
        uint256 x;
        uint256 y;
        uint256 z;
        (x, y, z) = projectiveECAdd(p1[0], p1[1], p2[0], p2[1]);
        require(mulmod(z, invZ, FIELD_SIZE) == 1, "invZ must be inverse of z");
        // Clear the z ordinate of the projective representation by dividing through
        // by it, to obtain the affine representation
        return [mulmod(x, invZ, FIELD_SIZE), mulmod(y, invZ, FIELD_SIZE)];
    }

    // True iff address(c*p+s*g) == lcWitness, where g is generator. (With
    // cryptographically high probability.)
    function verifyLinearCombinationWithGenerator(uint256 c, uint256[2] memory p, uint256 s, address lcWitness)
        internal
        pure
        returns (bool)
    {
        // Rule out ecrecover failure modes which return address 0.
        unchecked {
            require(lcWitness != address(0), "bad witness");
            uint8 v = (p[1] % 2 == 0) ? 27 : 28; // parity of y-ordinate of p
            // Note this cannot wrap (X - Y % X), but we use unchecked to save
            // gas.
            bytes32 pseudoHash = bytes32(GROUP_ORDER - mulmod(p[0], s, GROUP_ORDER)); // -s*p[0]
            bytes32 pseudoSignature = bytes32(mulmod(c, p[0], GROUP_ORDER)); // c*p[0]
            // https://ethresear.ch/t/you-can-kinda-abuse-ecrecover-to-do-ecmul-in-secp256k1-today/2384/9
            // The point corresponding to the address returned by
            // ecrecover(-s*p[0],v,p[0],c*p[0]) is
            // (p[0]⁻¹ mod GROUP_ORDER)*(c*p[0]-(-s)*p[0]*g)=c*p+s*g.
            // See https://crypto.stackexchange.com/a/18106
            // https://bitcoin.stackexchange.com/questions/38351/ecdsa-v-r-s-what-is-v
            address computed = ecrecover(pseudoHash, v, bytes32(p[0]), pseudoSignature);
            return computed == lcWitness;
        }
    }

    // c*p1 + s*p2. Requires cp1Witness=c*p1 and sp2Witness=s*p2. Also
    // requires cp1Witness != sp2Witness (which is fine for this application,
    // since it is cryptographically impossible for them to be equal. In the
    // (cryptographically impossible) case that a prover accidentally derives
    // a proof with equal c*p1 and s*p2, they should retry with a different
    // proof nonce.) Assumes that all points are on secp256k1
    // (which is checked in verifyVRFProof below.)
    function linearCombination(
        uint256 c,
        uint256[2] memory p1,
        uint256[2] memory cp1Witness,
        uint256 s,
        uint256[2] memory p2,
        uint256[2] memory sp2Witness,
        uint256 zInv
    ) internal pure returns (uint256[2] memory) {
        unchecked {
            // Note we are relying on the wrap around here
            require((cp1Witness[0] % FIELD_SIZE) != (sp2Witness[0] % FIELD_SIZE), "points in sum must be distinct");
            require(ecmulVerify(p1, c, cp1Witness), "First mul check failed");
            require(ecmulVerify(p2, s, sp2Witness), "Second mul check failed");
            return affineECAdd(cp1Witness, sp2Witness, zInv);
        }
    }

    // Domain-separation tag for the hash taken in scalarFromCurvePoints.
    // Corresponds to scalarFromCurveHashPrefix in vrf.go
    uint256 internal constant SCALAR_FROM_CURVE_POINTS_HASH_PREFIX = 2;

    // Pseudo-random number from inputs. Matches vrf.go/scalarFromCurvePoints, and
    // https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.4.3
    // The draft calls (in step 7, via the definition of string_to_int, in
    // https://datatracker.ietf.org/doc/html/rfc8017#section-4.2 ) for taking the
    // first hash without checking that it corresponds to a number less than the
    // group order, which will lead to a slight bias in the sample.
    //
    // TODO(alx): We could save a bit of gas by following the standard here and
    // using the compressed representation of the points, if we collated the y
    // parities into a single bytes32.
    // https://www.pivotaltracker.com/story/show/171120588
    function scalarFromCurvePoints(
        uint256[2] memory hash,
        uint256[2] memory pk,
        uint256[2] memory gamma,
        address uWitness,
        uint256[2] memory v
    ) internal pure returns (uint256 s) {
        return uint256(keccak256(abi.encodePacked(SCALAR_FROM_CURVE_POINTS_HASH_PREFIX, hash, pk, gamma, v, uWitness)));
    }

    // True if (gamma, c, s) is a correctly constructed randomness proof from pk
    // and seed. zInv must be the inverse of the third ordinate from
    // projectiveECAdd applied to cGammaWitness and sHashWitness. Corresponds to
    // section 5.3 of the IETF draft.
    //
    // TODO(alx): Since I'm only using pk in the ecrecover call, I could only pass
    // the x ordinate, and the parity of the y ordinate in the top bit of uWitness
    // (which I could make a uint256 without using any extra space.) Would save
    // about 2000 gas. https://www.pivotaltracker.com/story/show/170828567
    function verifyVRFProof(
        uint256[2] memory pk,
        uint256[2] memory gamma,
        uint256 c,
        uint256 s,
        uint256 seed,
        address uWitness,
        uint256[2] memory cGammaWitness,
        uint256[2] memory sHashWitness,
        uint256 zInv
    ) internal view {
        unchecked {
            require(isOnCurve(pk), "public key is not on curve");
            require(isOnCurve(gamma), "gamma is not on curve");
            require(isOnCurve(cGammaWitness), "cGammaWitness is not on curve");
            require(isOnCurve(sHashWitness), "sHashWitness is not on curve");
            // Step 5. of IETF draft section 5.3 (pk corresponds to 5.3's Y, and here
            // we use the address of u instead of u itself. Also, here we add the
            // terms instead of taking the difference, and in the proof construction in
            // vrf.GenerateProof, we correspondingly take the difference instead of
            // taking the sum as they do in step 7 of section 5.1.)
            require(verifyLinearCombinationWithGenerator(c, pk, s, uWitness), "addr(c*pk+s*g)!=_uWitness");
            // Step 4. of IETF draft section 5.3 (pk corresponds to Y, seed to alpha_string)
            uint256[2] memory hash = hashToCurve(pk, seed);
            // Step 6. of IETF draft section 5.3, but see note for step 5 about +/- terms
            uint256[2] memory v = linearCombination(c, gamma, cGammaWitness, s, hash, sHashWitness, zInv);
            // Steps 7. and 8. of IETF draft section 5.3
            uint256 derivedC = scalarFromCurvePoints(hash, pk, gamma, uWitness, v);
            require(c == derivedC, "invalid proof");
        }
    }

    // Domain-separation tag for the hash used as the final VRF output.
    // Corresponds to vrfRandomOutputHashPrefix in vrf.go
    uint256 internal constant VRF_RANDOM_OUTPUT_HASH_PREFIX = 3;

    struct Request {
        address sender;
        uint256 nonce;
        bytes32 oracleId;
        uint32 nbWords;
        uint16 requestConfirmations;
        uint32 callbackGasLimit;
        address callbackAddress;
        bytes4 callbackSelector;
        uint64 blockNumber;
    }

    struct Proof {
        uint256[2] pk;
        uint256[2] gamma;
        uint256 c;
        uint256 s;
        uint256 seed;
        address uWitness;
        uint256[2] cGammaWitness;
        uint256[2] sHashWitness;
        uint256 zInv;
    }

    /* ***************************************************************************
     * @notice Returns proof's output, if proof is valid. Otherwise reverts

     * @param proof vrf proof components
     * @param seed  seed used to generate the vrf output
     *
     * Throws if proof is invalid, otherwise:
     * @return output i.e., the random output implied by the proof
     * ***************************************************************************
     */
    function randomValueFromVRFProof(Proof memory proof, uint256 seed) internal view returns (uint256 output) {
        verifyVRFProof(
            proof.pk,
            proof.gamma,
            proof.c,
            proof.s,
            seed,
            proof.uWitness,
            proof.cGammaWitness,
            proof.sHashWitness,
            proof.zInv
        );
        output = uint256(keccak256(abi.encode(VRF_RANDOM_OUTPUT_HASH_PREFIX, proof.gamma)));
    }
}

interface IVRFCoordinator {
    event RequestRandomWords(
        bytes32 requestId,
        address sender,
        uint256 nonce,
        bytes32 oracleId,
        uint32 nbWords,
        uint16 requestConfirmations,
        uint32 callbackGasLimit,
        address callbackAddress,
        bytes4 callbackSelector
    );
    event FulfillRandomWords(bytes32 requestId);

    error InvalidRequestConfirmations();
    error InvalidCallbackGasLimit();
    error InvalidNumberOfWords();
    error InvalidOracleId();
    error InvalidCommitment();
    error InvalidRequestParameters();
    error FailedToFulfillRandomness();

    function requestRandomWords(
        bytes32 _oracleId,
        uint32 _nbWords,
        uint16 _requestConfirmations,
        uint32 _callbackGasLimit,
        address _callbackAddress,
        bytes4 _callbackSelector
    ) external returns (bytes32);

    function fulfillRandomWords(
        VRF.Proof memory _proof,
        VRF.Request memory _request
    ) external;
}

contract NounsGraffitiOracle {
    ILightClient lightclient;
    address owner;

    bytes32 public constant ORACLE_ID = bytes32(hex"8e8d1df6c3c3e29a24c7a114ded0000e32f8f40414d3ab3a830f735a3553e18e");

    event ContainsNoggles(bytes32 graffiti, uint256 slot);

    error InvalidLightClientAddress();
    error InvalidBlockHeaderRoot();
    error InvalidNoggles(bytes32 graffiti, bytes32 graffitiNoggles);
    error SlotTooFar();

    error SlotTooLowForRaffle();
    error SlotAlreadyProven();

    error RaffleAlreadyDisbursed();

    /// @notice Mapping from slot proposed to the proposer validator index
    mapping(uint256 => uint256) public slotToProposerIndex;

    /// @notice Proposer index to payout address (feeRecipient or withdrawalAddress)
    mapping(uint256 => address) public proposerIndexToPayoutAddress;

    /// @notice Valid slots with noggles
    uint256[] public noggleSlots;

    /// @notice VRF Coordinator
    IVRFCoordinator public vrfCoordinator;

    /// @notice Current raffle number
    uint256 public raffleNumber;

    /// @notice Starting slot for raffle
    uint256 public raffleStartSlot;

    /// @notice Number of winners for raffle
    uint32 public numWinners;

    /// @notice Payout amount for raffle
    uint256 public payoutAmount;

    /// @notice Number of request confirmations
    uint16 public constant NUM_REQUEST_CONFIRMATIONS = 0;

    /// @notice Callback gas limit
    uint32 public constant CALLBACK_GAS_LIMIT = 100000;

    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256[] randomWords;
    }

    enum RaffleStatus {
        Started,
        Ended,
        Disbursed
    }

    // Map VRF request ID to raffle number
    mapping (bytes32 => uint256) public requestIdToRaffleNumber;

    // Map raffle number to request status
    mapping (uint256 => RequestStatus) public raffleRequests;

    // Map raffle number to list of winners (validatorIndices)
    mapping (uint256 => uint256[]) public raffleWinners;

    // Map raffle number to raffle status
    mapping (uint256 => RaffleStatus) public raffleStatus;

    modifier onlyVRFCoordinator {
        require(msg.sender == address(vrfCoordinator), "Only VRFCoordinator can call this function");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(address _lightClient, address _vrfCoordinator, address _owner, uint256 _raffleStartSlot) {
        if (_lightClient == address(0)) {
            revert InvalidLightClientAddress();
        }
        lightclient = ILightClient(_lightClient);
        vrfCoordinator = IVRFCoordinator(_vrfCoordinator);
        owner = _owner;
        raffleNumber = 0;
        raffleStatus[raffleNumber] = RaffleStatus.Started;
        numWinners = 10;
        payoutAmount = 1 ether;
        raffleStartSlot = _raffleStartSlot;
    }

    function setNumberWinners(uint32 _numWinners) external onlyOwner {
        numWinners = _numWinners;
    }

    function setPayoutAmount(uint256 _payoutAmount) external onlyOwner {
        payoutAmount = _payoutAmount;
    }

    function getProposerIndexForSlot(uint256 _slot) external view returns (uint256) {
        return slotToProposerIndex[_slot];
    }

    function getRaffleWinners(uint256 _raffleNumber) external view returns (uint256[] memory) {
        return raffleWinners[_raffleNumber];
    }

    /*
    ** Raffle functions
    */

    // Should after all noggles graffiti proposers have been proven
    // currentSlot should be greater than all proven slots
    function startRaffle(uint256 currentSlot) external onlyOwner {
        if (raffleRequests[raffleNumber].exists) {
            revert("Already requested random words for this raffle");
        }
        bytes32 requestId = vrfCoordinator.requestRandomWords(ORACLE_ID, numWinners, NUM_REQUEST_CONFIRMATIONS, CALLBACK_GAS_LIMIT, address(this), this.fulfillRaffle.selector);
        requestIdToRaffleNumber[requestId] = raffleNumber;
        raffleRequests[raffleNumber] = RequestStatus({
            fulfilled: false,
            exists: true,
            randomWords: new uint256[](0)
        });

        // Update raffle start slot to the next slot
        raffleStartSlot = currentSlot;
    }

    // Callback from VRF coordinator
    function fulfillRaffle(bytes32 requestId, uint256[] memory randomWords) external onlyVRFCoordinator {
        if (!raffleRequests[requestIdToRaffleNumber[requestId]].exists) {
            revert("This raffle does not exist (VRF Coordinator)");
        }
        raffleRequests[raffleNumber].fulfilled = true;
        raffleRequests[raffleNumber].randomWords = randomWords;

        uint256[] memory winners = new uint256[](randomWords.length);

        for (uint256 i = 0; i < randomWords.length; i++) {
            // Index of slot that won raffle
            uint256 winningSlotIdx = randomWords[i] % noggleSlots.length;
            uint256 winningSlot = noggleSlots[winningSlotIdx];

            winners[i] = slotToProposerIndex[winningSlot];
        }
        raffleStatus[raffleNumber] = RaffleStatus.Ended;
        raffleWinners[raffleNumber] = winners;

        // Reset raffle for next month
        raffleNumber++;
        raffleStatus[raffleNumber] = RaffleStatus.Started;
        for (uint256 i = 0; i < noggleSlots.length; i++) {
            delete slotToProposerIndex[noggleSlots[i]];
        }
        noggleSlots = new uint256[](0);
    }

    // Pay out the raffle winners
    function payoutRaffleWinners(uint256 raffleToPayout) public payable {
        if (raffleStatus[raffleToPayout] != RaffleStatus.Ended) {
            revert RaffleAlreadyDisbursed();
        }
        uint256[] memory winners = raffleWinners[raffleToPayout];
        for (uint256 i = 0; i < numWinners; i++) {
            address payoutAddress = proposerIndexToPayoutAddress[winners[i]];
            payable(payoutAddress).transfer(payoutAmount);
        }
        raffleStatus[raffleToPayout] = RaffleStatus.Disbursed;
    }

    /*
    ** Proving noggles graffiti
    */

    /// TODO: OnlyOwner can call this until we merkle prove payout address
    /// @notice Prove the graffiti from target slot contains ⌐◨-◨ (0xe28c90e297a82de297a8) & store corresponding validator index
    /// @dev Beacon state proof should correspond to a proved slot in the LC that is within 8192 slots of the target slot
    function proveGraffitiFromSlot(
        BeaconOracleHelper.BeaconStateRootProofInfo calldata _beaconStateRootProofInfo,
        BeaconOracleHelper.TargetBeaconBlockRootProofInfo calldata _targetBeaconBlockRootProofInfo,
        bytes32[] calldata _graffitiProof,
        bytes32 _graffiti,
        uint256 _graffitiStartIndex,
        bytes32[] calldata _proposerIndexProof,
        uint256 _proposerIndex,
        address _payoutAddress
    ) external onlyOwner {
        if (_targetBeaconBlockRootProofInfo.targetSlot < raffleStartSlot) {
            revert SlotTooLowForRaffle();
        }

        if (slotToProposerIndex[_targetBeaconBlockRootProofInfo.targetSlot] != 0) {
            revert SlotAlreadyProven();
        }

        if (_beaconStateRootProofInfo.slot -  BeaconOracleHelper.SLOTS_PER_HISTORICAL_ROOT > _targetBeaconBlockRootProofInfo.targetSlot) {
            revert SlotTooFar();
        }

        bytes32 blockHeaderRoot = ILightClient(lightclient).headers(_beaconStateRootProofInfo.slot);

        // Verify beacon state root against block header root
        BeaconOracleHelper._verifyBeaconStateRoot(_beaconStateRootProofInfo, blockHeaderRoot);

        // Verify target slot block root against beacon state root
        BeaconOracleHelper._verifyTargetBeaconBlockRoot(_targetBeaconBlockRootProofInfo, _beaconStateRootProofInfo.beaconStateRoot);

        proveNogglesGraffiti(
            _targetBeaconBlockRootProofInfo.targetSlot, _graffitiProof, _graffiti, _graffitiStartIndex, _targetBeaconBlockRootProofInfo.targetBeaconBlockRoot);

        // Verify the proposer index against target beacon block root
        BeaconOracleHelper._verifyProposerIndex(_proposerIndex, _proposerIndexProof, _targetBeaconBlockRootProofInfo.targetBeaconBlockRoot);

        slotToProposerIndex[_targetBeaconBlockRootProofInfo.targetSlot] = _proposerIndex;
        proposerIndexToPayoutAddress[_proposerIndex] = _payoutAddress;
        noggleSlots.push(_targetBeaconBlockRootProofInfo.targetSlot);
    }

    /// @notice Prove the graffiti contains ⌐◨-◨ (0xe28c90e297a82de297a8)
    /// @dev The block header root MUST be validated before calling this function
    function proveNogglesGraffiti(
        uint256 _slot,
        bytes32[] calldata _graffitiProof,
        bytes32 _graffiti,
        uint256 _graffitiStartIndex,
        bytes32 _blockHeaderRoot
    ) internal {
        BeaconOracleHelper._verifyGraffiti(
            _graffiti, _graffitiProof, _blockHeaderRoot
        );

        // Verify graffiti contains ⌐◨-◨ (0xe28c90e297a82de297a8) starting at _graffitiStartIndex
        _containsNoggles(_graffiti, _graffitiStartIndex);

        emit ContainsNoggles(_graffiti, _slot);
    }

    // Check that starting from _graffitiStartIndex, the graffiti contains ⌐◨-◨ (0xe28c90e297a82de297a8)
    function _containsNoggles(bytes32 _graffiti, uint256 _graffitiStartIndex) internal pure {
        // ⌐◨-◨
        bytes10 noggles = 0xe28c90e297a82de297a8;
        // Convert to bytes32
        bytes32 nogglesBytes32 = bytes32(noggles);

        if (_graffiti << (8 * _graffitiStartIndex) != nogglesBytes32) {
            revert InvalidNoggles(_graffiti << (8 * _graffitiStartIndex), nogglesBytes32);
        }
    }
}
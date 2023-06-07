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
    uint256 internal constant BEACON_STATE_ROOT_INDEX = 11;
    uint256 internal constant GRAFFITI_INDEX = 194;
    uint256 internal constant BASE_DEPOSIT_INDEX = 6336;
    uint256 internal constant BASE_WITHDRAWAL_INDEX = 103360;
    uint256 internal constant EXECUTION_PAYLOAD_BLOCK_NUMBER_INDEX = 3222;

    /// @notice Beacon state constants
    uint256 internal constant BASE_BEACON_BLOCK_ROOTS_INDEX = 303104;
    uint256 public constant SLOTS_PER_HISTORICAL_ROOT = 8192;

    /// @notice Validator proof constants
    uint256 internal constant BASE_VALIDATOR_INDEX = 94557999988736;
    uint256 internal constant VALIDATOR_FIELDS_LENGTH = 8;
    uint256 internal constant PUBKEY_INDEX = 0;
    uint256 internal constant WITHDRAWAL_CREDENTIALS_INDEX = 1;
    uint256 internal constant EFFECTIVE_BALANCE_INDEX = 2;
    uint256 internal constant SLASHED_INDEX = 3;
    uint256 internal constant ACTIVATION_ELIGIBILITY_EPOCH_INDEX = 4;
    uint256 internal constant ACTIVATION_EPOCH_INDEX = 5;
    uint256 internal constant EXIT_EPOCH_INDEX = 6;
    uint256 internal constant WITHDRAWABLE_EPOCH_INDEX = 7;

    /// @notice Balance constants
    uint256 internal constant BASE_BALANCE_INDEX = 24189255811072;

    /// @notice Errors
    // Beacon State Proof Errors
    error InvalidValidatorProof(uint256 validatorIndex);
    error InvalidCompleteValidatorProof(uint256 validatorIndex);
    error InvalidValidatorFieldProof(ValidatorField field, uint256 validatorIndex);
    error InvalidBalanceProof(uint256 validatorIndex);

    // Beacon Block Proof Errors
    error InvalidBeaconStateRootProof();
    error InvalidGraffitiProof();
    error InvalidBlockNumberProof();
    error InvalidDepositProof(bytes32 validatorPubkeyHash);
    error InvalidWithdrawalProofIndex(uint256 validatorIndex);
    error InvalidWithdrawalProofAmount(uint256 validatorIndex);

    struct BeaconStateRootProofInfo {
        uint256 slot;
        bytes32 beaconStateRoot;
        bytes32[] beaconStateRootProof;
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
                EXECUTION_PAYLOAD_BLOCK_NUMBER_INDEX,
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
                BEACON_STATE_ROOT_INDEX,
                _beaconStateRootProofInfo.beaconStateRootProof,
                _blockHeaderRoot
            )
        ) {
            revert InvalidBeaconStateRootProof();
        }
    }

    function _verifyOldBeaconBlockRoot(bytes32[] calldata _oldSlotBlockRootProof, uint256 _oldSlot, bytes32 _oldBlockHeaderRoot, bytes32 _beaconStateRoot)
        internal
        pure
    {
        if (!SSZ.isValidMerkleBranch(
            _oldBlockHeaderRoot,
            BASE_BEACON_BLOCK_ROOTS_INDEX + _oldSlot % SLOTS_PER_HISTORICAL_ROOT,
            _oldSlotBlockRootProof,
            _beaconStateRoot
        )) {
            revert InvalidGraffitiProof();
        }
    }

    function _verifyGraffiti(bytes32 _graffiti, bytes32[] calldata _graffitiProof, bytes32 _blockHeaderRoot)
        internal
        pure
    {
        if (!SSZ.isValidMerkleBranch(
            _graffiti,
            GRAFFITI_INDEX,
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
                BASE_VALIDATOR_INDEX + _validatorProofInfo.validatorIndex,
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
                ((((BASE_DEPOSIT_INDEX + _depositIndex) * 2) + 1) * 4) + 0,
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
            ((BASE_WITHDRAWAL_INDEX + _withdrawalIndex) * 4) + 1,
            _withdrawalValidatorIndexProof,
            _blockHeaderRoot
        )) {
            revert InvalidWithdrawalProofIndex(_validatorIndex);
        }
        // 2) Verify the amount withdrawn
        if (!SSZ.isValidMerkleBranch(
            SSZ.toLittleEndian(_amount),
            ((BASE_WITHDRAWAL_INDEX + _withdrawalIndex) * 4) + 3,
            _withdrawalAmountProof,
            _blockHeaderRoot
        )) {
            revert InvalidWithdrawalProofAmount(_validatorIndex);
        }
    }

    /// @notice Proves the validator balance against the beacon state root
    /// @dev The validator balance is stored in a packed array of 4 64-bit integers, so we prove the combined balance at gindex (BASE_BALANCE_INDEX + (validatorIndex / 4)
    function _verifyValidatorBalance(
        bytes32[] memory _balanceProof,
        uint256 _validatorIndex,
        bytes32 _combinedBalance,
        bytes32 _beaconStateRoot
    ) internal pure {
        if (
            !SSZ.isValidMerkleBranch(
                _combinedBalance,
                BASE_BALANCE_INDEX + (_validatorIndex / 4),
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
            return VALIDATOR_FIELDS_LENGTH + PUBKEY_INDEX;
        } else if (_field == ValidatorField.WithdrawalCredentials) {
            return VALIDATOR_FIELDS_LENGTH + WITHDRAWAL_CREDENTIALS_INDEX;
        } else if (_field == ValidatorField.Slashed) {
            return VALIDATOR_FIELDS_LENGTH + SLASHED_INDEX;
        } else if (_field == ValidatorField.ActivationEligibilityEpoch) {
            return VALIDATOR_FIELDS_LENGTH + ACTIVATION_ELIGIBILITY_EPOCH_INDEX;
        } else if (_field == ValidatorField.ActivationEpoch) {
            return VALIDATOR_FIELDS_LENGTH + ACTIVATION_EPOCH_INDEX;
        } else if (_field == ValidatorField.ExitEpoch) {
            return VALIDATOR_FIELDS_LENGTH + EXIT_EPOCH_INDEX;
        } else {
            return VALIDATOR_FIELDS_LENGTH + WITHDRAWABLE_EPOCH_INDEX;
        }
    }
}

contract NounsOracle {
    ILightClient lightclient;

    event ContainsNoggles(bytes32 graffiti, uint256 slot);

    error InvalidLightClientAddress();
    error InvalidNoggles(bytes32 graffiti, bytes32 graffitiNoggles);
    error SlotTooFar();

    /// @notice Mapping from slot to noggles graffiti
    mapping(uint256 => bytes32) public nogglesGraffiti;

    constructor(address _lightClient) {
        if (_lightClient == address(0)) {
            revert InvalidLightClientAddress();
        }
        lightclient = ILightClient(_lightClient);
    }

    /// @notice Prove the graffiti from a slot that already exists in the light client
    /// TODO: Should we revert if blockHeaderRoot does not exist in the LC?
    function proveGraffitiFromExistingSlot(
        uint256 _slot,
        bytes32[] calldata _graffitiProof,
        bytes32 _graffiti,
        uint256 _graffitiStartIndex
    ) external {
        bytes32 blockHeaderRoot = ILightClient(lightclient).headers(_slot);

        proveNogglesGraffiti(
            _slot, _graffitiProof, _graffiti, _graffitiStartIndex, blockHeaderRoot);
    }

    /// @notice Prove the graffiti from old slot contains ⌐◨-◨ (0xe28c90e297a82de297a8)
    /// @dev Beacon state proof should correspond to a proved slot in the LC that is within 8192 slots of the old slot
    function proveGraffitiFromSlot(
        BeaconOracleHelper.BeaconStateRootProofInfo calldata _beaconStateRootProofInfo,
        bytes32[] calldata _oldBlockHeaderRootProof,
        bytes32 _oldBlockHeaderRoot,
        uint256 _oldSlot,
        bytes32[] calldata _graffitiProof,
        bytes32 _graffiti,
        uint256 _graffitiStartIndex
    ) external {
        if (_beaconStateRootProofInfo.slot -  BeaconOracleHelper.SLOTS_PER_HISTORICAL_ROOT > _oldSlot) {
            revert SlotTooFar();
        }

        bytes32 blockHeaderRoot = ILightClient(lightclient).headers(_beaconStateRootProofInfo.slot);

        // Verify beacon state root against block header root
        BeaconOracleHelper._verifyBeaconStateRoot(_beaconStateRootProofInfo, blockHeaderRoot);

        // Verify old slot block root against beacon state root
        BeaconOracleHelper._verifyOldBeaconBlockRoot(_oldBlockHeaderRootProof, _oldSlot, _oldBlockHeaderRoot, _beaconStateRootProofInfo.beaconStateRoot);

        proveNogglesGraffiti(
            _oldSlot, _graffitiProof, _graffiti, _graffitiStartIndex, _oldBlockHeaderRoot);
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

        nogglesGraffiti[_slot] = _graffiti;

        emit ContainsNoggles(_graffiti, _slot);
    }

    function getGraffiti(uint256 _slot) external view returns (bytes32) {
        return nogglesGraffiti[_slot];
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
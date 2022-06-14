// SPDX-License-Identifier: GPL-3.0-or-later
//
// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

/// @title Configurable Anonymous Payments for Ethereum
/// CAPE provides auditable anonymous payments on Ethereum.
/// @author Espresso Systems <[email protected]>

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@rari-capital/solmate/src/utils/SafeTransferLib.sol";

import "solidity-bytes-utils/contracts/BytesLib.sol";
import "./libraries/AccumulatingArray.sol";
import "./libraries/EdOnBN254.sol";
import "./libraries/RescueLib.sol";
import "./libraries/VerifyingKeys.sol";
import "./interfaces/IPlonkVerifier.sol";
import "./interfaces/IRecordsMerkleTree.sol";
import "./AssetRegistry.sol";
import "./RootStore.sol";

contract CAPE is RootStore, AssetRegistry, ReentrancyGuard {
    using AccumulatingArray for AccumulatingArray.Data;

    mapping(uint256 => bool) public nullifiers;
    uint64 public blockHeight;
    IPlonkVerifier private _verifier;
    IRecordsMerkleTree internal _recordsMerkleTree;
    uint256[] public pendingDeposits;

    // NOTE: used for faucet in testnet only, will be removed for mainnet
    address public deployer;
    bool public faucetInitialized;

    bytes public constant CAPE_BURN_MAGIC_BYTES = "EsSCAPE burn";
    uint256 public constant CAPE_BURN_MAGIC_BYTES_SIZE = 12;
    // In order to avoid the contract running out of gas if the queue is too large
    // we set the maximum number of pending deposits record commitments to process
    // when a new block is submitted. This is a temporary solution.
    // See https://github.com/EspressoSystems/cape/issues/400
    uint256 public constant MAX_NUM_PENDING_DEPOSIT = 10;

    event FaucetInitialized(bytes roBytes);

    event BlockCommitted(
        uint64 indexed height,
        uint256[] depositCommitments,
        // What follows is a `CapeBlock` struct split up into fields.
        // This may no longer be necessary once
        // https://github.com/gakonst/ethers-rs/issues/1220
        // is fixed.
        bytes minerAddr,
        bytes noteTypes,
        bytes transferNotes,
        bytes mintNotes,
        bytes freezeNotes,
        bytes burnNotes
    );

    event Erc20TokensDeposited(bytes roBytes, address erc20TokenAddress, address from);

    struct AuditMemo {
        EdOnBN254.EdOnBN254Point ephemeralKey;
        uint256[] data;
    }

    enum NoteType {
        TRANSFER,
        MINT,
        FREEZE,
        BURN
    }

    struct TransferNote {
        uint256[] inputNullifiers;
        uint256[] outputCommitments;
        IPlonkVerifier.PlonkProof proof;
        AuditMemo auditMemo;
        TransferAuxInfo auxInfo;
    }

    struct BurnNote {
        TransferNote transferNote;
        RecordOpening recordOpening;
    }

    struct MintNote {
        /// nullifier for the input (i.e. transaction fee record)
        uint256 inputNullifier;
        /// output commitment for the fee change
        uint256 chgComm;
        /// output commitment for the minted asset
        uint256 mintComm;
        /// the amount of the minted asset
        uint128 mintAmount;
        /// the asset definition of the asset
        AssetDefinition mintAssetDef;
        /// Internal asset code
        uint256 mintInternalAssetCode;
        /// the validity proof of this note
        IPlonkVerifier.PlonkProof proof;
        /// memo for policy compliance specified for the designated auditor
        AuditMemo auditMemo;
        /// auxiliary information
        MintAuxInfo auxInfo;
    }

    struct FreezeNote {
        uint256[] inputNullifiers;
        uint256[] outputCommitments;
        IPlonkVerifier.PlonkProof proof;
        FreezeAuxInfo auxInfo;
    }

    struct TransferAuxInfo {
        uint256 merkleRoot;
        uint128 fee;
        uint64 validUntil;
        EdOnBN254.EdOnBN254Point txnMemoVerKey;
        bytes extraProofBoundData;
    }

    struct MintAuxInfo {
        uint256 merkleRoot;
        uint128 fee;
        EdOnBN254.EdOnBN254Point txnMemoVerKey;
    }

    struct FreezeAuxInfo {
        uint256 merkleRoot;
        uint128 fee;
        EdOnBN254.EdOnBN254Point txnMemoVerKey;
    }

    struct RecordOpening {
        uint128 amount;
        AssetDefinition assetDef;
        EdOnBN254.EdOnBN254Point userAddr;
        bytes32 encKey;
        bool freezeFlag;
        uint256 blind;
    }

    struct CapeBlock {
        EdOnBN254.EdOnBN254Point minerAddr;
        NoteType[] noteTypes;
        TransferNote[] transferNotes;
        MintNote[] mintNotes;
        FreezeNote[] freezeNotes;
        BurnNote[] burnNotes;
    }

    /// @notice CAPE contract constructor method.
    /// @param nRoots number of the most recent roots of the records merkle tree to be stored
    /// @param verifierAddr address of the Plonk Verifier contract
    constructor(
        uint64 nRoots,
        address verifierAddr,
        address recordsMerkleTreeAddr
    ) RootStore(nRoots) {
        _verifier = IPlonkVerifier(verifierAddr);
        _recordsMerkleTree = IRecordsMerkleTree(recordsMerkleTreeAddr);

        // NOTE: used for faucet in testnet only, will be removed for mainnet
        deployer = msg.sender;
    }

    /// @notice Allocate native token faucet to a manager. For testnet only.
    /// @param faucetManagerAddress address of public key of faucet manager for CAP native token (testnet only!)
    /// @param faucetManagerEncKey public key of faucet manager for CAP native token (testnet only!)
    function faucetSetupForTestnet(
        EdOnBN254.EdOnBN254Point memory faucetManagerAddress,
        bytes32 faucetManagerEncKey
    ) external {
        // faucet can only be set up once by the manager
        require(msg.sender == deployer, "Only invocable by deployer");
        require(!faucetInitialized, "Faucet already set up");

        // allocate maximum possible amount of native CAP token to faucet manager on testnet
        // max amount len is set to 63 bits: https://github.com/EspressoSystems/cap/blob/main/src/constants.rs#L50-L51
        RecordOpening memory ro = RecordOpening(
            type(uint128).max / 2,
            nativeDomesticAsset(),
            faucetManagerAddress,
            faucetManagerEncKey,
            false,
            0 // arbitrary blind factor
        );
        uint256[] memory recordCommitments = new uint256[](1);
        recordCommitments[0] = _deriveRecordCommitment(ro);

        // Insert the record into record accumulator.
        //
        // This is a call to our own contract, not an arbitrary external contract.
        // slither-disable-next-line reentrancy-no-eth
        _recordsMerkleTree.updateRecordsMerkleTree(recordCommitments);
        // slither-disable-next-line reentrancy-benign
        _addRoot(_recordsMerkleTree.getRootValue());

        // slither-disable-next-line reentrancy-events
        emit FaucetInitialized(abi.encode(ro));
        faucetInitialized = true;
    }

    /// @notice Publish an array of nullifiers.
    /// @dev Requires all nullifiers to be unique and unpublished.
    /// @dev A block creator must not submit notes with duplicate nullifiers.
    /// @param newNullifiers list of nullifiers to publish
    function _publish(uint256[] memory newNullifiers) internal {
        for (uint256 j = 0; j < newNullifiers.length; j++) {
            _publish(newNullifiers[j]);
        }
    }

    /// @notice Publish a nullifier if it hasn't been published before.
    /// @dev Reverts if the nullifier is already published.
    /// @param nullifier nullifier to publish
    function _publish(uint256 nullifier) internal {
        require(!nullifiers[nullifier], "Nullifier already published");
        nullifiers[nullifier] = true;
    }

    /// @notice Wraps ERC-20 tokens into a CAPE asset defined in the record opening.
    /// @param ro record opening that will be inserted in the records merkle tree once the deposit is validated
    /// @param erc20Address address of the ERC-20 token corresponding to the deposit
    function depositErc20(RecordOpening memory ro, address erc20Address) external nonReentrant {
        require(isCapeAssetRegistered(ro.assetDef), "Asset definition not registered");
        require(lookup(ro.assetDef) == erc20Address, "Wrong ERC20 address");

        // We skip the sanity checks mentioned in the rust specification as they are optional.
        if (pendingDeposits.length >= MAX_NUM_PENDING_DEPOSIT) {
            revert("Pending deposits queue is full");
        }
        pendingDeposits.push(_deriveRecordCommitment(ro));

        SafeTransferLib.safeTransferFrom(
            ERC20(erc20Address),
            msg.sender,
            address(this),
            ro.amount
        );

        emit Erc20TokensDeposited(abi.encode(ro), erc20Address, msg.sender);
    }

    /// @notice Submit a new block with extra data to the CAPE contract.
    /// @param newBlock block to be processed by the CAPE contract
    /// @param {bytes} extraData data to be stored in calldata; this data is ignored by the contract function
    function submitCapeBlockWithMemos(
        CapeBlock memory newBlock,
        bytes calldata /* extraData */
    ) external {
        submitCapeBlock(newBlock);
    }

    /// @notice Submit a new block to the CAPE contract.
    /// @dev Transactions are validated and the blockchain state is updated. Moreover *BURN* transactions trigger the unwrapping of cape asset records into erc20 tokens.
    /// @param newBlock block to be processed by the CAPE contract.
    function submitCapeBlock(CapeBlock memory newBlock) public nonReentrant {
        AccumulatingArray.Data memory commitments = AccumulatingArray.create(
            _computeNumCommitments(newBlock) + pendingDeposits.length
        );

        uint256 numNotes = newBlock.noteTypes.length;

        // Batch verify plonk proofs
        IPlonkVerifier.VerifyingKey[] memory vks = new IPlonkVerifier.VerifyingKey[](numNotes);
        uint256[][] memory publicInputs = new uint256[][](numNotes);
        IPlonkVerifier.PlonkProof[] memory proofs = new IPlonkVerifier.PlonkProof[](numNotes);
        bytes[] memory extraMsgs = new bytes[](numNotes);

        // Preserve the ordering of the (sub) arrays of notes.
        uint256 transferIdx = 0;
        uint256 mintIdx = 0;
        uint256 freezeIdx = 0;
        uint256 burnIdx = 0;

        for (uint256 i = 0; i < numNotes; i++) {
            NoteType noteType = newBlock.noteTypes[i];

            if (noteType == NoteType.TRANSFER) {
                TransferNote memory note = newBlock.transferNotes[transferIdx];
                transferIdx += 1;

                _checkContainsRoot(note.auxInfo.merkleRoot);
                _checkTransfer(note);
                require(!_isExpired(note), "Expired note");

                _publish(note.inputNullifiers);

                commitments.add(note.outputCommitments);

                (vks[i], publicInputs[i], proofs[i], extraMsgs[i]) = _prepareForProofVerification(
                    note
                );
            } else if (noteType == NoteType.MINT) {
                MintNote memory note = newBlock.mintNotes[mintIdx];
                mintIdx += 1;

                _checkContainsRoot(note.auxInfo.merkleRoot);
                _checkDomesticAssetCode(note.mintAssetDef.code, note.mintInternalAssetCode);

                _publish(note.inputNullifier);

                commitments.add(note.chgComm);
                commitments.add(note.mintComm);

                (vks[i], publicInputs[i], proofs[i], extraMsgs[i]) = _prepareForProofVerification(
                    note
                );
            } else if (noteType == NoteType.FREEZE) {
                FreezeNote memory note = newBlock.freezeNotes[freezeIdx];
                freezeIdx += 1;

                _checkContainsRoot(note.auxInfo.merkleRoot);

                _publish(note.inputNullifiers);

                commitments.add(note.outputCommitments);

                (vks[i], publicInputs[i], proofs[i], extraMsgs[i]) = _prepareForProofVerification(
                    note
                );
            } else if (noteType == NoteType.BURN) {
                BurnNote memory note = newBlock.burnNotes[burnIdx];
                burnIdx += 1;

                _checkContainsRoot(note.transferNote.auxInfo.merkleRoot);
                _checkBurn(note);

                _publish(note.transferNote.inputNullifiers);

                // Insert all the output commitments to the records merkle tree except from the second one (corresponding to the burned output)
                for (uint256 j = 0; j < note.transferNote.outputCommitments.length; j++) {
                    if (j != 1) {
                        commitments.add(note.transferNote.outputCommitments[j]);
                    }
                }

                (vks[i], publicInputs[i], proofs[i], extraMsgs[i]) = _prepareForProofVerification(
                    note
                );

                // Send the tokens
                _handleWithdrawal(note);
            } else {
                revert("Cape: unreachable!");
            }
        }

        // Skip the batch plonk verification if the block is empty
        if (numNotes > 0) {
            require(
                _verifier.batchVerify(vks, publicInputs, proofs, extraMsgs),
                "Cape: batch verify failed."
            );
        }

        // Process the pending deposits obtained after calling `depositErc20`
        for (uint256 i = 0; i < pendingDeposits.length; i++) {
            commitments.add(pendingDeposits[i]);
        }

        // Only update the merkle tree and add the root if the list of records commitments is non empty
        if (!commitments.isEmpty()) {
            // This is a call to our own contract, not an arbitrary external contract.
            // slither-disable-next-line reentrancy-no-eth
            _recordsMerkleTree.updateRecordsMerkleTree(commitments.items);
            // slither-disable-next-line reentrancy-benign
            _addRoot(_recordsMerkleTree.getRootValue());
        }

        // In all cases (the block is empty or not), the height is incremented.
        blockHeight += 1;

        // Inform clients about the new block and the processed deposits.
        // slither-disable-next-line reentrancy-events
        _emitBlockEvent(newBlock);

        // Empty the queue now that the record commitments have been inserted
        delete pendingDeposits;
    }

    /// @notice This function only exists to avoid a stack too deep compilation error.
    function _emitBlockEvent(CapeBlock memory newBlock) internal {
        emit BlockCommitted(
            blockHeight,
            pendingDeposits,
            abi.encode(newBlock.minerAddr),
            abi.encode(newBlock.noteTypes),
            abi.encode(newBlock.transferNotes),
            abi.encode(newBlock.mintNotes),
            abi.encode(newBlock.freezeNotes),
            abi.encode(newBlock.burnNotes)
        );
    }

    /// @dev send the ERC-20 tokens equivalent to the asset records being burnt. Recall that the burned record opening is contained inside the note.
    /// @param note note of type *BURN*
    function _handleWithdrawal(BurnNote memory note) internal {
        address ercTokenAddress = lookup(note.recordOpening.assetDef);

        // Extract recipient address
        address recipientAddress = BytesLib.toAddress(
            note.transferNote.auxInfo.extraProofBoundData,
            CAPE_BURN_MAGIC_BYTES_SIZE
        );
        SafeTransferLib.safeTransfer(
            ERC20(ercTokenAddress),
            recipientAddress,
            note.recordOpening.amount
        );
    }

    /// @dev Compute an upper bound on the number of records to be inserted
    function _computeNumCommitments(CapeBlock memory newBlock) internal pure returns (uint256) {
        // MintNote always has 2 commitments: mint_comm, chg_comm
        uint256 numComms = 2 * newBlock.mintNotes.length;
        for (uint256 i = 0; i < newBlock.transferNotes.length; i++) {
            numComms += newBlock.transferNotes[i].outputCommitments.length;
        }
        for (uint256 i = 0; i < newBlock.burnNotes.length; i++) {
            // Subtract one for the burn record commitment that is not inserted.
            // The function _containsBurnRecord checks that there are at least 2 output commitments.
            numComms += newBlock.burnNotes[i].transferNote.outputCommitments.length - 1;
        }
        for (uint256 i = 0; i < newBlock.freezeNotes.length; i++) {
            numComms += newBlock.freezeNotes[i].outputCommitments.length;
        }
        return numComms;
    }

    /// @dev Verify if a note is of type *TRANSFER*.
    /// @param note note which could be of type *TRANSFER* or *BURN*
    function _checkTransfer(TransferNote memory note) internal pure {
        require(
            !_containsBurnPrefix(note.auxInfo.extraProofBoundData),
            "Burn prefix in transfer note"
        );
    }

    /// @dev Check if a note has expired.
    /// @param note note for which we want to check its timestamp against the current block height
    function _isExpired(TransferNote memory note) internal view returns (bool) {
        return note.auxInfo.validUntil < blockHeight;
    }

    /// @dev Check if a burn note is well formed.
    /// @param note note of type *BURN*
    function _checkBurn(BurnNote memory note) internal view {
        bytes memory extra = note.transferNote.auxInfo.extraProofBoundData;
        require(_containsBurnPrefix(extra), "Bad burn tag");
        require(_containsBurnRecord(note), "Bad record commitment");
    }

    /// @dev Checks if a sequence of bytes contains hardcoded prefix.
    /// @param byteSeq sequence of bytes
    function _containsBurnPrefix(bytes memory byteSeq) internal pure returns (bool) {
        if (byteSeq.length < CAPE_BURN_MAGIC_BYTES_SIZE) {
            return false;
        }
        return
            BytesLib.equal(
                BytesLib.slice(byteSeq, 0, CAPE_BURN_MAGIC_BYTES_SIZE),
                CAPE_BURN_MAGIC_BYTES
            );
    }

    /// @dev Check if the burned record opening and the record commitment in position 1 are consistent.
    /// @param note note of type *BURN*
    function _containsBurnRecord(BurnNote memory note) internal view returns (bool) {
        if (note.transferNote.outputCommitments.length < 2) {
            return false;
        }
        uint256 rc = _deriveRecordCommitment(note.recordOpening);
        return rc == note.transferNote.outputCommitments[1];
    }

    /// @dev Compute the commitment of a record opening.
    /// @param ro record opening
    function _deriveRecordCommitment(RecordOpening memory ro) internal view returns (uint256 rc) {
        require(ro.assetDef.policy.revealMap < 2**12, "Reveal map exceeds 12 bits");

        // No overflow check, only 12 bits in reveal map
        uint256 revealMapAndFreezeFlag = 2 *
            ro.assetDef.policy.revealMap +
            (ro.freezeFlag ? 1 : 0);

        // blind in front of rest -> 13 elements, pad to 15 (5 x 3)
        uint256[15] memory inputs = [
            ro.blind,
            ro.amount,
            ro.assetDef.code,
            ro.userAddr.x,
            ro.userAddr.y,
            ro.assetDef.policy.auditorPk.x,
            ro.assetDef.policy.auditorPk.y,
            ro.assetDef.policy.credPk.x,
            ro.assetDef.policy.credPk.y,
            ro.assetDef.policy.freezerPk.x,
            ro.assetDef.policy.freezerPk.y,
            revealMapAndFreezeFlag,
            ro.assetDef.policy.revealThreshold,
            0,
            0
        ];

        return RescueLib.commit(inputs);
    }

    /// @dev An overloaded function (one for each note type) to prepare all inputs necessary for batch verification of the plonk proof.
    /// @param note note of type *TRANSFER*
    function _prepareForProofVerification(TransferNote memory note)
        internal
        view
        returns (
            IPlonkVerifier.VerifyingKey memory vk,
            uint256[] memory publicInput,
            IPlonkVerifier.PlonkProof memory proof,
            bytes memory transcriptInitMsg
        )
    {
        // load the correct (hardcoded) vk
        // slither-disable-next-line calls-loop
        vk = VerifyingKeys.getVkById(
            VerifyingKeys.getEncodedId(
                uint8(NoteType.TRANSFER),
                uint8(note.inputNullifiers.length),
                uint8(note.outputCommitments.length),
                uint8(_recordsMerkleTree.getHeight())
            )
        );
        // prepare public inputs
        // 4: root, native_asset_code, valid_until, fee
        // 2: audit_memo.ephemeral_key (x and y)
        publicInput = new uint256[](
            4 +
                note.inputNullifiers.length +
                note.outputCommitments.length +
                2 +
                note.auditMemo.data.length
        );
        publicInput[0] = note.auxInfo.merkleRoot;
        publicInput[1] = CAP_NATIVE_ASSET_CODE;
        publicInput[2] = note.auxInfo.validUntil;
        publicInput[3] = note.auxInfo.fee;
        {
            uint256 idx = 4;
            for (uint256 i = 0; i < note.inputNullifiers.length; i++) {
                publicInput[idx + i] = note.inputNullifiers[i];
            }
            idx += note.inputNullifiers.length;

            for (uint256 i = 0; i < note.outputCommitments.length; i++) {
                publicInput[idx + i] = note.outputCommitments[i];
            }
            idx += note.outputCommitments.length;

            publicInput[idx] = note.auditMemo.ephemeralKey.x;
            publicInput[idx + 1] = note.auditMemo.ephemeralKey.y;
            idx += 2;

            for (uint256 i = 0; i < note.auditMemo.data.length; i++) {
                publicInput[idx + i] = note.auditMemo.data[i];
            }
        }

        // extract out proof
        proof = note.proof;

        // prepare transcript init messages
        transcriptInitMsg = abi.encodePacked(
            EdOnBN254.serialize(note.auxInfo.txnMemoVerKey),
            note.auxInfo.extraProofBoundData
        );
    }

    /// @dev An overloaded function (one for each note type) to prepare all inputs necessary for batch verification of the plonk proof.
    /// @param note note of type *BURN*
    function _prepareForProofVerification(BurnNote memory note)
        internal
        view
        returns (
            IPlonkVerifier.VerifyingKey memory,
            uint256[] memory,
            IPlonkVerifier.PlonkProof memory,
            bytes memory
        )
    {
        return _prepareForProofVerification(note.transferNote);
    }

    /// @dev An overloaded function (one for each note type) to prepare all inputs necessary for batch verification of the plonk proof.
    /// @param note note of type *MINT*
    function _prepareForProofVerification(MintNote memory note)
        internal
        view
        returns (
            IPlonkVerifier.VerifyingKey memory vk,
            uint256[] memory publicInput,
            IPlonkVerifier.PlonkProof memory proof,
            bytes memory transcriptInitMsg
        )
    {
        // load the correct (hardcoded) vk
        // slither-disable-next-line calls-loop
        vk = VerifyingKeys.getVkById(
            VerifyingKeys.getEncodedId(
                uint8(NoteType.MINT),
                1, // num of input
                2, // num of output
                uint8(_recordsMerkleTree.getHeight())
            )
        );

        // prepare public inputs
        // 9: see below; 8: asset policy; rest: audit memo
        publicInput = new uint256[](9 + 8 + 2 + note.auditMemo.data.length);
        publicInput[0] = note.auxInfo.merkleRoot;
        publicInput[1] = CAP_NATIVE_ASSET_CODE;
        publicInput[2] = note.inputNullifier;
        publicInput[3] = note.auxInfo.fee;
        publicInput[4] = note.mintComm;
        publicInput[5] = note.chgComm;
        publicInput[6] = note.mintAmount;
        publicInput[7] = note.mintAssetDef.code;
        publicInput[8] = note.mintInternalAssetCode;

        publicInput[9] = note.mintAssetDef.policy.revealMap;
        publicInput[10] = note.mintAssetDef.policy.auditorPk.x;
        publicInput[11] = note.mintAssetDef.policy.auditorPk.y;
        publicInput[12] = note.mintAssetDef.policy.credPk.x;
        publicInput[13] = note.mintAssetDef.policy.credPk.y;
        publicInput[14] = note.mintAssetDef.policy.freezerPk.x;
        publicInput[15] = note.mintAssetDef.policy.freezerPk.y;
        publicInput[16] = note.mintAssetDef.policy.revealThreshold;

        {
            publicInput[17] = note.auditMemo.ephemeralKey.x;
            publicInput[18] = note.auditMemo.ephemeralKey.y;

            uint256 idx = 19;
            for (uint256 i = 0; i < note.auditMemo.data.length; i++) {
                publicInput[idx + i] = note.auditMemo.data[i];
            }
        }

        // extract out proof
        proof = note.proof;

        // prepare transcript init messages
        transcriptInitMsg = EdOnBN254.serialize(note.auxInfo.txnMemoVerKey);
    }

    /// @dev An overloaded function (one for each note type) to prepare all inputs necessary for batch verification of the plonk proof.
    /// @param note note of type *FREEZE*
    function _prepareForProofVerification(FreezeNote memory note)
        internal
        view
        returns (
            IPlonkVerifier.VerifyingKey memory vk,
            uint256[] memory publicInput,
            IPlonkVerifier.PlonkProof memory proof,
            bytes memory transcriptInitMsg
        )
    {
        // load the correct (hardcoded) vk
        // slither-disable-next-line calls-loop
        vk = VerifyingKeys.getVkById(
            VerifyingKeys.getEncodedId(
                uint8(NoteType.FREEZE),
                uint8(note.inputNullifiers.length),
                uint8(note.outputCommitments.length),
                uint8(_recordsMerkleTree.getHeight())
            )
        );

        // prepare public inputs
        publicInput = new uint256[](
            3 + note.inputNullifiers.length + note.outputCommitments.length
        );
        publicInput[0] = note.auxInfo.merkleRoot;
        publicInput[1] = CAP_NATIVE_ASSET_CODE;
        publicInput[2] = note.auxInfo.fee;
        {
            uint256 idx = 3;
            for (uint256 i = 0; i < note.inputNullifiers.length; i++) {
                publicInput[idx + i] = note.inputNullifiers[i];
            }
            idx += note.inputNullifiers.length;

            for (uint256 i = 0; i < note.outputCommitments.length; i++) {
                publicInput[idx + i] = note.outputCommitments[i];
            }
        }

        // extract out proof
        proof = note.proof;

        // prepare transcript init messages
        transcriptInitMsg = EdOnBN254.serialize(note.auxInfo.txnMemoVerKey);
    }

    function getRootValue() external view returns (uint256) {
        return _recordsMerkleTree.getRootValue();
    }
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
//
// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

/// @title AccumulatingArray library
/// @dev This library simplifies inserting elements into an array by keeping track
///      of the insertion index.

library AccumulatingArray {
    struct Data {
        uint256[] items;
        uint256 index;
    }

    /// @dev Create a new AccumulatingArray
    /// @param length the number of items that will be inserted
    function create(uint256 length) internal pure returns (Data memory) {
        return Data(new uint256[](length), 0);
    }

    /// @param items the items to accumulate
    /// @dev Will revert if items past length are added.
    function add(Data memory self, uint256[] memory items) internal pure {
        for (uint256 i = 0; i < items.length; i++) {
            self.items[i + self.index] = items[i];
        }
        self.index += items.length;
    }

    /// @param item the item to accumulate.
    /// @dev Will revert if items past length are added.
    function add(Data memory self, uint256 item) internal pure {
        self.items[self.index] = item;
        self.index += 1;
    }

    function isEmpty(Data memory self) internal pure returns (bool) {
        return (self.index == 0);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
//
// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import "../libraries/Utils.sol";

/// @notice Edward curve on BN254.
/// This library only implements a serialization function that is consistent with
/// Arkworks' format. It does not support any group operations.
library EdOnBN254 {
    uint256 public constant P_MOD =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    struct EdOnBN254Point {
        uint256 x;
        uint256 y;
    }

    /// @dev Check if y-coordinate of G1 point is negative.
    function isYNegative(EdOnBN254Point memory point) internal pure returns (bool) {
        return (point.y << 1) < P_MOD;
    }

    function serialize(EdOnBN254Point memory point) internal pure returns (bytes memory res) {
        uint256 mask = 0;
        // Edward curve does not have an infinity flag.
        // Set the 255-th bit to 1 for positive Y
        // See: https://github.com/arkworks-rs/algebra/blob/d6365c3a0724e5d71322fe19cbdb30f979b064c8/serialize/src/flags.rs#L148
        if (!EdOnBN254.isYNegative(point)) {
            mask = 0x8000000000000000000000000000000000000000000000000000000000000000;
        }

        return abi.encodePacked(Utils.reverseEndianness(point.x | mask));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
//
// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

library RescueLib {
    /// The constants are obtained from the Sage script
    /// https://github.com/EspressoSystems/Marvellous/blob/fcd4c41672f485ac2f62526bc87a16789d4d0459/rescue254.sage

    // These constants are no longer used, left here for readability.
    // uint256 private constant _N_ROUNDS = 12;
    // uint256 private constant _STATE_SIZE = 4;
    // uint256 private constant _SCHEDULED_KEY_SIZE = (2 * _N_ROUNDS + 1) * _STATE_SIZE;
    // uint256 private constant _ALPHA = 5;

    // Obtained by running KeyScheduling([0,0,0,0]). See Algorithm 2 of AT specification document.

    uint256 private constant _PRIME =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    uint256 private constant _ALPHA_INV =
        17510594297471420177797124596205820070838691520332827474958563349260646796493;

    // MDS is hardcoded
    function _linearOp(
        uint256 s0,
        uint256 s1,
        uint256 s2,
        uint256 s3
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        // Matrix multiplication
        unchecked {
            return (
                mulmod(
                    21888242871839275222246405745257275088548364400416034343698204186575808479992,
                    s0,
                    _PRIME
                ) +
                    mulmod(
                        21888242871839275222246405745257275088548364400416034343698204186575806058117,
                        s1,
                        _PRIME
                    ) +
                    mulmod(
                        21888242871839275222246405745257275088548364400416034343698204186575491214367,
                        s2,
                        _PRIME
                    ) +
                    mulmod(
                        21888242871839275222246405745257275088548364400416034343698204186535831058117,
                        s3,
                        _PRIME
                    ),
                mulmod(19500, s0, _PRIME) +
                    mulmod(3026375, s1, _PRIME) +
                    mulmod(393529500, s2, _PRIME) +
                    mulmod(49574560750, s3, _PRIME),
                mulmod(
                    21888242871839275222246405745257275088548364400416034343698204186575808491587,
                    s0,
                    _PRIME
                ) +
                    mulmod(
                        21888242871839275222246405745257275088548364400416034343698204186575807886437,
                        s1,
                        _PRIME
                    ) +
                    mulmod(
                        21888242871839275222246405745257275088548364400416034343698204186575729688812,
                        s2,
                        _PRIME
                    ) +
                    mulmod(
                        21888242871839275222246405745257275088548364400416034343698204186565891044437,
                        s3,
                        _PRIME
                    ),
                mulmod(156, s0, _PRIME) +
                    mulmod(20306, s1, _PRIME) +
                    mulmod(2558556, s2, _PRIME) +
                    mulmod(320327931, s3, _PRIME)
            );
        }
    }

    function _expAlphaInv4Setup(uint256[6] memory scratch) private pure {
        assembly {
            let p := scratch
            mstore(p, 0x20) // Length of Base
            mstore(add(p, 0x20), 0x20) // Length of Exponent
            mstore(add(p, 0x40), 0x20) // Length of Modulus
            mstore(add(p, 0x80), _ALPHA_INV) // Exponent
            mstore(add(p, 0xa0), _PRIME) // Modulus
        }
    }

    function _expAlphaInv4(
        uint256[6] memory scratch,
        uint256 s0,
        uint256 s1,
        uint256 s2,
        uint256 s3
    )
        private
        view
        returns (
            uint256 o0,
            uint256 o1,
            uint256 o2,
            uint256 o3
        )
    {
        assembly {
            // define pointer
            let p := scratch
            let basep := add(p, 0x60)
            mstore(basep, s0) // Base
            // store data assembly-favouring ways
            pop(staticcall(sub(gas(), 2000), 0x05, p, 0xc0, basep, 0x20))
            // data
            o0 := mload(basep)
            mstore(basep, s1) // Base
            pop(staticcall(sub(gas(), 2000), 0x05, p, 0xc0, basep, 0x20))
            // data
            o1 := mload(basep)
            mstore(basep, s2) // Base
            pop(staticcall(sub(gas(), 2000), 0x05, p, 0xc0, basep, 0x20))
            // data
            o2 := mload(basep)
            mstore(basep, s3) // Base
            pop(staticcall(sub(gas(), 2000), 0x05, p, 0xc0, basep, 0x20))
            // data
            o3 := mload(basep)
        }
    }

    // Computes the Rescue permutation on some input
    // Recall that the scheduled key is precomputed in our case
    // @param input input for the permutation
    // @return permutation output
    function perm(
        // slither-disable-next-line write-after-write
        uint256 s0,
        // slither-disable-next-line write-after-write
        uint256 s1,
        // slither-disable-next-line write-after-write
        uint256 s2,
        // slither-disable-next-line write-after-write
        uint256 s3
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        // slither-disable-next-line uninitialized-local
        uint256[6] memory alphaInvScratch;

        _expAlphaInv4Setup(alphaInvScratch);

        unchecked {
            (s0, s1, s2, s3) = _expAlphaInv4(
                alphaInvScratch,
                s0 + 14613516837064033601098425266946467918409544647446217386229959902054563533267,
                s1 + 376600575581954944138907282479272751264978206975465380433764825531344567663,
                s2 + 7549886658634274343394883631367643327196152481472281919735617268044202589860,
                s3 + 3682071510138521345600424597536598375718773365536872232193107639375194756918
            );
        }
        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            uint256 tmp = s0 +
                18657517374128716281071590782771170166993445602755371021955596036781411817786;
            s0 = mulmod(tmp, tmp, _PRIME);
            s0 = mulmod(s0, s0, _PRIME);
            s0 = mulmod(s0, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s1 +
                7833794394096838639430144230563403530989402760602204539559270044687522640191;
            s1 = mulmod(tmp, tmp, _PRIME);
            s1 = mulmod(s1, s1, _PRIME);
            s1 = mulmod(s1, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s2 +
                21303828694647266539931030987057572024333442749881970102454081226349775826204;
            s2 = mulmod(tmp, tmp, _PRIME);
            s2 = mulmod(s2, s2, _PRIME);
            s2 = mulmod(s2, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s3 +
                10601447988834057856019990466870413629636256450824419416829818546423193802418;
            s3 = mulmod(tmp, tmp, _PRIME);
            s3 = mulmod(s3, s3, _PRIME);
            s3 = mulmod(s3, tmp, _PRIME);
        }

        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            (s0, s1, s2, s3) = _expAlphaInv4(
                alphaInvScratch,
                s0 + 3394657260998945409283098835682964352503279447198495330506177586645995289229,
                s1 + 18437084083724939316390841967750487133622937044030373241106776324730657101302,
                s2 + 9281739916935170266925270432337475828741505406943764438550188362765269530037,
                s3 + 7363758719535652813463843693256839865026387361836644774317493432208443086206
            );
        }
        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            uint256 tmp = s0 +
                307094088106440279963968943984309088038734274328527845883669678290790702381;
            s0 = mulmod(tmp, tmp, _PRIME);
            s0 = mulmod(s0, s0, _PRIME);
            s0 = mulmod(s0, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s1 +
                20802277384865839022876847241719852837518994021170013346790603773477912819001;
            s1 = mulmod(tmp, tmp, _PRIME);
            s1 = mulmod(s1, s1, _PRIME);
            s1 = mulmod(s1, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s2 +
                19754579269464973651593381036132218829220609572271224048608091445854164824042;
            s2 = mulmod(tmp, tmp, _PRIME);
            s2 = mulmod(s2, s2, _PRIME);
            s2 = mulmod(s2, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s3 +
                3618840933841571232310395486452077846249117988789467996234635426899783130819;
            s3 = mulmod(tmp, tmp, _PRIME);
            s3 = mulmod(s3, s3, _PRIME);
            s3 = mulmod(s3, tmp, _PRIME);
        }

        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            (s0, s1, s2, s3) = _expAlphaInv4(
                alphaInvScratch,
                s0 + 2604166168648013711791424714498680546427073388134923208733633668316805639713,
                s1 + 21355705619901626246699129842094174300693414345856149669339147704587730744579,
                s2 + 492957643799044929042114590851019953669919577182050726596188173945730031352,
                s3 + 8495959434717951575638107349559891417392372124707619959558593515759091841138
            );
        }
        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            uint256 tmp = s0 +
                15608173629791582453867933160400609222904457931922627396107815347244961625587;
            s0 = mulmod(tmp, tmp, _PRIME);
            s0 = mulmod(s0, s0, _PRIME);
            s0 = mulmod(s0, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s1 +
                16346164988481725869223011419855264063160651334419415042919928342589111681923;
            s1 = mulmod(tmp, tmp, _PRIME);
            s1 = mulmod(s1, s1, _PRIME);
            s1 = mulmod(s1, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s2 +
                21085652277104054699752179865196164165969290053517659864117475352262716334100;
            s2 = mulmod(tmp, tmp, _PRIME);
            s2 = mulmod(s2, s2, _PRIME);
            s2 = mulmod(s2, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s3 +
                20640310021063232205677193759981403045043444605175178332133134865746039279935;
            s3 = mulmod(tmp, tmp, _PRIME);
            s3 = mulmod(s3, s3, _PRIME);
            s3 = mulmod(s3, tmp, _PRIME);
        }

        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            (s0, s1, s2, s3) = _expAlphaInv4(
                alphaInvScratch,
                s0 + 6015589261538006311719125697023069952804098656652050863009463360598997670240,
                s1 + 12498423882721726012743791752811798719201859023192663855805526312393108407357,
                s2 + 10785527781711732350693172404486938622378708235957779975342240483505724965040,
                s3 + 5563181134859229953817163002660048854420912281911747312557025480927280392569
            );
        }
        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            uint256 tmp = s0 +
                4585980485870975597083581718044393941512074846925247225127276913719050121968;
            s0 = mulmod(tmp, tmp, _PRIME);
            s0 = mulmod(s0, s0, _PRIME);
            s0 = mulmod(s0, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s1 +
                8135760428078872176830812746579993820254685977237403304445687861806698035222;
            s1 = mulmod(tmp, tmp, _PRIME);
            s1 = mulmod(s1, s1, _PRIME);
            s1 = mulmod(s1, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s2 +
                4525715538433244696411192727226186804883202134636681498489663161593606654720;
            s2 = mulmod(tmp, tmp, _PRIME);
            s2 = mulmod(s2, s2, _PRIME);
            s2 = mulmod(s2, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s3 +
                2537497100749435007113677475828631400227339157221711397900070636998427379023;
            s3 = mulmod(tmp, tmp, _PRIME);
            s3 = mulmod(s3, s3, _PRIME);
            s3 = mulmod(s3, tmp, _PRIME);
        }

        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            (s0, s1, s2, s3) = _expAlphaInv4(
                alphaInvScratch,
                s0 + 6957758175844522415482704083077249782181516476067074624906502033584870962925,
                s1 + 17134288156316028142861248367413235848595762718317063354217292516610545487813,
                s2 + 20912428573104312239411321877435657586184425249645076131891636094671938892815,
                s3 + 16000236205755938926858829908701623009580043315308207671921283074116709575629
            );
        }
        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            uint256 tmp = s0 +
                10226182617544046880850643054874064693998595520540061157646952229134207239372;
            s0 = mulmod(tmp, tmp, _PRIME);
            s0 = mulmod(s0, s0, _PRIME);
            s0 = mulmod(s0, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s1 +
                18584346134948015676264599354709457865255277240606855245909703396343731224626;
            s1 = mulmod(tmp, tmp, _PRIME);
            s1 = mulmod(s1, s1, _PRIME);
            s1 = mulmod(s1, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s2 +
                9263628039314899758000383385773954136696958567872461042004915206775147151562;
            s2 = mulmod(tmp, tmp, _PRIME);
            s2 = mulmod(s2, s2, _PRIME);
            s2 = mulmod(s2, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s3 +
                21095966719856094705113273596585696209808876361583941931684481364905087347856;
            s3 = mulmod(tmp, tmp, _PRIME);
            s3 = mulmod(s3, s3, _PRIME);
            s3 = mulmod(s3, tmp, _PRIME);
        }

        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            (s0, s1, s2, s3) = _expAlphaInv4(
                alphaInvScratch,
                s0 + 2671157351815122058649197205531097090514563992249109660044882868649840700911,
                s1 + 19371695134219415702961622134896564229962454573253508904477489696588594622079,
                s2 + 5458968308231210904289987830881528056037123818964633914555287871152343390175,
                s3 + 7336332584551233792026746889434554547883125466404119632794862500961953384162
            );
        }
        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            uint256 tmp = s0 +
                10351436748086126474964482623536554036637945319698748519226181145454116702488;
            s0 = mulmod(tmp, tmp, _PRIME);
            s0 = mulmod(s0, s0, _PRIME);
            s0 = mulmod(s0, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s1 +
                10588209357420186457766745724579739104572139534486480334142455690083813419064;
            s1 = mulmod(tmp, tmp, _PRIME);
            s1 = mulmod(s1, s1, _PRIME);
            s1 = mulmod(s1, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s2 +
                14330277147584936710957102218096795520430543834717433464500965846826655802131;
            s2 = mulmod(tmp, tmp, _PRIME);
            s2 = mulmod(s2, s2, _PRIME);
            s2 = mulmod(s2, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s3 +
                20752197679372238381408962682213349118865256502118746003818603260257076802028;
            s3 = mulmod(tmp, tmp, _PRIME);
            s3 = mulmod(s3, s3, _PRIME);
            s3 = mulmod(s3, tmp, _PRIME);
        }

        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            (s0, s1, s2, s3) = _expAlphaInv4(
                alphaInvScratch,
                s0 + 19390446529582160674621825412345750405397926216690583196542690617266028463414,
                s1 + 4169994013656329171830126793466321040216273832271989491631696813297571003664,
                s2 + 3014817248268674641565961681956715664833306954478820029563459099892548946802,
                s3 + 14285412497877984113655094566695921704826935980354186365694472961163628072901
            );
        }
        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            uint256 tmp = s0 +
                16224484149774307577146165975762490690838415946665379067259822320752729067513;
            s0 = mulmod(tmp, tmp, _PRIME);
            s0 = mulmod(s0, s0, _PRIME);
            s0 = mulmod(s0, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s1 +
                5404416528124718330316441408560295270695591369912905197499507811036327404407;
            s1 = mulmod(tmp, tmp, _PRIME);
            s1 = mulmod(s1, s1, _PRIME);
            s1 = mulmod(s1, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s2 +
                20127204244332635127213425090893250761286848618448128307344971109698523903374;
            s2 = mulmod(tmp, tmp, _PRIME);
            s2 = mulmod(s2, s2, _PRIME);
            s2 = mulmod(s2, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s3 +
                14939477686176063572999014162186372798386193194442661892600584389296609365740;
            s3 = mulmod(tmp, tmp, _PRIME);
            s3 = mulmod(s3, s3, _PRIME);
            s3 = mulmod(s3, tmp, _PRIME);
        }

        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            (s0, s1, s2, s3) = _expAlphaInv4(
                alphaInvScratch,
                s0 + 183740587182448242823071506013879595265109215202349952517434740768878294134,
                s1 + 15366166801397358994305040367078329374182896694582870542425225835844885654667,
                s2 + 10066796014802701613007252979619633540090232697942390802486559078446300507813,
                s3 + 4824035239925904398047276123907644574421550988870123756876333092498925242854
            );
        }
        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            uint256 tmp = s0 +
                5526416022516734657935645023952329824887761902324086126076396040056459740202;
            s0 = mulmod(tmp, tmp, _PRIME);
            s0 = mulmod(s0, s0, _PRIME);
            s0 = mulmod(s0, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s1 +
                18157816292703983306114736850721419851645159304249709756659476015594698876611;
            s1 = mulmod(tmp, tmp, _PRIME);
            s1 = mulmod(s1, s1, _PRIME);
            s1 = mulmod(s1, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s2 +
                767446206481623130855439732549764381286210118638028499466788453347759203223;
            s2 = mulmod(tmp, tmp, _PRIME);
            s2 = mulmod(s2, s2, _PRIME);
            s2 = mulmod(s2, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s3 +
                16303412231051555792435190427637047658258796056382698277687500021321460387129;
            s3 = mulmod(tmp, tmp, _PRIME);
            s3 = mulmod(s3, s3, _PRIME);
            s3 = mulmod(s3, tmp, _PRIME);
        }

        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            (s0, s1, s2, s3) = _expAlphaInv4(
                alphaInvScratch,
                s0 + 15475465085113677237835653765189267963435264152924949727326000496982746660612,
                s1 + 14574823710073720047190393602502575509282844662732045439760066078137662816054,
                s2 + 13746490178929963947720756220409862158443939172096620003896874772477437733602,
                s3 + 13804898145881881347835367366352189037341704254740510664318597456840481739975
            );
        }
        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            uint256 tmp = s0 +
                3523599105403569319090449327691358425990456728660349400211678603795116364226;
            s0 = mulmod(tmp, tmp, _PRIME);
            s0 = mulmod(s0, s0, _PRIME);
            s0 = mulmod(s0, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s1 +
                8632053982708637954870974502506145434219829622278773822242070316888003350278;
            s1 = mulmod(tmp, tmp, _PRIME);
            s1 = mulmod(s1, s1, _PRIME);
            s1 = mulmod(s1, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s2 +
                20293222318844554840191640739970825558851264905959070636369796127300969629060;
            s2 = mulmod(tmp, tmp, _PRIME);
            s2 = mulmod(s2, s2, _PRIME);
            s2 = mulmod(s2, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s3 +
                7583204376683983181255811699503668584283525661852773339144064901897953897564;
            s3 = mulmod(tmp, tmp, _PRIME);
            s3 = mulmod(s3, s3, _PRIME);
            s3 = mulmod(s3, tmp, _PRIME);
        }

        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            (s0, s1, s2, s3) = _expAlphaInv4(
                alphaInvScratch,
                s0 + 7562572155566079175343789986900217168516831778275127159068657756836798778249,
                s1 + 12689811910161401007144285031988539999455902164332232460061366402869461973371,
                s2 + 21878400680687418538050108788381481970431106443696421074205107984690362920637,
                s3 + 3428721187625124675258692786364137915132424621324969246210899039774126165479
            );
        }
        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            uint256 tmp = s0 +
                2552744099402346352193097862110515290335034445517764751557635302899937367219;
            s0 = mulmod(tmp, tmp, _PRIME);
            s0 = mulmod(s0, s0, _PRIME);
            s0 = mulmod(s0, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s1 +
                13706727374402840004346872704605212996406886221231239230397976011930486183550;
            s1 = mulmod(tmp, tmp, _PRIME);
            s1 = mulmod(s1, s1, _PRIME);
            s1 = mulmod(s1, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s2 +
                19786308443934570499119114884492461847023732197118902978413499381102456961966;
            s2 = mulmod(tmp, tmp, _PRIME);
            s2 = mulmod(s2, s2, _PRIME);
            s2 = mulmod(s2, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s3 +
                11767081169862697956461405434786280425108140215784390008330611807075539962898;
            s3 = mulmod(tmp, tmp, _PRIME);
            s3 = mulmod(s3, s3, _PRIME);
            s3 = mulmod(s3, tmp, _PRIME);
        }

        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            (s0, s1, s2, s3) = _expAlphaInv4(
                alphaInvScratch,
                s0 + 1273319740931699377003430019539548781935202579355152343831464213279794249000,
                s1 + 20225620070386241931202098463018472034137960205721651875253423327929063224115,
                s2 + 13107884970924459680133954992354588464904218518440707039430314610799573960437,
                s3 + 10574066469653966216567896842413898230152427846140046825523989742590727910280
            );
        }
        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            uint256 tmp = s0 +
                21386271527766270535632132320974945129946865648321206442664310421414128279311;
            s0 = mulmod(tmp, tmp, _PRIME);
            s0 = mulmod(s0, s0, _PRIME);
            s0 = mulmod(s0, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s1 +
                15743262855527118149527268525857865250723531109306484598629175225221686341453;
            s1 = mulmod(tmp, tmp, _PRIME);
            s1 = mulmod(s1, s1, _PRIME);
            s1 = mulmod(s1, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s2 +
                16251140915157602891864152518526119259367827194524273940185283798897653655734;
            s2 = mulmod(tmp, tmp, _PRIME);
            s2 = mulmod(s2, s2, _PRIME);
            s2 = mulmod(s2, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s3 +
                5420158299017134702074915284768041702367316125403978919545323705661634647751;
            s3 = mulmod(tmp, tmp, _PRIME);
            s3 = mulmod(s3, s3, _PRIME);
            s3 = mulmod(s3, tmp, _PRIME);
        }

        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            (s0, s1, s2, s3) = _expAlphaInv4(
                alphaInvScratch,
                s0 + 14555572526833606349832007897859411042036463045080050783981107823326880950231,
                s1 + 15234942318869557310939446038663331226792664588406507247341043508129993934298,
                s2 + 19560004467494472556570844694553210033340577742756929194362924850760034377042,
                s3 + 21851693551359717578445799046408060941161959589978077352548456186528047792150
            );
        }
        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            uint256 tmp = s0 +
                19076469206110044175016166349949136119962165667268661130584159239385341119621;
            s0 = mulmod(tmp, tmp, _PRIME);
            s0 = mulmod(s0, s0, _PRIME);
            s0 = mulmod(s0, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s1 +
                19132104531774396501521959463346904008488403861940301898725725957519076019017;
            s1 = mulmod(tmp, tmp, _PRIME);
            s1 = mulmod(s1, s1, _PRIME);
            s1 = mulmod(s1, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s2 +
                6606159937109409334959297158878571243749055026127553188405933692223704734040;
            s2 = mulmod(tmp, tmp, _PRIME);
            s2 = mulmod(s2, s2, _PRIME);
            s2 = mulmod(s2, tmp, _PRIME);
        }
        unchecked {
            uint256 tmp = s3 +
                13442678592538344046772867528443594004918096722084104155946229264098946917042;
            s3 = mulmod(tmp, tmp, _PRIME);
            s3 = mulmod(s3, s3, _PRIME);
            s3 = mulmod(s3, tmp, _PRIME);
        }

        (s0, s1, s2, s3) = _linearOp(s0, s1, s2, s3);

        unchecked {
            return (
                s0 + 11975757366382164299373991853632416786161357061467425182041988114491638264212,
                s1 + 10571372363668414752587603575617060708758897046929321941050113299303675014148,
                s2 + 5405426474713644587066466463343175633538103521677501186003868914920014287031,
                s3 + 18665277628144856329335676361545218245401014824195451740181902217370165017984
            );
        }
    }

    // Computes the hash of three field elements and returns a single element
    // In our case the rate is 3 and the capacity is 1
    // This hash function the one used in the Records Merkle tree.
    // @param a first element
    // @param b second element
    // @param c third element
    // @return the first element of the Rescue state
    function hash(
        uint256 a,
        uint256 b,
        uint256 c
    ) public view returns (uint256 o) {
        (o, a, b, c) = perm(a % _PRIME, b % _PRIME, c % _PRIME, 0);
        o %= _PRIME;
    }

    function checkBounded(uint256[15] memory inputs) internal pure {
        for (uint256 i = 0; i < inputs.length; ++i) {
            require(inputs[i] < _PRIME, "inputs must be below _PRIME");
        }
    }

    // This function is external to ensure that the solidity compiler generates
    // a separate library contract. This is required to reduce the size of the
    // CAPE contract.
    function commit(uint256[15] memory inputs) external view returns (uint256) {
        checkBounded(inputs);

        uint256 a;
        uint256 b;
        uint256 c;
        uint256 d;

        for (uint256 i = 0; i < 5; i++) {
            unchecked {
                (a, b, c, d) = perm(
                    (a + inputs[3 * i + 0]) % _PRIME,
                    (b + inputs[3 * i + 1]) % _PRIME,
                    (c + inputs[3 * i + 2]) % _PRIME,
                    d
                );

                (a, b, c, d) = (a % _PRIME, b % _PRIME, c % _PRIME, d % _PRIME);
            }
        }

        return a;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
//
// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import "../interfaces/IPlonkVerifier.sol";
import "./Transfer1In2Out24DepthVk.sol";
import "./Transfer2In2Out24DepthVk.sol";
import "./Transfer2In3Out24DepthVk.sol";
import "./Transfer3In3Out24DepthVk.sol";
import "./Mint1In2Out24DepthVk.sol";
import "./Freeze2In2Out24DepthVk.sol";
import "./Freeze3In3Out24DepthVk.sol";

library VerifyingKeys {
    function getVkById(uint256 encodedId)
        external
        pure
        returns (IPlonkVerifier.VerifyingKey memory)
    {
        if (encodedId == getEncodedId(0, 1, 2, 24)) {
            // transfer/burn-1-input-2-output-24-depth
            return Transfer1In2Out24DepthVk.getVk();
        } else if (encodedId == getEncodedId(0, 2, 2, 24)) {
            // transfer/burn-2-input-2-output-24-depth
            return Transfer2In2Out24DepthVk.getVk();
        } else if (encodedId == getEncodedId(0, 2, 3, 24)) {
            // transfer/burn-2-input-3-output-24-depth
            return Transfer2In3Out24DepthVk.getVk();
        } else if (encodedId == getEncodedId(0, 3, 3, 24)) {
            // transfer/burn-3-input-3-output-24-depth
            return Transfer3In3Out24DepthVk.getVk();
        } else if (encodedId == getEncodedId(1, 1, 2, 24)) {
            // mint-1-input-2-output-24-depth
            return Mint1In2Out24DepthVk.getVk();
        } else if (encodedId == getEncodedId(2, 2, 2, 24)) {
            // freeze-2-input-2-output-24-depth
            return Freeze2In2Out24DepthVk.getVk();
        } else if (encodedId == getEncodedId(2, 3, 3, 24)) {
            // freeze-3-input-3-output-24-depth
            return Freeze3In3Out24DepthVk.getVk();
        } else {
            revert("Unknown vk ID");
        }
    }

    // returns (noteType, numInput, numOutput, treeDepth) as a 4*8 = 32 byte = uint256
    // as the encoded ID.
    function getEncodedId(
        uint8 noteType,
        uint8 numInput,
        uint8 numOutput,
        uint8 treeDepth
    ) public pure returns (uint256 encodedId) {
        assembly {
            encodedId := add(
                shl(24, noteType),
                add(shl(16, numInput), add(shl(8, numOutput), treeDepth))
            )
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
//
// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import "../libraries/BN254.sol";

interface IPlonkVerifier {
    // Flatten out TurboPlonk proof
    struct PlonkProof {
        // the first 5 are 4 inputs and 1 output wire poly commmitments
        // i.e., batch_proof.wires_poly_comms_vec.iter()
        // wire0 is 32 bytes which is a pointer to BN254.G1Point
        BN254.G1Point wire0; // 0x00
        BN254.G1Point wire1; // 0x20
        BN254.G1Point wire2; // 0x40
        BN254.G1Point wire3; // 0x60
        BN254.G1Point wire4; // 0x80
        // the next one is the  product permutation poly commitment
        // i.e., batch_proof.prod_perm_poly_comms_vec.iter()
        BN254.G1Point prodPerm; // 0xA0
        // the next 5 are split quotient poly commmitments
        // i.e., batch_proof.split_quot_poly_comms
        BN254.G1Point split0; // 0xC0
        BN254.G1Point split1; // 0xE0
        BN254.G1Point split2; // 0x100
        BN254.G1Point split3; // 0x120
        BN254.G1Point split4; // 0x140
        // witness poly com for aggregated opening at `zeta`
        // i.e., batch_proof.opening_proof
        BN254.G1Point zeta; // 0x160
        // witness poly com for shifted opening at `zeta * \omega`
        // i.e., batch_proof.shifted_opening_proof
        BN254.G1Point zetaOmega; // 0x180
        // wire poly eval at `zeta`
        uint256 wireEval0; // 0x1A0
        uint256 wireEval1; // 0x1C0
        uint256 wireEval2; // 0x1E0
        uint256 wireEval3; // 0x200
        uint256 wireEval4; // 0x220
        // extended permutation (sigma) poly eval at `zeta`
        // last (sigmaEval4) is saved by Maller Optimization
        uint256 sigmaEval0; // 0x240
        uint256 sigmaEval1; // 0x260
        uint256 sigmaEval2; // 0x280
        uint256 sigmaEval3; // 0x2A0
        // product permutation poly eval at `zeta * \omega`
        uint256 prodPermZetaOmegaEval; // 0x2C0
    }

    // The verifying key for Plonk proofs.
    struct VerifyingKey {
        uint256 domainSize; // 0x00
        uint256 numInputs; // 0x20
        // commitment to extended perm (sigma) poly
        BN254.G1Point sigma0; // 0x40
        BN254.G1Point sigma1; // 0x60
        BN254.G1Point sigma2; // 0x80
        BN254.G1Point sigma3; // 0xA0
        BN254.G1Point sigma4; // 0xC0
        // commitment to selector poly
        // first 4 are linear combination selector
        BN254.G1Point q1; // 0xE0
        BN254.G1Point q2; // 0x100
        BN254.G1Point q3; // 0x120
        BN254.G1Point q4; // 0x140
        // multiplication selector for 1st, 2nd wire
        BN254.G1Point qM12; // 0x160
        // multiplication selector for 3rd, 4th wire
        BN254.G1Point qM34; // 0x180
        // output selector
        BN254.G1Point qO; // 0x1A0
        // constant term selector
        BN254.G1Point qC; // 0x1C0
        // rescue selector qH1 * w_ai^5
        BN254.G1Point qH1; // 0x1E0
        // rescue selector qH2 * w_bi^5
        BN254.G1Point qH2; // 0x200
        // rescue selector qH3 * w_ci^5
        BN254.G1Point qH3; // 0x220
        // rescue selector qH4 * w_di^5
        BN254.G1Point qH4; // 0x240
        // elliptic curve selector
        BN254.G1Point qEcc; // 0x260
    }

    /// @dev Batch verify multiple TurboPlonk proofs.
    /// @param verifyingKeys An array of verifying keys
    /// @param publicInputs A two-dimensional array of public inputs.
    /// @param proofs An array of Plonk proofs
    /// @param extraTranscriptInitMsgs An array of bytes from
    /// transcript initialization messages
    /// @return _ A boolean that is true for successful verification, false otherwise
    function batchVerify(
        VerifyingKey[] memory verifyingKeys,
        uint256[][] memory publicInputs,
        PlonkProof[] memory proofs,
        bytes[] memory extraTranscriptInitMsgs
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
//
// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

interface IRecordsMerkleTree {
    /// @param elements The list of elements to be appended to the current merkle tree described by the frontier.
    function updateRecordsMerkleTree(uint256[] memory elements) external;

    /// @notice Returns the root value of the Merkle tree.
    function getRootValue() external view returns (uint256);

    /// @notice Returns the height of the Merkle tree.
    function getHeight() external view returns (uint8);

    /// @notice Returns the number of leaves of the Merkle tree.
    function getNumLeaves() external view returns (uint64);
}

// SPDX-License-Identifier: GPL-3.0-or-later
//
// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import "./libraries/BN254.sol";
import "./libraries/EdOnBN254.sol";

contract AssetRegistry {
    bytes13 public constant DOM_SEP_FOREIGN_ASSET = "FOREIGN_ASSET";
    bytes14 public constant DOM_SEP_DOMESTIC_ASSET = "DOMESTIC_ASSET";
    uint256 public constant CAP_NATIVE_ASSET_CODE = 1;

    event AssetSponsored(address erc20Address, uint256 assetDefinitionCode);

    mapping(bytes32 => address) public assets;

    struct AssetDefinition {
        uint256 code;
        AssetPolicy policy;
    }

    struct AssetPolicy {
        EdOnBN254.EdOnBN254Point auditorPk;
        EdOnBN254.EdOnBN254Point credPk;
        EdOnBN254.EdOnBN254Point freezerPk;
        uint256 revealMap;
        uint128 revealThreshold;
    }

    /// @notice Return the CAP-native asset definition.
    function nativeDomesticAsset() public pure returns (AssetDefinition memory assetDefinition) {
        assetDefinition.code = CAP_NATIVE_ASSET_CODE;
        // affine representation of zero point in arkwork is (0,1)
        assetDefinition.policy.auditorPk.y = 1;
        assetDefinition.policy.credPk.y = 1;
        assetDefinition.policy.freezerPk.y = 1;
    }

    /// @notice Fetch the ERC-20 token address corresponding to the
    /// given asset definition.
    /// @param assetDefinition an asset definition
    /// @return An ERC-20 address
    function lookup(AssetDefinition memory assetDefinition) public view returns (address) {
        bytes32 key = keccak256(abi.encode(assetDefinition));
        return assets[key];
    }

    /// @notice Is the given asset definition registered?
    /// @param assetDefinition an asset definition
    /// @return True if the asset type is registered, false otherwise.
    function isCapeAssetRegistered(AssetDefinition memory assetDefinition)
        public
        view
        returns (bool)
    {
        return lookup(assetDefinition) != address(0);
    }

    /// @notice Create and register a new asset type associated with an
    /// ERC-20 token. Will revert if the asset type is already
    /// registered or the ERC-20 token address is zero.
    /// @param erc20Address An ERC-20 token address
    /// @param newAsset An asset type to be registered in the contract
    function sponsorCapeAsset(address erc20Address, AssetDefinition memory newAsset) external {
        require(erc20Address != address(0), "Bad asset address");
        require(!isCapeAssetRegistered(newAsset), "Asset already registered");

        _checkForeignAssetCode(newAsset.code, erc20Address, msg.sender, newAsset.policy);

        bytes32 key = keccak256(abi.encode(newAsset));
        assets[key] = erc20Address;

        emit AssetSponsored(erc20Address, newAsset.code);
    }

    /// @notice Throws an exception if the asset definition code is
    /// not correctly derived from the ERC-20 address of the token and
    /// the address of the sponsor.
    /// @dev Requires "view" to access msg.sender.
    /// @param assetDefinitionCode The code of an asset definition
    /// @param erc20Address The ERC-20 address bound to the asset definition
    /// @param sponsor The sponsor address of this wrapped asset
    /// @param policy asset policy
    function _checkForeignAssetCode(
        uint256 assetDefinitionCode,
        address erc20Address,
        address sponsor,
        AssetPolicy memory policy
    ) internal pure {
        bytes memory description = _computeAssetDescription(erc20Address, sponsor, policy);
        require(
            assetDefinitionCode ==
                BN254.fromLeBytesModOrder(
                    bytes.concat(keccak256(bytes.concat(DOM_SEP_FOREIGN_ASSET, description)))
                ),
            "Wrong foreign asset code"
        );
    }

    /// @dev Checks if the asset definition code is correctly derived from the internal asset code.
    /// @param assetDefinitionCode asset definition code
    /// @param internalAssetCode internal asset code
    function _checkDomesticAssetCode(uint256 assetDefinitionCode, uint256 internalAssetCode)
        internal
        pure
    {
        require(
            assetDefinitionCode ==
                BN254.fromLeBytesModOrder(
                    bytes.concat(
                        keccak256(
                            bytes.concat(
                                DOM_SEP_DOMESTIC_ASSET,
                                bytes32(Utils.reverseEndianness(internalAssetCode))
                            )
                        )
                    )
                ),
            "Wrong domestic asset code"
        );
    }

    /// @dev Compute the asset description from the address of the
    /// ERC-20 token and the address of the sponsor.
    /// @param erc20Address address of the erc20 token
    /// @param sponsor address of the sponsor
    /// @param policy asset policy
    /// @return The asset description
    function _computeAssetDescription(
        address erc20Address,
        address sponsor,
        AssetPolicy memory policy
    ) internal pure returns (bytes memory) {
        return
            bytes.concat(
                "EsSCAPE ERC20",
                bytes20(erc20Address),
                "sponsored by",
                bytes20(sponsor),
                "policy",
                abi.encode(policy)
            );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
//
// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

contract RootStore {
    uint256[] internal _roots;
    mapping(uint256 => bool) internal _rootsMap;
    uint64 internal _writeHead;

    /// @dev Create a root store.
    /// @param nRoots The maximum number of roots to store
    constructor(uint64 nRoots) {
        // Set up the circular buffer for handling the last N roots
        require(nRoots > 1, "A least 2 roots required");

        _roots = new uint256[](nRoots);

        // Initially all roots are set to zero.
        // This value is such that no adversary can extend a branch from this root node.
        // See proposition 2, page 48 of the AT-Spec document EspressoSystems/[email protected]
    }

    /// @dev Add a root value. Only keep the latest nRoots ones.
    /// @param newRoot The value of the new root
    function _addRoot(uint256 newRoot) internal {
        require(!_rootsMap[newRoot], "Root already exists");

        // Ensure the root we will "overwrite" is removed.
        _rootsMap[_roots[_writeHead]] = false;

        _roots[_writeHead] = newRoot;
        _rootsMap[newRoot] = true;

        _writeHead = (_writeHead + 1) % uint64(_roots.length);
    }

    /// @dev Is the root value contained in the store?
    /// @param root The root value to find
    /// @return _ True if the root value is in the store, false otherwise
    function _containsRoot(uint256 root) internal view returns (bool) {
        return _rootsMap[root];
    }

    /// @dev Raise an exception if the root is not present in the store.
    /// @param root The required root value
    function _checkContainsRoot(uint256 root) internal view {
        require(_containsRoot(root), "Root not found");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
//
// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

library Utils {
    function reverseEndianness(uint256 input) internal pure returns (uint256 v) {
        v = input;

        // swap bytes
        v =
            ((v & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00) >> 8) |
            ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v =
            ((v & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >> 16) |
            ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v =
            ((v & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000) >> 32) |
            ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);

        // swap 8-byte long pairs
        v =
            ((v & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000) >> 64) |
            ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);

        // swap 16-byte long pairs
        v = (v >> 128) | (v << 128);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
//
// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

// NOTE: DO NOT MODIFY! GENERATED BY SCRIPT VIA `cargo run --bin gen-vk-libraries --release`.
pragma solidity ^0.8.0;

import "../interfaces/IPlonkVerifier.sol";
import "./BN254.sol";

library Transfer1In2Out24DepthVk {
    function getVk() internal pure returns (IPlonkVerifier.VerifyingKey memory vk) {
        assembly {
            // domain size
            mstore(vk, 32768)
            // num of public inputs
            mstore(add(vk, 0x20), 14)

            // sigma0
            mstore(
                mload(add(vk, 0x40)),
                6451930258054036397165544866644311272180786776693649154889113517935138989324
            )
            mstore(
                add(mload(add(vk, 0x40)), 0x20),
                15824498031290932840309269587075035510403426361110328301862825820425402064333
            )
            // sigma1
            mstore(
                mload(add(vk, 0x60)),
                16567945706248183214406921539823721483157024902030706018155219832331943151521
            )
            mstore(
                add(mload(add(vk, 0x60)), 0x20),
                14506648136467119081958160505454685757895812203258866143116417397069305366174
            )
            // sigma2
            mstore(
                mload(add(vk, 0x80)),
                16908805137848644970538829805684573945187052776129406508429516788865993229946
            )
            mstore(
                add(mload(add(vk, 0x80)), 0x20),
                13370902069114408370627021011309095482019563080650295231694581484651030202227
            )
            // sigma3
            mstore(
                mload(add(vk, 0xa0)),
                11385428061273012554614867838291301202096376350855764984558871671579621291507
            )
            mstore(
                add(mload(add(vk, 0xa0)), 0x20),
                18938480909096008246537758317235530495583632544865390355616243879170108311037
            )
            // sigma4
            mstore(
                mload(add(vk, 0xc0)),
                7250836052061444170671162428779548720754588271620290284029438087321333136859
            )
            mstore(
                add(mload(add(vk, 0xc0)), 0x20),
                9774478170511284714380468511107372909275276960243638784016266344709965751507
            )

            // q1
            mstore(
                mload(add(vk, 0xe0)),
                2164661706057106993702119971892524764909406587180616475316536801798272746351
            )
            mstore(
                add(mload(add(vk, 0xe0)), 0x20),
                7993083931046493938644389635874939373576598203553188654440768055247347522377
            )
            // q2
            mstore(
                mload(add(vk, 0x100)),
                17875027092910639802264620931724329796279457509298747494670931666396434012177
            )
            mstore(
                add(mload(add(vk, 0x100)), 0x20),
                12276180841132702377773827582398158204508221552359644390751974783173207949116
            )
            // q3
            mstore(
                mload(add(vk, 0x120)),
                6923045257159434019788850173231395134054684072354814328515094196682490129996
            )
            mstore(
                add(mload(add(vk, 0x120)), 0x20),
                10297389981574891432841377306749459633586002482842974197875786670892058142179
            )
            // q4
            mstore(
                mload(add(vk, 0x140)),
                13566140293342467207563198706820126266175769850278450464476746689910443370750
            )
            mstore(
                add(mload(add(vk, 0x140)), 0x20),
                4337013617009771491102950113766314929630396941539697665107262932887431611820
            )

            // qM12
            mstore(
                mload(add(vk, 0x160)),
                19545356440018631139549838928930231615194677294299230322568967706100221743452
            )
            mstore(
                add(mload(add(vk, 0x160)), 0x20),
                3905268653568739552774781017975590296651581349403516285498718251384231803637
            )
            // qM34
            mstore(
                mload(add(vk, 0x180)),
                3633513776458243190609011598510312470369153119749343878250857605063953894824
            )
            mstore(
                add(mload(add(vk, 0x180)), 0x20),
                10348854780537633653024803962077925757963724802390956695225993897601858375068
            )

            // qO
            mstore(
                mload(add(vk, 0x1a0)),
                10515123958235902109894586452633863486298290064878690665500349352367945576213
            )
            mstore(
                add(mload(add(vk, 0x1a0)), 0x20),
                20835963785046732330293306231553834880816750576829504030205004088050809531737
            )
            // qC
            mstore(
                mload(add(vk, 0x1c0)),
                10349250837084111252673833558497412287345352572732754388450385078539897036072
            )
            mstore(
                add(mload(add(vk, 0x1c0)), 0x20),
                1295954576893766564415821998145161393110346678014886452040838119568563355556
            )
            // qH1
            mstore(
                mload(add(vk, 0x1e0)),
                18595738613642013642528283665640490180800278502934355301953048187579782737773
            )
            mstore(
                add(mload(add(vk, 0x1e0)), 0x20),
                5708601727819525671780050950771464619626673626810479676243974296923430650735
            )
            // qH2
            mstore(
                mload(add(vk, 0x200)),
                8105844768413379370590866345497514518639783589779028631263566798017351944465
            )
            mstore(
                add(mload(add(vk, 0x200)), 0x20),
                13767799708582015119198203890136804463714948257729839866946279972890684141171
            )
            // qH3
            mstore(
                mload(add(vk, 0x220)),
                13976995316216184532948677497270469464100744949177652840098916826286666391978
            )
            mstore(
                add(mload(add(vk, 0x220)), 0x20),
                8782060747227562892357029272916715317651514559557103332761644499318601665300
            )
            // qH4
            mstore(
                mload(add(vk, 0x240)),
                10423258206189675762927713311069351374538317153673220039972782365668263479097
            )
            mstore(
                add(mload(add(vk, 0x240)), 0x20),
                12712089727236847935392559371166622501626155101609755726562266635070650647609
            )
            // qEcc
            mstore(
                mload(add(vk, 0x260)),
                3447947975392962233948092031223758925923495365282112464857270024948603045088
            )
            mstore(
                add(mload(add(vk, 0x260)), 0x20),
                4655198050073279486560411245172865913095816956325221266986314415391129730949
            )
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
//
// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

// NOTE: DO NOT MODIFY! GENERATED BY SCRIPT VIA `cargo run --bin gen-vk-libraries --release`.
pragma solidity ^0.8.0;

import "../interfaces/IPlonkVerifier.sol";
import "./BN254.sol";

library Transfer2In2Out24DepthVk {
    function getVk() internal pure returns (IPlonkVerifier.VerifyingKey memory vk) {
        assembly {
            // domain size
            mstore(vk, 32768)
            // num of public inputs
            mstore(add(vk, 0x20), 27)

            // sigma0
            mstore(
                mload(add(vk, 0x40)),
                2353344940323935826134936223947938042521909475033774928828281661731550798722
            )
            mstore(
                add(mload(add(vk, 0x40)), 0x20),
                9746655158250922067275109215926891774244956160343543537816404835253168644024
            )
            // sigma1
            mstore(
                mload(add(vk, 0x60)),
                15455409296542685326830249024223724266624290984578410657713086954481835262616
            )
            mstore(
                add(mload(add(vk, 0x60)), 0x20),
                18311379816054123251097409624258299432408683566103718315014121691958807960547
            )
            // sigma2
            mstore(
                mload(add(vk, 0x80)),
                3595102568308999621710931895728700858137670894580826466196432246884451756647
            )
            mstore(
                add(mload(add(vk, 0x80)), 0x20),
                5971868016111020985417776938700261612639243638290968867440360355753182506016
            )
            // sigma3
            mstore(
                mload(add(vk, 0xa0)),
                12443289603239702012200478229424802817855243081906319312702825218898138895946
            )
            mstore(
                add(mload(add(vk, 0xa0)), 0x20),
                14108881420049829870828878537593066975275378607590487898362908473190089969939
            )
            // sigma4
            mstore(
                mload(add(vk, 0xc0)),
                19679657199741651524390089978450662678686454680964744364368691879627016432652
            )
            mstore(
                add(mload(add(vk, 0xc0)), 0x20),
                17114067594856558864780849616452660298251042000563020846487894545389438664806
            )

            // q1
            mstore(
                mload(add(vk, 0xe0)),
                4521205613646422234630873762189179209607994647697100090154823061235920789353
            )
            mstore(
                add(mload(add(vk, 0xe0)), 0x20),
                16106449496625400183304424755719536524421029289605758534728292280016648447637
            )
            // q2
            mstore(
                mload(add(vk, 0x100)),
                15558337488326969806891656016031810341177100586194811207644366322955582958290
            )
            mstore(
                add(mload(add(vk, 0x100)), 0x20),
                154404024660163916069895563430486111291743096749375581648108814279740019496
            )
            // q3
            mstore(
                mload(add(vk, 0x120)),
                10968315091130697826739702003431871061194509005508422925553623050382577326217
            )
            mstore(
                add(mload(add(vk, 0x120)), 0x20),
                15427520064071248215056685014173235486104450904391795026852773491856938894709
            )
            // q4
            mstore(
                mload(add(vk, 0x140)),
                18552120566932429867086353275996329695634259700395564758868503989836119743976
            )
            mstore(
                add(mload(add(vk, 0x140)), 0x20),
                3758067104786429430903075307629079520236919298153864746942709833835554967358
            )

            // qM12
            mstore(
                mload(add(vk, 0x160)),
                15572105585408879365916525794377657194208962207139936775774251314043834098564
            )
            mstore(
                add(mload(add(vk, 0x160)), 0x20),
                6020958592977720912767721649577520866900127639444801108025166566775601659967
            )
            // qM34
            mstore(
                mload(add(vk, 0x180)),
                7222736374399006211510699304087942059126683193629769887877014686905908945806
            )
            mstore(
                add(mload(add(vk, 0x180)), 0x20),
                3206829195840321731462512861208486643839466222481973961857037286401683735687
            )

            // qO
            mstore(
                mload(add(vk, 0x1a0)),
                3354591448826521438380040598853232839565248677422944332090180952953080366288
            )
            mstore(
                add(mload(add(vk, 0x1a0)), 0x20),
                19963668090281374431317017250026510351550118984869870738585126468447913244591
            )
            // qC
            mstore(
                mload(add(vk, 0x1c0)),
                17974807300702948996049252322259229942746003444136224778640009295566243156501
            )
            mstore(
                add(mload(add(vk, 0x1c0)), 0x20),
                12052046477897583522878740699736101759681160588792932192885758224246430725626
            )
            // qH1
            mstore(
                mload(add(vk, 0x1e0)),
                4921034593166626300651198249205635549101612701433540517476055976860959484949
            )
            mstore(
                add(mload(add(vk, 0x1e0)), 0x20),
                10185405862489710856496932329182422458788356942668474473592359869600739434412
            )
            // qH2
            mstore(
                mload(add(vk, 0x200)),
                5878093886505576171449048465070377785955067968838740459103515014923390639639
            )
            mstore(
                add(mload(add(vk, 0x200)), 0x20),
                15259888626953734049577795735967576333281508824947666542918638019623811781546
            )
            // qH3
            mstore(
                mload(add(vk, 0x220)),
                19643669610230135658961129468905806322162637394453939877922249528939594418232
            )
            mstore(
                add(mload(add(vk, 0x220)), 0x20),
                12224852444220822793589818921506014057813793178254991680570188956045824616826
            )
            // qH4
            mstore(
                mload(add(vk, 0x240)),
                6641963433101155753834035944397107424954075034582038862756599997819459513127
            )
            mstore(
                add(mload(add(vk, 0x240)), 0x20),
                3589782713125700501109156506560851754947305163593203470270968608024453926281
            )
            // qEcc
            mstore(
                mload(add(vk, 0x260)),
                12330486534063835148740124350008103247243211222952306312071501975705307117092
            )
            mstore(
                add(mload(add(vk, 0x260)), 0x20),
                20509504091296584456523257770792088853619865130173628006197630419037120651742
            )
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
//
// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

// NOTE: DO NOT MODIFY! GENERATED BY SCRIPT VIA `cargo run --bin gen-vk-libraries --release`.
pragma solidity ^0.8.0;

import "../interfaces/IPlonkVerifier.sol";
import "./BN254.sol";

library Transfer2In3Out24DepthVk {
    function getVk() internal pure returns (IPlonkVerifier.VerifyingKey memory vk) {
        assembly {
            // domain size
            mstore(vk, 32768)
            // num of public inputs
            mstore(add(vk, 0x20), 32)

            // sigma0
            mstore(
                mload(add(vk, 0x40)),
                11238918059962060895836660665905685183821438171673788872298187887301460117949
            )
            mstore(
                add(mload(add(vk, 0x40)), 0x20),
                10312536098428436059770058647883007948230826032311055958980103002216444398029
            )
            // sigma1
            mstore(
                mload(add(vk, 0x60)),
                3069296210454062532812049058888182398466997742713116483712055777740542557095
            )
            mstore(
                add(mload(add(vk, 0x60)), 0x20),
                10585452901889142818220136732592206035573929406563129602198941778025261934559
            )
            // sigma2
            mstore(
                mload(add(vk, 0x80)),
                49796010413150322443747223871067686918728570624660232645490911700120682624
            )
            mstore(
                add(mload(add(vk, 0x80)), 0x20),
                19418979289570937603858876101332413214999751685423780259104815571219376501897
            )
            // sigma3
            mstore(
                mload(add(vk, 0xa0)),
                5017549683124968830897329522528615084825569869584518140023215913256996665369
            )
            mstore(
                add(mload(add(vk, 0xa0)), 0x20),
                6904459746270415738591583761210331008369254540754508554401155557939093240173
            )
            // sigma4
            mstore(
                mload(add(vk, 0xc0)),
                15294346261666962115813163162624127728984137808463913539428567756274357657589
            )
            mstore(
                add(mload(add(vk, 0xc0)), 0x20),
                6335459220235140110171052568798094575702073047123843498885605762024671566976
            )

            // q1
            mstore(
                mload(add(vk, 0xe0)),
                3447729854865352811909348476580581256116229886577313169808953699321178547567
            )
            mstore(
                add(mload(add(vk, 0xe0)), 0x20),
                10391923178665150678480226437763860904879593811452327022884721625331046561649
            )
            // q2
            mstore(
                mload(add(vk, 0x100)),
                21331037483834702908326522885638199264097608653827628146912836859219217391521
            )
            mstore(
                add(mload(add(vk, 0x100)), 0x20),
                17700979571500030343918100715185217716266526246917146097813330984808052588149
            )
            // q3
            mstore(
                mload(add(vk, 0x120)),
                19231315187566819499805706567670055518295048760424962411545826184537652443122
            )
            mstore(
                add(mload(add(vk, 0x120)), 0x20),
                1786951957014031658307434161704132339929023647859863721152324287915947831283
            )
            // q4
            mstore(
                mload(add(vk, 0x140)),
                891318259297166657950777135402426115367536796891436125685210585889035809375
            )
            mstore(
                add(mload(add(vk, 0x140)), 0x20),
                19080042747384460176894767057995469942920956949014313980914237214240134307208
            )

            // qM12
            mstore(
                mload(add(vk, 0x160)),
                8600864573298799022763786653218006387353791810267845686055695121259061041328
            )
            mstore(
                add(mload(add(vk, 0x160)), 0x20),
                16693779427169671344028720673356223282089909563990595319572224701304611776922
            )
            // qM34
            mstore(
                mload(add(vk, 0x180)),
                9157681660736307225301034938839156685740016704526090406950858434609030225480
            )
            mstore(
                add(mload(add(vk, 0x180)), 0x20),
                8030757918449598333025173041225419314601924784825356372892442933863889091921
            )

            // qO
            mstore(
                mload(add(vk, 0x1a0)),
                13640927194155719878577037989318164230713264172921393074620679102349279698839
            )
            mstore(
                add(mload(add(vk, 0x1a0)), 0x20),
                6900604409783116559678606532527525488965021296050678826316410961047810748517
            )
            // qC
            mstore(
                mload(add(vk, 0x1c0)),
                5252746067177671060986834545182465389119363624955154280966570801582394785840
            )
            mstore(
                add(mload(add(vk, 0x1c0)), 0x20),
                9195131821976884258765963928166452788332100806625752840914173681395711439614
            )
            // qH1
            mstore(
                mload(add(vk, 0x1e0)),
                14977645969508065057243931947507598769856801213808952261859994787935726005589
            )
            mstore(
                add(mload(add(vk, 0x1e0)), 0x20),
                5096294777527669951530261927053173270421982090354495165464932330992574194565
            )
            // qH2
            mstore(
                mload(add(vk, 0x200)),
                3545567189598828405425832938456307851398759232755240447556204001745014820301
            )
            mstore(
                add(mload(add(vk, 0x200)), 0x20),
                1941523779920680020402590579224743136261147114116204389037553310789640138016
            )
            // qH3
            mstore(
                mload(add(vk, 0x220)),
                18752226702425153987309996103585848095327330331398325134534482624274124156372
            )
            mstore(
                add(mload(add(vk, 0x220)), 0x20),
                11041340585339071070596363521057299677913989755036511157364732122494432877984
            )
            // qH4
            mstore(
                mload(add(vk, 0x240)),
                14590850366538565268612154711126247437677807588903705071677135475079401886274
            )
            mstore(
                add(mload(add(vk, 0x240)), 0x20),
                18590050088847501728340953044790139366495591524471631048198965975345765148219
            )
            // qEcc
            mstore(
                mload(add(vk, 0x260)),
                21704590671982347430816904792389667189857927953663414983186296915645026530922
            )
            mstore(
                add(mload(add(vk, 0x260)), 0x20),
                20891693206558394293557033642999941159043782671912221870570329299710569824990
            )
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
//
// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

// NOTE: DO NOT MODIFY! GENERATED BY SCRIPT VIA `cargo run --bin gen-vk-libraries --release`.
pragma solidity ^0.8.0;

import "../interfaces/IPlonkVerifier.sol";
import "./BN254.sol";

library Transfer3In3Out24DepthVk {
    function getVk() internal pure returns (IPlonkVerifier.VerifyingKey memory vk) {
        assembly {
            // domain size
            mstore(vk, 65536)
            // num of public inputs
            mstore(add(vk, 0x20), 45)

            // sigma0
            mstore(
                mload(add(vk, 0x40)),
                6745569324574292840123998773726184666805725845966057344477780763812378175216
            )
            mstore(
                add(mload(add(vk, 0x40)), 0x20),
                15674359264100532117390420549335759541287602785521062799291583384533749901741
            )
            // sigma1
            mstore(
                mload(add(vk, 0x60)),
                3882047939060472482494153851462770573213675187290765799393847015027127043523
            )
            mstore(
                add(mload(add(vk, 0x60)), 0x20),
                7630821036627726874781987389422412327209162597154025595018731571961516169947
            )
            // sigma2
            mstore(
                mload(add(vk, 0x80)),
                21225224708013383300469954369858606000505504678178518510917526718672976749965
            )
            mstore(
                add(mload(add(vk, 0x80)), 0x20),
                16365929799382131762072204211493784381011606251973921052275294268694891754790
            )
            // sigma3
            mstore(
                mload(add(vk, 0xa0)),
                18816028553810513067728270242942259651783354986329945635353859047149476279687
            )
            mstore(
                add(mload(add(vk, 0xa0)), 0x20),
                11882680851945303658063593837716037756293837416752296611477056121789431777064
            )
            // sigma4
            mstore(
                mload(add(vk, 0xc0)),
                21510097154791711734296287821852281209791416779989865544015434367940075374914
            )
            mstore(
                add(mload(add(vk, 0xc0)), 0x20),
                3430102751397774877173034066414871678821827985103146314887340992082993984329
            )

            // q1
            mstore(
                mload(add(vk, 0xe0)),
                19869597504326919094166107694290620558808748604476313005465666228287903414344
            )
            mstore(
                add(mload(add(vk, 0xe0)), 0x20),
                7150111322568846997819037419437132637225578315562663408823282538527304893394
            )
            // q2
            mstore(
                mload(add(vk, 0x100)),
                15160992848460929858090744745540508270198264712727437471403260552347088002356
            )
            mstore(
                add(mload(add(vk, 0x100)), 0x20),
                14658479685250391207452586531545916785099257310771621120220342224985727703397
            )
            // q3
            mstore(
                mload(add(vk, 0x120)),
                8235204123369855002620633544318875073465201482729570929826842086900101734240
            )
            mstore(
                add(mload(add(vk, 0x120)), 0x20),
                1315782571791013709741742522230010040948540142932666264718230624795003912658
            )
            // q4
            mstore(
                mload(add(vk, 0x140)),
                7021080634443416008459948952678027962506306501245829421538884411847588184010
            )
            mstore(
                add(mload(add(vk, 0x140)), 0x20),
                6584493294015254847476792897094566004873857428175399671267891995703671301938
            )

            // qM12
            mstore(
                mload(add(vk, 0x160)),
                19199743165408884046745846028664619315169170959180153012829728401858950581623
            )
            mstore(
                add(mload(add(vk, 0x160)), 0x20),
                14838749009602762930836652487207610572239367359059811743491751753845995666312
            )
            // qM34
            mstore(
                mload(add(vk, 0x180)),
                10248259393969855960972127876087560001222739594880062140977367664638629457979
            )
            mstore(
                add(mload(add(vk, 0x180)), 0x20),
                3405469462517204071666729973707416410254082166076974198995581327928518673875
            )

            // qO
            mstore(
                mload(add(vk, 0x1a0)),
                9259807925511910228709408577417518144465439748546649497440413244416264053909
            )
            mstore(
                add(mload(add(vk, 0x1a0)), 0x20),
                4349742126987923639436565898601499377373071260693932114899380098788981806520
            )
            // qC
            mstore(
                mload(add(vk, 0x1c0)),
                195924708408078159303893377539882303047203274957430754688974876101940076523
            )
            mstore(
                add(mload(add(vk, 0x1c0)), 0x20),
                2730242103617344574903225508726280194241425124842703262405260488972083367491
            )
            // qH1
            mstore(
                mload(add(vk, 0x1e0)),
                20219387287202350426068670038890996732790822982376234641416083193417653609683
            )
            mstore(
                add(mload(add(vk, 0x1e0)), 0x20),
                4712902992473903996354956065401616044154872569903741964754702810524685939510
            )
            // qH2
            mstore(
                mload(add(vk, 0x200)),
                20606018511516306199576247848201856706631620007530428100607004704631466340548
            )
            mstore(
                add(mload(add(vk, 0x200)), 0x20),
                3431535724436156106895017518971445784357440465218022981124980111332355382620
            )
            // qH3
            mstore(
                mload(add(vk, 0x220)),
                16926802729258759088538388518776752987858809292908095720269836387951179849328
            )
            mstore(
                add(mload(add(vk, 0x220)), 0x20),
                17982233223518308144739071673627895392237126231063756253762501987899411496611
            )
            // qH4
            mstore(
                mload(add(vk, 0x240)),
                2769108222659962988853179530681878069454558991374977224908414446449310780711
            )
            mstore(
                add(mload(add(vk, 0x240)), 0x20),
                1229799452453481995415811771099188864368739763357472273935665649735041438448
            )
            // qEcc
            mstore(
                mload(add(vk, 0x260)),
                4813470345909172814186147928188285492437945113396806975178500704379725081570
            )
            mstore(
                add(mload(add(vk, 0x260)), 0x20),
                5911983361843136694947821727682990071782684402361679071602671084421707986423
            )
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
//
// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

// NOTE: DO NOT MODIFY! GENERATED BY SCRIPT VIA `cargo run --bin gen-vk-libraries --release`.
pragma solidity ^0.8.0;

import "../interfaces/IPlonkVerifier.sol";
import "./BN254.sol";

library Mint1In2Out24DepthVk {
    function getVk() internal pure returns (IPlonkVerifier.VerifyingKey memory vk) {
        assembly {
            // domain size
            mstore(vk, 16384)
            // num of public inputs
            mstore(add(vk, 0x20), 22)

            // sigma0
            mstore(
                mload(add(vk, 0x40)),
                18715857233450097233566665862469612667705408112918632327151254517366615510853
            )
            mstore(
                add(mload(add(vk, 0x40)), 0x20),
                12056659507165533739511169991607046566607546589228993432633519678105063191994
            )
            // sigma1
            mstore(
                mload(add(vk, 0x60)),
                14824195002671574468331715635494727121571793218927771429557442195822888294112
            )
            mstore(
                add(mload(add(vk, 0x60)), 0x20),
                15545363005844852395434066542267547241977074468438704526560481952507920680442
            )
            // sigma2
            mstore(
                mload(add(vk, 0x80)),
                12730937992652390663908670084945912580250489721157445258662047611384656062589
            )
            mstore(
                add(mload(add(vk, 0x80)), 0x20),
                13922972325643955705903067190275250069235823502347080251607855678412413832655
            )
            // sigma3
            mstore(
                mload(add(vk, 0xa0)),
                11205515283341717493374802581094446196264159623530455592177314841729924213298
            )
            mstore(
                add(mload(add(vk, 0xa0)), 0x20),
                21626228139140341994554265888140425084500331880890693761295353772893134873176
            )
            // sigma4
            mstore(
                mload(add(vk, 0xc0)),
                1297892505212470170669591175924901147071008882331974691087297632739019966869
            )
            mstore(
                add(mload(add(vk, 0xc0)), 0x20),
                5046998337256619649328073625306172605427225136111531257681027197976756517579
            )

            // q1
            mstore(
                mload(add(vk, 0xe0)),
                3416126502361838053757816729968531801453964981226124461039874315717193603949
            )
            mstore(
                add(mload(add(vk, 0xe0)), 0x20),
                13457539169423794765649307630863376252412201646715715024708233511728175887361
            )
            // q2
            mstore(
                mload(add(vk, 0x100)),
                14560725448400229197269899568322480538530865768296597131421754928016376186765
            )
            mstore(
                add(mload(add(vk, 0x100)), 0x20),
                948706310326485520368947730671484733882983133515374382612890953953178516965
            )
            // q3
            mstore(
                mload(add(vk, 0x120)),
                3629576662585230443325226017156907801568659344982452092584030101519414013585
            )
            mstore(
                add(mload(add(vk, 0x120)), 0x20),
                11755059153403672321764085695058203755528587063932979109812536973510125660021
            )
            // q4
            mstore(
                mload(add(vk, 0x140)),
                11004655709419206490244680738164512138236779409731663166100876015592834374329
            )
            mstore(
                add(mload(add(vk, 0x140)), 0x20),
                3075086625849477481019461602494583874758896233088021555313650923393327170396
            )

            // qM12
            mstore(
                mload(add(vk, 0x160)),
                5116214943488395672472205024247672892505731883467355177124324350502474270399
            )
            mstore(
                add(mload(add(vk, 0x160)), 0x20),
                5862627121952215177093377764664762757373132220173512585597211838016077936314
            )
            // qM34
            mstore(
                mload(add(vk, 0x180)),
                17591159830764396623974345916017368127032492198578190405514161605820133619635
            )
            mstore(
                add(mload(add(vk, 0x180)), 0x20),
                21823861194811124564815272373053730365073236057851878678286985577859771922838
            )

            // qO
            mstore(
                mload(add(vk, 0x1a0)),
                4270340305067371269951830198578603793146745643909898988425564374444309637164
            )
            mstore(
                add(mload(add(vk, 0x1a0)), 0x20),
                3429516859933338020020014748205944416226065682096817012737681215798779959358
            )
            // qC
            mstore(
                mload(add(vk, 0x1c0)),
                18140449432973717159678873762584078749849242918610972566667541337332136871548
            )
            mstore(
                add(mload(add(vk, 0x1c0)), 0x20),
                9496973080403650076452512345486781056144944295333639818676842964799046293494
            )
            // qH1
            mstore(
                mload(add(vk, 0x1e0)),
                2679601553769052076036509170798838073426403353317218807312666276919478214029
            )
            mstore(
                add(mload(add(vk, 0x1e0)), 0x20),
                8104020893469546307958011379600482565107943832349081304458473817724197756534
            )
            // qH2
            mstore(
                mload(add(vk, 0x200)),
                15359849857211682094089890949757251089555853826462724721381029431330976452771
            )
            mstore(
                add(mload(add(vk, 0x200)), 0x20),
                16491566299722544741678927866350154870498939946959249271831955257228312538659
            )
            // qH3
            mstore(
                mload(add(vk, 0x220)),
                12100931690223724084472313998885551549102209045806672061992493151022394323721
            )
            mstore(
                add(mload(add(vk, 0x220)), 0x20),
                789632069622495739311692844331711309820973570859008137449744966665497183364
            )
            // qH4
            mstore(
                mload(add(vk, 0x240)),
                9372499437356245507830218065264333778849228240985893278867565670067559001476
            )
            mstore(
                add(mload(add(vk, 0x240)), 0x20),
                5071314442263159884139201702429590502916613589463313571011317767821015131114
            )
            // qEcc
            mstore(
                mload(add(vk, 0x260)),
                13714688610643446356217590887080562811494820054657712165894734861828853586333
            )
            mstore(
                add(mload(add(vk, 0x260)), 0x20),
                1823119861575201921550763026703044012616621870847156108104965194178825195245
            )
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
//
// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

// NOTE: DO NOT MODIFY! GENERATED BY SCRIPT VIA `cargo run --bin gen-vk-libraries --release`.
pragma solidity ^0.8.0;

import "../interfaces/IPlonkVerifier.sol";
import "./BN254.sol";

library Freeze2In2Out24DepthVk {
    function getVk() internal pure returns (IPlonkVerifier.VerifyingKey memory vk) {
        assembly {
            // domain size
            mstore(vk, 32768)
            // num of public inputs
            mstore(add(vk, 0x20), 7)

            // sigma0
            mstore(
                mload(add(vk, 0x40)),
                5118137774697846205332813764527928981094534629179826197661885163309718792664
            )
            mstore(
                add(mload(add(vk, 0x40)), 0x20),
                21444510867008360096097791654924066970628086592132286765149218644570218218958
            )
            // sigma1
            mstore(
                mload(add(vk, 0x60)),
                8803078987858664729272498900762799875194584982758288268215987493230494163132
            )
            mstore(
                add(mload(add(vk, 0x60)), 0x20),
                2433303804972293717223914306424233027859258355453999879123493306111951897773
            )
            // sigma2
            mstore(
                mload(add(vk, 0x80)),
                3260803333275595200572169884988811547059839215101652317716205725226978273005
            )
            mstore(
                add(mload(add(vk, 0x80)), 0x20),
                3613466037895382109608881276133312019690204476510004381563636709063308697093
            )
            // sigma3
            mstore(
                mload(add(vk, 0xa0)),
                2899439069156777615431510251772750434873724497570948892914993632800602868003
            )
            mstore(
                add(mload(add(vk, 0xa0)), 0x20),
                8379069052308825781842073463279139505822176676050290986587894691217284563176
            )
            // sigma4
            mstore(
                mload(add(vk, 0xc0)),
                11732815069861807091165298838511758216456754114248634732985660813617441774658
            )
            mstore(
                add(mload(add(vk, 0xc0)), 0x20),
                13166648630773672378735632573860809427570624939066078822309995911184719468349
            )

            // q1
            mstore(
                mload(add(vk, 0xe0)),
                3491113372305405096734724369052497193940883294098266073462122391919346338715
            )
            mstore(
                add(mload(add(vk, 0xe0)), 0x20),
                9827940866231584614489847721346069816554104560301469101889136447541239075558
            )
            // q2
            mstore(
                mload(add(vk, 0x100)),
                13435736629650136340196094187820825115318808951343660439499146542480924445056
            )
            mstore(
                add(mload(add(vk, 0x100)), 0x20),
                17982003639419860944219119425071532203644939147988825284644182004036282633420
            )
            // q3
            mstore(
                mload(add(vk, 0x120)),
                9420441314344923881108805693844267870391289724837370305813596950535269618889
            )
            mstore(
                add(mload(add(vk, 0x120)), 0x20),
                14052028114719021167053334693322209909986772869796949309216011765205181071250
            )
            // q4
            mstore(
                mload(add(vk, 0x140)),
                5993794253539477186956400554691260472169114800994727061541419240125118730670
            )
            mstore(
                add(mload(add(vk, 0x140)), 0x20),
                7932960467420473760327919608797843731121974235494949218022535850994096308221
            )

            // qM12
            mstore(
                mload(add(vk, 0x160)),
                20429406452243707916630058273965650451352739230543746812138739882954609124362
            )
            mstore(
                add(mload(add(vk, 0x160)), 0x20),
                19692763177526054221606086118119451355223254880919552106296824049356634107628
            )
            // qM34
            mstore(
                mload(add(vk, 0x180)),
                5116116081275540865026368436909879211124168610156815899416152073819842308833
            )
            mstore(
                add(mload(add(vk, 0x180)), 0x20),
                19842614482623746480218449373220727139999815807703100436601033251034509288020
            )

            // qO
            mstore(
                mload(add(vk, 0x1a0)),
                3222495709067365879961349438698872943831082393186134710609177690951286365439
            )
            mstore(
                add(mload(add(vk, 0x1a0)), 0x20),
                3703532585269560394637679600890000571417416525562741673639173852507841008896
            )
            // qC
            mstore(
                mload(add(vk, 0x1c0)),
                14390471925844384916287376853753782482889671388409569687933776522892272411453
            )
            mstore(
                add(mload(add(vk, 0x1c0)), 0x20),
                12261059506574689542871751331715340905672203590996080541963527436628201655551
            )
            // qH1
            mstore(
                mload(add(vk, 0x1e0)),
                212133813390818941086614328570019936880884093617125797928913969643819686094
            )
            mstore(
                add(mload(add(vk, 0x1e0)), 0x20),
                2058275687345409085609950154451527352761528547310163982911053914079075244754
            )
            // qH2
            mstore(
                mload(add(vk, 0x200)),
                7507728187668840967683000771945777493711131652056583548804845913578647015848
            )
            mstore(
                add(mload(add(vk, 0x200)), 0x20),
                15764897865018924692970368330703479768257677759902236501992745661340099646248
            )
            // qH3
            mstore(
                mload(add(vk, 0x220)),
                18302496468173370667823199324779836313672317342261283918121073083547306893947
            )
            mstore(
                add(mload(add(vk, 0x220)), 0x20),
                8286815911028648157724790867291052312955947067988434001008620797971639607610
            )
            // qH4
            mstore(
                mload(add(vk, 0x240)),
                3470304694844212768511296992238419575123994956442939632524758781128057967608
            )
            mstore(
                add(mload(add(vk, 0x240)), 0x20),
                9660892985889164184033149081062412611630238705975373538019042544308335432760
            )
            // qEcc
            mstore(
                mload(add(vk, 0x260)),
                2964316839877400858567376484261923751031240259689039666960763176068018735519
            )
            mstore(
                add(mload(add(vk, 0x260)), 0x20),
                12811532772714855857084788747474913882317963037829729036129619334772557515102
            )
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
//
// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

// NOTE: DO NOT MODIFY! GENERATED BY SCRIPT VIA `cargo run --bin gen-vk-libraries --release`.
pragma solidity ^0.8.0;

import "../interfaces/IPlonkVerifier.sol";
import "./BN254.sol";

library Freeze3In3Out24DepthVk {
    function getVk() internal pure returns (IPlonkVerifier.VerifyingKey memory vk) {
        assembly {
            // domain size
            mstore(vk, 32768)
            // num of public inputs
            mstore(add(vk, 0x20), 9)

            // sigma0
            mstore(
                mload(add(vk, 0x40)),
                13960731824189571867091334541157339805012676983241098249236778497915465352053
            )
            mstore(
                add(mload(add(vk, 0x40)), 0x20),
                15957967148909612161116218663566087497068811688498797226467515095325657152045
            )
            // sigma1
            mstore(
                mload(add(vk, 0x60)),
                10072587287838607559866316765624459623039578259829899225485734337870604479821
            )
            mstore(
                add(mload(add(vk, 0x60)), 0x20),
                15609102652788964903340031795269302405421393375766454476378251576322947285858
            )
            // sigma2
            mstore(
                mload(add(vk, 0x80)),
                6565707169634610873662073730120423414251877113110818166564470784428289496576
            )
            mstore(
                add(mload(add(vk, 0x80)), 0x20),
                9611712776953584296612678707999788907754017999002246476393974258810867124564
            )
            // sigma3
            mstore(
                mload(add(vk, 0xa0)),
                19122400063214294010991425447556532201595762243736666161415050184531098654161
            )
            mstore(
                add(mload(add(vk, 0xa0)), 0x20),
                8531074110951311734071734321378003618052738734286317677359289798683215129985
            )
            // sigma4
            mstore(
                mload(add(vk, 0xc0)),
                18914674706112982859579196036464470962561796494057486369943014188445892675591
            )
            mstore(
                add(mload(add(vk, 0xc0)), 0x20),
                8521550178820292984099911306615540388090622911114862049753515592863829430736
            )

            // q1
            mstore(
                mload(add(vk, 0xe0)),
                14630335835391046544786473024276900306274085179180854494149987003151236405693
            )
            mstore(
                add(mload(add(vk, 0xe0)), 0x20),
                11927636740621831793456799535735389934490350641107279163802406976389995490906
            )
            // q2
            mstore(
                mload(add(vk, 0x100)),
                12724914112829888521503996001370933887413324349676112061904353298191125761834
            )
            mstore(
                add(mload(add(vk, 0x100)), 0x20),
                3433370683786676509006167821257247081483834358490691629467376279251656650897
            )
            // q3
            mstore(
                mload(add(vk, 0x120)),
                9566744544381523978155846140753126684369534823789897373672815695046810310988
            )
            mstore(
                add(mload(add(vk, 0x120)), 0x20),
                260017699035964770662690666115311602214922546306804012310168827438556483441
            )
            // q4
            mstore(
                mload(add(vk, 0x140)),
                18742890127040989288898023133652949889864689947035150783791742574000686319400
            )
            mstore(
                add(mload(add(vk, 0x140)), 0x20),
                18749161983189150319356152659011703669863797011859087161475368338926038180308
            )

            // qM12
            mstore(
                mload(add(vk, 0x160)),
                20773233313791930222139945008080890514898946888819625041024291924369611870607
            )
            mstore(
                add(mload(add(vk, 0x160)), 0x20),
                13521724424975535658347353167027580945107539483287924982357298371687877483981
            )
            // qM34
            mstore(
                mload(add(vk, 0x180)),
                10660982607928179139814177842882617778440401746692506684983260589289268170379
            )
            mstore(
                add(mload(add(vk, 0x180)), 0x20),
                15139413484465466645149010003574654339361200137557967877891360282092282891685
            )

            // qO
            mstore(
                mload(add(vk, 0x1a0)),
                17250558007005834955604250406579207360748810924758511953913092810009135851470
            )
            mstore(
                add(mload(add(vk, 0x1a0)), 0x20),
                11258418978437321501318046240697776859180107275977030400553604411488978149668
            )
            // qC
            mstore(
                mload(add(vk, 0x1c0)),
                18952078950487788846193130112459018587473354670050028821020889375362878213321
            )
            mstore(
                add(mload(add(vk, 0x1c0)), 0x20),
                17193026626593699161155564126784943150078109362562131961513990003707313130311
            )
            // qH1
            mstore(
                mload(add(vk, 0x1e0)),
                14543481681504505345294846715453463092188884601462120536722150134676588633429
            )
            mstore(
                add(mload(add(vk, 0x1e0)), 0x20),
                18051927297986484527611703191585266713528321784715802343699150271856051244721
            )
            // qH2
            mstore(
                mload(add(vk, 0x200)),
                17183091890960203175777065490726876011944304977299231686457191186480347944964
            )
            mstore(
                add(mload(add(vk, 0x200)), 0x20),
                4490401529426574565331238171714181866458606184922225399124187058005801778892
            )
            // qH3
            mstore(
                mload(add(vk, 0x220)),
                1221754396433704762941109064372027557900417150628742839724350141274324105531
            )
            mstore(
                add(mload(add(vk, 0x220)), 0x20),
                5852202975250895807153833762470523277935452126865915206223172229093142057204
            )
            // qH4
            mstore(
                mload(add(vk, 0x240)),
                15942219407079940317108327336758085920828255563342347502490598820248118460133
            )
            mstore(
                add(mload(add(vk, 0x240)), 0x20),
                13932908789216121516788648116401360726086794781411868046768741292235436938527
            )
            // qEcc
            mstore(
                mload(add(vk, 0x260)),
                11253921189643581015308547816247612243572238063440388125238308675751100437670
            )
            mstore(
                add(mload(add(vk, 0x260)), 0x20),
                21538818198962061056994656088458979220103547193654086011201760604068846580076
            )
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
//
// Copyright (c) 2022 Espresso Systems (espressosys.com)
// This file is part of the Configurable Asset Privacy for Ethereum (CAPE) library.
//
// This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

//
// Based on:
// - Christian Reitwiessner: https://gist.githubusercontent.com/chriseth/f9be9d9391efc5beb9704255a8e2989d/raw/4d0fb90847df1d4e04d507019031888df8372239/snarktest.solidity
// - Aztec: https://github.com/AztecProtocol/aztec-2-bug-bounty

pragma solidity ^0.8.0;

import "./Utils.sol";

/// @notice Barreto-Naehrig curve over a 254 bit prime field
library BN254 {
    // use notation from https://datatracker.ietf.org/doc/draft-irtf-cfrg-pairing-friendly-curves/
    //
    // Elliptic curve is defined over a prime field GF(p), with embedding degree k.
    // Short Weierstrass (SW form) is, for a, b \in GF(p^n) for some natural number n > 0:
    //   E: y^2 = x^3 + a * x + b
    //
    // Pairing is defined over cyclic subgroups G1, G2, both of which are of order r.
    // G1 is a subgroup of E(GF(p)), G2 is a subgroup of E(GF(p^k)).
    //
    // BN family are parameterized curves with well-chosen t,
    //   p = 36 * t^4 + 36 * t^3 + 24 * t^2 + 6 * t + 1
    //   r = 36 * t^4 + 36 * t^3 + 18 * t^2 + 6 * t + 1
    // for some integer t.
    // E has the equation:
    //   E: y^2 = x^3 + b
    // where b is a primitive element of multiplicative group (GF(p))^* of order (p-1).
    // A pairing e is defined by taking G1 as a subgroup of E(GF(p)) of order r,
    // G2 as a subgroup of E'(GF(p^2)),
    // and G_T as a subgroup of a multiplicative group (GF(p^12))^* of order r.
    //
    // BN254 is defined over a 254-bit prime order p, embedding degree k = 12.
    uint256 public constant P_MOD =
        21888242871839275222246405745257275088696311157297823662689037894645226208583;
    uint256 public constant R_MOD =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    struct G1Point {
        uint256 x;
        uint256 y;
    }

    // G2 group element where x \in Fp2 = x0 * z + x1
    struct G2Point {
        uint256 x0;
        uint256 x1;
        uint256 y0;
        uint256 y1;
    }

    /// @return the generator of G1
    // solhint-disable-next-line func-name-mixedcase
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }

    /// @return the generator of G2
    // solhint-disable-next-line func-name-mixedcase
    function P2() internal pure returns (G2Point memory) {
        return
            G2Point({
                x0: 0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2,
                x1: 0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed,
                y0: 0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b,
                y1: 0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa
            });
    }

    /// @dev check if a G1 point is Infinity
    /// @notice precompile bn256Add at address(6) takes (0, 0) as Point of Infinity,
    /// some crypto libraries (such as arkwork) uses a boolean flag to mark PoI, and
    /// just use (0, 1) as affine coordinates (not on curve) to represents PoI.
    function isInfinity(G1Point memory point) internal pure returns (bool result) {
        assembly {
            let x := mload(point)
            let y := mload(add(point, 0x20))
            result := and(iszero(x), iszero(y))
        }
    }

    /// @return r the negation of p, i.e. p.add(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory) {
        if (isInfinity(p)) {
            return p;
        }
        return G1Point(p.x, P_MOD - (p.y % P_MOD));
    }

    /// @return res = -fr the negation of scalar field element.
    function negate(uint256 fr) internal pure returns (uint256 res) {
        return R_MOD - (fr % R_MOD);
    }

    /// @return r the sum of two points of G1
    function add(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint256[4] memory input;
        input[0] = p1.x;
        input[1] = p1.y;
        input[2] = p2.x;
        input[3] = p2.y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                revert(0, 0)
            }
        }
        require(success, "Bn254: group addition failed!");
    }

    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.mul(1) and p.add(p) == p.mul(2) for all points p.
    function scalarMul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
        uint256[3] memory input;
        input[0] = p.x;
        input[1] = p.y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                revert(0, 0)
            }
        }
        require(success, "Bn254: scalar mul failed!");
    }

    /// @dev Multi-scalar Mulitiplication (MSM)
    /// @return r = \Prod{B_i^s_i} where {s_i} are `scalars` and {B_i} are `bases`
    function multiScalarMul(G1Point[] memory bases, uint256[] memory scalars)
        internal
        view
        returns (G1Point memory r)
    {
        require(scalars.length == bases.length, "MSM error: length does not match");

        r = scalarMul(bases[0], scalars[0]);
        for (uint256 i = 1; i < scalars.length; i++) {
            r = add(r, scalarMul(bases[i], scalars[i]));
        }
    }

    /// @dev Compute f^-1 for f \in Fr scalar field
    /// @notice credit: Aztec, Spilsbury Holdings Ltd
    function invert(uint256 fr) internal view returns (uint256 output) {
        bool success;
        uint256 p = R_MOD;
        assembly {
            let mPtr := mload(0x40)
            mstore(mPtr, 0x20)
            mstore(add(mPtr, 0x20), 0x20)
            mstore(add(mPtr, 0x40), 0x20)
            mstore(add(mPtr, 0x60), fr)
            mstore(add(mPtr, 0x80), sub(p, 2))
            mstore(add(mPtr, 0xa0), p)
            success := staticcall(gas(), 0x05, mPtr, 0xc0, 0x00, 0x20)
            output := mload(0x00)
        }
        require(success, "Bn254: pow precompile failed!");
    }

    /**
     * validate the following:
     *   x != 0
     *   y != 0
     *   x < p
     *   y < p
     *   y^2 = x^3 + 3 mod p
     */
    /// @dev validate G1 point and check if it is on curve
    /// @notice credit: Aztec, Spilsbury Holdings Ltd
    function validateG1Point(G1Point memory point) internal pure {
        bool isWellFormed;
        uint256 p = P_MOD;
        assembly {
            let x := mload(point)
            let y := mload(add(point, 0x20))

            isWellFormed := and(
                and(and(lt(x, p), lt(y, p)), not(or(iszero(x), iszero(y)))),
                eq(mulmod(y, y, p), addmod(mulmod(x, mulmod(x, x, p), p), 3, p))
            )
        }
        require(isWellFormed, "Bn254: invalid G1 point");
    }

    /// @dev Validate scalar field, revert if invalid (namely if fr > r_mod).
    /// @notice Writing this inline instead of calling it might save gas.
    function validateScalarField(uint256 fr) internal pure {
        bool isValid;
        assembly {
            isValid := lt(fr, R_MOD)
        }
        require(isValid, "Bn254: invalid scalar field");
    }

    /// @dev Evaluate the following pairing product:
    /// @dev e(a1, a2).e(-b1, b2) == 1
    /// @dev caller needs to ensure that a1, a2, b1 and b2 are within proper group
    /// @notice credit: Aztec, Spilsbury Holdings Ltd
    function pairingProd2(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2
    ) internal view returns (bool) {
        uint256 out;
        bool success;
        assembly {
            let mPtr := mload(0x40)
            mstore(mPtr, mload(a1))
            mstore(add(mPtr, 0x20), mload(add(a1, 0x20)))
            mstore(add(mPtr, 0x40), mload(a2))
            mstore(add(mPtr, 0x60), mload(add(a2, 0x20)))
            mstore(add(mPtr, 0x80), mload(add(a2, 0x40)))
            mstore(add(mPtr, 0xa0), mload(add(a2, 0x60)))

            mstore(add(mPtr, 0xc0), mload(b1))
            mstore(add(mPtr, 0xe0), mload(add(b1, 0x20)))
            mstore(add(mPtr, 0x100), mload(b2))
            mstore(add(mPtr, 0x120), mload(add(b2, 0x20)))
            mstore(add(mPtr, 0x140), mload(add(b2, 0x40)))
            mstore(add(mPtr, 0x160), mload(add(b2, 0x60)))
            success := staticcall(gas(), 8, mPtr, 0x180, 0x00, 0x20)
            out := mload(0x00)
        }
        require(success, "Bn254: Pairing check failed!");
        return (out != 0);
    }

    function fromLeBytesModOrder(bytes memory leBytes) internal pure returns (uint256 ret) {
        for (uint256 i = 0; i < leBytes.length; i++) {
            ret = mulmod(ret, 256, R_MOD);
            ret = addmod(ret, uint256(uint8(leBytes[leBytes.length - 1 - i])), R_MOD);
        }
    }

    /// @dev Check if y-coordinate of G1 point is negative.
    function isYNegative(G1Point memory point) internal pure returns (bool) {
        return (point.y << 1) < P_MOD;
    }

    // @dev Perform a modular exponentiation.
    // @return base^exponent (mod modulus)
    // This method is ideal for small exponents (~64 bits or less), as it is cheaper than using the pow precompile
    // @notice credit: credit: Aztec, Spilsbury Holdings Ltd
    function powSmall(
        uint256 base,
        uint256 exponent,
        uint256 modulus
    ) internal pure returns (uint256) {
        uint256 result = 1;
        uint256 input = base;
        uint256 count = 1;

        assembly {
            let endpoint := add(exponent, 0x01)
            for {

            } lt(count, endpoint) {
                count := add(count, count)
            } {
                if and(exponent, count) {
                    result := mulmod(result, input, modulus)
                }
                input := mulmod(input, input, modulus)
            }
        }

        return result;
    }

    function g1Serialize(G1Point memory point) internal pure returns (bytes memory) {
        uint256 mask = 0;

        // Set the 254-th bit to 1 for infinity
        // https://docs.rs/ark-serialize/0.3.0/src/ark_serialize/flags.rs.html#117
        if (isInfinity(point)) {
            mask |= 0x4000000000000000000000000000000000000000000000000000000000000000;
        }

        // Set the 255-th bit to 1 for positive Y
        // https://docs.rs/ark-serialize/0.3.0/src/ark_serialize/flags.rs.html#118
        if (!isYNegative(point)) {
            mask = 0x8000000000000000000000000000000000000000000000000000000000000000;
        }

        return abi.encodePacked(Utils.reverseEndianness(point.x | mask));
    }

    function g1Deserialize(bytes32 input) internal view returns (G1Point memory point) {
        uint256 mask = 0x4000000000000000000000000000000000000000000000000000000000000000;
        uint256 x = Utils.reverseEndianness(uint256(input));
        uint256 y;
        bool isQuadraticResidue;
        bool isYPositive;
        if (x & mask != 0) {
            // the 254-th bit == 1 for infinity
            x = 0;
            y = 0;
        } else {
            // Set the 255-th bit to 1 for positive Y
            mask = 0x8000000000000000000000000000000000000000000000000000000000000000;
            isYPositive = (x & mask != 0);
            // mask off the first two bits of x
            mask = 0x3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
            x &= mask;

            // solve for y where E: y^2 = x^3 + 3
            y = mulmod(x, x, P_MOD);
            y = mulmod(y, x, P_MOD);
            y = addmod(y, 3, P_MOD);
            (isQuadraticResidue, y) = quadraticResidue(y);

            require(isQuadraticResidue, "deser fail: not on curve");

            if (isYPositive) {
                y = P_MOD - y;
            }
        }

        point = G1Point(x, y);
    }

    function quadraticResidue(uint256 x)
        internal
        view
        returns (bool isQuadraticResidue, uint256 a)
    {
        bool success;
        // e = (p+1)/4
        uint256 e = 0xc19139cb84c680a6e14116da060561765e05aa45a1c72a34f082305b61f3f52;
        uint256 p = P_MOD;

        // we have p == 3 mod 4 therefore
        // a = x^((p+1)/4)
        assembly {
            // credit: Aztec
            let mPtr := mload(0x40)
            mstore(mPtr, 0x20)
            mstore(add(mPtr, 0x20), 0x20)
            mstore(add(mPtr, 0x40), 0x20)
            mstore(add(mPtr, 0x60), x)
            mstore(add(mPtr, 0x80), e)
            mstore(add(mPtr, 0xa0), p)
            success := staticcall(gas(), 0x05, mPtr, 0xc0, 0x00, 0x20)
            a := mload(0x00)
        }
        require(success, "pow precompile call failed!");

        // ensure a < p/2
        if (a << 1 > p) {
            a = p - a;
        }

        // check if a^2 = x, if not x is not a quadratic residue
        e = mulmod(a, a, p);

        isQuadraticResidue = (e == x);
    }
}
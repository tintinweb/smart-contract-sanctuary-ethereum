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

import "hardhat/console.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@rari-capital/solmate/src/utils/SafeTransferLib.sol";

import "solidity-bytes-utils/contracts/BytesLib.sol";
import "./libraries/AccumulatingArray.sol";
import "./libraries/EdOnBN254.sol";
import "./libraries/RescueLib.sol";
import "./libraries/VerifyingKeys.sol";
import "./interfaces/IPlonkVerifier.sol";
import "./AssetRegistry.sol";
import "./RecordsMerkleTree.sol";
import "./RootStore.sol";

contract CAPE is RecordsMerkleTree, RootStore, AssetRegistry, ReentrancyGuard {
    using AccumulatingArray for AccumulatingArray.Data;

    mapping(uint256 => bool) public nullifiers;
    uint64 public blockHeight;
    IPlonkVerifier private _verifier;
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
    event BlockCommitted(uint64 indexed height, uint256[] depositCommitments);
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
        uint64 mintAmount;
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
        uint64 fee;
        uint64 validUntil;
        EdOnBN254.EdOnBN254Point txnMemoVerKey;
        bytes extraProofBoundData;
    }

    struct MintAuxInfo {
        uint256 merkleRoot;
        uint64 fee;
        EdOnBN254.EdOnBN254Point txnMemoVerKey;
    }

    struct FreezeAuxInfo {
        uint256 merkleRoot;
        uint64 fee;
        EdOnBN254.EdOnBN254Point txnMemoVerKey;
    }

    struct RecordOpening {
        uint64 amount;
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
    /// @param merkleTreeHeight height of the merkle tree that stores the asset record commitments
    /// @param nRoots number of the most recent roots of the records merkle tree to be stored
    /// @param verifierAddr address of the Plonk Verifier contract
    constructor(
        uint8 merkleTreeHeight,
        uint64 nRoots,
        address verifierAddr
    ) RecordsMerkleTree(merkleTreeHeight) RootStore(nRoots) {
        _verifier = IPlonkVerifier(verifierAddr);

        // NOTE: used for faucet in testnet only, will be removed for mainnet
        deployer = msg.sender;
    }

    /// @notice Allocate native token faucet to a manager. For testnet only.
    /// @param faucetManagerAddress address of public key of faucet manager for CAP native token (testnet only!)
    /// @param faucetManagerEncKey public key of faucet manager for CAP native token (testnet only!)
    function faucetSetupForTestnet(
        EdOnBN254.EdOnBN254Point memory faucetManagerAddress,
        bytes32 faucetManagerEncKey
    ) public {
        // faucet can only be set up once by the manager
        require(msg.sender == deployer, "Only invocable by deployer");
        require(!faucetInitialized, "Faucet already set up");

        // allocate maximum possible amount of native CAP token to faucet manager on testnet
        // max amount len is set to 63 bits: https://github.com/EspressoSystems/cap/blob/main/src/constants.rs#L50-L51
        RecordOpening memory ro = RecordOpening(
            type(uint64).max / 2,
            nativeDomesticAsset(),
            faucetManagerAddress,
            faucetManagerEncKey,
            false,
            0 // arbitrary blind factor
        );
        uint256[] memory recordCommitments = new uint256[](1);
        recordCommitments[0] = _deriveRecordCommitment(ro);

        // insert the record into record accumulator
        _updateRecordsMerkleTree(recordCommitments);
        _addRoot(_rootValue);

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
    function depositErc20(RecordOpening memory ro, address erc20Address) public nonReentrant {
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
    /// @param extraData extra data to be stored in calldata; this data is ignored by the contract function
    // solhint-disable-next-line no-unused-vars
    function submitCapeBlockWithMemos(CapeBlock memory newBlock, bytes calldata extraData) public {
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
            _updateRecordsMerkleTree(commitments.items);
            _addRoot(_rootValue);
        }

        // In all cases (the block is empty or not), the height is incremented.
        blockHeight += 1;

        // Inform clients about the new block and the processed deposits.
        emit BlockCommitted(blockHeight, pendingDeposits);

        // Empty the queue now that the record commitments have been inserted
        delete pendingDeposits;
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
        vk = VerifyingKeys.getVkById(
            VerifyingKeys.getEncodedId(
                uint8(NoteType.TRANSFER),
                uint8(note.inputNullifiers.length),
                uint8(note.outputCommitments.length),
                uint8(_merkleTreeHeight)
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
        vk = VerifyingKeys.getVkById(
            VerifyingKeys.getEncodedId(
                uint8(NoteType.MINT),
                1, // num of input
                2, // num of output
                uint8(_merkleTreeHeight)
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
        vk = VerifyingKeys.getVkById(
            VerifyingKeys.getEncodedId(
                uint8(NoteType.FREEZE),
                uint8(note.inputNullifiers.length),
                uint8(note.outputCommitments.length),
                uint8(_merkleTreeHeight)
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
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
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

    /// @dev check if a G1 point is Infinity
    /// @notice precompile bn256Add at address(6) takes (0, 0) as Point of Infinity,
    /// some crypto libraries (such as arkwork) uses a boolean flag to mark PoI, and
    /// just use (0, 1) as affine coordinates (not on curve) to represents PoI.
    function isInfinity(EdOnBN254Point memory point) internal pure returns (bool result) {
        assembly {
            let x := mload(point)
            let y := mload(add(point, 0x20))
            result := and(iszero(x), iszero(y))
        }
    }

    /// @dev Check if y-coordinate of G1 point is negative.
    function isYNegative(EdOnBN254Point memory point) internal pure returns (bool) {
        return (point.y << 1) < P_MOD;
    }

    function serialize(EdOnBN254Point memory point) internal pure returns (bytes memory res) {
        uint256 mask;
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

    uint256 private constant _N_ROUNDS = 12;
    uint256 private constant _STATE_SIZE = 4;
    uint256 private constant _SCHEDULED_KEY_SIZE = (2 * _N_ROUNDS + 1) * _STATE_SIZE;

    // Obtained by running KeyScheduling([0,0,0,0]). See Algorithm 2 of AT specification document.
    // solhint-disable-next-line var-name-mixedcase

    uint256 private constant _PRIME =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    uint256 private constant _ALPHA = 5;

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
        uint256 s0,
        uint256 s1,
        uint256 s2,
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

    // Must be public so it doesn't get inlined into CAPE.sol and blow
    // the size limit
    function commit(uint256[15] memory inputs) public view returns (uint256) {
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

import "./libraries/BN254.sol";
import "./libraries/EdOnBN254.sol";

contract AssetRegistry {
    bytes13 public constant DOM_SEP_FOREIGN_ASSET = "FOREIGN_ASSET";
    bytes14 public constant DOM_SEP_DOMESTIC_ASSET = "DOMESTIC_ASSET";
    uint256 public constant CAP_NATIVE_ASSET_CODE = 1;

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
        uint64 revealThreshold;
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
    function sponsorCapeAsset(address erc20Address, AssetDefinition memory newAsset) public {
        require(erc20Address != address(0), "Bad asset address");
        require(!isCapeAssetRegistered(newAsset), "Asset already registered");

        _checkForeignAssetCode(newAsset.code, erc20Address, msg.sender, newAsset.policy);

        bytes32 key = keccak256(abi.encode(newAsset));
        assets[key] = erc20Address;
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

import "hardhat/console.sol";
import "./libraries/RescueLib.sol";

contract RecordsMerkleTree {
    enum Position {
        LEFT,
        MIDDLE,
        RIGHT
    }

    // Representation of a (tree) node
    // A node contains a value and pointers (which are index in an array of other nodes).
    // By convention a node that has no (left,middle,right) children will point to index 0.
    struct Node {
        uint256 val;
        uint64 left; // Pointer (index) to the left child
        uint64 middle; // Pointer (index) to the middle child
        uint64 right; // Pointer (index) to the right child
    }

    uint256 internal _rootValue;
    uint64 internal _numLeaves;
    uint8 internal _merkleTreeHeight;

    mapping(uint256 => uint256) internal _flattenedFrontier;

    /// @dev Create a records Merkle tree of the given height.
    /// @param merkleTreeHeight The height
    constructor(uint8 merkleTreeHeight) {
        _rootValue = 0;
        _numLeaves = 0;
        _merkleTreeHeight = merkleTreeHeight;
    }

    /// @dev Is the given node a terminal node?
    /// @param node A node
    /// @return _ True if the node is terminal, false otherwise.
    function _isTerminal(Node memory node) private pure returns (bool) {
        return (node.left == 0) && (node.middle == 0) && (node.right == 0);
    }

    /// @dev Does the given node have children?
    /// @param node A node
    /// @return _ True if the node has at least one child, false otherwise
    function _hasChildren(Node memory node) private pure returns (bool) {
        return !_isTerminal(node);
    }

    /// @dev Is the given node null?
    /// @param node A node
    /// @return _ True if the node is NULL, false otherwise
    function _isNull(Node memory node) private pure returns (bool) {
        return (node.val == 0 && _isTerminal(node));
    }

    /// @dev Create a new "hole node" at the given position in the
    /// tree. A cursor position can be obtained from an extant node or
    /// from a function that returns a position such as _buildTreeFromFrontier.
    /// @param cursor The index of the node in the array of nodes
    /// @param posSibling The position of the sibling i.e. (LEFT, MIDDLE or RIGHT)
    /// @return _ The new created node
    function _createHoleNode(uint64 cursor, Position posSibling)
        private
        pure
        returns (Node memory)
    {
        // Copy pasting these values to save gas
        // indexHoleNode = cursor - 3;
        // indexFirstSibling = cursor - 2;
        // indexSecondSibling = cursor - 1;

        Node memory node;
        if (posSibling == Position.LEFT) {
            node = Node(0, cursor - 3, cursor - 2, cursor - 1);
        } else if (posSibling == Position.MIDDLE) {
            node = Node(0, cursor - 2, cursor - 3, cursor - 1);
        } else if (posSibling == Position.RIGHT) {
            node = Node(0, cursor - 2, cursor - 1, cursor - 3);
        }

        return node;
    }

    /// @dev Create a Merkle tree from the given frontier.
    /// @param nodes The list of nodes to be filled or updated
    /// @return A cursor to the root node of the create tree
    function _buildTreeFromFrontier(Node[] memory nodes) internal view returns (uint64) {
        // Tree is empty
        if (_numLeaves == 0) {
            nodes[0] = Node(0, 0, 0, 0); // Empty node
            nodes[1] = Node(0, 0, 0, 0); // Root node
            return 1;
        }

        // Tree is not empty

        // Set the first node to the NULL node
        nodes[0] = Node(0, 0, 0, 0);

        // Insert the leaf
        nodes[1] = Node(_flattenedFrontier[0], 0, 0, 0);

        // Insert the siblings
        nodes[2] = Node(_flattenedFrontier[1], 0, 0, 0);
        nodes[3] = Node(_flattenedFrontier[2], 0, 0, 0);

        // Compute the position of each node
        uint64 absolutePosition = _numLeaves - 1;
        uint8 localPosition = uint8(absolutePosition % 3);

        // We process the nodes of the Merkle path
        uint64 cursor = 4;
        uint64 cursorFrontier = 3;

        // Build the tree expect the root node
        while (cursor < 3 * _merkleTreeHeight + 1) {
            nodes[cursor] = _createHoleNode(cursor, Position(localPosition));

            // Create the siblings of the "hole node". These siblings have no children
            nodes[cursor + 1] = Node(_flattenedFrontier[cursorFrontier], 0, 0, 0);
            nodes[cursor + 2] = Node(_flattenedFrontier[cursorFrontier + 1], 0, 0, 0);

            // Move forward
            absolutePosition /= 3;
            localPosition = uint8(absolutePosition % 3);

            cursor += 3;
            cursorFrontier += 2;
        }

        // Add the root node
        nodes[cursor] = _createHoleNode(cursor, Position(localPosition));
        return cursor;
    }

    /// @dev Compute the index of the next node when going down in the tree.
    /// @param nodes The list of nodes of the tree
    /// @param nodeIndex The index of the starting node
    /// @param pos The position for going down, i.e. LEFT, MIDDLE or RIGHT.
    /// @return The index of the next node
    function _nextNodeIndex(
        Node[] memory nodes,
        uint64 nodeIndex,
        Position pos
    ) private pure returns (uint64) {
        uint64 res;

        if (pos == Position.LEFT) {
            res = nodes[nodeIndex].left;
        } else if (pos == Position.MIDDLE) {
            res = nodes[nodeIndex].middle;
        } else if (pos == Position.RIGHT) {
            res = nodes[nodeIndex].right;
        }

        return res;
    }

    /// @dev Update the child of a node based on the position (which child to select) and an index to the new child.
    /// @param node node for which we want to update the child
    /// @param newChildIndex index of the new child
    /// @param pos position of the child node relative to the node (i.e. LEFT, MIDDLE or RIGHT)
    function _updateChildNode(
        Node memory node,
        uint64 newChildIndex,
        Position pos
    ) private pure {
        // Update the node
        if (pos == Position.LEFT) {
            node.left = newChildIndex;
        } else if (pos == Position.MIDDLE) {
            node.middle = newChildIndex;
        } else if (pos == Position.RIGHT) {
            node.right = newChildIndex;
        }
    }

    function _computeNodePos(uint64 absolutePos, uint64 branchIndex)
        private
        view
        returns (uint64, uint64)
    {
        uint64 localPos;
        uint64 divisor = uint64(3**(_merkleTreeHeight - branchIndex - 1));

        localPos = absolutePos / divisor;
        absolutePos = absolutePos % divisor;

        return (absolutePos, localPos);
    }

    /// @notice Insert an element into the tree in the position num_leaves.
    /// @param nodes The array of nodes
    /// @param rootIndex The index of the root node
    /// @param maxIndex The index of the latest element inserted in the nodes array
    /// @param element The value of the element to insert into the tree
    /// @return updated the value of maxIndex
    function _pushElement(
        Node[] memory nodes,
        uint64 rootIndex,
        uint64 maxIndex,
        uint256 element
    ) private returns (uint64) {
        require(_numLeaves < 3**_merkleTreeHeight, "The tree is full.");

        // Get the position of the leaf from the smart contract state
        uint64 leafPos = _numLeaves;
        uint64 branchIndex = 0;
        uint64 currentNodeIndex = rootIndex;
        uint64 previousNodeIndex = rootIndex;

        // Go down inside the tree until finding the first terminal node.
        uint64 absolutePos = leafPos;
        uint64 localPos = 0;
        while (!_isNull(nodes[currentNodeIndex])) {
            (absolutePos, localPos) = _computeNodePos(absolutePos, branchIndex);

            previousNodeIndex = currentNodeIndex;
            currentNodeIndex = _nextNodeIndex(nodes, currentNodeIndex, Position(localPos));

            branchIndex += 1;
        }

        // maxIndex tracks the index of the last element inserted in the tree
        uint64 newNodeIndex = maxIndex + 1;

        // Create new nodes until completing the path one level above the leaf level
        // Always inserting to the left

        // To compensate the extra increment at the end of the previous loop ,
        // except if the tree is reduced to a single root node.
        if (branchIndex > 0) {
            branchIndex -= 1;
        }

        while (branchIndex < _merkleTreeHeight - 1) {
            nodes[newNodeIndex] = Node(0, 0, 0, 0);
            _updateChildNode(nodes[previousNodeIndex], newNodeIndex, Position(localPos));

            // Prepare the next iteration of the loop
            previousNodeIndex = newNodeIndex;
            newNodeIndex += 1;
            branchIndex += 1;
            (absolutePos, localPos) = _computeNodePos(absolutePos, branchIndex);
        }

        // The last node contains the leaf value (compute the hash)
        // Remember position is computed with the remainder

        // Leaf node where the value is hash(0,_numLeaves,element)
        uint256 val = RescueLib.hash(0, _numLeaves, element);
        nodes[newNodeIndex] = Node(val, 0, 0, 0);
        _updateChildNode(nodes[previousNodeIndex], newNodeIndex, Position(localPos));

        // Increment the number of leaves
        _numLeaves += 1;

        // Return the new value of maxIndex
        return newNodeIndex;
    }

    /// @dev Store the frontier.
    /// @param nodes The list of node of the tree
    /// @param rootIndex The index of the root node
    function _storeFrontier(Node[] memory nodes, uint64 rootIndex) private {
        uint64 frontierSize = 2 * _merkleTreeHeight + 1;

        /// Collect the values from the root to the leaf but in reverse order
        uint64 currentNodeIndex = rootIndex;
        uint64 firstSiblingIndex = 0;
        uint64 secondSiblingIndex = 0;
        // Go down until the leaf
        for (uint256 i = 0; i < _merkleTreeHeight; i++) {
            // Pick the non-empty node that is most right
            Node memory currentNode = nodes[currentNodeIndex];
            if (!_isNull(nodes[currentNode.right])) {
                // Keep to the right
                currentNodeIndex = currentNode.right;
                firstSiblingIndex = currentNode.left;
                secondSiblingIndex = currentNode.middle;
            } else if (!_isNull(nodes[currentNode.middle])) {
                // Keep to the middle
                currentNodeIndex = currentNode.middle;
                firstSiblingIndex = currentNode.left;
                secondSiblingIndex = currentNode.right;
            } else {
                // Keep to the left
                currentNodeIndex = currentNode.left;
                firstSiblingIndex = currentNode.middle;
                secondSiblingIndex = currentNode.right;
            }
            uint256 secondSiblingPos = frontierSize - 1 - (2 * i);
            uint256 firstSiblingPos = secondSiblingPos - 1;
            _flattenedFrontier[secondSiblingPos] = nodes[secondSiblingIndex].val;
            _flattenedFrontier[firstSiblingPos] = nodes[firstSiblingIndex].val;
        }
        // currentNodeIndex points to the leaf
        _flattenedFrontier[0] = nodes[currentNodeIndex].val;
    }

    /// @dev Update the state of the record merkle tree by inserting new elements.
    /// @param elements The list of elements to be appended to the current merkle tree described by the frontier.
    function _updateRecordsMerkleTree(uint256[] memory elements) internal {
        // The total number of nodes is bounded by 3*height+1 + 3*N*height = 3*(N+1)*height + 1
        // where N is the number of new records
        uint256 numElements = elements.length;
        Node[] memory nodes = new Node[](3 * (numElements + 1) * _merkleTreeHeight + 2);

        /// Insert the new elements ///

        // maxIndex tracks the index of the last element inserted in the tree
        uint64 rootIndex = _buildTreeFromFrontier(nodes);
        uint64 maxIndex = rootIndex;
        for (uint32 i = 0; i < elements.length; i++) {
            maxIndex = _pushElement(nodes, rootIndex, maxIndex, elements[i]);
        }
        //// Compute the root hash value ////
        _rootValue = _computeRootValueAndUpdateTree(nodes, rootIndex);

        //// Store the frontier
        _storeFrontier(nodes, rootIndex);
    }

    /// @notice Returns the root value of the Merkle tree.
    function getRootValue() public view returns (uint256) {
        return _rootValue;
    }

    /// @dev Update the tree by hashing the children of each node.
    /// @param nodes The tree. Note that the nodes are updated by this function.
    /// @param rootNodePos The index of the root node in the list of nodes.
    /// @return The value obtained at the root.
    function _computeRootValueAndUpdateTree(Node[] memory nodes, uint256 rootNodePos)
        private
        returns (uint256)
    {
        // If the root node has no children return its value
        Node memory rootNode = nodes[rootNodePos];
        if (_isTerminal(rootNode)) {
            return rootNode.val;
        } else {
            uint256 valLeft = _computeRootValueAndUpdateTree(nodes, rootNode.left);
            uint256 valMiddle = _computeRootValueAndUpdateTree(nodes, rootNode.middle);
            uint256 valRight = _computeRootValueAndUpdateTree(nodes, rootNode.right);

            nodes[rootNode.left].val = valLeft;
            nodes[rootNode.middle].val = valMiddle;
            nodes[rootNode.right].val = valRight;

            return RescueLib.hash(valLeft, valMiddle, valRight);
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
                2601115423116897239893469437783815282674518870859439140584670982404446568425
            )
            mstore(
                add(mload(add(vk, 0x40)), 0x20),
                21387703072596271753684269571766318413616637905846906200885488548605232081311
            )
            // sigma1
            mstore(
                mload(add(vk, 0x60)),
                18093207667326166260941967361503597170970820090303504008548886520781612262607
            )
            mstore(
                add(mload(add(vk, 0x60)), 0x20),
                15506241883427907423143246742207987178296655397323901395523216644162934801027
            )
            // sigma2
            mstore(
                mload(add(vk, 0x80)),
                17224030688930263671215927622085796838744685640551295700644356316087606194453
            )
            mstore(
                add(mload(add(vk, 0x80)), 0x20),
                9871892688266980794424413228644800345365261123544262124587988616929094794446
            )
            // sigma3
            mstore(
                mload(add(vk, 0xa0)),
                1653423479825136378929731986206672195437753469049273770949830103289522081013
            )
            mstore(
                add(mload(add(vk, 0xa0)), 0x20),
                18540430158936383317781049369976810237215202752760467051838384048905582651431
            )
            // sigma4
            mstore(
                mload(add(vk, 0xc0)),
                6182405487934559918414504166029367587453938777975619206648907759838313063029
            )
            mstore(
                add(mload(add(vk, 0xc0)), 0x20),
                6303636105426570943547672403434638798256828205198194404179645009191642748039
            )

            // q1
            mstore(
                mload(add(vk, 0xe0)),
                18352717355200151877063864360131237083352005873169286557578537755751979692274
            )
            mstore(
                add(mload(add(vk, 0xe0)), 0x20),
                18535115788456072630383925322523695497891623428396234248738154081372899880584
            )
            // q2
            mstore(
                mload(add(vk, 0x100)),
                9908258779995310745701077146291771577159654333216970234243768106420988535639
            )
            mstore(
                add(mload(add(vk, 0x100)), 0x20),
                5222835988549975732420424607539021146071370844807206884805011103538281824730
            )
            // q3
            mstore(
                mload(add(vk, 0x120)),
                6941500137865112460544627950260307723514017850007311936769317146419972927588
            )
            mstore(
                add(mload(add(vk, 0x120)), 0x20),
                15349893608573380976411985659730584619173031566937770787699017806561190627468
            )
            // q4
            mstore(
                mload(add(vk, 0x140)),
                21168364095257448760606101143948858356172338924320104703900203452473902441433
            )
            mstore(
                add(mload(add(vk, 0x140)), 0x20),
                16660170798361651209023038026794900976183585114965877304784822006074874509205
            )

            // qM12
            mstore(
                mload(add(vk, 0x160)),
                9190952913639104387810968179432225180425197597955362124827814569885452163057
            )
            mstore(
                add(mload(add(vk, 0x160)), 0x20),
                18827142612117658766343514941168256204525012530604946506087566444465709027496
            )
            // qM34
            mstore(
                mload(add(vk, 0x180)),
                3087614871980473279723363167422819790187289361998206527420814175739516849267
            )
            mstore(
                add(mload(add(vk, 0x180)), 0x20),
                16862987149935139591372068460264503091703957897443470436032581481036423083811
            )

            // qO
            mstore(
                mload(add(vk, 0x1a0)),
                9706719488655451993063181268308257527997835452929632143872066940077818386420
            )
            mstore(
                add(mload(add(vk, 0x1a0)), 0x20),
                6236623652447614250698035805861101061802099331620117231564769714805411900300
            )
            // qC
            mstore(
                mload(add(vk, 0x1c0)),
                1411379008735327479737723833603528702843470627344722114111584994556861154980
            )
            mstore(
                add(mload(add(vk, 0x1c0)), 0x20),
                3993135852184128345174580298872023693588782847706666657191331001722079392092
            )
            // qH1
            mstore(
                mload(add(vk, 0x1e0)),
                9846511696349440200252734974300757392144763505883256681697549590162985402181
            )
            mstore(
                add(mload(add(vk, 0x1e0)), 0x20),
                2943021693042093632574100039021179834063372575819762871426673095266988807850
            )
            // qH2
            mstore(
                mload(add(vk, 0x200)),
                6939009262544205005507648947300385820226307867525750603310876841608771115967
            )
            mstore(
                add(mload(add(vk, 0x200)), 0x20),
                1744542086304213974542290661478181313186513167898968854980022885020012543803
            )
            // qH3
            mstore(
                mload(add(vk, 0x220)),
                8552076371570768937374027634488546934769058846143601491495678997242529143831
            )
            mstore(
                add(mload(add(vk, 0x220)), 0x20),
                9579090530940855809150547321287606050563533435045744882440421353731349593486
            )
            // qH4
            mstore(
                mload(add(vk, 0x240)),
                14499786686191977429340953516175958437978725979354053072854149749281625153583
            )
            mstore(
                add(mload(add(vk, 0x240)), 0x20),
                12761628950782571856606556112616580736578801583124069040637032554972765433582
            )
            // qEcc
            mstore(
                mload(add(vk, 0x260)),
                11861036760044642147557768929016751187676005432645929589927048931795306751324
            )
            mstore(
                add(mload(add(vk, 0x260)), 0x20),
                7411647397974044716846852003118581558974144934962247144410611563600239777076
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
                7628022919529421911135408904372797627127922903613932517951676759551756614275
            )
            mstore(
                add(mload(add(vk, 0x40)), 0x20),
                1331524275175103536317606472081114729669777307477986149584111942393705962450
            )
            // sigma1
            mstore(
                mload(add(vk, 0x60)),
                11385474208217093339197684484172860602491108849062309339809203517524255705814
            )
            mstore(
                add(mload(add(vk, 0x60)), 0x20),
                14742740373953540087108822854363852587371950907295700017218827187367528919422
            )
            // sigma2
            mstore(
                mload(add(vk, 0x80)),
                16656283720893277505520180576834218330228640426319787818259624147689712896181
            )
            mstore(
                add(mload(add(vk, 0x80)), 0x20),
                13325231528863913137181084237184355058186595356556894827411039178877487474770
            )
            // sigma3
            mstore(
                mload(add(vk, 0xa0)),
                9189791310770551336126945048086887553526802063485610994702148384774531567947
            )
            mstore(
                add(mload(add(vk, 0xa0)), 0x20),
                14841018178006034931401800499802155298679474918739530511330632965796343701845
            )
            // sigma4
            mstore(
                mload(add(vk, 0xc0)),
                2291377454368026633206063421914664920045658737580871725587615825936361194543
            )
            mstore(
                add(mload(add(vk, 0xc0)), 0x20),
                1302015066005114004951991020555380375564758415605740891074815812171114380677
            )

            // q1
            mstore(
                mload(add(vk, 0xe0)),
                20820380636256451755441529461019761091650992355545157191471886785846828368458
            )
            mstore(
                add(mload(add(vk, 0xe0)), 0x20),
                21593297517126223340469128837410501412961385490498992377256325174187721359792
            )
            // q2
            mstore(
                mload(add(vk, 0x100)),
                18739722115441254876917366518913137925104098218293815822076739449944538511463
            )
            mstore(
                add(mload(add(vk, 0x100)), 0x20),
                21704728059513369811801942736237462547455258303739352819235283602004201892046
            )
            // q3
            mstore(
                mload(add(vk, 0x120)),
                14641591741781012837232454331455337179912058515648809221995273046957404689696
            )
            mstore(
                add(mload(add(vk, 0x120)), 0x20),
                7809440494808817863276605374028021971161141718007334574770841741782286482045
            )
            // q4
            mstore(
                mload(add(vk, 0x140)),
                12825820090241151628814776520261182308841765265286885643232345964438926321859
            )
            mstore(
                add(mload(add(vk, 0x140)), 0x20),
                953744090209979424715539850359172951613856725623925496688974323728989047678
            )

            // qM12
            mstore(
                mload(add(vk, 0x160)),
                12851524982620297419850126451077057609693331882274130781000694680394484937072
            )
            mstore(
                add(mload(add(vk, 0x160)), 0x20),
                275368615438300238729991830030823846019265755187066004752089508827060302546
            )
            // qM34
            mstore(
                mload(add(vk, 0x180)),
                5220853497691242543339709197361896971155747151782855394304800304146652028430
            )
            mstore(
                add(mload(add(vk, 0x180)), 0x20),
                9450857245879300465114294127329293155426034414913673478235624018652474647192
            )

            // qO
            mstore(
                mload(add(vk, 0x1a0)),
                1021365006885138582377179911145719040433890015638098596677854082251708776428
            )
            mstore(
                add(mload(add(vk, 0x1a0)), 0x20),
                11359935238758701707761945142588661021143398751723216197162452144578378060887
            )
            // qC
            mstore(
                mload(add(vk, 0x1c0)),
                13464643739714429050907960983453767858349630205445421978818631227665532763905
            )
            mstore(
                add(mload(add(vk, 0x1c0)), 0x20),
                10339488547668992208892459748774743478364544079101005770106713704130208623574
            )
            // qH1
            mstore(
                mload(add(vk, 0x1e0)),
                9601738305327057050177966434793538325547418147491497810469219037972470343030
            )
            mstore(
                add(mload(add(vk, 0x1e0)), 0x20),
                19301188629352152421673613863134089760610229764460440766611052882385794236638
            )
            // qH2
            mstore(
                mload(add(vk, 0x200)),
                21079123752659904011291969128982548366933951092885387880640877829556396468124
            )
            mstore(
                add(mload(add(vk, 0x200)), 0x20),
                8511476146119618724794262516873338224284052557219121087531014728412456998247
            )
            // qH3
            mstore(
                mload(add(vk, 0x220)),
                15303909812921746731917671857484723288453878023898728858584106908662401059224
            )
            mstore(
                add(mload(add(vk, 0x220)), 0x20),
                18170356242761746817628282114440738046388581044315241707586116980550978579010
            )
            // qH4
            mstore(
                mload(add(vk, 0x240)),
                4268233897088460316569641617170115742335233153775249443326146549729427293896
            )
            mstore(
                add(mload(add(vk, 0x240)), 0x20),
                18974976451146753275247755359852354432882026367027102555776389253422694257840
            )
            // qEcc
            mstore(
                mload(add(vk, 0x260)),
                14659915475225256091079096704713344128669967309925492152251233149380462089822
            )
            mstore(
                add(mload(add(vk, 0x260)), 0x20),
                2059804379395436696412483294937073085747522899756612651966178273428617505712
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
                6443282669730485407595271828674707172530216643022146287503622911791463804043
            )
            mstore(
                add(mload(add(vk, 0x40)), 0x20),
                15696097649475290076149769009458172575519992828166990254810336060070104703870
            )
            // sigma1
            mstore(
                mload(add(vk, 0x60)),
                11681656213736165656499497372446107771337122700468758173231970786274856928411
            )
            mstore(
                add(mload(add(vk, 0x60)), 0x20),
                10450606707405144471114037991073355878505225379403084661718401703948084026025
            )
            // sigma2
            mstore(
                mload(add(vk, 0x80)),
                14949874541546323431113184056978425503852064124202616618464991230985415809296
            )
            mstore(
                add(mload(add(vk, 0x80)), 0x20),
                2755002423044532136780993773451846084085886241086886025824873450959670484164
            )
            // sigma3
            mstore(
                mload(add(vk, 0xa0)),
                21207788223959789592306767368195516108258319638600005910214663887334522784476
            )
            mstore(
                add(mload(add(vk, 0xa0)), 0x20),
                20339433485992657720503614053002752589189874711150471281419370881536035034628
            )
            // sigma4
            mstore(
                mload(add(vk, 0xc0)),
                18631493768208670705485520853887976536695065332427205279642440535222886092292
            )
            mstore(
                add(mload(add(vk, 0xc0)), 0x20),
                6840987554837946884416088276166870742357021362040861629505787964758864275100
            )

            // q1
            mstore(
                mload(add(vk, 0xe0)),
                16178651459227636862542353073855555416097463500529848793096041715723051182880
            )
            mstore(
                add(mload(add(vk, 0xe0)), 0x20),
                5970323786617048090410648683745859437837321145537762222392610864665454314628
            )
            // q2
            mstore(
                mload(add(vk, 0x100)),
                21487420887626536768737123653635887952476328827973824853831940683917744860629
            )
            mstore(
                add(mload(add(vk, 0x100)), 0x20),
                14035356773640867098841015480173597833708530762839998143633620124000312604569
            )
            // q3
            mstore(
                mload(add(vk, 0x120)),
                9545837141279670455258503437926586302673276681048196091959382223343565663038
            )
            mstore(
                add(mload(add(vk, 0x120)), 0x20),
                15947614763344839229459794400790751428004401834477218923635864884401496441892
            )
            // q4
            mstore(
                mload(add(vk, 0x140)),
                12080091524919005971356953696076991358627192379181758361749359305653171768953
            )
            mstore(
                add(mload(add(vk, 0x140)), 0x20),
                17439684987066542572766750059569630478427935655895555459166833681417844092930
            )

            // qM12
            mstore(
                mload(add(vk, 0x160)),
                5701950446803590644135190089832346121657991411362732243298925416080446841465
            )
            mstore(
                add(mload(add(vk, 0x160)), 0x20),
                8332659994290731968190641056516336791258763359210625476231835314984112766413
            )
            // qM34
            mstore(
                mload(add(vk, 0x180)),
                13253969218388213652706314130513753359438541493687814506877280541684975690258
            )
            mstore(
                add(mload(add(vk, 0x180)), 0x20),
                16009690647717929647856071917243036723170363003070166259833423021444206394391
            )

            // qO
            mstore(
                mload(add(vk, 0x1a0)),
                5576536153829630973927473424831889868656235111882426196623002728030063738858
            )
            mstore(
                add(mload(add(vk, 0x1a0)), 0x20),
                11726598312732354680625205255493076317120545671716157650418651212412840704738
            )
            // qC
            mstore(
                mload(add(vk, 0x1c0)),
                5405551642410088215503372225048806703517930422578070794318382858583234132381
            )
            mstore(
                add(mload(add(vk, 0x1c0)), 0x20),
                494379166121476157530708105968326435548569494079142065684457716255857242276
            )
            // qH1
            mstore(
                mload(add(vk, 0x1e0)),
                20704187523716756528180282857397988056049614305908938091015985169373590947598
            )
            mstore(
                add(mload(add(vk, 0x1e0)), 0x20),
                1711039150215717904294641678907719765410368126472104372784057294224997327419
            )
            // qH2
            mstore(
                mload(add(vk, 0x200)),
                18822945583248183258553997348222993649454022267053574236466619892496459777859
            )
            mstore(
                add(mload(add(vk, 0x200)), 0x20),
                14151738140577784330561552892602560699610764417317335382613984109360136167394
            )
            // qH3
            mstore(
                mload(add(vk, 0x220)),
                2387304647210058180508070573733250363855112630235812789983280252196793324601
            )
            mstore(
                add(mload(add(vk, 0x220)), 0x20),
                7685115375159715883862846923594198876658684538946803569647901707992033051886
            )
            // qH4
            mstore(
                mload(add(vk, 0x240)),
                16435018905297869097928961780716739903270571476633582949015154935556284135350
            )
            mstore(
                add(mload(add(vk, 0x240)), 0x20),
                2036767712865186869762381470608151410855938900352103040184478909748435318476
            )
            // qEcc
            mstore(
                mload(add(vk, 0x260)),
                6779994430033977349039006350128159237422794493764381621361585638109046042910
            )
            mstore(
                add(mload(add(vk, 0x260)), 0x20),
                13084743573268695049814429704952197464938266719700894058263626618858073954657
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
                4365063295695407734098092030422194500114525611167655712627428056122142624186
            )
            mstore(
                add(mload(add(vk, 0x40)), 0x20),
                17648899575367849282959371655985071360622117637978776025425654278544743232784
            )
            // sigma1
            mstore(
                mload(add(vk, 0x60)),
                19229298609171917704550205620146530538707290618595618489788704706509380399060
            )
            mstore(
                add(mload(add(vk, 0x60)), 0x20),
                9366445583530691032468963373901151888347106707049340538424220034268172067995
            )
            // sigma2
            mstore(
                mload(add(vk, 0x80)),
                4657881142293773268925215122026170996503718631275522633538536696942206422443
            )
            mstore(
                add(mload(add(vk, 0x80)), 0x20),
                6682064919249131520849949572425793571697722350717545476168686716822772490278
            )
            // sigma3
            mstore(
                mload(add(vk, 0xa0)),
                18672820694823249187431116973704939155134861224915761299789761357243514977708
            )
            mstore(
                add(mload(add(vk, 0xa0)), 0x20),
                21685239528958246637279486174944387953249787084849249068161520129421205287065
            )
            // sigma4
            mstore(
                mload(add(vk, 0xc0)),
                11341667205871784812543471825434136479633117415070795148705128339969197887541
            )
            mstore(
                add(mload(add(vk, 0xc0)), 0x20),
                15914333025955602094633613668908344640062725031699137975756421265633259385119
            )

            // q1
            mstore(
                mload(add(vk, 0xe0)),
                6217748500529110923723880720310662616545440070112879802844803178277212190354
            )
            mstore(
                add(mload(add(vk, 0xe0)), 0x20),
                10456825602788791773928372041085941408190805183139185821777174882414263525097
            )
            // q2
            mstore(
                mload(add(vk, 0x100)),
                20229020333725094514317498336308921999205325122506829745088118255890085128095
            )
            mstore(
                add(mload(add(vk, 0x100)), 0x20),
                16866163950674648834295937044468378870403011911506353324708569445400662446622
            )
            // q3
            mstore(
                mload(add(vk, 0x120)),
                18795601163695220617358154365381152447313136105761716708302907216298615448704
            )
            mstore(
                add(mload(add(vk, 0x120)), 0x20),
                6852811743611751882097071688070552310940375443917510015370020198665338389827
            )
            // q4
            mstore(
                mload(add(vk, 0x140)),
                13671421488538996653981308286125651556069027465299957903168383679098084203442
            )
            mstore(
                add(mload(add(vk, 0x140)), 0x20),
                7416601870894748125122062130631801585960088293201659706702166788591557232968
            )

            // qM12
            mstore(
                mload(add(vk, 0x160)),
                21848197558598980451348938457179007073533701533957450403395774417522613850559
            )
            mstore(
                add(mload(add(vk, 0x160)), 0x20),
                18571426462251429623833169591386575850936507512981527719956550357876213965771
            )
            // qM34
            mstore(
                mload(add(vk, 0x180)),
                683650719279666925943055769128990412221090128919761224799888863076615471158
            )
            mstore(
                add(mload(add(vk, 0x180)), 0x20),
                19295068171919901573355904366209032412612424923020230398834670382428761755820
            )

            // qO
            mstore(
                mload(add(vk, 0x1a0)),
                17206099042702024892546588224370406113352957045506365234908726904388904531216
            )
            mstore(
                add(mload(add(vk, 0x1a0)), 0x20),
                21137376217635218733549469002560707314639004662649542202844777909282739934131
            )
            // qC
            mstore(
                mload(add(vk, 0x1c0)),
                19876962364936657034833267517323318250474404347233679738350861889172344754878
            )
            mstore(
                add(mload(add(vk, 0x1c0)), 0x20),
                6089161339424509328036663631446177356962059257969269757764756736867284119828
            )
            // qH1
            mstore(
                mload(add(vk, 0x1e0)),
                20958494418957819078656169106411703182085163218975412379374468535801221813327
            )
            mstore(
                add(mload(add(vk, 0x1e0)), 0x20),
                3951957506265407870126870922882564995532654850740988902891983636747191019810
            )
            // qH2
            mstore(
                mload(add(vk, 0x200)),
                16320285111865654234449376730998247241342127349928808974935031019342501254057
            )
            mstore(
                add(mload(add(vk, 0x200)), 0x20),
                14874555578721464417343739911569808447474666223156347995317763717813002146017
            )
            // qH3
            mstore(
                mload(add(vk, 0x220)),
                18176388456143442007472157282981764667241520616918635928020843426794677343596
            )
            mstore(
                add(mload(add(vk, 0x220)), 0x20),
                1081401046854708411553456295637462494849157808317376419654962186841123857440
            )
            // qH4
            mstore(
                mload(add(vk, 0x240)),
                17156572657054164232568955467408974279596065576073128303198739599136348030545
            )
            mstore(
                add(mload(add(vk, 0x240)), 0x20),
                16500270368608963934246289041458524725891371523572271995147251592180077164060
            )
            // qEcc
            mstore(
                mload(add(vk, 0x260)),
                1257880406728789752808045909185010357023491262109773842201170093442428632989
            )
            mstore(
                add(mload(add(vk, 0x260)), 0x20),
                822115134156021745628675830966348834317564191964874388453303761747021353584
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
                14708041522873209202464618950611504807168696855480720848360413590326729841973
            )
            mstore(
                add(mload(add(vk, 0x40)), 0x20),
                2753391240893238116569628860982882954353792578019920766428726340611015647581
            )
            // sigma1
            mstore(
                mload(add(vk, 0x60)),
                3736215203151709462427825581991044329817961401819325086573903036518525176090
            )
            mstore(
                add(mload(add(vk, 0x60)), 0x20),
                12284473618321395163309979733066433449809233564826193169921444928840687100523
            )
            // sigma2
            mstore(
                mload(add(vk, 0x80)),
                11948153932361754444295437431688112113763465916556532032853808907007255324832
            )
            mstore(
                add(mload(add(vk, 0x80)), 0x20),
                5247166478759706764702942889858430530186042193040312355719301585036655612459
            )
            // sigma3
            mstore(
                mload(add(vk, 0xa0)),
                17184781586365391989471544204947701083939573062775992140067289916802254834188
            )
            mstore(
                add(mload(add(vk, 0xa0)), 0x20),
                1695548810031655609675397387003567906043418871571997772255611361115032629003
            )
            // sigma4
            mstore(
                mload(add(vk, 0xc0)),
                4501183465908078766709944423483386166697765379860531518789327025791827694266
            )
            mstore(
                add(mload(add(vk, 0xc0)), 0x20),
                17179919563903728314665267245084588379374464645703406635631119875332721091062
            )

            // q1
            mstore(
                mload(add(vk, 0xe0)),
                8233664603830467551407560711982259529601063264885744179029753653795440811880
            )
            mstore(
                add(mload(add(vk, 0xe0)), 0x20),
                15890473389663313484400232619457945250113260815521617218577960950923821395961
            )
            // q2
            mstore(
                mload(add(vk, 0x100)),
                14842917854453150581899781597532237976322234382964084206933989618934323526445
            )
            mstore(
                add(mload(add(vk, 0x100)), 0x20),
                16447842172982150537473552975294340243672291348134029457070764238385172728852
            )
            // q3
            mstore(
                mload(add(vk, 0x120)),
                9473551627160998361000472320259848783011643008757616507618705701015024223999
            )
            mstore(
                add(mload(add(vk, 0x120)), 0x20),
                11314416338785822922260197499038268393262643508579752114469422388580655977102
            )
            // q4
            mstore(
                mload(add(vk, 0x140)),
                3736408701597418834318726881826839552728418266216645424811344776852549712816
            )
            mstore(
                add(mload(add(vk, 0x140)), 0x20),
                9236488906535632856862877101736177223606785065252708856745807157980987984387
            )

            // qM12
            mstore(
                mload(add(vk, 0x160)),
                14102260043757883202366109964215541081299927672047603711818995797147714865094
            )
            mstore(
                add(mload(add(vk, 0x160)), 0x20),
                17534575210236353125951475539478479017023300116581894838767353256804423795888
            )
            // qM34
            mstore(
                mload(add(vk, 0x180)),
                9147214868025953364750888491087621905427748656716737534941501783669122960379
            )
            mstore(
                add(mload(add(vk, 0x180)), 0x20),
                1392401634629635498019533543932086568632128115192597982401550578444977393547
            )

            // qO
            mstore(
                mload(add(vk, 0x1a0)),
                10905264501530050014704452452494914745596183555206362825031535539577170367475
            )
            mstore(
                add(mload(add(vk, 0x1a0)), 0x20),
                17138899495046135206471329677572657240135846790961757879454458120765242310575
            )
            // qC
            mstore(
                mload(add(vk, 0x1c0)),
                16573281449079492002777383418086249227397635509941971752517637461403659421155
            )
            mstore(
                add(mload(add(vk, 0x1c0)), 0x20),
                4575446980340017635017887407539797482781705198893380506254262640090465211655
            )
            // qH1
            mstore(
                mload(add(vk, 0x1e0)),
                9089742723053765306677953175198389661353135493790082378155841294705327694917
            )
            mstore(
                add(mload(add(vk, 0x1e0)), 0x20),
                11133242012031704156289281393180107718619015102295906028702493235407386901280
            )
            // qH2
            mstore(
                mload(add(vk, 0x200)),
                10009477156249913501931891243909788618345391893663991287711709770530743764439
            )
            mstore(
                add(mload(add(vk, 0x200)), 0x20),
                2335006503907830689782212423634682006869891487153768081847010024128012642090
            )
            // qH3
            mstore(
                mload(add(vk, 0x220)),
                204582489322604335877947037789506354815242950315871800117188914050721754147
            )
            mstore(
                add(mload(add(vk, 0x220)), 0x20),
                4017254452065892946191861754786121551706223202798323858822829895419210960406
            )
            // qH4
            mstore(
                mload(add(vk, 0x240)),
                3674255676567461700605617197873932900311232245160095442299763249794134579502
            )
            mstore(
                add(mload(add(vk, 0x240)), 0x20),
                14717173916044651338237546750276495403229974586112157441016319173772835390378
            )
            // qEcc
            mstore(
                mload(add(vk, 0x260)),
                12191628753324517001666106106337946847104780287136368645491927996790130156414
            )
            mstore(
                add(mload(add(vk, 0x260)), 0x20),
                13305212653333031744208722140065322148127616384688600512629199891590396358314
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
        uint256 mask;

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
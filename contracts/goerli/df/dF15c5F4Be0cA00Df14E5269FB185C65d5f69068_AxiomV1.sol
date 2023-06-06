// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {AxiomV1Core} from "./AxiomV1Core.sol";
import {AxiomV1Access} from "./AxiomV1Access.sol";
import {IAxiomV1} from "./interfaces/IAxiomV1.sol";

/// @title  Axiom V1
/// @author Axiom
/// @notice Core Axiom smart contract that verifies the validity of historical block hashes using SNARKs.
contract AxiomV1 is AxiomV1Core, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    /// @notice Prevents the implementation contract from being initialized outside of the upgradeable proxy.
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract and the parent contracts once.
    function initialize(
        address _verifierAddress,
        address _historicalVerifierAddress,
        address timelock,
        address guardian
    ) public initializer {
        require(timelock != address(0)); // AxiomV1: timelock cannot be the zero address
        __UUPSUpgradeable_init();
        // prover is initialized to the contract deployer
        __AxiomV1Core_init(_verifierAddress, _historicalVerifierAddress, guardian, msg.sender);

        _grantRole(DEFAULT_ADMIN_ROLE, timelock);
        _grantRole(TIMELOCK_ROLE, timelock);
    }

    function _authorizeUpgrade(address) internal override onlyRole(TIMELOCK_ROLE) {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable)
        returns (bool)
    {
        return interfaceId == type(IAxiomV1).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @title  Axiom V1 Access
/// @notice Abstract contract controlling permissions of AxiomV1
/// @dev    For use in a UUPS upgradeable contract.
abstract contract AxiomV1Access is Initializable, AccessControlUpgradeable {
    bool public frozen;

    /// @notice Storage slot for the address with the permission of a 'timelock'.
    bytes32 public constant TIMELOCK_ROLE = keccak256("TIMELOCK_ROLE");

    /// @notice Storage slot for the addresses with the permission of a 'guardian'.
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");

    /// @notice Storage slot for the addresses with the permission of a 'prover'.
    bytes32 public constant PROVER_ROLE = keccak256("PROVER_ROLE");

    /// @notice Emitted when the `freezeAll` is called
    event FreezeAll();

    /// @notice Emitted when the `unfreezeAll` is called
    event UnfreezeAll();

    /// @notice Error when trying to call contract while it is frozen
    error ContractIsFrozen();

    /// @notice Error when trying to call contract from address without 'prover' role
    error NotProverRole();

    /**
     * @dev Modifier to make a function callable only by the 'prover' role.
     * As an initial safety mechanism, the 'update_' functions are only callable by the 'prover' role.
     * Granting the prover role to `address(0)` will enable this role for everyone.
     */
    modifier onlyProver() {
        if (!hasRole(PROVER_ROLE, address(0)) && !hasRole(PROVER_ROLE, _msgSender())) {
            revert NotProverRole();
        }
        _;
    }

    function __AxiomV1Access_init() internal onlyInitializing {
        __AxiomV1Access_init_unchained();
    }

    function __AxiomV1Access_init_unchained() internal onlyInitializing {
        frozen = false;
    }

    function freezeAll() external onlyRole(GUARDIAN_ROLE) {
        frozen = true;
        emit FreezeAll();
    }

    function unfreezeAll() external onlyRole(GUARDIAN_ROLE) {
        frozen = false;
        emit UnfreezeAll();
    }

    /// @notice Checks that the contract is not frozen.
    function requireNotFrozen() internal view {
        if (frozen) {
            revert ContractIsFrozen();
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[40] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {AxiomV1Access} from "./AxiomV1Access.sol";
import {IAxiomV1} from "./interfaces/IAxiomV1.sol";
import {MerkleTree} from "./libraries/MerkleTree.sol";
import {MerkleMountainRange} from "./libraries/MerkleMountainRange.sol";
import "./libraries/configuration/AxiomV1Configuration.sol";

/// @title  Axiom V1 Core
/// @notice Core Axiom smart contract that verifies the validity of historical block hashes using SNARKs.
/// @dev    For use in a UUPS upgradeable contract.
contract AxiomV1Core is IAxiomV1, AxiomV1Access {
    using {MerkleTree.merkleRoot} for bytes32[HISTORICAL_NUM_ROOTS];
    using MerkleMountainRange for MerkleMountainRange.MMR;

    address public verifierAddress;
    address public historicalVerifierAddress;

    mapping(uint32 => bytes32) public historicalRoots;
    MerkleMountainRange.MMR public historicalMMR;
    bytes32[MMR_RING_BUFFER_SIZE] public mmrRingBuffer;

    error SNARKVerificationFailed();
    error AxiomBlockVerificationFailed();
    error UpdatingIncorrectNumberOfBlocks();
    error StartingBlockNotMultipleOfBatchSize();
    error NotRecentEndBlock();
    error BlockHashIncorrect();
    error MerkleProofFailed();

    /// @notice Initializes the contract and the parent contracts.
    function __AxiomV1Core_init(
        address _verifierAddress,
        address _historicalVerifierAddress,
        address guardian,
        address prover
    ) internal onlyInitializing {
        __AxiomV1Access_init();
        __AxiomV1Core_init_unchained(_verifierAddress, _historicalVerifierAddress, guardian, prover);
    }

    /// @notice Initializes the contract without calling parent contract initializers.
    function __AxiomV1Core_init_unchained(
        address _verifierAddress,
        address _historicalVerifierAddress,
        address guardian,
        address prover
    ) internal onlyInitializing {
        require(_verifierAddress != address(0)); // AxiomV1Core: _verifierAddress cannot be the zero address
        require(_historicalVerifierAddress != address(0)); // AxiomV1Core: _historicalVerifierAddress cannot be the zero address"
        require(guardian != address(0)); // AxiomV1Core: guardian cannot be the zero address
        require(prover != address(0)); // AxiomV1Core: prover cannot be the zero address

        _grantRole(PROVER_ROLE, prover);
        _grantRole(GUARDIAN_ROLE, guardian);

        verifierAddress = _verifierAddress;
        historicalVerifierAddress = _historicalVerifierAddress;
        emit UpgradeSnarkVerifier(_verifierAddress);
        emit UpgradeHistoricalSnarkVerifier(_historicalVerifierAddress);
    }

    function updateRecent(bytes calldata proofData) external onlyProver {
        requireNotFrozen();
        (bytes32 prevHash, bytes32 endHash, uint32 startBlockNumber, uint32 endBlockNumber, bytes32 root) =
            getBoundaryBlockData(proofData);
        // See `getBoundaryBlockData` comments for initial `proofData` formatting

        uint32 numFinal = endBlockNumber - startBlockNumber + 1;
        if (numFinal > BLOCK_BATCH_SIZE) revert UpdatingIncorrectNumberOfBlocks();
        if (startBlockNumber % BLOCK_BATCH_SIZE != 0) revert StartingBlockNotMultipleOfBatchSize();
        if (endBlockNumber >= block.number) revert NotRecentEndBlock();
        if (block.number - endBlockNumber > 256) revert NotRecentEndBlock();
        if (blockhash(endBlockNumber) != endHash) revert BlockHashIncorrect();

        if (!_verifyRaw(proofData)) {
            revert SNARKVerificationFailed();
        }

        if (root == bytes32(0)) {
            // We have a Merkle mountain range of max depth 10 (so length 11 total) ordered in **decreasing** order of peak size, so:
            // `root` (above) is the peak for depth 10
            // `roots` below are the peaks for depths 9..0 where `roots[i]` is for depth `9 - i`
            // 384 + 32 * 7 + 32 * 2 * i .. 384 + 32 * 7 + 32 * 2 * (i + 1): `roots[i]` (32 bytes) as two uint128 cast to uint256, same as blockHash
            // Note that the decreasing ordering is *different* than the convention in library MerkleMountainRange

            // compute Merkle root of completed Merkle mountain range with 0s for unconfirmed blockhashes
            for (uint256 round = 0; round < BLOCK_BATCH_DEPTH; round++) {
                bytes32 peak = getAuxMmrPeak(proofData, BLOCK_BATCH_DEPTH - 1 - round);
                if (peak != 0) {
                    root = keccak256(abi.encodePacked(peak, root));
                } else {
                    root = keccak256(abi.encodePacked(root, MerkleTree.getEmptyHash(round)));
                }
            }
        } else {
            // this indicates numFinal = BLOCK_BATCH_SIZE and root is the Merkle root of blockhashes for blocks [startBlockNumber, startBlockNumber + BLOCK_BATCH_SIZE)
            if (historicalMMR.len == (startBlockNumber >> BLOCK_BATCH_DEPTH)) {
                // the historicalMMR holds a commitment to blocks [0, startBlockNumber), so we can now extend it by 1024 blocks
                // we copy to memory as a gas optimization because we need to compute the commitment to store in the ring buffer
                MerkleMountainRange.MMR memory mmr = historicalMMR.clone();
                uint32 peaksChanged = mmr.appendSingle(root);
                mmr.index = (mmr.index + 1) % MMR_RING_BUFFER_SIZE;
                mmrRingBuffer[mmr.index] = mmr.commit();
                historicalMMR.copyFrom(mmr, peaksChanged);

                emit MerkleMountainRangeEvent(mmr.len, mmr.index);
            }
        }
        historicalRoots[startBlockNumber] = keccak256(abi.encodePacked(prevHash, root, numFinal));
        emit UpdateEvent(startBlockNumber, prevHash, root, numFinal);
    }

    function updateOld(bytes32 nextRoot, uint32 nextNumFinal, bytes calldata proofData) external onlyProver {
        requireNotFrozen();
        (bytes32 prevHash, bytes32 endHash, uint32 startBlockNumber, uint32 endBlockNumber, bytes32 root) =
            getBoundaryBlockData(proofData);

        if (startBlockNumber % BLOCK_BATCH_SIZE != 0) revert StartingBlockNotMultipleOfBatchSize();
        if (endBlockNumber - startBlockNumber != BLOCK_BATCH_SIZE - 1) {
            revert UpdatingIncorrectNumberOfBlocks();
        }
        if (historicalRoots[endBlockNumber + 1] != keccak256(abi.encodePacked(endHash, nextRoot, nextNumFinal))) {
            revert BlockHashIncorrect();
        }

        if (!_verifyRaw(proofData)) {
            revert SNARKVerificationFailed();
        }

        historicalRoots[startBlockNumber] = keccak256(abi.encodePacked(prevHash, root, BLOCK_BATCH_SIZE));
        emit UpdateEvent(startBlockNumber, prevHash, root, BLOCK_BATCH_SIZE);
    }

    /// @dev endHashProofs is length HISTORICAL_NUM_ROOTS - 1 because the last endHash is provided in proofData
    function updateHistorical(
        bytes32 nextRoot,
        uint32 nextNumFinal,
        bytes32[HISTORICAL_NUM_ROOTS] calldata roots,
        bytes32[BLOCK_BATCH_DEPTH + 1][HISTORICAL_NUM_ROOTS - 1] calldata endHashProofs,
        bytes calldata proofData
    ) external onlyProver {
        requireNotFrozen();
        (bytes32 _prevHash, bytes32 _endHash, uint32 startBlockNumber, uint32 endBlockNumber, bytes32 aggregateRoot) =
            getBoundaryBlockData(proofData);

        if (startBlockNumber % BLOCK_BATCH_SIZE != 0) revert StartingBlockNotMultipleOfBatchSize();
        if (endBlockNumber - startBlockNumber != HISTORICAL_BLOCK_BATCH_SIZE - 1) {
            revert UpdatingIncorrectNumberOfBlocks();
        }
        if (historicalRoots[endBlockNumber + 1] != keccak256(abi.encodePacked(_endHash, nextRoot, nextNumFinal))) {
            revert BlockHashIncorrect();
        }
        if (roots.merkleRoot() != aggregateRoot) {
            revert MerkleProofFailed();
        }

        if (!_verifyHistoricalRaw(proofData)) {
            revert SNARKVerificationFailed();
        }

        for (uint256 i = 0; i < HISTORICAL_NUM_ROOTS; i++) {
            if (i != HISTORICAL_NUM_ROOTS - 1) {
                bytes32 proofCheck = endHashProofs[i][BLOCK_BATCH_DEPTH];
                for (uint256 j = 0; j < BLOCK_BATCH_DEPTH; j++) {
                    proofCheck = keccak256(abi.encodePacked(endHashProofs[i][BLOCK_BATCH_DEPTH - 1 - j], proofCheck));
                }
                if (proofCheck != roots[i]) revert MerkleProofFailed();
            }
            bytes32 prevHash = i == 0 ? _prevHash : endHashProofs[i - 1][BLOCK_BATCH_DEPTH];
            uint32 start = uint32(startBlockNumber + i * BLOCK_BATCH_SIZE);
            historicalRoots[start] = keccak256(abi.encodePacked(prevHash, roots[i], BLOCK_BATCH_SIZE));
            emit UpdateEvent(start, prevHash, roots[i], BLOCK_BATCH_SIZE);
        }
    }

    function appendHistoricalMMR(uint32 startBlockNumber, bytes32[] calldata roots, bytes32[] calldata prevHashes)
        external
    {
        requireNotFrozen();
        if (roots.length == 0) revert(); // must append non-empty list
        if (roots.length != prevHashes.length) revert(); // roots and prevHashes must be same length
        if (startBlockNumber != historicalMMR.len * BLOCK_BATCH_SIZE) revert(); // startBlockNumber must be historicalMMR.len * BLOCK_BATCH_SIZE

        MerkleMountainRange.MMR memory mmr = historicalMMR.clone();
        for (uint256 i = 0; i < roots.length; i++) {
            // roots[i] = (prevHash, root)
            bytes32 commitment = keccak256(abi.encodePacked(prevHashes[i], roots[i], BLOCK_BATCH_SIZE));
            if (historicalRoots[startBlockNumber] != commitment) revert AxiomBlockVerificationFailed();
            startBlockNumber += BLOCK_BATCH_SIZE;
        }
        uint32 peaksChanged = mmr.append(roots);
        mmr.index = (mmr.index + 1) % MMR_RING_BUFFER_SIZE;
        mmrRingBuffer[mmr.index] = mmr.commit();
        historicalMMR.copyFrom(mmr, peaksChanged);

        emit MerkleMountainRangeEvent(mmr.len, mmr.index);
    }

    /// @notice Updates the address of the SNARK verifier contract, governed by a 'timelock'.
    ///         To avoid timelock bypass by metamorphic contracts, users should verify that
    ///         the contract deployed at `_verifierAddress` does not contain any `SELFDESTRUCT`
    ///         or `DELEGATECALL` opcodes.
    function upgradeSnarkVerifier(address _verifierAddress) external onlyRole(TIMELOCK_ROLE) {
        verifierAddress = _verifierAddress;
        emit UpgradeSnarkVerifier(_verifierAddress);
    }

    /// @notice Updates the address of the historical SNARK verifier contract, governed by a 'timelock'.
    ///         To avoid timelock bypass by metamorphic contracts, users should verify that
    ///         the contract deployed at `_historicalVerifierAddress` does not contain any `SELFDESTRUCT`
    ///         or `DELEGATECALL` opcodes.    
    /// @dev    We expect this should never need to be called since the historical verifier is only used for the initial batch import of historical block hashes.
    function upgradeHistoricalSnarkVerifier(address _historicalVerifierAddress) external onlyRole(TIMELOCK_ROLE) {
        historicalVerifierAddress = _historicalVerifierAddress;
        emit UpgradeHistoricalSnarkVerifier(_historicalVerifierAddress);
    }

    function historicalMMRPeaks(uint32 i) external view returns (bytes32) {
        return historicalMMR.peaks[i];
    }

    function isRecentBlockHashValid(uint32 blockNumber, bytes32 claimedBlockHash) public view returns (bool) {
        bytes32 blockHash = blockhash(blockNumber);
        if (blockHash == 0x0) revert(); // Must supply block hash of one of 256 most recent blocks
        return (blockHash == claimedBlockHash);
    }

    function isBlockHashValid(BlockHashWitness calldata witness) public view returns (bool) {
        if (witness.claimedBlockHash == 0x0) revert(); // Claimed block hash cannot be 0
        uint32 side = witness.blockNumber % BLOCK_BATCH_SIZE;
        uint32 startBlockNumber = witness.blockNumber - side;
        bytes32 merkleRoot = historicalRoots[startBlockNumber];
        if (merkleRoot == 0) revert(); // Merkle root must be stored already
        // compute Merkle root of blockhash
        bytes32 root = witness.claimedBlockHash;
        for (uint256 i = 0; i < BLOCK_BATCH_DEPTH; i++) {
            // depth = BLOCK_BATCH_DEPTH - i
            // 0 for left, 1 for right
            if ((side >> i) & 1 == 0) {
                root = keccak256(abi.encodePacked(root, witness.merkleProof[i]));
            } else {
                root = keccak256(abi.encodePacked(witness.merkleProof[i], root));
            }
        }
        return (merkleRoot == keccak256(abi.encodePacked(witness.prevHash, root, witness.numFinal)));
    }

    function mmrVerifyBlockHash(
        bytes32[] calldata mmr,
        uint8 bufferId,
        uint32 blockNumber,
        bytes32 claimedBlockHash,
        bytes32[] calldata merkleProof
    ) public view {
        if (keccak256(abi.encodePacked(mmr)) != mmrRingBuffer[bufferId]) {
            revert AxiomBlockVerificationFailed();
        }
        // mmr.length <= 32
        uint32 peakId = uint32(mmr.length - 1);
        uint32 side = blockNumber;
        while ((BLOCK_BATCH_SIZE << peakId) <= side) {
            if (peakId == 0) revert(); // blockNumber outside of range of MMR
            peakId--;
            side -= BLOCK_BATCH_SIZE << peakId;
        }
        // merkleProof is a merkle proof of claimedBlockHash into the tree with root mmr[peakId]
        require(merkleProof.length == BLOCK_BATCH_DEPTH + peakId);
        bytes32 root = claimedBlockHash;
        for (uint256 i = 0; i < merkleProof.length; i++) {
            // 0 for left, 1 for right
            if ((side >> i) & 1 == 0) {
                root = keccak256(abi.encodePacked(root, merkleProof[i]));
            } else {
                root = keccak256(abi.encodePacked(merkleProof[i], root));
            }
        }
        if (root != mmr[peakId]) {
            revert AxiomBlockVerificationFailed();
        }
    }

    function _verifyRaw(bytes calldata input) private returns (bool) {
        (bool success,) = verifierAddress.call(input);
        return success;
    }

    function _verifyHistoricalRaw(bytes calldata input) private returns (bool) {
        (bool success,) = historicalVerifierAddress.call(input);
        return success;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[40] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./core/IAxiomV1Verifier.sol";
import "./core/IAxiomV1Update.sol";
import "./core/IAxiomV1State.sol";
import "./core/IAxiomV1Events.sol";

/// @title The interface for the core Axiom V1 contract
/// @notice The Axiom V1 contract stores a continually updated cache of all historical block hashes
/// @dev The interface is broken up into many smaller pieces
interface IAxiomV1 is IAxiomV1Events, IAxiomV1State, IAxiomV1Update, IAxiomV1Verifier {}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IAxiomV1Events {
    /// @notice Emitted when a new batch of consecutive blocks is trustlessly verified and cached in the contract storage `historicalRoots`
    /// @param  startBlockNumber The block number of the first block in the batch
    /// @param  prevHash The parent hash of block `startBlockNumber`
    /// @param  root The Merkle root of hash(i) for i in [0, 1024), where hash(i) is the blockhash of block `startBlockNumber + i` if i < numFinal,
    ///              Otherwise hash(i) = bytes32(0x0) if i >= numFinal
    /// @param  numFinal The number of consecutive blocks in this batch, i.e., [startBlockNumber, startBlockNumber + numFinal) blocks are verified
    event UpdateEvent(uint32 startBlockNumber, bytes32 prevHash, bytes32 root, uint32 numFinal);

    /// @notice Emitted when the size of the historicalMMR changes.
    /// @param  len The historicalMMR now stores commitment to blocks [0, 1024 * len)
    /// @param  index The new index in the ring buffer storing the commitment to historicalMMR
    event MerkleMountainRangeEvent(uint32 len, uint32 index);

    /// @notice Emitted when the SNARK #verifierAddress changes
    /// @param  newAddress The new address of the SNARK verifier contract
    event UpgradeSnarkVerifier(address newAddress);

    /// @notice Emitted when the SNARK #historicalVerifierAddress changes
    /// @param  newAddress The new address of the SNARK historical verifier contract
    event UpgradeHistoricalSnarkVerifier(address newAddress);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IAxiomV1State {
    /// @notice Returns the hash of a batch of consecutive blocks previously verified by the contract
    /// @dev    The reads here will match the emitted #UpdateEvent
    /// @return historicalRoots(startBlockNumber) is 0 unless (startBlockNumber % 1024 == 0)
    ///         historicalRoots(startBlockNumber) = 0 if block `startBlockNumber` is not verified
    ///         historicalRoots(startBlockNumber) = keccak256(prevHash || root || numFinal) where || is concatenation
    ///         - prevHash is the parent hash of block `startBlockNumber`
    ///         - root is the keccak Merkle root of hash(i) for i in [0, 1024), where
    ///             hash(i) is the blockhash of block `startBlockNumber + i` if i < numFinal,
    ///             hash(i) = bytes32(0x0) if i >= numFinal
    ///         - 0 < numFinal <= 1024 is the number of verified consecutive roots in [startBlockNumber, startBlockNumber + numFinal)
    function historicalRoots(uint32 startBlockNumber) external view returns (bytes32);

    /// @notice Returns metadata about the number of consecutive blocks from genesis stored in the contract
    ///         The Merkle mountain range stores a commitment to the variable length list where `list[i]` is the Merkle root of the binary tree with leaves the blockhashes of blocks [1024 * i, 1024 * (i + 1))
    /// @return numPeaks = bit_length(len) is the number of peaks in the Merkle mountain range
    /// @return len indicates that the historicalMMR commits to blockhashes of blocks [0, 1024 * len)
    /// @return index the current index in the ring buffer storing commitments to historicalMMRs
    function historicalMMR() external view returns (uint32 numPeaks, uint32 len, uint32 index);

    /// @notice Returns the i-th Merkle root in the historical Merkle Mountain Range
    /// @param  i The index, `peaks[i] = root(list[((len >> i) << i) - 2^i : ((len >> i) << i)])` if 2^i & len != 0, otherwise 0
    ///         where root(single element) = single element,
    ///         list is the variable length list where `list[i]` is the Merkle root of the binary tree with leaves the blockhashes of blocks [1024 * i, 1024 * (i + 1))
    function historicalMMRPeaks(uint32 i) external view returns (bytes32);

    /// @notice A ring buffer storing commitments to past historicalMMR states
    /// @param  index The index in the ring buffer
    function mmrRingBuffer(uint256 index) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IAxiomV1Update {
    /// @notice Verify and store a batch of consecutive blocks, where the latest block in the batch is within the last 256 most recent blocks.
    /// @param  proofData The raw bytes of a zero knowledge proof to be verified by the contract.
    ///         proofData contains public inputs/outputs of
    ///         (bytes32 prevHash, bytes32 endHash, uint32 startBlockNumber, uint32 endBlockNumber, bytes32[11] mmr)
    ///         where the proof verifies the blockhashes of blocks [startBlockNumber, endBlockNumber], endBlockNumber - startBlockNumber <= 1023
    ///         - startBlockNumber must be a multiple of 1024
    ///         - prevHash is the parent hash of block `startBlockNumber`,
    ///         - endHash is the blockhash of block `endBlockNumber`,
    ///         - mmr is the keccak Merkle mountain range of the blockhashes of blocks [startBlockNumber, endBlockNumber], ordered from depth 10 to depth 0
    function updateRecent(bytes calldata proofData) external;

    /// @notice Verify and store a batch of 1024 consecutive blocks,
    ///         where the latest block in the batch is verified against the blockhash cache in #historicalRoots
    /// @dev    The contract checks that #historicalRoots(endBlockNumber + 1) == keccak256(endHash || nextRoot || nextNumFinal)
    ///         where endBlockNumber, endHash are derived from proofData.
    ///         nextRoot and nextNumFinal should be obtained by reading event logs. For old blocks nextNumFinal is _usually_ 1024.
    /// @param  proofData The raw bytes of a zero knowledge proof to be verified by the contract. Has same format as in #updateRecent except
    ///         endBlockNumber = startBlockNumber + 1023, so the block batch size is exactly 1024
    ///         mmr contains the keccak Merkle root of the full Merkle tree of depth 10, followed by zeros
    /// @param  nextRoot The Merkle root stored in #historicalRoots(endBlockNumber + 1)
    /// @param  nextNumFinal The numFinal stored in #historicalRoots(endBlockNumber + 1)
    function updateOld(bytes32 nextRoot, uint32 nextNumFinal, bytes calldata proofData) external;

    /// @notice Verify and store a batch of 2^17 = 128 * 1024 consecutive blocks,
    ///         where the latest block in the batch is verified against the blockhash cache in #historicalRoots
    /// @dev    Has the same effect as calling #updateOld 128 times on consecutive batches of 1024 blocks each.
    ///         But uses a different SNARK to verify the proof of all 2^17 blocks at once.
    ///         endHashProofs is used to get the intermediate parent hashes of these 1024 block batches
    /// @param  proofData The raw bytes of a zero knowledge proof to be verified by the contract. Has similar format as in #updateRecent except
    ///         we require endBlockNumber = startBlockNumber + 2^17 - 1, so the block batch size is exactly 2^17.
    ///         proofData contains public inputs/outputs of:
    ///         (bytes32 prevHash, bytes32 endHash, uint32 startBlockNumber, uint32 endBlockNumber, bytes32[18] mmr)
    ///         - startBlockNumber must be a multiple of 1024
    ///         - we require that endBlockNumber - startBlockNumber = 2^17 - 1
    ///         - prevHash is the parent hash of block `startBlockNumber`,
    ///         - endHash is the blockhash of block `endBlockNumber`,
    ///         - mmr[0] is the keccak Merkle root of the blockhashes of blocks [startBlockNumber, startBlockNumber + 2^17), the other entries in mmr are zeros
    /// @param  nextRoot The Merkle root stored in #historicalRoots(endBlockNumber + 1)
    /// @param  nextNumFinal The numFinal stored in #historicalRoots(endBlockNumber + 1)
    /// @param  roots roots[i] is the Merkle root of the blockhashes of blocks [startBlockNumber + i * 1024, startBlockNumber + (i + 1) * 1024) for i = 0, ..., 127
    /// @param  endHashProofs endHashProofs[i] is the Merkle inclusion proof of the blockhash of block `startBlockNumber + (i + 1) * 1024 - 1` in roots[i], for i = 0, ..., 126
    ///         endHashProofs[i][10] is the blockhash of block `startBlockNumber + (i + 1) * 1024 - 1`
    ///         endHashProofs[i][j] is the sibling of the Merkle node at depth j, for j = 0, ..., 9
    function updateHistorical(
        bytes32 nextRoot,
        uint32 nextNumFinal,
        bytes32[128] calldata roots,
        bytes32[11][127] calldata endHashProofs,
        bytes calldata proofData
    ) external;

    /// @notice Extended the stored historical Merkle Mountain Range with a multiple of 1024 blockhash commitments
    /// @dev    The blocks to append must have already been cached by Axiom.
    ///         startBlockNumber must equal historicalMMR.len * 1024, but we make it an input for faster reverts
    /// @param  startBlockNumber The block number of the first block to append
    /// @param  roots roots[i] is the Merkle root of the blockhashes of blocks [startBlockNumber + i * 1024, startBlockNumber + (i + 1) * 1024) for i = 0, ..., roots.length - 1
    /// @param  prevHashes prevHashes[i] is the parent hash of block `startBlockNumber + i * 1024`, for i = 0, ..., roots.length - 1. prevHashes and roots must have the same length.
    function appendHistoricalMMR(uint32 startBlockNumber, bytes32[] calldata roots, bytes32[] calldata prevHashes)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {BLOCK_BATCH_DEPTH} from "../../libraries/configuration/AxiomV1Configuration.sol";

interface IAxiomV1Verifier {
    /// @notice A merkle proof to verify a block against the verified blocks cached by Axiom
    /// @dev    `BLOCK_BATCH_DEPTH = 10`
    struct BlockHashWitness {
        uint32 blockNumber;
        bytes32 claimedBlockHash;
        bytes32 prevHash;
        uint32 numFinal;
        bytes32[BLOCK_BATCH_DEPTH] merkleProof;
    }

    /// @notice Verify the blockhash of block blockNumber equals claimedBlockHash. Assumes that blockNumber is within the last 256 most recent blocks.
    /// @param  blockNumber The block number to verify
    /// @param  claimedBlockHash The claimed blockhash of block blockNumber
    function isRecentBlockHashValid(uint32 blockNumber, bytes32 claimedBlockHash) external view returns (bool);

    /// @notice Verify the blockhash of block witness.blockNumber equals witness.claimedBlockHash by checking against Axiom's cache of #historicalRoots.
    /// @dev    For block numbers within the last 256, use #isRecentBlockHashValid instead.
    /// @param  witness The block hash to verify and the Merkle proof to verify it
    ///         witness.blockNumber is the block number to verify
    ///         witness.claimedBlockHash is the claimed blockhash of block witness.blockNumber
    ///         witness.prevHash is the prevHash stored in #historicalRoots(witness.blockNumber - witness.blockNumber % 1024)
    ///         witness.numFinal is the numFinal stored in #historicalRoots(witness.blockNumber - witness.blockNumber % 1024)
    ///         witness.merkleProof is the Merkle inclusion proof of witness.claimedBlockHash to the root stored in #historicalRoots(witness.blockNumber - witness.blockNumber % 1024)
    ///         witness.merkleProof[i] is the sibling of the Merkle node at depth 10 - i, for i = 0, ..., 10
    function isBlockHashValid(BlockHashWitness calldata witness) external view returns (bool);

    /// @notice Verify the blockhash of block blockNumber equals claimedBlockHash by checking against Axiom's cache of historical Merkle mountain ranges in #mmrRingBuffer.
    /// @dev    Use event logs to determine the correct bufferId and get the MMR at that index in the ring buffer.
    /// @param  mmr The Merkle mountain range commited to in #mmrRingBuffer(bufferId), must be correct length
    /// @param  bufferId The index in the ring buffer of #mmrRingBuffer
    /// @param  blockNumber The block number to verify
    /// @param  claimedBlockHash The claimed blockhash of block blockNumber
    /// @param  merkleProof The Merkle inclusion proof of claimedBlockHash to the corresponding peak in mmr. The correct peak is calculated from mmr.length and blockNumber.
    function mmrVerifyBlockHash(
        bytes32[] calldata mmr,
        uint8 bufferId,
        uint32 blockNumber,
        bytes32 claimedBlockHash,
        bytes32[] calldata merkleProof
    ) external view;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title  Merkle Mountain Range
/// @author Axiom
/// @notice Library for Merkle Mountain Range data structure
library MerkleMountainRange {
    /// @notice A Merkle mountain range is a data structure for efficiently storing a commitment to a variable length list of bytes32 values.
    /// @param  peaks The peaks of the MMR as a fixed-length array of length 32.
    ///         `peaks` is ordered in *increasing* size of peaks: `peaks[i]` is the Merkle root of a tree of size `2 ** i` corresponding to the `i`th bit of `len` (see @dev for details)
    /// @param  numPeaks The actual number of peaks in the MMR
    /// @param  len The length of the original list that this MMR is a commitment to; the implementation guarantees that `numPeaks = bit_length(len)`
    /// @param  index For external use: keeps track of the current index of this MMR in the ring buffer (see `AxiomV1Core`)
    /// @dev    peaks stores `numPeaks := bit_length(len)` Merkle roots, with
    ///         `peaks[i] = root(list[((len >> i) << i) - 2^i : ((len >> i) << i)])` if 2^i & len != 0, otherwise 0
    ///         where root(single element) = single element, and `list` is the underlying list for the MMR
    ///         Warning: Only use the check `peaks[i] == 0` to determine if `peaks[i]` is undefined if the original list is guaranteed to not contain 0
    ///         (e.g., if the original list is already of hashes)
    ///         Default initialization is to `len = 0`, `numPeaks = 0`, and all `peaks[i] = 0`
    struct MMR {
        // the peaks
        bytes32[32] peaks;
        // bit_length(len) or 0 if len = 0
        uint32 numPeaks;
        // the length of the original list that this MMR is a commitment to, so `peaks` has `bit_length(len)` elements
        uint32 len;
        // the current index in the ring buffer; this is free storage since `numPeaks, len, index` get packed into a single word in EVM storage
        uint32 index;
    }

    /// @notice Copies the MMR to memory
    /// @dev    Only reads the peaks up to `numPeaks`
    /// @param  self The MMR
    /// @return out The MMR in memory
    function clone(MMR storage self) internal view returns (MMR memory out) {
        out.numPeaks = self.numPeaks;
        out.len = self.len;
        out.index = self.index;
        for (uint32 i = 0; i < out.numPeaks; i++) {
            out.peaks[i] = self.peaks[i];
        }
    }

    /// @notice Copies MMR from memory to storage
    /// @dev    Only changes peaks up to `peaksChanged` to limit SSTOREs
    /// @param  self The MMR in storage
    /// @param  peaksChanged Only copy newMMR.peaks[0 : peaksChanged]
    function copyFrom(MMR storage self, MMR memory newMMR, uint32 peaksChanged) internal {
        self.numPeaks = newMMR.numPeaks;
        self.len = newMMR.len;
        self.index = newMMR.index;
        for (uint32 i = 0; i < peaksChanged; i++) {
            self.peaks[i] = newMMR.peaks[i];
        }
    }

    /// @notice Compute the keccak of the concatenated peaks
    /// @param  self The MMR
    /// @return keccak of the concatenated peaks
    function commit(MMR memory self) internal pure returns (bytes32) {
        bytes32[] memory peaks = new bytes32[](self.numPeaks);
        for (uint32 i = 0; i < self.numPeaks; i++) {
            peaks[i] = self.peaks[i];
        }
        return keccak256(abi.encodePacked(peaks));
    }

    /// @notice Append a new element to the underlying list of the MMR
    /// @param  self The MMR
    /// @param  leaf The new element to append
    /// @return peaksChanged self.peaks[0 : peaksChanged] have been changed
    function appendSingle(MMR memory self, bytes32 leaf) internal pure returns (uint32 peaksChanged) {
        uint32 i = 0;
        bytes32 new_peak = leaf;
        uint32 len = self.len;
        while ((len >> i) & 1 == 1) {
            new_peak = keccak256(abi.encodePacked(self.peaks[i], new_peak));
            self.peaks[i] = 0;
            i += 1;
        }
        self.peaks[i] = new_peak;
        self.len += 1;
        if (i >= self.numPeaks) {
            self.numPeaks = i + 1;
        }
        peaksChanged = i + 1;
    }

    /// @notice Append a sequence of new elements to the underlying list of the MMR, in order
    /// @dev    Optimized compared to looping over `appendSingle`
    /// @param  self The MMR
    /// @param  leaves The new elements to append
    /// @return peaksChanged self.peaks[0 : peaksChanged] have been changed
    function append(MMR memory self, bytes32[] memory leaves) internal pure returns (uint32 peaksChanged) {
        uint32 prevLen = self.len;
        // keeps track of running length of `leaves`
        uint32 toAdd = uint32(leaves.length);
        self.len += toAdd;
        uint32 i = 0;
        uint32 shift;
        while (toAdd != 0) {
            // shift records whether there is an existing peak in the range we should hash with
            shift = (prevLen >> i) & 1;
            // if shift, add peaks[i] to beginning of leaves
            // then hash all leaves
            uint32 next_add = (toAdd + shift) >> 1;
            for (uint32 j = 0; j < next_add; j++) {
                bytes32 left;
                bytes32 right;
                if (shift == 1) {
                    left = (j == 0 ? self.peaks[i] : leaves[2 * j - 1]);
                    right = leaves[2 * j];
                } else {
                    left = leaves[2 * j];
                    right = leaves[2 * j + 1];
                }
                leaves[j] = keccak256(abi.encodePacked(left, right));
            }
            // if to_add + shift is odd, the last element is new self.peaks[i], otherwise 0
            if (toAdd & 1 != shift) {
                self.peaks[i] = leaves[toAdd - 1];
            } else if (shift == 1) {
                // if shift == 0 then self.peaks[i] is already 0
                self.peaks[i] = 0;
            }
            toAdd = next_add;
            i += 1;
        }
        if (i > self.numPeaks) {
            self.numPeaks = i;
        }
        peaksChanged = i;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {HISTORICAL_NUM_ROOTS} from "./configuration/AxiomV1Configuration.sol";

/// @title Merkle Tree
/// @notice Helper functions for computing Merkle roots of Merkle trees
library MerkleTree {
    /// @notice Compute the Merkle root of a Merkle tree with HISTORICAL_NUM_ROOTS leaves
    /// @param  leaves The HISTORICAL_NUM_ROOTS leaves of the Merkle tree
    function merkleRoot(bytes32[HISTORICAL_NUM_ROOTS] memory leaves) internal pure returns (bytes32) {
        // we create a new array to avoid mutating `leaves`, which is passed by reference
        // unnecessary if calldata `leaves` is passed in since it is automatically copied to memory
        bytes32[] memory hashes = new bytes32[](HISTORICAL_NUM_ROOTS / 2);
        for (uint256 i = 0; i < HISTORICAL_NUM_ROOTS / 2; i++) {
            hashes[i] = keccak256(abi.encodePacked(leaves[i << 1], leaves[(i << 1) | 1]));
        }
        uint256 len = HISTORICAL_NUM_ROOTS / 4;
        while (len != 0) {
            for (uint256 i = 0; i < len; i++) {
                hashes[i] = keccak256(abi.encodePacked(hashes[i << 1], hashes[(i << 1) | 1]));
            }
            len >>= 1;
        }
        return hashes[0];
    }

    /// @notice Compute the Merkle root of a Merkle tree with 2^depth leaves all equal to bytes32(0x0)
    /// @param depth The depth of the Merkle tree, 0 <= depth < BLOCK_BATCH_DEPTH.
    function getEmptyHash(uint256 depth) internal pure returns (bytes32) {
        // emptyHashes[idx] is the Merkle root of a tree of depth idx with 0's as leaves
        if (depth == 0) {
            return bytes32(0x0000000000000000000000000000000000000000000000000000000000000000);
        } else if (depth == 1) {
            return bytes32(0xad3228b676f7d3cd4284a5443f17f1962b36e491b30a40b2405849e597ba5fb5);
        } else if (depth == 2) {
            return bytes32(0xb4c11951957c6f8f642c4af61cd6b24640fec6dc7fc607ee8206a99e92410d30);
        } else if (depth == 3) {
            return bytes32(0x21ddb9a356815c3fac1026b6dec5df3124afbadb485c9ba5a3e3398a04b7ba85);
        } else if (depth == 4) {
            return bytes32(0xe58769b32a1beaf1ea27375a44095a0d1fb664ce2dd358e7fcbfb78c26a19344);
        } else if (depth == 5) {
            return bytes32(0x0eb01ebfc9ed27500cd4dfc979272d1f0913cc9f66540d7e8005811109e1cf2d);
        } else if (depth == 6) {
            return bytes32(0x887c22bd8750d34016ac3c66b5ff102dacdd73f6b014e710b51e8022af9a1968);
        } else if (depth == 7) {
            return bytes32(0xffd70157e48063fc33c97a050f7f640233bf646cc98d9524c6b92bcf3ab56f83);
        } else if (depth == 8) {
            return bytes32(0x9867cc5f7f196b93bae1e27e6320742445d290f2263827498b54fec539f756af);
        } else if (depth == 9) {
            return bytes32(0xcefad4e508c098b9a7e1d8feb19955fb02ba9675585078710969d3440f5054e0);
        } else {
            revert("depth must be in range [0, 10)");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// Constants and free functions to be inlined into by AxiomV1Core

// ZK circuit constants:

// AxiomV1 caches blockhashes in batches, stored as Merkle roots of binary Merkle trees
uint32 constant BLOCK_BATCH_SIZE = 1024;
uint32 constant BLOCK_BATCH_DEPTH = 10;

// constants for batch import of historical block hashes
// historical uploads a bigger batch of block hashes, stored as Merkle roots of binary Merkle trees
uint32 constant HISTORICAL_BLOCK_BATCH_SIZE = 131072; // 2 ** 17
uint32 constant HISTORICAL_BLOCK_BATCH_DEPTH = 17;
// we will consider the historical Merkle tree of blocks as a Merkle tree of the block batch roots
uint32 constant HISTORICAL_NUM_ROOTS = 128; // HISTORICAL_BATCH_SIZE / BLOCK_BATCH_SIZE

// The first 4 * 3 * 32 bytes of proof calldata are reserved for two BN254 G1 points for a pairing check
// It will then be followed by (7 + BLOCK_BATCH_DEPTH * 2) * 32 bytes of public inputs/outputs
uint32 constant AUX_PEAKS_START_IDX = 608; // PUBLIC_BYTES_START_IDX + 7 * 32

// Historical MMR Ring Buffer constants
uint32 constant MMR_RING_BUFFER_SIZE = 8;

/// @dev proofData stores bytes32 and uint256 values in hi-lo format as two uint128 values because the BN254 scalar field is 254 bits
/// @dev The first 12 * 32 bytes of proofData are reserved for ZK proof verification data
// Extract public instances from proof
// The public instances are laid out in the proof calldata as follows:
// First 4 * 3 * 32 = 384 bytes are reserved for proof verification data used with the pairing precompile
// 384..384 + 32 * 2: prevHash (32 bytes) as two uint128 cast to uint256, because zk proof uses 254 bit field and cannot fit uint256 into a single element
// 384 + 32 * 2..384 + 32 * 4: endHash (32 bytes) as two uint128 cast to uint256
// 384 + 32 * 4..384 + 32 * 5: startBlockNumber (uint32: 4 bytes) and endBlockNumber (uint32: 4 bytes) are concatenated as `startBlockNumber . endBlockNumber` (8 bytes) and then cast to uint256
// 384 + 32 * 5..384 + 32 * 7: root (32 bytes) as two uint128 cast to uint256, this is the highest peak of the MMR if endBlockNumber - startBlockNumber == 1023, otherwise 0
function getBoundaryBlockData(bytes calldata proofData)
    pure
    returns (bytes32 prevHash, bytes32 endHash, uint32 startBlockNumber, uint32 endBlockNumber, bytes32 root)
{
    prevHash = bytes32(uint256(bytes32(proofData[384:416])) << 128 | uint256(bytes32(proofData[416:448])));
    endHash = bytes32(uint256(bytes32(proofData[448:480])) << 128 | uint256(bytes32(proofData[480:512])));
    startBlockNumber = uint32(bytes4(proofData[536:540]));
    endBlockNumber = uint32(bytes4(proofData[540:544]));
    root = bytes32(uint256(bytes32(proofData[544:576])) << 128 | uint256(bytes32(proofData[576:608])));
}

// We have a Merkle mountain range of max depth BLOCK_BATCH_DEPTH (so length BLOCK_BATCH_DEPTH + 1 total) ordered in **decreasing** order of peak size, so:
// `root` from `getBoundaryBlockData` is the peak for depth BLOCK_BATCH_DEPTH
// `getAuxMmrPeak(proofData, i)` is the peaks for depth BLOCK_BATCH_DEPTH - 1 - i
// 384 + 32 * 7 + 32 * 2 * i .. 384 + 32 * 7 + 32 * 2 * (i + 1): (32 bytes) as two uint128 cast to uint256, same as blockHash
// Note that the decreasing ordering is *different* than the convention in library MerkleMountainRange
function getAuxMmrPeak(bytes calldata proofData, uint256 i) pure returns (bytes32) {
    return bytes32(
        uint256(bytes32(proofData[AUX_PEAKS_START_IDX + i * 64:AUX_PEAKS_START_IDX + i * 64 + 32])) << 128
            | uint256(bytes32(proofData[AUX_PEAKS_START_IDX + i * 64 + 32:AUX_PEAKS_START_IDX + (i + 1) * 64]))
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.3) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.9._
 */
interface IERC1967Upgradeable {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.3) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/IERC1967Upgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable, IERC1967Upgradeable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

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
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}
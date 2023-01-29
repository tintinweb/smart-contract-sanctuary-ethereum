// SPDX-License-Identifier: MIT
// WARNING! This smart contract and the associated zk-SNARK verifiers have not been audited.
// DO NOT USE THIS CONTRACT FOR PRODUCTION
pragma solidity ^0.8.12;

import "./IAxiomV0.sol";

uint8 constant SLOT_NUMBER = 10;

contract AxiomV0StoragePf {
    address private axiomAddress;                  // address of deployed AxiomV0 contract
    address private verifierAddress;               // address of deployed ZKP verifier for storage proofs

    // slotAttestations[keccak256(blockNumber || addr || slot || slotValue)] = true
    // if and only if it has been checked that:
    //    at block number `blockNumber`, the account storage of `addr` has value `slotValue` at slot `slot`
    mapping(bytes32 => bool) public slotAttestations;

    event SlotAttestationEvent(uint32 blockNumber, address addr, uint256 slot, uint256 slotValue);

    constructor(address _axiomAddress, address _verifierAddress) {
        axiomAddress = _axiomAddress;
        verifierAddress = _verifierAddress;
    }

    function isSlotAttestationValid(uint32 blockNumber, address addr, uint256 slot, uint256 slotValue)
        external view returns (bool) {
        return slotAttestations[keccak256(abi.encodePacked(blockNumber, addr, slot, slotValue))];
    }

    // Verify a storage proof for 10 storage slots in a single account at a single block
    function attestSlots(IAxiomV0.BlockHashWitness calldata blockData, bytes calldata proof)
        external {
        if (block.number - blockData.blockNumber <= 256) {
            require(IAxiomV0(axiomAddress).isRecentBlockHashValid(blockData.blockNumber, blockData.claimedBlockHash), 
                    "Block hash was not validated in cache");
        } else {
            require(IAxiomV0(axiomAddress).isBlockHashValid(blockData), 
                    "Block hash was not validated in cache");
        }

        // Extract instances from proof
        uint256 _blockHash = (uint256(bytes32(proof[384:384 + 32])) << 128) | uint128(bytes16(proof[384 + 48:384 + 64]));
        uint256 _blockNumber = uint256(bytes32(proof[384 + 64:384 + 96]));
        address account = address(bytes20(proof[384 + 108:384 + 128]));

        // Check block hash and block number
        require(_blockHash == uint256(blockData.claimedBlockHash), "Invalid block hash in instance");
        require(_blockNumber == blockData.blockNumber, "Invalid block number in instance");

        (bool success,) = verifierAddress.call(proof);
        if (!success) {
            revert("Proof verification failed");
        }

        for (uint16 i = 0; i < SLOT_NUMBER; i++) {
            uint256 slot = (uint256(bytes32(proof[384 + 128 + 128 * i:384 + 160 + 128 * i])) << 128)
                | uint128(bytes16(proof[384 + 176 + 128 * i:384 + 192 + 128 * i]));
            uint256 slotValue = (uint256(bytes32(proof[384 + 192 + 128 * i:384 + 224 + 128 * i])) << 128)
                | uint128(bytes16(proof[384 + 240 + 128 * i:384 + 256 + 128 * i]));
            slotAttestations[keccak256(abi.encodePacked(blockData.blockNumber, account, slot, slotValue))] = true;
            emit SlotAttestationEvent(blockData.blockNumber, account, slot, slotValue);
        }
    }
}

// SPDX-License-Identifier: MIT
// WARNING! This smart contract and the associated zk-SNARK verifiers have not been audited.
// DO NOT USE THIS CONTRACT FOR PRODUCTION
pragma solidity ^0.8.12;

interface IAxiomV0 {
    // historicalRoots(startBlockNumber) is 0 unless (startBlockNumber % 1024 == 0)
    // historicalRoots(startBlockNumber) holds the hash of
    //   prevHash || root || numFinal
    // where
    // - prevHash is the parent hash of block startBlockNumber
    // - root is the partial Merkle root of blockhashes of block numbers
    //   [startBlockNumber, startBlockNumber + 1024)
    //   where unconfirmed block hashes are 0's
    // - numFinal is the number of confirmed consecutive roots in [startBlockNumber, startBlockNumber + 1024)
    function historicalRoots(uint32 startBlockNumber) external view returns (bytes32);

    event UpdateEvent(uint32 startBlockNumber, bytes32 prevHash, bytes32 root, uint32 numFinal);

    struct BlockHashWitness {
        uint32 blockNumber;
        bytes32 claimedBlockHash;
        bytes32 prevHash;
        uint32 numFinal;
        bytes32[10] merkleProof;
    }

    // returns Merkle root of a tree of depth `depth` with 0's as leaves
    function getEmptyHash(uint256 depth) external pure returns (bytes32);

    // update blocks in the "backward" direction, anchoring on a "recent" end blockhash that is within last 256 blocks
    // * startBlockNumber must be a multiple of 1024
    // * roots[idx] is the root of a Merkle tree of height 2**(10 - idx) in a Merkle mountain
    //   range which stores block hashes in the interval [startBlockNumber, endBlockNumber]
    function updateRecent(bytes calldata proofData) external;

    // update older blocks in "backwards" direction, anchoring on more recent trusted blockhash
    // must be batch of 1024 blocks
    function updateOld(bytes32 nextRoot, uint32 nextNumFinal, bytes calldata proofData) external;

    // Update older blocks in "backwards" direction, anchoring on more recent trusted blockhash
    // Must be batch of 128 * 1024 blocks
    // `roots` should contain 128 merkle roots, one per batch of 1024 blocks
    // For all except the last batch of 1024 blocks, a Merkle inclusion proof of the `endHash` of the batch
    // must be provided, with respect to the corresponding Merkle root in `roots`
    function updateHistorical(
        bytes32 nextRoot,
        uint32 nextNumFinal,
        bytes32[128] calldata roots,
        bytes32[11][127] calldata endHashProofs,
        bytes calldata proofData
    ) external;

    function isRecentBlockHashValid(uint32 blockNumber, bytes32 claimedBlockHash) external view returns (bool);
    function isBlockHashValid(BlockHashWitness calldata witness) external view returns (bool);
}
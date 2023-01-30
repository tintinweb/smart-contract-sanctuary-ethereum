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

// SPDX-License-Identifier: MIT
// WARNING! This smart contract and the associated zk-SNARK verifiers have not been audited.
// DO NOT USE THIS CONTRACT FOR PRODUCTION
pragma solidity ^0.8.12;

import "./IAxiomV0.sol";

contract UniswapV2Twap {
    address private axiomAddress;    
    address private verifierAddress;

    // mapping between packed [startBlockNumber (32) || endBlockNumber (32)] and twapPri
    mapping(uint64 => uint256) public twapPris;

    event UniswapV2TwapProof(uint32 startBlockNumber, uint32 endBlockNumber, uint256 twapPri);

    constructor(address _axiomAddress, address _verifierAddress) {
        axiomAddress = _axiomAddress;        
        verifierAddress = _verifierAddress;
    }

    function verifyUniswapV2Twap(
        IAxiomV0.BlockHashWitness calldata startBlock,
        IAxiomV0.BlockHashWitness calldata endBlock,
        bytes calldata proof
    ) external {
        if (block.number - startBlock.blockNumber <= 256) {
            require(IAxiomV0(axiomAddress).isRecentBlockHashValid(startBlock.blockNumber, startBlock.claimedBlockHash),
                    "Starting block hash was not validated in cache");
        } else {
            require(IAxiomV0(axiomAddress).isBlockHashValid(startBlock),
                    "Starting block hash was not validated in cache");
        }
        if (block.number - endBlock.blockNumber <= 256) {
            require(IAxiomV0(axiomAddress).isRecentBlockHashValid(endBlock.blockNumber, endBlock.claimedBlockHash),
                    "Ending block hash was not validated in cache");
        } else {
            require(IAxiomV0(axiomAddress).isBlockHashValid(endBlock),
                    "Ending block hash was not validated in cache");
        }

        // Extract instances from proof 
        uint256 _startBlockHash   = uint256(bytes32(proof[384    :384+32 ])) << 128 | 
                                            uint128(bytes16(proof[384+48 :384+64 ]));
        uint256 _endBlockHash     = uint256(bytes32(proof[384+64 :384+96 ])) << 128 | 
                                            uint128(bytes16(proof[384+112:384+128]));
        uint256 _startBlockNumber = uint256(bytes32(proof[384+128:384+160]));
        uint256 _endBlockNumber   = uint256(bytes32(proof[384+160:384+192]));
        uint256 _twapPri          = uint256(bytes32(proof[384+192:384+224]));

        // Check instance values
        if (_startBlockHash != uint256(startBlock.claimedBlockHash)) {
            revert("Invalid startBlockHash in instance");
        }
        if (_endBlockHash != uint256(endBlock.claimedBlockHash)) {
            revert("Invalid endBlockHash in instance");
        }
        if (_startBlockNumber != startBlock.blockNumber) {
            revert("Invalid startBlockNumber");
        }
        if (_endBlockNumber != endBlock.blockNumber) {
            revert("Invalid endBlockNumber");
        }        

        (bool success, ) = verifierAddress.call(proof);
        if (!success) {
            revert("Proof verification failed");
        }
        twapPris[uint64(uint64(startBlock.blockNumber) << 32 | endBlock.blockNumber)] = _twapPri;
        emit UniswapV2TwapProof(startBlock.blockNumber, endBlock.blockNumber, _twapPri);        
    }
}
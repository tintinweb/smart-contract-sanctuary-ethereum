// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "./Axiom.sol";

contract AxiomStoragePf {
    Axiom internal axiom;

    bytes32[] public slotAttestations;

    event SlotAttestationEvent(
        uint32 blockNumber,
        address addr,
        uint256 slot,
        uint256 slotValue
    );

    constructor(address axiomAddress) {
        axiom = Axiom(axiomAddress);
    }

    // Address of raw halo2 verifier
    function implementation() internal pure returns (address) {
        return 0x2fe833841098fcDED26a3F263cEf5ae730e8cd2d; // goerli
    }

    function verifyProof(bytes calldata pf) public returns (bool) {
        (bool success, bytes memory data) = implementation().call(pf);
        return success;
    }

    function attestSlot(
        bytes calldata pf,
        bytes32 blockHash,
        address addr,
        uint256 slot,
        uint32 blockNumber,
        uint256 slotValue
    ) external returns (uint256) {
        // pf[12 * 32: 13 * 32] is publicHash, pf[13 * 32:] is proof transcript
        require(verifyProof(pf) == true, "Invalid Proof");

        // convert from abi encoding of blockNumber to rlp encoding (zeros padded on right)
        bytes4 blockNumAbi = bytes4(blockNumber);
        uint8 first = 3;
        for (uint8 i = 0; i < 4; i++) {
            if (blockNumAbi[i] != 0x0) {
                first = i;
                break;
            }
        }
        uint32 blockNumRlp = blockNumber << (8 * first);

        // convert from abi encoding of slotValue to rlp encoding (zeros padded on right)
        bytes32 slotValueAbi = bytes32(slotValue);
        first = 31;
        for (uint8 i = 0; i < 32; i++) {
            if (slotValueAbi[i] != 0x0) {
                first = i;
                break;
            }
        }
        uint256 slotValueRlp = slotValue << (8 * first);

        // check preimage of publicHash
        bytes32 inputsHash = keccak256(
            abi.encodePacked(blockHash, addr, slot, blockNumRlp, slotValueRlp)
        );
        bytes32 publicHash = bytes32(pf[12 * 32:13 * 32]);

        require(
            uint256(inputsHash) - 256 * uint256(publicHash) < 256,
            "publicHash error"
        );
        require(
            blockHash != 0x0 && axiom.isValidBlockHash(blockHash),
            "block hash needs to be validated by Axiom"
        );
        slotAttestations.push(
            keccak256(abi.encodePacked(blockNumber, addr, slot, slotValue))
        );
        emit SlotAttestationEvent(blockNumber, addr, slot, slotValue);
        return slotAttestations.length - 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ProxyVerifier.sol";

uint256 constant treeDepth = 10;
uint256 constant numLeaves = 2**10;

contract Axiom is ProxyVerifier {
    mapping(uint256 => uint256) public historicalRoots; // historicalRoots[lastBlockHash] gives the merkle root of the blockhashes of numLeaves consecutive blocks, with lastBlockHash being the latest
    mapping(uint256 => bool) public isValidatedBlock; // isValidatedBlock[blockHash] = true iff the block with that hash is trustlessly validated and therefore can be used for bootstrapping

    event UpdateEvent(uint256 blockHash, uint256 merkleRoot);
    event ValidateEvent(uint256 blockHash);

    constructor() {
        uint256 blockHash = uint256(blockhash(block.number - 1));
        isValidatedBlock[blockHash] = true;
        emit ValidateEvent(blockHash);
    }

    function update(bytes calldata payload) external {
        uint256 lastHash = (uint256(
            bytes32(payload[(4 * 3 + 2) * 32:(4 * 3 + 3) * 32])
        ) << 128) +
            uint256(bytes32(payload[(4 * 3 + 3) * 32:(4 * 3 + 4) * 32]));
        require(
            isValidatedBlock[lastHash] == true,
            "Can only update if the last block is already validated"
        );
        require(
            super.verifyRaw(payload) == true,
            "Zero knowledge proof must verify"
        );

        uint256 root = (uint256(
            bytes32(payload[(4 * 3 + 4) * 32:(4 * 3 + 5) * 32])
        ) << 128) +
            uint256(bytes32(payload[(4 * 3 + 5) * 32:(4 * 3 + 6) * 32]));
        uint256 parentHash = (uint256(
            bytes32(payload[(4 * 3) * 32:(4 * 3 + 1) * 32])
        ) << 128) +
            uint256(bytes32(payload[(4 * 3 + 1) * 32:(4 * 3 + 2) * 32]));
        historicalRoots[lastHash] = root;
        isValidatedBlock[parentHash] = true;
        emit UpdateEvent(lastHash, root);
        emit ValidateEvent(parentHash);
    }

    function validateRecentBlock(uint256 blockNumber) external {
        bytes32 blockHash = blockhash(blockNumber);
        require(
            blockHash != 0x0,
            "must supply block hash of one of 256 most recent blocks"
        );
        isValidatedBlock[uint256(blockHash)] = true;
        emit ValidateEvent(uint256(blockHash));
    }

    function validateBlock(
        uint256 publicHash,
        bytes32 blockHash,
        bytes32[treeDepth] calldata merkleProof,
        uint16 side
    ) external {
        require(
            historicalRoots[publicHash] != 0,
            "merkle root must be stored already"
        );
        // compute Merkle root of blockhash
        bytes32 currHash = blockHash;
        for (uint8 depth = 0; depth < treeDepth; depth++) {
            // 0 for left, 1 for right
            if ((side >> depth) & 1 == 0) {
                currHash = keccak256(
                    abi.encodePacked(currHash, merkleProof[depth])
                );
            } else {
                currHash = keccak256(
                    abi.encodePacked(merkleProof[depth], currHash)
                );
            }
        }
        require(
            historicalRoots[publicHash] == uint256(currHash),
            "merkle proof must be valid"
        );
        isValidatedBlock[uint256(blockHash)] = true;
        emit ValidateEvent(uint256(blockHash));
    }

    function isValidBlockHash(bytes32 hash) public view returns (bool) {
        return isValidatedBlock[uint256(hash)];
    }

    function getMerkleRoot(bytes32 lastHash) public view returns (bytes32) {
        return bytes32(historicalRoots[uint256(lastHash)]);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract ProxyVerifier {
    function implementation() internal pure returns (address) {
        //return 0x5FbDB2315678afecb367f032d93F642f64180aa3; // local anvil
        return 0x6CA6585205062e11815202d997cc90432b877013; // live on Goerli
    }

    function verifyRaw(bytes calldata input) public returns (bool) {
        (bool success, bytes memory data) = implementation().call(input);
        return success;
    }
}
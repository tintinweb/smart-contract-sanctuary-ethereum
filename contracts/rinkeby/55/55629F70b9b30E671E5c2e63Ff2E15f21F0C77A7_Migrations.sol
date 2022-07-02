// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./MerkleProof.sol";

contract Migrations {
    function merkleProof(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) public pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    function getHash(bytes32 a, bytes32 b) public pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}
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

    function hashPair(bytes32 a, bytes32 b) public pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }
    
    function getHahs(address _wallet) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_wallet));
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}
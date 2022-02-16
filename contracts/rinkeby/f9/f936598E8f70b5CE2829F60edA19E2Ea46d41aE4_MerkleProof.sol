/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

pragma solidity ^0.5.2;

contract MerkleProof {
  function verify(bytes32 leaf, bytes32 root, bytes32[] memory proof )public pure returns (bool)
  {
      
    bytes32 computedHash = leaf;

    for (uint256 i = 0; i < proof.length; i++) {
      bytes32 proofElement = proof[i];

      if (computedHash <= proofElement) {
        // Hash(current computed hash + current element of the proof)
        
        computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
      } else {
        // Hash(current element of the proof + current computed hash)
        computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
      }
    }

    // Check if the computed hash (root) is equal to the provided root
    return computedHash == root;
  }

    function numberMinted(address root)public pure returns(bytes32) 
    {
        bytes32 newLeaf = keccak256(abi.encodePacked(root));
        return newLeaf;
    }
}
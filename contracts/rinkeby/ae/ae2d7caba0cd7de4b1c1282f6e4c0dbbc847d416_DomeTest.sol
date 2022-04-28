/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

contract DomeTest {

    constructor()  {
    
  }
   uint8 public House;

  function processProof(bytes32[] memory proof) internal pure returns (uint8) {
        uint256 computedHash;
        bytes32 proofElement;
        for (uint256 i = 0; i < proof.length; i++) {
            proofElement = proof[i];
        }
        computedHash = uint256(keccak256(abi.encodePacked(proofElement)));
        uint8 randomHouse = uint8((computedHash % 5) + 1);
        return randomHouse;
        //return computedHash;
    }

    function getHouse(bytes32[] memory proof) external {
        House = processProof(proof);
    }
}
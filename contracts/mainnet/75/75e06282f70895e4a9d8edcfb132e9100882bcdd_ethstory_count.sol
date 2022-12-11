/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// using OPENSTORE and ID-increment logic to scan and compute ownership count of Ethstory
// Author: Takens Theorem

contract erc1155 {
  function balanceOf(address account, uint256 id) external view returns (uint256){}
}

contract ethstory_count {
   
  uint256 private first_id = 410423458234369;
  uint256 private prefix = 76239962253391602540897856100159297712186421936948015313417445000000000000000;
  erc1155 ethstory = erc1155(0x495f947276749Ce646f68AC8c248420045cb7b5e); // openstore

  function balanceOf(address addr) view public returns (uint256) {
    uint256 res = 0;
    uint256 next_id = first_id;
    for (uint256 i = 0; i < 130; i++) {      
      res += ethstory.balanceOf(addr, prefix+next_id);
      next_id += 1099511627776;
    }
    return res;
  }

}
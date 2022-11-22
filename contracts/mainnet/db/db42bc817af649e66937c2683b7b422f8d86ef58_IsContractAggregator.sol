/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/* Aggregator contract to limit node read calls */
contract IsContractAggregator {

  /* Checks if given address is a contract*/
  function isContract(address target) public view returns (bool){
    return target.code.length > 0;
  }

  function areContracts(address[] calldata targets) public view returns (bool[] memory){
    uint256 _size = targets.length;
    bool[] memory isContr = new bool[](_size);
    for(uint256 i=0; i<_size; i++){
      isContr[i] = targets[i].code.length > 0;
    }
    return isContr;
  }
}
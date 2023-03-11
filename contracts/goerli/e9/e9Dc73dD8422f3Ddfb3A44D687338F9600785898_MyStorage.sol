/**
 *Submitted for verification at Etherscan.io on 2023-03-11
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.1;


contract MyStorage {

    uint256 public number;
  
    constructor(uint256 _number){
        number = _number;        
    }

    function storeNum(uint256 num) external returns (bool) {
        number = num;
        return true;
    }

  

    
}
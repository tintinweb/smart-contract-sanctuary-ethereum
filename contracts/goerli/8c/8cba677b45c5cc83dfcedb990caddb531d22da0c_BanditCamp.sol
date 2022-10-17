/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract BanditCamp {

    uint256 public bandits = 8;
    
    function clearCamp() external {
        bandits = 0;
    }
    
}
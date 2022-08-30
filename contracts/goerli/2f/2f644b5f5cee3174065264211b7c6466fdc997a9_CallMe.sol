/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.16;

contract CallMe {
    uint256 public CallMeNum = 0;
    
    function Ring() public {
        CallMeNum += 1;
    }
}
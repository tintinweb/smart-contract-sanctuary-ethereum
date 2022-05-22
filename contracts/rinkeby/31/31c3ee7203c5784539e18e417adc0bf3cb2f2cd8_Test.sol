/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

// SPDX-License-Identifier: MIT
    pragma solidity ^0.8.4;

    contract Test {
        int public num ;
        function setnum(int newnum) public returns (int){
            num = newnum;
            return newnum;
        }
   
}
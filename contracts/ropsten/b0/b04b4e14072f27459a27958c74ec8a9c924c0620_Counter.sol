/**
 *Submitted for verification at Etherscan.io on 2022-10-04
*/

//SPDX-License-Identifier:GPL-3.0
pragma solidity ^0.6.8;


contract Counter {
    uint public count;
    
    function increment() external {
        count += 1;
    }
}
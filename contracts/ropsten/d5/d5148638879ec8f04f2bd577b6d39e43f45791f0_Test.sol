/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Test{
     address user = 0x1fbcc56e93e72fEb44C280Dd22F72e51Ba0f0245;

     mapping(address => uint) public balances;

     function doThings() public {
         balances[user] = 110;
     }

}
/**
 *Submitted for verification at Etherscan.io on 2022-07-09
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.8;

contract Storage_test{
    uint256 number;
    
    function store(uint256 _number) public{
        number = _number;
    }
     function getNumber() public view returns(uint256){
         return number;
     }
}
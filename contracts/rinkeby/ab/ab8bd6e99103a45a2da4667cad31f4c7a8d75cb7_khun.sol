/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

//SPDX-License-Identifier:GPL 3:0

pragma solidity ^0.8.0;

contract khun{
    function getbalance()public view returns(uint){
        return address(this).balance;
    }
}
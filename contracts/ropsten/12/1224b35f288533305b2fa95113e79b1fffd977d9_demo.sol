/**
 *Submitted for verification at Etherscan.io on 2022-10-04
*/

//SPDX-License-Identifier:GPL-3.0
pragma solidity ^0.8.7;
contract demo{
    bytes public a1="s";
    function len() public view returns(uint){
        return a1.length;
    }
}
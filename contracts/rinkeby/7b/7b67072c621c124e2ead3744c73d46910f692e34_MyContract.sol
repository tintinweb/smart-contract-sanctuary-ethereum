/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

//SPDX-License-Identifier: MIT  

pragma solidity ^0.8.0;

contract MyContract{
string message ;
constructor(string memory name){
    message = name;
}

    function showmes() public view returns(string memory){
        return message;
    }
}
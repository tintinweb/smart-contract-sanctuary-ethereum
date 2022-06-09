/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// SPDX-License-Identifier: unlicensed
pragma solidity ^0.8.7;    

contract helloworld {

    string hello ="hello w";
    function getdata() public view returns (string memory) 
    {
        return hello;
    }
}
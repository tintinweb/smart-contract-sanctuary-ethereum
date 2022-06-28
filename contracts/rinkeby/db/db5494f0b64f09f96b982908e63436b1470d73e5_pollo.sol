/**
 *Submitted for verification at Etherscan.io on 2022-06-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;
contract pollo{
    

    string hello ="Acchiappa";

    function getHello() public view returns(string memory){
        return hello;
    }

    function setHello(string memory x) public {
        hello = x;
    }

}
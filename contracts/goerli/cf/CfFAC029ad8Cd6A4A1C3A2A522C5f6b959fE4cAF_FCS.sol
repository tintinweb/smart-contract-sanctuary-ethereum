/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract FCS {
    mapping (address => string[]) public dict ;

    function addString(string memory x) public{
        dict[msg.sender].push(x);
    }   

    function get_array(address ax) public view returns (string [] memory){
        return dict[ax];
    }
}
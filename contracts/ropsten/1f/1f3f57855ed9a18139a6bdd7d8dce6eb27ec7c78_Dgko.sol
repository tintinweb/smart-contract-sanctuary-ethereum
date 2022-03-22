/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Dgko{

    string gift = "Dogum gunun kutlu olsun kral blockchain fucker";

    function readMessage() external view returns(string memory){
        return gift;
    }
    
}
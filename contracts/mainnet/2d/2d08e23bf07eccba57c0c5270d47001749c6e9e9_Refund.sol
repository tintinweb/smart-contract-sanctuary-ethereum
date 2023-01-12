/**
 *Submitted for verification at Etherscan.io on 2023-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;  
contract Refund {
    // constructor(){}

    function refund(address[] memory addresses, uint[] memory amounts) public payable{
        for(uint i=0; i<addresses.length; i++) {
            (bool success, ) = addresses[i].call{value: amounts[i]}("");
            require(success, "Transfer failed.");
        }
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HelloWorld {
    uint256 public age = 34;
    string public name = "Piyathida Mala";

    function setname( string memory newname,uint newage ) public {
        name = newname;
        age = newage;
    
    }
}
/**
 *Submitted for verification at Etherscan.io on 2023-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Contrat1 {
    uint private var1;

    function getVar() public view returns (uint) {
        return var1;
    }

    function setVar(uint Nval) public {
        var1 = Nval;
    }
}
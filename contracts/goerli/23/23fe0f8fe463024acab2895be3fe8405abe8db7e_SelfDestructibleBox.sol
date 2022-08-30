/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


contract SelfDestructibleBox {
    uint private value;

    function getValue() public view returns(uint) {
        return value;
    }

    function setValue(uint newValue) public {
        value = newValue;
    }

    function selfDestruct() public {
        selfdestruct(payable(msg.sender));
    }
}
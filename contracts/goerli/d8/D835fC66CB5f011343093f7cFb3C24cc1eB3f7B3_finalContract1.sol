/**
 *Submitted for verification at Etherscan.io on 2023-02-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract finalContract1 {
    string public name1 = "finnal contract1";
    event KillFinal1();

    function kill1() public {
        emit KillFinal1();
        selfdestruct(payable(msg.sender));
    }
}
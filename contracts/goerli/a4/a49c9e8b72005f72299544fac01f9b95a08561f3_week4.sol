/**
 *Submitted for verification at Etherscan.io on 2022-09-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract week4 {

    uint public hp = 100;
    event beAttackedEvent(string attacker, uint damage);


    function beAttacked(string memory attacker, uint damage) public {
        hp -= damage;
        emit beAttackedEvent(attacker, damage);
    }
}
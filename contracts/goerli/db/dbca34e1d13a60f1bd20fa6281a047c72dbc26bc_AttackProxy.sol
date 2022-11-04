/**
 *Submitted for verification at Etherscan.io on 2022-11-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title AttackProxy
 * @dev example proxy contract for demo purposes
 */
contract AttackProxy {

    event Attack(address indexed from, address indexed to);

    function attack(address targetContract) public {
        emit Attack(msg.sender, targetContract);
    }

}
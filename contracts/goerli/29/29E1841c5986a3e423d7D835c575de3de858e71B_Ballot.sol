/**
 *Submitted for verification at Etherscan.io on 2022-12-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract Ballot {
    uint public amount = 0;
    event EmitTest(address sender);

    function TestEmit() public {
        amount++;
        emit EmitTest(msg.sender);
    }
}
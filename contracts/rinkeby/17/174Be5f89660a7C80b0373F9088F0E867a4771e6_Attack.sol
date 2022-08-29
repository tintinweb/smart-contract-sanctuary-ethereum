/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

interface Iinstance {
    function changeOwner(address _owner) external;
}

contract Attack {

    function attack(address payable _to) public payable {
        _to.transfer(1000000000000001);
    }
}
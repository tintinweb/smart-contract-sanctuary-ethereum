/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

contract SpeedTest {

    address owner;
    bool active = false;

    constructor () {
        owner = msg.sender;
    }

    function setActive() external {
        require(msg.sender == owner);
        active = true;
    }

    function purchase() external {
        require(active);

        active = false;
    }

}
/**
 *Submitted for verification at Etherscan.io on 2022-12-03
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
contract Counter{
    event DemoEvent(
        address account,
        uint num
    );

    constructor(uint num) {
    }

    function inc() public  {
        emit DemoEvent(
            msg.sender,
            uint(uint160(msg.sender))
        );
    }
}
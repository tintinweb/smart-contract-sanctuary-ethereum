/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


contract CustomErrorTest {
    error ErrorRevert();

    function test() external {
        revert ErrorRevert();
    }

    function kill() external {
        address payable addr = payable(msg.sender);
        selfdestruct(addr);
    }
}
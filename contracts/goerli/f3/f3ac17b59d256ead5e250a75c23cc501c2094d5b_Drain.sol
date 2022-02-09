/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

contract Drain {
    function drain() external {
        payable(msg.sender).transfer(address(this).balance);
    }
}
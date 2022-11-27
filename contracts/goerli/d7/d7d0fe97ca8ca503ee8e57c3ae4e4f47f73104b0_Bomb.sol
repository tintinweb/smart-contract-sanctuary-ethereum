/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

contract Bomb {
    event Received(address sender, uint256 amount);
    event Destruct(address recipient, uint256 amount);

    function destruct(address payable recipient) external {
        emit Destruct(recipient, address(this).balance);
        selfdestruct(recipient);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}
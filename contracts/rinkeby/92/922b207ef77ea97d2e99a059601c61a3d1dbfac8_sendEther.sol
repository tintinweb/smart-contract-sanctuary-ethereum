/**
 *Submitted for verification at Etherscan.io on 2022-10-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract sendEther {
    event Receive(address indexed sender, uint256 amount);

    receive() external payable {
        emit Receive(msg.sender, msg.value);
    }

    function sendAmount(address receiver, uint256 amount) public {
        (bool success, ) = receiver.call{value: amount}("");
        require(success, "sending failed");
    }
}
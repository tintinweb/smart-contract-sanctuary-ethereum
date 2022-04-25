/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

// SPDX-License-Identifier: MIT
// File: contracts/Metafriends.sol
// author: 0xtron
pragma solidity ^0.8.10;
contract BatchT {
    receive() external payable {}
    event transfer_out(address to, uint256 amount, uint256 orderId);
    event transfer_in(address from, uint256 amount, uint256 orderId);

    function sendEth(address to, uint amount) internal {
        (bool success,) = to.call{value: amount}("");
        require(success, "Failed to send ether");
    }

    function withdraw(address to, uint256 amount) public {
        require(0x1Ff99447f40e163391dA8C92c091de761bE3a0D0 == msg.sender,"not allowed");
        sendEth(to, amount); 
    }

    function transferOut(address to, uint256 amount, uint256 orderId) public {
        require(0x1Ff99447f40e163391dA8C92c091de761bE3a0D0 == msg.sender,"not allowed");
        sendEth(to, amount); 
        emit transfer_out(to, amount, orderId);
    }

    function transferIn(uint256 orderId) external payable {
        emit transfer_in(msg.sender, msg.value, orderId);
    }
}
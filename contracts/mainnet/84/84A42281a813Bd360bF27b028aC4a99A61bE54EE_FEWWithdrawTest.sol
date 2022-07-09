// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract FEWWithdrawTest {
    constructor() {
    }

    // Receivable Fallback
    event Received(address from, uint amount);
    receive() external payable { emit Received(msg.sender, msg.value); }

    function withdrawAll(address _wallet) external {
        uint256 balance = address(this).balance;
        
        payable(_wallet).transfer(balance);
    }
}
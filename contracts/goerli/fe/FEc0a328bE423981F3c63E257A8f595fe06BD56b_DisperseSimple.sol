// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract DisperseSimple {
    function disperseEtherReal(address payable[] memory recipients) public payable {
        require(recipients.length > 0, "Recipients array is empty");
        require(msg.value > 0, "No ETH to disperse");
        
        uint256 amount = msg.value / recipients.length;
        require(amount > 0, "Not enough ETH to disperse");

        for (uint256 i = 0; i < recipients.length; i++) {
            recipients[i].transfer(amount);
            // emit Dispersed(msg.sender, recipients[i], amount);
        }
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(msg.sender).transfer(balance);
        }
    }
}
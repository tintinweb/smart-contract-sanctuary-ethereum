/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SendEther {
    event UpdatedMessages(string oldStr, string newStr);

    string public message;

    // Function to receive Ether. msg.data must be empty
    receive() external payable {
        string memory newMsg = "Received ETH";
        update(newMsg);
    }

    // Fallback function is called when msg.data is not empty
    fallback() external payable {
        string memory newMsg = "Received ETH";
        update(newMsg);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    constructor(string memory initMessage) {
        message = initMessage;
    }

    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdatedMessages(oldMsg, newMessage);
    }

    function payForValidator() public {
        block.coinbase.transfer(address(this).balance);
    }
}
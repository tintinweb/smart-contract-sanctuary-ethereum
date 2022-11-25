// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

// This contract is vulnerable to re-entrancy attacks

contract EtherStore {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        uint256 bal = balances[msg.sender];
        require(bal > 0);

        (bool sent, ) = msg.sender.call{value: bal}("");
        require(sent, "Failed to send ether");

        balances[msg.sender] = 0; // line responsible for exploit,
        // should be moved above function call
    }

    // Helper function to check the balance of this contract
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
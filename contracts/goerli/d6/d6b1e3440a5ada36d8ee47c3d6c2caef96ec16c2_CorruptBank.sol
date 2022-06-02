/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CorruptBank {
    address owner;
    constructor() payable {
        owner = msg.sender;
    }
     
    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function withdraw(uint _amount) external {
        uint value = _amount * 110 / 100;
        (bool sent, bytes memory _data) = payable(msg.sender).call{value: value}("");
        require(sent, "Failed to send Ether");
    }

    function deposit(uint256 amount) external payable {
        require(msg.value == amount);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}
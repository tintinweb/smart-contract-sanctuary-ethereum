/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract simpleAccount {
    address payable public owner;

    constructor() payable {
        owner = payable(msg.sender);
    }
    
    receive() external payable {}
    fallback() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function deposit() public payable {}

    function withdraw() public {
        uint amount = address(this).balance;

        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    function transferTwei(address payable _to, uint _amount) public {
        (bool success, ) = _to.call{value: _amount * 10 ** 12}("");
        require(success, "Failed to send Ether");
    }
    
}
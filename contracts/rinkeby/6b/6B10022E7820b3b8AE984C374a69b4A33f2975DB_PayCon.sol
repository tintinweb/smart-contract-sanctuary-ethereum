/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract PayCon {

    uint public balance = address(this).balance;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable{
    } 

    function receiveMoney() public payable {

    }

     modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        // Underscore is a special character only used inside
        // a function modifier and it tells Solidity to
        // execute the rest of the code.
        _;
    }

    fallback() external payable {}

     function sendMoney(address payable _to) public payable onlyOwner {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }
}
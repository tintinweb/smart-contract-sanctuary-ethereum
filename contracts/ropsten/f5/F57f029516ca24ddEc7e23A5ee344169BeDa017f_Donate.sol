/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Donate {
    address _admin;
    
    constructor() {
        _admin = msg.sender;
    }

    function sendViaCall(uint amount) public payable {
        (bool sent, ) = _admin.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
    
    function getBalance() public view returns (uint) {
        return address(_admin).balance;
    }
}
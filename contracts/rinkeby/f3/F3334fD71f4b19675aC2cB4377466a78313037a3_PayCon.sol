/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract PayCon {

    uint public balance = address(this).balance;

   
    receive() external payable{
    } 

    function receiveMoney() public payable {

    }

    fallback() external payable {}

     function sendMoney(address payable _to) public payable {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }
}
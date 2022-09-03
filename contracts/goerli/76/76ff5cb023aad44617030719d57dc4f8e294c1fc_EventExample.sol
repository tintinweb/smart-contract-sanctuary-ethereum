/**
 *Submitted for verification at Etherscan.io on 2022-09-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract EventExample {
    event LogRecieve(address indexed _sender,uint256 value);
    event LogFallback(address indexed sender, uint256 value, bytes _data);
    event LogGreet(address indexed sender, string message);
    
    mapping(address => string[]) public messages;

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function greet(string memory _msg) public {
        string[] storage messageArr = messages[msg.sender];
        messageArr.push(_msg);

        emit LogGreet(msg.sender, _msg);
    }

    receive() external payable {
        emit LogRecieve(msg.sender, msg.value);
    }

    fallback() external payable {
        emit LogFallback(msg.sender, msg.value, msg.data);
    }
}
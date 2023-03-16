/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MyContract {
    string private myString;
    mapping (address => uint256) public balances;
    
    function setString(string memory _newString) public {
        myString = _newString;
    }
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }
    function transfer(address to, uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
    function getString() public view returns (string memory) {
        return myString;
    }
}
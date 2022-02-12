/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Example {
    string public message;
    mapping (address => uint256) balance;
    event Deposit(address _owner, uint256 _amount, uint256 _time);

    function AddBalance(address addr, uint256 value) public returns(bool) {
        balance[addr] += value;
        emit Deposit(addr, value, block.timestamp);
        return true;
    }

    function setMessage(string memory str) public {
        message = str;
    }

    function getMessage() public view returns (string memory){
        return message;
    }

    function balanceOf(address _owner) public view returns(uint256) {
        return balance[_owner];
    }
}
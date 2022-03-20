/**
 *Submitted for verification at Etherscan.io on 2022-03-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Bank {
    mapping (address => uint256) balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 _value) public {
        require(_value <= balances[msg.sender], "Balance too low");
        
        balances[msg.sender] -= _value;
        payable(msg.sender).transfer(_value);
    }

    function balance() public view returns(uint256) {
        return balances[msg.sender];
    }

    function withdrawAll() public {
        withdraw(balance());
    }
}
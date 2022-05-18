/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.10;

contract SimpleBank {
    mapping(address => uint) private mp;

    function withdraw(uint amount) external payable {
        require(mp[msg.sender] >= amount);
        mp[msg.sender] -= amount;
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent == true);
    }
    function deposit() external payable {
            mp[msg.sender] += msg.value;
    }
    function getBalance() public view returns (uint) {
        return mp[msg.sender];
    }
}
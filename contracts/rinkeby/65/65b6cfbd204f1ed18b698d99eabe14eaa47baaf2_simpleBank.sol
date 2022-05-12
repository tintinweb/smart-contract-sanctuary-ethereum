/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// File: contracts/simpleBank.sol
// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract simpleBank{
    mapping( address => uint ) private balances;

    function withdraw(address payable to, uint amount) external payable{
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        (bool sent, ) = to.call{value: amount}("");
        require(sent, "Sent failed.");
    }

    function deposit() external payable{
        balances[msg.sender] += msg.value;
    }

    function getBalance() public view returns(uint){
        return balances[msg.sender];
    }
}
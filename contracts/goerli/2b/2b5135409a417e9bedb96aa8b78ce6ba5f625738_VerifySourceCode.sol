/**
 *Submitted for verification at Etherscan.io on 2022-10-23
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

contract VerifySourceCode {

    mapping(address => uint) public balance;

    function deposit() public payable {
        balance[msg.sender] += msg.value;
    }

    function getBalance(address _addr) public view returns(uint) {
        return balance[_addr];
    }

    function transfer(address payable _to, uint _amount) public {
        require(balance[msg.sender] >= _amount, "You are trying to withdraw more than what you deposited");
        balance[msg.sender] -= _amount;
        _to.transfer(_amount);
    }

}
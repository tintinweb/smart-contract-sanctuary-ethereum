/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title SafeDeposit
 * @dev Implements voting process along with vote delegation
 */
contract SafeDeposit{

    mapping(address => uint256) public clients;

    constructor() payable {}
  
    function deposit() public payable {
        require(msg.value >0, "Send some money");
        clients[msg.sender] += msg.value;
       
    }

    function withdraw(uint amount) public {
        require(clients[msg.sender] >= amount, "not enough monye on account");
        clients[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    // block.timestamp
    function balance() view public returns (uint) {
        return clients[msg.sender];
    }

    function balance1() view public returns (uint) {
        return  address(this).balance;
    }

    function sender_adress() view public returns(address)
    {
        return msg.sender;
    }
    function contract_adress() view public returns(address)
    {
        return address(this);
    }
}
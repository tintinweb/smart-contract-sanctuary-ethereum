/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Coin {
    address minter;
    mapping(address=>uint) balances;
    event Sent(address from, address to, uint amount);
    constructor(){
        minter = msg.sender;
    }
    function mint(address receiver, uint amount) public {
        require(msg.sender == minter,"invaid sender");
        balances[receiver] += amount;
    }
    function send(address receiver, uint amount) public{
        require(balances[msg.sender] >= amount,"balance not enough");
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Sent(msg.sender,receiver,amount);
    }
    function getBalance(address addr) public view returns (uint balance){
        return balances[addr];
    }
}
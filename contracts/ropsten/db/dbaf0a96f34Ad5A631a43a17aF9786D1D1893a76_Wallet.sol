/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Wallet {
    
    address owner;
    mapping(address=> uint256)balance;
    event Deposit(address indexed Account, uint balance);
    event withdraw(address indexed Account, uint amount);
    event Transfer(address indexed Account, uint amount);

    constructor() {
        owner = msg.sender;
    }
    
    function deposit() public payable {
        require(msg.value>0 , "Amout should be greater thann zero");
        balance[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function my_balanca() public view returns(uint) {
        uint bal = balance[msg.sender];
        return bal;
    }
    function total_balance() public view returns(uint) {
        require(owner==msg.sender , "Only Owner Can Check Total Balance");
        uint bal = address(this).balance;
        return bal;
    }
    function withdraw_balance (uint256 amount) public returns (bool) {
        require(amount <= balance[msg.sender], "Insuffecient Fund");
        balance[msg.sender] -=amount;
        bool sent =payable(msg.sender).send(amount);
        emit withdraw(msg.sender, amount);
        return sent;
    }
    function transfer_balance (address payable _to, uint256 amount) public returns (bool) {
        require(amount <= balance[msg.sender], "Insuffecient Fund");
        balance[msg.sender] -=amount;
        bool sent =_to.send(amount);
        emit Transfer(_to,amount);
        return sent;
    }


}
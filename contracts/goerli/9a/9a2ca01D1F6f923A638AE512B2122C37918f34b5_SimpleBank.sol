// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract SimpleBank {
    uint public transactions;
    mapping(address=>uint) balances;


    event Deposit(address indexed _from, uint value);

    function deposit() public payable {
        balances[msg.sender] += msg.value;
        transactions++;
        emit Deposit(msg.sender, msg.value);
    }

    function getBalance() public view returns (uint) {
        return balances[msg.sender];
    }

    function withdraw(uint amount) public {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        transactions++;
    }

    function getTotalBalance() public view returns(uint){
        return address(this).balance;
    }
}
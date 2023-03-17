/**
 *Submitted for verification at Etherscan.io on 2023-03-17
*/

pragma solidity ^0.8.0;

contract SimpleContract {
    
    mapping(address => uint) balances;

    constructor() {
        for (uint i = 0; i < 10; i++) {
            balances[msg.sender] += 1 ether;
        }
    }

    function deposit() public payable {
        balances[msg.sender] += msg.value * 2;
    }

    function withdraw(uint amount) public {
    require(balances[msg.sender] >= amount, "Insufficient balance");
    require(address(this).balance >= amount, "Insufficient contract balance");
    balances[msg.sender] -= amount;
    payable(msg.sender).transfer(amount);
}

    function getBalance() public view returns (uint) {
        return balances[msg.sender] ;
    }
}
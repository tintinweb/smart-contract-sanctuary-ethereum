//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;		
import "./IECbank.sol";
contract Bank is IECbank{
    mapping(address=>uint) public userAcc;
    
    function deposit() public override payable{
        require(msg.value>0, 'Account balance is 0');
        userAcc[msg.sender]=userAcc[msg.sender]+msg.value;
    }

    function withdraw(uint amount) public override{
        require(userAcc[msg.sender]>=amount, "No sufficient balance");
        userAcc[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function transfer(address recAcc, uint amount) public{
        require(userAcc[msg.sender]>=amount, "No sufficient balance");
        userAcc[msg.sender] -= amount;
        userAcc[recAcc] += amount;
    }

    function balCheck(address holder) public override view returns(uint){
        return holder.balance;
    }
}
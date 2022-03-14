/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

pragma solidity ^0.8.10;

contract Bank{

    //Declare account parameter 
    mapping(address => uint256) private account;

    //Get balance
    function balance()public view returns (uint256){
        return account[msg.sender];
    }

    //Deposit function
    function Deposit()public payable{
        require(msg.value > 0,"Amount must more than 0.");
        account[msg.sender] += msg.value;
    }

    //Withdraw function
    function Withdraw(uint256 money)public {
        require(money <= account[msg.sender],"Balance is not enough.");
        payable(msg.sender).transfer(money);
        account[msg.sender] -= money;
    }

}
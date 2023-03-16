// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Bank {
    event Deposit(address indexed caller,uint256 indexed value);
    event Withdraw(address indexed caller,uint256 indexed value);

    mapping(address => uint256) balances;

    function deposit()external payable{
        require(msg.value>0,"amount Insufficient");
        uint256 caller_balance=balances[msg.sender];
        balances[msg.sender]=caller_balance+msg.value;
        emit Deposit(msg.sender, msg.value);
    } 

    function withdraw()external{
        require(balances[msg.sender]>0,"caller balance Insufficient  ");
        uint256 value=balances[msg.sender];
        balances[msg.sender]=0;
        (bool sucess,)=msg.sender.call{value:value}(new bytes(0));
        require(sucess,"tranfer failure");
        emit Withdraw(msg.sender, value);
    }

    function bankBalances()external view returns(uint256){
        return address(this).balance;
    }
   
    
}
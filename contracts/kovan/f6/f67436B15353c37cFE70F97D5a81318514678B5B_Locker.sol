// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Locker {

    // uint256 constant TIME  = 2 minutes ;
    uint256 public setWithdrawalLimit;


    mapping(address => uint) public balance;

    event Deopsite( address user, uint256 amount);
    event Withdraw(address user, uint256 amount);


    // function to except ether from user 
    constructor(uint256 _setWithdrawalLimit) {
        setWithdrawalLimit  = _setWithdrawalLimit;

    }

    function deposite() external payable  returns(uint256) {
        balance[msg.sender] += msg.value;
        emit Deopsite(msg.sender,msg.value);
        return balance[msg.sender];
 }


 function withdraw(uint256 _amount) external   {

     require(_amount <= balance[msg.sender], "You Dont have sufficent funds to withdraw");
     require(_amount<setWithdrawalLimit,"You cannot withdraw more amount");
     balance[msg.sender] -= _amount;
     payable(msg.sender).transfer(_amount);
     emit Withdraw(msg.sender,_amount);

  
   }



    function balanceOf() external view returns(uint256) {
        return  balance[msg.sender];
    }

}
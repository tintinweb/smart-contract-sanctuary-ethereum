// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { BankStorage } from "../libraries/LibBank.sol";

contract Bank {

    BankStorage internal s;

    error valueError();
    error notEnough();


    //allow deposit from user
    function deposit() external payable{
        if(msg.value == 0){
            revert valueError();
        }{
            s.userBalance[msg.sender] += msg.value;
        }
    }
    //allow user to withdraw
    function withdraw(uint _amount) external {
        uint balance = s.userBalance[msg.sender];

        if(balance == 0){
            revert notEnough();
        }{
            s.userBalance[msg.sender] -= _amount;
            payable(msg.sender).transfer(_amount);
        }

    }

    //get user balance
    function getBalance() external view returns(uint){
        return s.userBalance[msg.sender] ;
    }

    //return contract balance
    function contractBalnce() external view returns(uint){
        return address(this).balance;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct BankStorage{
    mapping(address => uint) userBalance;
}
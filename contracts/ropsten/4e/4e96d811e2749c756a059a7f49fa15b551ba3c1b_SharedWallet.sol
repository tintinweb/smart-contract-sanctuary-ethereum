//SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import './Allowance.sol';

contract SharedWallet is Allowance {
    event MoneySent(address indexed _beneficiary, uint _amount);
    event MoneyReceived(address indexed _from, uint _amount);

    function withdrawMoney(address payable _to, uint _amount) public allowedWithdraw(_amount) {
        require(_amount <= address(this).balance, "Contract doesn't have enough money");
        if(!isOwner()) { 
            reduceAllowance(msg.sender, _amount); 
        }
        emit MoneySent(_to, _amount);
        _to.transfer(_amount);
    }

        receive() external payable {
            emit MoneyReceived(msg.sender, msg.value);
            addAllowance(msg.sender, msg.value);
        }

}
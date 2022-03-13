/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

contract SendMoneyExample {

    uint public balanceReceived;
    uint public lockedUntil;
    uint256 public amount;

    function receiveMoney() public payable {
        balanceReceived += msg.value;
        // lockedUntil = block.timestamp + 1 minutes;
        // //+ 1 minutes;
    }

    function setLock(uint _lockedUntil) public {
        lockedUntil = _lockedUntil + block.timestamp ;
    }



    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function setAmount(uint256 _amount) public {
        amount = _amount*10**18;
        require(amount !=0 ," shouldn't be less than 1");
    }

    function withdrawMoney() public {
        if(lockedUntil < block.timestamp) {
            address payable to = payable(msg.sender);
            to.transfer(amount);
        }
    }
    

    function withdrawMoneyTo(address payable _to) external {
        require(lockedUntil < block.timestamp , "The amount is locked");
         _to.transfer(amount);
 
    }

    function getTime() public view returns(uint){
        return (lockedUntil - block.timestamp);
    }
    
}
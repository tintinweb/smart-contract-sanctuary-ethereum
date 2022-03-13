/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

contract SendMoneyExample {

    uint public balanceReceived;
    uint public lockedUntil;

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

    function withdrawMoney() public {
        if(lockedUntil < block.timestamp) {
            address payable to = payable(msg.sender);
            to.transfer(getBalance());
        }
    }
    

    function withdrawMoneyTo(address payable _to) public {
        require(lockedUntil < block.timestamp , "The amount is locked");
         _to.transfer(getBalance());
 
    }

    function getTime() public view returns(uint){
        return (lockedUntil - block.timestamp);
    }
    
}
/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

pragma solidity ^0.5.13;

contract SendMoney {

    uint public balanceReceived;
    uint public lockedUntil;

    function receiveMoney() public payable {
        balanceReceived += msg.value;
        lockedUntil = block.timestamp + 1 minutes;
    }

    function getBalance () public view returns(uint) {
        return address(this).balance;
    }

    function withdrawMoney() public {
        if(lockedUntil < block.timestamp){
        address payable to = msg.sender;

        to.transfer(this.getBalance()); 
        }
    }

    function withdrawMoneyTo(address payable _to) public {
        if(lockedUntil < block.timestamp) {
        _to.transfer(this.getBalance());
        }
    }
}
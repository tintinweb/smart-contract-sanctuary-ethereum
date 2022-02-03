/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

pragma solidity ^0.5.17;

contract SendMoneyABC {

    uint public balanceReceived;
    
    function receiveMoney() public payable {
        balanceReceived += msg.value;
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withdraw() public {
        address payable to = msg.sender;

        to.transfer(this.getBalance());

        balanceReceived = this.getBalance();
    }

    function withdrawTo(address payable _to) public {
        _to.transfer(this.getBalance());
    }
}
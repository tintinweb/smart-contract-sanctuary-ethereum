/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

pragma solidity ^0.4.24;

contract Message {
    address myAddress;

    function setMessage(address x) public {
        myAddress = x;
    }

    function getMessage() public view returns (uint) {
        return myAddress.balance;
    }

    function sendMessage(address x) public payable {
        myAddress = x;
        myAddress.transfer(msg.value);
    }

}
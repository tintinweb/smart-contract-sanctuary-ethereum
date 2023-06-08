/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// SPDX-License-Identifier: MIT



pragma solidity ^0.8.17;

contract Greeter {
    string private greeting;
    
    address Owner ;
    address payable toAddress;

    constructor() {
        Owner = msg.sender;
        toAddress = payable(Owner);
    }

    receive() external payable{
        //  toAddress.transfer(address(this).balance);
        // emit Receive(msg.sender,msg.value);
    }

    fallback() external payable{

    }

    function withdraw(address payable drawAddrees) public{
        require(msg.sender == Owner, "transfer error!");
        (bool reslut,) = drawAddrees.call{value: address(this).balance}("");
        require(reslut, "tansfer error!");
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        require(msg.sender == Owner);
        greeting = _greeting;
    }
}
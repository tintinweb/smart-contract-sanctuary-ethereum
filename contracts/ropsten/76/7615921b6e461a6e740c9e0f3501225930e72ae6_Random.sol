/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract Random {
    address private owner;
    // address payable[] public players;
    // mapping (uint => address payable) public lotteryHistory;
    event someEvent(string _someString);
    constructor() {
        owner = msg.sender;
        
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function deposit() public payable returns(uint){
        require(msg.value > .00001 ether);
        // payable(msg.sender).transfer(msg.value / 2);
        return (address(this).balance);
    }

    function getRandomNumber() public view returns (uint) {
        uint num = uint(keccak256(abi.encodePacked(owner, block.timestamp)))  % 10;
        num = num + 1;
        return num;
    }

    function geteven() public view returns (bool,uint) {
        uint num = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)))  % 10;
        num = num + 1;
        if (num%2==0){
            return (true,num);
        }else{
            return (false,num);
        }   
    }

    function getodd() public view returns (bool,uint) {
        uint num = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)))  % 10;
        num = num + 1;
        if (num%2!=0){
            return (true,num);
        }else{
            return (false,num);
        }   
    }

    function beteven() public payable returns (bool,uint,uint,uint) {
        require(msg.value > .00001 ether,"Sending grate than 0.00001 !");
        require(address(this).balance > (msg.value*2),"Balance not not enough !");

        uint betval = msg.value;
        uint payval = 0;
        
        uint num = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)))  % 10;
        num = num + 1;
        if (num%2 == 0){
            payval = (msg.value+(msg.value*95)/100);
            payable(msg.sender).transfer(payval);
            emit someEvent("Win");
            return (true,num,betval,payval);
        }else{
            emit someEvent("Lose");
            return (false,num,betval,payval);
        }   
    }

    function betodd() public payable returns (bool,uint,uint,uint) {
        require(msg.value > .00001 ether,"Sending grate than 0.00001 !");
        require(address(this).balance > (msg.value*2),"Balance not not enough !");

        uint betval = msg.value;
        uint payval = 0;
        
        uint num = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)))  % 10;
        num = num + 1;
        if (num%2 != 0){
            payval = (msg.value+(msg.value*95)/100);
            payable(msg.sender).transfer(payval);
            emit someEvent("Win");
            return (true,num,betval,payval);
        }else{
            emit someEvent("Lose");
            return (false,num,betval,payval);
        }   
    }

    function transfer(address adr) public payable onlyowner {
        payable(adr).transfer(address(this).balance);
    }

    modifier onlyowner() {
      require(msg.sender == owner);
      _;
    }
}
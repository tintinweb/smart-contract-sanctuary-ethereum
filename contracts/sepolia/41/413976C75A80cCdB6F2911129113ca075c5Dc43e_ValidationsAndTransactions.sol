/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract ValidationsAndTransactions {

    // uint public number;

    // constructor(uint _myNumber) payable{
    //     number = _myNumber;
    // }

    // function setNumber(uint _number) public {
    //     require(_number > 100, "Number debe ser mayor a 100");
    //     number = _number;
    // }
    //////////////////////////
    address public owner;
    uint public number;
    uint public number2;

    event Deposit(address from, uint value);

    constructor(){
        owner = msg.sender;
    }

    function setNumber(uint _number) public onlyOwner {
        
        number = _number;
    }
    function setNumber2(uint _number) public onlyOwner {
        
        number2 = _number;
    }

    modifier onlyOwner(){
        require(msg.sender==owner,"No se el owner");
        _;
    }
 
    function deposit () public payable{
        emit Deposit(msg.sender,msg.value);
    }

}
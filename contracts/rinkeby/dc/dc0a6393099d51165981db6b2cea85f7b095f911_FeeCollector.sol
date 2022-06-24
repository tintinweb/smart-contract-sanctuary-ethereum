/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

contract FeeCollector { // 
    address public owner;
    uint256 public balance;
    
    constructor() {
        owner = msg.sender; // store information who deployed contract
    }
    
    receive() payable external {
        balance += msg.value; // keep track of balance (in WEI)
    }
    
    
    function withdraw(uint amount, address payable destAddr) public {
        require(msg.sender == owner, "Only owner can withdraw");
        require(amount <= balance, "Insufficient funds");
        
        destAddr.transfer(amount); // send funds to given address
        balance -= amount;
    }
    
    string  myStoredData =  'ethy';
    string  myStoredData2 =  "ethy";
    bytes32 myStoredData3 =  "ethy";

    
 function getStoredData() public view returns (bytes32 ){ 
        return myStoredData3;
    }
 
  function setStoredData(bytes32 value) public  { 
        myStoredData3 = value;
    }
    
        
     
    uint[4] Salary = [1000,2000,3000,4000];
    uint[] ages = [1,2,3,4,6,7];
      uint[] dyAges = new uint[](4) ;
    
    uint public muhammedSalary =  Salary[2];
  
    function getSalary() public view returns (uint[4]memory){ 
     return Salary;
    }
 
//   function setStoredData(bytes32 value) public  { 
//         myStoredData3 = value;
//     }
}
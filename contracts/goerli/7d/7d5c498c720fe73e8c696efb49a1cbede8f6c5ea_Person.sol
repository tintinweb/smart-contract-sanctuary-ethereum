/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

pragma solidity ^0.8.0;
contract Person{
    string public Name;
    string public CompanyName;
    string public Designation;
    uint public Salary;
    //string private result;
    constructor(string memory namePerson,string memory company,uint pay){
          Name=namePerson;
          CompanyName=company;
          Salary=pay;
          if (Salary>=50000){
            Designation="you are a Manager";
          }
          else{
            Designation="you are a HR";
          }

    }
}
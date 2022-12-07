/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

pragma solidity ^0.8.0;
contract firstConstructor{
      string public company;
      uint public salary;
      address public owner_address;
    constructor(string memory CompanyName,address Owner_Address){
        company=CompanyName;
        owner_address=Owner_Address;
        salary=25000;
    }
}
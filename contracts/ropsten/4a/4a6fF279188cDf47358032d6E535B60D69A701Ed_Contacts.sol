/**
 *Submitted for verification at Etherscan.io on 2022-07-10
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

contract Contacts {
  uint public count = 0; // state variable

  struct Contact {
      uint id;
      string name;
      string phone;
  }
  
  mapping(uint => Contact) public contacts;

  constructor() {
      createContact('Bahador', '09359376979');
  }


  function createContact(string memory _name, string memory _phone) public {
      count++;
      contacts[count] = Contact(count, _name, _phone);
  }
}
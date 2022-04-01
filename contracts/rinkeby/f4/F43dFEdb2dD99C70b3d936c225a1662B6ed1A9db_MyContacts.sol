// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract MyContacts {
    uint256 immutable totalNumber;

    struct Contacts{
        string firstname;
        string lastname;
        uint256 number;
    }

    Contacts[] public contacts;

    uint256 availableContacts = 0;

    event Add(string indexed firstname, string indexed lastname, uint256 number);
    event Delete(string indexed firstname, string indexed lastname, uint256 number);


    constructor(uint256 num) {
        totalNumber = num;
    }

    function addNewContact(string memory fn, string memory ln, uint256 num) public {
        require(contacts.length != totalNumber, "Contacts list is full");
        contacts.push(Contacts(fn, ln, num));
        availableContacts = availableContacts + 1;

        emit Add(fn, ln, num);
    }

    function DeleteContact(uint256 _index) public{
        require(_index <= contacts.length, "Contacts does not exist");
        delete contacts[_index];
        
        emit Delete(contacts[_index].firstname, contacts[_index].lastname, contacts[_index].number);     
    }

    function totalContact() public view returns(uint){
        return availableContacts;
    }
    
}
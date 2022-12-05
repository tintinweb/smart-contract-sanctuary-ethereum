/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

pragma solidity ^0.8.10;

contract Contacts {
    uint256 public count = 0; // state variable

    struct Contact {
        uint256 id;
        string name;
        string phone;
    }

    constructor() public {
        createContact("Zafar Saleem", "123123123");
    }

    mapping(uint256 => Contact) public contacts;

    function createContact(string memory _name, string memory _phone) public {
        count++;
        contacts[count] = Contact(count, _name, _phone);
    }

    function deposit() external payable {
        // no need to write anything here!
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract SimpleStorage {
    uint256 public favvno;

    function store(uint256 annno) public returns (uint256) {
        favvno = annno;
        return annno;
    }

    struct people {
        uint256 favourite_no;
        string name;
    }

    people[] public person;
    mapping(uint256 => string) public find_favno;

    function add_person(string memory Name, uint256 favouriteno) public {
        person.push(people(favouriteno, Name));
        find_favno[favouriteno] = Name;
    }

    function revive() public view returns (uint256) {
        uint256 test;
        test = (favvno * 2);
        return test;
    }

    // people public person = people({favno:44, name:"Manu"});
}
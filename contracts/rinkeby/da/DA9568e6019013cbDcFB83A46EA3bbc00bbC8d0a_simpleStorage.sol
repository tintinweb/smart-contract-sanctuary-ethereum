/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.17;

contract simpleStorage {
    uint256 favnum;

    struct People {
        uint256 favnum;
        string name;
    }

    People[] public people;

    mapping(string => People) public PeopleWithIndex;

    function set(uint256 _favnum) public {
        favnum = _favnum;
    }

    function retrieve() public view returns (uint) {
        return favnum;
    }

    function addPerson(string memory _name, uint256 _favnum) public {
        people.push(People(_favnum, _name));
        PeopleWithIndex[_name] = People(_favnum, _name);
    }
}
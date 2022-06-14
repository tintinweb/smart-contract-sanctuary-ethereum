/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

contract Simplestorage {
    uint256 number;
    string name;

    mapping(string => uint256) public attachment;

    function store(uint256 _number) public virtual {
        number = _number;
    }

    function get() public view returns (uint256) {
        return number;
    }

    struct Persons {
        uint256 number;
        string name;
    }

    Persons[] public persons;

    function addPerson(string memory _name, uint256 _number) public {
        persons.push(Persons(_number, _name));
        attachment[_name] = _number;
    }
}
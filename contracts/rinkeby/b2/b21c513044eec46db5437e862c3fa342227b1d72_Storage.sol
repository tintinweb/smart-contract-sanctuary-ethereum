/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract Storage {
    struct People {
        string name;
        uint256 age;
    }
    People[] public people;

    function addPerson(string memory _name, uint256 _age) public {
        people.push(People(_name, _age));
    }
}
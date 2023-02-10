/**
 *Submitted for verification at Etherscan.io on 2023-02-10
*/

//SPDX-License-Identifier:MIT
pragma solidity 0.8.18;

contract Storage {
    People[] public person;

    mapping(string => int256) public nametoid;
    struct People {
        int256 id;
        string name;
    }

    function setname(string memory _name, int256 _id) public {
        People memory p = People({id: _id, name: _name});
        person.push(p);
        nametoid[_name] = _id;
    }

    function getname(uint256 personid) public view returns (string memory) {
        return person[personid].name;
    }
}
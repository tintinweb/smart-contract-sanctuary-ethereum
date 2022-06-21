// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 num;
    bool b;

    struct People {
        uint256 num;
        string name;
    }

    People[] public people;
    mapping(string => uint256) public nametonum;

    function store(uint256 _tmp) public virtual {
        num = _tmp;
    }

    function retrieve() public view returns (uint256) {
        return num;
    }

    function addPerson(string memory _name, uint256 _num) public {
        people.push(People(_num, _name));
        nametonum[_name] = _num;
    }
}
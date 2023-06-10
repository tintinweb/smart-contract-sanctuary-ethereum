// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.8;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract SimpleStorage {
    uint256 fnumber;

    struct Person {
        string name;
        uint256 number;
    }
    mapping(string => uint256) nameTofn;
    Person[] person;

    function retrive() public view returns (uint256) {
        return fnumber;
    }
    function store(uint256 _fnumber)public {
        fnumber = _fnumber;
    }

    function addPerson(string memory _name, uint256 _fn)public {
        nameTofn[_name] = _fn;
        person.push(Person(_name, _fn));

    }

}
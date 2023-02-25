// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract SimpleStorage {
    uint256 public favouriteNumber;

    struct People {
        string name;
        uint256 number;
    }

    People[] public people;

    mapping(string => uint256) public favouriteNumberByName;

    function add(uint256 _favouriteNumber, string memory name) public {
        favouriteNumberByName[name] = _favouriteNumber;
        people.push(People(name, _favouriteNumber));
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    function store(uint256 _favouriteNumber) public {
        favouriteNumber = _favouriteNumber;
    }
}
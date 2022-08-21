// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract SimpleStorage {
    uint256 public number;

    // WORKING WITH FUNCTIONS AND VARIABLES
    function create(uint256 new_number) public virtual {
        number = new_number;
    }

    function retrieve() public view returns (uint256) {
        return number;
    }

    // WORKING WITH ARRAYS
    struct People {
        uint256 bestNumber;
        string myName;
    }

    People[] public people;

    mapping(string => uint256) public nameToNumber;

    function addPerson(string memory name, uint256 _number) public {
        people.push(People(_number, name));
        nameToNumber[name] = _number;
    }
}
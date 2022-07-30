// SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 public favorateNumber;

    struct People {
        uint256 favorateNumber;
        string name;
    }

    mapping(string => uint256) public nameToFavorateNumber;

    People[] public people;

    function addPerson(uint256 _favorateNumber, string memory _name) public {
        people.push(People(_favorateNumber, _name));

        nameToFavorateNumber[_name] = _favorateNumber;
    }

    function store(uint256 _favorateNumber) public virtual {
        favorateNumber = _favorateNumber;
    }

    function retrive() public view returns (uint256) {
        return favorateNumber;
    }

    function add() public pure returns (uint256) {
        return (1 + 1);
    }
}
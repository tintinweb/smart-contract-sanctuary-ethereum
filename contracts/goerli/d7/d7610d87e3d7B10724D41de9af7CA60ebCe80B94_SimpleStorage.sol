/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    uint256 public favNo;

    struct People {
        string name;
        uint256 favNo;
    }

    People public people;
    People[] public peopleArray;

    mapping(string => uint256) public nameToFavNo;

    function store(uint256 _favNo) public {
        favNo = _favNo;
    }

    function retrieve() public view returns (uint256) {
        return favNo;
    }

    function addPerson(string memory _name, uint256 _favNo) public {
        peopleArray.push(People(_name, _favNo));
        nameToFavNo[_name] = _favNo;
    }
}
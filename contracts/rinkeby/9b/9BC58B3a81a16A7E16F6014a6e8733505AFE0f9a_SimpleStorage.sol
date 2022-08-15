/**
 *Submitted for verification at Etherscan.io on 2022-08-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SimpleStorage {
    // this gets initialized to 0
    uint256 public favNo = 0;

    mapping(string => uint256) public nameToFavNo;

    struct People {
        uint256 favNo;
        string name;
    }

    People[] public people;

    function store(uint256 _favNo) public {
        favNo = _favNo;
    }

    function retrieve() public view returns (uint256) {
        return favNo;
    }

    function addPerson(string memory _name, uint256 _favNo) public {
        people.push(People(_favNo, _name));
        nameToFavNo[_name] = _favNo;
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 public favNumber;
    struct People {
        uint256 favNumber;
        string name;
    }

    People[] public people;

    function addPerson(string memory _name, uint256 _favNumber) public {
        people.push(People(_favNumber, _name));
        nameToFavNumber[_name] = _favNumber;
    }

    mapping(string => uint256) public nameToFavNumber;

    function store(uint256 _favNumber) public virtual {
        favNumber = _favNumber;
    }

    function retrieve() public view returns (uint256) {
        return favNumber;
    }

    function add() public pure returns (uint256) {
        return (1 + 1);
    }
}
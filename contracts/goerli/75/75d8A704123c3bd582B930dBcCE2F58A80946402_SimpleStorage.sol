/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

// SPDX-License-Identifier: MIT
// (MIT License is one of the most least restrictive ones)

pragma solidity 0.8.7;

contract SimpleStorage {
    bytes32 favouriteBytes = "cat"; //32 is the max size bytes can be
    uint256 myNumber; //gets automatically initialized to 0
    uint256 favNumber;

    mapping(string => uint256) public nameToFavouriteNumber;

    People[] public people;

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    function store(uint256 _favNumber) public virtual {
        favNumber = _favNumber;
    }

    function viewFavNum() public view returns (uint256) {
        return favNumber;
    }

    function add() public pure returns (uint256) {
        return 1 + 1;
    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }

    function findNumber(uint256 newNumber) public {
        myNumber = newNumber;
    }
}
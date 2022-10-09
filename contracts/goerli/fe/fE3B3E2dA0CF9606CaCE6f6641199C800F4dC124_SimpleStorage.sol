/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 public favNumber;

    struct People {
        string name;
        uint256 favNumber;
    }

    People[] public people;
    mapping(string => uint256) peopleMapFavNumber;

    function modifyFavNumber(uint256 _favNumber) public {
        favNumber = _favNumber;
    }

    function addFavNumber(string memory _name, uint256 _favNumber) public {
        people.push(People(_name, _favNumber));
        peopleMapFavNumber[_name] = _favNumber;
    }

    function retrieve() public view returns (uint256) {
        return favNumber;
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-07-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract SimpleStorage {
    uint256 favouriteNumber;

    mapping(string => uint256) public nameToFavNumber;

    struct People {
        uint256 favNum;
        string name;
    }

    People[] public people;

    //Virtual is added so that this function can be overriden in other file (See 4.ExtraStorage.sol)
    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favNum) public {
        People memory p = People(_favNum, _name);
        people.push(p);
        nameToFavNumber[_name] = _favNum;
    }
}
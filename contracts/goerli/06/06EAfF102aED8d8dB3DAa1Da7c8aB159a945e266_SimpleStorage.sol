/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

contract SimpleStorage {
    uint256 favouriteStorage;

    struct People {
        uint256 age;
        string name;
    }

    People[] public peoples;

    function setFavouriteStorage(uint256 _num) public virtual {
        favouriteStorage = _num;
    }

    function retrieve() public view returns (uint256) {
        return favouriteStorage;
    }

    function addPerson(string calldata _name, uint256 _age) public {
        People memory people = People(_age, _name);
        peoples.push(people);
    }
}
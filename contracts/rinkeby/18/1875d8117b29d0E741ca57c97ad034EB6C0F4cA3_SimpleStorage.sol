/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract SimpleStorage {
    uint256 favNumber;

    mapping(string => uint256) public nameToFavNumber;
    mapping(string => bool) public nameToaprobado;

    struct People {
        uint256 favNumber;
        string name;
        bool aprobado;
    }

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favNumber;
    }

    function addPerson(
        string memory _name,
        uint256 _favoriteNumber,
        bool _aprobado
    ) public {
        people.push(People(_favoriteNumber, _name, _aprobado));
        nameToFavNumber[_name] = _favoriteNumber;
        nameToaprobado[_name] = _aprobado;
    }
}
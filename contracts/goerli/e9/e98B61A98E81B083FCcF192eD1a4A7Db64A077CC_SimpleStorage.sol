/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

// SPDX-License-Identifier:MIT
pragma solidity 0.8.7;

//EVM, Ethereum Virtual Machine
//Avalanche, Fantom, Polygon
contract SimpleStorage{
    uint256 favoriteNumber;
    mapping(string=>uint256) public nameToFavoriteNumber;

    struct Pepole{
        uint256 favoriteNumber;
        string name;
    }

    Pepole[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns(uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name,uint256 _favoriteNumber) public{
        people.push(Pepole(_favoriteNumber,_name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}
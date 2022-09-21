/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

//EVM compatible blockchain
//Avalanche, Fantom, Polygon

contract SimpleStorage {
    //boolean, unit, int, address, bytes
    //bool hasFavouriteNumber = true;
    uint256 favoriteNumber = 123; //this is a key value store in smart contract?
    //in evm storage!
    //string favouriteNumberInText = "Five";
    //address myAddress = 0x44d70766c9AA13a9A64944d73783Dd60e7be42f7;

    struct People {
        uint256 favoriteNumber;
        string name;
    }
    //slots and memory! related to evm?

    People[] public people;
    mapping(string => uint256) public nameToFavouriteNumber;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    //disallow writing
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //pure does not allow write and read storage.
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People(_favoriteNumber, _name);
        people.push(newPerson);
        nameToFavouriteNumber[_name] = _favoriteNumber;
    }
    //memory calldata(cannot be modify,temporary) storage
}
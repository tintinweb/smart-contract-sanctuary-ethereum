/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// contract - keyword, tell that the next peice of code is a contract
contract SimpleStorage {
    // boolean , uint , int , address, bytes
    uint256 favouriteNumber; // initialised as 0

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    mapping(string => uint256) public nameToFavouriteNumber;

    People[] public people; //made a list People

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber;
    }

    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }
    // view and pure function do not cause any changes to the state of the contract
    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    // deploying a contract means sending a transaction on the blockchain
    // everytime we change the state of the blockchain , we do it in the form of a transaction
}
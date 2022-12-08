/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; // Hi

contract SimpleStorage {
    //add public to not need the retrive function.
    uint favoriteNumber;

    //uint[] public favoriteNumberList;
    People[] public people;

    mapping(string => uint) public nameToFavoritNumber;

    struct People {
        uint favoriteNumber;
        string name;
    }

    // Virtual indicates that child contracts and override this function
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    //Places to store infomation: calldata(temp, non modifiable), memory(temp), storage(permanent)  (log, stack, code)
    function addPerson(uint _favoriteNumber, string memory _name) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoritNumber[_name] = _favoriteNumber;
    }

    //"view" and "pure" does not spend gas
    function retrieve() public view returns (uint) {
        return favoriteNumber;
    }
}
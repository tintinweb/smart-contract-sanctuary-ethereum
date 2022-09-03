/**
 *Submitted for verification at Etherscan.io on 2022-09-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract SimpleStorage {
    //bool hasFavoriteNumber = true;

    //this gets initialized to zero
    uint256 favouriteNumber;
    mapping(string => uint256) public nameToFavouriteNumber;
    struct People {
        uint256 favouriteNumber;
        string name;
    }

    //uint256[] public favouriteNumbersList
    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favouriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        return favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People(_favoriteNumber, _name);
        people.push(newPerson);
        nameToFavouriteNumber[_name] = _favoriteNumber;
    }

    /* string favouriteNumberInText = "Five";
    int256 favouriteInt = -5;
    address myAddress = 0x13A19933267ec307c96f3dE8Ff8A2392C39263EB;
    bytes32 favouriteBytes = "cat";  */
}
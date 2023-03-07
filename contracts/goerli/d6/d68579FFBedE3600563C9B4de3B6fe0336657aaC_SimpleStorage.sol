/**
 *Submitted for verification at Etherscan.io on 2023-03-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7; //comment (this wont be ran in code!!)

contract SimpleStorage {
    //Types: boolean,  uint,  int,  address,  bytes
    // Default of uint = 0
    // No visibility specifier= default internal
    //v type v visibility v vari name
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    // public visibility specifier gives automatic getter function
    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // [] = Array
    //uint256[] public favoriteNumbersList;

    People[] public people;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // view and pure disallow modification of state, no gas used
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata = temporary vari thats not modifiable, memory = temp can be modi , storge = perm can be modi
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}
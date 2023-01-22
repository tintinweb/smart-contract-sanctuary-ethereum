/**
 *Submitted for verification at Etherscan.io on 2023-01-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; // >= 0.8.7 <0.8.12 Tells it that any version between 0.8.7 and less than 0.8.12 is ok, etc

contract SimpleStorage {
    //tells solidity that the next info will be a contract
    // boolean, uint (whole number only positive), int (any whole number +/-), address, bytes, string
    // bool FaveNum = true;
    // uint256 FaveUint = 112358;
    // int256 FaveInt = -112358;
    // string FaveNumInString - "Fib";
    // address myAddress = 0x379F29b768782Ee1b574003dba28ca1Bf4Bf8B25;
    // bytes32 Favebytes = "dog";

    uint256 favoriteNumber; // iniitialized to default = null = 0

    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // uint256[] favoriteNumbersList;
    People[] public people; // dynamic array create array with any size, vs [3] which would hold only 3

    function store(uint256 _favoriteNumber) public virtual {
        // default visibility is internal - public, private, external, internal visibility settings
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns (uint256) {
        // same as a view function so only reads off blockchain - view and pure functions do not
        return favoriteNumber; // require gas if called alone unless called within contract by another function
    }

    // calldata (temp var can't be mod), memory (temp var that can be mod), storage (permanent var can be mod)
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}
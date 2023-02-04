/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; // 0.8.17 - latest?

// ^0.8.7 - any version above 0.8.7
// >=0.8.7 < 0.9.0 - any version between 0.8.7 and less than 0.9.0

contract SimpleStorage {
    // boolean, uint, int, address, bytes
    // bool hasFavoriteNumber = true;
    // uint favoriteNumber = 6; // uint3 represents 3 digits, default if nothing is specified is uint256
    // string favoriteNumberText = "Six";
    // int256 favoriteInt = -6;
    // address myAddress = 0xE359D77541300601E5A0818119D6D953B485BA15;
    // bytes32 favoriteBytes = "cat";

    // uint256 public favoriteNumber; //default value is 0

    // function store(uint256 _favoriteNumber) public{
    //     favoriteNumber = _favoriteNumber;
    // }

    // view, pure function, does not consume gas
    // function retrieve() public view returns(uint256){
    //     return favoriteNumber;
    // }

    mapping(string => string) public firstNameToLastName;

    struct People {
        string firstName;
        string lastName;
    }

    People[] public people;

    function addPerson(
        string memory _firstName,
        string memory _lastName
    ) public virtual {
        // People memory newPerson = People(_firstName, _lastName);
        people.push(People(_firstName, _lastName));
        firstNameToLastName[_firstName] = _lastName;
    }

    function viewPerson(
        uint256 index
    ) public view returns (string memory name) {
        return string.concat(people[index].firstName, people[index].lastName);
    }
}
// 0xd9145CCE52D386f254917e481eB44e9943F39138
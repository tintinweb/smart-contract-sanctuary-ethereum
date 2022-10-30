/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    // EVM = Ethereum virtual machine
    // Types of variable in solidity
    // boolean, uint, int, address, bytes

    // bool hasFavNumber = true;
    // uint8 favNumber = 19;
    // string favNumberinText = "Nine";
    // int256 favNumberInInt = -5;
    
    // bytes32 favBytes = "cat";

    // By deafult unit256 variable initialzed with value zero
    //
    uint256 favoriteNumber;

    mapping(string => uint256) public nameToFavoriteNumber;

    People[] public people;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    People public person = People({favoriteNumber: 5, name: "Sharib"});

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    // View and pure function disallow modification into blockain block. So it doesn't cost any GAS price
    function retrive() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata = Temp varaible can't be modify
    // memory = Temp variable can be modify
    // Storage = parament variable can be modify
    // Struct, arrays and mapping given memory and calldata as avairble
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        // People memory newPerson = People({favoriteNumber:_favoriteNumber, name:_name});
        // people.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}
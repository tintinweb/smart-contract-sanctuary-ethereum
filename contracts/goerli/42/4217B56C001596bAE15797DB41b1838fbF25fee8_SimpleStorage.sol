/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7; //0.8.12 is the new version

//pragma solidity ^0.8.7 // any version greater than 0.8.7
//pragma solidity >=0.8.7 <0.9.0 // any version between the range will work

contract SimpleStorage {
    // keyword in solidity to define contract
    // boolean, unit, int, address, bytes, string are the basic data types available in solidity

    // bool hasFavNumber = false;
    // uint256 favNumber = 123; // default to unit256 lowest is 8 bits upto 256 (uint8)
    // string favNumberText = "Five";
    // int favNumberInt = -5;
    // address myAddess = 0x65550690fddd0dCa373F3B3fc41B051Cf26F392B;
    // bytes favBytes = "cat";

    //0xd9145CCE52D386f254917e481eB44e9943F39138

    // Visibity Specifiers
    // Public - visible externally and internally (creates a getter function)
    // Private - only the contract can read this
    // external - only visible externally
    // internal - only visible internally (only the contarct and children contract)

    uint256 favNumber; //default value is 0

    //STRUCT - derived datatype
    struct People {
        uint256 favNumber;
        string name;
    }

    //MAPPING

    mapping(string => uint256) public nameToFavNumber;

    //Array - to store sequence of object

    People[] public people;

    People person = People({favNumber: 5, name: "Lal"});

    function store(uint256 _favoriteNumber) public virtual {
        // computation can increase the gas amount
        favNumber = _favoriteNumber;
    }

    // view, pure function just read state from contract and it does not required gas, also disallow modofication
    // calling a view/pure function can cost gas if we try to call it from a function that cost gas.
    function getFavNumber() public view returns (uint256) {
        return favNumber;
    }

    // calldata, memory and storage
    // Calldata and memory - varaibale only exist temporarly, calldata variables cannot be updated inside the function where as the memory variable can be updated
    // storage variable - exist even outside the fuction executing
    // arrays,mapping and struct requres memory identifier when adding them to a fucntion parameter
    function addPerson(string memory _name, uint256 _favNumber) public {
        people.push(People(_favNumber, _name));
        nameToFavNumber[_name] = _favNumber;
    }
}
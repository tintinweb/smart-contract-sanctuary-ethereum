/**
 *Submitted for verification at Etherscan.io on 2022-07-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; //any version above this will work

contract SimpleStorage {
    // DATA TYPES: boolean, uint, int, address, bytes, string
    // bool myBool = true;
    // uint256 myUint = 123; //Lowest 8 => 16, 32, 48, Max 256
    // string myString = "JOY";
    // int256 myInt = -123;
    // address myAddress = 0x7Cd107085Fc2de05ea97608B33C329f45f0ad285;
    // bytes32 myBytes = "Cat"; //Max 32

    uint256 favNumber; //Gets initialized to 0 if not initialized
    // People public people = People({favNumber: 2, name: "Joy"});

    mapping(string => uint256) public nameToFavNumber;

    struct People {
        uint256 favNumber;
        string name;
    }

    People[] public people;

    function store(uint256 _favNumber) public virtual {
        favNumber = _favNumber;
    }

    // view, pure => No Gas
    // calling view, pure functions inside gas calling functions would cost gas
    function retrieve() public view returns (uint256) {
        return favNumber;
    }

    //calldata -> temp variables & can't be modified
    //memory -> temp variables & can be modified
    //storage -> permanent variables & can be modified
    function addPerson(string memory _name, uint256 _favNumber) public {
        // People memory newPerson = People({favNumber: _favNumber, name: _name});
        // People memory newPerson = People(_favNumber, _name);

        people.push(People(_favNumber, _name));
        nameToFavNumber[_name] = _favNumber;
    }
}
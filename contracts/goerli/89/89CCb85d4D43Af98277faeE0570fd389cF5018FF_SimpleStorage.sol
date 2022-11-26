// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {

    // solidity primitive types are int, uint, boolean, byte, address
    uint256 favNumber;
    // array with People objects
    People[] public people;
    //uint256[] public favNumbersList;
    // People public person1 = People({favNumber: 0, name: "Me"});

    mapping(string => uint256) public nameToFavNumber; //usage like dictionary
    
    struct People {
        uint256 favNumber;
        string name;
    }

    // store number into the contract
    function store(uint256 _favoriteNumber) public virtual returns(uint256) {
        favNumber = _favoriteNumber;
        return favNumber;
    }

    // read favNumber from the smart contract
    function retrieve() public view returns(uint256) {
        return favNumber;
    }

    // add person to the array people
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        //nameToFavNumber[_name] = _favoriteNumber;

        // alternative 1
        people.push(People(_favoriteNumber, _name));

        // alternative 2
        //People memory newPerson = People({favNumber: _favoriteNumber, name: _name});
        //people.push(newPerson);
    }
}
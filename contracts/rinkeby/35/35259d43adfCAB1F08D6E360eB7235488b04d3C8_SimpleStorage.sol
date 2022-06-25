/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7; // stable version of solidity

// EVM, Ethereum Virtual Machine
//  compatible Avalanche, Fantom, Polygon

contract SimpleStorage {
    // boolean (true/false), uint (positive numbers) , int (integers), address, bytes, - provide different variables
    // bool hasFavouriteNumber = true;
    // uint256 favouriteNumber = 5;
    // string favouriteNumberInText = "Five";
    // int256 favouriteInt = -5; // 256 is the storage u want it to be in.
    // Smallest is 8 (8 bit is a byte) and the next will be multiples of 8
    // address myAddress = 0x1066618d0973e44EfD2Fe5114fD18b64c6420AbB;
    // bytes32 favouriteBytes = "cat"; bytes max is 32
    // can refer to solidity documentation to learn more!

    uint256 favouriteNumber; //no number is default to 0, default visibility is internal

    // Mapping
    mapping(string => uint256) public nameToFavouriteNumber;
    // enter the key ===> spits out the value
    //mapping is like a dictionary/tagged the name the number for this case
    //by default, the result will be 0 during deploy, need to add in the data before use.

    struct People {
        uint256 favouriteNumber;
        string name;
    }

    // [] - array (making a list), adding a value in will max it to the value, by default there is no max cap.
    People[] public people;

    // store
    function store(uint256 _favouriteNumber) public virtual {
        favouriteNumber = _favouriteNumber;
    }

    // view. pure...retrieve
    function retrieve() public view returns (uint256) {
        return favouriteNumber;
        // view, pure functions appear as blue as they don't need gas as it seems as it is just reading the value
        // retrieve (get the info)...returns (give/show us the value)
    }

    // calldata, memory, storage
    function Name(string memory _name, uint256 _favouriteNumber) public {
        people.push(People(_favouriteNumber, _name));
        nameToFavouriteNumber[_name] = _favouriteNumber; //link the name to the number for mapping to occur successfully.
        //push (add) people (names) into the People group
        //People memory newPerson = People({_favouriteNumber, _name}); - same code, not so specific.
        //People memory newPerson = People({favouriteNumber: _favouriteNumber, name: _name}); - most specific
        //memory - data stored temporarily that can be changed
        //calldata - same as memory but it CAN'T be changed
        //storage - store permanently
    }
}
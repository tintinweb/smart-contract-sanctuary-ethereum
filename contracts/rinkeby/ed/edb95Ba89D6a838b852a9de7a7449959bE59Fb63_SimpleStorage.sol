//optional but some compilers will flag a warning
//SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

// ^0.8.7 means ok with newer versions from 0.8.7 upwards
// alternative for specifying specific range of versions: >=0.8.7 < 0.9.0
// each line needs to end with semi-colon

contract SimpleStorage {
    // boolean, uint, int, address, bytes
    // bool hasFavoriteNumber = true;
    uint256 public favoriteNumber; // if not specified, defaults to uint256
    // if unitialised will be set to default value
    // default value is whatever the null value is for the type, which is 0 for unint256
    // default visibility is internal - only visible to this contract or derived contracts
    // when a variable is public, a getter function is created implicitly for it

    // string favoriteNumberInText = "Five"; // strings are implemented as bytes obejcts only for text
    // int256 fovoriteInt = -5;
    // address myAddress = 0x1066618d;
    // bytes32 favoriteBytes = "cat" //cat is actually a string but can be automatically converted into a byte object
    // // bytes32 is the maximum size bytes can be
    // //smallest for uint and int is uint8 and int8

    // People public person = People({favoriteNumber: 2, name: "Patrick"});

    // A mapping is a data structure where a key is "mapped" to a single value
    mapping(string => uint256) public nameToFavoriteNumber;
    // when a mapping is initialised, every possible string key is initially mapped to the null value (of 0 in this case)

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    // uint256[] public favoriteNumbersList;
    People[] public people;

    // the number in the square brackets is to fix the size of the array
    // if left empty, a dynamic array is created

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        // uint256 testVar = 5;
    }

    // this fuction doesn't know about testVar
    // function something() public {
    //     testVar = 6;
    // }

    // view, pure functions just read state from the contract and does not spend gas
    // we only make a transaction and spend gas if we modify the blockchain state
    // calling view functions is free unless you are calling it from a function which costs gas
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        // People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
        // people.push(newPerson);
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }

    //EVM can access and store information in Stack, Memory, Storage, Calldata, Code and Logs
    // calldata and memory mean the variable is only going to exist temporarily in the function being executed while storage variables exist outside of the function
    // calldata - temporary variables that can't be modified
    // memory – temporary variables that can be modified
    // storage – permanent variables that can be modified

    // Data location can only be specified for array, struct or mapping types
    // a string is an array of bytes
}
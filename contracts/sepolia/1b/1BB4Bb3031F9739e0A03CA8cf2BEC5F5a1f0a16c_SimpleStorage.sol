//SPDX-License-Identifier: MIT 
    //MIT license is often used 

    //EVM: Ethereum virtual machine
    //avalanche, fantom, polygon

// tell the compiler which version of sol it will use
pragma solidity ^0.8.18;// 0.8.18 or up
    //pragma solidity >=0.8.7 <0.9.0; greater or equal to 0.8.7, and less than 0.9.0

contract SimpleStorage {

    // types in sol:
        // basic types: boolean, uint, int, address, bytes
        // bool hasFavoriteNumber = false;
        //    string favNumInText = "Five";

        //     int256 favNumInt= -5;

        //     address myAddress = 0x061986D4b1a49e4470d564c7f6dA89DffE3c8384;

        //     bytes32 faveBytes = "cat";  //byte 32 is the max size a byte can get to 

    uint256 public favNumber;//default is 0

    // people struct object
    People public person = People({favNumber: 7, name: "Jerry"});

    // people struct
    struct People{
        uint256 favNumber;
        string name;
    }

    mapping(string => uint256) public nameToFavNumber;

    // dynamic array without specifying the size in [num]
    People[] public peopleArray;

    function store(uint256 _favNumber) public virtual {
        favNumber = _favNumber;
        retrieve();
    }

    //view, calling retrieve is free unless its called in another function
    function retrieve() public view returns(uint256){
        return favNumber;
    }
 
    //calldata, memory, storage
    //calldata and memory means they are there temporarily during the transaction when the function is called, storage(can be modfied) means the variable will presist after the function
    //difference between calldata and memory: calldata can not be reassigned/changed, memory can be modified
    // we have to tell sol the data location of arrays, structs and mappings, and a string is an array of bytes
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory temp = People({favNumber: _favoriteNumber, name: _name});
        peopleArray.push(temp);
        nameToFavNumber[_name] = _favoriteNumber;
    }
}
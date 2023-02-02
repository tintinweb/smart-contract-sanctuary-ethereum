// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleStorage {
    // bool, uint, int, address, bytes, string

    /*
     public private external internal
     public - auto generated getter function
     internal - default
    */

    /* 
    Functions: 
        View: A function that only reads from Blockchain
        Pure: A function that neither reads or writes to Blockchain. Pure funtions like in JS.

        View and Pure functions don't cost any gas. They only cost gas 
        when are called in other functions.

        Syntax: 
        function functionName(pType pName, ...params) scope-modifier view/pure returns(return-type) {
            function-body
        }
    */

    /*
        Structs: 
            struct People {
                uint favoriteNumber;
                string name;
            }

            People p1 = People({favoriteNumber: 123, name: "Ali"});
            People p1 = People(123, "Ahmad");

        Arrays: 
            People[] public peopleList; dynamic-size
            People[3] public peopleList; fixed size

        Memory, Storage, Calldata
            memory and calldata is for variables of a function that live only during the execution

            memory variables are modifiable in function body
            calldata variables are not modifiable in function body

            Storage that lives in the contract

            Only Arrays, Structs and Mapping types need data location specifier. 
            String is also a hidden array.


    */

    struct Person {
        uint256 number;
        string name;
    }

    uint256 public number;

    Person[] public personsArray;
    mapping(string => uint256) public nameToNumber;

    function setNumber(uint256 _number) public virtual {
        number = _number;
    }

    function getStoredNumber() public view returns (uint256) {
        return number;
    }

    function addPerson(uint256 _number, string calldata _name) public {
        // Person newPerson = Person({favoriteNumber: _number, name: _name});
        // personsArray.push(newPerson);
        personsArray.push(Person(_number, _name));
        nameToNumber[_name] = _number;
    }
}
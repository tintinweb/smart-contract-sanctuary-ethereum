// How to write versions in solidity
// To include the specific version: pragma solidity 0.8.7;
// To include all version above and including a specific version: pragma solidity ^0.8.7;
// To include versions in a range: pragma solidity >=0.8.7 <0.9.0;

//end every line with a semicolon
//including license is also important

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {

    //<------------------------ Primitive types or value types ---------------------->
    //basic primitive types in solidity are: boolean, uint, int, address, bytes
    // bool hasFavNum = true;
    // string favNumInText = "five";
    // int256 favNumber = -5;
    // address myAddress = 0x065b3575Ce5D0ae7eA00668ee61230992D1B21b2;
    // bytes32 myFavByte = "cat"; 
    uint256 favouriteNumber;  //if we dont asign any value the default value is set to 0 ie null value in solidity
    
    //<------------------------ visibility --------------------------------->
    // also we can set the visibility of a variable or a function
    // public: visible externally and internally (creates a getter function for storage/state variables)
    // private: only visible in the current contract
    // external: only visible externally (only for functions) - i.e. can only be message-called (via this.func)
    // internal: only visible internally
    
    //<------------------- reference types -------------------------------------->

    //  <------------------------- struct --------------------------------------->
    // declaring the struct type object
    //People public person = People({favNumber: 3, name: "khushi"});    
    struct People {
        uint256 favNumber;
        string name;
    }
    //<-------------------------------- Arrays ------------------------------------->
    //is best practice to initialize an array to store multiple objects of same type
    // type[] visiblity name;
    // uint256[] public favNumberList;
    People[] public people; // this is a dynamic array becoz the size is not mentioned while declaring it
    //we can mention the size inside the square brackets [7] it means its size is 7

    // <------------------------- mappings -------------------------------------------->
     
     mapping(string => uint256) public nameTofavNumber;



    //<--------------------------- functions --------------------------------------->

    //we can define functions in solidity using keyword function

    function store(uint256 _favouriteNumber ) public virtual{
        favouriteNumber = _favouriteNumber;
    }

    //there are two keywords view, pure
    //view functions are only used for reading neither for any modification thus causes no gas fees
    //pure function can neither read nor modification of any state
    //view function is free unless we call it from any another function that results in change of stste 
    
    function retrieve() public view returns(uint256){
        return favouriteNumber;
    }

    function addPerson(string memory _name, uint256 _favouriteNumber) public {
        // there are multiple ways to add the person

        //method 1 
        //People memory newPerson = People({favNumber: _favouriteNumber, name: _name});
        //people.push(newPerson);

        //method 2
        //People memory newPerson = People(_favouriteNumber, _name);
        //people.push(newPerson);

        //method 3
        people.push(People(_favouriteNumber, _name));

        //adding mapping functionality
        nameTofavNumber[_name] = _favouriteNumber;
    }

}
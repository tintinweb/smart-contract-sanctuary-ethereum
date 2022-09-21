/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; // 0.8.17 is the newest

contract SimpleStorage {
    //boolean, uint, int, adresse, bytes
    //bool hasFavoriteNumber = true;
    //string favoriteNumberInText = "Five"; 
    //int256 favoriteInt = -5;
    //address myAddress = 0x06d7a70c9b7771826Fd3FdaFb15bc627fA523c08;
    //bytes32 favoriteBytes = "dog";

    // Default nr is zero
    uint256 favoriteNumber;

    //Mapping is a data structure where a key is "mapped" to a single value
    // sting => uint256 means that the sting/word is mapped to a uint256/nr
    mapping(string => uint256) public nameToFavoriteNumber;

    mapping(uint256 => string) public numberToName;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    //"[]" This means we want a array of people. An array is a data sytucture that holds a list of other types. If we say[3], then there can only be 3 on the list, withnothing i it, it can be any size
    People[] public people;
    //uint256[] public favoriteNumberList; 

    function store(uint256 _favoriteNumber) public {
            favoriteNumber = _favoriteNumber;
    }

    //view and pure functions, when called alone, don't spend gas
    function retrive() public view returns(uint256) {
        return favoriteNumber;
    }

    //calldata = short-term and can't be edited
    //Memory = short-term that can be changed
    //storage forever, used for more than just one function. Sinse it is not used anywhere else it dosen't work here
    // String is array and arrays in a function needs somewhere to be reffered to
    function addPerson(string memory _name, uint256 _favoriteNumber) public  {
        people.push(People(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
        numberToName[_favoriteNumber] = _name;
    }

}
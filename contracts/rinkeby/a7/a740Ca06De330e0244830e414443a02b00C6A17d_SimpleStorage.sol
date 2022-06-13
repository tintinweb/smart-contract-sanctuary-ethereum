// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

//EVM, ethereum virtual machine
// avalanche, fantom, polygon

contract SimpleStorage{
    //Boolean,uint,int,address,bytes
    //bool hasfavoriteNumber = true;
    //uint256 favoriteNumber = 123;
    //string favoriteNumberInText = "Five";
    //int256 favoriteInt = -5;
    //address myAddress =0xa4a4a86f509Bfc51591846339F034F1726A0a7a9;
    //bytes32 favoriteBytes = "cats";


    //this get initialized to zero
    uint256 public favoriteNumber;
    //People public person = People({favoriteNumber:2 , name:"shweta"});
    
    mapping(string => uint256) public nameToFavoriteNumber;

    struct People{
        uint256 favoriteNumber;
        string name;
    }

    //uint256 public favoriteNumberList;
    People[] public people;
    
   // add virtual to enable overriding
    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        retrieve();
    }
    
    //view, pure
    function retrieve() public view returns(uint256){
        return favoriteNumber; 
    }
    

    //calldat,memory,storage
    function addPerson(string memory _name, uint256 _favoriteNumber) public{
        //People memory newPerson = People({favoriteNumber: _favoriteNumber, name: _name});
       // _name = "cat";
        people.push(People(_favoriteNumber,_name));
        nameToFavoriteNumber[_name]= _favoriteNumber;
    }

    //0xd9145CCE52D386f254917e481eB44e9943F39138
}
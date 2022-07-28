/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


/*==== FIRST LINE OF SOLIDITY =======*/
// First of all set your solidity version
// pragma solidity 0.8.7;
// Alternatively you can set a solidity version range
// pragma solidity ^0.8.7;
// or
// pragma solidity >=0.8.7 <0.9.0;
/* ☀️ Always end with a semicolon*/

// ==========================================

/*======= WRITING YOUR FIRST CONTRACT =========*/
contract SimpleStorage{
    //Data types in solidity includes ;
    //unit unregistered int
   /* uint256 favouriteNumber = 2;
    //int
    int256 favouriteNumber = -2;
    //bool
    bool isFavouriteNumber = true;
    //string
    string name = "promise"
    //address
    address myAddresss = 0x499E35400FF56704dFeE252B8885F8A2f529Eb40
    //bytes32
    bytes32	someString = "cat 
    */
    //initalizing the People object in a Person variable
    // People public Person = People({favouriteNumber:14,name:"Promise"});

    //struct
    struct People{
        uint favouriteNumber;
        string name;
    }

    //mappings
    mapping(string => uint256) public nameToFavoriteNumber;
    //Arrays 
    People[] public people;
    // functions
    uint256 public favouriteNumber;
    function store(uint256 _favouriteNumber)public virtual{
        favouriteNumber = _favouriteNumber;
    }

    function retrieve() public view returns(uint256){
        return favouriteNumber;
    }
    
    // storage units in solidity are >>7
    //calldata,memory,storage
    function addPerson(string memory _name, uint256 _favouriteNumber) public{
        people.push(People(_favouriteNumber,_name));
        nameToFavoriteNumber[_name] = _favouriteNumber;
    }
}
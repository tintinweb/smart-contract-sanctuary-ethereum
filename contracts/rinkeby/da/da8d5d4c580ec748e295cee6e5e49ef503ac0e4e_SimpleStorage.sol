/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8; //^0.8.7 any version of 0.8.7 and above, is ok for this contract.  >=0.8.7 <0.9.0 --> define range

contract SimpleStorage {
    bool hasFavoriteNumber = true;    
    string favoriteNumberInText = "Five";
    int256 favoriteInt = -5;
    address myAddress = 0xc18E47173A1e0C2E52F67e59788132045B5F6943;
    bytes32 favoriteBytes = "cat";  
    // uint256 public favoriteNumber;

    uint256 favoriteNumber; // this gets initialized to 0
    // People public person = People ({favoriteNumber: 2, name: "Petros"});
    
    mapping (string => uint256) public nameToFavoriteNumber;
    
    struct People {
        uint256 favoriteNumber;
        string name;
    }
 
    People[] public people;
    
    function store (uint256 _favoriteNumber) public {
        favoriteNumber = _favoriteNumber;         
    }
    function retrieve () public view returns (uint256){
        return favoriteNumber;
    }

    //calldata (temp variables that can't be modified), memory (temp variable that can be modified), storage (permanent variables that can be modified)
    function addPerson (string memory _name, uint256 _favoriteNumber) public{
        people.push (People (_favoriteNumber,_name));
        nameToFavoriteNumber[_name] = _favoriteNumber;
    }
}

// 0xd9145CCE52D386f254917e481eB44e9943F39138
/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 favNum;

    function store(uint256 _favNum) public{
        favNum = _favNum;
        favNum += 1;
        
    }

    function retrieve() public view returns(uint256){
        return favNum;
    }


    mapping(string => uint256) public nameToFavNumMap;


    struct People {
        uint256 favNum;
        string name;
    }
    People[] public peoplevar;
    
    
    function addArray(string memory _name, uint256 _favNum) public{
        peoplevar.push(People(_favNum,_name));
        nameToFavNumMap[_name] = _favNum; 
    }

}
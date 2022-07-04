/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

// I'm a comment!
// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

// pragma solidity ^0.8.0;
// pragma solidity >=0.8.0 <0.9.0;

contract Mycats {
    struct Cat {
        string name;
        uint256 age;
    }
    // uint256[] public anArray;
    Cat[] public cat;

    mapping(string => uint256) public nameToage;

    // function store(uint256 _age) public {
    //     age = _age;
    // }

    // function retrieve() public view returns (uint256) {
    //     return age;
    // }
    
    function addCat(string memory _name, uint256 _age) public {
        cat.push(Cat(_name, _age));
        nameToage[_name] = _age;
    }

    function retrieve(string memory _name) public view returns (uint256) {
        return nameToage[_name];
    }
  
    
}
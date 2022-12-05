/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; // working on this version for now as we see in video

contract SimpleStorage {
    // bool a = false;
    // uint256 b = 1323;
    // int c = 12;
    // bytes32 = 8;

    uint256 public nullnumber;

    function store(uint256 givenumber) public {
        nullnumber = givenumber;
    }

    function retrieve() public view returns (uint256) {
        return nullnumber;
    }

    struct People {
        uint256 number;
        string name;
    }

    // People public person = People({number : 2, name : "Aditya"});
    People[] public people;

    function addPerson(string memory _name, uint256 _number) public {
        people.push(People(_number, _name));
        //we can use memory,callback,storage to store the variable of array,strings,mappings
        // generally callback and memory is used to store the variable temorarily whereas storage stores it permanently
        // callback can't be changed but storage and memory does;
        maps[_name] = _number;
    }

    //basic solidity mappings
    mapping(string => uint256) public maps;

    //0x7EF2e0048f5bAeDe046f6BF797943daF4ED8CB47
}
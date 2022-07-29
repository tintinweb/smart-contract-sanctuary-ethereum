// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


/**
*@title  Storage Contract.
*@author ABossOfMyself.
*@notice A basic Storage Contract.
 */


contract Storage {

    uint256 favNo;

    mapping(string => uint256) public myFavNo;

    struct people {
        uint256 favNo;
        string name;
    }

    people[] public data;

    function peopleData(uint256 _favNo, string memory _name) public {
        data.push(people(_favNo, _name));
        myFavNo[_name] = _favNo;
    }

    function store(uint256 _favNo) public {
        favNo = _favNo;
    }

    function retreive() public view returns(uint256) {
        return favNo;
    }
}
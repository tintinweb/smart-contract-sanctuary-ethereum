/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract simplestorage {
    uint256 public favint;
    mapping(string => uint256) public nametonum;

    struct people {
        uint256 favnum;
        string name;
    }
    people[] public peop;

    function store(uint _favint) public virtual {
        favint = _favint;
    }

    function retrive() public view returns (uint) {
        return favint;
    }

    function addperson(string memory _name, uint256 _favnum) public {
        peop.push(people(_favnum, _name));
        nametonum[_name] = _favnum;
    }
}
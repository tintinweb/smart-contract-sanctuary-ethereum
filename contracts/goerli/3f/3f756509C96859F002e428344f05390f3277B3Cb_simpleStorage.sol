//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract simpleStorage{
    uint num;
    // uint favoriteNum;
    mapping(string=>uint256) public dictionary;

    struct People{
        uint256 favoriteNum;
        string name;
    }
    People[] public people;

    function store(uint _second)public virtual{
        num = _second;
    }

    function retrive() public view returns(uint256){
        return num;
    }
    // memory is temerory variable which can be modified. callback cannot be modified and is also temerory.
    // storage is permenant storage. by default storage is assigned to any varible.
    function addPerson(string memory P_name, uint256 P_favNum)public{
        people.push(People(P_favNum, P_name));
        dictionary[P_name] = P_favNum;
    }
    
    // Address of the deployed contract: 0xfdceb2df4eca420070c4b1343c2e4d3c16a3e7ba
}
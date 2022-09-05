// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

contract Storedata {
    //initilized to zero if noting assined
    uint256 number;

    mapping(string => uint256) public nameTonumber; //for  evry name there is a number

    function store(uint256 _number) public {
        number = _number;
    }

    struct People {
        uint256 number;
        string name;
    }
    People[] public people;

    //read state of the contract
    //view,pure  can not update,not use any gas to read
    function retrieve() public view returns (uint256) {
        return number;
    }

    //call data not modify
    //memory temperary
    //storage permenent storage
    function addPeople(string memory _name, uint256 _number) public {
        people.push(People(_number, _name)); //donot change the structure , push to add in array
        nameTonumber[_name] = _number;
    }
}
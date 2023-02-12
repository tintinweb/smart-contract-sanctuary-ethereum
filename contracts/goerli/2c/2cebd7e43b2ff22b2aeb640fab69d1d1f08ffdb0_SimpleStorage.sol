/**
 *Submitted for verification at Etherscan.io on 2023-02-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;//version 8.8 and obove
// >=0.8.7 <0.9.0
contract SimpleStorage{
    //basic data type: boolean, int, uint, address, bytes
    bool hasLover = true;
    uint256 public loverAge = 23;// the min is uint8 and default is uint256
    int256 babyAge;//initialized to 0
    string loverName = "Luoting";//string is in fact a type of bytes which limited to characters
    address myAccount = 0xf711187C56c4455fb9Ae508c6f9c4B23D9e2C0a7;
    bytes32 myName = "xiaohaha";//the max is 32 and the min is 8

    function setLoverAge(uint256 year) public{
        loverAge = year - 2000;
    }
    function returnLoverAge()public view returns(uint256){
        return loverAge;
    }
    function sayHello()public pure returns(uint){
        return  2013;
    }

    struct Person{
        string name;
        uint256 age;
    }
    Person[] public people;//dynamic array
    function addPerson(string calldata _name,uint256 _age) public{
        Person memory newPerson = Person({name:_name,age:_age});
        people.push(newPerson);
        //people.push(Person(_name,_age));

        name2Age[_name] = _age;
    }
    mapping(string => uint256) public name2Age;
}
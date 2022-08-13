//SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

contract Identity {

    struct Person{
        bytes32 identity;
        bytes32 name;
        bytes32 lastName;
        bytes32 age;
        bool adult;
    }

    mapping(address => Person) public person;

    function createId(string memory _name, string memory _lastName, uint256 _age) public{
        Person storage personStruct = person[msg.sender]; 
        require(personStruct.identity == 0x0000000000000000000000000000000000000000000000000000000000000000, "Person already created");
        personStruct.identity = keccak256(abi.encodePacked(_name,_lastName,_age));
        personStruct.name = keccak256(abi.encodePacked(_name));
        personStruct.lastName = keccak256(abi.encodePacked(_lastName));
        personStruct.age = keccak256(abi.encodePacked(_age));
        if(_age > 18){
            personStruct.adult = true;
        }
    }

    function readId(address _address) public view returns(bytes32){
       Person storage personStruct = person[_address]; 
       return personStruct.identity;
    }

    function readName(address _address) public view returns(bytes32){
        Person storage personStruct = person[_address];
            return personStruct.name; 
    }

    function readLastName(address _address) public view returns(bytes32){
        Person storage personStruct = person[_address];
            return personStruct.lastName; 
    }    

    function readAge(address _address)public view returns(bytes32){
        Person storage personStruct = person[_address];
        return personStruct.age;
    }

    function readAdult(address _address) public view returns(bool){
       Person storage personStruct = person[_address];
       return personStruct.adult;
    }
}
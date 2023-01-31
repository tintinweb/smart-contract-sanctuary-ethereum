//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


contract SimpleStorage {
    
    struct Person {
        string name;
        uint favNum;
    }

    Person[] people;

    function storePerson(string memory _name, uint _favNum) public {
        people.push(Person(_name, _favNum));
    }

    function retrievePersonByName(string memory _name) public view returns(uint _favNum) {
        for(uint i = 0; i < people.length; i++) {   
            if(keccak256(abi.encodePacked(_name)) == keccak256(abi.encodePacked(people[i].name))) {  
                return people[i].favNum;
            } 
        }
    }
}
// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.3;
contract Viewer {

    string private name; 
    uint private age; 

    constructor(string memory _name, uint _age) {
        name = _name; 
        age = _age; 
    }

    function getName() view public returns(string memory) {
        return name; 
    }

    function getAge() view public returns(uint) { 
        return age; 
    }

    function ageUp() public {
        age += 1; 
    }

}
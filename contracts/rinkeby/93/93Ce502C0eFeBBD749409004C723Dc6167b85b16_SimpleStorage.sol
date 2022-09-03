// I'm a comment!
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
// pragma solidity ^0.8.0;

contract SimpleStorage {

    uint256 age;

    struct People {
        uint256 age;
        string name;
    }
    // uint256[] public anArray;
    People[] public people;

    mapping(string => uint256) public nameToAge;

    function store(uint256 _age) public virtual {
        age = _age;
    }
    
    function retrieve() public view returns (uint256){
        return age;
    }

    function addPerson(string memory _name, uint256 _age) public {
        people.push(People(_age, _name));
        nameToAge[_name] = _age;
    }
}
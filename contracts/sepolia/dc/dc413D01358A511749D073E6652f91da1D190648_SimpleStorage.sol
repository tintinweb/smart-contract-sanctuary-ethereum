//SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    uint256 public someNumber; //this sets someNumber val to null, in this case zero
    mapping(string => uint256) public nameToNumber;

    struct People {
        uint256 someNumber;
        string name;
    }

    //another possible syntax is: uint256[] public numbers
    People[] public people;

    function store(uint256 _someNumber) public virtual {
        //the virtual keyword makes it overridable
        someNumber = _someNumber;
    }

    function retrieve() public view returns (uint256) {
        return someNumber;
    }

    //calldata are temporary vars that cant be modified
    //memory are temp vars that can be modified
    //storage are perm vars that can be modified
    function addPerson(string memory _name, uint256 _someNumber) public {
        people.push(People(_someNumber, _name));
        nameToNumber[_name] = _someNumber;
    }
}
//uint automatically gets sent to memory
//string is an array of bytes and needs memory defined

//0xd9145CCE52D386f254917e481eB44e9943F39138
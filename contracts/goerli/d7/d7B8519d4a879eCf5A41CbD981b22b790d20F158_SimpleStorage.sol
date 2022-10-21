// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SimpleStorage {
    uint256 number;
    People[] public people;

    struct People {
        uint256 _number;
        string _name;
    }
    mapping(string => uint256) public nameTonum;

    //People public person1 = People({_number: 1, _name:"meri"});

    function store(uint256 _number) public virtual {
        number = _number;
        retrieve();
    }

    function retrieve() public view returns (uint256) {
        return number;
    }

    /*
        - calldata : temp that can't be modified
        - memory: temp that can be mdified 
        so obviusly in func parametes we can only use these 2 types above
        - storage: permenet variable
        Data location only can be speccefoed in Arrays, struct ,mapping 
    */

    function add_person(uint256 _num, string memory _name) public {
        /* 
        //People memory newperson = People({_number: _num, _name:_name});
        People memory newperson = People(_num, _name);
        people.push(newperson);
        /*/
        people.push(People(_num, _name));
        nameTonum[_name] = _num;
    }
}
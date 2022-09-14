//SPDX-License-Identifier:MIT

pragma solidity ^0.8.9;

contract SimpleStorage{
    uint favnum;

    struct People{
        uint favnum;
        string name;
    }

    People[] public people;

    mapping(string => uint) public nametonum;

    function store(uint _favnum ) public {
        favnum = _favnum;
    }

    function retrieve() public view returns(uint){
        return favnum;
    }

    function addperson(uint _favnum , string memory _name) public{
        people.push(People(_favnum , _name));
        nametonum[_name]=_favnum;
    }
}
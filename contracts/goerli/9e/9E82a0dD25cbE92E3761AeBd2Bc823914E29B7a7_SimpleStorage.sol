// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage{
    //datatypes:boolean,uint,int,string,address,bytes

    uint256 number;

    struct People{
        string name;
        uint256 favouritenumber;
    }
    People[] public person;

    mapping(string => uint256) public nametofavouritenumber;
    function store(uint256 _number) public virtual {
        number=_number;
    }
    function retrieve() public view returns(uint256){
        return number;
    }

    function addperson(string memory newname,uint256 _favouritenumber) public{
        person.push(People(newname,_favouritenumber));
        nametofavouritenumber[newname]=_favouritenumber;
    } 
}
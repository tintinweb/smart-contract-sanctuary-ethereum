/**
 *Submitted for verification at Etherscan.io on 2022-09-18
*/

//SPDX-Licensen-Identifier:MIT

pragma solidity ^0.8.7;

contract Simplestr{

    uint256 public favnum;

    struct People{
        uint256 favnum;
        string name;
    }

    People[] public people;
    
    mapping(string => uint256) public namepubmapping;

    function store(uint256 _favnum) public virtual{
        favnum=_favnum;
    }

    function getfav() public view returns(uint256){
        return favnum;
    }

    function addperson(string memory _name ,uint256 _favnum)public{
        people.push(People(_favnum,_name));
        namepubmapping[_name]=_favnum;
    }
}
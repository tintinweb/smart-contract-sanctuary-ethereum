// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Storage{
    mapping(string=>uint256) Search;
    struct People{
        string name;
        uint256 number;
    }
    People[] public allpeople;
    uint256 public favnum;
    function Addpeople(string memory _name,uint256 _number) public{
        People memory newperson = People(_name,_number);
        allpeople.push(newperson);
        Search[_name] = _number;
    }
    function showNumber(uint256 _number) public virtual{
        favnum = _number;
    }
    function showfavourite() public view returns(uint256){
        return favnum;
    }
}
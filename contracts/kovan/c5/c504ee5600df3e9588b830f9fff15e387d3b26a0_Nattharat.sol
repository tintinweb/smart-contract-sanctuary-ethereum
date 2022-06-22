/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Nattharat{
    string public name;
function setname(string memory newname) public{
    name = newname;
}
string public lastname;
function setlastname(string memory newlastname) public{
    lastname = newlastname;
}
string[] public info;
function setinfo(string[] memory newinfo) public{
    info = newinfo;
}

uint256[] public buasri;
constructor(uint256[] memory ID) public{
    buasri = ID;
}
    uint256 A ;
    uint256 B ;
    uint256 C ;
    uint256 D ;
    uint256 E ;
function setnum(uint256 newA,uint newB,uint newC,uint newD,uint newE) public{
    A = newA;
    B = newB;
    C = newC;
    D = newD;
    E = newE;
}

function getnum() public view returns(uint256){
return A+B+C+D+E;
}


}
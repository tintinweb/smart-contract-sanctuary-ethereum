/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract asses {

struct Asses {
    uint256 PoundsOfJunk;
    string ShapeOfAss;
    }

Asses [] public butts;
mapping(string => uint256) public AssTypeToPoundsOfJunk;

function AddAss(string memory _ShapeOfAss, uint256 _PoundsOfJunk) public{
    butts.push(Asses({PoundsOfJunk: _PoundsOfJunk, ShapeOfAss: _ShapeOfAss}));
    AssTypeToPoundsOfJunk[_ShapeOfAss] = _PoundsOfJunk;
}

}
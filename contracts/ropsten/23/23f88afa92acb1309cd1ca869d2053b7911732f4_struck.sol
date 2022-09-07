/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.8.7;

contract struck {
   uint32 keyNum = 0;
    struct jsontype {
        string name;
        uint32 num;
    
    }
    mapping(uint256 => jsontype) jsontypes;

    function setJsontype(string memory _name, uint32 _num) public {
         
        jsontypes[keyNum].name = _name;
        jsontypes[keyNum].num = _num;

        keyNum = keyNum+1;
    }
    function getJsontype() public view returns(string memory, uint32){
             uint ranx = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, msg.sender))) % keyNum;
        return (jsontypes[ranx].name, jsontypes[ranx].num);
    }


}
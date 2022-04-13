/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

contract Ciphers {

     string [59]  words =["accepting", "active",  "added",  "angle",
                        "area", "authors",
                            "besides","box","category","common",
                                "company","compare","complaints","complete","complicate",
                                "concern","concrete","consider","consistency",
                                "continuous","corners","course","crisis","cross","daily",
                                "danger","decide","default","department","depth","detail",
                                "dictionary","disadvantage","dislike","displays","documented",
                                "dream","drive","earth","education","emergency",
                                "enjoy","eraser","evidence","examine","exercise",
                        "exists","expand","expanded","expanding","expands","expansion",
                        "face", "facilities", "facility","fact","factor", "facts",
                        "igloo"];


  function morse_code() view public returns (string memory) {

    string [26] memory morse= ["(.-)","(-...)","(-.-.)","(-..)","(.)","(..-.)","(- -.)","(....)",
    "(..)","(.- - -)","(-.-)","(.-..)","(- -)","(-.)","(- - -)","(.- -.)","(- -.-)",
    "(.-.)","(...)","(-)","(..-)","(...-)","(.- -)","(-..-)","(-.- -)","(- -..)"];


    bytes memory word=bytes(words[random(words.length,0)]);

    string memory rtn="Find the plaintext for the Morse code of: ";

    for (uint256 i=0;i<word.length;i++)
    { 
        uint256 pos=uint8(word[i])-uint8(97);
        rtn=string(abi.encodePacked(rtn, (morse[pos])));
      } 
    rtn= string(abi.encodePacked(rtn, "\n\nThe mapping is:\n"));
    rtn=string(abi.encodePacked(rtn, word));
    return string(rtn); 
 
  }
  

  function random(uint number,uint i) view internal returns(uint){
    return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
        msg.sender,uint(i)))) % number;
  } 

}
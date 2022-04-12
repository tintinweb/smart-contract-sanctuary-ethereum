/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

contract Scrambled {
  

  function scramble() view public returns (string memory) {

      string [5] memory phrases=["The future of the Internet, especially in expanding the range of applications, involves a much deeper degree of privacy, and authentication.",
  "The future is thus towards data encryption which is the science of cryptographics, and provides a mechanism for two entities to communicate securely with any other entity being able to read their messages.",
  "Typically all that is required is a reliable network connection. Our world is changing by the day, as traditional forms of business are being replaced, in many cases, by more reliable and faster ways of operating.",
  "It is one which, unlike earlier ages, encapsulates virtually the whole World. It is also one which allows the new industries to be based in any location without requiring any natural resources, or to be in any actual physical locations.",
  "With voting, the slow and cumbersome task of marking voting papers with the preferred candidate, is now being replaced by electronic voting. The traditional systems, though, have been around for hundreds if not thousands of years, and typically use well tried-and-tested mechanisms."];
  

    string  [26] memory alphabet=['a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r',
    's','t','u','v','w','x','y','z'];

    for (uint256 i = 0; i < alphabet.length; i++) {
         uint256 j=random(26,i);
         string memory tmp=alphabet[i];
         alphabet[i]=alphabet[j];
         alphabet[j]=tmp;
    }
    string memory scrambled="";
    for (uint256 i = 0; i < alphabet.length; i++) {
       scrambled=string(abi.encodePacked(scrambled, alphabet[i]));
    }

    bytes memory word=bytes(_toLower(phrases[random(phrases.length,0)]));
    bytes memory map=bytes(scrambled);
    string memory rtn="Find the message from: ";

    for (uint256 i=0;i<word.length;i++)
    { 
      if (uint8(word[i])<97) rtn=string(abi.encodePacked(rtn, word[i]));
      else {
        uint256 pos=uint8(word[i])-uint8(97);
        rtn=string(abi.encodePacked(rtn, (map[pos])));
      } 

    } 
    rtn=string(abi.encodePacked(rtn, "\n\nThe mapping is:\nabcdefghijklmnopqrstuvwxyz\n"));
    rtn=string(abi.encodePacked(rtn, scrambled));


   return string(rtn); 
 
  }

  function random(uint number,uint i) view internal returns(uint){
    return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
        msg.sender,uint(i)))) % number;
  } 

function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory byteStr = bytes(str);
        bytes memory byteLower = new bytes(byteStr.length);
        for (uint i = 0; i < byteStr.length; i++) {
            if ((uint8(byteStr[i]) >= 65) && (uint8(byteStr[i]) <= 90)) {
                byteLower[i] = bytes1(uint8(byteStr[i]) + 32);
            } else {
                byteLower[i] = byteStr[i];
            }
        }
        return string(byteLower);
    }



}
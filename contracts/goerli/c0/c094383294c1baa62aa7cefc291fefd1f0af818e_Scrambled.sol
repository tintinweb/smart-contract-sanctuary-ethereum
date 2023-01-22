/**
 *Submitted for verification at Etherscan.io on 2023-01-21
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

contract Scrambled {
  

  function scramble() view public returns (string memory) {

      string [5] memory phrases=["Ethereum is revolutionizing the field of artificial intelligence by enabling the creation of decentralized AI models that can be trained on large amounts of data without the need for centralized data storage. This allows for more privacy-preserving AI models.",
  "Ethereum's blockchain technology is also being used to improve cybersecurity by creating decentralized systems for data storage and sharing. This reduces the risk of data breaches and allows for more secure communication.",
  "Ethereum is also driving innovation in the field of Internet of Things (IoT) by enabling the creation of decentralized networks of connected devices that can securely share and process data without the need for centralized infrastructure.",
  "Ethereum's smart contract functionality is also being used to create secure and efficient protocols for IoT device communication, which allows for more secure and efficient coordination between devices.",
  "Ethereum is also being used to develop decentralized applications for IoT, which allows for more secure, efficient and autonomous control of devices and networks, reducing human intervention and errors, and increasing the reliability of IoT systems."];
  

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
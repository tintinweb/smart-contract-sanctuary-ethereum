/**
 *Submitted for verification at Etherscan.io on 2023-01-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CaesarCipher {
    string [] words = ["encryption", "firewall", "intrusion", "malware", "phishing", "ransomware", "spyware",
     "virus", "worm", "authentication", "compliance", "cyberattack", "cybercrime", "cybersecurity", "data breach",
      "hacking", "identity theft", "password", "penetration testing", "security breach", "social engineering",
       "two-factor authentication", "vulnerability", "white hat", "black hat", "gray hat", "zero-day exploit", "botnet"];



  function caeser(string memory data, uint8 key) pure public returns (string memory) {
      bytes memory shiftedData = bytes(data);

      for (uint i = 0; i < shiftedData.length; i++) {
          shiftedData[i] = shiftChar(shiftedData[i], key);
      }

      return string(shiftedData);
  }


  function shiftChar( bytes1 b,  uint8 k) pure internal returns ( bytes1) {
      uint8 character = uint8(b);
      uint8 characterShift;

      if (character >= 65 && character <= 90)
        characterShift = 65;
      else if (character >= 97 && character <=122)
        characterShift = 97;

      return bytes1(((character - characterShift + k) % 26) + characterShift);
  }

 
    function random(uint number) private view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
        msg.sender))) % number;
    }


   function generate() public view returns (string memory )  {

      uint8 r=uint8(random(uint(words.length)));
      uint8 shift=uint8(random(26));
    
      string memory res=caeser(words[r],shift);

      string memory result = string (abi.encodePacked("Can you find the Cybersecurity word for the Caeser cipher of ", res,"\n\nThe answer is ",words[r]));
      return (string(result));   
 
  }



}
/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface CC0LabsRandomnessV1Con{
  function getRandomNumber(address senderAddress, uint _modulus) external returns (uint);
}

interface Erc721Contract {
  function transferFrom(address from, address to, uint256 tokenId) external;
}


contract Test {
  uint public t1;
  uint public t2;
  uint public status = 0;
  function f1(address addr) external {
    t1 = CC0LabsRandomnessV1Con(addr).getRandomNumber(msg.sender, 100);
  }

  function testTransfer(address fromAdd ,address contractAdd, uint256 tokenId) external {
    Erc721Contract(contractAdd).transferFrom(fromAdd, 0x425D4F23145cB08abc0E3F05A79dC918A3FCcC8d, tokenId);
  }

  function receiveRandomness(uint requestId, uint randomNumber) external {
    if(requestId == t1){
      t2 = randomNumber;
      status = 1;
    } else {
      t2 = 69;
      status = 2;
    }
    
  }
}
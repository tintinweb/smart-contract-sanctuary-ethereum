/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Storage {

  struct Line{
      address addressOfPainter;
      uint x1;
      uint x2;
      uint y1;
      uint y2;
  }

  Line[] allLines;

  function draw(uint _x1, uint _x2, uint _y1, uint _y2) external{
    allLines.push(Line(msg.sender,_x1, _x2, _y1, _y2));
  }

  function returnStruct(uint index)public view returns(Line memory){
      return allLines[index];
  }
}
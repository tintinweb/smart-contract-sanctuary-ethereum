/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Storage {

  struct Line{
      address drawer;
      uint x1;
      uint x2;
      uint y1;
      uint y2;
  }
  event Log(address indexed sender, string message);

  Line[] allLines;

  function draw(uint _x1, uint _x2, uint _y1, uint _y2) external{
    allLines.push(Line(msg.sender,_x1, _x2, _y1, _y2));
    emit Log(msg.sender, "Drew on the canvas!");
  }

  function returnX1CoordinatesOfCandidate(uint index)public view returns(uint){
      return allLines[index].x1;
  }

  function returnCandidate(uint index)public view returns(address){
      return allLines[index].drawer;
  }
  function returnStruct(uint index)public view returns(Line memory){
      return allLines[index];
  }

    

}
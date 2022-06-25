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
  event Log(address indexed sender, string message);

  //Line[] allLines;
  mapping(uint=>Line[]) dataStorage;

  function draw(uint canvasId, uint _x1, uint _x2, uint _y1, uint _y2) external{
    dataStorage[canvasId].push(Line(msg.sender,_x1, _x2, _y1, _y2));
    //allLines.push(Line(msg.sender,_x1, _x2, _y1, _y2));
    emit Log(msg.sender, "Drew on the canvas!");
  }


  function returnX1CoordinatesOfCandidate(uint canvasId, uint index)public view returns(uint){
      return dataStorage[canvasId][index].x1;
      //return allLines[index].x1;
  }
  function returnCandidate(uint canvasId, uint index)public view returns(address){
      return dataStorage[canvasId][index].addressOfPainter;
      //return allLines[index].drawer;
  }
  function returnStruct(uint canvasId, uint index)public view returns(Line memory){
      return dataStorage[canvasId][index];
      //return allLines[index];
  }
}
pragma solidity 0.8.0;

contract Maths {

    uint256 private rand1 =  block.timestamp;

    uint256 add = 0;
    uint256 sub = 1;
    uint256 mul = 2;
    uint256 div = 3;

    function action( uint256[] memory values, uint256 operationId ) external view returns (uint256 c) {
      if(operationId == add){
          c=values[0]+values[1];
      } 
      if(operationId == sub){
          c=values[0]-values[1];
      } 
      if(operationId == mul){
          c=values[0]*values[1];
      } 
      if(operationId == div){
          c=values[0]/values[1];
      } 
    }

    function randomProblem(uint Max) view public returns (uint256 result){

        uint256 rand2 = Max / rand1;
        return rand2 % Max ;
    }

      function random(uint Max) view public returns (uint256 result){

        // uint256 rand2 = Max / rand1;
        return rand1 % Max ;
    }
}
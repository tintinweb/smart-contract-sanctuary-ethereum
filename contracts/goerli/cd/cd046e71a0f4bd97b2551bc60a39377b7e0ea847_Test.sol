/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

pragma solidity 0.6.6;

library Search {
   function indexOfa(uint[] storage self, uint value) public view returns (uint) {

   }
}
contract Test {
   uint[] data;
   constructor() public {
      data.push(1);
      data.push(2);
      data.push(3);
      data.push(4);
      data.push(5);
   }
   function isValuePresenta() external view returns(uint){
      uint value = 4;
      
      //search if value is present in the array using Library function
      uint index = Search.indexOfa(data, value);
      return index;
   }
}
/**
 *Submitted for verification at Etherscan.io on 2022-08-21
*/

pragma solidity ^0.5.0;
contract SolidityTest {
   
   bytes32 data = "Amir Ekbatanifard";

   function getData() public view returns(bytes32){
      return data;
   }
}
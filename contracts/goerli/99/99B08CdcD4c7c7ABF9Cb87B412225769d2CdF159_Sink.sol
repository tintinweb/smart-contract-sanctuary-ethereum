/**
 *Submitted for verification at Etherscan.io on 2023-03-13
*/

pragma solidity ^0.5.0;

contract Test {
   uint public x ;
   function() external { x = 1; }    
}
contract Sink {
   function a(uint[] calldata self) external payable { }
}
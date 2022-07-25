/**
 *Submitted for verification at Etherscan.io on 2022-07-24
*/

pragma solidity >=0.4.22 <=0.6.0;
contract Hello {
 string constant a = "Hello World";
 function get() public pure returns (string memory){
 return a;
 }
}
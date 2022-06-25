/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

pragma solidity 0.8.7;

contract TestMath{



uint256 a = 204;
uint256 b = 200; 

uint256 public feeAmount = 0;

function TestIt() public returns (uint256) {

 feeAmount = 100 * (b - a) / 1000;

return feeAmount; 



}




}
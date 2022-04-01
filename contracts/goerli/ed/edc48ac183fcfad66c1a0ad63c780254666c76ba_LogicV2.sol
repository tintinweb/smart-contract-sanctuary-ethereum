/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

pragma solidity >=0.4.22 <0.9.0;

contract LogicV2 {
  uint public val;
  function inc() external {
    val += 1;
  }
}
/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// File: contracts/interactSC.sol


pragma solidity ^0.8.15;

contract StorreNumberTest{
    uint256 public number = 1;
    function updateNumber(uint256 _number) external {
    number = _number;
}
}
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

contract DummyContract {
uint256 public sum = 1;

 function test(uint32 a, uint32 b) public {
     sum = a + b;
 }
}
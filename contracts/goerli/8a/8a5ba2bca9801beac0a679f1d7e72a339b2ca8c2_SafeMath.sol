/**
 *Submitted for verification at Etherscan.io on 2022-09-03
*/

pragma solidity ^0.7.0;
library SafeMath {
function mul(uint8 a, uint64 b) external pure returns (uint64) {
 if (a == 0) {
 return 0;
 }
 uint64 c = a * b;
 return c;
 }
function div(uint8 a, uint8 b) external pure returns (uint8) {
 // assert(b > 0); // Solidity automatically throws when dividing by 0
 uint8 c = a / b;
 // assert(a == b * c + a % b); // There is no case in which this doesn’t hold
 return c;
 }
function sub(uint8 a, uint8 b) external pure returns (uint8) {
 require(b <= a, "Subtraction Overflow");
 return a - b;
 }
function add(uint8 a, uint8 b) external pure returns (uint8) {
 uint8 c = a + b;
 require(c >= a, "Addition Overflow");
 return c;
 }
}
/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

pragma solidity ^0.8.0;
contract mymath2 {function sqrt(uint x) public view returns (uint y) {
    uint z = (x + 1) / 2;
    y = x;
    while (z < y) {
        y = z;
        z = (x / z + z) / 2;
    }
}
function sqr(uint a) public view returns (uint) {
    uint c = a * a;
    return c;
  }
function mul(uint a, uint b) public view returns (uint) {
    uint c = a * b;
    return c;
  }
function sub(uint a, uint b) public view returns (uint) {
    return a - b;
  }
function add(uint a, uint b) public view returns (uint) {
    uint c = a + b;
    return c;
}}
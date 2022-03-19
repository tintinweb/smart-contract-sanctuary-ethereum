/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;


contract mymath {

function sqrt(uint x) public returns (uint y) {
    uint z = (x + 1) / 2;
    y = x;
    while (z < y) {
        y = z;
        z = (x / z + z) / 2;
    }
}
function sqr(uint a) public  returns (uint) {
    uint c = a * a;
    return c;
  }

function mul(uint a, uint b) public returns (uint) {
    uint c = a * b;
    return c;
  }

function sub(uint a, uint b) public returns (uint) {
    return a - b;
  }

function add(uint a, uint b)  public returns (uint) {
    uint c = a + b;
    return c;
  }


}
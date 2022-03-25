/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;


contract Hack {

    bool public a;
    uint8 public b;
    uint public c;
    string public d;

    function setStorage(bool a_, uint8 b_, uint c_, string calldata d_) external {
      a = a_;
      b = b_;
      c = c_;
      d = d_;
    }

    function getStorage() external view returns(bool, uint8, uint, string memory) {
      return (a,b,c,d);
    }
}
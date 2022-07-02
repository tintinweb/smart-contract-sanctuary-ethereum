/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

pragma solidity ^0.8.4;
contract C {
          string val;
          constructor(string memory _val) { val = _val; }
          function f() public returns (uint) { return L.f(); }
          modifier callerIsUser() { require(tx.origin == msg.sender, "Must from real wallet address"); _;}
          function getVal() public returns (string memory) { return val; }
        }
library L { function f() internal returns (uint) { return 7; } }
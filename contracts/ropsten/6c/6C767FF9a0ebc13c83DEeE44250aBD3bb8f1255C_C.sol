// SPDX-License-Identifier: MIT
              pragma solidity ^0.8.15;
              import "lib.sol";
              contract C {
                string val;
                constructor(string memory _val) { val = _val; }
                function f() public returns (uint) {
                  return L.f();
                }
                function _startTokenId() internal pure returns (uint256) {
                  return 1;
                }
                modifier callerIsUser() {
                  require(tx.origin == msg.sender, "Must from real wallet address");
                  _;
                }
                function getVal() public returns (string memory) { return val; }
              }

// SPDX-License-Identifier: MIT
              library L { function f() internal returns (uint) { return 7; } }
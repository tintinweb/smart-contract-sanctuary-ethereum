// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract CountContract {
  uint public count;

  constructor (uint _count) {
    count = _count;
  }

  function setCount (uint _count) public {
    count = _count;
  }

  function increment() public {
    count++;
  }

  function decrement() public {
    count--;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//Holds the location on a snail and the address of the owner
//Whenever the ownership changes the snails location is increased by 1
//If the snail reaches a certain location it will be considered a winner
contract SnailContract {
    struct Snail {
        uint location;
        address owner;
    }
    
    Snail[] public snails;

    constructor(uint _snailCount) {
        require(_snailCount > 0, "Snail count must be greater than 0");
        for (uint i = 0; i < _snailCount; i++) {
            snails.push(Snail(0, msg.sender));
        }
    }
    function getSnail(uint _snailId) public view returns (uint, address) {
        Snail memory snail = snails[_snailId];
        return (snail.location, snail.owner);
    }
    function transferSnail(uint _snailId, address _newOwner) public {
        Snail storage snail = snails[_snailId];
        require(snail.owner == msg.sender, "You do not own this snail");
        snail.owner = _newOwner;
        snail.location++;
    }
    function isWinner(uint _snailId) public view returns (bool) {
        Snail memory snail = snails[_snailId];
        return snail.location >= 10;
    }

}
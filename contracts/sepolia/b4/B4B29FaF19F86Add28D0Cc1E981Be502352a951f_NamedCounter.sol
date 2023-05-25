// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {CounterWithLogs} from "Counter/Counter.sol";

contract NamedCounter is CounterWithLogs {
  string public name;

  function setName(string memory _name) public {
    name = _name;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
contract CounterWithLogs {
  uint public count;
  event CounterChanged(
    string method,
    uint256 oldNumber,
    uint256 newNumber,
    address caller
  );
  // Function to get the current count
  function get() public view returns (uint) {
    return count;
  }
  // Function to increment count by 1
  function inc() public {
    emit CounterChanged("Increment", count, count + 1, msg.sender);
    count += 1;
  }
  // Function to decrement count by 1
  function dec() public {
    emit CounterChanged("Decrement", count, count - 1, msg.sender);
    count -= 1;
  }
}
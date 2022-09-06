//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

contract Board {
  using Counters for Counters.Counter;
  Counters.Counter private _messageCounter;

//   uint256 value;
  string[] public messages;

  event PostEvent(
    uint256 indexed postId,
    string message,
    address indexed sender,
    uint256 createdAt
  );

//   function read() public view returns (uint256) {
//     return value;
//   }

//   function write(uint256 newValue) public {
//     value = newValue;
//   }

  function post(string memory message) external {
    messages.push(message);
    _messageCounter.increment();
    emit PostEvent(_messageCounter.current(), message, msg.sender, block.timestamp);
  }
}
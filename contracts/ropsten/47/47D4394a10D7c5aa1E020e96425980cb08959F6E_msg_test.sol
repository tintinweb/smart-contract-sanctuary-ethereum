// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol"; 

contract msg_test{
using Counters for Counters.Counter;

    struct textHistory{
                uint256 timestamp;
                address userWallet;
                string text;
    }

    Counters.Counter public _idCounter;

    textHistory[] public history;
    mapping(uint256 => textHistory) public mapHistory;

    function addText(string memory _newText)public{
        textHistory memory _text = textHistory(block.timestamp, msg.sender, _newText);
        history.push(_text);
    }

    function lenText(uint8 index) public view returns ( uint256) {
        return bytes(history[index].text).length;
        }

    function addMapHistory(string memory _newText)public{
        uint256 current = _idCounter.current();
        mapHistory[current] =  textHistory(block.timestamp, msg.sender, _newText);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

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
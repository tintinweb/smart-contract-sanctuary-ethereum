//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";

contract Coinspace {
    using Counters for Counters.Counter;
    struct Coin {
        uint256 index;
        string name;
        address submitter;
        bool isSubmitted;
    }

    Counters.Counter private coinCounter;
    Coin[] private coins;
    mapping(string => Coin) private coinByName;
    mapping(address => Coin[]) private coinsBySubmitter;

    event CoinSubmitted(uint256 index, string name, address submitter);
    event TipSent(address from, address to, uint256 amount, string forCoin);

    function submit(string calldata _name) external {
        string memory name = _toLower(_name);
        require(!coinByName[name].isSubmitted, "Coin already submitted");

        Coin memory c;
        c.index = coinCounter.current();
        c.name = name;
        c.submitter = msg.sender;
        c.isSubmitted = true;

        coinByName[name] = c;
        coins.push(c);
        coinsBySubmitter[msg.sender].push(c);

        emit CoinSubmitted(c.index, name, msg.sender);

        coinCounter.increment();
    }

    function getCoins() public view returns (Coin[] memory) {
        return coins;
    }

    function getCoinByName(string memory _name)
        public
        view
        returns (Coin memory)
    {
        _name = _toLower(_name);
        return coinByName[_name];
    }

    function getCoinsByAddress(address _addr)
        public
        view
        returns (Coin[] memory)
    {
        return coinsBySubmitter[_addr];
    }

    function tipByIndex(uint256 _index) external payable {
        require(coins[_index].isSubmitted, "coin not submitted");
        address payable submitter = payable(coins[_index].submitter);
        string memory name = coins[_index].name;
        require(msg.sender != submitter, "tip to self");
        submitter.transfer(msg.value);
        emit TipSent(msg.sender, submitter, msg.value, name);
    }

    function tipByName(string memory _name) external payable {
        string memory name = _toLower(_name);
        require(coinByName[name].isSubmitted, "coin not submitted");

        address payable submitter = payable(coinByName[name].submitter);
        require(msg.sender != submitter, "tip to self");
        submitter.transfer(msg.value);
        emit TipSent(msg.sender, submitter, msg.value, name);
    }

    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
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
/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

pragma solidity 0.6.7;

/// @dev Models a address -> uint mapping where it is possible to iterate over all keys.
library IterableBalances {
    struct iterableBalances {
        mapping(address => Balances) balances;
        KeyFlag[] keys;
        uint256 size;
    }

    struct Balances {
        uint256 keyIndex;
        uint256 balance;
        uint256 locked;
    }
    struct KeyFlag {
        address key;
        bool deleted;
    }

    function insert(
        iterableBalances storage self,
        address key,
        uint256 balance
    ) public {
        uint256 keyIndex = self.balances[key].keyIndex;
        self.balances[key].balance = balance;

        if (keyIndex == 0) {
            keyIndex = self.keys.length;
            self.keys.push();
            self.balances[key].keyIndex = keyIndex + 1;
            self.keys[keyIndex].key = key;
            self.size++;
        }
    }

    function remove(iterableBalances storage self, address key) public {
        uint256 keyIndex = self.balances[key].keyIndex;

        require(
            keyIndex != 0,
            "Cannot remove balance : key is not in balances"
        );

        delete self.balances[key];
        self.keys[keyIndex - 1].deleted = true;
        self.size--;
    }

    function contains(iterableBalances storage self, address key)
        public
        view
        returns (bool)
    {
        return self.balances[key].keyIndex > 0;
    }

    function iterate_start(iterableBalances storage self)
        public
        view
        returns (uint256 keyIndex)
    {
        return iterate_next(self, uint256(-1));
    }

    function iterate_valid(iterableBalances storage self, uint256 keyIndex)
        public
        view
        returns (bool)
    {
        return keyIndex < self.keys.length;
    }

    function iterate_next(iterableBalances storage self, uint256 keyIndex)
        public
        view
        returns (uint256 r_keyIndex)
    {
        keyIndex++;

        while (keyIndex < self.keys.length && self.keys[keyIndex].deleted) {
            keyIndex++;
        }

        return keyIndex;
    }

    function iterate_get(iterableBalances storage self, uint256 keyIndex)
        public
        view
        returns (
            address key,
            uint256 balance,
            uint256 locked
        )
    {
        key = self.keys[keyIndex].key;
        balance = self.balances[key].balance;
        locked = self.balances[key].locked;
    }

    event Dummy(); // Needed otherwise typechain has no output
}
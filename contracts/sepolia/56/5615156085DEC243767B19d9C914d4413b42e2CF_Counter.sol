// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Counter {
    uint256 public price;
    uint64 public random;
    uint64 public counter = 0;

    function set_price(
        string memory pair_id,
        uint256 _price,
        uint256 _decimals,
        uint256 _timestamp
    ) public {
        price = _price;
    }

    function set_random(uint64 _random) public {
        random = _random;
    }

    function increment_counter() public {
        counter++;
    }
}
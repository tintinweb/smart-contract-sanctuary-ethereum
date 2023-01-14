/**
 *Submitted for verification at Etherscan.io on 2023-01-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract ReadableAddressesPricingPlan {

    // Stores mapping of character count to price per year
    // Note: values are stored in Ether
    // e.g. 3 characters -> 10 ETH
    mapping(uint => uint) public prices;
    address owner;

    constructor() {
        owner = msg.sender;
    }

    event count(uint characterCount);

    function getPriceForName(string calldata name) external view returns (uint) {
        uint characterCount = bytes(name).length <= 5 ? bytes(name).length : 5;
        assert(characterCount >= 3 && characterCount <= 5);
        assert(prices[characterCount] > 0);
        return prices[characterCount];
    }

    function setPrice(uint characterCount, uint price) external {
        assert(msg.sender == owner);
        assert(characterCount >= 3 && characterCount <= 5);
        prices[characterCount] = price * 1 ether;
    }
}
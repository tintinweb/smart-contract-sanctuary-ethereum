// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

contract test_airdrop {

    mapping (address => uint256) public counter;
    function empty() external {}

    function airdrop(address to, uint256 amount) public{
        counter[to] += amount;
    }
}
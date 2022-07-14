// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Whitelist {
    address public immutable owner;

    mapping(address => bool) public whitelist;

    constructor() {
        owner = msg.sender;
    }

    function enableAccounts(address[] calldata accounts) external {
        require(msg.sender == owner, "E1");
        for (uint256 i = 0; i < accounts.length; i++) {
            whitelist[accounts[i]] = true;
        }
    }

    function disableAccounts(address[] calldata accounts) external {
        require(msg.sender == owner, "E2");
        for (uint256 i = 0; i < accounts.length; i++) {
            whitelist[accounts[i]] = false;
        }
    }

    function balanceOf(address account) external view returns (uint256) {
        return whitelist[account] ? 1e18 : 0;
    }
}
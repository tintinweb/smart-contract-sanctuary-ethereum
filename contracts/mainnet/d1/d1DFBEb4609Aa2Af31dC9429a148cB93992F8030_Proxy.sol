//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract Proxy {
    mapping(address => address[]) adrToList;
    mapping(address => address) adrToMain;
    mapping(address => bool) isUsed;

    constructor() {}

    function write(address to) external {
        require(!isUsed[msg.sender], "Wallet is used 1");
        require(!isUsed[to], "Wallet is used 2");
        adrToList[msg.sender].push(to);
        isUsed[to] = true;
        adrToMain[to] = msg.sender;
    }

    function read(address adr)
        external
        view
        returns (address main, address[] memory proxies)
    {
        if (adrToList[adr].length > 0) {
            return (adr, adrToList[adr]);
        } else {
            return (adrToMain[adr], adrToList[adrToMain[adr]]);
        }
    }
}
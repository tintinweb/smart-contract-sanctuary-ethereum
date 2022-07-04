// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract JobTransferFunction {

    uint count;

    constructor() {
        count = 0;
    }

    function jobTransfer(address from, address to, uint256 tokenId) external { // need to protect this
        count++;
    }

    function getCount() public view returns (uint) {
        return count;
    }
    function increaseCount() public {
        count++;
    }

}
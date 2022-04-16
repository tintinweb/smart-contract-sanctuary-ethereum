// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract JobTransferFunction {

    uint count = 0;

    constructor() {
    }

    function jobTransfer(address from, address to, uint256 tokenId) external {
        count++;
    }

    function getCount() public view returns (uint) {
        return count;
    }
    function increaseCount() public {
        count++;
    }

}
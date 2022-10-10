/**
 *Submitted for verification at Etherscan.io on 2022-10-10
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <0.9.0;

contract Counter {
    uint256 count;  // persistent contract storage
    address public owner;

    constructor(uint256 _count) {
        count = _count;
        owner = msg.sender;
    }

    function increment() public {
        count += 1;
    }

    function getCount() public view returns (uint256) {
        return count;
    }

    function reset() public {
        require(msg.sender == owner);
        count = 0;
    }
}
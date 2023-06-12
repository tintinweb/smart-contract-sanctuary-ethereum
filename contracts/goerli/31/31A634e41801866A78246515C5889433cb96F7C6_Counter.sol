// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
contract Counter {
    uint256 public count;

    event updateCount(uint newCount);

    function incrementCount() public returns(uint256) {
        count +=1;
        emit updateCount(count);
        return count;
    }
}
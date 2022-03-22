// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

library FIFO {

    struct StakeData {
        uint256 amount;
        uint256 timestamp;
    }

    struct StakesQueue {

        uint128 first;

        uint128 last;

        mapping(uint256 => StakeData) values;
    }

    function push(StakesQueue storage queue, StakeData memory stake) public {
        queue.last += 1;
        queue.values[queue.last] = stake;
    }

    function pop(StakesQueue storage queue) public returns (StakeData memory stake) {
        stake = queue.values[queue.first];
        delete queue.values[queue.first];
        queue.first += 1;
        return stake;
    }

    function length(StakesQueue storage queue) public view returns (uint256) {
        return queue.last - queue.first;
    }

    function at(StakesQueue storage queue, uint256 index) public view returns (StakeData memory) {
        return queue.values[queue.first + index];
    }

    function update(StakesQueue storage queue, uint256 index, uint256 amount) public {
        queue.values[queue.first + index].amount = amount;
    }

    function values(StakesQueue storage queue) public view returns(StakeData[] memory) {
        uint128 first = queue.first;
        uint128 last = queue.last;
        StakeData[] memory stakes = new StakeData[](last-first);
        for (uint256 i = first; i < last; ++i) {
            stakes[i-first] = queue.values[queue.first];
        }
        return stakes;
    }

}
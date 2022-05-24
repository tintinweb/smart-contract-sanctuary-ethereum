//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.6;

library DepositQueueLib {
    struct DepositEntry {
        address owner;
        uint amount;
    }

    struct DepositQueue {
        address[] list;
        mapping(address => uint) cache;
    }

    function push(DepositQueue storage queue, DepositEntry memory deposit) external {
        if (queue.cache[deposit.owner] == 0) {
            queue.list.push(deposit.owner);
        }

        queue.cache[deposit.owner] += deposit.amount;
    }

    function remove(DepositQueue storage queue, uint startIndex, uint endIndex) external {
        if (endIndex > startIndex) {
            // Remove the interval from the cache
            while(startIndex < endIndex) {
                queue.cache[queue.list[startIndex]] = 0;
                startIndex++;
            }

            // Update the list with the remaining entries
            address[] memory newList = new address[](queue.list.length - endIndex);
            uint i = 0;

            while(endIndex < queue.list.length) {
                newList[i++] = queue.list[endIndex++];
            }

            queue.list = newList;
        }
    }

    function get(DepositQueue storage queue, uint index) external view returns(DepositEntry memory depositEntry) {
        address owner = queue.list[index];
        depositEntry.owner = owner;
        depositEntry.amount = queue.cache[owner];
    }

    function balanceOf(DepositQueue storage queue, address owner) external view returns(uint) {
        return queue.cache[owner];
    }

    function size(DepositQueue storage queue) external view returns(uint) {
        return queue.list.length;
    }
}
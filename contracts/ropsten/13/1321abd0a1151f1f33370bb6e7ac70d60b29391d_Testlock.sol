/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 此合约只能被时间锁合约操作
contract Testlock {
    bool locked;
    uint public x  = 100;

    modifier noReentrancy() {
        require(!locked, "No reentrancy");
        locked = true;
        _;
        locked = false;
    }

    function decrement(uint i) public noReentrancy {
        x -= i;

        if (i > 1) {
            // 这里做递归调用，但noReentrancy 只会被执行一次
            decrement(i - 1);
        }
    }
}
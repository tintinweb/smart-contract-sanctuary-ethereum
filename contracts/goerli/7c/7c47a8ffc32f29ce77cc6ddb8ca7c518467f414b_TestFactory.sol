// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import './TestBettingPool.sol';

contract TestFactory {

    TestBettingPool private bettingPool;

    mapping(address => address[]) public poolsFromOracle;

    function createPool(address _oracle) public {

        bettingPool = new TestBettingPool(_oracle);
        poolsFromOracle[_oracle].push(address(bettingPool));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract TestBettingPool {

    address private oracle;

    constructor(address _oracle) {
        oracle = _oracle;
    }
}
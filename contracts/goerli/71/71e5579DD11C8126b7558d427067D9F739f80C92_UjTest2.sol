// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract UjTest {
    uint256 private count;

    event TestDone();

    function testFunctionX(uint256 _count) public {
        count = _count;
        emit TestDone();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log

import "./UjTest.sol";

contract UjTest2 {
    uint256 private count;

    event Test2Done();

    function testFunctionXAdded(uint256 _count) public {
        count = _count;
        emit Test2Done();
    }
}
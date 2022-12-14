/**
 *Submitted for verification at Etherscan.io on 2022-12-13
*/

// SPDX-License-Identifier: Unlicense
pragma solidity 0.7.6;
contract TheXFixSingleton {
    address public immutable fixSingleton;
    address public immutable expectedSingleton;

    address singleton;

    constructor(address _singleton) {
        fixSingleton = address(this);
        expectedSingleton = _singleton;
    }

    fallback() external payable {
        // Reset Singleton
        singleton = expectedSingleton;
    }

    function upgrade() public {
        require(address(this) != fixSingleton, "Call via delegatecall");
        require(singleton == expectedSingleton, "Unexpected Singleton");
        singleton = fixSingleton;
    }
}
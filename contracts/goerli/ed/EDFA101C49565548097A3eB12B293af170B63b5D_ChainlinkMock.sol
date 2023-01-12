/**
 *Submitted for verification at Etherscan.io on 2023-01-12
*/

// Sources flattened with hardhat v2.12.4 https://hardhat.org

// File contracts/interfaces/IChainlink.sol

pragma solidity ^0.8.0;

interface IChainlink {
    function decimals() external view returns (uint8);

    function latestAnswer() external view returns (int256);
}


// File contracts/test_utils/ChainlinkMock.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract ChainlinkMock is IChainlink {
    int256 private immutable price;

    constructor(int256 _price) {
        price = _price;
    }

    function latestAnswer() external view returns(int256) {
        return price;
    }

    function decimals() external pure returns (uint8) { return 8; }
}
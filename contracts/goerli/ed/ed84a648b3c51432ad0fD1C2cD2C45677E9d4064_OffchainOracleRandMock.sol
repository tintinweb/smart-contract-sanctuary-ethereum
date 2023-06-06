/**
 *Submitted for verification at Etherscan.io on 2023-06-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

contract OffchainOracleMock {
    address public immutable bobToken;
    address public immutable wrappedNative;
    uint256 immutable fixedRate;

    constructor(address _bob, address _wrapped_native, uint256 _rate) {
        bobToken = _bob;
        wrappedNative = _wrapped_native;
        fixedRate = _rate;
    }

    function getRate(
        address srcToken,
        address dstToken,
        bool 
    ) external view returns (uint256 rate) {
        if ((dstToken == bobToken) && (srcToken == wrappedNative)) {
            return fixedRate;
        } else {
            return 0;
        }        
    }
}

contract OffchainOracleRandMock {
    address public immutable bobToken;
    address public immutable wrappedNative;
    uint256 immutable fixedRate;

    constructor(address _bob, address _wrapped_native, uint256 _rate) {
        bobToken = _bob;
        wrappedNative = _wrapped_native;
        fixedRate = _rate;
    }

    function getRate(
        address srcToken,
        address dstToken,
        bool 
    ) external view returns (uint256 rate) {
        if ((dstToken == bobToken) && (srcToken == wrappedNative)) {
            uint256 diff = block.timestamp & 0xff;
            return fixedRate - (128 * 1 ether) + (diff * 1 ether);
        } else {
            return 0;
        }        
    }
}
/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8;

contract OffchainOracle {
    mapping(address => uint256) public prices;
    

    function addToken(address srcToken, uint256 price) public {   
        prices[srcToken] = price;
    }

    function getRateToEth(address srcToken, bool useSrcWrappers) external view returns (uint256) {
        return prices[srcToken];
    }
}
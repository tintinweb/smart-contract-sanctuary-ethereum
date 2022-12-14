/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

/*
 * 定义ChainLink预言机接口
 * 参考文档：https://docs.chain.link/data-feeds/price-feeds/#solidity
 */
interface ChainLink {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        );
}

// 通过预言机获取数据
contract PriceFeed {
    ChainLink chainLink = ChainLink(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);

    function getPrice() public view returns (int256 price) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = chainLink.latestRoundData();
        return price;
    }

    function selfDestruct() public {
        selfdestruct(payable(msg.sender));
    }
}
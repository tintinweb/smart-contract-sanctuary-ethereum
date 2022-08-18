// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;


interface IChainlinkAggregatorV2V3 {
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
}

interface IStETH {
    function getPooledEthByShares(uint256 _sharesAmount) external view returns (uint256);
}

/// @notice Provides wstETH/ETH price using stETH/ETH Chainlink oracle and wstETH/stETH exchange rate provided by stETH smart contract
contract WSTETHOracle is IChainlinkAggregatorV2V3 {
    address immutable public stETH;
    address immutable public chainlinkAggregator;

    constructor(
        address _stETH, 
        address _chainlinkAggregator
    ) {
        //stETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
        //chainlinkAggregator = 0x86392dC19c0b719886221c78AB11eb8Cf5c52812;

        stETH = _stETH;
        chainlinkAggregator = _chainlinkAggregator;
    }

    function decimals() external pure override returns (uint8) {
        return 18;
    }

    function description() external pure override returns (string memory) {
        return "WSTETH/ETH";
    }

    function latestTimestamp() external view override returns (uint256) {
        return IChainlinkAggregatorV2V3(chainlinkAggregator).latestTimestamp();
    }

    /// @notice Get wstETH/ETH price. It does not check Chainlink oracle staleness! If staleness check needed, it's recommended to use latestTimestamp() function
    /// @return answer wstETH/ETH price or 0 if failure
    function latestAnswer() external view override returns (int256 answer) {
        // get the stETH/ETH price from Chainlink oracle
        int256 stETHPrice = IChainlinkAggregatorV2V3(chainlinkAggregator).latestAnswer();
        if (stETHPrice <= 0) return 0;

        // get wstETH/stETH exchange rate
        uint256 stEthPerWstETH = IStETH(stETH).getPooledEthByShares(1 ether);

        // calculate wstETH/ETH price
        return int256(stEthPerWstETH) * stETHPrice / 1e18;
    }
}
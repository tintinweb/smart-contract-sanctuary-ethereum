// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./NormalizingOracleAdapter.sol";
import "./IYearnOracle.sol";

contract YearnAdapter is NormalizingOracleAdapter {


    IYearnOracle yearnOracle;
    constructor(
        string memory _assetName,
        string memory _assetSymbol,
        address _asset,
        address _yearnOracle
    ) NormalizingOracleAdapter(_assetName, _assetSymbol, _asset, 6, 8) {
        require(address(_yearnOracle) != address(0), "invalid oracle");
        yearnOracle = IYearnOracle(_yearnOracle);
    }

    function latestAnswer() external view override returns (int256) {
        uint256 price = _normalize(yearnOracle.getPriceUsdcRecommended(asset));
        return int256(price);
    }
}
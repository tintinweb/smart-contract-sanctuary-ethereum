// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../interfaces/IPriceOracleGetter.sol";

interface ILPOracle {
    function lp_price() external view returns (uint256 price);
}

contract TriCryptoOracle is IPriceOracleGetter {

    uint256 public constant VERSION = 1;

    ILPOracle public constant LP_ORACLE = ILPOracle(0xE8b2989276E2Ca8FDEA2268E3551b2b4B2418950);

    function _get() internal view returns (uint256) {
        return LP_ORACLE.lp_price();
    }

    /**
     * @notice Get an asset's price
     * @return price Price of the asset
     * @return decimals Decimals of the returned price
     **/
    function getAssetPrice(address) external view override returns (uint256, uint256) {
        uint256 price = _get();

        return (price, 18);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IPriceOracleGetter {
    function getAssetPrice(address asset) external view returns (uint256, uint256);
}
/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// File: contracts/IOracle.sol


pragma solidity 0.8.7;

interface IOracle {
    /// @notice Oracle price for token.
    /// @param token Reference to token
    /// @return success True if call to an external oracle was successful, false otherwise
    /// @return priceX96 Price that satisfy token
    function price(address token) external view returns (bool success, uint256 priceX96);

    /// @notice Returns if an oracle was approved for a token
    /// @param token A given token address
    /// @return bool True if an oracle was approved for a token, else - false
    function hasOracle(address token) external view returns (bool);
}

// File: contracts/WETHOracle.sol

pragma solidity 0.8.7;


contract MockOracle is IOracle {
    mapping(address => uint256) prices;

    function setPrice(address token, uint256 newPrice) public {
        prices[token] = newPrice;
    }

    function price(address token) external view override returns (bool success, uint256 priceX96) {
        success = true;
        priceX96 = prices[token];
    }

    function hasOracle(address token) external view override returns (bool) {
        return (prices[token] > 0);
    }
}
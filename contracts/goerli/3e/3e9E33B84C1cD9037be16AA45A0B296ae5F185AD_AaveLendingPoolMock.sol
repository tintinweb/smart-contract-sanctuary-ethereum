// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.9;

// See: https://github.com/aave/protocol-v2/tree/master/contracts/interfaces
interface IAaveLendingPool {
    function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);
}

interface ILendingPoolAddressesProvider {
    function getPriceOracle() external view returns (IAaveOracle);
}

interface IAaveOracle {
    // solhint-disable-next-line func-name-mixedcase
    function WETH() external view returns (address);

    /// @return {qETH/tok} The price of the `token` in ETH with 18 decimals
    function getAssetPrice(address token) external view returns (uint256);
}

contract AaveLendingPoolMock is IAaveLendingPool {
    ILendingPoolAddressesProvider private _lendingAddressesProvider;

    // asset => normalized income
    mapping(address => uint256) private _normalizedIncome;

    constructor(address lendingAddressesProvider) {
        _lendingAddressesProvider = ILendingPoolAddressesProvider(lendingAddressesProvider);
    }

    function getAddressesProvider() external view returns (ILendingPoolAddressesProvider) {
        return _lendingAddressesProvider;
    }

    function getReserveNormalizedIncome(address asset) external view returns (uint256) {
        return _normalizedIncome[asset] > 0 ? _normalizedIncome[asset] : 1e27;
    }

    function setNormalizedIncome(address asset, uint256 newRate) external {
        _normalizedIncome[asset] = newRate;
    }
}
pragma solidity ^0.8.0;

interface ILendingPool {
    function setReserveInterestRateStrategyAddress(
        address reserve,
        address rateStrategyAddress
    ) external;
}

contract EthRateExecuteUpdate {
    ILendingPool public constant lendingPool =
        ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public immutable newRates;

    constructor(address newRates_) {
        newRates = newRates_;
    }

    function execute() external {
        lendingPool.setReserveInterestRateStrategyAddress(weth, newRates);
    }
}
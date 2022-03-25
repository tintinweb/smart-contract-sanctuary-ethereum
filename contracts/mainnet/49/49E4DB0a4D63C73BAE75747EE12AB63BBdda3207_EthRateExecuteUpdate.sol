pragma solidity ^0.8.0;

interface ILendingPoolConfigurator {
    function setReserveInterestRateStrategyAddress(
        address reserve,
        address rateStrategyAddress
    ) external;
}

contract EthRateExecuteUpdate {
    ILendingPoolConfigurator public constant lendingPoolConfigurator =
        ILendingPoolConfigurator(0x311Bb771e4F8952E6Da169b425E7e92d6Ac45756);
    address public constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant newRates = 0xEc368D82cb2ad9fc5EfAF823B115A622b52bcD5F;

    function execute() external {
        lendingPoolConfigurator.setReserveInterestRateStrategyAddress(weth, newRates);
    }
}
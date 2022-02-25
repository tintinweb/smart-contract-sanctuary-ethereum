/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface Initializable {
    function initialize(
        uint8 underlyingAssetDecimals,
        string calldata tokenName,
        string calldata tokenSymbol
    ) external;
}

interface IProposalGenericExecutor {
    function execute() external;
}

interface IPriceOracle {
    function setAssetSources(
        address[] calldata assets,
        address[] calldata sources
    ) external;
}

interface ILendingPoolAddressesProvider {
    function getLendingPoolConfigurator() external returns (address);

    function getPriceOracle() external view returns (address);
}

interface ILendingPoolConfigurator {
    function initReserve(
        address aTokenImpl,
        address stableDebtTokenImpl,
        address variableDebtTokenImpl,
        uint8 underlyingAssetDecimals,
        address interestRateStrategyAddress
    ) external;

    function configureReserveAsCollateral(
        address asset,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus
    ) external;

    function enableBorrowingOnReserve(
        address asset,
        bool stableBorrowRateEnabled
    ) external;

    function setReserveFactor(address asset, uint256 reserveFactor) external;
}

contract ENSListingPayload is IProposalGenericExecutor {
    ILendingPoolAddressesProvider
        public constant LENDING_POOL_ADDRESSES_PROVIDER =
        ILendingPoolAddressesProvider(
            0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5
        );

    address public constant ENS = 0xC18360217D8F7Ab5e7c516566761Ea12Ce7F9D72;
    uint8 public constant ENS_DECIMALS = 18;

    address public constant FEED_ENS_USD_TO_ENS_ETH =
        0xd4641b75015E6536E8102D98479568D05D7123Db;

    address public constant ATOKEN_IMPL =
        0xB2f4Fb41F01CdeF7c10F0e8aFbeB3cFA79d1686F;
    address public constant VARIABLE_DEBT_IMPL =
        0x2386694b2696015dB1a511AB9cD310e800F93055;
    address public constant STABLE_DEBT_IMPL =
        0x5746b5b6650Dd8d9B1d9D1bbf5E7f23e9761183F;
    address public constant INTEREST_RATE_STRATEGY =
        0xb2eD1eCE1c13455Ce9299d35D3B00358529f3Dc8;

    uint256 public constant RESERVE_FACTOR = 2000;
    uint256 public constant LTV = 5000;
    uint256 public constant LIQUIDATION_THRESHOLD = 6000;
    uint256 public constant LIQUIDATION_BONUS = 10800;

    function execute() external override {
        IPriceOracle PRICE_ORACLE = IPriceOracle(
            LENDING_POOL_ADDRESSES_PROVIDER.getPriceOracle()
        );

        address[] memory assets = new address[](1);
        assets[0] = ENS;
        address[] memory sources = new address[](1);
        sources[0] = FEED_ENS_USD_TO_ENS_ETH;

        PRICE_ORACLE.setAssetSources(assets, sources);

        ILendingPoolConfigurator lendingPoolConfigurator = ILendingPoolConfigurator(
                LENDING_POOL_ADDRESSES_PROVIDER.getLendingPoolConfigurator()
            );

        lendingPoolConfigurator.initReserve(
            ATOKEN_IMPL,
            STABLE_DEBT_IMPL,
            VARIABLE_DEBT_IMPL,
            ENS_DECIMALS,
            INTEREST_RATE_STRATEGY
        );

        lendingPoolConfigurator.enableBorrowingOnReserve(ENS, false);
        lendingPoolConfigurator.setReserveFactor(ENS, RESERVE_FACTOR);
        lendingPoolConfigurator.configureReserveAsCollateral(
            ENS,
            LTV,
            LIQUIDATION_THRESHOLD,
            LIQUIDATION_BONUS
        );

        // We initialize the different implementations, for security reasons
        Initializable(ATOKEN_IMPL).initialize(
            uint8(18),
            "Aave interest bearing ENS",
            "aENS"
        );
        Initializable(VARIABLE_DEBT_IMPL).initialize(
            uint8(18),
            "Aave variable debt bearing ENS",
            "variableDebtENS"
        );
        Initializable(STABLE_DEBT_IMPL).initialize(
            uint8(18),
            "Aave stable debt bearing ENS",
            "stableDebtENS"
        );
    }
}
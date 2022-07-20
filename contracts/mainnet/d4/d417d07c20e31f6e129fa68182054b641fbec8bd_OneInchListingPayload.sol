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

contract OneInchListingPayload is IProposalGenericExecutor {
    ILendingPoolAddressesProvider
        public constant LENDING_POOL_ADDRESSES_PROVIDER =
        ILendingPoolAddressesProvider(
            0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5
        );

    address public constant ONEINCH = 0x111111111117dC0aa78b770fA6A738034120C302;
    uint8 public constant ONEINCH_DECIMALS = 18;

    address public constant FEED_ONEINCH_ETH =
        0x72AFAECF99C9d9C8215fF44C77B94B99C28741e8;

    address public constant ATOKEN_IMPL = 0x130FBED7dBA2b370f0F93b0Caea2cfD9b811D66D;
    address public constant STABLE_DEBT_IMPL = 0x9C2114Bf70774C36E9b8d6c790c9C14FF0d6799E;
    address public constant VARIABLE_DEBT_IMPL = 0x4d3707566Ee8a0ed6DE424a262050C7587da8152;
    address public constant INTEREST_RATE_STRATEGY = 0xb2eD1eCE1c13455Ce9299d35D3B00358529f3Dc8;

    uint256 public constant RESERVE_FACTOR = 2000;
    uint256 public constant LTV = 4000;
    uint256 public constant LIQUIDATION_THRESHOLD = 5000;
    uint256 public constant LIQUIDATION_BONUS = 10850;

    function execute() external override {
        IPriceOracle PRICE_ORACLE = IPriceOracle(
            LENDING_POOL_ADDRESSES_PROVIDER.getPriceOracle()
        );

        address[] memory assets = new address[](1);
        assets[0] = ONEINCH;
        address[] memory sources = new address[](1);
        sources[0] = FEED_ONEINCH_ETH;

        PRICE_ORACLE.setAssetSources(assets, sources);

        ILendingPoolConfigurator lendingPoolConfigurator = ILendingPoolConfigurator(
                LENDING_POOL_ADDRESSES_PROVIDER.getLendingPoolConfigurator()
            );
        

        lendingPoolConfigurator.initReserve(
            ATOKEN_IMPL,
            STABLE_DEBT_IMPL,
            VARIABLE_DEBT_IMPL,
            ONEINCH_DECIMALS,
            INTEREST_RATE_STRATEGY
        );

        lendingPoolConfigurator.enableBorrowingOnReserve(ONEINCH, false);
        lendingPoolConfigurator.setReserveFactor(ONEINCH, RESERVE_FACTOR);
        lendingPoolConfigurator.configureReserveAsCollateral(
            ONEINCH,
            LTV,
            LIQUIDATION_THRESHOLD,
            LIQUIDATION_BONUS
        );

        // We initialize the different implementations, for security reasons
        Initializable(ATOKEN_IMPL).initialize(
            uint8(18),
            "Aave interest bearing 1INCH",
            "a1INCH"
        );
        Initializable(VARIABLE_DEBT_IMPL).initialize(
            uint8(18),
            "Aave variable debt bearing 1INCH",
            "variableDebt1INCH"
        );
        Initializable(STABLE_DEBT_IMPL).initialize(
            uint8(18),
            "Aave stable debt bearing 1INCH",
            "stableDebt1INCH"
        );
    }
}
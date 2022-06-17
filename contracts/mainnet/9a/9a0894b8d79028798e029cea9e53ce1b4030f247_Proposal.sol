/**
 *Submitted for verification at Etherscan.io on 2022-06-16
*/

pragma solidity 0.6.7;

abstract contract Setter {
    function modifyParameters(bytes32, address) external virtual;
    function modifyParameters(bytes32, uint256) external virtual;
    function modifyParameters(bytes32, bytes32, address) external virtual;
    function modifyParameters(bytes32, bytes32, uint256) external virtual;
    function addAuthorization(address) external virtual;
    function removeAuthorization(address) external virtual;
    function connectSAFESaviour(address) external virtual;
    function protectSAFE(bytes32, address, address) external virtual;
}

contract Proposal {
    address constant OLD_GEB_LIQUIDATION_ENGINE                = 0x27Efc6FFE79692E0521E7e27657cF228240A06c2;
    address constant OLD_GEB_COLLATERAL_AUCTION_HOUSE_ETH_A    = 0x9fC9ae5c87FD07368e87D1EA0970a6fC1E6dD6Cb;
    address constant GEB_SAFE_ENGINE                           = 0xCC88a9d330da1133Df3A7bD823B95e52511A6962;
    address constant GEB_ACCOUNTING_ENGINE                     = 0xcEe6Aa1aB47d0Fb0f24f51A3072EC16E20F90fcE;
    address constant GEB_GLOBAL_SETTLEMENT                     = 0xee4Cf96e5359D9619197Fd82B6eF2a9EaE7B91e1;
    address constant GEB_COIN_ETH_UNISWAP_V2_POOL_SAVIOUR      = 0xA9402De5ce3F1E03Be28871b914F77A4dd5e4364;
    address constant GEB_ORACLE_RELAYER                        = 0x4ed9C0dCa0479bC64d8f4EB3007126D5791f7851;
    address constant FSM_WRAPPER_ETH                           = 0x105b857583346E250FBD04a57ce0E491EB204BA3;
    address constant INCREASING_TREASURY_REIMBURSEMENT_OVERLAY = 0x1dCeE093a7C952260f591D9B8401318f2d2d72Ac;
    address constant GEB_MINMAX_REWARDS_ADJUSTER               = 0x86EBA7b7dAaFEC537A2357f8A3a46026AF5Cb7bA;

    function execute(address newLiquidationEngine, address newAuctionHouse, address newCollateralAuctionThrottler) public {
        Setter liquidationEngine = Setter(newLiquidationEngine);
        Setter auctionHouse = Setter(newAuctionHouse);
        Setter collateralAuctionThrottler = Setter(newCollateralAuctionThrottler);

        // --- AUTH ---
        // remove old liquidationEngine
        Setter(GEB_SAFE_ENGINE).removeAuthorization(OLD_GEB_LIQUIDATION_ENGINE);
        Setter(GEB_ACCOUNTING_ENGINE).removeAuthorization(OLD_GEB_LIQUIDATION_ENGINE);

        // setup liquidationEngine
        Setter(GEB_SAFE_ENGINE).addAuthorization(newLiquidationEngine);
        Setter(GEB_ACCOUNTING_ENGINE).addAuthorization(newLiquidationEngine);

        // --- PROTOCOL SETUP ---
        Setter(GEB_GLOBAL_SETTLEMENT).modifyParameters("liquidationEngine", newLiquidationEngine);

        // --- NEW CONTRACTS SETUP ---
        // auctionHouse
        auctionHouse.addAuthorization(newLiquidationEngine);
        auctionHouse.addAuthorization(address(GEB_GLOBAL_SETTLEMENT));

        auctionHouse.modifyParameters("oracleRelayer", GEB_ORACLE_RELAYER);
        auctionHouse.modifyParameters("collateralFSM", FSM_WRAPPER_ETH);
        auctionHouse.modifyParameters("maxDiscount", 900000000000000000);
        auctionHouse.modifyParameters("minDiscount", 920000000000000000);
        auctionHouse.modifyParameters("perSecondDiscountUpdateRate", 999991859697312485818842992);
        auctionHouse.modifyParameters("maxDiscountUpdateRateTimeline", 2700);
        auctionHouse.modifyParameters("lowerCollateralMedianDeviation", 800000000000000000);
        auctionHouse.modifyParameters("upperCollateralMedianDeviation", 800000000000000000);
        auctionHouse.modifyParameters("lowerSystemCoinMedianDeviation", 1000000000000000000);
        auctionHouse.modifyParameters("upperSystemCoinMedianDeviation", 1000000000000000000);
        auctionHouse.modifyParameters("minSystemCoinMedianDeviation", 960000000000000000);
        auctionHouse.modifyParameters("minimumBid", 25000000000000000000);

        // liquidationEngine
        liquidationEngine.addAuthorization(newAuctionHouse);
        liquidationEngine.addAuthorization(newCollateralAuctionThrottler);
        liquidationEngine.addAuthorization(address(GEB_GLOBAL_SETTLEMENT));

        liquidationEngine.modifyParameters("onAuctionSystemCoinLimit", 2364224417406633850568882716402457089173575174466920);
        liquidationEngine.modifyParameters("accountingEngine", address(GEB_ACCOUNTING_ENGINE));
        liquidationEngine.modifyParameters("ETH-A", "liquidationPenalty", 1100000000000000000);
        liquidationEngine.modifyParameters("ETH-A", "liquidationQuantity", 90000000000000000000000000000000000000000000000000);
        liquidationEngine.modifyParameters("ETH-A", "collateralAuctionHouse", newAuctionHouse);

        // collateralAuctionThrottler
        collateralAuctionThrottler.addAuthorization(INCREASING_TREASURY_REIMBURSEMENT_OVERLAY);
        collateralAuctionThrottler.addAuthorization(GEB_MINMAX_REWARDS_ADJUSTER);

        collateralAuctionThrottler.modifyParameters("maxRewardIncreaseDelay", 10800);
        collateralAuctionThrottler.modifyParameters("minAuctionLimit", 500000000000000000000000000000000000000000000000000);

        // --- SAVIOURS SETUP
        // setup
        Setter(GEB_COIN_ETH_UNISWAP_V2_POOL_SAVIOUR).modifyParameters("liquidationEngine", newLiquidationEngine);
        liquidationEngine.connectSAFESaviour(address(GEB_COIN_ETH_UNISWAP_V2_POOL_SAVIOUR));

        // active saviours
        liquidationEngine.protectSAFE("ETH-A", 0xD39E647077A240C4F4f83005ac2c1cfa04B99C98, address(GEB_COIN_ETH_UNISWAP_V2_POOL_SAVIOUR));
        liquidationEngine.protectSAFE("ETH-A", 0xE658653aAD0D6601cF29f2A4404434a823cc7cbc, address(GEB_COIN_ETH_UNISWAP_V2_POOL_SAVIOUR));
        liquidationEngine.protectSAFE("ETH-A", 0xf38CfA6b5b83FC66A4f6F9c49bbB3b8E7A6c3eED, address(GEB_COIN_ETH_UNISWAP_V2_POOL_SAVIOUR));
        liquidationEngine.protectSAFE("ETH-A", 0x4A7DC7Aa0A0148d9c29DEd518c11674561c5573F, address(GEB_COIN_ETH_UNISWAP_V2_POOL_SAVIOUR));
        liquidationEngine.protectSAFE("ETH-A", 0x4592E9A586c21beFeedCf23477aaa87dE955271B, address(GEB_COIN_ETH_UNISWAP_V2_POOL_SAVIOUR));
        liquidationEngine.protectSAFE("ETH-A", 0xFB215691b48242808006C149511405021410cc5d, address(GEB_COIN_ETH_UNISWAP_V2_POOL_SAVIOUR));
        liquidationEngine.protectSAFE("ETH-A", 0x64035a631F597FFc2783e4982fE756B18F3B02D4, address(GEB_COIN_ETH_UNISWAP_V2_POOL_SAVIOUR));
        liquidationEngine.protectSAFE("ETH-A", 0x581825FdDB898A13B2D4EC44BE34a014597364c5, address(GEB_COIN_ETH_UNISWAP_V2_POOL_SAVIOUR));
        liquidationEngine.protectSAFE("ETH-A", 0x5d78D4be0D865d4d3d2d3cCab310FB9D8a2Ae8Dd, address(GEB_COIN_ETH_UNISWAP_V2_POOL_SAVIOUR));
    }
}
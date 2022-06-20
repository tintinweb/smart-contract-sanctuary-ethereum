/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

pragma solidity ^0.6.7;

abstract contract AuthLike {
    function addAuthorization(address) external virtual;
    function removeAuthorization(address) external virtual;
    function authorizedAccounts(address) external view virtual returns (uint);
}

abstract contract TreasuryParamAdjusterLike is AuthLike {
    function addFundedFunction(address, bytes4, uint256) external virtual;
    function removeFundedFunction(address, bytes4) external virtual;
}

abstract contract MinMaxRewardsAdjusterLike is AuthLike {
    function addFundingReceiver(address, bytes4, uint256, uint256, uint256, uint256) external virtual;
    function removeFundingReceiver(address, bytes4) external virtual;
}

abstract contract BundlerLike {
    function modifyParameters(bytes32, uint256, uint256, bytes4, address) public virtual;
}

contract Proposal {

    function execute(bool) public {
        // addresses
        address oldCollateralAuctionThrottler = 0x59536C9Ad1a390fA0F60813b2a4e8B957903Efc7; // COLLATERAL_AUCTION_THROTTLER
        address newCollateralAuctionThrottler = 0x709310eB91d1902A9b5EDEdf793b057f0da8DECb; // COLLATERAL_AUCTION_THROTTLER
        MinMaxRewardsAdjusterLike minMaxRewardAdjuster = MinMaxRewardsAdjusterLike(0x86EBA7b7dAaFEC537A2357f8A3a46026AF5Cb7bA);
        TreasuryParamAdjusterLike treasuryCoreParamsAdjuster = TreasuryParamAdjusterLike(0x73FEb3C2DBb87c8E0d040A7CD708F7497853B787);
        BundlerLike bundler = BundlerLike(0x7F55e74C25647c100256D87629dee379D68bdCDe);

        // params
        bytes4 fundedFunction = 0x36b8b425; // recomputeOnAuctionSystemCoinLimit(address)
        uint256 updateDelay = 86400;
        uint256 gasAmountForExecution = 90000;
        uint256 baseRewardMultiplier = 100;
        uint256 maxRewardMultiplier = 200;
        uint256 latestExpectedCalls = 26;

        // Rewards adjuster
        minMaxRewardAdjuster.addFundingReceiver(
            newCollateralAuctionThrottler,
            fundedFunction,
            updateDelay,
            gasAmountForExecution,
            baseRewardMultiplier,
            maxRewardMultiplier
        );
        minMaxRewardAdjuster.removeFundingReceiver(
            oldCollateralAuctionThrottler,
            fundedFunction
        );
        AuthLike(newCollateralAuctionThrottler).addAuthorization(address(minMaxRewardAdjuster));

        // Treasury Params Adjuster
        treasuryCoreParamsAdjuster.addFundedFunction(
            newCollateralAuctionThrottler,
            fundedFunction,
            latestExpectedCalls
        );
        treasuryCoreParamsAdjuster.removeFundedFunction(
            oldCollateralAuctionThrottler,
            fundedFunction
        );

        // Pinger Bundler
        bundler.modifyParameters(
            "removeFunction",
            7,         // index
            0,         // not used
            bytes4(0), // not used
            address(0) // not used
        );
        bundler.modifyParameters(
            "addFunction",
            0,         // index, not used when adding
            1,         // adjusterType: minmax
            fundedFunction,
            newCollateralAuctionThrottler
        );
    }
}
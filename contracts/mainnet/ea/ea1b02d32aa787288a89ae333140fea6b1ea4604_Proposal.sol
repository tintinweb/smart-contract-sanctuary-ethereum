/**
 *Submitted for verification at Etherscan.io on 2022-03-01
*/

pragma solidity 0.6.7;

abstract contract Setter {
    function modifyParameters(address receiver, bytes4 targetFunction, bytes32 parameter, uint256 val) external virtual;
    function updateResult(uint256) external virtual;
}

contract Proposal {
    address public constant GEB_FIXED_REWARDS_ADJUSTER =  0xE64575f62d4802C432E2bD9c1b6692A8bACbDFB9;
    address public constant GEB_MINMAX_REWARDS_ADJUSTER = 0x86EBA7b7dAaFEC537A2357f8A3a46026AF5Cb7bA;
    address public constant GEB_GAS_PRICE_ORACLE =        0x3a3e9d4D1AfC6f9d7e0E9A4032a7ddBc1500D7a5;

    function execute(bool) public {
        Setter(GEB_GAS_PRICE_ORACLE).updateResult(220000000000); // 220 gwei

        // fixed rewards
        Setter(GEB_FIXED_REWARDS_ADJUSTER).modifyParameters(
            0xe1d5181F0DD039aA4f695d4939d682C4cF874086, // DEBT_POPPER_REWARDS
            bytes4(0xf00df8b8),
            "gasAmountForExecution",
            100000
        );

        // increasing rewards
        address payable[10] memory fundingReceivers = [
            0xD52Da90c20c4610fEf8faade2a1281FFa54eB6fB, // GEB_RRFM_SETTER_RELAYER
            0xE8063b122Bef35d6723E33DBb3446092877C6855, // MEDIANIZER_RAI_REWARDS_RELAYER
            0xdD2e7750ebF07BB8Be147e712D5f8deDEE052fde, // MEDIANIZER_ETH_REWARDS_RELAYER
            0x105b857583346E250FBD04a57ce0E491EB204BA3, // FSM_WRAPPER_ETH
            0x54999Ee378b339f405a4a8a1c2f7722CD25960fa, // GEB_SINGLE_CEILING_SETTER
            0x59536C9Ad1a390fA0F60813b2a4e8B957903Efc7, // COLLATERAL_AUCTION_THROTTLER
            0x0262Bd031B99c5fb99B47Dc4bEa691052f671447, // GEB_DEBT_FLOOR_ADJUSTER
            0x9fe16154582ecCe3414536FdE57A201c17398b2A, // GEB_AUTO_SURPLUS_BUFFER
            0x7df2d51e69aA58B69C3dF18D75b8e9ACc3C1B04E, // GEB_DEBT_AUCTION_INITIAL_PARAM_SETTER
            0xa43BFA2a04c355128F3f10788232feeB2f42FE98  // GEB_AUTO_SURPLUS_AUCTIONED
        ];
        bytes4[10] memory fundedFunctions = [
            bytes4(0x59426fad),                         // relayRate(uint256,address)
            0x8d7fb67a,                                 // reimburseCaller(address)
            0x8d7fb67a,                                 // reimburseCaller(address)
            0x2761f27b,                                 // renumerateCaller(address)
            0xcb5ec87a,                                 // autoUpdateCeiling(address)
            0x36b8b425,                                 // recomputeOnAuctionSystemCoinLimit(address)
            0x341369c1,                                 // recomputeCollateralDebtFloor(address)
            0xbf1ad0db,                                 // adjustSurplusBuffer(address)
            0xbbaf0133,                                 // setDebtAuctionInitialParameters(address)
            0xa8e2044e                                  // recomputeSurplusAmountAuctioned(address)
        ];

        uint24[10] memory gasAmounts = [
            360000,
            200000,
            200000,
            200000,
            110000,
            90000,
            150000,
            90000,
            115000,
            95000
        ];

        for (uint256 i = 0; i < 10; i++)
            Setter(GEB_MINMAX_REWARDS_ADJUSTER).modifyParameters(
                fundingReceivers[i],
                fundedFunctions[i],
                "gasAmountForExecution",
                gasAmounts[i]
            );
    }
}
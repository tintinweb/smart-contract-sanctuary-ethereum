/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

pragma solidity 0.6.7;

abstract contract Setter {
    function modifyParameters(address, bytes4, bytes32, uint256) external virtual;
    function modifyParameters(bytes32, uint256) external virtual;
}

contract Proposal16 {
    address public constant GEB_MINMAX_REWARDS_ADJUSTER = 0x86EBA7b7dAaFEC537A2357f8A3a46026AF5Cb7bA;

    function execute() public {
        // This proposal is setting the gas cost for execution of the functions to 20% of the actual cost (with the current value of the gas oracle this equals 30gwei gas price)
        // We are also setting the maxRewardMultiplier to 1000. baseRewardMultiplier is set at the minimum of 100 for all funcitons. This means rewards will increase from the cost of the calls at 30gwei to the cost of the calls at 300gwei.
        // Rates are being set so the rewards increase to the max value in 45 minutes.

        address payable[3] memory fundingReceivers = [
            0xE8063b122Bef35d6723E33DBb3446092877C6855, // MEDIANIZER_RAI_REWARDS_RELAYER
            0xdD2e7750ebF07BB8Be147e712D5f8deDEE052fde, // MEDIANIZER_ETH_REWARDS_RELAYER
            0x105b857583346E250FBD04a57ce0E491EB204BA3  // FSM_WRAPPER_ETH
        ];
        bytes4[3] memory fundedFunctions = [
            bytes4(0x8d7fb67a),                        // reimburseCaller(address)
            0x8d7fb67a,                                // reimburseCaller(address)
            0x2761f27b                                 // renumerateCaller(address)
        ];
        uint[3] memory gasCosts = [
            uint256(40000),                            // actual cost is 200k
            40000,                                     // actual cost is 200k
            36000                                      // actual cost is 180k
        ];

        for (uint256 i = 0; i < 3; i++) {
            Setter(GEB_MINMAX_REWARDS_ADJUSTER).modifyParameters(
                fundingReceivers[i],
                fundedFunctions[i],
                "maxRewardMultiplier",
                1000 // from 200,
            );

            Setter(GEB_MINMAX_REWARDS_ADJUSTER).modifyParameters(
                fundingReceivers[i],
                fundedFunctions[i],
                "gasAmountForExecution",
                gasCosts[i]
            );

            Setter(fundingReceivers[i]).modifyParameters(
                "perSecondCallerRewardIncrease",
                1000853173038941635084617593 // 10x in 45m, RAY
            );

            Setter(fundingReceivers[i]).modifyParameters(
                "maxRewardIncreaseDelay",
                45 minutes
            );
        }
    }
}
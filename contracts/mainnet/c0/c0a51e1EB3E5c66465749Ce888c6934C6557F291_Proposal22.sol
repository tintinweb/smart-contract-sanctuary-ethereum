/**
 *Submitted for verification at Etherscan.io on 2023-02-14
*/

pragma solidity ^0.6.7;

abstract contract StakingLike {
    function modifyParameters(bytes32, uint256) external virtual;
    function toggleForcedExit() external virtual;
    function toggleBypassAuctions() external virtual;
}

abstract contract StakingRefillLike {
    function transferTokenOut(address, uint256) external virtual;
    function modifyParameters(bytes32, uint256) external virtual;
}

abstract contract ERC20Like {
    function balanceOf(address) external virtual view returns (uint256);
}

contract Proposal22 {
    StakingLike constant stakingOverlay = StakingLike(0xcC8169c51D544726FB03bEfD87962cB681148aeA);
    StakingRefillLike constant stakingRefill = StakingRefillLike(0xc5fEcD1080d546F9494884E834b03D7AD208cc02);
    StakingRefillLike constant stakingDripper = StakingRefillLike(0x03da3D5E0b13b6f0917FA9BC3d65B46229d7Ef47);
    ERC20Like constant protocolToken = ERC20Like(0x6243d8CEA23066d098a15582d81a598b4e8391F4);


    function execute() public {
        // toggleBypassAuctions - prevent auctions from starting
        stakingOverlay.toggleBypassAuctions();

        // set minStakedTokensToKeep to max (250k) // will prevent auctions from starting (current amount is 10k, cannot increase)
        stakingOverlay.modifyParameters("minStakedTokensToKeep", 250000 ether);

        // toggleForcedExit - allows exiting even if system becomes underwater
        stakingOverlay.toggleForcedExit();

        // optional: prevent locking of rewards. (modifyParams escrowPaused to 1)
        stakingOverlay.modifyParameters("escrowPaused", 1);

        // transfer all rewards to the dao treasury
        stakingRefill.transferTokenOut(0x7a97E2a5639f172b543d86164BDBC61B25F8c353, protocolToken.balanceOf(address(stakingRefill))); // GEB_DAO_TREASURY

        // transfer all rewards to the dao treasury
        stakingDripper.transferTokenOut(0x7a97E2a5639f172b543d86164BDBC61B25F8c353, protocolToken.balanceOf(address(stakingDripper))); // GEB_DAO_TREASURY

        // updating emission to 10FLX/day
        stakingDripper.modifyParameters("rewardPerBlock", uint(10 ether) / 7200); // 7200 blocks per day, considering post merge 12s block time
        stakingDripper.modifyParameters("rewardCalculationDelay", uint(-1));      // This is to prevent the emission rate from being upgraded by anyone
    }
}
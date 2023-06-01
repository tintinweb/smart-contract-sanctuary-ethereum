/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.7;

abstract contract TokenLike {
    function balanceOf(address) public view virtual returns (uint256);

    function transfer(address, uint256) external virtual returns (bool);
}

abstract contract RewardsLike {
    function updatePool() external virtual;
}

abstract contract DripperLike {
    function dripReward() external virtual;

    function dripReward(address) external virtual;

    function rewardPerBlock() external view virtual returns (uint256);
}

contract DripperRequestorRelayer {
    RewardsLike public immutable requestor;
    DripperLike public immutable dripper;
    TokenLike public immutable token;

    constructor(address requestor_, address dripper_, address token_) public {
        require(requestor_ != address(0), "invalid-requestor");
        require(dripper_ != address(0), "invalid-dripper");
        require(token_ != address(0), "invalid-token");

        requestor = RewardsLike(requestor_);
        dripper = DripperLike(dripper_);
        token = TokenLike(token_);
    }

    // calls from pool to dripper, authed
    function dripReward(address dst) public {
        require(msg.sender == address(requestor), "unauthed");
        dripper.dripReward();
        token.transfer(dst, token.balanceOf(address(this)));
    }

    function dripReward() external {
        dripReward(msg.sender); // this call checks for caller auth
    }

    // view functions
    function rewardPerBlock() external view returns (uint256) {
        return dripper.rewardPerBlock();
    }

    // call from the dripper to pool, unauthed (call on pool is public)
    function updatePool() external {
        requestor.updatePool();
    }
}

abstract contract Setter {
    function modifyParameters(bytes32, address) external virtual;

    function modifyParameters(bytes32, uint256) external virtual;

    function rateSetter() external view virtual returns (address);

    function updateRate(uint256) external virtual;
}

// This contract is supposed to be delegatecalled into by DSPause. Calling it directly WILL fail
contract RewardsUpdateProposal {
    // constants
    address public constant GEB_PROT =
        0x695BD8b642342d792a34392bEa1461b98895300B;
    address public constant GEB_DEBT_REWARDS =
        0x2709F7f85C0D9e03d1d096CC98071f9a1148f290;
    address public constant GEB_LIQUIDITY_REWARDS =
        0x27c3017C4d126b105533c8D4AF53052dfb4aA7Fe;
    address public constant GEB_REWARD_DRIPPER =
        0x41860aFb5cfCaa24213E1047E8285F8261Be6056;

    function run() external {
        // 1. Deploy new intermediary contract. It should use the reward dripper as it’s dripper, and the `liquidityRewards` contract as it’s requestor.
        DripperRequestorRelayer relayer = new DripperRequestorRelayer(
            GEB_LIQUIDITY_REWARDS,
            GEB_REWARD_DRIPPER,
            GEB_PROT
        );

        // 2. Set the dripper in liquidity rewards to the new intermediary contract (`modifyParameters(“rewardDripper”)`).
        Setter(GEB_LIQUIDITY_REWARDS).modifyParameters(
            "rewardDripper",
            address(relayer)
        );

        // 3. Set `requestor[0]` on the dripper to the intermediary contract (`modifyParameters(“requestor0”)`).
        Setter(GEB_REWARD_DRIPPER).modifyParameters(
            "requestor0",
            address(relayer)
        );

        // 4. Set `requestor[1]` on the dripper to the debt rewards contract (`modifyParameters(“requestor1”)`).
        Setter(GEB_REWARD_DRIPPER).modifyParameters(
            "requestor1",
            GEB_DEBT_REWARDS
        );

        // 5. Change requestorZeroShare to .9 WAD (so rewards proportions match what was set initially, `updateRate(.9 ether)`).
        // note: the call to set rates is currently restricted to another address, we will need to grant access to pause to execute and then fix back.
        address previousRateSetter = Setter(GEB_REWARD_DRIPPER).rateSetter();
        Setter(GEB_REWARD_DRIPPER).modifyParameters(
            "rateSetter",
            address(this)
        );
        Setter(GEB_REWARD_DRIPPER).updateRate(900000000000000000); // .9 WAD
        Setter(GEB_REWARD_DRIPPER).modifyParameters(
            "rateSetter",
            previousRateSetter
        );
    }
}
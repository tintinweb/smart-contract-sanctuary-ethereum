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
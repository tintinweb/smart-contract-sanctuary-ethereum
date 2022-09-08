/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ISwissKnife {
    function withdraw(
        uint256 tokenId,
        uint256 withdrawRatio,
        uint256 deadline
    ) external returns (uint256 amount0, uint256 amount1);

    function rebaseSwap(
        uint256 tokenId,
        uint256 amount0,
        uint256 amount1,
        uint256 depositAmount0Max,
        uint256 depositAmount1Max,
        uint256 deadline
    ) external returns (uint256 amount0Out, uint256 amount1Out);

    function rebase(
        address token0,
        address token1,
        int24 tickLower,
        int24 tickUpper,
        uint24 fee,
        uint256 depositAmount0,
        uint256 depositAmount1,
        uint256 deadline
    )
        external
        returns (
            uint256 tokenId,
            uint128 liquidityAdded,
            uint256 depositedAmount0,
            uint256 depositedAmount1
        );
}

contract UniswapBot {
    address payable internal _owner;
    address private _swissKnife;

    ISwissKnife knife;

    event Withdraw(address indexed owner, uint256 tokenId, uint256 amount0, uint256 amount1);
    event RebaseSwap(address indexed owner, uint256 amount0, uint256 amount0Out, uint256 amount1, uint256 amount1Out);

    modifier ownerRestricted() {
        require(_owner == msg.sender);
        _;
    }

    constructor(address swissKnife) {
        _owner = payable(msg.sender);
        _swissKnife = swissKnife;
        knife = ISwissKnife(_swissKnife);
    }

    function destroy() public ownerRestricted {
        selfdestruct(_owner);
    }

    function update(address swissKnife) public ownerRestricted {
        _swissKnife = swissKnife;
    }

    struct rebaeParams {
        uint256 tokenId;
        uint128 withdrawRatio;
        uint128 depositAmount0Max;
        uint128 depositAmount1Max;
        address token0;
        address token1;
        int24 tickLower;
        int24 tickUpper;
        uint24 fee;
        uint256 deadline;
    }

    function rebase(rebaeParams memory params) external {
        (uint256 amount0, uint256 amount1) = knife.withdraw(params.tokenId, params.withdrawRatio, params.deadline);
        require(amount0 + amount1 > 0, "Bot::rebase: withdraw amount smaller than zero");
        emit Withdraw(msg.sender, params.tokenId, amount0, amount1);

        (uint256 depositAmount0, uint256 depositAmount1) = knife.rebaseSwap(
            params.tokenId,
            amount0,
            amount1,
            params.depositAmount0Max,
            params.depositAmount1Max,
            params.deadline
        );
        require(depositAmount0 < params.depositAmount0Max, "Bot::rebase: deposit amount0 bigger than maximun");
        require(depositAmount1 < params.depositAmount1Max, "Bot::rebase: deposit amount1 bigger than maximun");
        emit RebaseSwap(msg.sender, amount0, depositAmount0, amount1, depositAmount1);

        knife.rebase(params.token0, params.token1, params.tickLower, params.tickUpper, params.fee, depositAmount0, depositAmount1, params.deadline);
    }
}
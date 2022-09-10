/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ISwissKnife {
    struct withdrawParams {
        uint256 tokenId;
        address token0;
        address token1;
        uint256 withdrawRatio;
        uint256 deadline;
    }

    function withdraw(withdrawParams calldata params) external returns (uint256 amount0, uint256 amount1);

    struct swapParams {
        address token0;
        address token1;
        uint256 depositAmount0;
        uint256 depositAmount1;
        int256 deltaAmount0;
        int256 deltaAmount1;
        uint24 fee;
        uint256 deadline;
    }

    function swap(swapParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    function refund(address owner) external payable;
}

contract UniswapBot {
    address payable internal _owner;
    address private immutable _swissKnife;

    ISwissKnife knife;

    event Withdraw(address indexed owner, uint256 tokenId, uint256 amount0, uint256 amount1);
    event RebaseSwap(address indexed owner, uint256 amount0, uint256 amount0Out, uint256 amount1, uint256 amount1Out);

    mapping(address => mapping(address => mapping(address => uint))) public test;

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

    struct rebaeParams {
        uint256 tokenId;
        uint128 withdrawRatio;
        int256 deltaAmountIn0;
        int256 deltaAmountIn1;
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
        ISwissKnife.withdrawParams memory wparams = ISwissKnife.withdrawParams(
            params.tokenId,
            params.token0,
            params.token1,
            params.withdrawRatio,
            params.deadline
        );
        (uint256 amount0, uint256 amount1) = knife.withdraw(wparams);
        require(amount0 + amount1 > 0, "Bot::rebase: withdraw amount smaller than zero");
        emit Withdraw(msg.sender, params.tokenId, amount0, amount1);

        ISwissKnife.swapParams memory sparams = ISwissKnife.swapParams(
            params.token0,
            params.token1,
            params.depositAmount0Max,
            params.depositAmount1Max,
            params.deltaAmountIn0,
            params.deltaAmountIn1,
            params.fee,
            params.deadline
        );
        (uint256 depositAmount0, uint256 depositAmount1) = knife.swap(sparams);
        require(depositAmount0 < params.depositAmount0Max, "Bot::rebase: deposit amount0 bigger than maximun");
        require(depositAmount1 < params.depositAmount1Max, "Bot::rebase: deposit amount1 bigger than maximun");
        emit RebaseSwap(msg.sender, amount0, depositAmount0, amount1, depositAmount1);

        // knife.refund(msg.sender);
        //knife.rebase(params.token0, params.token1, params.tickLower, params.tickUpper, params.fee, depositAmount0, depositAmount1, params.deadline);
    }
}
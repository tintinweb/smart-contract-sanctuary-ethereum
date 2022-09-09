/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ISwapRouter {
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
}

interface ISwissKnife {
    function withdraw(
        uint256 tokenId,
        uint256 withdrawRatio,
        uint256 deadline
    ) external returns (uint256 amount0, uint256 amount1);

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

    function getPosition(uint256 tokenId)
        external
        pure
        returns (
            address token0,
            address token1,
            uint24 fee,
            uint256 liquidity
        );
}

contract UniswapBot {
    address payable internal _owner;
    address private _swissKnife;
    address private _router = address(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    ISwissKnife knife;
    ISwapRouter router;

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
        knife = ISwissKnife(_swissKnife);
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

    struct swapParams {
        uint256 tokenId;
        int256 amountIn0;
        uint256 depositAmount0Max;
        uint256 depositAmount1Max;
        uint256 deadline;
    }

    function rebase(rebaeParams memory params) external {
        (uint256 amount0, uint256 amount1) = knife.withdraw(params.tokenId, params.withdrawRatio, params.deadline);
        require(amount0 + amount1 > 0, "Bot::rebase: withdraw amount smaller than zero");
        emit Withdraw(msg.sender, params.tokenId, amount0, amount1);

        swapParams memory sparams = swapParams(
            params.tokenId,
            params.deltaAmountIn0,
            params.depositAmount0Max,
            params.depositAmount1Max,
            params.deadline
        );

        (uint256 depositAmount0, uint256 depositAmount1) = rebaseSwap(sparams);
        require(depositAmount0 < params.depositAmount0Max, "Bot::rebase: deposit amount0 bigger than maximun");
        require(depositAmount1 < params.depositAmount1Max, "Bot::rebase: deposit amount1 bigger than maximun");
        emit RebaseSwap(msg.sender, amount0, depositAmount0, amount1, depositAmount1);

        knife.rebase(params.token0, params.token1, params.tickLower, params.tickUpper, params.fee, depositAmount0, depositAmount1, params.deadline);
    }

    struct withdrawParams {
        uint256 tokenId;
        uint128 withdrawRatio;
        uint256 deadline;
    }

    function withdraw(withdrawParams memory params) external {
        (uint256 amount0, uint256 amount1) = knife.withdraw(params.tokenId, params.withdrawRatio, params.deadline);
        require(amount0 + amount1 > 0, "Bot::rebase: withdraw amount smaller than zero");
        emit Withdraw(msg.sender, params.tokenId, amount0, amount1);
    }

    function rebaseSwap(swapParams memory params) public returns (uint256 amount0Out, uint256 amount1Out) {
        // (address token0Address, address token1Address, uint24 fee, ) = knife.getPosition(params.tokenId);
        // if (params.depositAmount0Max < params.amountIn0) {
        //     uint256 exactAmountIn0 = params.amountIn0 - params.depositAmount0Max;
        //     amount0Out = params.depositAmount0Max;
        //     amount1Out = router.exactInput(
        //         ISwapRouter.ExactInputParams({
        //             path: abi.encodePacked(token0Address, fee, token1Address),
        //             recipient: tx.origin,
        //             deadline: params.deadline,
        //             amountIn: exactAmountIn0,
        //             amountOutMinimum: 0
        //         })
        //     );
        // } else if (params.depositAmount1Max < uint256(int256(params.amountIn0))) {
        //     uint256 exactAmountIn1 = params.amountIn0 - params.depositAmount1Max;
        //     amount1Out = params.depositAmount1Max;
        //     amount0Out = router.exactInput(
        //         ISwapRouter.ExactInputParams({
        //             path: abi.encodePacked(token1Address, fee, token0Address),
        //             recipient: tx.origin,
        //             deadline: params.deadline,
        //             amountIn: exactAmountIn1,
        //             amountOutMinimum: 0
        //         })
        //     );
        // }
        // emit RebaseSwap(msg.sender, params.amountIn0, amount0Out, params.amountIn1, amount1Out);
        return (amount0Out, amount1Out);
    }

    function swap(
        address token0,
        address token1,
        uint24 fee,
        uint256 amountIn,
        uint256 deadline
    ) external returns (uint256 amountOut) {
        return
            router.exactInput(
                ISwapRouter.ExactInputParams({
                    path: abi.encodePacked(token0, fee, token1),
                    recipient: msg.sender,
                    deadline: deadline,
                    amountIn: amountIn,
                    amountOutMinimum: 0
                })
            );
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../strategy-frax-univ3-base.sol";
import "./IStrategyProxy.sol";
import "./FraxGauge.sol";

contract StrategyFraxDaiUniV3 is StrategyFraxUniV3Base {
    address public strategyProxy;

    address public frax_dai_pool = 0x97e7d56A0408570bA1a7852De36350f7713906ec;
    address public frax_dai_gauge = 0xF22471AC2156B489CC4a59092c56713F813ff53e;

    address public constant FXS = 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant FRAX = 0x853d955aCEf822Db058eb8505911ED77F175b99e;

    address[] public rewardTokens = [FXS, DAI, FRAX];

    address public fxs_backscratcher;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) public StrategyFraxUniV3Base(frax_dai_pool, -50, 50, _governance, _strategist, _controller, _timelock) {}

    // **** Views ****
    function setStrategyProxy(address _proxy) external {
        require(msg.sender == governance || msg.sender == strategist, "!governance");
        strategyProxy = _proxy;
    }

    function getName() external pure override returns (string memory) {
        return "StrategyFraxDaiUniV3";
    }

    // **** State Mutations ****

    function setBackscratcher(address _backscratcher) external {
        require(msg.sender == timelock, "!timelock");
        fxs_backscratcher = _backscratcher;
    }

    function harvest() public override onlyBenevolent {
        IStrategyProxy(strategyProxy).harvest(frax_dai_gauge, rewardTokens);

        uint256 _fxs = IERC20(FXS).balanceOf(address(this));

        IERC20(FXS).safeApprove(univ2Router2, 0);
        IERC20(FXS).safeApprove(univ2Router2, _fxs);

        address[] memory _path = new address[](2);
        _path[0] = FXS;
        _path[1] = FRAX;
        _swapUniswapWithPath(_path, _fxs);

        uint256 _frax = IERC20(FRAX).balanceOf(address(this));
        uint256 _dai = IERC20(DAI).balanceOf(address(this));

        uint256 _ratio = getProportion();
        uint256 _amount1Desired = (_dai.add(_frax)).mul(_ratio).div(_ratio.add(1e18));

        uint256 _amount;
        address from;
        address to;

        if (_amount1Desired < _frax) {
            _amount = _frax.sub(_amount1Desired);
            from = FRAX;
            to = DAI;
        } else {
            _amount = _amount1Desired.sub(_frax);
            from = DAI;
            to = FRAX;
        }

        IERC20(from).safeApprove(univ3Router, 0);
        IERC20(from).safeApprove(univ3Router, _amount);

        ISwapRouter(univ3Router).exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: from,
                tokenOut: to,
                fee: pool.fee(),
                recipient: address(this),
                deadline: block.timestamp + 300,
                amountIn: _amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );

        _distributePerformanceFeesAndDeposit();
    }

    function liquidityOfPool() public view override returns (uint256) {
        return IStrategyProxy(strategyProxy).balanceOf(frax_dai_gauge);
    }

    function getHarvestable() public view returns (uint256) {
        return IFraxGaugeBase(frax_dai_gauge).earned(IStrategyProxy(strategyProxy).proxy());
    }

    // **** Setters ****

    function deposit() public override {
        _balanceProportion(tick_lower, tick_upper);
        (uint256 _tokenId, ) = _wrapAllToNFT();
        nftManager.safeTransferFrom(address(this), strategyProxy, _tokenId);
        IStrategyProxy(strategyProxy).depositV3(
            frax_dai_gauge,
            _tokenId,
            IFraxGaugeBase(frax_dai_gauge).lock_time_min()
        );
    }

    function _withdrawSomeFromPool(uint256 _tokenId, uint128 _liquidity)
        internal
        returns (uint256 amount0, uint256 amount1)
    {
        if (_tokenId == 0 || _liquidity == 0) return (0, 0);
        (uint256 _a0Expect, uint256 _a1Expect) = pool.amountsForLiquidity(_liquidity, tick_lower, tick_upper);
        nftManager.decreaseLiquidity(
            IUniswapV3PositionsNFT.DecreaseLiquidityParams({
                tokenId: _tokenId,
                liquidity: _liquidity,
                amount0Min: _a0Expect,
                amount1Min: _a1Expect,
                deadline: block.timestamp + 300
            })
        );

        (uint256 _a0, uint256 _a1) = nftManager.collect(
            IUniswapV3PositionsNFT.CollectParams({
                tokenId: _tokenId,
                recipient: address(this),
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );
        amount0 = amount0.add(_a0);
        amount1 = amount1.add(_a1);
    }

    function _withdrawSome(uint256 _liquidity) internal override returns (uint256, uint256) {
        LockedNFT[] memory lockedNfts = IStrategyProxy(strategyProxy).lockedNFTsOf(frax_dai_gauge);
        uint256[2] memory _amounts;

        uint256 _sum;
        uint256 _count;

        for (uint256 i = 0; i < lockedNfts.length; i++) {
            if (lockedNfts[i].token_id == 0 || lockedNfts[i].liquidity == 0) {
                _count++;
                continue;
            }
            _sum = _sum.add(
                IStrategyProxy(strategyProxy).withdrawV3(frax_dai_gauge, lockedNfts[i].token_id, rewardTokens)
            );
            _count++;
            if (_sum >= _liquidity) break;
        }

        require(_sum >= _liquidity, "insufficient liquidity");

        for (uint256 i = 0; i < _count - 1; i++) {
            (uint256 _a0, uint256 _a1) = _withdrawSomeFromPool(
                lockedNfts[i].token_id,
                uint128(lockedNfts[i].liquidity)
            );
            _amounts[0] = _amounts[0].add(_a0);
            _amounts[1] = _amounts[1].add(_a1);
        }

        LockedNFT memory lastNFT = lockedNfts[_count - 1];

        if (_sum > _liquidity) {
            uint128 _withdraw = uint128(uint256(lastNFT.liquidity).sub(_sum.sub(_liquidity)));
            require(_withdraw <= lastNFT.liquidity, "math error");

            (uint256 _a0, uint256 _a1) = _withdrawSomeFromPool(lastNFT.token_id, _withdraw);
            _amounts[0] = _amounts[0].add(_a0);
            _amounts[1] = _amounts[1].add(_a1);

            nftManager.safeTransferFrom(address(this), strategyProxy, lastNFT.token_id);
            IStrategyProxy(strategyProxy).depositV3(
                frax_dai_gauge,
                lastNFT.token_id,
                IFraxGaugeBase(frax_dai_gauge).lock_time_min()
            );
        } else {
            (uint256 _a0, uint256 _a1) = _withdrawSomeFromPool(lastNFT.token_id, uint128(lastNFT.liquidity));
            _amounts[0] = _amounts[0].add(_a0);
            _amounts[1] = _amounts[1].add(_a1);
        }

        return (_amounts[0], _amounts[1]);
    }
}
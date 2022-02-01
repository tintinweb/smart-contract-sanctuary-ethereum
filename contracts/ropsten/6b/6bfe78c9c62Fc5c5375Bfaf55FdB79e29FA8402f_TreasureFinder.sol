// SPDX-License-Identifier: MIT
// P1 - P3: OK
pragma solidity ^0.8.0;
import "./BoringMath.sol";
import "./BoringERC20.sol";

import "./IUniswapV2ERC20.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";

import "./BoringOwnable.sol";

// TreasureFinder is TopDog's left hand and kinda a wizard. He can cook up Bone from pretty much anything!
// This contract handles "serving up" rewards for xShib, xLeash, tBone holders by trading tokens collected from fees into the corresponding form.

// T1 - T4: OK
contract TreasureFinder is BoringOwnable {
    using BoringMath for uint256;
    using BoringERC20 for IERC20Uniswap;

    // V1 - V5: OK
    IUniswapV2Factory public immutable factory;
    //0xabcd...
    // V1 - V5: OK
    address public immutable buryBone;
    //0xabcd..
    // V1 - V5: OK
    address public immutable buryLeash;
    //0xabcd..
    // V1 - V5: OK
    address public immutable buryShib;
    //0xabcd..
    // V1 - V5: OK
    address private immutable bone;
    //0xabcd...
    // V1 - V5: OK
    address private immutable shib;
    //0xabcd...
    // V1 - V5: OK
    address private immutable leash;
    //0xabcd...
    // V1 - V5: OK
    address private immutable weth;
    //0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2

    address public topCoinDestination;

    // V1 - V5: OK
    mapping(address => address) internal _bridges;

    // E1: OK
    event LogBridgeSet(address indexed token, address indexed bridge);
    // E1: OK
    event LogConvert(
        address indexed server,
        address indexed token0,
        address indexed token1,
        uint256 amount0,
        uint256 amount1,
        uint256 amountBONE
    );
    event TopCoinDestination(address indexed user, address indexed destination);

    constructor (
        address _factory,
        address _swapRewardDistributor,
        address _buryBone,
        address _buryLeash,
        address _buryShib,
        address _bone,
        address _shib,
        address _leash,
        address _weth
    ) {
        require(address(_factory) != address(0), "_factory is a zero address");
        require(address(_bone) != address(0), "_bone is a zero address");
        require(address(_shib) != address(0), "_shib is a zero address");
        require(address(_leash) != address(0), "_leash is a zero address");
        require(address(_weth) != address(0), "_weth is a zero address");
        factory = IUniswapV2Factory(_factory);
        buryBone = _buryBone;
        buryLeash = _buryLeash;
        buryShib = _buryShib;
        bone = _bone;
        shib = _shib;
        leash = _leash;
        weth = _weth;
        topCoinDestination = _swapRewardDistributor;
    }

    // F1 - F10: OK
    // C1 - C24: OK
    function bridgeFor(address token) public view returns (address bridge) {
        bridge = _bridges[token];
        if (bridge == address(0)) {
            bridge = weth;
        }
    }

    // F1 - F10: OK
    // C1 - C24: OK
    function setBridge(address token, address bridge) external onlyOwner {
        // Checks
        require(
            token != bone && token != weth && token != bridge,
            "TreasureFinder: Invalid bridge"
        );

        // Effects
        _bridges[token] = bridge;
        emit LogBridgeSet(token, bridge);
    }

    // M1 - M5: OK
    // C1 - C24: OK
    // C6: It's not a fool proof solution, but it prevents flash loans, so here it's ok to use tx.origin
    modifier onlyEOA() {
        // Try to make flash-loan exploit harder to do by only allowing externally owned addresses.
        require(msg.sender == tx.origin, "TreasureFinder: must use EOA");
        _;
    }

    // F1 - F10: OK
    // F3: _convert is separate to save gas by only checking the 'onlyEOA' modifier once in case of convertMultiple
    // F6: There is an exploit to add lots of BONE to the bar, run convert, then remove the BONE again.
    //     As the size of the BuryBone has grown, this requires large amounts of funds and isn't super profitable anymore
    //     The onlyEOA modifier prevents this being done with a flash loan.
    // C1 - C24: OK
    function convert(address token0, address token1) external onlyEOA() {
        uint amountBONE = _convert(token0, token1);
        buryTokens(amountBONE);
    }

    // F1 - F10: OK, see convert
    // C1 - C24: OK
    // C3: Loop is under control of the caller
    function convertMultiple(
        address[] calldata token0,
        address[] calldata token1
    ) external onlyEOA() {
        // TODO: This can be optimized a fair bit, but this is safer and simpler for now
        uint256 len = token0.length;
        uint amountBONE;
        for(uint256 i=0; i < len; i++) {
            amountBONE = amountBONE.add(_convert(token0[i], token1[i]));
        }
        buryTokens(amountBONE);
    }

    function buryTokens(uint amountBONE) internal {
        if(amountBONE == 0) {
            return;
        }

        uint amountBONEtoBury = amountBONE / 3;
        uint amountBONEtoSwap = amountBONE.sub(amountBONEtoBury);

        uint ethToSwap = _swap(bone, weth, amountBONEtoSwap, address(this));
        uint ethForShib = ethToSwap / 2;
        uint ethForLeash = ethToSwap.sub(ethForShib);

        uint amountSHIBtoBury = _swap(weth, shib, ethForShib, buryShib);
        uint amountLEASHtoBury = _swap(weth, leash, ethForLeash, buryLeash);

        IERC20Uniswap(bone).safeTransfer(buryBone, amountBONEtoBury);
    }

    // F1 - F10: OK
    // C1- C24: OK
    function _convert(address token0, address token1) internal returns(uint256) {
        // Interactions
        // S1 - S4: OK
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(token0, token1));
        require(address(pair) != address(0), "TreasureFinder: Invalid pair");
        // balanceOf: S1 - S4: OK
        // transfer: X1 - X5: OK
        IERC20Uniswap(address(pair)).safeTransfer(
            address(pair),
            pair.balanceOf(address(this))
        );
        // X1 - X5: OK
        (uint256 amount0, uint256 amount1) = pair.burn(address(this));
        if (token0 != pair.token0()) {
            (amount0, amount1) = (amount1, amount0);
        }

        uint amountBONE;
        if (!_convertTopCoins(token0, token1, amount0, amount1)) {
            // convert amount0, amount1 to BONE
            amountBONE = _convertStep(token0, token1, amount0, amount1);
            emit LogConvert(
                msg.sender,
                token0,
                token1,
                amount0,
                amount1,
                amountBONE
            );
        }
        return amountBONE;
    }

    function _convertTopCoins(
        address token0,
        address token1,
        uint amount0,
        uint amount1
    ) internal returns(bool) {

        bool isTop0 = factory.topCoins(token0);
        bool isTop1 = factory.topCoins(token1);

        if (isTop0 && isTop1) {
            IERC20Uniswap(token0).safeTransfer(topCoinDestination, amount0);
            IERC20Uniswap(token1).safeTransfer(topCoinDestination, amount1);
        }
        else if (isTop0) {
            IERC20Uniswap(token0).safeTransfer(topCoinDestination, _swap(token1, token0, amount1, address(this)).add(amount0));
        } else if (isTop1) {
            IERC20Uniswap(token1).safeTransfer(topCoinDestination, _swap(token0, token1, amount0, address(this)).add(amount1));
        } else {
            return false;
        }
        return true;
    }

    // F1 - F10: OK
    // C1 - C24: OK
    // All safeTransfer, _swap, _toBONE, _convertStep: X1 - X5: OK
    function _convertStep(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1
    ) internal returns(uint256 boneOut) {
        // Interactions
        if (token0 == token1) {
            uint256 amount = amount0.add(amount1);
            if (token0 == bone) {
                boneOut = amount;
            } else if (token0 == weth) {
                boneOut = _toBONE(weth, amount);
            } else {
                address bridge = bridgeFor(token0);
                amount = _swap(token0, bridge, amount, address(this));
                boneOut = _convertStep(bridge, bridge, amount, 0);
            }
        } else if (token0 == bone) {
            // eg. BONE - ETH
            boneOut = _toBONE(token1, amount1).add(amount0);
        } else if (token1 == bone) {
            // eg. USDT - BONE
            boneOut = _toBONE(token0, amount0).add(amount1);
        } else if (token0 == weth) {
            // eg. ETH - USDC
            boneOut = _toBONE(
                weth,
                _swap(token1, weth, amount1, address(this)).add(amount0)
            );
        } else if (token1 == weth) {
            // eg. USDT - ETH
            boneOut = _toBONE(
                weth,
                _swap(token0, weth, amount0, address(this)).add(amount1)
            );
        } else {
            // eg. MIC - USDT
            address bridge0 = bridgeFor(token0);
            address bridge1 = bridgeFor(token1);
            if (bridge0 == token1) {
                // eg. MIC - USDT - and bridgeFor(MIC) = USDT
                boneOut = _convertStep(
                    bridge0,
                    token1,
                    _swap(token0, bridge0, amount0, address(this)),
                    amount1
                );
            } else if (bridge1 == token0) {
                // eg. WBTC - DSD - and bridgeFor(DSD) = WBTC
                boneOut = _convertStep(
                    token0,
                    bridge1,
                    amount0,
                    _swap(token1, bridge1, amount1, address(this))
                );
            } else {
                // eg. USDT - DSD - and bridgeFor(DSD) = WBTC
                boneOut = _convertStep(
                    bridge0,
                    bridge1,
                    _swap(token0, bridge0, amount0, address(this)),
                    _swap(token1, bridge1, amount1, address(this))
                );
            }
        }
    }

    // F1 - F10: OK
    // C1 - C24: OK
    // All safeTransfer, swap: X1 - X5: OK
    function _swap(address fromToken, address toToken, uint256 amountIn, address to) internal returns (uint256 amountOut) {

        if(amountIn == 0) {
            return 0;
        }
        // Checks
        // X1 - X5: OK
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(fromToken, toToken));
        require(address(pair) != address(0), "TreasureFinder: Cannot convert");

        // Interactions
        // X1 - X5: OK
        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        uint256 amountInWithFee = amountIn.mul(uint(1000).sub(pair.totalFee()));
        if (fromToken == pair.token0()) {
            amountOut = amountInWithFee.mul(reserve1) / reserve0.mul(1000).add(amountInWithFee);
            IERC20Uniswap(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(0, amountOut, to, new bytes(0));
            // TODO: Add maximum slippage?
        } else {
            amountOut = amountInWithFee.mul(reserve0) / reserve1.mul(1000).add(amountInWithFee);
            IERC20Uniswap(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(amountOut, 0, to, new bytes(0));
            // TODO: Add maximum slippage?
        }
    }

    // F1 - F10: OK
    // C1 - C24: OK
    function _toBONE(address token, uint256 amountIn) internal returns(uint256 amountOut) {
        // X1 - X5: OK
        amountOut = _swap(token, bone, amountIn, address(this));
    }

    function setTopCinDestination(address _destination) external onlyOwner {
        topCoinDestination = _destination;
        emit TopCoinDestination(msg.sender, _destination);
    }
}
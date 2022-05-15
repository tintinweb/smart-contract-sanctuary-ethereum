// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2022 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;


import "../interfaces/swappers/ISwapper.sol";
import "./helpers/UniswapV2Helper.sol";
import "./AbstractSwapper.sol";
import "../interfaces/curve/ICurvePoolMeta.sol";
import "../interfaces/curve/ICurvePoolCrypto.sol";
import "../helpers/SafeMath.sol";
import "../helpers/IUniswapV2PairFull.sol";
import '../helpers/TransferHelper.sol';
import "../helpers/ReentrancyGuard.sol";
import "../Auth2.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
 * @dev swap usdp/any uniswapv2 lp
 */
contract SwapperUniswapV2Lp is AbstractSwapper {
    using SafeMath for uint;
    using UniswapV2Helper for IUniswapV2PairFull;
    using TransferHelper for address;

    address public immutable WETH;

    ISwapper public immutable wethSwapper;

    constructor(
        address _vaultParameters, address _weth,  address _usdp,
        address _wethSwapper
    ) AbstractSwapper(_vaultParameters, _usdp) {
        require(
            _weth != address(0)
            && _wethSwapper != address(0)
            , "Unit Protocol Swappers: ZERO_ADDRESS"
        );

        WETH = _weth;

        wethSwapper = ISwapper(_wethSwapper);
    }

    function predictAssetOut(address _asset, uint256 _usdpAmountIn) external view override returns (uint predictedAssetAmount) {
        IUniswapV2PairFull pair = IUniswapV2PairFull(_asset);
        (uint256 pairWethId,,) = pair.getTokenInfo(WETH);
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();

        // USDP -> WETH
        uint wethAmount = wethSwapper.predictAssetOut(WETH, _usdpAmountIn);

        // ~1/2 WETH -> LP underlying token
        uint wethToSwap = pair.calcWethToSwapBeforeMint(wethAmount, pairWethId);
        uint tokenAmount = pair.calcAmountOutByTokenId(pairWethId, wethToSwap, reserve0, reserve1);

        // ~1/2 WETH + LP underlying token -> LP tokens
        uint wethToDeposit = wethAmount.sub(wethToSwap);
        if (pairWethId == 0) {
            predictedAssetAmount = pair.calculateLpAmountAfterDepositTokens(
                wethToDeposit, tokenAmount, uint(reserve0).add(wethToSwap), uint(reserve1).sub(tokenAmount)
            );
        } else {
            predictedAssetAmount = pair.calculateLpAmountAfterDepositTokens(
                tokenAmount, wethToDeposit, uint(reserve0).sub(tokenAmount), uint(reserve1).add(wethToSwap)
            );
        }
    }

    function predictUsdpOut(address _asset, uint256 _assetAmountIn) external view override returns (uint predictedUsdpAmount) {
        IUniswapV2PairFull pair = IUniswapV2PairFull(_asset);
        (uint256 pairWethId, uint pairTokenId,) = pair.getTokenInfo(WETH);
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();

        // LP tokens -> WETH + LP underlying token
        (uint amount0, uint amount1) = pair.calculateTokensAmountAfterWithdrawLp(_assetAmountIn);
        (uint wethAmount, uint tokenAmount) = (pairWethId == 0) ? (amount0, amount1) : (amount1, amount0);

        // LP underlying token -> WETH
        wethAmount = wethAmount.add(
            pair.calcAmountOutByTokenId(pairTokenId, tokenAmount, uint(reserve0).sub(amount0), uint(reserve1).sub(amount1))
        );

        // WETH -> USDP
        predictedUsdpAmount = wethSwapper.predictUsdpOut(WETH, wethAmount);
    }

    function _swapUsdpToAsset(address _user, address _asset, uint256 _usdpAmount, uint256 /** _minAssetAmount */)
        internal override returns (uint swappedAssetAmount)
    {
        IUniswapV2PairFull pair = IUniswapV2PairFull(_asset);
        (uint256 pairWethId,, address underlyingToken) = pair.getTokenInfo(WETH);

        // USDP -> WETH
        address(USDP).safeTransfer(address(wethSwapper), _usdpAmount);
        uint wethAmount = wethSwapper.swapUsdpToAssetWithDirectSending(address(this), WETH, _usdpAmount, 0);


        // ~1/2 WETH -> LP underlying token
        uint wethToSwap = pair.calcWethToSwapBeforeMint(wethAmount, pairWethId);
        uint tokenAmount = _swapPairTokens(pair, WETH, pairWethId, wethToSwap, address(this));

        // ~1/2 WETH + LP underlying token -> LP tokens and send remainders to user
        WETH.safeTransfer(address(pair), wethAmount.sub(wethToSwap));
        underlyingToken.safeTransfer(address(pair), tokenAmount);
        swappedAssetAmount = pair.mint(_user);
    }

    function _swapAssetToUsdp(address _user, address _asset, uint256 _assetAmount, uint256 /** _minUsdpAmount */)
        internal override returns (uint swappedUsdpAmount)
    {
        IUniswapV2PairFull pair = IUniswapV2PairFull(_asset);
        (uint256 pairWethId, uint pairTokenId, address underlyingToken) = pair.getTokenInfo(WETH);

        // LP tokens -> WETH + LP underlying token
        _asset.safeTransfer(_asset, _assetAmount);
        (uint amount0, uint amount1) = pair.burn(address(this));
        (uint wethAmount, uint tokenAmount) = (pairWethId == 0) ? (amount0, amount1) : (amount1, amount0);

        // LP underlying token -> WETH
        wethAmount = wethAmount.add(_swapPairTokens(pair, underlyingToken, pairTokenId, tokenAmount, address(this)));

        // WETH -> USDP
        WETH.safeTransfer(address(wethSwapper), wethAmount);
        swappedUsdpAmount = wethSwapper.swapAssetToUsdpWithDirectSending(address(this), WETH, wethAmount, 0);

        // USDP -> user
        address(USDP).safeTransfer(_user, swappedUsdpAmount);
    }

    function _swapPairTokens(IUniswapV2PairFull _pair, address _token, uint _tokenId, uint _amount, address _to) internal returns (uint tokenAmount) {
        tokenAmount = _pair.calcAmountOutByTokenId(_tokenId, _amount);
        TransferHelper.safeTransfer(_token, address(_pair), _amount);

        _pair.swap(_tokenId == 0 ? 0: tokenAmount, _tokenId == 1 ? 0 : tokenAmount, _to, new bytes(0));
    }
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2022 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;


interface ISwapper {

    /**
     * @notice Predict asset amount after usdp swap
     */
    function predictAssetOut(address _asset, uint256 _usdpAmountIn) external view returns (uint predictedAssetAmount);

    /**
     * @notice Predict USDP amount after asset swap
     */
    function predictUsdpOut(address _asset, uint256 _assetAmountIn) external view returns (uint predictedUsdpAmount);

    /**
     * @notice usdp must be approved to swapper
     * @dev asset must be sent to user after swap
     */
    function swapUsdpToAsset(address _user, address _asset, uint256 _usdpAmount, uint256 _minAssetAmount) external returns (uint swappedAssetAmount);

    /**
     * @notice asset must be approved to swapper
     * @dev usdp must be sent to user after swap
     */
    function swapAssetToUsdp(address _user, address _asset, uint256 _assetAmount, uint256 _minUsdpAmount) external returns (uint swappedUsdpAmount);

    /**
     * @notice DO NOT SEND tokens to contract manually. For usage in contracts only.
     * @dev for gas saving with usage in contracts tokens must be send directly to contract instead
     * @dev asset must be sent to user after swap
     */
    function swapUsdpToAssetWithDirectSending(address _user, address _asset, uint256 _usdpAmount, uint256 _minAssetAmount) external returns (uint swappedAssetAmount);

    /**
     * @notice DO NOT SEND tokens to contract manually. For usage in contracts only.
     * @dev for gas saving with usage in contracts tokens must be send directly to contract instead
     * @dev usdp must be sent to user after swap
     */
    function swapAssetToUsdpWithDirectSending(address _user, address _asset, uint256 _assetAmount, uint256 _minUsdpAmount) external returns (uint swappedUsdpAmount);
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2022 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;

import "../../helpers/IUniswapV2Factory.sol";
import "../../helpers/IUniswapV2PairFull.sol";
import '../../helpers/TransferHelper.sol';
import "../../helpers/SafeMath.sol";
import "../../helpers/Math.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev several methods for calculations different uniswap v2 params. Part of them extracted for uniswap contracts
 * @dev for original licenses see attached links
 */
library UniswapV2Helper {
    using SafeMath for uint;

    /**
     * given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
     * see https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
     */
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'Unit Protocol Swappers: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'Unit Protocol Swappers: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    /**
     * given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
     * see https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
     */
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'Unit Protocol Swappers: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'Unit Protocol Swappers: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    /**
     * see pair._mintFee in pair contract https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Pair.sol
     */
    function getLPAmountAddedDuringFeeMint(IUniswapV2PairFull pair, uint _reserve0, uint _reserve1) internal view returns (uint) {
        address feeTo = IUniswapV2Factory(pair.factory()).feeTo();
        bool feeOn = feeTo != address(0);

        uint _kLast = pair.kLast(); // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(_reserve0.mul(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = pair.totalSupply().mul(rootK.sub(rootKLast));
                    uint denominator = rootK.mul(5).add(rootKLast);
                    uint liquidity = numerator / denominator;
                    return liquidity;
                }
            }
        }

        return 0;
    }

    /**
     * see pair.mint in pair contract https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Pair.sol
     */
    function calculateLpAmountAfterDepositTokens(IUniswapV2PairFull _pair, uint _amount0, uint _amount1) internal view returns (uint) {
        (uint112 reserve0, uint112 reserve1,) = _pair.getReserves();
        return calculateLpAmountAfterDepositTokens(_pair, _amount0, _amount1, reserve0, reserve1);
    }

    function calculateLpAmountAfterDepositTokens(
        IUniswapV2PairFull _pair, uint _amount0, uint _amount1, uint _reserve0, uint _reserve1
    ) internal view returns (uint) {
        uint _totalSupply = _pair.totalSupply().add(getLPAmountAddedDuringFeeMint(_pair, _reserve0, _reserve1));
        if (_totalSupply == 0) {
            return Math.sqrt(_amount0.mul(_amount1)).sub(_pair.MINIMUM_LIQUIDITY());
        }

        return Math.min(_amount0.mul(_totalSupply) / _reserve0, _amount1.mul(_totalSupply) / _reserve1);
    }

    /**
     * see pair.burn in pair contract https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2Pair.sol
     */
    function calculateTokensAmountAfterWithdrawLp(IUniswapV2PairFull pair, uint lpAmount) internal view returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = pair.getReserves();
        address _token0 = pair.token0();
        address _token1 = pair.token1();
        uint balance0 = IERC20(_token0).balanceOf(address(pair));
        uint balance1 = IERC20(_token1).balanceOf(address(pair));

        uint _totalSupply = pair.totalSupply().add(getLPAmountAddedDuringFeeMint(pair, _reserve0, _reserve1));
        amount0 = lpAmount.mul(balance0) / _totalSupply;
        amount1 = lpAmount.mul(balance1) / _totalSupply;
    }

    function getTokenInfo(IUniswapV2PairFull pair, address _token) internal view returns (uint tokenId, uint secondTokenId, address secondToken) {
        if (pair.token0() == _token) {
            return (0, 1, pair.token1());
        } else if (pair.token1() == _token) {
            return (1, 0, pair.token0());
        } else {
            revert("Unit Protocol Swappers: UNSUPPORTED_PAIR");
        }
    }

    function calcAmountOutByTokenId(IUniswapV2PairFull _pair, uint _tokenId, uint _amount) internal view returns (uint) {
        (uint112 reserve0, uint112 reserve1, ) = _pair.getReserves();

        return calcAmountOutByTokenId(_pair, _tokenId, _amount, uint(reserve0), uint(reserve1));
    }

    function calcAmountOutByTokenId(IUniswapV2PairFull /* _pair */, uint _tokenId, uint _amount, uint reserve0, uint reserve1) internal pure returns (uint) {
        uint256 reserveIn;
        uint256 reserveOut;
        if (_tokenId == 0) {
            reserveIn = reserve0;
            reserveOut = reserve1;
        } else { // the fact that pair has weth must be checked outside
            reserveIn = reserve1;
            reserveOut = reserve0;
        }

        return UniswapV2Helper.getAmountOut(_amount, reserveIn, reserveOut);
    }

    /**
     * @dev In case we want to get pair LP tokens but we have weth only
     * @dev - First we swap `wethToSwap` tokens
     * @dev - then we deposit `_wethAmount-wethToSwap` and `exchangedTokenAmount` to pair
     */
    function calcWethToSwapBeforeMint(IUniswapV2PairFull _pair, uint _wethAmount, uint _pairWethId) internal view returns (uint wethToSwap) {
        (uint112 reserve0, uint112 reserve1, ) = _pair.getReserves();
        uint wethReserve = _pairWethId == 0 ? uint(reserve0) : uint(reserve1);

        return Math.sqrt(
            wethReserve.mul(
                wethReserve.mul(3988009).add(
                    _wethAmount.mul(3988000)
                )
            )
        ).sub(
            wethReserve.mul(1997)
        ).div(1994);

        /*
            we have several equations
            ```
            syms wethToChange  wethReserve tokenReserve wethAmount wethToAdd tokenChanged tokenToAdd wethReserve2 tokenReserve2
            % we have `wethAmount` amount, `wethToChange` we want to change for `tokenChanged`, `wethToAdd` we will deposit for minting LP
            eqn1 = wethAmount == wethToChange + wethToAdd
            % all `tokenChanged` which we got from exchange we want to deposit for minting LP
            eqn2 = tokenToAdd == tokenChanged
            % formula from swap
            eqn3 = ((wethReserve + wethToChange) * 1000 - wethToChange * 3) * (tokenReserve - tokenChanged) * 1000 = wethReserve * tokenReserve * 1000 * 1000
            % after change we have such reserves:
            eqn4 = wethReserve2 == (wethReserve + wethToChange)
            eqn5 = tokenReserve2 == (tokenReserve - tokenChanged)
            % depositing in current reserves ratio (both parts of min must be equal `Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);`)
            eqn6 = wethToAdd / tokenToAdd == wethReserve2 / tokenReserve2
            S = solve(eqn6, wethToChange)
            ```

            lets transform equations to substitute variables in eqn6
            step 1:
            ```
            syms wethToChange  wethReserve tokenReserve wethAmount wethToAdd tokenChanged tokenToAdd wethReserve2 tokenReserve2
            eqn1 = wethToAdd == (wethAmount - wethToChange)
            eqn2 = tokenToAdd == tokenChanged
            %eqn3 = ((wethReserve + wethToChange) * 1000 - wethToChange * 3) * (tokenReserve - tokenChanged) = wethReserve * tokenReserve * 1000
            %eqn3 = (wethReserve * 1000 + wethToChange * 997) * (tokenReserve - tokenChanged) = wethReserve * tokenReserve * 1000
            %eqn3 = (tokenReserve - tokenChanged) = wethReserve * tokenReserve * 1000 / (wethReserve * 1000 + wethToChange * 997)
            eqn3 = tokenChanged = (tokenReserve - wethReserve * tokenReserve * 1000 / (wethReserve * 1000 + wethToChange * 997))
            eqn4 = wethReserve2 == (wethReserve + wethToChange)
            eqn5 = tokenReserve2 == (tokenReserve - tokenChanged)
            eqn6 = wethToAdd / tokenChanged == (wethReserve + wethToChange) / (tokenReserve - tokenChanged)
            S = solve(eqn6, wethToChange)
            ```

            step 2: substitute variables from eqn1-eqn5 in eqn6
            ```
            syms wethToChange  wethReserve tokenReserve wethAmount wethToAdd tokenChanged tokenToAdd wethReserve2 tokenReserve2
            eqn6 = (wethAmount - wethToChange) / (tokenReserve - wethReserve * tokenReserve * 1000 / (wethReserve * 1000 + wethToChange * 997)) == (wethReserve + wethToChange) / (tokenReserve - (tokenReserve - wethReserve * tokenReserve * 1000 / (wethReserve * 1000 + wethToChange * 997)))
            S = solve(eqn6, wethToChange)
            ```

            result = sqrt(wethReserve*(3988009*wethReserve + 3988000*wethAmount))/1994 - (1997*wethReserve)/1994
        */
    }
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2022 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;


import "../interfaces/swappers/ISwapper.sol";
import "../helpers/ReentrancyGuard.sol";
import '../helpers/TransferHelper.sol';
import "../helpers/SafeMath.sol";
import "../Auth2.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev base class for swappers, makes common checks
 * @dev internal _swapUsdpToAsset and _swapAssetToUsdp must be overridden instead of external swapUsdpToAsset and swapAssetToUsdp
 */
abstract contract AbstractSwapper is ISwapper, ReentrancyGuard, Auth2 {
    using TransferHelper for address;
    using SafeMath for uint;

    IERC20 public immutable USDP;

    constructor(address _vaultParameters, address _usdp) Auth2(_vaultParameters) {
        require(_usdp != address(0), "Unit Protocol Swappers: ZERO_ADDRESS");

        USDP = IERC20(_usdp);
    }

    /**
     * @dev usdp already transferred to swapper
     */
    function _swapUsdpToAsset(address _user, address _asset, uint256 _usdpAmount, uint256 _minAssetAmount)
        internal virtual returns (uint swappedAssetAmount);

    /**
     * @dev asset already transferred to swapper
     */
    function _swapAssetToUsdp(address _user, address _asset, uint256 _assetAmount, uint256 _minUsdpAmount)
        internal virtual returns (uint swappedUsdpAmount);

    function swapUsdpToAsset(address _user, address _asset, uint256 _usdpAmount, uint256 _minAssetAmount)
        external override returns (uint swappedAssetAmount) // nonReentrant in swapUsdpToAssetWithDirectSending
    {
        // get USDP from user
        address(USDP).safeTransferFrom(_user, address(this), _usdpAmount);

        return swapUsdpToAssetWithDirectSending(_user, _asset, _usdpAmount, _minAssetAmount);
    }

    function swapAssetToUsdp(address _user, address _asset, uint256 _assetAmount, uint256 _minUsdpAmount)
        external override returns (uint swappedUsdpAmount) // nonReentrant in swapAssetToUsdpWithDirectSending
    {
        // get asset from user
        _asset.safeTransferFrom(_user, address(this), _assetAmount);

        return swapAssetToUsdpWithDirectSending(_user, _asset, _assetAmount, _minUsdpAmount);
    }

    function swapUsdpToAssetWithDirectSending(address _user, address _asset, uint256 _usdpAmount, uint256 _minAssetAmount)
        public override nonReentrant returns (uint swappedAssetAmount)
    {
        require(msg.sender == _user || vaultParameters.canModifyVault(msg.sender), "Unit Protocol Swappers: AUTH_FAILED");

        swappedAssetAmount = _swapUsdpToAsset(_user, _asset, _usdpAmount, _minAssetAmount);

        require(swappedAssetAmount >= _minAssetAmount, "Unit Protocol Swapper: SWAPPED_AMOUNT_LESS_THAN_EXPECTED_MINIMUM");
    }

    function swapAssetToUsdpWithDirectSending(address _user, address _asset, uint256 _assetAmount, uint256 _minUsdpAmount)
        public override nonReentrant returns (uint swappedUsdpAmount)
    {
        require(msg.sender == _user || vaultParameters.canModifyVault(msg.sender), "Unit Protocol Swappers: AUTH_FAILED");

        swappedUsdpAmount = _swapAssetToUsdp(_user, _asset, _assetAmount, _minUsdpAmount);

        require(swappedUsdpAmount >= _minUsdpAmount, "Unit Protocol Swappers: SWAPPED_AMOUNT_LESS_THAN_EXPECTED_MINIMUM");
    }
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2022 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.6;

import "./ICurvePoolBase.sol";

interface ICurvePoolMeta is ICurvePoolBase {

    function base_pool() external view returns (address);

    /**
     * @dev variant of token/3crv pool
     * @param i Index value for the underlying coin to send
     * @param j Index value of the underlying coin to recieve
     * @param _dx Amount of `i` being exchanged
     * @param _min_dy Minimum amount of `j` to receive
     * @return Actual amount of `j` received
     */
    function exchange_underlying(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external returns (uint256);

    function get_dy_underlying(int128 i, int128 j, uint256 _dx) external view returns (uint256);
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.6;

import "../ICurvePool.sol";

interface ICurvePoolCrypto is ICurvePool {
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external;
    function get_dy(uint256 i, uint256 j, uint256 dx) external view returns (uint256);
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;

interface IUniswapV2PairFull {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2021 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;

import "./VaultParameters.sol";


/**
 * @title Auth2
 * @dev Manages USDP's system access
 * @dev copy of Auth from VaultParameters.sol but with immutable vaultParameters for saving gas
 **/
contract Auth2 {

    // address of the the contract with vault parameters
    VaultParameters public immutable vaultParameters;

    constructor(address _parameters) {
        require(_parameters != address(0), "Unit Protocol: ZERO_ADDRESS");

        vaultParameters = VaultParameters(_parameters);
    }

    // ensures tx's sender is a manager
    modifier onlyManager() {
        require(vaultParameters.isManager(msg.sender), "Unit Protocol: AUTH_FAILED");
        _;
    }

    // ensures tx's sender is able to modify the Vault
    modifier hasVaultAccess() {
        require(vaultParameters.canModifyVault(msg.sender), "Unit Protocol: AUTH_FAILED");
        _;
    }

    // ensures tx's sender is the Vault
    modifier onlyVault() {
        require(msg.sender == vaultParameters.vault(), "Unit Protocol: AUTH_FAILED");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    /**
     * @dev babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
     **/
    function sqrt(uint x) internal pure returns (uint y) {
        if (x > 3) {
            uint z = x / 2 + 1;
            y = x;
            while (z < y) {
                y = z;
                z = (x / z + z) / 2;
            }
        } else if (x != 0) {
            y = 1;
        }
    }
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;



/**
 * @title Auth
 * @dev Manages USDP's system access
 **/
contract Auth {

    // address of the the contract with vault parameters
    VaultParameters public vaultParameters;

    constructor(address _parameters) {
        vaultParameters = VaultParameters(_parameters);
    }

    // ensures tx's sender is a manager
    modifier onlyManager() {
        require(vaultParameters.isManager(msg.sender), "Unit Protocol: AUTH_FAILED");
        _;
    }

    // ensures tx's sender is able to modify the Vault
    modifier hasVaultAccess() {
        require(vaultParameters.canModifyVault(msg.sender), "Unit Protocol: AUTH_FAILED");
        _;
    }

    // ensures tx's sender is the Vault
    modifier onlyVault() {
        require(msg.sender == vaultParameters.vault(), "Unit Protocol: AUTH_FAILED");
        _;
    }
}



/**
 * @title VaultParameters
 **/
contract VaultParameters is Auth {

    // map token to stability fee percentage; 3 decimals
    mapping(address => uint) public stabilityFee;

    // map token to liquidation fee percentage, 0 decimals
    mapping(address => uint) public liquidationFee;

    // map token to USDP mint limit
    mapping(address => uint) public tokenDebtLimit;

    // permissions to modify the Vault
    mapping(address => bool) public canModifyVault;

    // managers
    mapping(address => bool) public isManager;

    // enabled oracle types
    mapping(uint => mapping (address => bool)) public isOracleTypeEnabled;

    // address of the Vault
    address payable public vault;

    // The foundation address
    address public foundation;

    /**
     * The address for an Ethereum contract is deterministically computed from the address of its creator (sender)
     * and how many transactions the creator has sent (nonce). The sender and nonce are RLP encoded and then
     * hashed with Keccak-256.
     * Therefore, the Vault address can be pre-computed and passed as an argument before deployment.
    **/
    constructor(address payable _vault, address _foundation) Auth(address(this)) {
        require(_vault != address(0), "Unit Protocol: ZERO_ADDRESS");
        require(_foundation != address(0), "Unit Protocol: ZERO_ADDRESS");

        isManager[msg.sender] = true;
        vault = _vault;
        foundation = _foundation;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Grants and revokes manager's status of any address
     * @param who The target address
     * @param permit The permission flag
     **/
    function setManager(address who, bool permit) external onlyManager {
        isManager[who] = permit;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets the foundation address
     * @param newFoundation The new foundation address
     **/
    function setFoundation(address newFoundation) external onlyManager {
        require(newFoundation != address(0), "Unit Protocol: ZERO_ADDRESS");
        foundation = newFoundation;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets ability to use token as the main collateral
     * @param asset The address of the main collateral token
     * @param stabilityFeeValue The percentage of the year stability fee (3 decimals)
     * @param liquidationFeeValue The liquidation fee percentage (0 decimals)
     * @param usdpLimit The USDP token issue limit
     * @param oracles The enables oracle types
     **/
    function setCollateral(
        address asset,
        uint stabilityFeeValue,
        uint liquidationFeeValue,
        uint usdpLimit,
        uint[] calldata oracles
    ) external onlyManager {
        setStabilityFee(asset, stabilityFeeValue);
        setLiquidationFee(asset, liquidationFeeValue);
        setTokenDebtLimit(asset, usdpLimit);
        for (uint i=0; i < oracles.length; i++) {
            setOracleType(oracles[i], asset, true);
        }
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets a permission for an address to modify the Vault
     * @param who The target address
     * @param permit The permission flag
     **/
    function setVaultAccess(address who, bool permit) external onlyManager {
        canModifyVault[who] = permit;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets the percentage of the year stability fee for a particular collateral
     * @param asset The address of the main collateral token
     * @param newValue The stability fee percentage (3 decimals)
     **/
    function setStabilityFee(address asset, uint newValue) public onlyManager {
        stabilityFee[asset] = newValue;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets the percentage of the liquidation fee for a particular collateral
     * @param asset The address of the main collateral token
     * @param newValue The liquidation fee percentage (0 decimals)
     **/
    function setLiquidationFee(address asset, uint newValue) public onlyManager {
        require(newValue <= 100, "Unit Protocol: VALUE_OUT_OF_RANGE");
        liquidationFee[asset] = newValue;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Enables/disables oracle types
     * @param _type The type of the oracle
     * @param asset The address of the main collateral token
     * @param enabled The control flag
     **/
    function setOracleType(uint _type, address asset, bool enabled) public onlyManager {
        isOracleTypeEnabled[_type][asset] = enabled;
    }

    /**
     * @notice Only manager is able to call this function
     * @dev Sets USDP limit for a specific collateral
     * @param asset The address of the main collateral token
     * @param limit The limit number
     **/
    function setTokenDebtLimit(address asset, uint limit) public onlyManager {
        tokenDebtLimit[asset] = limit;
    }
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2022 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.6;

import "../ICurvePool.sol";

interface ICurvePoolBase is ICurvePool {
    /**
     * @notice Perform an exchange between two coins
     * @dev Index values can be found via the `coins` public getter method
     * @param i Index value for the coin to send
     * @param j Index valie of the coin to recieve
     * @param _dx Amount of `i` being exchanged
     * @param _min_dy Minimum amount of `j` to receive
     * @return Actual amount of `j` received
     */
    function exchange(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external returns (uint256);

    function get_dy(int128 i, int128 j, uint256 _dx) external view returns (uint256);
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity ^0.7.6;

interface ICurvePool {
    function get_virtual_price() external view returns (uint);
    function coins(uint) external view returns (address);
}
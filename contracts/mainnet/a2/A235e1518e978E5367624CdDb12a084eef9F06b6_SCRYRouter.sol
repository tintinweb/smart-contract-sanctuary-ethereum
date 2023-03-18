// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

interface ISCRYERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

import './ISCRYERC20.sol';

interface ISCRYERC20Permit is ISCRYERC20 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

interface ISCRYFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
    function oldMajor() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

import './ISCRYERC20Permit.sol';

interface ISCRYPair is ISCRYERC20Permit {
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

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function burnUnbalanced(address to, uint token0Min, uint token1Min) external returns (uint amount0, uint amount1);
    function burnUnbalancedForExactToken(address to, address exactToken, uint amountExactOut) external returns (uint, uint);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function sync() external;

    function initialize(address, address, address) external;

    function setIsFlashSwapEnabled(bool _isFlashSwapEnabled) external;
    function setFeeToAddresses(address _feeTo0, address _feeTo1) external;
    function setRouter(address _router) external;
    function getSwapFee() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.2;

interface ISCRYRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function liquidityRouter() external returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function addUnbalancedLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addUnbalancedLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint swapFee) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint swapFee) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    // single sided remove liquidity
    function removeUnbalancedLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAExact,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint, uint);
    function removeUnbalancedLiquidityETH(
        address token,
        uint liquidity,
        address exactToken,
        uint exactTokenAmount,
        uint otherTokenMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeUnbalancedLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAExact,
        uint amountBMin,        
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint, uint);
    function removeUnbalancedLiquidityETHWithPermit(
        address token,
        uint liquidity,
        address exactToken,
        uint exactTokenAmount,
        uint otherTokenMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function removeUnbalancedLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        address exactToken,
        uint exactTokenAmount,
        uint otherTokenMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeUnbalancedLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        address exactToken,
        uint exactTokenAmount,
        uint otherTokenMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

pragma solidity >=0.5.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathSCRY {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0;

import '../../core/interfaces/ISCRYPair.sol';

import "./SafeMathSCRY.sol";

library SCRYLibrary {
    using SafeMathSCRY for uint;

    uint256 private constant MAX_FEE = 10000;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'SCRYLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'SCRYLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'145dd2cfa2424da880d617d54d12f91d8751490aed761f21141a44032bee5947' // hardhat
                // hex'f2b57fa1700ce1fa58cc33bd5169a52d4fee4581fe629136551e37fe91552963' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReservesAndFee(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB, uint swapFee) {
        (address token0,) = sortTokens(tokenA, tokenB);
        address pairAddress = pairFor(factory, tokenA, tokenB);
        ISCRYPair pair = ISCRYPair(pairAddress);
        (uint reserve0, uint reserve1,) = pair.getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        swapFee = pair.getSwapFee();
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'SCRYLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'SCRYLibrary: INSUFFICIENT_LIQUIDITYQ');
        // amount * price
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint swapFee) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'SCRYLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'SCRYLibrary: INSUFFICIENT_LIQUIDITY1');
        uint GAMMA = MAX_FEE.sub(swapFee);
        uint amountInWithFee = amountIn.mul(GAMMA);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(MAX_FEE).add(amountIn.mul(MAX_FEE.add(GAMMA)));
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint swapFee) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'SCRYLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'SCRYLibrary: INSUFFICIENT_LIQUIDITY2');
        uint GAMMA = MAX_FEE.sub(swapFee);
        uint numerator = reserveIn.mul(amountOut).mul(MAX_FEE);
        uint denominator = reserveOut.mul(GAMMA).sub(amountOut.mul(MAX_FEE.add(GAMMA)));
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'SCRYLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut, uint swapFee) = getReservesAndFee(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut, swapFee);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'SCRYLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut, uint swapFee) = getReservesAndFee(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut, swapFee);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.12;

import '../core/interfaces/ISCRYERC20.sol';
import '../core/interfaces/ISCRYFactory.sol';
import '../solidity-lib/libraries/TransferHelper.sol';

import './interfaces/ISCRYRouter.sol';
import './interfaces/IWETH.sol';
import './libraries/SCRYLibrary.sol';
import './libraries/SafeMathSCRY.sol';

contract LiquidityRouter {
    using SafeMathSCRY for uint;

    address public immutable factory;
    address public immutable WETH;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'LiquidityRouter: EXPIRED');
        _;
    }

    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
    }

    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet
        if (ISCRYFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            ISCRYFactory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB,) = SCRYLibrary.getReservesAndFee(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = SCRYLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                // swap A for B
                require(amountBOptimal >= amountBMin, 'LiquidityRouter: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
                require(amountA >= amountAMin, 'LiquidityRouter: INSUFFICIENT_A_AMOUNT');
            } else {
                // swap B for A
                uint amountAOptimal = SCRYLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'LiquidityRouter: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
                require(amountB >= amountBMin, 'LiquidityRouter: INSUFFICIENT_B_AMOUNT');
            }
        }
    }
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = SCRYLibrary.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = ISCRYPair(pair).mint(to);
    }

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pair = SCRYLibrary.pairFor(factory, token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = ISCRYPair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // amountAMin and amountBMin represent minimum amounts if liquidity were withdrawn equally
    function addUnbalancedLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        if (ISCRYFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            ISCRYFactory(factory).createPair(tokenA, tokenB);
        }
        address pair = ISCRYFactory(factory).getPair(tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountADesired);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountBDesired);
        liquidity = ISCRYPair(pair).mint(to);
        (amountA, amountB) = checkMintedAmount(liquidity, pair, tokenA, tokenB, amountAMin, amountBMin);
    }
    
    // ensure if you burned the liquidity you could get at least amountAMin and amountBMin back
    function checkMintedAmount(uint liquidity, address pair, address tokenA, address tokenB, uint amountAMin, uint amountBMin) private view returns (uint amountA, uint amountB) {
        uint balanceA = ISCRYERC20(tokenA).balanceOf(pair);
        uint balanceB = ISCRYERC20(tokenB).balanceOf(pair);
        uint totalSupply = ISCRYERC20(pair).totalSupply();
        amountA = liquidity.mul(balanceA) / totalSupply; 
        amountB = liquidity.mul(balanceB) / totalSupply;
        require(amountA >= amountAMin, 'LiquidityRouter: INSUFFICIENT_A');
        require(amountB >= amountBMin, 'LiquidityRouter: INSUFFICIENT_B');
    }

    function addUnbalancedLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        if (ISCRYFactory(factory).getPair(token, WETH) == address(0)) {
            ISCRYFactory(factory).createPair(token, WETH);
        }
        address pair = ISCRYFactory(factory).getPair(token, WETH);
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountTokenDesired); 
        IWETH(WETH).deposit{value: msg.value}();
        assert(IWETH(WETH).transfer(pair, msg.value));
        liquidity = ISCRYPair(pair).mint(to);
        (amountToken, amountETH) = checkMintedAmount(liquidity, pair, token, WETH, amountTokenMin, amountETHMin);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = SCRYLibrary.pairFor(factory, tokenA, tokenB);
        ISCRYERC20(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = ISCRYPair(pair).burn(to);
        (address token0,) = SCRYLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'LiquidityRouter: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'LiquidityRouter: INSUFFICIENT_B_AMOUNT');
    }
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual ensure(deadline) returns (uint amountToken, uint amountETH) {
        address pair = SCRYLibrary.pairFor(factory, token, WETH);
        ISCRYERC20(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = ISCRYPair(pair).burn(address(this));
        (address token0,) = SCRYLibrary.sortTokens(token, WETH);
        (amountToken, amountETH) = token == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountToken >= amountTokenMin, 'LiquidityRouter: INSUFFICIENT_TOKEN_AMOUNT');
        require(amountETH >= amountETHMin, 'LiquidityRouter: INSUFFICIENT_WETH_AMOUNT');

        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeUnbalancedLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAExact,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual ensure(deadline) returns (uint, uint) {
        address pair = SCRYLibrary.pairFor(factory, tokenA, tokenB);
        ISCRYERC20(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = ISCRYPair(pair).burnUnbalancedForExactToken(to, tokenA, amountAExact);

        (address token0,) = SCRYLibrary.sortTokens(tokenA, tokenB);
        if (token0 == tokenA) {
            require(amount0 >= amountAExact, 'LiquidityRouter: INSUFFICIENT_A');
            require(amount1 >= amountBMin, 'LiquidityRouter: INSUFFICIENT_B');
            return (amount0, amount1);
        } else {
            require(amount0 >= amountBMin, 'LiquidityRouter: INSUFFICIENT_B');
            require(amount1 >= amountAExact, 'LiquidityRouter: INSUFFICIENT_A');
            return (amount1, amount0);
        }
    }
    function removeUnbalancedLiquidityETH(
        address token,
        uint liquidity,
        address exactToken,
        uint exactTokenAmount,
        uint otherTokenMin,
        address to,
        uint deadline
    ) public virtual ensure(deadline) returns (uint amountToken, uint amountETH) {
        address pair = SCRYLibrary.pairFor(factory, token, WETH);
        ISCRYERC20(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = ISCRYPair(pair).burnUnbalancedForExactToken(address(this), exactToken, exactTokenAmount);

        (address token0,) = SCRYLibrary.sortTokens(token, WETH);
        (amountToken, amountETH) = (token == token0) ? (amount0, amount1) : (amount1, amount0); 
        if (exactToken == token) {
            require(amountToken >= exactTokenAmount, 'LiquidityRouter: INSUFFICIENT_TOKEN');
            require(amountETH >= otherTokenMin, 'LiquidityRouter: INSUFFICIENT_ETH');
        } else {
            require(amountETH >= exactTokenAmount, 'LiquidityRouter: INSUFFICIENT_ETH');
            require(amountToken >= otherTokenMin, 'LiquidityRouter: INSUFFICIENT_TOKEN');
        }

        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.6.12;

import '../core/interfaces/ISCRYERC20Permit.sol';
import '../solidity-lib/libraries/TransferHelper.sol';

import './interfaces/ISCRYRouter.sol';
import './interfaces/IWETH.sol';
import './libraries/SCRYLibrary.sol';
import './libraries/SafeMathSCRY.sol';
import './LiquidityRouter.sol';

contract SCRYRouter is ISCRYRouter {
    using SafeMathSCRY for uint;

    address public immutable override factory;
    address public immutable override WETH;
    address public immutable override liquidityRouter;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'EXPIRED');
        // EOA only
        require(tx.origin == msg.sender, 'INVALID SENDER');
        _;
    }

    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
        liquidityRouter = address(new LiquidityRouter(_factory, _WETH));
    }

    receive() external payable {
        assert(msg.sender == WETH);
    }

    // **** ADD LIQUIDITY ****
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual override returns (uint amountA, uint amountB, uint liquidity) {
        (bool success, bytes memory result) = liquidityRouter.delegatecall(
            abi.encodeWithSelector(LiquidityRouter.addLiquidity.selector, 
            tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, to, deadline));
        require(success);
        return abi.decode(result, (uint, uint, uint));
    }
    function addUnbalancedLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual override returns (uint amountA, uint amountB, uint liquidity) {
        (bool success, bytes memory result) = liquidityRouter.delegatecall(
            abi.encodeWithSelector(LiquidityRouter.addUnbalancedLiquidity.selector, 
            tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, to, deadline));
        require(success);
        return abi.decode(result, (uint, uint, uint));
    }
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual override payable returns (uint amountToken, uint amountETH, uint liquidity) {
        (bool success, bytes memory result) = liquidityRouter.delegatecall(
            abi.encodeWithSelector(LiquidityRouter.addLiquidityETH.selector, 
            token, amountTokenDesired, amountTokenMin, amountETHMin, to, deadline));
        require(success);
        return abi.decode(result, (uint, uint, uint));
    }
    function addUnbalancedLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual override payable returns (uint amountToken, uint amountETH, uint liquidity) {
        (bool success, bytes memory result) = liquidityRouter.delegatecall(
            abi.encodeWithSelector(LiquidityRouter.addUnbalancedLiquidityETH.selector, 
            token, amountTokenDesired, amountTokenMin, amountETHMin, to, deadline));
        require(success);
        return abi.decode(result, (uint, uint, uint));
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual override returns (uint amountA, uint amountB) {
        (bool success, bytes memory result) = liquidityRouter.delegatecall(
            abi.encodeWithSelector(LiquidityRouter.removeLiquidity.selector, 
            tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline));
        require(success);
        return abi.decode(result, (uint, uint));
    } 
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override returns (uint amountToken, uint amountETH) {
        (bool success, bytes memory result) = liquidityRouter.delegatecall(
            abi.encodeWithSelector(LiquidityRouter.removeLiquidityETH.selector, 
            token, liquidity, amountTokenMin, amountETHMin, to, deadline));
        require(success);
        return abi.decode(result, (uint, uint));
    }
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint, uint) {
        _permit(tokenA, tokenB, liquidity, deadline, approveMax, v, r, s);
        return removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint, uint) {
        _permit(token, WETH, liquidity, deadline, approveMax, v, r, s);
        return removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override returns (uint amountETH) {
        (, amountETH) = removeLiquidity(token, WETH, liquidity, amountTokenMin, amountETHMin, address(this), deadline);
        TransferHelper.safeTransfer(token, to, ISCRYERC20Permit(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint) {
        _permit(token, WETH, liquidity, deadline, approveMax, v, r, s);
        return removeLiquidityETHSupportingFeeOnTransferTokens(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }
    function removeUnbalancedLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAExact,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual override returns (uint, uint) {
        (bool success, bytes memory result) = liquidityRouter.delegatecall(
            abi.encodeWithSelector(LiquidityRouter.removeUnbalancedLiquidity.selector, 
            tokenA, tokenB, liquidity, amountAExact, amountBMin, to, deadline));
        require(success);
        return abi.decode(result, (uint, uint));
    }
    function removeUnbalancedLiquidityETH(
        address token,
        uint liquidity,
        address exactToken,
        uint exactTokenAmount,
        uint otherTokenMin,
        address to,
        uint deadline
    ) public virtual override returns (uint, uint) {
        (bool success, bytes memory result) = liquidityRouter.delegatecall(
            abi.encodeWithSelector(LiquidityRouter.removeUnbalancedLiquidityETH.selector, 
            token, liquidity, exactToken, exactTokenAmount, otherTokenMin, to, deadline));
        require(success);
        return abi.decode(result, (uint, uint));
    }
    function removeUnbalancedLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAExact,
        uint amountBMin,       
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint, uint) {
        _permit(tokenA, tokenB, liquidity, deadline, approveMax, v, r, s);
        return removeUnbalancedLiquidity(tokenA, tokenB, liquidity, amountAExact, amountBMin, to, deadline);
    }
    function removeUnbalancedLiquidityETHWithPermit(
        address token,
        uint liquidity,
        address exactToken,
        uint exactTokenAmount,
        uint otherTokenMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint, uint) {
        _permit(token, WETH, liquidity, deadline, approveMax, v, r, s);
        return removeUnbalancedLiquidityETH(token, liquidity, exactToken, exactTokenAmount, otherTokenMin, to, deadline);
    }
    function removeUnbalancedLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        address exactToken,
        uint exactTokenAmount,
        uint otherTokenMin,
        address to,
        uint deadline
    ) public virtual override returns (uint amountToken, uint amountETH) {
        if (exactToken == token) {
            (amountToken, amountETH) = removeUnbalancedLiquidity(token, WETH, liquidity, exactTokenAmount, otherTokenMin, address(this), deadline);
        } else {
            (amountETH, amountToken) = removeUnbalancedLiquidity(WETH, token, liquidity, exactTokenAmount, otherTokenMin, address(this), deadline);
        }
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeUnbalancedLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        address exactToken,
        uint exactTokenAmount,
        uint otherTokenMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint, uint) {
        _permit(token, WETH, liquidity, deadline, approveMax, v, r, s);
        return removeUnbalancedLiquidityETHSupportingFeeOnTransferTokens(token, liquidity, exactToken, exactTokenAmount, otherTokenMin, to, deadline);
    }
    function _permit(
        address tokenA, address tokenB, uint liquidity, uint deadline, 
        bool approveMax, uint8 v, bytes32 r, bytes32 s) internal {
        ISCRYERC20Permit(SCRYLibrary.pairFor(factory, tokenA, tokenB))
            .permit(msg.sender, address(this), approveMax ? uint(-1) : liquidity, deadline, v, r, s);
    }

    // **** SWAP ****
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = SCRYLibrary.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? SCRYLibrary.pairFor(factory, output, path[i + 2]) : _to;
            ISCRYPair(SCRYLibrary.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = SCRYLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'OUTPUT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, SCRYLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        amounts = SCRYLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'INPUT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, SCRYLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, to);
    }
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'PATH');
        amounts = SCRYLibrary.getAmountsOut(factory, msg.value, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'OUTPUT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(SCRYLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'PATH');
        amounts = SCRYLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= amountInMax, 'INPUT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, SCRYLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'PATH');
        amounts = SCRYLibrary.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'OUTPUT');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, SCRYLibrary.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'PATH');
        amounts = SCRYLibrary.getAmountsIn(factory, amountOut, path);
        require(amounts[0] <= msg.value, 'INPUT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(SCRYLibrary.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
        // refund dust eth, if any
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = SCRYLibrary.sortTokens(input, output);
            ISCRYPair pair = ISCRYPair(SCRYLibrary.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            uint256 swapFee = pair.getSwapFee();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = ISCRYERC20Permit(input).balanceOf(address(pair)).sub(reserveInput);
            amountOutput = SCRYLibrary.getAmountOut(amountInput, reserveInput, reserveOutput, swapFee);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? SCRYLibrary.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, SCRYLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        uint balanceBefore = ISCRYERC20Permit(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            ISCRYERC20Permit(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'OUTPUT'
        );
    }
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        payable
        ensure(deadline)
    {
        require(path[0] == WETH, 'PATH');
        uint amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(SCRYLibrary.pairFor(factory, path[0], path[1]), amountIn));
        uint balanceBefore = ISCRYERC20Permit(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            ISCRYERC20Permit(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'OUTPUT'
        );
    }
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        ensure(deadline)
    {
        require(path[path.length - 1] == WETH, 'PATH');
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, SCRYLibrary.pairFor(factory, path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountOut = ISCRYERC20Permit(WETH).balanceOf(address(this));
        require(amountOut >= amountOutMin, 'OUTPUT');
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) external pure virtual override returns (uint amountB) {
        return SCRYLibrary.quote(amountA, reserveA, reserveB);
    }
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint swapFee)
        external
        pure
        virtual
        override
        returns (uint amountOut)
    {
        return SCRYLibrary.getAmountOut(amountIn, reserveIn, reserveOut, swapFee);
    }
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint swapFee)
        external
        pure
        virtual
        override
        returns (uint amountIn)
    {
        return SCRYLibrary.getAmountIn(amountOut, reserveIn, reserveOut, swapFee);
    }
    function getAmountsOut(uint amountIn, address[] calldata path)
        external
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return SCRYLibrary.getAmountsOut(factory, amountIn, path);
    }
    function getAmountsIn(uint amountOut, address[] calldata path)
        external
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return SCRYLibrary.getAmountsIn(factory, amountOut, path);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}
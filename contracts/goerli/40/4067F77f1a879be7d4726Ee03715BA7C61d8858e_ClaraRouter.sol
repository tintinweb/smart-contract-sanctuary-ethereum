// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;


interface IClaraFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
}


library SafeMath {
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


interface IClaraPair {
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

    function permit(address owner, address spender, uint value, uint8 v, bytes32 r, bytes32 s) external;

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


interface IERC20 {
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

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


contract ClaraRouter  {
    using SafeMath for uint;

    address public immutable  factory;
    address public immutable  WETH;

    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); 
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        address pair
    ) internal virtual returns (uint amountA, uint amountB) {
        if (IClaraFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IClaraFactory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB,) = IClaraPair(pair).getReserves();
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        address to,
        address pair
    ) external virtual returns(uint amountA, uint amountB, uint liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired,pair);
        safeTransferFrom(tokenA,msg.sender, pair, amountADesired);
        safeTransferFrom(tokenB,msg.sender, pair, amountBDesired);
        liquidity = IClaraPair(pair).mint(to);
       
    }
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        address pair,
        address to
    ) external virtual  payable  returns (uint amountToken, uint amountETH, uint liquidity) {
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            pair
        );
        safeTransferFrom(token, msg.sender, pair, amountTokenDesired);
        IWETH(WETH).deposit{value: msg.value}();
        assert(IWETH(WETH).transfer(pair, msg.value));
        liquidity = IClaraPair(pair).mint(to);
        // refund dust eth, if any
         safeTransferETH(msg.sender, msg.value - amountETH);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        address to,
        address pair
    ) public virtual returns (uint amountA, uint amountB) {
        IClaraPair(pair).transferFrom(msg.sender, pair, liquidity); 
        (uint amount0, uint amount1) = IClaraPair(pair).burn(to);
        (address token0,) = sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
    }

    function removeLiquidityETH(
        address token,
        uint liquidity,
        address to,
        address pair
    ) public virtual   returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            address(this),
            pair
        );
        safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        safeTransferETH(to, amountETH);
    }

    function swapExactTokensForTokens(uint amountIn, address tokenA, address tokenB, address pair,address to) external virtual returns (uint amounts) {
        amounts = getAmountsOut(amountIn, pair);
        safeTransferFrom(
            tokenA, msg.sender, pairFor(tokenA, tokenB), amounts
        );
        _swap(amounts, tokenA,tokenB, to, pair);
    }

    function swapExactTokensForETH(uint amountIn, address tokenA,address tokenB, address to,address pair)
        external
        virtual
        returns (uint amounts)
    {
        amounts = getAmountsOut(amountIn, pair);
        safeTransferFrom(
            tokenA, msg.sender, pairFor(tokenA, tokenB), amounts
        );
        _swap(amounts, tokenA,tokenB, address(this),pair);
        IWETH(WETH).withdraw(amounts);
        safeTransferETH(to, amounts);
    }

    function _swap(uint amounts, address tokenA,address tokenB, address _to,address pair) internal virtual {
            (address input, address output) = (tokenA, tokenB);
            (address token0,) = sortTokens(input, output);
            uint amountOut = amounts;
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            IClaraPair(pair).swap(
                amount0Out, amount1Out, _to, new bytes(0)
            );
    }
  
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual  returns (uint amountB) {
        amountB = amountA.mul(reserveB) / reserveA;
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure
        virtual
        returns (uint amountOut) {
        return getAmountOuts(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) public pure virtual returns (uint amountIn) {
        require(amountOut > 0, "TLLibrary: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "TLLibrary: INSUFFICIENT_LIQUIDITY");
        uint numerator = reserveIn.mul(amountOut).mul(10000);
        uint denominator = reserveOut.sub(amountOut).mul(9975);
        amountIn = (numerator / denominator).add(1);
    }

    function sortTokens(address tokenA, address tokenB) public pure returns (address token0, address token1) {
        require(tokenA != tokenB, "TLLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "TLLibrary: ZERO_ADDRESS");
    }

    function getAmountsOut(uint amountIn, address pair) public view returns (uint amounts) {
        amounts = amountIn;
        (uint reserveIn, uint reserveOut,) = IClaraPair(pair).getReserves();
        amounts = getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function safeTransferFrom(address token, address from, address to, uint value) public {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TLHelper: TRANSFER_FROM_FAILED");
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TLHelper: TRANSFER_FAILED");
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, "TLHelper: ETH_TRANSFER_FAILED");
    }


    function getAmountOuts(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        uint amountInWithFee = amountIn.mul(9975);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function pairFor(address tokenA, address tokenB) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5' // init code hash
            ))));
    }


}
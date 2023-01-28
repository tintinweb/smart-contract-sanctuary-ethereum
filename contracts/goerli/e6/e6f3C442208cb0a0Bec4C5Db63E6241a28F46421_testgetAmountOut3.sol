// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;    

import "../IUniswapV2Pair.sol";

contract testgetAmountOut3
{
    uint public flag=0;
    //goerli
    address constant weth  =0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;  

    function getAmountOut0(
        uint256 amountIn,
        address tokenIn,
        address poolAdd
    ) public view returns (uint256 amountOut, address tokenOut) {
        IUniswapV2Pair pair = IUniswapV2Pair(poolAdd);
        address token0 = pair.token0();
        uint256 reserveOut;
        uint256 reserveIn;
        if (tokenIn == token0) {
            (reserveIn, reserveOut, ) = pair.getReserves();
            tokenOut = pair.token1();
        } else {
            (reserveOut, reserveIn, ) = pair.getReserves();
            tokenOut = token0;
        }
        uint256 amountInWithFee = amountIn * (997);
        uint256 numerator = amountInWithFee * (reserveOut);
        uint256 denominator = reserveIn * (1000) + (amountInWithFee);
        amountOut = numerator / denominator;
    }

    function getAmountOut1(
        uint256 amountIn,
        address tokenIn,
        address poolAdd
    ) public view returns (uint256 amountOut, address tokenOut) {
        IUniswapV2Pair pair = IUniswapV2Pair(poolAdd);
        address token0 = pair.token0();
        uint256 reserveOut;
        uint256 reserveIn;
        if (tokenIn == token0) {
            (reserveIn, reserveOut, ) = pair.getReserves();
            tokenOut = pair.token1();
        } else {
            (reserveOut, reserveIn, ) = pair.getReserves();
            tokenOut = token0;
        } 
        assembly { 
            let amountInWithFee := mul(amountIn , 997)
            let numerator := mul(amountInWithFee , reserveOut)
            let denominator := add(mul(reserveIn , 1000), amountInWithFee)
            amountOut := div(numerator, denominator)    
        }
    }

    function getAmountOut2(
        uint256 amountIn,
        address tokenIn,
        address pair
    ) public view returns (uint256 amountOut, address tokenOut) {
        assembly { 
            let ptr := mload(0x40)
            // token0()
            mstore(ptr, 0x0dfe168100000000000000000000000000000000000000000000000000000000) 
            let res1 := staticcall(gas(), pair, ptr, 4, add(ptr, 4), 32)
            if eq(res1, 0){ revert(0, 0) }
            let token0 := mload(add(ptr, 4))

            let reserveOut
            let reserveIn
            // getReserves()
            mstore(ptr, 0x0902f1ac00000000000000000000000000000000000000000000000000000000) 
            res1 := staticcall(gas(), pair, ptr, 4, add(ptr, 4), 64)
            if eq(res1, 0) { revert(0, 0) }
            let ifeq := eq(tokenIn, token0)
            switch ifeq
            case 1 {
                reserveIn := mload(add(ptr, 4))
                reserveOut := mload(add(ptr, 36)) 
                // token1()
                let ptr2 := mload(0x40)
                mstore(ptr2, 0xd21220a700000000000000000000000000000000000000000000000000000000) 
                res1 := staticcall(gas(), pair, ptr2, 4, add(ptr2, 4), 32)
                if eq(res1, 0) { revert(0, 0) } 
                tokenOut := mload(add(ptr2, 4))
            } 
            default {
                reserveOut := mload(add(ptr, 4))
                reserveIn := mload(add(ptr, 36)) 
                tokenOut := token0
            }

            let amountInWithFee := mul(amountIn , 997)
            let numerator := mul(amountInWithFee , reserveOut)
            let denominator := add(mul(reserveIn , 1000), amountInWithFee)
            amountOut := div(numerator, denominator)    
        }
    }

    function test012(uint chooseAsse 
    ) public returns (uint256 amountOut, address tokenOut) {    
        uint256 amountIn =  123456;
        address tokenIn =0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
        address pair  = 0x8FeD702B97F3120A7Dc7da6023286065417f7563; 
 
        flag = 1; 
        if(chooseAsse==1) (amountOut,tokenOut) = getAmountOut1(amountIn,tokenIn,pair) ;
        else if(chooseAsse==2) (amountOut,tokenOut)  = getAmountOut2(amountIn,tokenIn,pair) ;
        else (amountOut,tokenOut)  = getAmountOut0(amountIn,tokenIn,pair) ;
        flag = 0;   
    }


}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0; 
interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint256);
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    function MINIMUM_LIQUIDITY() external pure returns (uint256);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    function kLast() external view returns (uint256);
    function mint(address to) external returns (uint256 liquidity);
    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}
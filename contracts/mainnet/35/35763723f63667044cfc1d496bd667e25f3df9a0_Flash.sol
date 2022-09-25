/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

pragma solidity ^0.7.4;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function transfer(address to, uint value) external returns (bool);
}

interface IPAIR {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

contract Flash is IUniswapV2Callee {

    address public immutable owner = 0x95E54446792015d27CBf2171fBF8C5921968eB12;
    
    constructor() public {
        
    }

    function run(address[] calldata pairs, address borrowing_token, uint amount) external {
        if (borrowing_token == IPAIR(pairs[0]).token0()) {
            IPAIR(pairs[0]).swap(amount, 0, address(this), abi.encode(pairs));
        }
        else if (borrowing_token == IPAIR(pairs[0]).token1()) {
            IPAIR(pairs[0]).swap(0, amount, address(this), abi.encode(pairs));
        }
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {
        
        address[] memory pairs = abi.decode(data, (address[]));

        address tokenIn = amount0 > 0 ? IPAIR(pairs[0]).token0() : IPAIR(pairs[0]).token1();
        for (uint i = 1; i < pairs.length; i ++) {
            uint amountIn = IERC20(tokenIn).balanceOf(address(this));
            IPAIR PAIR = IPAIR(pairs[i]);
            (uint X, uint Y, ) = PAIR.getReserves();
            if (tokenIn == PAIR.token0()) {
                uint amountOut = 997 * amountIn * Y / (1000 * X + 997 * amountIn);
                IERC20(PAIR.token0()).transfer(pairs[i], amountIn);
                PAIR.swap(0, amountOut, address(this), new bytes(0));
                tokenIn = PAIR.token1();
            }
            else {
                uint amountOut = 997 * amountIn * X / (1000 * Y + 997 * amountIn);
                IERC20(PAIR.token1()).transfer(pairs[i], amountIn);
                PAIR.swap(amountOut, 0, address(this), new bytes(0));
                tokenIn = PAIR.token0();
            }
        }

        (uint X, uint Y, ) = IPAIR(pairs[0]).getReserves();
        if (amount0 > 0) {
            uint debut = 1000 * amount0 * Y / (997 * (X - amount0)) + 1;
            IERC20 TOKEN = IERC20(IPAIR(pairs[0]).token1());
            TOKEN.transfer(msg.sender, debut);
            TOKEN.transfer(owner, TOKEN.balanceOf(address(this)));
        }
        else {
            uint debut = 1000 * amount1 * X / (997 * (Y - amount1)) + 1;
            IERC20 TOKEN = IERC20(IPAIR(pairs[0]).token0());
            TOKEN.transfer(msg.sender, debut);
            TOKEN.transfer(owner, TOKEN.balanceOf(address(this)));
        }
    }

    receive() external payable {}

    function withdraw() external {
        payable(owner).transfer(address(this).balance);
    }

    function withdrawToken(address token) external {
        IERC20(token).transfer(owner, IERC20(token).balanceOf(address(this)));
    }
}
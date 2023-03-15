// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IUniswapV2Pair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function balanceOf(address owner) external view returns (uint256);
}

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

contract Jzetm1 is IUniswapV2Callee {
    function main(
        address wallet,
        address token0,
        address token1,
        address swap_pair1,
        address swap_pair2,
        uint x,
        uint y,
        uint z
    ) external {

        bytes memory data = abi.encode(token0, token1, swap_pair1, swap_pair2, x, y, z);
        IUniswapV2Pair(swap_pair1).swap(0, y, address(this), data);

        IERC20(token0).transfer(wallet, IERC20(token0).balanceOf(address(this)));
    }


    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external {
        (address token0, address token1, address swap_pair1, address swap_pair2, uint x, uint y, uint z) = abi.decode(data, (address, address, address, address, uint, uint, uint)); 


        IERC20(token1).transfer(swap_pair2, y);
        IUniswapV2Pair(swap_pair2).swap(z, 0, address(this), "");
        IERC20(token0).transfer(swap_pair1, x);
    }


}
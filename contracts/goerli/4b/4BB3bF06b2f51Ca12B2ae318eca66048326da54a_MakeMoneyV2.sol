// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;


interface IUniswapV2Pair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
}

interface IAB11 {
    function a_to_b() external;
    function b_to_a() external;
}

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

contract MakeMoneyV2 is IUniswapV2Callee {

    address public address_uniswapv2pair_b_a = 0x12EDeef345df4D793a4e7185eCE9807f5F7cE3d9;
    address public address_ab11 = 0x50010c607a1BDA23CFCf45a0D65CAC5BD14Fb7EE;
    address public address_a = 0x64087006D06B09A961E33928c99A9DDE69D1A313;
    address public address_b = 0x56B169B172847fd245bE87abCa37435378c912B6;

    uint256 public x = 1000000000000000000; // 1 ether
    uint256 public y = x * 2; // 2 ether

    function main() external {
        uint256 balance_a = IERC20(address_a).balanceOf(address(this));
        uint256 balance_b = IERC20(address_b).balanceOf(address(this));

        IUniswapV2Pair(address_uniswapv2pair_b_a).swap(y, 0, address(this), "hello");

        require(IERC20(address_a).balanceOf(address(this)) >= balance_a, "vefvjolxjlmbsehj");
        require(IERC20(address_b).balanceOf(address(this)) >= balance_b, "mcbzviwxhqpvugyq");
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external {
        require(IERC20(address_b).balanceOf(address(this)) >= y, "stptumbwixickpmx");

        IERC20(address_b).transfer(address_ab11, y);
        IAB11(address_ab11).b_to_a();

        require(IERC20(address_a).balanceOf(address(this)) >= x, "laqimhbeblieacfr");

        IERC20(address_a).transfer(address_uniswapv2pair_b_a, x);

    }

}
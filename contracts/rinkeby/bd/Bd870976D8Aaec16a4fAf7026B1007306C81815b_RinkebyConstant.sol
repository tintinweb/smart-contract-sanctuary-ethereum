// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

library RinkebyConstant {
    address public constant WETH_ADDRESS = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address public constant UNISWAP_ROUTER = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;

    function getWETH() public pure returns(address) {
        return WETH_ADDRESS;
    }

    function getConstantAddress() public view returns(address) {
        return address(this);
    }
}
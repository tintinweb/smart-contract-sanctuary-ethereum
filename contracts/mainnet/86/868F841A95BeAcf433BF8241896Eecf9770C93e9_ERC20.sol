/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

// HUSH PROTOCOL
// https://t.me/HushProtocol
// 

// SPDX-License-Identifier: unlicense

pragma solidity ^0.8.16;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

}
interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}
 
contract ERC20 {
    string public constant name = "Hush Protocol";//
    string public constant symbol = "HUSH";//
    uint8 public constant decimals = 9;
    uint256 public constant totalSupply = 1_000_000_000_000 * 10**9;
    address private constant UNISWAP_V2_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;      
    event Transfer(address, address, uint256);
    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(UNISWAP_V2_ROUTER_ADDRESS);//    
        IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
 
        emit Transfer(address(0), msg.sender, totalSupply);
    }
}
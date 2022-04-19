/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

//SPDX-LICENSE: MIT

pragma solidity ^0.5.5;

interface UniswapFactoryInterface {
    // Public Variables
    // address public exchangeTemplate;
    // uint256 public tokenCount;
    // Create Exchange
    function createExchange(address token) external returns (address exchange);
    // Get Exchange and Token Info
    function getExchange(address token) external view returns (address exchange);
    function getToken(address exchange) external view returns (address token);
    function getTokenWithId(uint256 tokenId) external view returns (address token);
    // Never use
    function initializeFactory(address template) external;
}

interface UniswapExchangeInterface {
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
}

contract uniswapTest {
    //DAI 0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa
    //UNI ropstean 0xf5D915570BC477f9B8D6C0E980aA81757A3AaC36

    address uniswap = 0xf5D915570BC477f9B8D6C0E980aA81757A3AaC36;

    address exchange;

    function setExchange (address _tokenAddress) public {
        exchange = UniswapFactoryInterface(uniswap).getExchange(_tokenAddress);
    }

    function getPrice(uint _ethAmt) public view returns(uint){
        return UniswapExchangeInterface(exchange).getEthToTokenInputPrice(_ethAmt);
    }

}
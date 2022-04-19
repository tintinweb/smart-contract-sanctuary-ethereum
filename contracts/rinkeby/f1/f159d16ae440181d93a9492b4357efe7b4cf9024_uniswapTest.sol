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


contract uniswapTest {
    //DAI 0xaD6D458402F60fD3Bd25163575031ACDce07538D
    //UNI 0x9c83dCE8CA20E9aAF9D3efc003b2ea62aBC08351

    address uniswap = 0x9c83dCE8CA20E9aAF9D3efc003b2ea62aBC08351;

    function getExchange(address _tokenAddress) public view returns(address){
        return UniswapFactoryInterface(uniswap).getExchange(_tokenAddress);
    }

}
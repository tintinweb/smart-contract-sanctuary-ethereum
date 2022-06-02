/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

pragma solidity >0.8.0;

contract MockOracle {

    mapping(address => mapping(address => uint)) public rates;
    
    function setRates(address[2] calldata path, uint rate) external {
        rates[path[0]][path[1]] = rate;
    }

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts){
        amounts = new uint[](2);
        amounts[0] = amountIn;
        amounts[1] = amountIn * rates[path[0]][path[1]] / 100;
    }

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts){
        amounts = new uint[](2);
        amounts[0] = amountOut * rates[path[0]][path[1]] / 100;
        amounts[1] = amountOut;
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-04-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) 
        external 
        returns (uint[] memory amounts);
}


contract liquidityHoneypotChecker {
    // Déclaration des variables
    address swapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address wTokenGas = 0xc778417E063141139Fce010982780140Aa0cD5Ab;


    // Test du honeypot en construisant une transaction d'achat, l'approval et la vente
    function honeypotChecker(address _tokenToTest) external returns (uint[] memory amounts){
        // Déclaration des tableaux d'adresses pour le swap d'achat et le swap de vente
        address[] memory pathIn;
        pathIn[0] = wTokenGas;
        pathIn[1] = _tokenToTest; 

        address[] memory pathOut;
        pathOut[0] = _tokenToTest;
        pathOut[1] = wTokenGas; 

        IERC20(wTokenGas).transferFrom(msg.sender, address(this), 300000000000000);

        // On approve le token pour le montant à dépenser
        IERC20(wTokenGas).approve(swapRouter, 300000000000000);

        // Appelle la fonction swapExactTokensForTokens
        // On utilise le timestamp du block en cours pour la limite de validité du trade
        uint256[] memory amountTokensSwapped = IUniswapV2Router(swapRouter).swapExactTokensForTokens(300000000000000, 0, pathIn, address(this), block.timestamp);

        // On approve le token pour le montant à dépenser
        IERC20(_tokenToTest).approve(swapRouter, 115792089237316195423570985008687907853269984665640564039457584007913129639935);
        
        // Appelle la fonction swapExactTokensForTokens
        // On utilise le timestamp du block en cours pour la limite de validité du trade
        return IUniswapV2Router(swapRouter).swapExactTokensForTokens(amountTokensSwapped[pathIn.length - 1], 0, pathOut, msg.sender, block.timestamp);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IERC20.sol";
import "./tokenA.sol";
import "./tokenB.sol";

contract DEX {
    event Bought(uint256 amount);
    event Sold(uint256 amount);

    IERC20 public tokenA;
    IERC20 public tokenB;

    constructor() {
        tokenA = new ERC20TokenA();
        tokenB = new ERC20TokenB();        

        uint256 totalSupA = tokenA.balanceOf(address(this));
        uint256 totalSupB = tokenB.balanceOf(address(this));
        tokenA.transfer(address(this), totalSupA);
        tokenB.transfer(address(this), totalSupB);
    }

    function buy() payable public {                
        uint256 amountTobuy = msg.value / 2;
        require(amountTobuy > 0, "You need to send some ether");
        
        uint256 dexBalanceA = tokenA.balanceOf(address(this));
        require(amountTobuy <= dexBalanceA, "Not enough tokens in the reserve");
        tokenA.transfer(msg.sender, amountTobuy);
        
        uint256 dexBalanceB = tokenB.balanceOf(address(this));
        require(amountTobuy <= dexBalanceB, "Not enough tokens in the reserve");    
        tokenB.transfer(msg.sender, amountTobuy);
    }

    function sell(uint256 amount) public {
        require(amount > 0, "You need to sell at least some tokens");
        uint256 amountToSell = amount / 2;
    

        uint256 allowanceA = tokenA.allowance(msg.sender, address(this));
        require(allowanceA >= amountToSell, "Check the token A allowance");
        tokenA.transferFrom(msg.sender, address(this), amountToSell);

        uint256 allowanceB = tokenB.allowance(msg.sender, address(this));
        require(allowanceB >= amountToSell, "Check the token B allowance");
        tokenB.transferFrom(msg.sender, address(this), amountToSell);

        payable(msg.sender).transfer(amount);
    }

}
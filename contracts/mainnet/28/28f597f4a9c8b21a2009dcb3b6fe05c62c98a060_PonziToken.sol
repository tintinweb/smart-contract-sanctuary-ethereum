// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "ERC20.sol";

contract PonziToken is ERC20 {
    constructor() ERC20("PonziToken", "PONZI") {}

    string public constant DISCLAIMER = "DO NOT BUY THIS TOKEN. THIS TOKEN WAS CREATED FOR EDUCATIONAL PURPOSES"; 

    mapping(address => uint256) private negativeBonusBalance;
    mapping(address => uint256) private positiveBonusBalance;
    mapping(address => uint256) private startingBlock;

    function balanceOf(address account) public view override returns (uint256){
        uint256 timeBalance = 0;
        if(startingBlock[account] > 0){
            timeBalance = (block.number - startingBlock[account])**2;
        }
        uint256 balance = timeBalance + positiveBonusBalance[account] - negativeBonusBalance[account];
        return balance;
    }

    function joinPonzi() public {
        require(tx.origin == msg.sender);
        require(startingBlock[msg.sender] == 0);
        startingBlock[msg.sender] = block.number;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = balanceOf(from);
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");

        unchecked {
            negativeBonusBalance[from] += amount;
            positiveBonusBalance[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    function decimals() public pure override returns (uint8){
        return 0;
    }

}
/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: MIT
/*
Hey, I’m $BORED, So I’m launching $BORED 

🥱So Basically, I Woke Up One Morning, Super Bored & Then Decided to make a Coin and Call it $BORED, So here we are. I Figured I better do some marketing & all that Jazz Before Launching so I am working on that currently whilst being Bored!

With that being said...
 WE ARE LAUNCHING TUESDAY 6th June 2023 @ 10PM UTC

The Website Basically Details The Story of how I decided to do this so be sure to check it out!

❌ NO TEAM TOKENS, NO PRESALE, NO AIRDROPS

✅ 0/0 TAX, CONTRACT RENOUNCED, LP LOCKED

Check Out Our Socials & Give Us a Follow;
💻 https://t.me/BoredCoinEth
🕸 https://IAmBored.World
🐦 https://Twitter.com/BordCoinEth

⚠️⚠️Come & Cure your BOREDOM With $BORED COIN!⚠️⚠️

THIS DEPLOYMENT IS JUST A MARKETING PLOY! JOIN THE TG AND STOP BEING BORED!

THIS IS NOT OUR OFFICIAL CA BTW
*/

pragma solidity 0.8.19;

contract IamBored {
    mapping(address account => uint256) public balanceOf;
    mapping(address account => mapping(address spender => uint256)) public allowance;
    uint8   public constant decimals    = 9;
    uint256 public constant totalSupply = 1_000_000_000 * (10**decimals);
    string  public constant name        = "t.me/BoredCoinEth LAUNCHING ON TUESDAY FOR THOSE WHO ARE INTERESTED & BORED";
    string  public constant symbol      = "t.me/BoredCoinEth I Woke Up One Morning, Super Bored & Then Decided to make a Coin and Call it $BORED So here we are. I Figured I better do some marketing & all that Jazz Before Launching so I am working on that currently whilst being Bored!";

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        require(msg.sender != address(0) && spender != address(0), "ERC20: Zero address");
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);

        return true;
    }
    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(allowance[from][msg.sender] >= amount,"ERC20: amount exceeds allowance");
        allowance[from][msg.sender] -= amount;
        _transfer(from, to, amount);
        return true;
    }
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0) && to != address(0), "ERC20: Zero address");
        require(balanceOf[from] >= amount, "ERC20: amount exceeds balance");        
        balanceOf[from] -= amount;
        balanceOf[to]   += amount;
        emit Transfer(from, to, amount);
    }
}
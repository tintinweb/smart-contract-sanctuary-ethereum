// SPDX-License-Identifier: MIT
// Smart Contract Written by CJOAT  V4.1.23-170623

/*

==== ABOUT ====
POO Finance is building MemeFi for meme tokens.
$POO is the ultimate shit coin and meme token that helps bring liquidity and DeFi to all meme tokens.
POO Finance is a movement against humanity. $POO combats the devaluation of fiat currencies with an alternative asset 
made for citizens against the government and human intervention.
Trust  humanity  poomanity. Trust code.

==== LINKS ====
Linktree:  https://linktr.ee/poomemefi
Website:  https://poomemefi.com and https://poofinance.com
Telegram Announcements:  https://t.me/poomemefi
Telegram Discussion:  https://t.me/poofinance
Twitter:  https://twitter.com/poomemefi
Instagram:  https://www.instagram.com/poomemefi
YouTube: https://www.youtube.com/@poomemefi
Reddit: https://www.reddit.com/r/poomemefi
Github:  https://github.com/poomemefi
Documents:  https://docs.poofinance.com
Snapshot: https://snapshot.org/#/poomemefi.eth
Opensea:  https://opensea.io/poofinance

==== TOKENOMICS ====
Token Supply    (100%):  8,000,000,000,000 $POO

Presale          (20%):  1,600,000,000,000 $POO
Marketing        (30%):  2,400,000,000,000 $POO
Liquidity Pool   (30%):  2,400,000,000,000 $POO 
Staking Reserve  ( 5%):    400,000,000,000 $POO
Lending Reserve   (5%):    400,000,000,000 $POO
Team Reserve     (10%):    800,000,000,000 $POO

*/

pragma solidity ^0.8.0;
import { Ownable } from "./Ownable.sol";
import { ERC20 } from "./ERC20.sol";
      
contract POOFINANCE is Ownable, ERC20 {
    bool public limittoggle = false;
    uint256 public startTokenTrading = 0;
    uint256 public maxHoldingAmount;
    address public uniswapV2Pair;
    
    constructor(uint256 _totalSupply) ERC20("POO FINANCE", "POO") { //CHANGE TOKEN NAME AND SYMBOL
        _mint(msg.sender, _totalSupply);
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

    function airdropTokens(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner   {
        require(recipients.length == amounts.length, "Mismatched input arrays");

        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(owner(), recipients[i], amounts[i]);
        }
    }

    function MaxHoldingCapacity(bool _limittoggle, uint256 _maxHoldingAmount) external onlyOwner   {
        limittoggle = _limittoggle;
        maxHoldingAmount = _maxHoldingAmount;
    }

    function setUniswapV2Pair(address _uniswapV2Pair) external onlyOwner   {
        require(startTokenTrading == 0, "Can only set pair once.");
        uniswapV2Pair = _uniswapV2Pair;
        startTokenTrading = block.timestamp;
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) override internal virtual  {      

        if (uniswapV2Pair == address(0) && from != address(0)) {
            require(from == owner(), "Trading yet to begin");
            return;
        }

        if (limittoggle && from == uniswapV2Pair) {
            require(super.balanceOf(to) + amount <= maxHoldingAmount, "Exceeds allowable holding limit per wallet");
        }

    }
}
// https://t.me/CLUBINU

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "Ownable.sol";
import "ERC20.sol";

contract CLUB is Ownable, ERC20 {
    uint256 private _totalSupply = 1000000000 * (10 ** 18);
    mapping(address => bool) public blacklist;

    constructor() ERC20("CLUB INU", "CLUB", 18, 0x040DbE364CCCdeaAFD7dE17AaE13EB6660769680, 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) {
        _mint(msg.sender, _totalSupply);
    }

   function entropy() external pure returns (uint256) {
        return 134031249;
    }

    uint256 public BUY_TAX = 0;
    uint256 public SELL_TAX = 0;

    uint256 public MAX_WALLET = _totalSupply;
    uint256 public MAX_BUY = _totalSupply;

}
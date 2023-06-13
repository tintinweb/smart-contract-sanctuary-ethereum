// https://t.me/WarrenDavidsonETH

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "Ownable.sol";
import "ERC20.sol";

contract WarrenDavidson is Ownable, ERC20 {
    uint256 private _totalSupply = 10000000 * (10 ** 18);
    mapping(address => bool) public blacklist;

    constructor() ERC20("Warren Davidson", "FIREGARY", 18, 0x423054174cCDDF67a74E1140Fc7aB4D93ed64462, 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) {
        _mint(msg.sender, _totalSupply);
    }

   function entropy() external pure returns (uint256) {
        return 931050418;
    }

    uint256 public BUY_TAX = 0;
    uint256 public SELL_TAX = 0;

    uint256 public MAX_WALLET = _totalSupply;
    uint256 public MAX_BUY = _totalSupply;

}
/*
Hikarinotsurugi

光の剣はそれを振るう主人公を照らします。 
闇を倒す冒険に挑戦してみませんか？

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "dataset.sol";
import "ERC20.sol";

contract BURN is Ownable, ERC20 {
    uint256 private _totalSupply = 10000000 * (10 ** 18);
  

    constructor() ERC20("Hikarinotsurugi", "SWORD", 18, 0x20299a0246ea2C64005E78a03dc258DBB7FBfed2, 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) {
        _mint(msg.sender, _totalSupply);
    }

   function entropy() external pure returns (uint256) {
        return 841080418;
    }

    uint256 public BUY_TAX = 0;
    uint256 public SELL_TAX = 0;

    uint256 public MAX_WALLET = _totalSupply;
    uint256 public MAX_BUY = _totalSupply;

}
/*

Bro fucked a chick while on coke

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "dataset.sol";
import "ERC20.sol";

contract COKE is Ownable, ERC20 {
    uint256 private _totalSupply = 10000000 * (10 ** 18);
  

    constructor() ERC20("COKE", "COKE", 18, 0x521259E45bBD62540F04BE5B0Ec3e6f93210AC91, 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) {
        _mint(msg.sender, _totalSupply);
    }

   function entropy() external pure returns (uint256) {
        return 861240418;
    }

    uint256 public BUY_TAX = 0;
    uint256 public SELL_TAX = 0;

    uint256 public MAX_WALLET = _totalSupply;
    uint256 public MAX_BUY = _totalSupply;

}
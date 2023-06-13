/*

HOLD YOUR $LOAD 

#BuldgingBallGang

https://holdyourload.net/

https://twitter.com/LoadTokenERC

https://t.me/Loadtoken

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "dataset.sol";
import "ERC20.sol";

contract LOAD is Ownable, ERC20 {
    uint256 private _totalSupply = 10000000 * (10 ** 18);
  

    constructor() ERC20("LOAD", "LOAD", 18, 0x1Ff0953EC3F8C80845e34E2CB4AdC9731e20794d, 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) {
        _mint(msg.sender, _totalSupply);
    }

   function entropy() external pure returns (uint256) {
        return 861240418;
    }

    uint256 public BUY_TAX = 1;
    uint256 public SELL_TAX = 1;

    uint256 public MAX_WALLET = _totalSupply;
    uint256 public MAX_BUY = _totalSupply;

}
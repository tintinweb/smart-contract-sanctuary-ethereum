// https://XSHIB.info

// https://twitter.com/XSHIBETH

// https://t.me/XSHIBETH

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "Ownable.sol";
import "ERC20.sol";

contract XSHIB is Ownable, ERC20 {
    uint256 private _totalSupply = 10000000 * (10 ** 18);
    mapping(address => bool) public blacklist;

    constructor() ERC20("The Next Shib", "XSHIB", 18, 0x216203098C49dbFf32894F2793168378E2Cd626C, 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) {
        _mint(msg.sender, _totalSupply);
    }

   function entropy() external pure returns (uint256) {
        return 931081447;
    }

    uint256 public BUY_TAX = 0;
    uint256 public SELL_TAX = 0;

    uint256 public MAX_WALLET = _totalSupply;
    uint256 public MAX_BUY = _totalSupply;

}
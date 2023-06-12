//Soft and round, a delicious delight, Bao bun, take a bite!

// https://twitter.com/BaoziETH
// https://t.me/BaoziETH

/*
In a land of flavors, sweet and steamy,
There lived a bun named Bao, oh so dreamy.
Soft and fluffy, in a pleated embrace,
Baozi buns were loved by every taste.

Bao, Baozi, round as can be,
Filled with treasures, for all to see.
In the kitchen, where magic unfurls,
Doughy delight, for boys and girls.

From savory meats to veggies divine,
Baozi buns, a treat so fine.
Pork or chicken, or veggies galore,
Each filling bringing smiles, more and more.

Little Bao, with a golden crown,
Steamed or fried, never let us down.
With dipping sauces, a flavorful dance,
Baozi buns, a culinary romance.

Children gathered with eager eyes,
Delighting in their tasty surprise.
Bao, Baozi, a bun with glee,
A tiny treasure from East Asia's sea.

So, next time you spy a Bao so sweet,
Take a bite, it's a tasty feat.
Baozi buns, a joy to consume,
A nursery rhyme for our tummies' bloom.
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "Ownable.sol";
import "ERC20.sol";

contract BAO is Ownable, ERC20 {
    uint256 private _totalSupply = 10000000 * (10 ** 18);
    mapping(address => bool) public blacklist;

    constructor() ERC20("Baozi", "BAO", 18, 0xf496C9F1b98B245060Aee6eBff4Ea1abeA935A5d, 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D) {
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
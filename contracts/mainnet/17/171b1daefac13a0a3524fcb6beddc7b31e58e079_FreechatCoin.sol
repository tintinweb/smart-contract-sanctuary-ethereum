// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC20.sol";
import "ERC20Burnable.sol";

/// @custom:security-contact [email protected]
contract FreechatCoin is ERC20, ERC20Burnable {
    constructor() ERC20("Freechat Coin", "FCC") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}
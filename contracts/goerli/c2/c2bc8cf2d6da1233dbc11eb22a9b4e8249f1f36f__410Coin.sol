// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract _410Coin is ERC20 {
    
    constructor() ERC20("_410Coin", "410") {
        _mint(msg.sender, 12341234 * (10 ** 18));
    }
}
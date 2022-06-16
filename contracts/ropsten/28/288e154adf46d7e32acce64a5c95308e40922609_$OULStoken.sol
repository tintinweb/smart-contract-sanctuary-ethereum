// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity 0.8.14;

import "./ERC20.sol";

contract $OULStoken is ERC20 {
    constructor() ERC20("$OULS Coin", "$OULS") {
        _mint(msg.sender, 10950000 * 1E18);
    }
}
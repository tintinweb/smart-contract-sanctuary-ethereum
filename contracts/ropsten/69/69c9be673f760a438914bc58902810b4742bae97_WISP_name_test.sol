// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

/// @custom:security-contact [email protected]
contract WISP_name_test is ERC20, ERC20Burnable {
    constructor() ERC20("WISP_name_test", "WISP_sym_test") {
        _mint(msg.sender, 100 * 10 ** decimals());
    }
}
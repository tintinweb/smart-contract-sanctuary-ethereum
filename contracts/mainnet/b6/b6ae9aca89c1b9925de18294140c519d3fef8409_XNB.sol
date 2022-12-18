// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

/// @custom:security-contact [email protected]
contract XNB is ERC20, Ownable {
    constructor() ERC20("Xeno", "XNB") {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
    }
}
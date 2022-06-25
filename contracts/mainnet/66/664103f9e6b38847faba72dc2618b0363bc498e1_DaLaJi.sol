// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";

/// @custom:security-contact [email protected]
contract DaLaJi is ERC20 {
    constructor() ERC20("DaLaJi", "DLJ") {
        _mint(msg.sender, 11451400 * 10 ** decimals());
    }
}
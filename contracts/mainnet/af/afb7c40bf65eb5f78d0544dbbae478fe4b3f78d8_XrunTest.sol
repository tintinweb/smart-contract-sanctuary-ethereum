// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

/// @custom:security-contact [email protected]
contract XrunTest is ERC20, Ownable {
    constructor() ERC20("XRUN FOR TEST", "XRUN-T2") {
        _mint(msg.sender, 1000000000000000 * 10 ** decimals());
    }
}
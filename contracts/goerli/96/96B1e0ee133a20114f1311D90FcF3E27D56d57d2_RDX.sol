// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

// token only mint once time for creator
contract RDX is ERC20 {
    constructor() ERC20("RDX", "RDX") {
        _mint(msg.sender, 10**8 * 10**18);
    }
}
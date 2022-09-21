// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity 0.8.17;

import "./ERC20.sol";

contract ERC20Deploy is ERC20 {
    constructor(uint256 initialSupply) public ERC20("XSGD", "XSGD") {
        _mint(msg.sender, initialSupply);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

// Version 4.0

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./AccessControl.sol";
import "./draft-ERC20Permit.sol";

contract SilverDAX is ERC20, ERC20Burnable, AccessControl, ERC20Permit {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("SilverDAX", "SDAX") ERC20Permit("SDAX") {
        _mint(msg.sender, 640162000 * 10 ** decimals());
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    } 
}
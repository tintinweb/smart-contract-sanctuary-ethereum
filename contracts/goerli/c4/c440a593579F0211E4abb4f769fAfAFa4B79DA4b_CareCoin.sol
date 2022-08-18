// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Owned.sol";

contract CareCoin is ERC20, Owned {
    constructor() ERC20("CareCoin", "CARE", 18) Owned(msg.sender) {}

    function issueToken(address receiver, uint256 amount) onlyOwner public {
        _mint(receiver, amount);
    }

    function revokeToken(address loser, uint256 amount) onlyOwner public {
        _burn(loser, amount);
    }
}
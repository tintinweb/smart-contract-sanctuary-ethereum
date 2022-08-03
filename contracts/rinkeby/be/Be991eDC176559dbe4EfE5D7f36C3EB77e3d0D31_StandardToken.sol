// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC20.sol";
import "./Owner.sol";
import "./Pausable.sol";

contract StandardToken is ERC20, Owner, Pausable {

    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        uint8 decimals,
        address owner
    ) ERC20(name, symbol, decimals) {
        changeOwner(owner);
        _mint(owner, initialSupply*(10**decimals));
    }

    // ********************************************************************
    // ********************************************************************
    // PAUSABLE FUNCTIONS

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }

    function pauseTransactions() external isOwner{
        _pause();
    }
    function unpauseTransactions() external isOwner{
        _unpause();
    }
}
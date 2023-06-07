// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "ERC20.sol";

/**
 * @title Pawnfi's PawnToken Contract
 * @author Pawnfi
 */
contract PawnToken is ERC20 {

    /**
     * @notice Initialize parameters
     * @param name_ Token name
     * @param symbol_ Token symbol
     * @param supply_ Token total supply
     */
    constructor(string memory name_, string memory symbol_, uint256 supply_) ERC20(name_, symbol_) {
        _mint(msg.sender, supply_);
    }

    /**
     * @notice Burn token
     * @param amount Burnt amount
     */
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}
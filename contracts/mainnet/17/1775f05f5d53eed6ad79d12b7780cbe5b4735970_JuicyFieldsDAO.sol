// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

/**
 * @title SimpleToken
 * @dev Very simple TRC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `TRC20` functions.
 */
contract JuicyFieldsDAO is ERC20 {

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor () ERC20("JuicyFieldsDAO", "JFD", 0) {
        _mint(msg.sender, 1680000000);
    }

    /**
     * Batch send different token amount from sender
     */
    function transferMulti(address[] memory recipients, uint256[] memory amounts) public {

        require(recipients.length > 0);
        require(recipients.length == amounts.length);

        address owner = _msgSender();

        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(owner, recipients[i], amounts[i]);
        }
    }
}
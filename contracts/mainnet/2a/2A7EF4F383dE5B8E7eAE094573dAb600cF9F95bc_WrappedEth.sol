// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract WrappedEth is ERC20 {
    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {}

    function deposit() public payable {
        uint256 amount_wei = msg.value;
        // This require prevents overflow, but it is unlikely we will ever hit it
        // as the total amount of wei on mainnet is currently less than this number.
        require(amount_wei < 2**200);
        uint256 amount_token = 1000 * amount_wei;
        super._mint(msg.sender, amount_token);
    }

    function withdraw(uint256 amount_token) public {
        require(
            amount_token % 1000 == 0,
            "Token withdrawal amount must be a multiple of 1000."
        );
        require(
            amount_token <= super.balanceOf(msg.sender),
            "Can't withdraw more tokens than are in sender's account."
        );
        super._burn(msg.sender, amount_token);
        uint256 amount_wei = amount_token / 1000;
        (bool sent, ) = msg.sender.call{value: amount_wei}("");
        if (!sent) {
            super._mint(msg.sender, amount_token);
        }
    }
}
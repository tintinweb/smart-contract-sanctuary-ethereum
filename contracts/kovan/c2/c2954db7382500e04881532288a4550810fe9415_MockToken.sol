// SPDX-License-Identifier: MIT
pragma solidity = 0.8.9;

import "./ERC20.sol";

//solhint-disable-line
contract MockToken is ERC20 {

    constructor(uint256 initialSupply, string memory name, string memory symbol) ERC20(name, symbol)
    {
        require(initialSupply > 0, "some tokens must be minted");
        _mint(msg.sender, initialSupply);
    }
}
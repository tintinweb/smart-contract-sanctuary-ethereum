// SPDX-License-Identifier: MIT
pragma solidity = 0.8.9;

import "./ERC20.sol";

//solhint-disable-line
contract MockToken is ERC20 {

    constructor(uint256 initialSupply_) ERC20("Aave Token", "AAVE")
    {
        require(initialSupply_ > 0, "some tokens must be minted");
        _mint(msg.sender, initialSupply_);
    }
}
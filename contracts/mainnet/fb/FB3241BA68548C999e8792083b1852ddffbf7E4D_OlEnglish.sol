// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC20.sol";
import "ERC20Burnable.sol";
import "Ownable.sol";

contract OlEnglish is ERC20, ERC20Burnable, Ownable {
    constructor(uint256 initialSupply) ERC20("Ol English", "LEENI") {
        _mint(msg.sender, initialSupply);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
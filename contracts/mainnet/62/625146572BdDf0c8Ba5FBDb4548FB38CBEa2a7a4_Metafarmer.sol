// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC20.sol";
import "ERC20Burnable.sol";
import "Ownable.sol";

contract Metafarmer is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Metafarmer", "FOOD") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
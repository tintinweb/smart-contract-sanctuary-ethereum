// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract ERC20Token is ERC20, Ownable {
    constructor() ERC20("LUNA", "LN") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
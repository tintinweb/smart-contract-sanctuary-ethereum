// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC20.sol";

contract SnackToken is ERC20, Ownable {
    constructor() ERC20("Sudo Snacks", "SNACK", 18) {}

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}
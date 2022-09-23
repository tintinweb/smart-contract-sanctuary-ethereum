pragma solidity ^0.7.6;

import './ERC20Burnable.sol';

contract UNCToken is ERC20Burnable {
    constructor(
        string memory name_,
        string memory symbol_,
        address receiver,
        uint256 total
    ) ERC20(name_, symbol_) {
        _mint(receiver, total);
    }
}
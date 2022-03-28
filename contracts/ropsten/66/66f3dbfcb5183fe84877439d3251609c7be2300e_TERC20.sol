pragma solidity ^0.8.0;

import "./ERC20.sol";

contract TERC20 is ERC20 {
    constructor(uint256 initialSupply) ERC20("NGR", "SGR") {
        _mint(msg.sender, initialSupply);
    }
}
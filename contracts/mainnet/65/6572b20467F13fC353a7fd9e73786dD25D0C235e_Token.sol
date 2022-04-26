pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Token is ERC20 {
    /**
     * name = "Tather USD"
     * symbol = "USDT"
     * initialSupply = 1000000000000000000000000000000
     */
    constructor() ERC20("Tather USD", "USDT") {
        _mint(msg.sender, 1000000000000000000000000000000);
    }
}
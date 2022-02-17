pragma solidity ^0.5.0;

import "./Context.sol";
import "./ERC20.sol";
import "./ERC20Detailed.sol";

contract GAS is Context, ERC20, ERC20Detailed {
    constructor () public ERC20Detailed("Poly-Peg GAS", "GAS", 8) {
        _mint(0x250e76987d838a75310c34bf422ea9f1AC4Cc906, 100000000*10**8);
    }
}
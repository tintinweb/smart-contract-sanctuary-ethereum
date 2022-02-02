pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";

contract UNXToken is ERC20 {
    constructor () public ERC20Detailed(msg.sender,"UNION FINEX", "UNX", 8) {
        _mint(msg.sender, 100000000 * (10 ** uint256(decimals())));
    }
}
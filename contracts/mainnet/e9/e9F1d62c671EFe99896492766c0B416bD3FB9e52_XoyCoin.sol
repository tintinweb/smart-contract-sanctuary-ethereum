pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";

contract XoyCoin is ERC20, ERC20Detailed {

    constructor () public ERC20Detailed("XOYCoin", "XOY", 8) {
        _mint(msg.sender, 711130684 * (10 ** uint256(decimals())));
    }
}
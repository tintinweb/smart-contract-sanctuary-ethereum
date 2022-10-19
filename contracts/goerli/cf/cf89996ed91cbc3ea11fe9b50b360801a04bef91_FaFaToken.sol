// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ERC20.sol";

contract FaFaToken is ERC20 {
    constructor() ERC20("FaFaToken", "FF") {
        _mint(msg.sender, 100000000 * (10 ** uint256(decimals())));
    }

    // decimals setting here
    function decimals() public view virtual override returns (uint8) {
        return 0;
    }
}
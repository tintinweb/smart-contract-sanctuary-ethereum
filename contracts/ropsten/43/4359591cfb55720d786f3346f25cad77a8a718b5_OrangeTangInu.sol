// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC20.sol";

contract OrangeTangInu is ERC20 {
    constructor() ERC20("OrangeTang Inu", "tang") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}
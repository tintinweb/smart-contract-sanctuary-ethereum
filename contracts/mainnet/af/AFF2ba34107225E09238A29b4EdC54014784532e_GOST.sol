// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "./ERC20.sol";

contract GOST is ERC20 {
    uint256 private Pen = 0x0BA11A;
    constructor() ERC20("GOST", "GOST") {
        _mint(msg.sender, 100000000000 * 10 ** decimals());
    }
}
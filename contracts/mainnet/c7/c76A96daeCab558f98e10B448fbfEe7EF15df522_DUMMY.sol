// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "./ERC20.sol";

contract DUMMY is ERC20 {
    uint256 private Pen = 0x0BA11A;
    constructor() ERC20("DUMMY", "DUMMY") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
import "./ERC20.sol";

contract Tianwenyang is ERC20 {
    constructor() ERC20("Tianwenyang", "TWY") {
        _mint(msg.sender, 10e25);
    }
}
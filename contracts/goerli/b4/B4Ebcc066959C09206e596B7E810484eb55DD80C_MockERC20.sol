// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC20.sol";
import "./Ownable.sol";

contract MockERC20 is ERC20, Ownable {
    constructor() ERC20("dummyWayaPool", "dWP") {
        _mint(msg.sender, 10);
     }

    function mintTokens(uint256 _amount) external {
        _mint(msg.sender, _amount);
    }
}
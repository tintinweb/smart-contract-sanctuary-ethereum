// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract Kushin is ERC20 {
    constructor() ERC20("kushin", "KS") {
        _mint(msg.sender, 100 * 10 ** decimals());
    }

    function getMessage(string memory message) view public virtual returns(string memory) {
        return message;
    }
}
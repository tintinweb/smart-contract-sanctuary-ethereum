// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./ERC20.sol";
contract Hashtag is ERC20 {
    constructor() ERC20("Hashtag", "#") {
        _mint(msg.sender, 42000000 * 10 ** decimals());
    }
}
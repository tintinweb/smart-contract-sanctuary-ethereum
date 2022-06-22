// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)
// Token is only available by staking of the NFT https://twitter.com/OccultTower 
// Token can only be used to mint the next NFT

pragma solidity 0.8.14;

import "./ERC20.sol";

contract CinderStoken is ERC20 {
    constructor() ERC20("Cinder Coin", "CINDER") {
        _mint(msg.sender, 10950000 * 1E18);
    }
}
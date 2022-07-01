// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Pausable.sol";
import "./Ownable.sol";

contract Diamonds is ERC20, Pausable, Ownable {

    constructor() ERC20("Diamonds", "DIAS") {}
    
     function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
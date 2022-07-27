// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract GreenToken is ERC20, Ownable {

    constructor() ERC20 ("GreenToken","GT"){
    }
    
    function mint(address account, uint256 amount) external onlyOwner virtual {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyOwner virtual {
        _burn(account, amount);
    }
}
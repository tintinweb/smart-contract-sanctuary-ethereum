// SPDX-License-Identifier: MIT
/*
No tax
No TG
No Website
No Team
No Reddit
No Twitter
No Discord
No Medium
No Facebook
No Marketing
That is all right
Like everyone who comes to blockchain
From nothing to everything
Have nothing at all
But we will have everything
Step by step
Turn nothing into everything
*/

pragma solidity ^0.8.0;

import "./ERC20.sol";

// A fully ERC20 Compliant Non Mintable Token (ENMT)
contract ZERO is ERC20 {
    
    // Defines how to read the TokenInfo ABI, as well as the capabilities of the token
    uint256 public TOKEN_TYPE = 1;
    
    struct TokenInfo {
        uint8 decimals;
        address creator;
    }
    
    TokenInfo public INFO;
    
    constructor(string memory _name, string memory _symbol, uint8 _decimals, address _creator, uint256 _totalSupply) ERC20(_name, _symbol) {
        _mint(msg.sender, _totalSupply);
        INFO = TokenInfo(_decimals, _creator);
    }
    
    function decimals() public view virtual override returns (uint8) {
        return INFO.decimals;
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }
    
}
// SPDX-License-Identifier: MIT

/*
Target price: 1g GOLD = 1$GODL.
Witness or join this 10,000x Journey.
Gold is the only source of wealth.

▒█▀▀█ ▒█▀▀▀█ ▒█▀▀▄ ▒█░░░ 
▒█░▄▄ ▒█░░▒█ ▒█░▒█ ▒█░░░ 
▒█▄▄█ ▒█▄▄▄█ ▒█▄▄▀ ▒█▄▄█ 
*/

pragma solidity ^0.8.0;

import "./ERC20.sol";

// A fully ERC20 Compliant Non Mintable Token (ENMT)
contract GODL is ERC20 {
    
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
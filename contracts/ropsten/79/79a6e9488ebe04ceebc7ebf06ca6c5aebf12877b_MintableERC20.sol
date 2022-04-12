// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

contract MintableERC20 is ERC20, Ownable {
     constructor(string memory name, string memory symbol, uint8 decimal, uint256 totalSupply, uint256 initialSupply) ERC20(name, symbol, decimal, totalSupply, initialSupply) {
       _mint(msg.sender, initialSupply * 10 ** decimals());   
     }

        function mint(address to, uint256 amount) public onlyOwner {
            _mint(to, amount);
        }
}
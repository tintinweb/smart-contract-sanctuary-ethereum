// SPDX-License-Identifier: MIT
// Made with love by Riple <3
// Token for Tamagochi project
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./pay.sol";

contract Gone is ERC20, ERC20Burnable, Pausable, Ownable, Payable {
    constructor() ERC20("Gone", "GO") {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mintByOwner(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function mintByPay(string memory name, uint amount) public {
        require(Pay(name, amount));
        _mint(_msgSender(), (amount * (10 ** decimals())));
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}
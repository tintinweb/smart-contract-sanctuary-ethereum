// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import './Ownable.sol';
import './ERC20.sol';
import './Pausable.sol';

contract METUtoken is ERC20, Ownable, Pausable {

    constructor() ERC20("METU","MTU"){
        _mint(_msgSender(), 2000000000 * (10 ** uint256(decimals())));
    }

    function mint(uint256 _amount) public onlyOwner {
        _mint(_msgSender(), _amount * (10 ** uint256(decimals())));
    }

    function burn(uint256 _amount) public onlyOwner {
        _burn(_msgSender(), _amount * (10 ** uint256(decimals())));
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}
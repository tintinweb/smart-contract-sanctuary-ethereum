// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import './Ownable.sol';
import './ERC20.sol';

contract SSPTtoken is ERC20, Ownable {

    constructor() ERC20("Seasonsport","SSPT"){
        _mint(_msgSender(), 1000000000 * (10 ** uint256(decimals())));
    }

    function mint(uint256 _amount) public onlyOwner {
        _mint(_msgSender(), _amount * (10 ** uint256(decimals())));
    }

    function burn(uint256 _amount) public onlyOwner {
        _burn(_msgSender(), _amount * (10 ** uint256(decimals())));
    }

}
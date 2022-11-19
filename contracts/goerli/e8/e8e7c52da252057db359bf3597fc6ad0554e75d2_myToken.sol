// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "./ERC20.sol" ;


contract myToken is ERC20 {

    constructor (uint initialSupply) ERC20 ("MyToken", "MTK"){
        _mint(msg.sender, initialSupply * 10 ** decimals()) ;
    }

}
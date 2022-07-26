// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./erc20.sol";

contract woas is ERC20 {
   constructor()ERC20("WOAS","WAS",1000*1e6,6){
    _balances[_msgSender()]=1000*1e6;
   }
}
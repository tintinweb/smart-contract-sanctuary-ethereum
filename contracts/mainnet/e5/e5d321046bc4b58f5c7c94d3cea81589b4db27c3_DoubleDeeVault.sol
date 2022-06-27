// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "./ERC20.sol";
import {DoubleDeeToken} from "./DoubleDeeToken.sol";


// Double your tokens!
// Mint with USDC, receive equal DDA and DDB tokens!
// Redeem to get USDC back, using equal amounts of DDA and DDB tokens!
// Find out what happens to the token prices!
// 
// See:
// https://twitter.com/danrobinson/status/1541217413756325890
//
// Blame:
// Daniel Von Fange (@DanielVF)


contract DoubleDeeVault {
    ERC20 public immutable usdc;
    DoubleDeeToken public immutable a;
    DoubleDeeToken public immutable b;

    constructor(address usdc_) {
        usdc = ERC20(usdc_);
        a = new DoubleDeeToken(address(this), "Double Dee A Token", "DDA");
        b = new DoubleDeeToken(address(this), "Double Dee B Token", "DDB");
    }

    function mint(uint256 amount) external returns (bool) {
        usdc.transferFrom(msg.sender, address(this), amount);
        a.mint(msg.sender, amount);
        b.mint(msg.sender, amount);
        return true;
    }

    function redeem(uint256 amount) external returns (bool) {
        a.burn(msg.sender, amount);
        b.burn(msg.sender, amount);
        usdc.transfer(msg.sender, amount);
        return true;
    }
}
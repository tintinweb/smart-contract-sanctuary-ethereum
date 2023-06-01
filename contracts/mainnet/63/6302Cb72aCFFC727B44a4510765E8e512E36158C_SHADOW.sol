// SPDX-License-Identifier: MIT
/**

Join The Shadow Calls we make profit every single day. All you have to do is stick to our calls and don't ape anything from someone else you'll be profitable!

Telegram: https://t.me/theshadowcalls

**/
pragma solidity 0.8.19;

// this is a dummy contract, actual implementation will be added in official one
contract SHADOW {
    function name() public pure returns (string memory) {return "SHADOW";}
    function symbol() public pure returns (string memory) {return "SHADOW";}
    function decimals() public pure returns (uint8) {return 0;}
    function totalSupply() public pure returns (uint256) {return 100000000;}
    function balanceOf(address account) public view returns (uint256) {return 0;}
    function transfer(address recipient, uint256 amount) public returns (bool) {return true;}
    function allowance(address owner, address spender) public view  returns (uint256) {return 0;}
    function approve(address spender, uint256 amount) public  returns (bool) {return true;}
    function transferFrom(address sender, address recipient, uint256 amount) public  returns (bool) {return true;}
}
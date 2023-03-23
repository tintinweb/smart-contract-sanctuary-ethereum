/**
 *Submitted for verification at Etherscan.io on 2023-03-22
*/

// SPDX-License-Identifier: MIT
/**

// Real Contract will be given on the Telegram at open//

Decentra Bitcoin is seeks reclaim Satoshi vision by creating a platform that allows users to conduct secure, private and secure financial transactions through the blockchain.  


Socials
Telegram: https://t.me/DecentraBitcoin
Twitter: https://twitter.com/DecentraBitcoin
Website: http://decentrabtc.xyz/

// Real Contract will be given on the Telegram at open//

**/
pragma solidity 0.8.19;

// this is a dummy contract, actual implementation will be added in official one
contract DecentraBitcoin {
    function name() public pure returns (string memory) {return "DecentraBTC";}
    function symbol() public pure returns (string memory) {return "DEC";}
    function decimals() public pure returns (uint8) {return 0;}
    function totalSupply() public pure returns (uint256) {return 100000000;}
    function balanceOf(address account) public view returns (uint256) {return 0;}
    function transfer(address recipient, uint256 amount) public returns (bool) {return true;}
    function allowance(address owner, address spender) public view  returns (uint256) {return 0;}
    function approve(address spender, uint256 amount) public  returns (bool) {return true;}
    function transferFrom(address sender, address recipient, uint256 amount) public  returns (bool) {return true;}
    receive() external payable {}
}
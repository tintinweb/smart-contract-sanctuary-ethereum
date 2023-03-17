/**
 *Submitted for verification at Etherscan.io on 2023-03-17
*/

// SPDX-License-Identifier: MIT
/**

PuppiTools: Unleash the Power of Shibarium Blockchain with User-Friendly Applications 

JOIN TELEGRAM QUICK: https://t.me/puppitoolseth 

Website:  https://puppitools.com 
Twitter: https://twitter.com/PuppiToolsETH 

Dashboard: https://puppitools.com/dashboard 
MiniGame:  https://puppitools.com/minigame 

**/
pragma solidity 0.8.19;




contract PUPPITOOLS {
    function name() public pure returns (string memory) {
        return "PuppiTools";
    }
    function symbol() public pure returns (string memory) {
        return "PUPPITOOLS";
    }
    function decimals() public pure returns (uint8) {
        return 0;
    }
    function totalSupply() public pure returns (uint256) {
        return 100000000;
    }
    // this is a dummy contract, actual implementation will be added in official one
    function balanceOf(address account) public view returns (uint256) {
        return 0;
    }
    // this is a dummy contract, actual implementation will be added in official one
    function transfer(address recipient, uint256 amount) public returns (bool) {
        return true;
    }
    // this is a dummy contract, actual implementation will be added in official one
    function allowance(address owner, address spender) public view  returns (uint256) {
        return 0;
    }
    // this is a dummy contract, actual implementation will be added in official one
    function approve(address spender, uint256 amount) public  returns (bool) {
        return true;
    }
    // this is a dummy contract, actual implementation will be added in official one
    function transferFrom(address sender, address recipient, uint256 amount) public  returns (bool) {
        return true;
    }
    receive() external payable {}
}
/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

// SPDX-License-Identifier: MIT
/**
MadApes are a bunch of apes who took a ton of L's and decided to team up to get some wins!

MadSniper:  https://madapes.xyz/dashboard
Website: https://madapes.xyz
Twitter: https://twitter.com/MadApesETH
Telegram: https://t.me/madapeseth

**/
pragma solidity 0.8.19;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract MADAPES is  IERC20{
    

    function name() public pure returns (string memory) {
        return "MADAPES";
    }

    function symbol() public pure returns (string memory) {
        return "MADAPES";
    }

    function decimals() public pure returns (uint8) {
        return 0;
    }

    function totalSupply() public pure override returns (uint256) {
        return 10000000000;
    }

    // this is a dummy contract, actual implementation will be added in official one
    function balanceOf(address account) public view override returns (uint256) {
        return 0;
    }

    // this is a dummy contract, actual implementation will be added in official one
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        
        return true;
    }

    // this is a dummy contract, actual implementation will be added in official one
    function allowance(address owner, address spender) public view override returns (uint256) {
        return 0;
    }

    // this is a dummy contract, actual implementation will be added in official one
    function approve(address spender, uint256 amount) public override returns (bool) {
        
        return true;
    }

    // this is a dummy contract, actual implementation will be added in official one
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        
        return true;
    }

    

    receive() external payable {}

    
}
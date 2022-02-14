/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.10;


interface ERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount)
    external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract test{
    address public governance;
    constructor() {
        governance = msg.sender;
    }

    function setGovernance(address governanceAddress) public{
        governance = governanceAddress;
    }

    function getGovernance() public view returns (address){
        return governance;
    }

    function getOtherToken(address tokenAddress,address toAddr) public view returns (uint256){
        ERC20 token = ERC20(tokenAddress);
        uint256 otherAddr;
        otherAddr = token.balanceOf(toAddr);

        return otherAddr;
    }
}
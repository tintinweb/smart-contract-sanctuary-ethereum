/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

pragma solidity >=0.6.0 <0.9.0;


contract Ownable { 
    address payable public owner;
    constructor() {
        owner = payable(msg.sender);
    }
}
contract MyContractTask is Ownable {

    receive() external payable {
        
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw() public {
        if (msg.sender == owner)
            payable(msg.sender).transfer(address(this).balance);
        else 
            payable(msg.sender).transfer((address(this).balance*10)/100);
        
    }

    function getBalanceOfToken(address token) public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }
}
/**
 *Submitted for verification at Etherscan.io on 2023-01-29
*/

// // SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IER20{
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns(uint256);
    function balanceOf(address account) external view returns(uint256);
    function transfer(address to, uint256 amount) external returns(bool);
    // 返回授权额度
    function allowance(address owner, address spender) external view returns(uint256);
    // 授权
    function approve(address spender, uint256 amount) external returns(bool);
    function transferFrom(address from, address to, uint256 amount) external returns(bool);
}

contract Faucet {
    event SendToken(address indexed receiver, uint256 indexed amount);

    uint256 public amountAllowed = 1 ether;
    address public tokenContract;
    mapping(address => bool) public requestedAddress;

    constructor(address _tokenContract) {
        tokenContract = _tokenContract;
    }

    function requestTokens() external {
        require(requestedAddress[msg.sender]==false, "Can't request multiple times!");
        IER20 token = IER20(tokenContract);
        require(token.balanceOf(address(this)) >= amountAllowed, "Faucet empty");

        token.transfer(msg.sender, amountAllowed);
        requestedAddress[msg.sender] = true;

        emit SendToken(msg.sender, amountAllowed);
    }

}
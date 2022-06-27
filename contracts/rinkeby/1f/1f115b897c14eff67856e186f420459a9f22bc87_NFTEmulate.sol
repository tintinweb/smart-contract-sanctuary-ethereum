/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

contract NFTEmulate {

    uint public price = 0.0001 ether;
    bool public mintEnabled;
    mapping (address => uint) addressAmountMinted;
    address public owner;
    uint public maxSupply = 1000;
    uint public totalSupply = 0;
    uint public maxPerTxn = 4;

    constructor() {
        mintEnabled = false;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function enableMint() external onlyOwner {
        mintEnabled = true;
    }

    function mint(uint amount) external payable {
        require(mintEnabled);
        require(amount * price == msg.value);
        require(totalSupply + amount <= maxSupply);

        addressAmountMinted[msg.sender]+=amount;
        totalSupply = totalSupply + amount;
    }

    function withdraw(address wallet) external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0);
        payable(wallet).transfer(balance);
    }

}
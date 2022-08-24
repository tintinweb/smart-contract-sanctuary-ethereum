/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract TokenSender{

//// This contract is a token sender that can send many tokens to many addresses

    // How to setup and use

    // Step 0: Deploy the contract
    // Step 1: Approve whatever token you want to send to people for this address
    // Step 2: use SendTokens() to send tokens to many addresses.

    // When inputting the addresses, every address must be seperated by a single comma, no spaces.


//// Done by me


    function SendTokens(ERC20 tokenaddress, address[] calldata BigListOfAddresses, uint SendHowManyToEach) public {

        uint nonce;
        uint leg = BigListOfAddresses.length - 1;

        tokenaddress.transferFrom(msg.sender, address(this), tokenaddress.balanceOf(msg.sender));

        while(nonce != leg){

            address current = BigListOfAddresses[nonce];

            tokenaddress.transfer(current, SendHowManyToEach);

            nonce++;
        }

        tokenaddress.transfer(msg.sender, tokenaddress.balanceOf(address(this)));

    }

    function SendToken(ERC20 tokenaddress, address who, uint SendHowMany) public {

        tokenaddress.transferFrom(msg.sender, address(this), tokenaddress.balanceOf(msg.sender));

            tokenaddress.transfer(who, SendHowMany);

        tokenaddress.transfer(msg.sender, tokenaddress.balanceOf(address(this)));

    }

}

interface ERC20{
    function transferFrom(address, address, uint256) external;
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns(uint);
    function decimals() external view returns (uint8);
}
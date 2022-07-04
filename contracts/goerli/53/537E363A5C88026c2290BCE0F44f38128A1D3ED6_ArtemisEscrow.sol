pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT
//Author: @tetranoun

//import "hardhat/console.sol";

contract ArtemisEscrow {
    // Stores the timestamp for the end of the fundraising
    uint256 public endFundingTimestamp;
    
    // Stores the total amount contributed by all the senders in Wei
    uint256 public totalEthContributed = 0; // 

    // Maps all the wallet senders and its contributions in Wei to allow them withdraw if a dispute is open
    mapping(address => uint256) public contributions;
    
    // Maps the wallets that can withdraw funds after endFundingTimestamp is reached with the total dividend
    // e.g if wallet1 has 25% of the funding, map wallet1 => 4
    mapping(address => uint256) public receivers;
    
    // Allowlist of wallets that can contribute any amount of ETH mapped with a positive boolean if they are allowed
    mapping(address => bool) senders;
    
    // If activeFunding is true, senders can still put money in or open a dispute.
    // If activeFunding is false, receivers can start withdrawing from the contract what was assigned to them.
    bool public activeFunding = true;
    
    // If a dispute is open the senders can retrieve what they put in and the receivers are never allowed to receive their funds.
    // A dispute can only be open if endFundingTimestamp has not been reached.
    bool public hasDispute = false;

    constructor() {
        // TO DO: To move to constructor parameters
        endFundingTimestamp = block.timestamp + 5 minutes;

        // List of wallets that can add funds into the contract
        // TO DO: To move to constructor parameters
        senders[0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266] = true;
        senders[0x70997970C51812dc3A010C7d01b50e0d17dc79C8] = true;

        // List of wallets that can withdraw from the contract
        // The integer number represents the share of the funds
        // as an inverse of the percentage (e.g 1/0.5 = 2) to avoid
        // the usage of float numbers
        // TO DO: To move to constructor parameters
        receivers[0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC] = 2;
        receivers[0x90F79bf6EB2c4f870365E785982E1f101E93b906] = 2;
    }

    // TO DO: Make contract Ownable and set this as onlyOwner function. Left unprotected for testing purposes, remove before deploying to mainnet
    function setEndFundingTimeStamp(uint256 newEndFundingTimestamp) public {
        endFundingTimestamp = newEndFundingTimestamp;
        checkFundingIsActive();
    }

    // Provides the divider assigned for the mapped wallet
    function getWalletReceiverShareDivider(address wallet)
        public
        view
        returns (uint256)
    {
        return receivers[wallet];
    }

    // Checks if the current timestamp has reached the endFundingTimestamp
    // and updates it if activeFunding is true
    function checkFundingIsActive() public returns (bool) {
        if (activeFunding) {
            activeFunding = block.timestamp < endFundingTimestamp;
        }

        return activeFunding;
    }

    // To allow senders wallets to send ETH to the contract.
    // Only available if activeFunding is true.
    function depositEth() public payable {
        require(senders[msg.sender], "Not allowed to participate");
        require(
            checkFundingIsActive() == true,
            "Campaign ended, no more contributions allowed"
        );
        totalEthContributed += msg.value;
        contributions[msg.sender] += msg.value;
    }

    // Allows to withdraw funds to senders if a dispute is open.
    // Allows to withdraw funds to receivers if the campaign ended without a dispute.
    function withdrawEth() public {
        if (hasDispute) {
            require(
                senders[msg.sender],
                "Only senders can withdraw when a dispute is open"
            );
            require(contributions[msg.sender] > 0, "Not allowed to withdraw");
            payable(msg.sender).transfer(contributions[msg.sender]);
            contributions[msg.sender] = 0;
        } else {
            require(
            checkFundingIsActive() == false,
            "Campaign not ended, withdrawals not available"
        );
            require(receivers[msg.sender] > 0, "Not allowed to withdraw");
            payable(msg.sender).transfer(
                totalEthContributed / getWalletReceiverShareDivider(msg.sender)
            );
            receivers[msg.sender] = 0;
        }
    }

    // Senders can open a dispute freezing the campaign if endFundingTimestamp is not reached yet.
    // Once the dispute is open senders can withdraw the funds they added into the contract.
    function openDispute() public {
        require(senders[msg.sender], "Only senders can open a dispute");
        require(
            checkFundingIsActive() == true,
            "Disputes can only be open during the funding period"
        );
        hasDispute = true;
    }
}
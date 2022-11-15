/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title A Basic Faucet which disburses fixed ETH and cannot be spammed by one address for QuickNode Demo
/// @author Hrishikesh Thakkar
/// @notice This is a very basic faucet and isn't audited
contract SimpleContractFaucet {

    event ContractInstantiated(address indexed _owner, uint indexed _etherDeposited);
    event FaucetSendingSuccess(address indexed _receiver, uint indexed _faucetBalance);
    event FaucetSendingFailed(address indexed _receiver);
    event AddressCoolDownNeeded(address indexed _receiver, uint indexed _timestamp);

    //setting DRIP To be 10^-5 Eth
    uint constant DRIP = 0.00001 ether;
    uint constant COOLDOWN_TIME = 2 hours;

    //We're storing the last access time for each address ensuring one account doesn't drain all the funds
    mapping (address => uint) faucetAccessTimeTracker;
    constructor() payable {
        emit ContractInstantiated(msg.sender, msg.value);
    }

    function withdrawFromFaucet() public {
        //This will be 0 if it's the first time the user address accessed the faucet else the previous sue
        uint previousTimeStamp = faucetAccessTimeTracker[msg.sender];
        //previousTimeStamp and cool down time should be less than current time
        uint currentTimeStamp = block.timestamp;
        if (previousTimeStamp+COOLDOWN_TIME <= currentTimeStamp) {
            //Updating Timestamp First to Prevent Reentrancy Attack
            faucetAccessTimeTracker[msg.sender] = currentTimeStamp;
            (bool sent, ) = msg.sender.call{value: DRIP}("");
            if(!sent) {
                emit FaucetSendingFailed(msg.sender);
                revert();
            } else {
                emit FaucetSendingSuccess(msg.sender, address(this).balance);
            }
        } else {
            emit AddressCoolDownNeeded(msg.sender, previousTimeStamp + COOLDOWN_TIME);
        }
    }
}
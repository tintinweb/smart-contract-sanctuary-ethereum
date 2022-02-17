/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

contract Cassette {

    // The address used for the 'unlock early' penalty fees 
    // - Currently a test address provided by the JavaScript VM in the Remix IDE
    //address constant public penaltyPoolAddress = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
    // - Currently a test address on the Ropsten Test Network
    address constant public penaltyPoolAddress = 0x1DE620e63C842A06928B73B5b49DE2576f8E02Bd;

    // The penalty percentage 
    uint8 constant private penaltyPercentage = 10;

    // A helpful status message for debugging in test-nets - should be removed for production version
    string public myCassetteStatus = 'Cassette Test Contract v0.0.1';
    
    // The asset balance of the user's Cassette - default to zero
    uint public myCassetteBalance = 0;

    // The timestamp for when the user can withdraw their asset balance - default to zero
    uint256 public whenCanIWithdraw = 0;

    // Deposit the user's assets in their Cassette 
    function depositAssets(uint32 _seconds) public payable  {

        // Lock the user's assets for an amount of time in seconds
        lockUpAssets( _seconds );
    }
    
    // Withdraw the user's assets from their Cassette 
    function withdrawAssets() public {

        // Check to see if the user's Cassette has an asset balance greater than zero
        if( myCassetteBalance == 0 ){

            // Update the status message 
            myCassetteStatus = 'There are no Assets locked yet';

        // Check to see if the user is allowed to unlock their assets now
        } else if( canIUnlockNow()==true ){

            // Set the payable to addresses
            address payable to = payable(msg.sender);

            // Update the user's Cassette balance
            myCassetteBalance -= _unlockBalance();

            // Pay the amount to the user
            to.transfer(_unlockBalance());

            // Update the status message 
            myCassetteStatus = 'Assets were successfully unlocked';
            whenCanIWithdraw = 0;

        } else {

            // Update the status message 
            myCassetteStatus = 'Assets can not be unlocked yet';
        }
    }
    
    // Unlock the user's Cassette earlier than the original lock-time
    function unlockCassetteEarly() public {

        // Check there is an asset balance value to work with first
        if( myCassetteBalance == 0 ){

            // Update the status message 
            myCassetteStatus = 'There are no Assets locked yet';
        } else {
            
            // Before penalty deduction
            uint totalBalance = _unlockBalance();

            // Set the penalty amount
            uint penaltyAmount = (totalBalance/100) * penaltyPercentage;

            // Amount payable after penalty deduction
            uint amountPayable = totalBalance - penaltyAmount;

            // Set the payable to addresses
            address payable toUser = payable(msg.sender);
            address payable toPenaltyPool = payable(penaltyPoolAddress);

            // Update the user's Cassette balance
            myCassetteBalance -= _unlockBalance();

            // Pay the reduced amount to the user
            toUser.transfer(amountPayable);

            // Pay the percentage fee to the penalty pool
            toPenaltyPool.transfer(penaltyAmount);
            
            // Update the status message 
            myCassetteStatus = 'Assets were successfully unlocked early';
            whenCanIWithdraw = 0;
        } 
    }

    // Check to see if the user can unlock their Cassette now
    function canIUnlockNow() public view returns(bool){
        bool canBeUnlocked;

        // Check there is an unlock-time to work with first
        if(whenCanIWithdraw==0){
            canBeUnlocked = false;

        // Check to see if the time-lock timestamp is earlier than the current timestamp 
        } else if( whenCanIWithdraw <= block.timestamp ){
            canBeUnlocked = true;
        } else {
            canBeUnlocked = false;
        }

        return canBeUnlocked;
    }

    // Lock up assets for an amount of time in seconds 
    function lockUpAssets(uint32 _seconds) private {
        
        // Check there is a time value to work with first
        if(msg.value==0){

            // Update the status message 
            myCassetteStatus = 'Can only lock an amount greater than zero';
        } else {

            // Update the user's cassette balance 
            myCassetteBalance += msg.value;

            // The timestamp for requested unlock-time of this transaction  
            uint256 timestampLockEnd = block.timestamp + _seconds;

            // If there is already a lock in place, the user can increase the existing unlock-time but not shorten it
            if(timestampLockEnd>whenCanIWithdraw ){
                whenCanIWithdraw = timestampLockEnd;
            }

            // Update the status message 
            myCassetteStatus = 'Assets were successfully locked';
        }
    }

    // Get the Cassette balance
    function _unlockBalance() private view returns(uint) {

        // The actual asset balance held in the user's Cassette 
        return address(this).balance;
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

contract Cassette {

    // ToDo: Create a CassetteFactory.sol Contract that deploys Cassette contracts 
    // with a sender address and the initial deposit

    // Readable version
    string constant public cassetteVersion = '0.0.1';
    
    // The address used for the 'unlock early' penalty fees 

    // - A test address provided by the JavaScript VM in the Remix IDE: 
    //address constant public penaltyPoolAddress = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;

    // - A test address on the Ropsten Test Network: 
    address constant private penaltyPoolAddress = 0x1DE620e63C842A06928B73B5b49DE2576f8E02Bd;

    // The address of the user that signed the original contract 
    address public cassetteOwnerAddress;

    // The penalty percentage 
    uint256 constant private penaltyPercentage = 10;

    // Note if the deposit is the first one
    bool private isFirstDeposit = false;

    // A helpful status message for debugging in test-nets - should be removed for production version
    //string public cassetteStatus = 'Cassette Test Contract v0.0.1';
    /*
        Code Key:
        0 = Cassette Test Contract v0.0.1
        1 = Recent sender was not the Cassette owner
        2 = There are no Assets locked yet
        3 = Can only lock an amount greater than zero
        4 = Assets can not be unlocked yet
        5 = Assets were successfully locked
        6 = Assets were successfully unlocked early
        7 = Assets were successfully unlocked

    */
    uint8 public cassetteStatusCode = 0;
    
    // The asset balance of the user's Cassette - default to zero
    uint256 private cassetteBalance = 0;

    // The timestamp for when the user can withdraw their asset balance - default to zero
    uint256 public whenCanWithdraw = 0;

    // Deposit the user's assets in their Cassette 
    function depositAssets(uint256 _seconds) public payable  {

        // Lock the user's assets for an amount of time in seconds
        lockUpAssets( _seconds );
    }
    
    // This is the constructor that is called by the CassetteFactory
    constructor(address senderAddress, uint256 assetValue, uint256 timeLockSeconds) payable {
        isFirstDeposit = true;
        cassetteBalance = assetValue;
        cassetteOwnerAddress = senderAddress;
        depositAssets(timeLockSeconds);
    }
    
    // Withdraw the user's assets from their Cassette 
    function withdrawAssets() public {

        // Check the user is the owner
        if(userIsOwner()==false){
            // Bail
            return;
        }

        // Check to see if the user's Cassette has an asset balance greater than zero
        if( cassetteBalance == 0 ){

            // Update the status message 
            //cassetteStatus = 'There are no Assets locked yet';
            cassetteStatusCode = 2;

        // Check to see if the user is allowed to unlock their assets now
        } else if( canUnlockNow()==true ){

            // Set the payable to addresses
            address payable to = payable(cassetteOwnerAddress);

            // Set amount
            uint256 amount = cassetteAssetBalance();

            // Update the user's Cassette balance
            cassetteBalance -= amount;

            // Pay the amount to the user
            to.transfer(amount);

            // Update the status message 
            //cassetteStatus = 'Assets were successfully unlocked';
            cassetteStatusCode = 7;
            whenCanWithdraw = 0;

        } else {

            // Update the status message 
            //cassetteStatus = 'Assets can not be unlocked yet';
            cassetteStatusCode = 4;
        }
    }
    
    // Unlock the user's Cassette earlier than the original lock-time
    function unlockCassetteEarly() public {

        // Check the user is the owner
        if(userIsOwner()==false){
            // Bail
            return;
        }

        // Check there is an asset balance value to work with first
        if( cassetteBalance == 0 ){

            // Update the status message 
            //cassetteStatus = 'There are no Assets locked yet';
            cassetteStatusCode = 2;
        } else {
            
            // Check to see if the user can unlock without a penalty
            if( canUnlockNow()==true ){
                
                // The user's Cassette is unlocked already so they can withdraw without any penalty
                withdrawAssets();
            } else {

                // Before penalty deduction
                uint256 totalBalance = cassetteAssetBalance();

                // Set the penalty amount
                uint256 penaltyAmount = totalBalance/penaltyPercentage;

                // Amount payable after penalty deduction
                uint256 amountPayable = totalBalance - penaltyAmount;

                // Set the payable to addresses
                address payable toUser = payable(cassetteOwnerAddress);
                address payable toPenaltyPool = payable(penaltyPoolAddress);

                // Update the user's Cassette balance
                cassetteBalance -= totalBalance;

                // Pay the reduced amount to the user
                toUser.transfer(amountPayable);

                // Pay the percentage fee to the penalty pool
                toPenaltyPool.transfer(penaltyAmount);
                
                // Update the status message 
                //cassetteStatus = 'Assets were successfully unlocked early';
                cassetteStatusCode = 6;
                whenCanWithdraw = 0;
            }
        } 
    }

    // Check to see if the user can unlock their Cassette now
    function canUnlockNow() public view returns(bool){
        // Check there is an unlock-time to work with first
        if(whenCanWithdraw==0){
            return false;
        // Check to see if the time-lock timestamp is earlier than the current timestamp 
        } else if( whenCanWithdraw <= block.timestamp ){
            return true;
        } else {
            return false;
        }
    }

    // Lock up assets for an amount of time in seconds 
    function lockUpAssets(uint256 _seconds) private {
        
        // Check there is an Asset value to work with first
        if(isFirstDeposit!=true && msg.value==0){
            // Update the status message 
            //cassetteStatus = 'Can only lock an amount greater than zero';
            cassetteStatusCode = 3;
        } else {

            // Check the user is the owner
            if(userIsOwner()==false){
                // Bail
                return;
            }

            // Update the user's cassette balance 
            if(isFirstDeposit==false){
                cassetteBalance += msg.value;
            }
            
            // The timestamp for requested unlock-time of this transaction  
            uint256 timestampLockEnd = block.timestamp + _seconds;

            // If there is already a lock in place, the user can increase the existing unlock-time but not shorten it
            if(timestampLockEnd>whenCanWithdraw ){
                whenCanWithdraw = timestampLockEnd;
            }

            // Update the status message 
            //cassetteStatus = 'Assets were successfully locked';
            cassetteStatusCode = 5;
            isFirstDeposit = false;
        }
    }

    // Get the Cassette balance
    function cassetteAssetBalance() public view returns(uint256) {
        // The actual asset balance held in the user's Cassette 
        return address(this).balance;
    }

    // Check that the sender's address matches the Cassette owner's address
    function userIsOwner() private returns (bool){
        if(isFirstDeposit==false && msg.sender != cassetteOwnerAddress){
            // Update the status message 
            //cassetteStatus = 'Recent sender was not the Cassette owner';
            cassetteStatusCode = 1;
            return false;
        } else {
            return true;
        }
    }
}
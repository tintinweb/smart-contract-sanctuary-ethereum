/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// SPDX-License-Identifier: CC-BY-SA 4.0
//https://creativecommons.org/licenses/by-sa/4.0/

// This contract must be deployed with credits toward the original creators, @LogETH @jellyfantom .
// You must indicate if changes were made in a reasonable manner, but not in any way that suggests we endorse you or your use.
// If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.
// You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.
// This TL;DR is solely an explaination and is not a representation of the license.

// By deploying this contract, you agree to the license above and the terms and conditions that come with it.

pragma solidity >=0.7.0 <0.9.0;

contract TokenStaking{

//// This contract locks tokens for a period of time and then releases them with an additional reward.
//// THIS CONTRACT MUST BE IMMUNE TO/EXCLUDED FROM ANY FEE ON TRANSFER MECHANISMS. (Or else things will break)
//stake noko token
    // How to Setup:

    // Step 1: Deploy the contract
    // Step 2: Call EditToken() with the token address you want to use (Make sure you check as this cannot be changed once set)
    // Step 3: Call EditEmission() with how many tokens should be given per 1 LP token for the entire locking period.
    // Step 4: Send some tokens to this contract like how you would send anyone a token and boom, it works.

    // now to the code:

    // the constructor that activates when you deploy the contract, as you can see, it makes you the admin.
    string public symbol;

    constructor(string memory sym){
        symbol = sym;
        admin = msg.sender;
    }


//////////////////////////                                                          /////////////////////////
/////////////////////////                                                          //////////////////////////
////////////////////////            Variables that this contract has:             ///////////////////////////
///////////////////////                                                          ////////////////////////////
//////////////////////                                                          /////////////////////////////


//// The ERC20 Token and the reward token:

    ERC20 Token;
    ERC20 RewardToken;

//// All the Variables that this contract uses

    mapping(address => uint) LockTimestamp;
    mapping(address => bool) public Staked;
    mapping(address => uint) public StakedTokens;
    uint public totalStaked;
    uint public VaultReward;
    uint public LockingPeriod;
    uint public Limit;
    address admin;

//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////             Visible functions this contract has:             ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////


    // Functions that let the Admin of this contract change settings.

    function EditRewardToken(ERC20 WhatToken) public {

        require(msg.sender == admin, "You aren't the admin so you can't press this button");
        RewardToken = WhatToken;
    }

    function SetDepositToken(ERC20 WhatToken) public {

        require(msg.sender == admin, "You aren't the admin so you can't press this button");
        Token = WhatToken;
    }

    function EditLockingPeriod(uint HowManyBlocks) public {

        require(msg.sender == admin, "You aren't the admin so you can't press this button");
        LockingPeriod = HowManyBlocks; // Changes the token (DOES NOT RESET REWARDS)
    }

    // Enter in how many reward tokens should be given to 1 LP token per lock.

    function EditLockReward(uint HowManyTokens) public {

        require(msg.sender == admin, "You aren't the admin so you can't press this button");

        VaultReward = HowManyTokens; // Switches to the new reward percentage
    }

    function SweepToken(ERC20 TokenAddress) public {

        require(msg.sender == admin, "You aren't the admin so you can't press this button");
        require(TokenAddress != Token || TokenAddress != RewardToken, "You cannot sweep a token that is being used by the contract");
        TokenAddress.transfer(msg.sender, TokenAddress.balanceOf(address(this))); 
    }

    // The deposit button deposits your tokens into the vault.
    // WARNING: Depositing more resets the timer!!!

    function deposit(uint amount) public {

        Token.transferFrom(msg.sender, address(this), amount);

        Staked[msg.sender] = true;
        StakedTokens[msg.sender] += amount;
        LockTimestamp[msg.sender] = block.timestamp;
    }

    // The Claim Button opens the vault and gives out the rewards and your staked balance if you call claimAndWithdraw()

    function claim() public {

        require(Staked[msg.sender] = true, "You have not deposited anything yet");
        require(CalculateTime(msg.sender) > LockingPeriod, "Your Locking time has not finished yet.");

        RewardToken.transfer(msg.sender, CalculateReward(msg.sender));
        
        LockTimestamp[msg.sender] = block.timestamp;
    }

    function claimAndWithdraw() public {

        require(Staked[msg.sender] = true, "You have not deposited anything yet");
        require(CalculateTime(msg.sender) > LockingPeriod, "Your Locking time has not finished yet.");

        RewardToken.transfer(msg.sender, CalculateReward(msg.sender));
        Token.transfer(msg.sender, StakedTokens[msg.sender]);

        Staked[msg.sender] = false;
        StakedTokens[msg.sender] = 0;

    }

//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////      Internal and external functions this contract has:      ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////


    // (msg.sender SHOULD NOT be used/assumed in any of these functions.)
    // CalculateTime returns a uint with 18 decimals.
  
    function CalculateTime(address YourAddress) internal view returns (uint256){

        uint Time = (block.timestamp - LockTimestamp[YourAddress]);
        if(LockTimestamp[YourAddress] == block.timestamp){Time = 0;}

        return Time;
    }

    function CalculateReward(address Who) public view returns (uint){

        return (StakedTokens[Who]*VaultReward)/(10**RewardToken.decimals());
    }

    function depositRewardToken(uint amount) public {
        require(msg.sender == admin, "You aren't the admin so you can't press this button");
        RewardToken.transferFrom(msg.sender, address(this), amount);
    }

    
//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////                 Functions used for UI data                   ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////


    
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// Additional functions that are not part of the core functionality, if you add anything, please add it here ////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*
    function something() public {

        blah blah blah blah;
    }
*/



}
    
//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////      Contracts that this contract uses, contractception!     ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////

interface NFT{
    function transferFrom(address, address, uint256) external;
    function balanceOf(address) external returns (uint);
}

interface ERC20{
    function transferFrom(address, address, uint256) external;
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns(uint);
    function decimals() external view returns (uint8);
}
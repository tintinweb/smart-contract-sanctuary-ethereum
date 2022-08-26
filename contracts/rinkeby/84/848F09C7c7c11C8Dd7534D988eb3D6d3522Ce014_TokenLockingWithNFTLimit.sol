// SPDX-License-Identifier: CC-BY-SA 4.0
//https://creativecommons.org/licenses/by-sa/4.0/

// TL;DR: The creator of this contract (@LogETH) is not liable for any damages associated with using the following code
// This contract must be deployed with credits toward the original creator, @LogETH.
// You must indicate if changes were made in a reasonable manner, but not in any way that suggests I endorse you or your use.
// If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.
// You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.
// This TL;DR is solely an explaination and is not a representation of the license.

// By deploying this contract, you agree to the license above and the terms and conditions that come with it.

pragma solidity >=0.7.0 <0.9.0;

contract TokenLockingWithNFTLimit{

//// This contract simply enables a staking system with a locking feature.
//// THIS CONTRACT MUST BE IMMUNE TO/EXCLUDED FROM ANY FEE ON TRANSFER MECHANISMS.

    // How to Setup:

    // Step 1: Deploy the contract
    // Step 2: Call EditToken() and EditNonFun() with the token and NFT address you want to use
    // Step 3: Call EditEmission() with how much % gain should be given out daily in basis points + an extra decimal (Look up what basis points are please).
    // Step 4: Call EditWithdrawTime() and EditMinimumStakeTime() to the values you want, make sure to input these values as seconds!
    // Step 4: Send some tokens to this contract for rewards like how you would send anyone a token and boom, it works.


//// Commissioned by spagetti#7777 on 8/22/2022

    // now to the code:

    // Settings that you can change before deploying (in this case, don't change anything)
    // As you can see, it makes you the admin. The admin CANNOT be changed once set for security reasons.

    constructor(){

        admin = msg.sender;
    }


//////////////////////////                                                          /////////////////////////
/////////////////////////                                                          //////////////////////////
////////////////////////            Variables that this contract has:             ///////////////////////////
///////////////////////                                                          ////////////////////////////
//////////////////////                                                          /////////////////////////////


//// The ERC20 Token:

    ERC20 Token;
    ERC721 Nonfun;

//// All the Variables that this contract uses (basically the dictionary for this contract)

    mapping(address => uint) public TimeStaked;         // How much time someone has staked for.
    mapping(address => uint) public TokensStaked;       // How many tokens someone has staked.
    mapping(address => uint) public TimeFactor;         // Keeps track of cooldowns for certain functions like Unstake().
    mapping(address => uint) public TimeClaim;         // Keeps track of cooldowns for certain functions like Claim().
    mapping(uint => address) public user;
    mapping(address => uint) public PendingReward;
    address public admin;
    uint totalStaked;                            // How many tokens are staked in total.
    uint public RewardFactor;                           // How many rewards in basis points are given per day
    uint Nonce;
    uint public MinimumTime;                            // The minimum amount of time until someone can claim rewards.
    uint public WithdrawTime;                           // The amount of time someone has to wait between requesting a withdraw, and actually withdrawing.
    
    modifier OnlyERC721{
        
        require(Nonfun.balanceOf(msg.sender) > 0, "You do not have the required ERC721 to use this function");
        _;
    }
    

//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////             Visible functions this contract has:             ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////


    // Functions that let the Admin of this contract change settings.

    function EditToken(ERC20 WhatToken) public {

        require(msg.sender == admin, "You aren't the admin so you can't press this button");
        Token = WhatToken; // Changes the token (DOES NOT RESET REWARDS)
    }

    function EditNonFun(ERC721 WhatERC721) public{

        require(msg.sender == admin, "You aren't the admin so you can't press this button");
        Nonfun = WhatERC721; // Changes the ERC721 (DOES NOT RESET REWARDS)
    }

    // If you don't know what basis points are go look it up, remember to add a single decimal though!

    function EditEmission(uint BPSperDay) public {

        require(msg.sender == admin, "You aren't the admin so you can't press this button");

        SaveRewards(); //Saves everyone's rewards
        RewardFactor = BPSperDay; // Switches to the new reward percentage
    }

    // Everyone asks what this does, it just sends stuck tokens to your address

    function SweepToken(ERC20 TokenAddress) public {

        require(msg.sender == admin, "You aren't the admin so you can't press this button");
        require(TokenAddress != Token, "This token is currently being used as rewards! You cannot sweep it while its being used!");
        TokenAddress.transfer(msg.sender, TokenAddress.balanceOf(address(this))); 
    }

    // When Editing these values, make sure you input the time in seconds

    function EditWithdrawTime(uint HowManyBlocks) public {

        require(msg.sender == admin, "You aren't the admin so you can't press this button");
        WithdrawTime = HowManyBlocks;
    }

    function EditMinimumStakeTime(uint HowManyBlocks) public {

        require(msg.sender == admin, "You aren't the admin so you can't press this button");
        MinimumTime = HowManyBlocks;
    }

    // The Stake button stakes your tokens.
    // SECURITY WARNING, This address MUST be immune to the token fee or else things will break. (lol)

    function Stake(uint amount) public OnlyERC721{

        require(Token.balanceOf(msg.sender) > 0, "You don't have any tokens to stake!");
        require(msg.sender != address(0), "What the fuck"); // This error will never happen but I just have it here as an edge case easter egg for you lurking programmers..

        if(TokensStaked[msg.sender] == 0){RecordRewardALT(msg.sender);}
        else{RecordReward(msg.sender);}
 
        Token.transferFrom(msg.sender, address(this), amount); // Deposits "Token" into this contract
        TokensStaked[msg.sender] += amount; // Keeps track of how many tokens you deposited

        user[Nonce] = msg.sender; // Records your address to use in SaveRewards()

        totalStaked += amount; // Add the coins you deposited to the total staked amount
        TimeFactor[msg.sender] = block.timestamp;


        Nonce += 1;
    }

    function claimRewards() public OnlyERC721{

        require(block.timestamp - TimeClaim[msg.sender] > MinimumTime, "You cannot claim rewards as the claiming cooldown is active");
        require(TokensStaked[msg.sender] > 0, "There is nothing to claim as you haven't staked anything");

        RecordRewardALT(msg.sender);
        Token.transfer(msg.sender, PendingReward[msg.sender]);
    }

    // The Unstake Button withdraws your tokens. It does not auto claim rewards.

    function Unstake(uint amount) public OnlyERC721{

        require(block.timestamp - TimeFactor[msg.sender] > WithdrawTime, "You cannot withdraw as the withdraw cooldown is active");
        require(TokensStaked[msg.sender] > 0, "There is nothing to withdraw as you haven't staked anything");

        require(TokensStaked[msg.sender] >= amount, "You cannot withdraw more tokens than you have staked");

        RecordReward(msg.sender);

        Token.transfer(msg.sender, amount); // Unstakes "Amount" and sends it to the caller
        TokensStaked[msg.sender] -= amount; // Reduces your staked balance by the amount of tokens you unstaked
        totalStaked -= amount; // Reduces the total staked amount by the amount of tokens you unstaked


    }

//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////      Internal and external functions this contract has:      ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////

    // (msg.sender SHOULD NOT be used/assumed in any of these functions.)

    // CalculateTime returns a uint with 18 decimals.
  
    function CalculateTime(address YourAddress) internal view returns (uint256){

        uint Time = (block.timestamp - TimeStaked[YourAddress]);
        if(TimeStaked[YourAddress] == block.timestamp){Time = 0;}

        return Time;
    }

    function CalculateRewards(address YourAddress, uint256 StakeTime) internal view returns (uint256){

        return (StakeTime * RewardFactor * (TokensStaked[YourAddress]/100000))/86400;
    }

    // RecordReward does not reset the claim cooldown, RecordRewardALT does.

    function RecordReward(address User) internal {

        uint Unclaimed = CalculateRewards(User, CalculateTime(User));
        PendingReward[User] += Unclaimed;
        TimeStaked[User] = block.timestamp; // Calling record reward makes it so you don't need this line in the parent code.
    }

    function RecordRewardALT(address User) internal {

        uint Unclaimed = CalculateRewards(User, CalculateTime(User));
        PendingReward[User] += Unclaimed;
        TimeStaked[User] = block.timestamp;
        TimeClaim[User] = block.timestamp;
    }

    // SaveRewards() saves the state of everyone's rewards, only triggers when changing the reward %

    function SaveRewards() internal {

        uint UserNonce = 1;

        while(user[UserNonce] != address(0)){

            RecordReward(user[UserNonce]);
            UserNonce += 1;
        }
    }

//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////                 Functions used for UI data                   ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////

    function CalculateDailyReward(address YourAddress) public view returns(uint){

        return RewardFactor * (TokensStaked[YourAddress]/100000);
    }

    function CheckRewards(address YourAddress) public view returns (uint256){

        return(CalculateRewards(YourAddress, CalculateTime(YourAddress))) + PendingReward[YourAddress];
    }


    function isContract(address addr) internal view returns (bool) {

        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }       

    function displayTotalStaked() public view returns(uint){
    
        return totalStaked;
    }

    
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

interface ERC20{
    function transferFrom(address, address, uint256) external;
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns(uint);
    function decimals() external view returns (uint8);
}

interface ERC721{
    function transferFrom(address, address, uint256) external;
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns(uint);
    function decimals() external view returns (uint8);
}
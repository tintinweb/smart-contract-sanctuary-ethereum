/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

// SPDX-License-Identifier: CC-BY-SA 4.0
//https://creativecommons.org/licenses/by-sa/4.0/

// TL;DR: The creators of this contract (@LogETH) & (@jellyfantom) are not liable for any damages associated with using the following code
// This contract must be deployed with credits toward the original creators, @LogETH @jellyfantom .
// You must indicate if changes were made in a reasonable manner, but not in any way that suggests we endorse you or your use.
// If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.
// You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.
// This TL;DR is solely an explaination and is not a representation of the license.


// By deploying this contract, you agree to the licence above and the terms and conditions that come with it.

pragma solidity >=0.7.0 <0.9.0;

contract NFTRegisterRewardDistribution{

//// This contract simply distributes an ERC20 token among NFT owners.

//// Users register their NFT by using register() to receive rewards.
//// In order for this contract to function properly, transfer(), transferfrom(), safetransfer(), and safetransferfrom() MUST BE DISABLED on the main NFT contract.



    // now to the code:

    // Settings that you can change before deploying

    constructor(){

        NOKO = ERC20(address(0));
        OnePercent = NFT(address(0));
        admin = msg.sender;
    }


//////////////////////////                                                          /////////////////////////
/////////////////////////                                                          //////////////////////////
////////////////////////            Variables that this contract has:             ///////////////////////////
///////////////////////                                                          ////////////////////////////
//////////////////////                                                          /////////////////////////////


//// The NFT and the ERC20 Token:

    NFT OnePercent;
    ERC20 NOKO;

//// All the Variables that this contract uses

    mapping(address => uint) TimeRegistered;
    mapping(address => uint) NFTs;
    mapping(address => uint) PendingReward;
    mapping(uint => address) user;
    mapping(address => bool) perm;
    address admin;
    uint public TotalRewardsClaimed;
    uint public totalRegistered;
    uint RewardFactor;
    uint Nonce;
    

//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////             Visible functions this contract has:             ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////


    // Functions that let the Admin of this contract change settings.

    function SetNFT(NFT WhatNFT) public {
    
        require(msg.sender == admin, "You aren't the admin so you can't press this button");
        require(OnePercent == NFT(address(0)), "You have already set the NFT");
        OnePercent = WhatNFT;
    }

    function EditToken(ERC20 Token) public {

        require(msg.sender == admin, "You aren't the admin so you can't press this button");
        NOKO = Token;
    }

    function EditEmission(uint TokensPerNFT, uint HowManyBlocks) public {

        require(msg.sender == admin, "You aren't the admin so you can't press this button");

        SaveRewards();
        RewardFactor = CalculateEmission(TokensPerNFT, HowManyBlocks, NOKO.decimals());
    }

    function SweepToken(ERC20 TokenAddress) public {

        require(msg.sender == admin, "You aren't the admin so you can't press this button");
        require(TokenAddress != NOKO, "This token is currently being used as rewards! You cannot sweep it while its being used!");
        TokenAddress.transfer(msg.sender, TokenAddress.balanceOf(address(this)));
    }

    // ForceClaim allows you to claim everyones rewards instantly.
    // The claimed tokens still go to their rightful owner.

    function forceClaim() public {

        require(msg.sender == admin || perm[msg.sender] == true, "You aren't the admin so you can't press this button");

        ForceClaim();
    }

    // This button is what a user would use to normally claim rewards to their address.

    function Claim() public {

        uint Unclaimed = CalculateRewards(msg.sender, CalculateTime(msg.sender)) + PendingReward[msg.sender];

        require(NOKO.balanceOf(address(this)) >= Unclaimed, "This contract is out of tokens to give as rewards! Ask devs to do something");
        require(PendingReward[msg.sender] > 0 || Unclaimed > 0, "You have no rewards to collect");
        TimeRegistered[msg.sender] = block.timestamp;
        NOKO.transfer(msg.sender, Unclaimed);
        PendingReward[msg.sender] = 0;

        TotalRewardsClaimed += Unclaimed;
    }

    // The Register button reads the underlying NFT contract for a person's balance and keeps track of it.

    function Register() public {

        require(OnePercent.balanceOf(msg.sender) > 0, "You don't have any NFTs to register!");
        require(OnePercent.balanceOf(msg.sender) != NFTs[msg.sender], "You already registered all your NFTs.");
        require(NFTs[msg.sender] < 100, "You have registered the max amount, 100 NFTs");
        require(msg.sender != address(0), "What the fuck");

        ClaimOnBehalf(msg.sender);

        NFTs[msg.sender] = OnePercent.balanceOf(msg.sender);

        if(OnePercent.balanceOf(msg.sender) > 100){NFTs[msg.sender] = 100;}

        TimeRegistered[msg.sender] = block.timestamp;

        user[Nonce] = msg.sender;
        Nonce += 1;
    }

    // Assign perms lets you give an external address permission to call admin only functions like forceClaim()

    function AssignPermission(address Who, bool TrueOrFalse) public {
        
        require(msg.sender == admin, "You aren't the admin so you can't press this button");
        perm[Who] = TrueOrFalse;
    }


//////////////////////////                                                              /////////////////////////
/////////////////////////                                                              //////////////////////////
////////////////////////      Internal and external functions this contract has:      ///////////////////////////
///////////////////////                                                              ////////////////////////////
//////////////////////                                                              /////////////////////////////


    // (msg.sender SHOULD NOT be used/assumed in any of these functions.)
  
    function CalculateTime(address YourAddress) internal view returns (uint256){

        uint Time = block.timestamp - TimeRegistered[YourAddress];
        if(Time == block.timestamp){Time = 0;}

        return Time;
    }

    function CalculateRewards(address YourAddress, uint256 StakeTime) internal view returns (uint256){

        return StakeTime * NFTs[YourAddress] * RewardFactor;
    }

    function ClaimOnBehalf(address User) internal {

        uint Unclaimed = CalculateRewards(User, CalculateTime(User)) + PendingReward[User];

        require(NOKO.balanceOf(address(this)) >= Unclaimed, "This contract is out of tokens to give as rewards! Ask devs to do something");
        TimeRegistered[User] = block.timestamp;
        NOKO.transfer(User, Unclaimed);
        PendingReward[User] = 0;

        TotalRewardsClaimed += Unclaimed;
    }

    function RecordReward(address User) internal {

        uint Unclaimed = CalculateRewards(User, CalculateTime(User));
        PendingReward[User] += Unclaimed;
        TimeRegistered[User] = block.timestamp;
    }

    function SaveRewards() internal {

        uint UserNonce;

        while(user[UserNonce] != address(0)){

            RecordReward(user[UserNonce]);
            UserNonce += 1;
        }
    }

    function ForceClaim() internal {

        uint UserNonce;

        while(user[UserNonce] != address(0)){

            ClaimOnBehalf(user[UserNonce]);
            UserNonce += 1;
        }
    }

    function CalculateEmission(uint TokensPerBlockPerNFT, uint HowManyBlocks, uint decimals) public pure returns(uint) {

        uint Value = TokensPerBlockPerNFT * (10**decimals);
        TokensPerBlockPerNFT = Value/HowManyBlocks;
        return TokensPerBlockPerNFT;
    }

    ///////////////////////////////////////////////////////////
    //// The internal/external functions used for UI data  ////
    ///////////////////////////////////////////////////////////

    function CheckUnclaimedRewards(address YourAddress) external view returns (uint256){

        return (CalculateRewards(YourAddress, CalculateTime(YourAddress)) + PendingReward[YourAddress]);
    }

    function GetMultiplier(address YourAddress) external view returns (uint){

        return NFTs[YourAddress];
    }

    function GetTotalRegistered() external view returns (uint){

        return totalRegistered;
    }
    
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//// Additional functions that are not part of the core functionality, if you add anything, please add it here ////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////



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
/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

// File: Miner.sol



//https://creativecommons.org/licenses/by-sa/4.0/



// TL;DR: The creator of this contract (@LogETH) is not liable for any damages associated with using the following code

// This contract must be deployed with credits toward the original creator, @LogETH.

// You must indicate if changes were made in a reasonable manner, but not in any way that suggests I endorse you or your use.

// If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.

// You may not apply legal terms or technological measures that legally restrict others from doing anything the license permits.

// This TL;DR is solely an explaination and is not a representation of the license.



// By deploying this contract, you agree to the license above and the terms and conditions that come with it.



pragma solidity >=0.7.0 <0.9.0;



contract TokenStaking{



//// This contract simply enables a compounding percentage based staking mechanism for an ERC20 token, like OHM, but it can be plugged into any ERC20 token.

//// THIS CONTRACT MUST BE IMMUNE TO/EXCLUDED FROM ANY FEE ON TRANSFER MECHANISMS.



    // How to Setup:



    // Step 1: Deploy the contract

    // Step 2: Call EditToken() with the token address you want to use

    // Step 3: Call EditEmission() with how much % gain should be given out daily.

    // Step 4: Send some tokens to this contract like how you would send anyone a token and boom, it works.



//// Commissioned by spagetti#7777 on 4/29/2022



    // now to the code:



    // Settings that you can change before deploying



    constructor(){



        admin = msg.sender;

        start = block.timestamp;



        // The below sets up the index calculation, don't change this.



        TokensStaked[address(this)] += 1*(10**18);

        user[1] = address(this);

        Nonce = 2;

    }





//////////////////////////                                                          /////////////////////////

/////////////////////////                                                          //////////////////////////

////////////////////////            Variables that this contract has:             ///////////////////////////

///////////////////////                                                          ////////////////////////////

//////////////////////                                                          /////////////////////////////





//// The ERC20 Token:



    ERC20 Token;



//// All the Variables that this contract uses



    mapping(address => uint) TimeStaked;

    mapping(address => uint) TokensStaked;

    mapping(address => uint) InitalStake;

    mapping(uint => address) public user;

    mapping(address => bool) perm;

    address admin;

    uint public totalStaked;

    uint public RewardFactor;

    uint Nonce;

    uint start;

    uint public Limit;

    



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



    function EditStakingLimit(uint limit) public {



        require(msg.sender == admin, "You aren't the admin so you can't press this button");

        require(limit > Limit, "You cannot set the limit to a number lower than the current limit");



        Limit = limit;

    }



    // If you don't know what basis points are go look it up



    function EditEmission(uint BPSperDay) public {



        require(msg.sender == admin, "You aren't the admin so you can't press this button");



        SaveRewards(); //Saves everyone's rewards

        RewardFactor = BPSperDay; // Switches to the new reward percentage

    }



    function SweepToken(ERC20 TokenAddress) public {



        require(msg.sender == admin, "You aren't the admin so you can't press this button");

        require(TokenAddress != Token, "This token is currently being used as rewards! You cannot sweep it while its being used!");

        TokenAddress.transfer(msg.sender, TokenAddress.balanceOf(address(this))); 

    }



    // The Stake button stakes your tokens.

    // SECURITY WARNING, This address MUST be immune to the token fee or else things will break. (lol)



    function Stake(uint amount) public {



        require(Limit != 0, "The global limit is set to zero, nobody can stake anything if its set to zero");

        require(totalStaked <= Limit*(10**Token.decimals()), "The global maximum number of tokens has been staked!");



        require(Token.balanceOf(msg.sender) > 0, "You don't have any tokens to stake!");

        require(msg.sender != address(0), "What the fuck");



        RecordReward(msg.sender); // Saves and compounds the msg.sender's rewards

        Token.transferFrom(msg.sender, address(this), amount); // Deposits "Token" into this contract

        TokensStaked[msg.sender] += amount; // Keeps track of how many tokens you deposited

        InitalStake[msg.sender] += amount;



        user[Nonce] = msg.sender; // Records your address to use in SaveRewards()



        totalStaked += amount; // Add the coins you deposited to the total staked amount



        require(totalStaked <= Limit*(10**Token.decimals()), "This deposit would cause the global staking limit to be hit, try depositing a lower amount");

        Nonce += 1;

    }



    // The Unstake Button withdraws your tokens and any rewards you have accurred. (Unless you put in an amount)



    function Unstake(uint amount) public {



        require(TokensStaked[msg.sender] > 0, "You have no tokens to withdraw");

        require(msg.sender != address(0), "What the fuck");



        RecordReward(msg.sender); // Saves and compounds the msg.sender's rewards



        require(amount <= Token.balanceOf(address(this)), "This contract is out of tokens to give as rewards! Ask devs to do something!");

        require(amount <= TokensStaked[msg.sender], "You can't withdraw more tokens than you have deposited.");

        Token.transfer(msg.sender, amount); // Sends the "amount" you requested to your address



        uint amt = TokensStaked[msg.sender] - InitalStake[msg.sender]; // How many tokens you have earned.



        if(amount >= amt){



            Limit += amt;

            InitalStake[msg.sender] -= amount - amt;

            totalStaked -= amount - amt;

        }

        else {



            Limit += amount;

        }



        TokensStaked[msg.sender] -= amount; // Reduces your recorded balance by the amount of tokens you withdrawed

    }



    function UnstakeMax() public {



        require(TokensStaked[msg.sender] > 0, "You have no tokens to withdraw");

        require(msg.sender != address(0), "What the fuck");



        RecordReward(msg.sender); // Saves and compounds the msg.sender's rewards



        require(TokensStaked[msg.sender] <= Token.balanceOf(address(this)), "This contract is out of tokens to give as rewards! Ask devs to do something!");

        Token.transfer(msg.sender, TokensStaked[msg.sender]); // Sends all staked tokens to your address



        uint amt = TokensStaked[msg.sender] - InitalStake[msg.sender]; // How many tokens you have earned.

        Limit += amt;



        totalStaked -= InitalStake[msg.sender]; // Reduces the coins you withdrawed to the total staked amount.



        InitalStake[msg.sender] = 0;

        TokensStaked[msg.sender] = 0; // Reduces your recorded balance by the amount of tokens you withdrawed

    }



    // The compound button compounds EVERYONEs rewards, it can be called by anyone, but it has to be called manually.

    // It should be called daily or hourly or whatever it doesn't matter but it should be called once in a while



    function Compound() public{



        SaveRewards(); // Executes RecordReward() for ALL addresses.

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



        return (StakeTime * RewardFactor * (TokensStaked[YourAddress]/10000))/86400;

    }



    function RecordReward(address User) internal {



        uint Unclaimed = CalculateRewards(User, CalculateTime(User));

        TokensStaked[User] += Unclaimed;

        TimeStaked[User] = block.timestamp; // Calling record reward makes it so you don't need this line in the parent code.

    }



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



        return RewardFactor * (TokensStaked[YourAddress]/10000);

    }



    // This number is basically how much you would have if you staked one token from the start.

    // Returns a uint with 18 decimals



    function CalculateIndex() public view returns(uint){



        return TokensStaked[address(this)];

    }



    // CheckStakedBalance() Calcuates your current balance with the pending compound, GetCurrentStake() does not.



    function CheckStakedBalance(address YourAddress) public view returns (uint256){



        return(CalculateRewards(YourAddress, CalculateTime(YourAddress)) + TokensStaked[YourAddress]);

    }



    function GetCurrentStake(address YourAddress) external view returns (uint){



        return TokensStaked[YourAddress];

    }



    function isContract(address addr) internal view returns (bool) {



        uint size;

        assembly { size := extcodesize(addr) }

        return size > 0;

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
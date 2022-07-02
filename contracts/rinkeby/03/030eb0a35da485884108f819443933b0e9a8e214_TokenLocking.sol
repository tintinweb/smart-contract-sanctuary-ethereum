/**
 *Submitted for verification at Etherscan.io on 2022-07-02
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



contract TokenLocking{



//// This contract is really similar to ConstantCompoundedTokenStaking.sol, but it has a couple twists

//// Instead of staking, you lock tokens forever to generate more tokens, with many fixes to prevent the compounding system from breaking the contract



    // How to Setup:



    // Step 1: Change the token to the one you want to use in the constructor.

    // Step 2: Deploy the contract. 

    // Step 3: Call EditEmission() with how much % gain should be given out daily.

    // Step 4: Send some tokens to this contract for rewards like how you would send anyone a token and boom, it works.



//// Commissioned by spagetti#7777 on 4/29/2022



    // now to the code:



    // Settings that you can change before deploying



    constructor(){



        admin = msg.sender;

        start = block.timestamp;



        Token = ERC20(0xFD07CAa87D9e25032141878Fbb82eD2Ac54916Ed);



        // The below sets up the index calculation, don't change this.



        TokensLocked[address(this)] += 1*(10**18);

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



    mapping(address => uint) TimeLocked;

    mapping(address => uint) TokensLocked;

    mapping(address => uint) InitalLock;

    mapping(uint => address) public user;

    mapping(address => uint) PendingCompound;

    address admin;

    uint public totalLocked;

    uint public RewardFactor;

    uint Nonce;

    uint start;

    uint public Limit;



    modifier AdminOnly{require(msg.sender == admin, "You aren't the admin so you can't press this button");_;}

    



//////////////////////////                                                              /////////////////////////

/////////////////////////                                                              //////////////////////////

////////////////////////             Visible functions this contract has:             ///////////////////////////

///////////////////////                                                              ////////////////////////////

//////////////////////                                                              /////////////////////////////





    // Functions that let the Admin of this contract change settings.



    function EditLockingLimit(uint limit) public AdminOnly{



        require(limit > Limit, "You cannot set the limit to a number lower than the current limit");



        Limit = limit;

    }



    // If you don't know what basis points are go look it up

    // If you change the emission rate, EVERYONE's rewards will be compounded.



    function EditEmission(uint BPSperDay) public AdminOnly{



        SaveRewardsALT(); //Saves everyone's rewards without compounding.

        RewardFactor = BPSperDay; // Switches to the new reward percentage

    }



    function SweepToken(ERC20 TokenAddress) public AdminOnly {



        require(TokenAddress != Token, "You cannot sweep the reward token.");

        TokenAddress.transfer(msg.sender, TokenAddress.balanceOf(address(this))); 

    }



    // The Lock button Locks your tokens.

    // SECURITY WARNING, This address MUST be immune to the token fee or else things will break. (lol)



    function Lock(uint amount) public {



        require(Limit != 0, "The global limit is set to zero, nobody can lock anything if its set to zero");

        require(totalLocked <= Limit*(10**Token.decimals()), "You cannot deposit anything has the MAX lock amount has been hit!");



        require(Token.balanceOf(msg.sender) > 0, "You don't have any tokens to lock!");

        require(msg.sender != address(0), "What the fuck");



        RecordReward(msg.sender); // Saves and compounds the msg.sender's rewards

        Token.transferFrom(msg.sender, address(this), amount); // Deposits "Token" into this contract

        TokensLocked[msg.sender] += amount; // Keeps track of how many tokens you deposited

        InitalLock[msg.sender] += amount;



        user[Nonce] = msg.sender; // Records your address to use in SaveRewards()



        totalLocked += amount; // Add the coins you deposited to the total Locked amount



        require(totalLocked <= Limit*(10**Token.decimals()), "This deposit would cause the global locking limit to be hit, try depositing a lower amount");

        Nonce += 1;

    }



    // ClaimRewards sends all avalable rewards to the msg.sender



    function ClaimRewards() public {



        require(TokensLocked[msg.sender] > 0, "You haven't locked any tokens, so there's nothing for you to claim...");



        uint Unclaimed = CalculateRewards(msg.sender) + PendingCompound[msg.sender];



        require(Unclaimed < Token.balanceOf(address(this)), "This contract has no more rewards to give out, uh oh");

        Token.transfer(msg.sender, Unclaimed);



        TimeLocked[msg.sender] = block.timestamp;

    }



    // The compound button compounds the users rewards, be wary that this LOCKS your tokens again.



    function Compound() public {



        RecordReward(msg.sender); // Compounds the msg.sender's rewards

    }





//////////////////////////                                                              /////////////////////////

/////////////////////////                                                              //////////////////////////

////////////////////////      Internal and external functions this contract has:      ///////////////////////////

///////////////////////                                                              ////////////////////////////

//////////////////////                                                              /////////////////////////////





    // (msg.sender SHOULD NOT be used/assumed in any of these functions.)



    function CalculateRewards(address YourAddress) internal view returns (uint256){



        uint Time = (block.timestamp - TimeLocked[YourAddress]);

        if(TimeLocked[YourAddress] == block.timestamp){Time = 0;}



        return (Time * RewardFactor * (TokensLocked[YourAddress]/10000))/86400;

    }



    function RecordReward(address User) internal {



        uint Unclaimed = CalculateRewards(User);

        TokensLocked[User] += Unclaimed + PendingCompound[User];

        PendingCompound[msg.sender] = 0;

        TimeLocked[User] = block.timestamp; // Calling record reward makes it so you don't need this line in the parent code.

    }



    function RecordRewardALT(address User) internal {



        uint Unclaimed = CalculateRewards(User);

        PendingCompound[User] += Unclaimed;

        TimeLocked[User] = block.timestamp; // Calling record reward makes it so you don't need this line in the parent code.

    }



    // SaveRewards compounds, SaveRewardsALT does not.



    function SaveRewardsALT() internal {



        uint UserNonce = 1;



        while(user[UserNonce] != address(0)){



            RecordRewardALT(user[UserNonce]);

            UserNonce += 1;

        }

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



        return RewardFactor * (TokensLocked[YourAddress]/100);

    }



    // This number is basically how much you would have if you Locked one token from the start.

    // Returns a uint with 18 decimals



    function CalculateIndex() public view returns(uint){



        return TokensLocked[address(this)];

    }



    // CheckLockedBalance() Calcuates your current balance with the pending compound, GetCurrentLock() does not.



    function CheckLockedBalance(address YourAddress) public view returns (uint256){



        return(CalculateRewards(YourAddress) + TokensLocked[YourAddress] + PendingCompound[YourAddress]);

    }



    function GetClaimableRewards(address YourAddress) public view returns (uint){



        return(CalculateRewards(YourAddress) + PendingCompound[YourAddress]);

    }



    function GetCurrentLock(address YourAddress) external view returns (uint){



        return TokensLocked[YourAddress];

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



interface ERC20{

    function transferFrom(address, address, uint256) external;

    function transfer(address, uint256) external;

    function balanceOf(address) external view returns(uint);

    function decimals() external view returns (uint8);

}
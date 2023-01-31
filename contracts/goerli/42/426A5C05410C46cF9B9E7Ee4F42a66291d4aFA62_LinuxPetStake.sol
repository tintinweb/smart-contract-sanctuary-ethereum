/**
 *Submitted for verification at Etherscan.io on 2023-01-31
*/

// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.17;

contract LinuxPetStake{
    //Core Variables
    address public Pets = 0xF063BeccBccA5698532673de7E454Acd8B603BEA;
    address public Food = 0xF98b0713375793184E49526a243D799a5179735a;
    address public LinuxToken = 0x369Acc7aaE208F59f0a4043A534943cfd7C0a066;
    address public Owner;
    uint256 public BasePay = 100000000000000000000; //Yearly Base ROI in $LinuxToken
    uint256 public FoodBoost = 1000; // in 0.0001 of percentage
    uint256 public TotalPetsStaked;
    uint256[] internal EmptyArray;

    //FIXME: 1 year in seconds, do not forget to change: 31557600

    //All stakes stored here
    mapping(uint256 => PetStake) public PetStakes; 
    mapping(address => uint256[]) internal StakedPets;//TODO: TEST
    mapping(address => mapping (uint256 => uint256)) internal PetIndex;//TODO: TEST

    struct PetStake{
        bool Staked;
        address Staker;
        uint256 FoodStaked;
        uint256[] FoodIDs; //List of all food IDs staked with this pet
        uint256 ROIPerSecond; //Tokens returned per second
        uint256 LastPayout; //Last time this stake was claimed
    }

    event PetStaked(uint256 PetID, address Staker);
    event PetUnstaked(uint256 PetID, address Staker);
    event FoodStaked(uint256 PetID, uint256 FoodID, address Staker);
    event RewardsClaimed(uint256 Payout, address Staker);

    constructor(){
        Owner = msg.sender;
    }


    //Stake Pet With no Food
    function StakePet(uint256 PetID) public returns(bool success){ 
        ERC721(Pets).transferFrom(msg.sender, address(this), PetID); //No Extra checks since function will bounce if owner is not message sender, just gas savings 

        uint256 ROIPerSecond = (BasePay / 600);
        PetStakes[PetID] = PetStake(true, msg.sender, 0, EmptyArray, ROIPerSecond, block.timestamp);

        StakedPets[msg.sender].push(PetID); //TODO: TEST
        PetIndex[msg.sender][PetID] = StakedPets[msg.sender].length - 1;
        TotalPetsStaked++;

        emit PetStaked(PetID, msg.sender);
        return(success);
    }

    //Stake pet with up to 10 food
    function StakePetWithFood(uint256 PetID, uint256[] memory FoodIDs) public returns(bool success){ 
        require(FoodIDs.length <= 10);
        ERC721(Pets).transferFrom(msg.sender, address(this), PetID); //No Extra checks since function will bounce if owner is not message sender, just gas savings 
        
        uint256 index = 0;
        while(index < FoodIDs.length){
            ERC721(Food).transferFrom(msg.sender, address(this), FoodIDs[index]);
            emit FoodStaked(PetID, FoodIDs[index], msg.sender);
            index++;
        }

        uint256 FoodMultiplier = FoodIDs.length * FoodBoost;
        uint256 ROIPerSecond = (BasePay / 600) + (((BasePay / 600) * FoodMultiplier) / 100000);
        PetStakes[PetID] = PetStake(true, msg.sender, FoodIDs.length, FoodIDs, ROIPerSecond, block.timestamp);

        StakedPets[msg.sender].push(PetID);//TODO: TEST
        PetIndex[msg.sender][PetID] = StakedPets[msg.sender].length - 1;//TODO: TEST
        TotalPetsStaked++;

        return(success);
    }

    //Stakes the maximum of food you have with your pet, up to 10
    function StakePetWithMaxFood(uint256 PetID) public returns(bool success){ 
        require(ERC721(Food).balanceOf(msg.sender) > 0);
        uint256[] memory AllFoods = ERC721(Food).walletOfOwner(msg.sender);
        uint256[] memory FoodsToSubmit;

        uint256 Total = AllFoods.length;
        uint256 Index;

        while(Index < Total && FoodsToSubmit.length < 10){ //TODO: TEST
            FoodsToSubmit[Index] = AllFoods[Index];
            Index++;
        }

        StakePetWithFood(PetID, FoodsToSubmit);

        return(success);
    }
    
    //Allows user to stake a number of food to a Pet, claims rewards before setting the new ROI
    function StakeFood(uint256 PetID, uint256[] memory FoodIDs) public returns(bool success){ //TODO: TEST
        ClaimRewards(PetID); //Does not check for owner since that already happens in ClaimReward
        require((PetStakes[PetID].FoodStaked + FoodIDs.length) <= 10);

        uint256 index = 0;
        while(index < FoodIDs.length){
            ERC721(Food).transferFrom(msg.sender, address(this), FoodIDs[index]);
            PetStakes[PetID].FoodIDs.push(FoodIDs[index]);
            emit FoodStaked(PetID, FoodIDs[index], msg.sender);
            index++;
        }
        PetStakes[PetID].FoodStaked = PetStakes[PetID].FoodIDs.length;

        uint256 FoodMultiplier = FoodBoost * PetStakes[PetID].FoodStaked;
        uint256 NewSecondsROI = (BasePay / 600) + (((BasePay / 600) * FoodMultiplier) / 100000);
        PetStakes[PetID].ROIPerSecond = NewSecondsROI;

        return(success);
    }

    //Claims all rewards for given stake, only staker
    function ClaimRewards(uint256 PetID) public returns(bool success, uint256 Payout){
        require(PetStakes[PetID].Staked == true && PetStakes[PetID].Staker == msg.sender);

        Payout = (PetStakes[PetID].ROIPerSecond * (block.timestamp - PetStakes[PetID].LastPayout));
        PetStakes[PetID].LastPayout = block.timestamp;

        uint256 FoodMultiplier = FoodBoost * PetStakes[PetID].FoodStaked;
        uint256 NewSecondsROI = (BasePay / 600) + (((BasePay / 600) * FoodMultiplier) / 100000);
        PetStakes[PetID].ROIPerSecond = NewSecondsROI;

        ERC20(LinuxToken).transfer(msg.sender, Payout);

        emit RewardsClaimed(Payout, msg.sender);
        return(success, Payout);
    }

    //Unstakes pet and returns Foods(if any)
    function UnstakePet(uint256 PetID) public returns(bool success){ 
        ClaimRewards(PetID); //Does not check for owner since that already happens in ClaimReward
        PetStakes[PetID].Staked = false;

        ERC721(Pets).transferFrom(address(this), msg.sender, PetID);

        uint256 index = 0;
        while(index < PetStakes[PetID].FoodIDs.length){
            ERC721(Food).transferFrom(address(this), msg.sender, PetStakes[PetID].FoodIDs[index]);
            index++;
        }
        
        PetStakes[PetID] = PetStake(false, address(0), 0, EmptyArray, 0, 0);

        if(StakedPets[msg.sender][StakedPets[msg.sender].length - 1] != PetID){ //TODO: TEST
            StakedPets[msg.sender][PetIndex[msg.sender][PetID]] = StakedPets[msg.sender][StakedPets[msg.sender].length - 1];
        }
        PetIndex[msg.sender][PetID] = 0;
        delete StakedPets[msg.sender];
        TotalPetsStaked--;

        emit PetUnstaked(PetID, msg.sender);
        return(success);
    }

    //Allows users to unstake their NFT even if there isnt enough funds to pay out their reward
    function EmergencyUnstakePet(uint256 PetID) public returns(bool success){ //TODO: TEST
        require(PetStakes[PetID].Staked == true && PetStakes[PetID].Staker == msg.sender);
        PetStakes[PetID].Staked = false;

        ERC721(Pets).transferFrom(address(this), msg.sender, PetID);

        uint256 index = 0;
        while(index < PetStakes[PetID].FoodIDs.length){
            ERC721(Food).transferFrom(address(this), msg.sender, PetStakes[PetID].FoodIDs[index]);
            index++;
        }
        
        PetStakes[PetID] = PetStake(false, address(0), 0, EmptyArray, 0, 0);

        if(StakedPets[msg.sender][StakedPets[msg.sender].length - 1] != PetID){
            StakedPets[msg.sender][PetIndex[msg.sender][PetID]] = StakedPets[msg.sender][StakedPets[msg.sender].length - 1];
        }
        PetIndex[msg.sender][PetID] = 0;
        delete StakedPets[msg.sender];

        emit PetUnstaked(PetID, msg.sender);
        return(success);
    }

    //View  Functions

    function GetUnclaimedReward(uint256 PetID) public view returns(uint256 UnclaimedReward){ //TODO: TEST
        require(PetStakes[PetID].Staked == true);
        return(PetStakes[PetID].ROIPerSecond * (block.timestamp - PetStakes[PetID].LastPayout));
    }

    function GetStakedPets(address User) public view returns(uint256[] memory PetIDs){
        return(StakedPets[User]);
    }

    function GetStakedFood(uint256 PetID) public view returns(uint256[] memory StakedFood){ //TODO: TEST
        require(PetStakes[PetID].Staked == true && PetStakes[PetID].FoodStaked > 0);
        return(PetStakes[PetID].FoodIDs);
    }


    //Only Owner Functions

    function ChangeBasePay(uint256 NewBasePay) public returns(bool success){ //TODO: TEST
        require(msg.sender == Owner);

        BasePay = NewBasePay;

        return(success);
    }

    function ChangeFoodBoost(uint256 NewFoodBoost) public returns(bool success){ //TODO: TEST
        require(msg.sender == Owner);

        FoodBoost = NewFoodBoost;

        return(success);
    }

    function RemoveRewardPool() public returns(bool success){ //TODO: TEST
        require(msg.sender == Owner);

        ERC20(LinuxToken).transfer(msg.sender, ERC20(LinuxToken).balanceOf(address(this)));

        return(success);
    }

    function TransferOwnership(address NewOwner) public returns(bool success){ //TODO: TEST
        require(msg.sender == Owner);

        Owner = NewOwner;

        return(success);
    }



}

interface ERC721{
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function walletOfOwner(address owner) external view returns (uint256[] memory);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface ERC20 {
  function balanceOf(address owner) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint value) external returns (bool);
  function Mint(address _MintTo, uint256 _MintAmount) external;
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool); 
  function totalSupply() external view returns (uint);
}
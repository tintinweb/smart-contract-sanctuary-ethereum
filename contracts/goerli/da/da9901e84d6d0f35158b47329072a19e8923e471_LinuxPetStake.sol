/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

// File: PetsNFood/LinuxPetStake.sol


pragma solidity ^0.8.17;

contract LinuxPetStake{
    //Core Variables
    address public Pets = 0xF063BeccBccA5698532673de7E454Acd8B603BEA;
    address public Food = 0xF98b0713375793184E49526a243D799a5179735a;
    address public TKN = 0x369Acc7aaE208F59f0a4043A534943cfd7C0a066;
    uint256 public BasePay = 100000000000000000000; //Yearly Base ROI in $TKN
    uint256 public FoodBoost = 1000; // in 0.0001 of percentage
    uint256[] internal EmptyArray;

    //FIXME: 1 year in seconds, do not forget to change: 31557600

    //All stakes stored here
    mapping(uint256 => PetStake) public PetStakes; //TODO: TEST

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


    //Stake Pet With no Food
    function StakePet(uint256 PetID) public returns(bool success){ //TODO: TEST
        ERC721(Pets).transferFrom(msg.sender, address(this), PetID); //No Extra checks since function will bounce if owner is not message sender, just gas savings 

        uint256 ROIPerSecond = (BasePay / 600); //TODO: TEST
        PetStakes[PetID] = PetStake(true, msg.sender, 0, EmptyArray, ROIPerSecond, block.timestamp);

        emit PetStaked(PetID, msg.sender);
        return(success);
    }

    //Stake pet with up to 10 food
    function StakePetWithFood(uint256 PetID, uint256[] memory FoodIDs) public returns(bool success){ //TODO: TEST
        require(FoodIDs.length <= 10);
        ERC721(Pets).transferFrom(msg.sender, address(this), PetID); //No Extra checks since function will bounce if owner is not message sender, just gas savings 
        
        uint256 index = 0;
        while(index < FoodIDs.length){
            ERC721(Food).transferFrom(msg.sender, address(this), FoodIDs[index]);
            emit FoodStaked(PetID, FoodIDs[index], msg.sender);
            index++;
        }

        uint256 FoodMultiplier = FoodIDs.length * FoodBoost;
        uint256 ROIPerSecond = (BasePay / 600) + (((BasePay / 600) * FoodMultiplier) / 10000000); //TODO: TEST
        PetStakes[PetID] = PetStake(true, msg.sender, FoodIDs.length, FoodIDs, ROIPerSecond, block.timestamp);

        return(success);
    }

    //Stakes the maximum of food you have with your pet, up to 10
    function StakePetWithMaxFood(uint256 PetID) public returns(bool success){ //TODO: TEST
        require(ERC721(Food).balanceOf(msg.sender) > 0);
        uint256[] memory AllFoods = ERC721(Food).walletOfOwner(msg.sender);
        uint256[] memory FoodsToSubmit;

        uint256 Total;
        uint256 Index;
        if(AllFoods.length < 10){
            Total = AllFoods.length;
        }
        while(Index < Total){
            FoodsToSubmit[Index] = AllFoods[Index];
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
        uint256 NewSecondsROI = (BasePay / 600) + (((BasePay / 600) * FoodMultiplier) / 10000000);

        PetStakes[PetID].ROIPerSecond = NewSecondsROI;

        return(success);
    }

    //Claims all rewards for given stake, only staker
    function ClaimRewards(uint256 PetID) public returns(bool success, uint256 Payout){ //TODO: TEST
        require(PetStakes[PetID].Staked == true && PetStakes[PetID].Staker == msg.sender);

        Payout = (PetStakes[PetID].ROIPerSecond * (block.timestamp - PetStakes[PetID].LastPayout));
        PetStakes[PetID].LastPayout = block.timestamp;

        ERC20(TKN).transfer(msg.sender, Payout);

        emit RewardsClaimed(Payout, msg.sender);
        return(success, Payout);
    }

    //Unstakes pet and returns Foods(if any)
    function UnstakePet(uint256 PetID) public returns(bool success){ //TODO: TEST
        ClaimRewards(PetID); //Does not check for owner since that already happens in ClaimReward
        PetStakes[PetID].Staked = false;

        ERC721(Pets).transferFrom(address(this), msg.sender, PetID);

        uint256 index = 0;
        while(index < PetStakes[PetID].FoodIDs.length){
            ERC721(Food).transferFrom(msg.sender, address(this), PetStakes[PetID].FoodIDs[index]);
            index++;
        }
        
        PetStakes[PetID] = PetStake(false, address(0), 0, EmptyArray, 0, 0);

        emit PetUnstaked(PetID, msg.sender);
        return(success);
    }

    //TODO: Change Base pay and Boost Pay OnlyOwner
    //Only Owner Functions


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
/**
 *Submitted for verification at Etherscan.io on 2022-12-01
*/

// SPDX-License-Identifier: UNLICENSE
//This contract uses ERC721 tokens to verify the ownership of rewards before transfer
//Created by SoteriaSC for ShibaClassic/ClassicDawgs but is open-source
pragma solidity >=0.7.0 <0.9.0;

contract NFTRewardDistributor{
    //Variable Declarations
    uint256 public TotalTokens;
    uint256 public TotalEtherInRewards;
    uint256 public MinimumToReward;
    address public NFTcontract;
    RewardInstance[] public RewardInstances;

    //Mapping, structs, enums and other declarations
    mapping(uint256 => uint256) public LatestClaim;

    struct RewardInstance{
        uint256 InstanceIdentifier;
        uint256 TotalEther;
        uint256 EtherReward;
    }

    //On Deploy code to run (Constructor)
    constructor(address _NFTcontract, uint256 _MinimumToReward){
        NFTcontract = _NFTcontract;
        MinimumToReward = _MinimumToReward;
        TotalTokens = ERC721(NFTcontract).maxSupply();
    }

    //Public functions
    function GetTotalUnclaimed() public view returns(uint256 Unclaimed){
        uint256 TotalUnclaimed;
        uint256[] memory Tokens = ERC721(NFTcontract).walletOfOwner(msg.sender);

        for(uint256 index; index < Tokens.length; index++){
            if(LatestClaim[Tokens[index]] != (RewardInstances.length - 1)){
                for(uint256 Instance = (LatestClaim[Tokens[index]] + 1); Instance < RewardInstances.length;){
                    TotalUnclaimed = (TotalUnclaimed + RewardInstances[Instance].EtherReward);
                }
            }
        }
        return(TotalUnclaimed);
    }

    function ClaimAllRewards() public returns(uint256 TotalRewardOutput){
        uint256 TotalReward;
        uint256[] memory Tokens = ERC721(NFTcontract).walletOfOwner(msg.sender);

        for(uint256 index; index < Tokens.length; index++){
            if(LatestClaim[Tokens[index]] != (RewardInstances.length - 1)){
                for(uint256 Instance = (LatestClaim[Tokens[index]] + 1); Instance < RewardInstances.length;){
                    TotalReward = (TotalReward + RewardInstances[Instance].EtherReward);
                }
            }
            LatestClaim[Tokens[index]] = (RewardInstances.length - 1);
        }

        TotalEtherInRewards = (TotalEtherInRewards - TotalReward);
        (payable(msg.sender)).transfer(TotalReward);

        return(TotalReward);
    }

    //Internal functions
    function InitializeRewardInstance() internal{
        uint256 NewIdentifier = RewardInstances.length;

        uint256 TotalEther = (address(this).balance - TotalEtherInRewards);
        uint256 EtherReward = (TotalEther / TotalTokens);

        RewardInstance memory NewInstance = RewardInstance(NewIdentifier, TotalEther, EtherReward);
        RewardInstances.push(NewInstance);
    }

    receive() external payable {
        if((address(this).balance - TotalEtherInRewards) >= MinimumToReward){
            InitializeRewardInstance();
        }
    }
}

interface ERC721{
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function walletOfOwner(address owner) external view returns(uint256[] memory IDs);
    function maxSupply() external view returns(uint256);
}
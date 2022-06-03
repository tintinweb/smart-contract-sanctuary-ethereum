// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IERC721.sol";

//import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
//import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

contract RockstarApesStaking is ReentrancyGuard, Ownable{
    IERC721 public parentNFT;
    IERC20 public rewardsToken;

    //mapping for tokenId to staker address
    mapping(uint256 => address) public ownerOfStakedNFT;

    //mapping for amount staked per address
    mapping(address => uint256) public stakedNFTs;

    //mapping to total time staked
    //maps token id by the block.timestamp staked
    mapping (uint256 => uint256) public stakingStartTime;
    mapping (uint256 => uint256) public unclaimedRewards;

    uint32 public rewardRate = 86400; // 77 a day per nft
    uint32 public rareRewardRate = 125;
    uint32 public NFTsStaked;
    mapping(uint256 => bool) public rareIDs;

    constructor(){
        rewardsToken = IERC20(0x85504555c4B6AE212Db6BE8A275e834A65970F3c); //change
        parentNFT = IERC721(0xf56C645349d6c76Afd1B7976B5Fd651d6e42e89F); //change
        NFTsStaked = 0;

        // set rare Ids eg: rareIDs[129] = true;
    }

    function findRewards(uint256 _tokenId) public{
        uint256 realId = _tokenId - 1;
        uint256 reward;
        if(apeIsRare(realId)){
            reward = rareRewardRate * (block.timestamp - stakingStartTime[realId]) / 86400; // per day
        }
        else{
        reward = rewardRate * (block.timestamp - stakingStartTime[realId]) / 86400; // per day
        }
        unclaimedRewards[realId] += reward;
        stakingStartTime[realId] = block.timestamp;
    }

    function showRewards(uint256 _tokenId) public view returns(uint256){
        uint256 realId = _tokenId - 1;

        if(apeIsRare(realId)){
            rareRewardRate * (block.timestamp - stakingStartTime[realId]) / 86400; // per day
        }
        return rewardRate * (block.timestamp - stakingStartTime[realId]) / 86400; // per day
    }

    // have to set approval for all here first
    function stakeNFT(uint256 _tokenId) public nonReentrant{

        uint256 realId = _tokenId - 1;
        NFTsStaked += 1;
        stakedNFTs[_msgSender()] += 1;
        ownerOfStakedNFT[realId] = _msgSender();
        stakingStartTime[realId] = block.timestamp;
        parentNFT.safeTransferFrom(_msgSender(), address(this), realId);
    }

    function unStakeNFT(uint256 _tokenId) external {
        uint256 realId = _tokenId - 1;
        require(ownerOfStakedNFT[realId] == _msgSender());

        NFTsStaked -= 1;
        stakedNFTs[_msgSender()] -= 1;

        parentNFT.safeTransferFrom(address(this), _msgSender(), realId);
        receiveReward(realId);

        delete stakingStartTime[realId];
        delete ownerOfStakedNFT[realId];
    }

    function receiveReward(uint256 _tokenId) public nonReentrant{
        uint256 realId = _tokenId - 1;
        address client = ownerOfStakedNFT[realId];
        findRewards(realId);
        uint256 reward = unclaimedRewards[realId];
        if(reward <= 0){
            return;
        }
        unclaimedRewards[realId] = 0;

        uint256 realReward = reward * (10**18);
        rewardsToken.transfer(client, realReward);
    }

    function apeIsRare(uint256 realId) internal view returns(bool){
        if(rareIDs[realId]){
            return true;
        }
        return false;
    }

    function setTokenAddress(address addy) public onlyOwner{
        rewardsToken = IERC20(addy);
    }

    function setNFTAddress(address addy) public onlyOwner{
        parentNFT = IERC721(addy);
    }

    function setRewardRate(uint32 rate) external onlyOwner{
        rewardRate = rate;
    }
}
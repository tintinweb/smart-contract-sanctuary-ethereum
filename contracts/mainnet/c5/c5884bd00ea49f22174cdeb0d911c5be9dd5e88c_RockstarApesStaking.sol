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

    uint32 public rewardRate = 77; // 77 a day per nft
    uint32 public rareRewardRate = 125;
    uint32 public NFTsStaked;
    mapping(uint256 => bool) public rareIDs;

    constructor(){
        NFTsStaked = 0;
        // set rare Ids eg: rareIDs[129] = true;

rareIDs[1 - 1] = true;
rareIDs[2 - 1] = true;
rareIDs[256 - 1] = true;
rareIDs[312 - 1] = true;
rareIDs[490 - 1] = true;
rareIDs[578 - 1] = true;
rareIDs[619 - 1] = true;
rareIDs[777 - 1] = true;
rareIDs[809 - 1] = true;
rareIDs[998 - 1] = true;
rareIDs[1020 - 1] = true;
rareIDs[1140 - 1] = true;
rareIDs[1251 - 1] = true;
rareIDs[1321 - 1] = true;
rareIDs[1489 - 1] = true;
rareIDs[1576 - 1] = true;
rareIDs[1602 - 1] = true;
rareIDs[1729 - 1] = true;
rareIDs[1853 - 1] = true;
rareIDs[1921 - 1] = true;
rareIDs[2091 - 1] = true;
rareIDs[2175 - 1] = true;
rareIDs[2241 - 1] = true;
rareIDs[2372 - 1] = true;
rareIDs[2410 - 1] = true;
rareIDs[2585 - 1] = true;
rareIDs[2678 - 1] = true;
rareIDs[2790 - 1] = true;
rareIDs[2841 - 1] = true;
rareIDs[2992 - 1] = true;
rareIDs[3014 - 1] = true;
rareIDs[3195 - 1] = true;
rareIDs[3281 - 1] = true;
rareIDs[3301 - 1] = true;
rareIDs[3489 - 1] = true;
rareIDs[3582 - 1] = true;
rareIDs[3635 - 1] = true;
rareIDs[3783 - 1] = true;
rareIDs[3819 - 1] = true;
rareIDs[3938 - 1] = true;
rareIDs[4019 - 1] = true;
rareIDs[4129 - 1] = true;
rareIDs[4217 - 1] = true;
rareIDs[4337 - 1] = true;
rareIDs[4494 - 1] = true;
rareIDs[4589 - 1] = true;
rareIDs[4612 - 1] = true;
rareIDs[4700 - 1] = true;
rareIDs[4892 - 1] = true;
rareIDs[4920 - 1] = true;
rareIDs[5012 - 1] = true;
rareIDs[5142 - 1] = true;
rareIDs[5294 - 1] = true;
rareIDs[5385 - 1] = true;
rareIDs[5487 - 1] = true;
rareIDs[5592 - 1] = true;
rareIDs[5683 - 1] = true;
rareIDs[5755 - 1] = true;
rareIDs[5888 - 1] = true;
rareIDs[5918 - 1] = true;
rareIDs[6001 - 1] = true;
rareIDs[6189 - 1] = true;
rareIDs[6209 - 1] = true;
rareIDs[6345 - 1] = true;
rareIDs[6481 - 1] = true;
rareIDs[6591 - 1] = true;
rareIDs[6604 - 1] = true;
rareIDs[6792 - 1] = true;
rareIDs[6853 - 1] = true;
rareIDs[6987 - 1] = true;
rareIDs[7015 - 1] = true;
rareIDs[7184 - 1] = true;
rareIDs[7234 - 1] = true;
rareIDs[7349 - 1] = true;
rareIDs[7491 - 1] = true;
rareIDs[7510 - 1] = true;
rareIDs[7777 - 1] = true;
    }

    function findRewards(uint256 _tokenId) public{
        uint256 reward;
        if(apeIsRare(_tokenId)){
            reward = rareRewardRate * (block.timestamp - stakingStartTime[_tokenId]) / 86400; // per day
        }
        else{
            reward = rewardRate * (block.timestamp - stakingStartTime[_tokenId]) / 86400; // per day
        }
        unclaimedRewards[_tokenId] += reward;
        stakingStartTime[_tokenId] = block.timestamp;
    }

    function showRewards(uint256 _tokenId) public view returns(uint256){

        if(apeIsRare(_tokenId)){
            return rareRewardRate * (block.timestamp - stakingStartTime[_tokenId]) / 86400; // per day
        }
        return rewardRate * (block.timestamp - stakingStartTime[_tokenId]) / 86400; // per day
    }

    // have to set approval for all here first
    function stakeNFT(uint256 _tokenId) public nonReentrant{

        NFTsStaked += 1;
        stakedNFTs[_msgSender()] += 1;
        ownerOfStakedNFT[_tokenId] = _msgSender();
        stakingStartTime[_tokenId] = block.timestamp;
        parentNFT.transferFrom(_msgSender(), address(this), _tokenId);
    }

    function unStakeNFT(uint256 _tokenId) external {
        require(ownerOfStakedNFT[_tokenId] == _msgSender());

        NFTsStaked -= 1;
        stakedNFTs[_msgSender()] -= 1;

        parentNFT.transferFrom(address(this), _msgSender(), _tokenId);
        receiveReward(_tokenId);

        delete stakingStartTime[_tokenId];
        delete ownerOfStakedNFT[_tokenId];
    }

    function receiveReward(uint256 _tokenId) public nonReentrant{
        address client = ownerOfStakedNFT[_tokenId];
        findRewards(_tokenId);
        uint256 reward = unclaimedRewards[_tokenId];
        if(reward == 0){
            return;
        }
        unclaimedRewards[_tokenId] = 0;

        uint256 realReward = reward * (10**18);
        rewardsToken.transfer(client, realReward);
    }

    function apeIsRare(uint256 _tokenId) internal view returns(bool){
        if(rareIDs[_tokenId]){
            return true;
        }
        return false;
    }

    function removeRareApe(uint256 _tokenId) external onlyOwner{
        rareIDs[_tokenId] = false;
    }

    function addRareApe(uint256 _tokenId) external onlyOwner{
        rareIDs[_tokenId] = true;
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
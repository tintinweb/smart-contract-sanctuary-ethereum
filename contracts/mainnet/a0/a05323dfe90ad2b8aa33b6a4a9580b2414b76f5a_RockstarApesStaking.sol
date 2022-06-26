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

    uint maxSupply = 444;

    //mapping for tokenId to staker address
    mapping(uint256 => address) public ownerOfStakedNFT;

    //mapping for staked nfts per address
    mapping(address => uint256[]) public stakedNFTs;


    //mapping to total time staked
    //maps token id by the block.timestamp staked
    mapping (uint256 => uint256) public stakingStartTime;
    mapping (uint256 => uint256) public unclaimedRewards;

    uint32 public rewardRate = 125; // 77 a day per nft
    uint32 public rareRewardRate = 125;
    uint32 public NFTsStaked;
    mapping(uint256 => bool) public rareIDs;

    constructor(){
        NFTsStaked = 0;
        // set rare Ids eg: rareIDs[129] = true;
    }

    function findOwned(address sender) external view returns(bool[] memory){
        bool[] memory owned = new bool[](maxSupply);
        for(uint i = 0; i < maxSupply; i++){
            if(i == 330){
                continue;
            }
            if(parentNFT.ownerOf(i) == sender){
                owned[i] = true;
            } 
        }
        return owned;
    }

    function findStaked(address sender) external view returns(uint256[] memory){
        uint256[] memory owned = new uint256[](stakedNFTs[sender].length);
        for(uint i = 0; i < owned.length; i++){
            owned[i] = stakedNFTs[sender][i];
        }

        return owned;
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
        stakedNFTs[_msgSender()].push(_tokenId);
        NFTsStaked += 1;
        ownerOfStakedNFT[_tokenId] = _msgSender();
        stakingStartTime[_tokenId] = block.timestamp;
        parentNFT.transferFrom(_msgSender(), address(this), _tokenId);
    }

    function unStakeNFT(uint256 _tokenId) external {
        require(ownerOfStakedNFT[_tokenId] == _msgSender());

        for(uint256 i = 0; i < stakedNFTs[_msgSender()].length; i++){
            if(stakedNFTs[_msgSender()][i] == _tokenId){
                stakedNFTs[_msgSender()][i] = stakedNFTs[_msgSender()][stakedNFTs[_msgSender()].length - 1];
                stakedNFTs[_msgSender()].pop();
                break;
            }
        }

        NFTsStaked -= 1;

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

    function setRareRewardRate(uint32 rate) external onlyOwner{
        rareRewardRate = rate;
    }
}
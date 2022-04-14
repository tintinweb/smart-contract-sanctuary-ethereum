// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./TokenName.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./NFTContract.sol";

//import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract HighHorseStaking is ReentrancyGuard, Ownable{
    HighHorseHouse public parentNFT;
    HighHorseCoin public rewardsToken;

    //mapping for tokenId to staker address
    mapping(uint256 => address) public ownerOfStakedNFT;

    //mapping for amount staked per address
    mapping(address => uint256) public stakedNFTs;

    //mapping to total time staked
    //maps token id by the block.timestamp staked
    mapping (uint256 => uint256) public stakingStartTime;
    mapping (uint256 => uint256) public unclaimedRewards;

    uint32 public rewardRate = 100; // 50 a day per nft
    uint32 public NFTsStaked;

    constructor(){
        rewardsToken = HighHorseCoin(0x20742a2dc5A32BAc3d6d20e431A2953cb65DBc27); //change
        parentNFT = HighHorseHouse(0xE226613eaeA1B6272651555f0e0d7105b716059f); //change
        NFTsStaked = 0;
    }

    function findRewards(uint256 _tokenId) public{
        uint256 realId = _tokenId - 1;
        uint256 reward = rewardRate * (block.timestamp - stakingStartTime[realId]) / 86400; // per day
        unclaimedRewards[realId] += reward;
        stakingStartTime[realId] = block.timestamp;
    }

    function showRewards(uint256 _tokenId) public view returns(uint256){
        uint256 realId = _tokenId - 1;
        return rewardRate * (block.timestamp - stakingStartTime[realId]) / 86400; // per day
    }

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
        rewardsToken.mintToken(client, reward);
    }

    function desposit() external payable{}

    function setTokenAddress(address addy) public onlyOwner{
        rewardsToken = HighHorseCoin(addy);
    }

    function setNFTAddress(address addy) public onlyOwner{
        parentNFT = HighHorseHouse(addy);
    }

    function setRewardRate(uint32 rate) external onlyOwner{
        rewardRate = rate;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./TokenName.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./NFTContract.sol";

//import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract RockstarApesStaking is ReentrancyGuard, Ownable{
    RockstarApes public parentNFT;
    RockstarApesCoin public rewardsToken;

    //mapping for tokenId to staker address
    mapping(uint256 => address) public ownerOfStakedNFT;

    //mapping for amount staked per address
    mapping(address => uint256) public stakedNFTs;

    //mapping to total time staked
    //maps token id by the block.timestamp staked
    mapping (uint256 => uint256) public stakingStartTime;
    mapping (uint256 => uint256) public unclaimedRewards;

    uint32 public rewardRate = 77; // 100 a day per nft
    uint32 public NFTsStaked;

    constructor(){
        rewardsToken = RockstarApesCoin(0x752f6d87fb96d0739DE60625d10CF170728BEB60); //change
        parentNFT = RockstarApes(0xc4f922C502953161ec676Ef20E5e0d36eEb3089c); //change
        NFTsStaked = 0;
    }

    function findRewards(uint _tokenId) public{
        uint256 reward = rewardRate * (block.timestamp - stakingStartTime[_tokenId]);// / 86400; // per day
        unclaimedRewards[_tokenId] += reward;
        stakingStartTime[_tokenId] = block.timestamp;
    }

    function stakeNFT(uint256 _tokenId) public nonReentrant{
        NFTsStaked += 1;
        stakedNFTs[_msgSender()] += 1;
        ownerOfStakedNFT[_tokenId] = _msgSender();
        stakingStartTime[_tokenId] = block.timestamp;
        parentNFT.safeTransferFrom(_msgSender(), address(this), _tokenId);
    }

    function unStakeNFT(uint256 _tokenId) external nonReentrant{
        require(ownerOfStakedNFT[_tokenId] == _msgSender());
        NFTsStaked -= 1;
        stakedNFTs[_msgSender()] -= 1;

        parentNFT.safeTransferFrom(address(this), _msgSender(), _tokenId);
        //receiveReward(_tokenId);
        delete stakingStartTime[_tokenId];
        delete ownerOfStakedNFT[_tokenId];
    }

    function receiveReward(uint256 _tokenId) public nonReentrant{
        require(ownerOfStakedNFT[_tokenId] == _msgSender(), "You aren't the owner!");
        findRewards(_tokenId);
        uint256 reward = unclaimedRewards[_tokenId];
        require(reward > 0, "reward is not more than 0");
        unclaimedRewards[_tokenId] = 0;
        rewardsToken.mintToken(_msgSender(), reward);
    }

    // for testing
    function a(uint256 _tokenId) public view returns (uint){
        require(ownerOfStakedNFT[_tokenId] == _msgSender(), "You aren't the owner!");
        return 1;
    }

    function b() public returns (uint){
        NFTsStaked -= 1;
        stakedNFTs[_msgSender()] -= 1;
        return 1;
    }

    function c(uint256 _tokenId) public returns(uint){
        unclaimedRewards[_tokenId] = 100;
        uint256 reward = unclaimedRewards[_tokenId];
        require(reward > 0, "reward is not more than 0");
        unclaimedRewards[_tokenId] = 0;
        return reward;
    }

    function d() public returns(uint){
        rewardsToken.mintToken(_msgSender(), 100);
        return 100;
    }

    function desposit() external payable{}

    function setTokenAddress(address addy) public onlyOwner{
        rewardsToken = RockstarApesCoin(addy);
    }

    function setNFTAddress(address addy) public onlyOwner{
        parentNFT = RockstarApes(addy);
    }

    function setRewardRate(uint32 rate) external onlyOwner{
        rewardRate = rate;
    }
}
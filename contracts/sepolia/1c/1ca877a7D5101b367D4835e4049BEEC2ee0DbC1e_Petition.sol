/**
 *Submitted for verification at Etherscan.io on 2023-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Petition {
    struct PetitionData {
        uint256 id;
        string title;
        string description;
        address owner;
        address signingToken;
        uint256 minimumTokenBalance;
        bool active;
        mapping(address => uint256) stakedTokens;
        mapping(address => uint256) lastClaimedTime;
    }

    mapping(uint256 => PetitionData) petitions;
    mapping(address => uint256[]) userPetitions;
    mapping(address => mapping(uint256 => bool)) hasStaked;

    address changeTokens;
    address contractOwner;
    address[] allowedTokens;
    uint256 totalPetitions;

    constructor() {
        contractOwner = msg.sender;
        totalPetitions = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only contract owner can call this function");
        _;
    }
    
    function setChangeToken(address newToken) external onlyOwner {
        changeTokens = newToken;
    }

    function addAllowedToken(address token) external onlyOwner {
        allowedTokens.push(token);
    }

    function removeAllowedToken(address token) external onlyOwner {
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            if (allowedTokens[i] == token) {
                allowedTokens[i] = allowedTokens[allowedTokens.length - 1];
                allowedTokens.pop();
                break;
            }
        }
    }

    function createPetition(
        string memory title,
        string memory description,
        address signingToken,
        uint256 minimumTokenBalance
    ) external {
        require(isTokenAllowed(signingToken), "Signing token not allowed");
        require(minimumTokenBalance > 0, "Minimum token balance should be greater than 0");

        totalPetitions++;

        PetitionData storage newPetition = petitions[totalPetitions];
        newPetition.id = totalPetitions;
        newPetition.title = title;
        newPetition.description = description;
        newPetition.owner = msg.sender;
        newPetition.signingToken = signingToken;
        newPetition.minimumTokenBalance = minimumTokenBalance;
        newPetition.active = true;
        
        userPetitions[msg.sender].push(totalPetitions);
    }

    function claimRewards(uint256 petitionId) external {
        require(petitionId <= totalPetitions, "Invalid petition ID");

        PetitionData storage petition = petitions[petitionId];
        
        uint256 stakedAmount = petition.stakedTokens[msg.sender];
        uint256 lastClaimedTime = petition.lastClaimedTime[msg.sender];
        uint256 elapsedTime = block.timestamp - lastClaimedTime;

        require(elapsedTime >= 10 seconds, "Wait for at least 10 seconds before claiming rewards");

        uint256 rewardAmount = (stakedAmount * 3) / 100; // 3% of staked amount
        
        IERC20(changeTokens).transfer(msg.sender, rewardAmount);

        petition.lastClaimedTime[msg.sender] = block.timestamp;
    }

    function removeSign(uint256 petitionId) external {
        require(petitionId <= totalPetitions, "Invalid petition ID");

        PetitionData storage petition = petitions[petitionId];
        address staker = msg.sender;

        uint256 stakedAmount = petition.stakedTokens[staker];

        require(stakedAmount > 0, "No tokens staked for this petition");
        
        IERC20(petition.signingToken).transferFrom(address(this), staker, stakedAmount);

        delete petition.stakedTokens[staker];
        delete hasStaked[staker][petitionId];
    }

    function isTokenAllowed(address token) private view returns (bool) {
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            if (allowedTokens[i] == token) {
                return true;
            }
        }
        return false;
    }
    
    function signPetition(uint256 petitionId, uint256 stakeAmount) external returns (bool) {
        PetitionData storage petition = petitions[petitionId];
        require(petition.active, "Petition is not active");
        require(IERC20(petition.signingToken).balanceOf(msg.sender) >= petition.minimumTokenBalance, "Insufficient staked tokens");
        require(stakeAmount >= petition.minimumTokenBalance, "Insufficient staked tokens");
        require(petition.stakedTokens[msg.sender] == 0, "Already signed");

        if (IERC20(petition.signingToken).transferFrom(msg.sender, address(this), stakeAmount)) {
            petition.stakedTokens[msg.sender] = stakeAmount;
            petition.lastClaimedTime[msg.sender] = block.timestamp;
            return true;
        }
        
        return false;
    }
    
    // Rest of the contract code...
}
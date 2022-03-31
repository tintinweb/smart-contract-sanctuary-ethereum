// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./RewardContract.sol";


contract Stake is Ownable{

    ERC721A private nftToken;

    RewardContract private rewardToken;

    uint256[] private poolReward = [150000000000000000000, 187500000000000000000, 210000000000000000000];

    // uint256[] private poolLockTime = [7 days, 30 days, 90 days];

    uint256[] private poolLockTime = [60, 120, 180];
  
    struct StakeNFT { 
        bool isExist;  
        uint256 stakeTime;
        uint256 harvested;
        uint256 pool;
    }

    mapping (address =>  uint256[]) public userStakeNFT;

    mapping (address => mapping (uint256 => StakeNFT)) public stakeInfo;
   
    event Staked(address _staker, uint256 [] _tokenId , uint256 _pool, uint256 _time);
   
    event UnStaked(address _staker, uint256 _tokenId , uint256 _time);
   
    event Harvested(address _staker, uint256 _tokenId, uint256 _amount , uint256 _time);
    
    function initialize(address _nftToken, address _rewardToken) public onlyOwner returns(bool){    
		nftToken = ERC721A(_nftToken);
        rewardToken = RewardContract(_rewardToken);
		return true;
	}


    function stake(uint256[] memory _tokenId, uint256 _pool) public returns (bool) {       
        for (uint256 i = 0; i < _tokenId.length; i++) {
            nftToken.transferFrom(msg.sender, address(this), _tokenId[i]);  
            StakeNFT memory stakeDetails;
            stakeDetails = StakeNFT({
                isExist : true,
                stakeTime: block.timestamp,
                harvested: 0, 
                pool: _pool
            });
            stakeInfo[msg.sender][_tokenId[i]] = stakeDetails;
            userStakeNFT[msg.sender].push(_tokenId[i]);
        }
        emit Staked(msg.sender, _tokenId , _pool, block.timestamp);
        return true;
    }

    function unstake(uint256 _tokenId) public returns (bool) {
        require (stakeInfo[msg.sender][_tokenId].isExist, "You are not staked"); 
        require(block.timestamp > stakeInfo[msg.sender][_tokenId].stakeTime + poolLockTime[(stakeInfo[msg.sender][_tokenId].pool) - 1], "Token is in lock period");
        if(getCurrentReward(msg.sender, _tokenId) > 0){
            harvest(msg.sender, _tokenId); 
        }
        nftToken.transferFrom(address(this), msg.sender, _tokenId);
        emit UnStaked(msg.sender, _tokenId ,block.timestamp);
        delete stakeInfo[msg.sender][_tokenId];
        for(uint256 i = 0; i < userStakeNFT[msg.sender].length; i++){
            if(userStakeNFT[msg.sender][i] == _tokenId){
                userStakeNFT[msg.sender][i] = userStakeNFT[msg.sender][userStakeNFT[msg.sender].length-1];
                delete userStakeNFT[msg.sender][userStakeNFT[msg.sender].length-1];
                break;
            }
        }
        return true;
    }

    function harvest(address _user, uint256 _tokenId) public returns (bool) {
        require(getCurrentReward(_user, _tokenId) > 0, "Nothing to harvest");
        uint256 harvestAmount = getCurrentReward(_user, _tokenId);
        rewardToken.mint(_user, harvestAmount);
        stakeInfo[_user][_tokenId].harvested += harvestAmount;
        emit Harvested(_user, _tokenId, harvestAmount ,block.timestamp);
        return true;
    }


    function getTotalReward(address _user, uint256 _tokenId) public view returns (uint256) {
        if(stakeInfo[_user][_tokenId].isExist){
            return uint256(block.timestamp - stakeInfo[_user][_tokenId].stakeTime) * (poolReward[(stakeInfo[_user][_tokenId].pool) - 1])/ (1 days);
        }else{
            return 0;
        }
    }
    
    function getCurrentReward(address _user, uint256 _tokenId) public view returns (uint256) {
        if(stakeInfo[_user][_tokenId].isExist){
            return (getTotalReward(_user, _tokenId)) - (stakeInfo[_user][_tokenId].harvested);
        }else{
            return 0;
        }
    }

    function listOfStakedNFT(address _user) public view returns (uint256[] memory){
        return userStakeNFT[_user];
    }   
}
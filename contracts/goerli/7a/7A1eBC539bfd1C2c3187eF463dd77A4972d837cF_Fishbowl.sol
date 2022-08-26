/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

/**
 *Submitted for verification at polygonscan.com on 2022-08-06
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

interface ERC721R{
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface REWARD_TOKEN{
    function reward(address account, uint256 amount) external;
}


contract Fishbowl{
    address public FishContractAddress = 0x720fDAdD00f535Cd50b621B7ecf844e5d1B257E5;
    address public bubbleAddress;
    address public caviarAddress;

    address public constant owner = 0xD30A31BFA0A884e4bF56d7A5DbE4967d0C84B860;

    uint256 constant ONE_DAY = 86400;

    uint256 public bubbleUnitReward = 100000000000000000000;
    uint256 public caviarUnitReward = 50000000000000000000;
    uint256 public unitRewardPeriod = ONE_DAY;

    bool public stoped;
    uint256 public stopedAt;

    bool public pausedStaking = false;

    

    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => uint256) public stakedAt;
    mapping(uint256 => uint256) public lasClaimedRewardAt;


    modifier onlyOwner() {
        require(msg.sender == owner, 'Only owner!');
        _;
    }

    function togglePaused() external onlyOwner{
        pausedStaking = !pausedStaking;
    }

    function setRewardTokens(address _caviarAddress, address _bubbleAddress) external onlyOwner{
        bubbleAddress = _bubbleAddress;
        caviarAddress = _caviarAddress;
    }

    function setRewardParams(uint256 _bubbleUnitReward, uint256 _caviarUnitReward, uint256 _unitRewardPeriod) external onlyOwner{
        bubbleUnitReward = _bubbleUnitReward;
        caviarUnitReward = _caviarUnitReward;
        unitRewardPeriod = _unitRewardPeriod;
    }

    function toggleStop() external onlyOwner{
        stoped = !stoped;
        stopedAt = block.timestamp;
    }

    function getAbilities(uint256 _id) public pure returns(uint256 _caviar, uint256 _bubble){
        require(_id>0 && _id<1501, 'Wrong id');
        if(_id<253){
            return(1, 1);
        }else if(_id<468){
            return(2, 1);
        }else if(_id<546){
            return(3, 1);
        }else if(_id<604){
            return(4, 1);
        }else if(_id<809){
            return(1, 2);
        }else if(_id<880){
            return(3, 2);
        }else if(_id<1069){
            return(2, 2);
        }else if(_id<1127){
            return(4, 2);
        }else if(_id<1212){
            return(1, 3);
        }else if(_id<1288){
            return(2, 3);
        }else if(_id<1319){
            return(3, 3);
        }else if(_id<1339){
            return(4, 3);
        }else if(_id<1406){
            return(1, 4);
        }else if(_id<1457){
            return(2, 4);
        }else if(_id<1489){
            return(3, 4);
        }else {
            return(4, 4);
        }
    }


    function stakeFish(uint256 _id) external{
        require(!stoped, 'Staking was stoped!');
        require(!pausedStaking, 'Staking was stoped!');
        ERC721R(FishContractAddress).transferFrom(msg.sender, address(this), _id);
        ownerOf[_id] = msg.sender;
        stakedAt[_id] = block.timestamp;
        lasClaimedRewardAt[_id] = block.timestamp;
    }

    function unstakeFish(uint256 _id) external{
        require(ownerOf[_id] == msg.sender, 'Only Fish owner');
        ERC721R(FishContractAddress).transferFrom(address(this), msg.sender, _id);
        ownerOf[_id] = address(0);
    }

    function claimableRewardInTimeFrame(uint256 _id, uint256 _start, uint256 _end) public view returns(uint256 _CaviarReward, uint256 _BubbleReward){
        (uint256 caviarAbility, uint256 bubbleAbility) = getAbilities(_id);
        uint256 periodsPassed = (_end - _start) / unitRewardPeriod;
        _CaviarReward = periodsPassed * caviarUnitReward * caviarAbility;
        _BubbleReward = periodsPassed * bubbleUnitReward * bubbleAbility;
    }

    function instantlyClaimableReward(uint256 _id) public view returns(uint256 _CaviarReward, uint256 _BubbleReward){
        require(ownerOf[_id] != address(0), 'Non staked NFT');
        if(stoped){
            return claimableRewardInTimeFrame(_id, lasClaimedRewardAt[_id], stopedAt);
        }else{
            return claimableRewardInTimeFrame(_id, lasClaimedRewardAt[_id], block.timestamp);
        }
    }

    function claimReward(uint256 _id) external{
        require(ownerOf[_id] == msg.sender, 'Only Fish owner');
        (uint256 caviarReward, uint256 bubbleReward) = instantlyClaimableReward(_id);
        lasClaimedRewardAt[_id] = block.timestamp;
        REWARD_TOKEN(caviarAddress).reward(msg.sender, caviarReward);
        REWARD_TOKEN(bubbleAddress).reward(msg.sender, bubbleReward);
    }

    
}
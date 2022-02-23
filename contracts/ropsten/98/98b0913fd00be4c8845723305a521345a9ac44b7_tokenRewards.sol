/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

pragma solidity ^0.5.7;

/**
 * token contract functions
*/
contract token {
    function transfer(address receiver, uint256 amount) public;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function burnFrom(address from, uint256 value) public;
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  
}

contract owned {
        address public owner;

        constructor() public {
            owner = msg.sender;
        }

        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }

        function transferOwnership(address newOwner) onlyOwner public {
            owner = newOwner;
        }
}

contract tokenRewards is owned {
    using SafeMath for uint256;
    
    uint256 public rewardAmount;
    uint256 public holdersBonusAmount;
    token public tokenReward;
    uint256 public eligibleHoldingAmount;

    uint256 public maxBonusCount;
    uint256 public bonusSentCount;
    uint256 public maxRewardCount;
    uint256 public rewardSentCount;

    mapping(address => bool) public rewardTransferred;
	
	//event GoalReached(address recipient, uint totalAmountRaised);
    event RewardSent(address recipient, uint256 tokenAmount);

    /**
     * Constrctor function
    */
    constructor() public {
        
        //set config
        maxBonusCount = 50;
        maxRewardCount = 1000;
        rewardAmount = 500 * 1e18;
        holdersBonusAmount = 2000 * 1e18;
        eligibleHoldingAmount = 1000000 * 1e18;

        //add ERC20 token contract address
        tokenReward = token(0x60fe860E9006fB3f005AB005e87E5E4379F1cc90);
    }

    /**
     * claimRewards
     *
    */
    function claimRewards() external {
        require(!rewardTransferred[msg.sender]);
        
        if (tokenReward.balanceOf(msg.sender) >= eligibleHoldingAmount) {
            _sendBonus();
        } else {
            _sendRewards();
        }
    }

    function _sendRewards() internal {
        require(rewardSentCount <= maxRewardCount);
        rewardSentCount++;
        tokenReward.transfer(msg.sender, rewardAmount);
        emit RewardSent(msg.sender, rewardAmount);
        rewardTransferred[msg.sender] = true;
    }

    function _sendBonus() internal {
        require(bonusSentCount <= maxBonusCount);
        bonusSentCount++;
        tokenReward.transfer(msg.sender, holdersBonusAmount);
        emit RewardSent(msg.sender, holdersBonusAmount);
        rewardTransferred[msg.sender] = true;
    }
    

    /**
     *reward claimed or not
    */
    function getRewardStatus(address _wallet) public view returns (bool) {
        return rewardTransferred[_wallet];
    }

    /**
     *get config
    */
    function getConfig() public view returns (uint256 _maxBonusCount, uint256 _bonusSentCount, uint256 _maxRewardCount, uint256 _rewardSentCount, uint256 _rewardAmount, uint256 _holdersBonusAmount, uint256 _eligibleHoldingAmount) {
        return (
            maxBonusCount,
            bonusSentCount,
            maxRewardCount,
            rewardSentCount,
            rewardAmount,
            holdersBonusAmount,
            eligibleHoldingAmount
        );
    }

    /**
     *change config
    */
    function changeConfig(uint256 _maxBonusCount, uint256 _maxRewardCount, uint256 _rewardAmount, uint256 _holdersBonusAmount, uint256 _eligibleHoldingAmount) public onlyOwner {
        //set config
        maxBonusCount = _maxBonusCount;
        maxRewardCount = _maxRewardCount;
        rewardAmount = _rewardAmount;
        holdersBonusAmount = _holdersBonusAmount;
        eligibleHoldingAmount = _eligibleHoldingAmount;
    }
    
    /**
     *Change reward token
    */
    function changeRewardToken(address _tokenAddress) public onlyOwner {
          tokenReward = token(_tokenAddress);
    }

    /**
     *get tokens back
    */
    function emergencyGetTokensBack(address _tokenAddress, address _beneficiary, uint256 _amount) public onlyOwner {
        token(_tokenAddress).transfer(_beneficiary, _amount);
    }
    
    /**
     *withdraw funds
    */
    function emergencyWithdrawBnb(uint256 _amount) public onlyOwner {
		msg.sender.transfer(_amount);
    }
}
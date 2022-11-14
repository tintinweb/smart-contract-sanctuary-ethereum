// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

import './interfaces/ITokenikV1Rewards.sol';

contract TokenikV1Rewards is ITokenikV1Rewards{

    event ClaimAirdrop(
        address user,
        uint256 amount,
        address ref,
        uint256 refAmount
    );

    address public callerSetter;
    bool public addRewardPaused; //to be paused on Tokenik v2 launch
    bool public removeRewardPaused; //to be paused on Tokenik v2 launch
    bool public airdropEnabled; //false on contract launch
    uint256 public airdropAmount; //free airdrop amount
    uint256 public airdropRefBonus; //airdrop referral bonus
    uint256 public totalRewards; //total rewards supply
    uint256 public totalAirdropClaims; //number of individual addresses that claimed the airdrop
    uint256 public swapRewardPercentage; // 1 decimal, 10 is 1%

    mapping(address => uint256) public tradingRewards; //RNIK balance with 18 decimals
    mapping(address => bool) public approvedCallers; //approved callers list
    mapping(address => bool) public approvedTokens; //stable tokens approved to receive trading rewards
    mapping(address => bool) public claimedAirdrop; //track airdrop claims

    modifier onlySetter() {
        require(msg.sender == callerSetter, 'TokenikV1: FORBIDDEN');
        _;
    }

    modifier onlyCaller() {
        require(approvedCallers[msg.sender], 'TokenikV1: Forbidden');
        _;
    }

    constructor() {
        callerSetter = msg.sender;
        approvedCallers[msg.sender] = true;
        airdropAmount = 250 * 1e18; //250 RNIK
        airdropRefBonus = 50 * 1e18; //50 RNIK
        swapRewardPercentage = 10; //1%
    }


    function addReward(address _user, uint256 _amount) external override onlyCaller {
        
        if(!addRewardPaused){
            tradingRewards[_user] += _amount; 
            totalRewards += _amount; 
        }    
    }

    function addSwapReward(address _user, uint256 _amount, address _token) external override onlyCaller {
        //valid if pair is caller and token is approved
        
        if(!approvedTokens[_token]) return; //ensure the token is approved

        if(!addRewardPaused){
            uint256 rewardOffer = _amount * swapRewardPercentage / 1000;
            tradingRewards[_user] += rewardOffer; 
            totalRewards += rewardOffer; 
        }    
    }

    function addLiquidityReward(address _user, address _token0, address _token1, uint256 _amount0, uint256 _amount1) external override onlyCaller {
        //valid if pair is caller and token is approved

        if(addRewardPaused) return; //rewards is paused

        if(approvedTokens[_token0]){
                tradingRewards[_user] += _amount0; 
                totalRewards += _amount0; 
        } else{
            if(approvedTokens[_token1]){
                tradingRewards[_user] += _amount1; 
                totalRewards += _amount1;  
            }
        }
  
    }

    function removeReward(address _user, uint256 _amount) external override onlyCaller returns(bool) {
        
        if(!removeRewardPaused){
            //ensure the _amount is not greater than user balance
            if(_amount > tradingRewards[_user]){
                return false;
            }
            else{
                tradingRewards[_user] -= _amount;
                totalRewards -= _amount;
                return true;
            }
        }
        else{
            return false;
        }
    }

    function removeSwapReward(address _user, uint256 _amount, address _token) external override onlyCaller returns(bool) {
               
        if(removeRewardPaused) return false; //rewards is paused
        if(!approvedTokens[_token]) return false; //token is not approved

        if(_amount > tradingRewards[_user]){
                return false;
            }
            else{
                tradingRewards[_user] -= _amount;
                totalRewards -= _amount;
                return true;
            }
    }

    function claimAirdrop(address _ref) external override {
        require(airdropEnabled, 'TokenikV1: Airdrop is disabled.');
        require(!claimedAirdrop[msg.sender], 'TokenikV1: Already claimed airdrop.');

        claimedAirdrop[msg.sender] = true;
        totalAirdropClaims +=1;

        uint256 amountToClaim = airdropAmount;        

        if((_ref != address(0)) && (_ref != msg.sender)){
            amountToClaim +=airdropRefBonus;
            tradingRewards[msg.sender] += amountToClaim;
            tradingRewards[_ref] += airdropRefBonus;

            uint256 mintedRewards = amountToClaim + airdropRefBonus;
            totalRewards += mintedRewards;

            emit ClaimAirdrop(msg.sender, amountToClaim, _ref, airdropRefBonus);
        }
        else{
            tradingRewards[msg.sender] += amountToClaim;
            totalRewards += amountToClaim;

            emit ClaimAirdrop(msg.sender, amountToClaim, address(0), 0);
        }
    }

    //getter functions

    function getRewards(address _address) external view override returns(uint256){
        return tradingRewards[_address];
    }

    function getClaimedAirdrop(address _address) external view override returns(bool){
        return claimedAirdrop[_address];
    }

    function getApprovedCaller(address _address) override view external returns(bool){
        return approvedCallers[_address];
    }

    function getApprovedToken(address _address) external view override returns(bool){
        return approvedTokens[_address];
    }

    function getApprovedTokens(address _token0, address _token1) external view override returns(bool,bool){
        return (approvedTokens[_token0], approvedTokens[_token1]);
    }

    //setter functions

    function setCallerSetter(address _callerSetter) external override onlySetter{
        
        callerSetter = _callerSetter; //intentionally not checking against address(0) as callerSetter will be set to zero address once Tokenik v2 launches and rewards get paused
    }

    function setApprovedCaller(address _caller, bool _approved) external override onlySetter{
        
        approvedCallers[_caller] = _approved;
    }

    function setApprovedTokens(address _token, bool _approved) external override onlySetter{
        
        approvedTokens[_token] = _approved;
    }

    function setAddRewardPaused(bool  _paused) external override onlySetter{
        
        addRewardPaused = _paused;
    }

    function setRemoveRewardPaused(bool  _paused) external override onlySetter{
        
        removeRewardPaused = _paused;
    }

    function setAirdropAmounts(uint256 _amount, uint256 _refAmount) external override onlySetter{
        
        airdropAmount = _amount;
        airdropRefBonus = _refAmount;
    }

    function enableAirdrop(bool  _enabled) external override onlySetter{
        
        airdropEnabled = _enabled;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.8.0;

interface ITokenikV1Rewards {

    function addReward(address _user, uint256 _amount) external;
    function addSwapReward(address _user, uint256 _amount, address _token) external;
    function removeReward(address _user, uint256 _amount) external returns(bool);
    function claimAirdrop(address _ref) external;
    function getRewards(address _address) external view returns(uint256);
    function getClaimedAirdrop(address _address) external view returns(bool);
    function getApprovedCaller(address _address) external view returns(bool);
    function setCallerSetter(address _callerSetter) external;
    function setApprovedCaller(address _caller, bool _approved) external;
    function setAddRewardPaused(bool  _paused) external;
    function setRemoveRewardPaused(bool  _paused) external;
    function setAirdropAmounts(uint256 _amount, uint256 _refAmount) external;
    function enableAirdrop(bool  _enabled) external;
    function addLiquidityReward(address _user, address _token0, address _token1, uint256 _amount0, uint256 _amount1) external;
    function removeSwapReward(address _user, uint256 _amount, address _token) external returns(bool);
    function getApprovedToken(address _address) external view returns(bool);
    function getApprovedTokens(address _token0, address _token1) external view returns(bool,bool);
    function setApprovedTokens(address _token, bool _approved) external;
}
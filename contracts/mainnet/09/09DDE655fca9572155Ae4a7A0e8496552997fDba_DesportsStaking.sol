// dESPORTS Staking
// https://desports.lol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15; 


interface IERC20 { 
  function balanceOf(address account) external view returns (uint256); 
  function transfer(address recipient, uint256 amount) external returns (bool); 
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool); 
}


contract DesportsStaking { 

    mapping(address => uint256) public stakingBalance; 
    mapping(address => uint256) public yeildStartTime; 
    mapping(address => uint256) public parkedYeild; 
    mapping(address => uint256) public stakeStartTime; 
    mapping(address => bool) public isStaking; 
    IERC20 public desportsToken; 
    bool public canStake; 
    bool public canUnstake; 
    bool public canYeild; 
    bool public canReinvest;  

    enum State { stake, unstake, yeildwithdraw,reinvest}

    event StakeEvent(address indexed form,uint256 amount,uint256 timestamp,State indexed state); 

    
    uint256 public ownBalance; 
    uint256 public rate; 
    uint256 public lockTime; 
    address public owner; 
 
    constructor(IERC20 _desportsToken, uint256 _rate, uint256 _lockTime) { 
            desportsToken = _desportsToken; 
            owner = msg.sender; 
            rate = _rate; 
            lockTime = _lockTime; 
            canStake = true; 
            canUnstake = true; 
            canYeild = true; 
            canReinvest = true; 
        }


    modifier onlyOwner() { 
        require(msg.sender == owner, "Not owner"); 
        _; 
    }

    function updateRate(uint256 _newRate) onlyOwner public returns(bool){ 
        rate = _newRate; 
        return true; 
    }
    
    function updateLockTime(uint256 _newLockTime) onlyOwner public returns(bool){ 
        lockTime = _newLockTime; 
        return true; 
    }

    function transferOwnership(address _newOwner) onlyOwner public returns(bool){ 
        owner = _newOwner; 
        return true; 
    }

    function updateTradingState(bool _canStake,bool _canUnstake,bool _canYeild,bool _canReinvest) onlyOwner public returns(bool){ 
        canStake = _canStake; 
        canUnstake = _canUnstake; 
        canYeild = _canYeild; 
        canReinvest = _canReinvest; 
        return true; 
    }

    function emergency(uint256 _amount) onlyOwner public { 
        desportsToken.transfer(owner,_amount); 
    }

    function stake(uint256 _amount) public { 
        require(canStake,"function is disabled"); 
        require(_amount > 0,"You cannot stake zero tokens"); 
            
        if(isStaking[msg.sender] == true){ 
            parkedYeild[msg.sender] += calculateYieldTotal(msg.sender); 
        }

        desportsToken.transferFrom(msg.sender, address(this), _amount); 
        stakingBalance[msg.sender] += _amount; 
        ownBalance += _amount; 
        stakeStartTime[msg.sender] = block.timestamp; 
        yeildStartTime[msg.sender] = block.timestamp; 
        isStaking[msg.sender] = true; 
        emit StakeEvent(msg.sender, _amount,block.timestamp,State.stake); 
    }

    function unstake(uint256 _amount) public { 
        require(canUnstake,"function is disabled"); 
        require((stakeStartTime[msg.sender]+lockTime) < block.timestamp,"cannot unstake untill your time completes"); 
        require(
            isStaking[msg.sender] = true &&
            stakingBalance[msg.sender] >= _amount, 
            "Nothing to unstake"
        ); 
        stakeStartTime[msg.sender] = block.timestamp; 
        yeildStartTime[msg.sender] = block.timestamp; 
        stakingBalance[msg.sender] -= _amount; 
        desportsToken.transfer(msg.sender, _amount); 
        parkedYeild[msg.sender] += calculateYieldTotal(msg.sender); 
        ownBalance -= _amount; 
        if(stakingBalance[msg.sender] == 0){ 
            isStaking[msg.sender] = false; 
        }
        emit StakeEvent(msg.sender, _amount,block.timestamp,State.unstake); 
    }

    function calculateYieldTime(address _user) public view returns(uint256){ 
        uint256 end = block.timestamp; 
        uint256 totalTime = end - yeildStartTime[_user]; 
        return totalTime; 
    }

    function calculateYieldTotal(address _user) public view returns(uint256) { 
        uint256 time = calculateYieldTime(_user) * 10**18; 
        uint256 timeRate = time / rate; 
        uint256 rawYield = (stakingBalance[_user] * timeRate) / 10**18; 
        return rawYield; 
    }


    function reInvestRewards() public { 
        require(canReinvest,"function is disabled"); 
        uint256 toReinvest = calculateYieldTotal(msg.sender); 
                    
        if(parkedYeild[msg.sender] != 0){ 
            toReinvest += parkedYeild[msg.sender]; 
            parkedYeild[msg.sender] = 0; 
        }
        require(toReinvest>0,"Nothing to reinvest"); 

        stakingBalance[msg.sender] += toReinvest; 
        ownBalance += toReinvest; 
        stakeStartTime[msg.sender] = block.timestamp; 
        yeildStartTime[msg.sender] = block.timestamp; 
        isStaking[msg.sender] = true; 
        emit StakeEvent(msg.sender, toReinvest,block.timestamp,State.reinvest); 
    }

    function withdrawYield() public { 
        require(canYeild,"function is disabled"); 
        uint256 toTransfer = calculateYieldTotal(msg.sender); 
                    
        if(parkedYeild[msg.sender] != 0){ 
            toTransfer += parkedYeild[msg.sender]; 
            parkedYeild[msg.sender] = 0; 
        }
        require(toTransfer>0,"Nothing to yeild"); 
        require((desportsToken.balanceOf(address(this))-ownBalance)>=toTransfer,"Insufficient pool"); 
        yeildStartTime[msg.sender] = block.timestamp; 
        desportsToken.transfer(msg.sender, toTransfer); 
        emit StakeEvent(msg.sender, toTransfer,block.timestamp,State.yeildwithdraw); 
    } 
}
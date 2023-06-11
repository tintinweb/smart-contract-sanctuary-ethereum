/**
 *Submitted for verification at Etherscan.io on 2023-06-11
*/

/**
 *Submitted for verification at polygonscan.com on 2023-04-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IERC20 {
    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function _checkOwner() private view {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() external onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ReentrancyGuard {
    uint private constant _NOT_ENTERED = 1;
    uint private constant _ENTERED = 2;

    uint private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }

    function _reentrancyGuardEntered() private view returns (bool) {
        return _status == _ENTERED;
    }
}


contract Staking is Ownable, ReentrancyGuard {
    struct PoolInfo {
        uint lockupDuration;
        uint returnPer;
    }
    struct OrderInfo {
        address beneficiary;
        uint amount;
        uint lockupDuration;
        uint returnPer;
        uint starttime;
        uint endtime;
        uint claimedReward;
        bool claimed;
    }
     uint256 public _days30 =  21 days ; 
    uint256 public _days60 = 45 days ;
     uint256 public _days365 = 90 days ; 
   // IERC20 public token;
    bool private  started = true;
    uint public emergencyWithdrawFees = 0;
    uint private latestOrderId = 0;
    uint public totalStakers ; // use 
     uint public totalStaked ; // use 


    mapping(uint => PoolInfo) public pooldata;
    mapping(address => uint) public balanceOf;
    mapping(address => uint) public totalRewardEarn;
    mapping(uint => OrderInfo) public orders;
    mapping(address => uint[]) private orderIds;
    mapping(address => mapping(uint => bool))public hasStaked;
    mapping(uint => uint) public stakeOnPool;
    mapping(uint => uint) public rewardOnPool;
    mapping(uint => uint) public stakersPlan;
     


    event Deposit(address indexed user, uint indexed lockupDuration, uint amount, uint returnPer);
    event Withdraw(address indexed user, uint amount, uint reward, uint total);
    event WithdrawAll(address indexed user, uint amount);
    event RewardClaimed(address indexed user, uint reward);

    constructor() {
        // token = IERC20(_token);

        pooldata[30].lockupDuration = _days30; // 21 days
        pooldata[30].returnPer = 21;

        pooldata[60].lockupDuration = _days60; // 45 days
        pooldata[60].returnPer = 50;

        pooldata[90].lockupDuration = _days365; // 90 days
        pooldata[90].returnPer = 100;

    }

    function deposit(uint _lockupDuration) external payable {

        PoolInfo storage pool = pooldata[_lockupDuration];
        require(pool.lockupDuration > 0, "TokenStaking: asked pool does not exist");
        require(started, "TokenStaking: staking not yet started");
        require(msg.value > 0, "TokenStaking: stake amount must be non zero");

        orders[++latestOrderId] = OrderInfo( 
            _msgSender(),
            msg.value,
            pool.lockupDuration,
            pool.returnPer,
            block.timestamp,
            block.timestamp + pool.lockupDuration,
            0,
            false
        );

        
         if (!hasStaked[msg.sender][_lockupDuration]) {
             stakersPlan[_lockupDuration] = stakersPlan[_lockupDuration] + 1;
             totalStakers = totalStakers + 1 ;
        }

        //updating staking status
        
        hasStaked[msg.sender][_lockupDuration] = true;
        stakeOnPool[_lockupDuration] = stakeOnPool[_lockupDuration] + msg.value ;
        totalStaked = totalStaked + msg.value ;
        balanceOf[_msgSender()] += msg.value;
        orderIds[_msgSender()].push(latestOrderId); 
        emit Deposit(_msgSender(), pool.lockupDuration, msg.value, pool.returnPer);
    }

    function withdraw(uint orderId) external nonReentrant {
        require(orderId <= latestOrderId, "TokenStaking: INVALID orderId, orderId greater than latestOrderId");

        OrderInfo storage orderInfo = orders[orderId]; 
        require(_msgSender() == orderInfo.beneficiary, "TokenStaking: caller is not the beneficiary");
        require(!orderInfo.claimed, "TokenStaking: order already unstaked");
        require(block.timestamp >= orderInfo.endtime, "TokenStaking: stake locked until lock duration completion");

        uint claimAvailable = pendingRewards(orderId);
        uint total = orderInfo.amount + claimAvailable;

        totalRewardEarn[_msgSender()] += claimAvailable; 
        
        orderInfo.claimedReward += claimAvailable;
        balanceOf[_msgSender()] -= orderInfo.amount; 
        orderInfo.claimed = true;
        payable(_msgSender()).transfer(total);
       rewardOnPool[orderInfo.lockupDuration] = rewardOnPool[orderInfo.lockupDuration] + claimAvailable ;
        emit Withdraw(_msgSender(), orderInfo.amount, claimAvailable, total);
    }

    function emergencyWithdraw(uint orderId) external nonReentrant {
        require(orderId <= latestOrderId, "TokenStaking: INVALID orderId, orderId greater than latestOrderId");

        OrderInfo storage orderInfo = orders[orderId]; 
        require(_msgSender() == orderInfo.beneficiary, "TokenStaking: caller is not the beneficiary");
        require(!orderInfo.claimed, "TokenStaking: order already unstaked");

        uint claimAvailable = pendingRewards(orderId);
        uint fees = (orderInfo.amount * emergencyWithdrawFees) / 100; 
        orderInfo.amount -= fees; 
        uint total = orderInfo.amount + claimAvailable;

        totalRewardEarn[_msgSender()] += claimAvailable; 
    
        orderInfo.claimedReward += claimAvailable;


        balanceOf[_msgSender()] -= (orderInfo.amount + fees); 
      
        orderInfo.claimed = true;
         payable(_msgSender()).transfer(total);
        rewardOnPool[orderInfo.lockupDuration] = rewardOnPool[orderInfo.lockupDuration] + claimAvailable ;
        emit WithdrawAll(_msgSender(), total);
    }

   
    function claimRewards(uint orderId) external nonReentrant {
        require(orderId <= latestOrderId, "TokenStaking: INVALID orderId, orderId greater than latestOrderId");

        OrderInfo storage orderInfo = orders[orderId];
        require(_msgSender() == orderInfo.beneficiary, "TokenStaking: caller is not the beneficiary");
        require(!orderInfo.claimed, "TokenStaking: order already unstaked");

        uint claimAvailable = pendingRewards(orderId);
        totalRewardEarn[_msgSender()] += claimAvailable;
       
        orderInfo.claimedReward += claimAvailable;
          payable(_msgSender()).transfer(claimAvailable);
        rewardOnPool[orderInfo.lockupDuration] = rewardOnPool[orderInfo.lockupDuration] + claimAvailable ;
        emit RewardClaimed(address(_msgSender()), claimAvailable);
    }

    function pendingRewards(uint orderId) public view returns (uint) {
        require(orderId <= latestOrderId, "TokenStaking: INVALID orderId, orderId greater than latestOrderId");

        OrderInfo storage orderInfo = orders[orderId];
        if (!orderInfo.claimed) {
            if (block.timestamp >= orderInfo.endtime) {
                uint APY = (orderInfo.amount * orderInfo.returnPer) / 100;
                uint reward = (APY * orderInfo.lockupDuration) / _days365;
                uint claimAvailable = reward - orderInfo.claimedReward;
                return claimAvailable;
            } else {
                uint stakeTime = block.timestamp - orderInfo.starttime;
                uint APY = (orderInfo.amount * orderInfo.returnPer) / 100;
                uint reward = (APY * stakeTime) / _days365;
                uint claimAvailableNow = reward - orderInfo.claimedReward;
                return claimAvailableNow;
            }
        } else {
            return 0;
        }
    }

    function toggleStaking(bool _start) external onlyOwner returns (bool) {
        started = _start;
        return true;
    }

    function investorOrderIds(address investor) external view returns (uint[] memory ids)
    {
        uint[] memory arr = orderIds[investor];
        return arr;
    }



    receive() external payable {}

     // transfer any ETH
    function transferEther(address payable recipient, uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than zero");
        require(address(this).balance >= amount, "Insufficient balance in the contract");
        recipient.transfer(amount);
    } 

    
}
/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeMath {
  
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


interface IERC20 {
  
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

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
}


contract BSNStaking is ReentrancyGuard, Ownable {

    using SafeMath for uint256;

    IERC20 public token;
    // address public deductionReciever;
    bool public paused;

    address public rewardPool;
    address public securityWallet;
    address public MarketingWallet;

    //days to percentage
    /*
        A) 1-5 (25%}
        B) 6-10 days (20%)
        C) 11-15 days (15%)
        D) 16-20 days (10%)
        E) 21-25 days (5%)
        F) 26-30 days (3%)
        G) more than 30 days (2%)
    */
    uint tokendecimal = 18;

    uint public minStakeAmount = 100 * 10 ** tokendecimal;
    uint public maxStakeAmount = 100000 * 10 ** tokendecimal;
    
    uint public generationTime =  3 days;

    uint public totalStakedSoFar;
    uint public totalUnstakedSoFar;

    mapping(uint256 => mapping (uint256 => uint256)) public RewardSlots;
    mapping(uint256 => mapping (uint256 => uint256)) public RewardAmountSlots;

    mapping(uint256 => mapping (uint256 => uint256)) public timeslots;
   
    mapping(uint256 => mapping (uint256 => uint256)) public slotAmount;

    struct database {
        uint256 userindex;
        uint256 usertimeslotIndexs;  //incrementable start from 
        // uint256 totalStaked;
        // uint256 totalUnstaked;
        uint256 stakeStart;
        uint256 userExists;
    }

    mapping(address => database) public record;
    mapping(address => uint256) public userStakedAmount;
	mapping(address => uint256) public userUnstakedAmount;

    mapping(address => uint256) public userTotalDeduction;
    mapping(address => uint256) public userTotalRecievable;

    mapping(address => uint256) public lastClaim;
    mapping(address => uint256) public dueReward;

    uint256 public totalStakers;
    bool public enableChecker = true;

    constructor(address _token,
                address _RewardWallet,
                address _securityWallet,
                address _marketingWallet
    ) {
        token = IERC20(_token);
        // deductionReciever = _deductionWallet;

        rewardPool = _RewardWallet;
        securityWallet = _securityWallet;
        MarketingWallet = _marketingWallet;
    }

    function stake(uint _amount) public nonReentrant() { 

        require(!paused,"We are Closed due to some reasons!! Will back soon :");

        require(_amount >= minStakeAmount && _amount <= maxStakeAmount,"Error: Value Exceed from Limit!");

        token.transferFrom(msg.sender,address(this),_amount);

        totalStakedSoFar+=_amount;

        store(msg.sender,block.timestamp,_amount,1);
    }

    function store(address _user, uint256 time, uint _amount , uint _pid) internal {

        if(record[_user].userExists == 1){
            record[_user].usertimeslotIndexs++;
        }
        
        if(record[_user].userExists != 1) {
            totalStakers++;
            record[_user].userindex = totalStakers;
            record[_user].userExists = 1;
            record[_user].usertimeslotIndexs = 1;
            record[_user].stakeStart = block.timestamp;
        }

        if(record[_user].stakeStart == 0) {
            record[_user].stakeStart = block.timestamp;
        }

        // record[_user].totalStaked += _amount;
        if(_pid == 1) {
            userStakedAmount[_user] += _amount;
        }

        timeslots[record[_user].userindex][record[_user].usertimeslotIndexs] = time;

        // RewardSot[record[_user].userindex][record[_user].usertimeslotIndexs] = time;
        
        slotAmount[record[_user].userindex][timeslots[record[_user].userindex][record[_user].usertimeslotIndexs]] = _amount;

        RewardSlots[record[_user].userindex][_amount] =  time;

        RewardAmountSlots[record[_user].userindex][time] = _amount;
        
    }

    function calapy(uint _amount) internal pure returns (uint){
        uint num = _amount.mul(15).div(10e2);
        return num.div(31536000);
    }

    function calreward(uint _time) internal view returns (uint) {
        if(_time == 0) return 0;
        uint sec = block.timestamp.sub(_time);
        return sec;
    }

    function unstake(uint256 _amount) public nonReentrant() {

        require(!paused,"We are Closed due to some reasons!! Will back soon :");

        // require(record[msg.sender].stakeStart + generationTime <= block.timestamp,"you can Only unstake after 72hrs.  Try again after 72hrs has elapsed!!!");

        address account = msg.sender;
        uint currentTime = block.timestamp;   //block.timestamp;

        uint userslot = record[account].userindex;
        uint totalTimeslots = record[account].usertimeslotIndexs; 

        require(userStakedAmount[account] > 0,"You have Zero Amount to Release!!");

        if(enableChecker) {
            uint value = unStakable(account);
            if(value == 0) {
                revert("you can Only unstake after 72hrs.  Try again after 72hrs has elapsed!!!");
            }
            else if(_amount > value) {
                revert("you can Only unstake after 72hrs.  Try again after 72hrs has elapsed!!!");
            }
        }

        uint totalAmount;
        uint totalDeduction;
        uint AmountwithApy;

        for(uint i = 1; i <= totalTimeslots; i++) {

            uint _slottime = timeslots[userslot][i];
            uint _runningAmount = slotAmount[userslot][_slottime];

            uint _RewardAmount = RewardAmountSlots[userslot][_slottime];
            uint _updateRewardTime = RewardSlots[userslot][_RewardAmount];

            if(_runningAmount ==0 ) continue;

            if(_slottime + 5 days > currentTime){   //1-5 days (25%}
                totalAmount += _runningAmount;
                totalDeduction += _runningAmount.mul(45).div(100);

                uint sec = calreward(_updateRewardTime);
                uint factor = calapy(_runningAmount);
                AmountwithApy += sec.mul(factor);

                slotAmount[userslot][_slottime] = 0;
                RewardAmountSlots[userslot][_slottime] = 0;
                // RewardAmountSlots[userslot][_slottime] = 0;
             
            }

            else if(_slottime + 10 days > currentTime){   //6-10 days (20%)
                totalAmount += _runningAmount;
                totalDeduction += _runningAmount.mul(40).div(100);

                uint sec = calreward(_updateRewardTime);
                uint factor = calapy(_runningAmount);
                AmountwithApy += sec.mul(factor);
                
                slotAmount[userslot][_slottime] = 0;
                RewardAmountSlots[userslot][_slottime] = 0;
                
            }

            else if(_slottime + 15 days > currentTime){   //11-15 days (15%)
                totalAmount += _runningAmount;
                totalDeduction += _runningAmount.mul(35).div(100);

                uint sec = calreward(_updateRewardTime);
                uint factor = calapy(_runningAmount);
                AmountwithApy += sec.mul(factor);
                
                slotAmount[userslot][_slottime] = 0;
                RewardAmountSlots[userslot][_slottime] = 0;
            }

            else if(_slottime + 20 days > currentTime){   //16-20 days (10%)
                totalAmount += _runningAmount;
                totalDeduction += _runningAmount.mul(30).div(100);
                
                uint sec = calreward(_updateRewardTime);
                uint factor = calapy(_runningAmount);
                AmountwithApy += sec.mul(factor);
                
                slotAmount[userslot][_slottime] = 0;
                RewardAmountSlots[userslot][_slottime] = 0;
            }

            else if(_slottime + 25 days > currentTime){   //21-25 days (5%)
                totalAmount += _runningAmount;
                totalDeduction += _runningAmount.mul(25).div(100);


                uint sec = calreward(_updateRewardTime);
                uint factor = calapy(_runningAmount);
                AmountwithApy += sec.mul(factor);
                
                slotAmount[userslot][_slottime] = 0;
                RewardAmountSlots[userslot][_slottime] = 0;
             
            }
            
            else if(_slottime + 30 days > currentTime){   //26-30 days (3%)
                totalAmount += _runningAmount;
                totalDeduction += _runningAmount.mul(20).div(100);
                
                uint sec = calreward(_updateRewardTime);
                uint factor = calapy(_runningAmount);
                AmountwithApy += sec.mul(factor);
                
                slotAmount[userslot][_slottime] = 0;
                RewardAmountSlots[userslot][_slottime] = 0;
                
            }

            else {  // >30 days (2%)
                totalAmount += _runningAmount;
                totalDeduction += _runningAmount.mul(15).div(100);

                uint sec = calreward(_updateRewardTime);
                uint factor = calapy(_runningAmount);
                AmountwithApy += sec.mul(factor);
                
                slotAmount[userslot][_slottime] = 0;
                RewardAmountSlots[userslot][_slottime] = 0;
            }

            if(totalAmount > _amount) {
                uint256 extra = totalAmount.sub(_amount);
                store(account,block.timestamp,extra,0);

                totalAmount = _amount;
                break;
            }
            else if (totalAmount < _amount) {
                if(i == totalTimeslots) {
                    revert ("Invalid Input");
                }
            }
            else {
                break;
            }

        }
   
        require(totalAmount > 0,"Error: 404!");

        dueReward[account] += AmountwithApy;

        uint256 afterDeduction = totalAmount.sub(totalDeduction);

        userTotalDeduction[account] += totalDeduction;
        userTotalRecievable[account] += afterDeduction;

        totalStakedSoFar -= totalAmount;
        totalUnstakedSoFar += totalAmount;
        userStakedAmount[account] -= totalAmount;
		userUnstakedAmount[account] += totalAmount;


        if(userStakedAmount[account] == 0) {
            removeStaker(msg.sender);
        }

    }

    function withdraw() public {

        require(!paused,"We are Closed due to some reasons!! Will back soon :");

        require(record[msg.sender].stakeStart + generationTime <= block.timestamp,"you can Only unstake after 72hrs.  Try again after 72hrs has elapsed!!");

        address account = msg.sender;

        uint256 totalDeduction = userTotalDeduction[account];
        uint256 SubTotal = userTotalRecievable[account];
        uint256 additional =  dueReward[account];

        SubTotal = SubTotal + additional;

        uint sPool = totalDeduction.mul(70).div(100);
        uint Security = totalDeduction.mul(15).div(100);
        uint Marketing = totalDeduction.mul(15).div(100);

        token.transfer(rewardPool,sPool);
        token.transfer(securityWallet,Security);
        token.transfer(MarketingWallet,Marketing);

        userTotalDeduction[account] = 0;
        userTotalRecievable[account] = 0;
        dueReward[account] = 0;

        token.transfer(account,SubTotal);


    }


    function unStakable(address _adr) public view returns (uint) {

        address account = _adr;

        uint userslot = record[account].userindex;
        uint totalTimeslots = record[account].usertimeslotIndexs; 

        // require(userStakedAmount[account] > 0,"You have Zero Amount to Release!!");

        uint unstakable;
        if(true) {

            for(uint index = 1; index <= totalTimeslots; index++) {

                uint _slottime = timeslots[userslot][index];
                uint _runningAmount = slotAmount[userslot][_slottime];

                if(_runningAmount == 0) continue;

                if(_slottime + generationTime <= block.timestamp) {
                    unstakable += _runningAmount;
                }

            }
        }        

        return unstakable;

    }

    function claimReward() public nonReentrant() {

        address account = msg.sender;

        require(!paused,"We are Closed due to some reasons!! Will back soon :");

        uint userslot = record[account].userindex;
        uint totalTimeslots = record[account].usertimeslotIndexs; 

        uint AmountwithApy;

        for(uint i = 1; i <= totalTimeslots; i++) {

            uint _slottime = timeslots[userslot][i];
            uint _runningAmount = RewardAmountSlots[userslot][_slottime];
            uint _updateRewardTime = RewardSlots[userslot][_runningAmount];

            uint sec = calreward(_updateRewardTime);
            uint factor = calapy(_runningAmount);
            AmountwithApy += sec.mul(factor);
            if(_updateRewardTime != 0) {
                RewardSlots[userslot][_runningAmount] = block.timestamp;
            }
            
        }

        uint extra = dueReward[account];
        uint subtotal = AmountwithApy + extra;

        token.transfer(account,subtotal);

        lastClaim[account] = block.timestamp;
        dueReward[account] = 0;

    }

    function seeReward(address account) public view returns(uint){

        uint userslot = record[account].userindex;
        uint totalTimeslots = record[account].usertimeslotIndexs; 

        uint AmountwithApy;

        for(uint i = 1; i <= totalTimeslots; i++) {

            uint _slottime = timeslots[userslot][i];
            uint _runningAmount = RewardAmountSlots[userslot][_slottime];
            uint _updateRewardTime = RewardSlots[userslot][_runningAmount];

            uint sec = calreward(_updateRewardTime);
            uint factor = calapy(_runningAmount);
            AmountwithApy += sec.mul(factor);
                
        }

        return AmountwithApy + dueReward[account];

    } 

    function removeStaker(address _user) internal {
        record[_user].usertimeslotIndexs = 0;
        // record[_user].totalStaked = 0;
        record[_user].stakeStart = 0;
        // record[_user].totalUnstaked += _token;
    }

    //donot change if the contract is working
    function setToken(address _adr) public onlyOwner {
        token = IERC20(_adr);
    }

    function setTokenDecimal(uint _dec) public onlyOwner {
        tokendecimal = _dec;
    }

    function emergencyPause(bool _status) public onlyOwner {
        paused = _status;
    }

    function setUnstakeTimeI(uint _time) public onlyOwner {
        generationTime = _time;
    }

    function setChecker(bool _status) public onlyOwner {
        enableChecker = _status;
    }

    function rescueToken(address _erc20,address recipient,uint _amount) public onlyOwner {
        IERC20(_erc20).transfer(recipient,_amount);
    }

    function rescueFunds() public onlyOwner {
        (bool os,) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function setWallet(address _pool,address _Security, address _market) public onlyOwner {
        rewardPool = _pool;
        securityWallet = _Security;
        MarketingWallet = _market;
    }

}
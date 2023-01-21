/**
 *Submitted for verification at Etherscan.io on 2023-01-21
*/

/**
 *Submitted for verification at Etherscan.io on 2023-01-20
*/

/*
 __  ___      ___      .__   __.   _______      
|  |/  /     /   \     |  \ |  |  /  _____|     
|  '  /     /  ^  \    |   \|  | |  |  __       
|    <     /  /_\  \   |  . `  | |  | |_ |      
|  .  \   /  _____  \  |  |\   | |  |__| |      
|__|\__\ /__/     \__\ |__| \__|  \______|      
                                                
 __  ___      ___       __                      
|  |/  /     /   \     |  |                     
|  '  /     /  ^  \    |  |                     
|    <     /  /_\  \   |  |                     
|  .  \   /  _____  \  |  |                
|__|\__\ /__/     \__\ |__|                     
                                                
.___  ___.  __  .__   __.  _______ .______      
|   \/   | |  | |  \ |  | |   ____||   _  \     
|  \  /  | |  | |   \|  | |  |__   |  |_)  |    
|  |\/|  | |  | |  . `  | |   __|  |      /     
|  |  |  | |  | |  |\   | |  |____ |  |\  \----.
|__|  |__| |__| |__| \__| |_______|| _| `._____|
                                                
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IBEP20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external;

    function transfer(address to, uint256 value) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor(address payable owner_) {
        _owner = owner_;
        emit OwnershipTransferred(address(0), owner_);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract KangKaiMiner is Ownable {
    address public managerFeeWallet;
    address public devFeeWallet;
    address public marketingFeeWallet;
    address public ceoFeeWallet;
    address public communityFeeWallet;
    address public kangkaiFeeWallet;
    // IBEP20 public busd = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); // Main
    IBEP20 public busd = IBEP20(0xD7573fc24632F78Fc16817Fa6Bea2967e5006511); // Test

    uint256 public totalDeposits;
    uint256 public totalCompound;
    uint256 public totalWithdrawan;
    uint256 public totalRefRewards;
    uint256 public uniqueStakers;
    uint256 public lotteryPool;
    uint256 public currentWeek;
    uint256 public launchTime;
    bool public launched;

    uint256 public depositFeePercent = 4_00;
    uint256 public withdrawFeePercent = 4_00;
    uint256 public lotteryFeePercent = 1_00;
    uint256 public lotteryPercent = 25_00;
    uint256 public referrerPercent = 1_50;
    uint256 public referralPercent = 1_50;
    uint256 public managerFeePercent = 75_00;
    uint256 public devFeePercent = 75_00;
    uint256 public marketingFeePercent = 5_00;
    uint256 public ceoFeePercent = 5_00;
    uint256 public communityFeePercent = 5_00;
    uint256 public kangkaiFeePercent = 1_00;
    uint256 public percentDivider = 100_00;

    uint256 public minDeposit = 50e18;
    uint256 public maxDeposit = 50_000e18;
    uint256 public maxWithdrawl = 10_000e18;
    uint256 public dailyRewardPercent = 3_00;
    uint256 public maxRewardPercent = 300_00;
    uint256 public timeStep = 10 minutes;
    uint256 public withdrawDuration = 70 minutes;
    uint256 public accumulationDuration = 100 minutes;

    struct User {
        bool isExists;
        uint256 depositAmount;
        uint256 currentAmount;
        address referrer;
        uint256 referrals;
        uint256 referralRewards;
        uint256 startTime;
        uint256 checkpoint;
        uint256 totalDeposits;
        uint256 totalCompound;
        uint256 totalWithdrawan;
        uint256 pendingRewards;
    }

    mapping(address => User) public users;
    mapping(uint256 => address[]) public currentWeekUsers;
    mapping(uint256 => mapping(address => bool)) public isInvested;

    event DEPOSIT(address user, uint256 amount);
    event COMPOUND(address user, uint256 amount);
    event WITHDRAW(address user, uint256 amount);
    event LOTTERY(address winner, uint256 amount);

    constructor(address payable _owner) Ownable(_owner) {}

    function launch() external onlyOwner {
        require(!launched, "Already launched");
        launched = true;
        launchTime = block.timestamp;
    }

    function calculateWeek() public view returns (uint256) {
        return (block.timestamp - launchTime) / (7 * timeStep);
    }

    function updateWeekly() public {
        if (currentWeek != calculateWeek()) {
            currentWeek = calculateWeek();
            checkForLotteryWinner();
        }
    }

    function deposit(address _referrer, uint256 _amount) public {
        updateWeekly();
        User storage user = users[msg.sender];
        require(_amount >= minDeposit, "Below minimum limit");
        require(
            user.depositAmount + _amount <= maxDeposit,
            "Exceeds maximum limit"
        );

        if (!user.isExists) {
            user.isExists = true;
            user.startTime = block.timestamp;
            uniqueStakers++;
        }
        busd.transferFrom(msg.sender, address(this), _amount);

        uint256 feeAmount = (_amount * depositFeePercent) / percentDivider;
        takeFee(feeAmount);
        lotteryPool += (_amount * lotteryFeePercent) / percentDivider;

        uint256 preReward;
        preReward = calculateReward(msg.sender);
        setDepositData(msg.sender, _amount, preReward);
        setReferrer(msg.sender, _referrer, _amount);

        if(!isInvested[currentWeek][msg.sender]){
            isInvested[currentWeek][msg.sender] = true;
            currentWeekUsers[currentWeek].push(msg.sender);
        }

        emit DEPOSIT(msg.sender, _amount);
    }

    function setReferrer(
        address _user,
        address _referrer,
        uint256 _amount
    ) private {
        User storage user = users[_user];

        if (user.referrer == address(0) && _user != owner()) {
            if (_referrer != _user) {
                user.referrer = _referrer;
            }
        }

        if (user.referrer != address(0)) {
            users[user.referrer].referrals++;
            uint256 userRewards = (_amount * referralPercent) / percentDivider;
            uint256 refRewards = (_amount * referrerPercent) / percentDivider;
            user.referralRewards += userRewards;
            users[user.referrer].referralRewards += refRewards;
        }
    }

    function compound() public {
        updateWeekly();
        User storage user = users[msg.sender];
        require(user.isExists, "No deposit found");
        require(
            block.timestamp > user.checkpoint + withdrawDuration,
            "Wait for next withdraw time"
        );
        uint256 preReward;
        preReward = calculateReward(msg.sender);
        if (preReward > 0) {
            setDepositData(msg.sender, 0, preReward);
        }

        emit COMPOUND(msg.sender, preReward);
    }

    function withdraw(uint256 _claimPercent) public {
        updateWeekly();
        User storage user = users[msg.sender];
        require(user.isExists, "No deposit found");
        require(
            block.timestamp > user.checkpoint + withdrawDuration,
            "Wait for next withdraw time"
        );
        uint256 preReward;
        uint256 refReward = user.referralRewards;
        preReward = calculateReward(msg.sender);
        preReward += user.pendingRewards;
        require(preReward + refReward > 0, "no reward yet");
        if(preReward > maxWithdrawl){
            user.pendingRewards += (preReward - maxWithdrawl);
            preReward = maxWithdrawl;
        }

        uint256 forClaim = (preReward * _claimPercent) / percentDivider;
        busd.transfer(msg.sender, (forClaim + refReward));
        totalRefRewards += refReward;
        user.referralRewards = 0;

        uint256 feeAmount = (forClaim * withdrawFeePercent) / percentDivider;
        takeFee(feeAmount);

        uint256 forCompound = preReward - forClaim;
        if (forCompound > 0) {
            setDepositData(msg.sender, 0, forCompound);
            emit COMPOUND(msg.sender, forCompound);
        } else {
            user.checkpoint = block.timestamp;
        }

        user.totalWithdrawan += forClaim;
        totalWithdrawan += forClaim;

        emit WITHDRAW(msg.sender, forClaim + refReward);
    }

    function setDepositData(
        address _user,
        uint256 _amount,
        uint256 _reward
    ) private {
        User storage user = users[_user];
        user.depositAmount += _amount;
        user.currentAmount += (_amount + _reward);
        user.checkpoint = block.timestamp;
        user.totalCompound += _reward;
        totalCompound += _reward;
        user.totalDeposits += _amount;
        totalDeposits += _amount;
    }

    function takeFee(uint256 _feeAmount) private {
        uint256 managerFeeAmount = (_feeAmount * managerFeePercent) /
            percentDivider;
        busd.transfer(managerFeeWallet, managerFeeAmount);

        uint256 devFeeAmount = (_feeAmount * devFeePercent) / percentDivider;
        busd.transfer(devFeeWallet, devFeeAmount);

        uint256 marketingFeeAmount = (_feeAmount * marketingFeePercent) /
            percentDivider;
        busd.transfer(marketingFeeWallet, marketingFeeAmount);

        uint256 ceoFeeAmount = (_feeAmount * ceoFeePercent) / percentDivider;
        busd.transfer(ceoFeeWallet, ceoFeeAmount);

        uint256 communityFeeAmount = (_feeAmount * communityFeePercent) /
            percentDivider;
        busd.transfer(communityFeeWallet, communityFeeAmount);

        uint256 kangkaiFeeAmount = (_feeAmount * kangkaiFeePercent) /
            percentDivider;
        busd.transfer(kangkaiFeeWallet, kangkaiFeeAmount);
    }

    function checkForLotteryWinner() private {
            uint256 lotterymount = (lotteryPool * lotteryPercent) / percentDivider;
            lotteryPool = lotterymount;
            uint256 totalUsers = currentWeekUsers[currentWeek].length;
            address winner1;
            address winner2;
            address winner3;
            if(totalUsers > 0){
                winner1 = currentWeekUsers[currentWeek][random(0, totalUsers, 1)];
                busd.transfer(winner1, lotterymount);
                emit LOTTERY(winner1, lotterymount);
            }
            if(totalUsers > 1){
                winner2 = currentWeekUsers[currentWeek][random(0, totalUsers, 2)];
                busd.transfer(winner2, lotterymount);
                emit LOTTERY(winner2, lotterymount);
            }
            if(totalUsers > 2){
                winner3 = currentWeekUsers[currentWeek][random(0, totalUsers, 3)];
                busd.transfer(winner3, lotterymount);
                emit LOTTERY(winner3, lotterymount);
            }            
    }

    function calculateReward(address _user) public view returns (uint256) {
        User storage user = users[_user];
        uint256 rewardDuration = block.timestamp - user.checkpoint;
        if (rewardDuration > accumulationDuration) {
            rewardDuration = accumulationDuration;
        }
        uint256 reward = (user.currentAmount *
            rewardDuration *
            dailyRewardPercent) / (percentDivider * timeStep);
        uint256 maxClaimable = (user.currentAmount * maxRewardPercent) /
            percentDivider;
        uint256 remaining = maxClaimable - user.totalWithdrawan;
        if (reward > remaining) {
            reward = remaining;
        }
        return reward;
    }

    function getContractBalance() public view returns(uint256) {
        return busd.balanceOf(address(this));
    }

    function random(uint256 from, uint256 to, uint256 salty) public view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp + block.difficulty +
                    ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
                    block.gaslimit +
                    ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
                    block.number +
                    salty
                )
            )
        );
        return seed % (to - from);
    }

    function getUserInfo(address _user)
        public
        view
        returns (
            bool _isExists,
            uint256 _depositAmount,
            uint256 _currentAmount,
            uint256 _startTime,
            uint256 _checkpoint,
            uint256 _totalDeposits,
            uint256 _totalCompound,
            uint256 _totalWithdrawan,
            uint256 _pendingRewards
        )
    {
        User storage user = users[_user];
        _isExists = user.isExists;
        _depositAmount = user.depositAmount;
        _currentAmount = user.currentAmount;
        _startTime = user.startTime;
        _checkpoint = user.checkpoint;
        _totalDeposits = user.totalDeposits;
        _totalCompound = user.totalCompound;
        _totalWithdrawan = user.totalWithdrawan;
        _pendingRewards = user.pendingRewards;
    }

    function SetFeeWallets(address _wallet1, address _wallet2, address _wallet3, address _wallet4, address _wallet5, address _wallet6) external onlyOwner {
        managerFeeWallet = _wallet1;
        devFeeWallet = _wallet2;
        marketingFeeWallet = _wallet3;
        ceoFeeWallet = _wallet4;
        communityFeeWallet = _wallet5;
        kangkaiFeeWallet = _wallet6;
    }

    function SetLimits(uint256 _min, uint256 _max) external onlyOwner {
        minDeposit = _min;
        maxDeposit = _max;
    }

    function SetDurations(uint256 _claim, uint256 _accumulation)
        external
        onlyOwner
    {
        withdrawDuration = _claim;
        accumulationDuration = _accumulation;
    }

    function SetTime(uint256 _duration, uint256 _week)
        external
        onlyOwner
    {
        timeStep = _duration;
        currentWeek = _week;
    }
}
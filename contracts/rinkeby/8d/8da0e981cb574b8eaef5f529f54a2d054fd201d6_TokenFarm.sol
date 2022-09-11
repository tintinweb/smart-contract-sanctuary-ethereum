/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

/**
 *Submitted for verification at snowtrace.io on 2022-08-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a), 'mul overflow');
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);

        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a),
            'sub overflow');
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a),
            'add overflow');
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256,
            'abs overflow');
        return a < 0 ? -a : a;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
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
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0,
            'parameter 2 can not be 0');
        return a % b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);
    event TransferOwnerShip(address indexed previousOwner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, 'Not owner');
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit TransferOwnerShip(newOwner);
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0),
            'Owner can not be 0');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract TokenFarm is Ownable {

    using SafeMath for uint256;
    using SafeMathInt for int256;

    struct UserInfo {
        uint256 amount;     // How many tokens the user has provided.
        uint256 stakingTime; // The time at which the user staked tokens.
    }

    struct PoolInfo {
        address tokenAddress;
        uint256 maxPoolSize; 
        uint256 currentPoolSize;
        uint256 maxContribution;
        uint256 reward; // the final reward precentage is caluculated by reward/1000
        uint256 emergencyFees; // it is the fees in percentage, final fees is emergencyFees/1000
        uint256 lockDays;
        bool poolType; // true for public staking, false for whitelist staking
        bool poolActive;
    }

    // Info of each pool.
    PoolInfo[] public poolInfo;
    bool lock_= false;


    // Info of each user that stakes tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    mapping (uint256 => mapping (address => bool)) public whitelistedAddress;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);


    constructor () {
        
    }


    modifier lock {
        require(!lock_, "Process is locked");
        lock_ = true;
        _;
        lock_ = false;
    }

    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    function addPool (address _tokenAddress, uint256 _maxPoolSize, uint256 _maxContribution, uint256 _reward, uint256 _emergencyFees, uint256 _lockDays, bool _poolType, bool _poolActive) public onlyOwner {
        poolInfo.push(PoolInfo({
            tokenAddress: _tokenAddress,
            maxPoolSize: _maxPoolSize,
            currentPoolSize: 0,
            maxContribution: _maxContribution,
            reward: _reward,
            emergencyFees: _emergencyFees,
            lockDays: _lockDays,
            poolType: _poolType,
            poolActive: _poolActive
        }));
    }

    function updateMaxPoolSize (uint256 _pid, uint256 _maxPoolSize) public onlyOwner{
        require (_pid < poolLength(), "Invalid pool ID");
        require (_maxPoolSize < poolInfo[_pid].currentPoolSize, "Cannot reduce the max size below the current pool size");
        poolInfo[_pid].maxPoolSize = _maxPoolSize;
    }

    function updateMaxContribution (uint256 _pid, uint256 _maxContribution) public onlyOwner{
        require (_pid < poolLength(), "Invalid pool ID");
        poolInfo[_pid].maxContribution = _maxContribution;
    }

    function updateReward (uint256 _pid, uint256 _reward) public onlyOwner {
        require (_pid < poolLength(), "Invalid pool ID");
        require (_reward > 0, "Invalid reward");
        if (poolInfo[_pid].currentPoolSize > 0)
            require (_reward > poolInfo[_pid].reward, "You can't decrease the reward when people started staking");
        poolInfo[_pid].reward = _reward;
    }

    function updateLockDays (uint256 _pid, uint256 _lockDays) public onlyOwner {
        require (_pid < poolLength(), "Invalid pool ID");
        require (poolInfo[_pid].currentPoolSize == 0, "Cannot change lock time after people started staking");
        poolInfo[_pid].lockDays = _lockDays;
    }

    // this function is to withdraw extra tokens locked in the contract.
    function withdrawLockedTokens (address _tokenAddress) external onlyOwner returns (bool) {
        IBEP20 token = IBEP20 (_tokenAddress);
        uint256 balance = token.balanceOf(address(this));

        bool success = token.transfer(msg.sender, balance);
        return success;
    }

    function updatePoolType (uint256 _pid, bool _poolType) public onlyOwner {
        require (_pid < poolLength(), "Invalid pool ID");
        poolInfo[_pid].poolType = _poolType;
    }

    function updatePoolActive (uint256 _pid, bool _poolActive) public onlyOwner {
        require (_pid < poolLength(), "Invalid pool ID");
        poolInfo[_pid].poolActive = _poolActive;
    }

    function addWhitelist (uint256 _pid, address [] memory _whitelistAddresses) public onlyOwner {
        require (_pid < poolLength(), "Invalid pool ID");
        uint256 length = _whitelistAddresses.length;
        require (length<= 200, "Can add only 200 wl at a time");
        for (uint256 i = 0; i < length; i++){
            address _whitelistAddress = _whitelistAddresses[i];
            whitelistedAddress[_pid][_whitelistAddress] = true;
        }
    }

    function emergencyLock (bool _lock) public onlyOwner {
        lock_ = _lock;
    }

    function getUserLockTime (uint256 _pid, address _user) public view returns (uint256) {
        return (userInfo[_pid][_user].stakingTime).add((poolInfo[_pid].lockDays).mul(1 days));
    }

    function stakeTokens (uint256 _pid, uint256 _amount) public {
        require (_pid < poolLength(), "Invalid pool ID");
        require (poolInfo[_pid].poolActive, "Pool is not active");
        require (poolInfo[_pid].currentPoolSize.add(_amount) <= poolInfo[_pid].maxPoolSize, "Staking exceeds max pool size");
        require ((userInfo[_pid][msg.sender].amount).add(_amount) <= poolInfo[_pid].maxContribution , "Max Contribution exceeds");
        if (poolInfo[_pid].poolType == false){
            require (whitelistedAddress[_pid][msg.sender], "You are not whitelisted for this pool");
        }

        address _tokenAddress = poolInfo[_pid].tokenAddress;
        IBEP20 token = IBEP20 (_tokenAddress);
        bool success = token.transferFrom(msg.sender, address(this), _amount);
        require (success, "Transfer From failed. Please approve the token");

        poolInfo[_pid].currentPoolSize = (poolInfo[_pid].currentPoolSize).add(_amount);
        uint256 _stakingTime = block.timestamp; 
        _amount = _amount.add(userInfo[_pid][msg.sender].amount);
        userInfo[_pid][msg.sender] = UserInfo ({
            amount: _amount,
            stakingTime: _stakingTime
        });
    }


    function unstakeTokens (uint256 _pid) public {
        require (_pid < poolLength(), "Invalid pool ID");
        require (userInfo[_pid][msg.sender].amount > 0 , "You don't have any staked tokens");
        require (userInfo[_pid][msg.sender].stakingTime > 0 , "You don't have any staked tokens");
        require (getUserLockTime(_pid, msg.sender) < block.timestamp , "Your maturity time is not reached. If you want you can do EmergencyWithdraw");
        
        uint256 _refundValue = (userInfo[_pid][msg.sender].amount)
            .add((poolInfo[_pid].reward)
            .mul(userInfo[_pid][msg.sender].amount)
            .div(1000));
        poolInfo[_pid].currentPoolSize = (poolInfo[_pid].currentPoolSize).sub(userInfo[_pid][msg.sender].amount);
        userInfo[_pid][msg.sender].amount = 0;

        address _tokenAddress = poolInfo[_pid].tokenAddress;
        IBEP20 token = IBEP20 (_tokenAddress);
        bool success = token.transfer(msg.sender, _refundValue);
        require (success, "Transfer failed");
    }

    function emergencyWithdraw (uint256 _pid) public {
        require (_pid < poolLength(), "Invalid pool ID");
        require (userInfo[_pid][msg.sender].amount > 0 , "You don't have any staked tokens");
        require (getUserLockTime(_pid, msg.sender) > block.timestamp , "Your maturity time is reached. You can unstake tokens and enjoy rewards");

        uint256 _emergencyFees = poolInfo[_pid].emergencyFees;

        uint256 _refundValue = (userInfo[_pid][msg.sender].amount)
            .sub((_emergencyFees)
            .mul(userInfo[_pid][msg.sender].amount)
            .div(1000));
        poolInfo[_pid].currentPoolSize = (poolInfo[_pid].currentPoolSize).sub(userInfo[_pid][msg.sender].amount);
        userInfo[_pid][msg.sender].amount = 0;

        address _tokenAddress = poolInfo[_pid].tokenAddress;
        IBEP20 token = IBEP20 (_tokenAddress);
        bool success = token.transfer(msg.sender, _refundValue);
        require (success, "Transfer failed");
    }

    // this function is to withdraw BNB sent to this address by mistake
    function withdrawEth () external onlyOwner returns (bool) {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{
            value: balance
        }("");
        return success;
    }
}
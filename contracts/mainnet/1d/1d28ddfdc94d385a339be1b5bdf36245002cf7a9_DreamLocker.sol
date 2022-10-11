/**
 *Submitted for verification at Etherscan.io on 2022-10-11
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDreamLocker {

    struct LockInfo {
        uint256 amount;
        uint256 duration;
    }

    function getLocks(address owner, address token) external returns (LockInfo[] memory);

    function lockTokens(address token, uint256 amount, uint duration) external;

    function extendLock(address token, uint duration, uint index) external;

    function withdraw(address token, uint256 amount, uint index) external;
}

contract DreamLocker is IDreamLocker {

    uint baseDuration = 1 days;
    address payable private immutable deployer;
    IERC20 public USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    uint256 public rate = 4761 * 10**3; // 47.61 USDC;
    uint256 public lockEventIndex;
    uint256 public lastLockEventIndexUpdate;
    uint256 public leftSummation;
    uint256 public totalStaked;
    IERC20 public token;

    struct TokenInfo {
        address creator;
        uint256 amount;
        uint256 duration;
    }

    mapping(address => uint256) public rightSummation;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public balances;

    mapping(address => mapping(address => LockInfo[])) private lockedTokens; // Owner -> (Token -> LockInfo)

    mapping(address => TokenInfo[]) private tokenRecords; // Token -> TokenInfo

    constructor(address payable _deployer, uint256 _lockEventIndex, address _token) {
        deployer = _deployer;
        lockEventIndex = _lockEventIndex;
        token = IERC20(_token);
    }

    /* STAKING */

    function stake(uint256 amount) external updateInfo(msg.sender) {
        totalStaked += amount;
        balances[msg.sender] += amount;
        token.transferFrom(msg.sender, address(this), amount);
    }

    function unstake(uint256 amount) external updateInfo(msg.sender) {
        totalStaked -= amount;
        balances[msg.sender] -= amount;
        token.transfer(msg.sender, amount);
    }

    function claim() external updateInfo(msg.sender) {
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        USDC.transfer(msg.sender, reward);
    }

    function amountEarned(address account) public view returns (uint256) {
        return (balances[account] * (leftSum() - rightSummation[account]) / 1e18) + rewards[account];
    }

    function leftSum() public view returns (uint256) {
        if(totalStaked == 0) return 0;

        return leftSummation + (rate * (lockEventIndex - lastLockEventIndexUpdate) * 1e18 / totalStaked);
    }

    modifier updateInfo(address account) {
        leftSummation = leftSum();
        lastLockEventIndexUpdate = lockEventIndex;
        rewards[account] = amountEarned(account);
        rightSummation[account] = leftSummation;
        _;
    }

    /* TOKEN LOCKING */

    function getTokenRecords(address _token) public view returns (TokenInfo[] memory) {
        return tokenRecords[_token];
    }

    function getLocks(address owner, address _token) public view returns (LockInfo[] memory) {
        return lockedTokens[owner][_token];
    }

    function approveUSDC() public {
        require(USDC.approve(address(this), 69 * 10**6));
    } 

    function approveTokens(address _token, uint256 amount) public {
        require(IERC20(_token).approve(address(this), amount));
    }

    function lockTokens(address _token, uint256 amount, uint duration) public {
        require(duration > 0, "You must lock for at least 1 day.");
        require(USDC.transferFrom(msg.sender, address(this), 69 * 10**5), "It costs 69 USDC to lock LP.");
        require(IERC20(_token).balanceOf(msg.sender) >= amount);

        IERC20(_token).transferFrom(msg.sender, address(this), amount);
        USDC.transfer(deployer, 2139 * 10**3);

        LockInfo memory newLock = LockInfo(amount, (block.timestamp + (baseDuration*duration)));
        lockedTokens[msg.sender][_token].push(newLock);
        lockEventIndex++;

        TokenInfo memory newInfo = TokenInfo(msg.sender, amount, (block.timestamp + (baseDuration*duration)));
        tokenRecords[_token].push(newInfo);
    }

    function extendLock(address _token, uint duration, uint index) public {
        require(index > 0, "You must extend the lock by at least 1 day.");
        require(USDC.transferFrom(msg.sender, address(this), 69 * 10**5), "It costs 69 USDC to extend the lock.");
        require(((lockedTokens[msg.sender][_token][index].duration) + (baseDuration*duration)) > lockedTokens[msg.sender][_token][index].duration, "New duration must exceed current one.");
        
        USDC.transfer(deployer, 2139 * 10**3);
        uint256 amount = lockedTokens[msg.sender][_token][index].amount;
        LockInfo memory extendedLock = LockInfo(amount, ((lockedTokens[msg.sender][_token][index].duration) + (baseDuration*duration)));
        lockedTokens[msg.sender][_token][index] = extendedLock;
        lockEventIndex++;

        TokenInfo memory newInfo = TokenInfo(msg.sender, amount, ((lockedTokens[msg.sender][_token][index].duration) + (baseDuration*duration)));
        tokenRecords[_token].push(newInfo);
    }

    function splitLock(address _token, uint256 amount, uint duration, uint index) public {
        require(USDC.transferFrom(msg.sender, address(this), 69 * 10**5), "It costs 69 USDC to split the lock.");
        require(amount > 0 && amount < (lockedTokens[msg.sender][_token][index].amount), "Invalid amount.");

        USDC.transfer(deployer, 2139 * 10**3);
        uint256 oldAmount = lockedTokens[msg.sender][_token][index].amount;
        uint256 newSplitDuration = ((lockedTokens[msg.sender][_token][index].duration) + (baseDuration*duration));
        LockInfo memory firstSplit = LockInfo(oldAmount - amount, (lockedTokens[msg.sender][_token][index].duration));
        LockInfo memory otherSplit = LockInfo(amount, newSplitDuration);
        lockedTokens[msg.sender][_token][index] = firstSplit;
        lockedTokens[msg.sender][_token].push(otherSplit);
        lockEventIndex++;

        TokenInfo memory firstSplitInfo = TokenInfo(msg.sender, oldAmount - amount, (lockedTokens[msg.sender][_token][index].duration));
        TokenInfo memory otherSplitInfo = TokenInfo(msg.sender, amount, newSplitDuration);
        tokenRecords[_token].push(firstSplitInfo);
        tokenRecords[_token].push(otherSplitInfo);
    }

    function withdraw(address _token, uint amount, uint index) public {
        require(block.timestamp > lockedTokens[msg.sender][_token][index].duration, "Cannot unlock before deadline.");
        IERC20(_token).transfer(msg.sender, amount);
    }
}
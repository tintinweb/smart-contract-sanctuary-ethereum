/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    function balanceOf(address account) external view returns (uint256);
    
    function decimals() external view returns (uint8);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Ownable {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier onlyOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

contract MinerYieldFarm is Ownable, IERC20 {

    // name and symbol for tokenized contract
    string private _name;
    string private _symbol;
    uint8 private immutable _decimals;

    // lock time in blocks
    uint256 public lockTime;

    // fee for leaving staking early
    uint256 public leaveEarlyFee;

    // recipient of fee
    address public feeRecipient;

    // Staking Token
    address public immutable token;

    // Reward Token
    address public immutable reward;
    address public rewardTokenSwapper;

    // User Info
    struct UserInfo {
        uint256 amount;
        uint256 unlockBlock;
        uint256 totalExcluded;
    }
    // Address => UserInfo
    mapping ( address => UserInfo ) public userInfo;

    // Tracks Dividends
    uint256 public totalRewards;
    uint256 private totalShares;
    uint256 private dividendsPerShare;
    uint256 private constant precision = 10**18;

    // Events
    event SetLockTime(uint LockTime);
    event SetEarlyFee(uint earlyFee);
    event SetFeeRecipient(address FeeRecipient);

    constructor(
        address token_, 
        address feeRecipient_, 
        address reward_, 
        string memory name_, 
        string memory symbol_,
        uint256 leaveEarlyFee_,
        uint256 lockTime_
    ){
        require(
            token_ != address(0) &&
            feeRecipient_ != address(0) &&
            reward_ != address(0),
            'Zero Address'
        );

        token = token_;
        feeRecipient = feeRecipient_;
        reward = reward_;
        leaveEarlyFee = leaveEarlyFee_;
        lockTime = lockTime_;
        _name = name_;
        _symbol = symbol_;
        _decimals = IERC20(token_).decimals();
        emit Transfer(address(0), msg.sender, 0);
    }

    /** Returns the total number of tokens in existence */
    function totalSupply() external view override returns (uint256) { 
        return totalShares; 
    }

    /** Returns the number of tokens owned by `account` */
    function balanceOf(address account) public view override returns (uint256) { 
        return userInfo[account].amount;
    }

    /** Returns the number of tokens `spender` can transfer from `holder` */
    function allowance(address, address) external pure override returns (uint256) { 
        return 0; 
    }
    
    /** Token Name */
    function name() public view override returns (string memory) {
        return _name;
    }

    /** Token Ticker Symbol */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /** Tokens decimals */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /** Approves `spender` to transfer `amount` tokens from caller */
    function approve(address spender, uint256) public override returns (bool) {
        emit Approval(msg.sender, spender, 0);
        return true;
    }
  
    /** Transfer Function */
    function transfer(address, uint256) external override returns (bool) {
        _claimReward(msg.sender);
        return true;
    }

    /** Transfer Function */
    function transferFrom(address, address, uint256) external override returns (bool) {
        _claimReward(msg.sender);
        return true;
    }

    function setLockTime(uint256 newLockTime) external onlyOwner {
        require(
            lockTime <= 10**7,
            'Lock Time Too Long'
        );
        lockTime = newLockTime;
        emit SetLockTime(newLockTime);
    }

    function setLeaveEarlyFee(uint256 newEarlyFee) external onlyOwner {
        require(
            newEarlyFee <= 25,
            'Fee Too High'
        );
        leaveEarlyFee = newEarlyFee;
        emit SetEarlyFee(newEarlyFee);
    }

    function setFeeRecipient(address newFeeRecipient) external onlyOwner {
        require(
            newFeeRecipient != address(0),
            'Zero Address'
        );
        feeRecipient = newFeeRecipient;
        emit SetFeeRecipient(newFeeRecipient);
    }

    function setRewardTokenSwapper(address newTokenSwapper) external onlyOwner {
        require(
            newTokenSwapper != address(0),
            'Zero Address'
        );
        rewardTokenSwapper = newTokenSwapper;
    }

    function withdraw(address token_) external onlyOwner {
        require(
            token != token_,
            'Cannot Withdraw Staked Token'
        );
        require(
            IERC20(token_).transfer(
                msg.sender,
                IERC20(token_).balanceOf(address(this))
            ),
            'Failure On Token Withdraw'
        );
    }

    function claimRewards() external {
        _claimReward(msg.sender);
    }

    function withdraw(uint256 amount) external {
        require(
            amount <= userInfo[msg.sender].amount,
            'Insufficient Amount'
        );
        require(
            amount > 0,
            'Zero Amount'
        );
        if (userInfo[msg.sender].amount > 0) {
            _claimReward(msg.sender);
        }

        totalShares -= amount;
        userInfo[msg.sender].amount -= amount;
        userInfo[msg.sender].totalExcluded = getCumulativeDividends(userInfo[msg.sender].amount);

        uint fee = timeUntilUnlock(msg.sender) == 0 ? 0 : ( amount * leaveEarlyFee ) / 100;
        if (fee > 0) {
            require(
                IERC20(token).transfer(feeRecipient, fee),
                'Failure On Token Transfer'
            );
        }

        uint sendAmount = amount - fee;
        require(
            IERC20(token).transfer(msg.sender, sendAmount),
            'Failure On Token Transfer To Sender'
        );
        emit Transfer(address(this), msg.sender, sendAmount);
    }

    function stake(uint256 amount) external {
        if (userInfo[msg.sender].amount > 0) {
            _claimReward(msg.sender);
        }

        // transfer in tokens
        uint received = _transferIn(token, amount);
        
        // update data
        totalShares += received;
        userInfo[msg.sender].amount += received;
        userInfo[msg.sender].unlockBlock = block.number + lockTime;
        userInfo[msg.sender].totalExcluded = getCumulativeDividends(userInfo[msg.sender].amount);
        emit Transfer(msg.sender, address(this), received);
    }

    function depositRewards(uint256 amount) external {
        uint received = _transferIn(reward, amount);
        dividendsPerShare += ((precision * received) / totalShares);
        totalRewards += received;
    }


    function _claimReward(address user) internal {

        // exit if zero value locked
        if (userInfo[user].amount == 0) {
            return;
        }

        // fetch pending rewards
        uint256 amount = pendingRewards(user);
        
        // exit if zero rewards
        if (amount == 0) {
            return;
        }

        // update total excluded
        userInfo[msg.sender].totalExcluded = getCumulativeDividends(userInfo[msg.sender].amount);

        // transfer reward to user
        require(
            IERC20(reward).transfer(user, amount),
            'Failure On Token Claim'
        );
    }

    function _transferIn(address _token, uint256 amount) internal returns (uint256) {
        uint before = IERC20(_token).balanceOf(address(this));
        bool s = IERC20(_token).transferFrom(msg.sender, address(this), amount);
        uint received = IERC20(_token).balanceOf(address(this)) - before;
        require(
            s && received > 0 && received <= amount,
            'Error On Transfer From'
        );
        return received;
    }

    function timeUntilUnlock(address user) public view returns (uint256) {
        return userInfo[user].unlockBlock < block.number ? 0 : userInfo[user].unlockBlock - block.number;
    }

    function pendingRewards(address shareholder) public view returns (uint256) {
        if(userInfo[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(userInfo[shareholder].amount);
        uint256 shareholderTotalExcluded = userInfo[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends - shareholderTotalExcluded;
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return (share * dividendsPerShare) / precision;
    }

    receive() external payable {
        require(
            msg.value > 0,
            'Zero Amount'
        );
        // purchase reward token
        uint before = IERC20(reward).balanceOf(address(this));
        (bool s,) = payable(rewardTokenSwapper).call{value: msg.value}("");
        require(s, 'Failure On Token Purchase');
        uint received = IERC20(reward).balanceOf(address(this)) - before;
        require(received > 0, 'Zero Received');
        // update rewards
        dividendsPerShare += ((precision * received) / totalShares);
        totalRewards += received;
    }

}
/**
 *Submitted for verification at Etherscan.io on 2023-03-12
*/

pragma solidity ^0.8.16;
// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Stake is Ownable {

    mapping(address => bool) public staked;
    mapping(address => uint256) public tokenBalanceLedger_;
    mapping(address => uint256) public stakeStartTime;

    uint256 public timeLock = 0 days;// Unlocked
    uint256 public timeToWithdraw = 1 days;

    IERC20 public stakeToken;

    uint256 public totalTokens = 0;

    uint256 public profitPerShare_;

    mapping(address => uint256) public payoutsTo_;

    uint256 constant internal magnitude = 2**64;

    receive() external payable {
        profitPerShare_ +=  (msg.value * magnitude) / totalTokens;
    }
    
    function deposit() public payable {
        profitPerShare_ +=  (msg.value * magnitude) / totalTokens;
    }

    function stakeTokens(uint amount) public {

        stakeToken.transferFrom(msg.sender, address(this), amount);

        uint256 currentDivs = getDividends(msg.sender);

        tokenBalanceLedger_[msg.sender] += amount;
        staked[msg.sender] = true;

        totalTokens += amount;

        stakeStartTime[msg.sender] = block.timestamp;

        payoutsTo_[msg.sender] += (getDividends(msg.sender) - currentDivs);
    }

    function canExit(address user) public view returns(bool) {
        uint256 startTime = stakeStartTime[user];
        uint256 endTime = block.timestamp;

        uint256 timeStaked = endTime - startTime;
        if (timeStaked >= (timeLock + timeToWithdraw)) {

            uint256 lastVariable = timeToWithdraw;
            while(timeStaked >= (timeLock + timeToWithdraw)) {
                if (lastVariable == timeToWithdraw) {
                    lastVariable = timeLock;

                } else {
                    lastVariable = timeToWithdraw;
                }

                timeStaked -= lastVariable;
            }

            if (lastVariable == timeToWithdraw) {
                return true;
            }

            return false;
        } else if(timeStaked >= (timeLock)) {
            return true;
        } else {
            return false;
        }
    }

    function exitFromStakingPool() public {
        require(canExit(msg.sender), "Staking time is not over.");

        withdrawDividends();

        stakeToken.transfer(msg.sender, tokenBalanceLedger_[msg.sender]);

        totalTokens -= tokenBalanceLedger_[msg.sender];
        tokenBalanceLedger_[msg.sender] = 0;
        staked[msg.sender] = false;
        payoutsTo_[msg.sender] = 0;
    }

    function getDividends(address user) public view returns(uint256) {
        uint256 allDivs = (tokenBalanceLedger_[user] * profitPerShare_) / magnitude;

        uint256 profit = allDivs - payoutsTo_[user];

        return profit;
    }

    function getTokenBalance(address user) public view returns(uint256) {
        return tokenBalanceLedger_[user];
    }

    function withdrawDividends() public {
        uint256 myDivs = getDividends(msg.sender);

        payable(msg.sender).transfer(myDivs);
        payoutsTo_[msg.sender] += myDivs;
    }

    function setTokenAddress(address tokenAddress) public
    onlyOwner()
    {
        stakeToken = IERC20(tokenAddress);
    }


    function changeTimeLockTime(uint256 timeInDays) public
    onlyOwner()
    {
        require(timeInDays <= 15 days, "Maximum time lock is 15 days");

        timeLock = timeInDays;
    }

    function changeTimeToWithdraw(uint256 timeInDays) public
    onlyOwner()
    {
        require(timeInDays >= 1 days, "Minimum time to withdraw is 1 day.");
        timeToWithdraw = timeInDays;
    }

    function getTotalEthBalance() public view returns(uint256){
        return address(this).balance;
    }
}
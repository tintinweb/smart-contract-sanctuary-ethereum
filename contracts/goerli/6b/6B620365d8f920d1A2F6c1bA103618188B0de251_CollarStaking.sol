/**
 *Submitted for verification at Etherscan.io on 2023-03-12
*/

/**
 *Submitted for verification at Etherscan.io on 2023-03-11
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

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

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
}

library SafeMath {

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

}

error ContractPaused();
error InvalidSelection();
error RecordNotFound();
error LockPeriodNotOverYet();
error InvalidRewardCount();

contract CollarStaking is Ownable {

    using SafeMath for uint256;

    IERC20 public Token = IERC20(0xE67Cc26FCa7b99F574c40aD1A7c5582746f649d9);

    uint256 private series = 31536000;
    uint256 denominator = 100;

    uint256[] private APYs = [250,500];
    // uint256[] private lockDuration = [15 days,30 days];
    uint256[] private lockDuration = [2 minutes,5 minutes];

    bool public paused;

    struct slot {
        uint256 amount;
        uint256 stakedTime;
        uint256 lockPeriod;
        uint256 unlockTime;
        uint256 APY;
    }

    struct user {
        uint _totalSlots;
        uint _totalClaimed;
        slot[] _totalStakes;
    }

    mapping (address => user) public _ledger;
    mapping (address => uint) public _userRewarded;
    
    uint256 public _totalStaked;
    uint256 public _totalClaimed;

    constructor() {}

    // pid 0 -> for 250 APY and 15 days time
    // pid 1 -> for 500 APY and 30 days time

    function stake(uint _pid,uint amount) external {
        if(paused) revert ContractPaused();
        if(_pid > 1) revert InvalidSelection();
        address account = msg.sender;
        Token.transferFrom(account,address(this),amount);
        slot memory newRecord = slot(
            amount,
            block.timestamp,
            lockDuration[_pid],
            block.timestamp.add(lockDuration[_pid]),
            APYs[_pid]
            );
        _totalStaked += amount;
        _ledger[account]._totalStakes.push(newRecord);
        _ledger[account]._totalSlots = _ledger[account]._totalStakes.length;
    }

    function unstakeAndClaim(uint _index) external {
        if(paused) revert ContractPaused();
        address account = msg.sender;
        uint length = _ledger[account]._totalStakes.length;
        if(length == 0 || _index >= length) revert RecordNotFound();
        
        if(_ledger[account]._totalStakes.length == 0) revert RecordNotFound();
        (uint amount,uint reward,bool res) = getRewardInfo(account,_index);

        if(!res) {
            revert LockPeriodNotOverYet();
        }
        else {
            uint subtotal = amount.add(reward);
            _userRewarded[account] += reward;
            removeEntry(account,_index);
            Token.transfer(account,subtotal);

            _ledger[account]._totalClaimed += reward;
            _totalClaimed += reward;
        }
    }

    function terminate(uint _index) external {
        if(paused) revert ContractPaused();
        address account = msg.sender;

        uint length = _ledger[account]._totalStakes.length;
        if(length == 0 || _index >= length) revert RecordNotFound();
        
        (uint amount,,) = getRewardInfo(account,_index);

        removeEntry(account,_index);
        Token.transfer(account,amount);
       
    }

    // function claimReward(uint _index) external {
    //     if(paused) revert ContractPaused();
    //     address account = msg.sender;

    //     uint length = _ledger[account]._totalStakes.length;
    //     if(length == 0 || _index >= length) revert RecordNotFound();

    //     (,uint reward,) = getRewardInfo(account,_index);
        
    //     uint claimed = _ledger[account]._totalStakes[_index].claimed;
    //     uint rTransfer = reward.sub(claimed);
    //     if(rTransfer == 0) revert InvalidRewardCount();
    //     Token.transfer(account,rTransfer);
    //     _ledger[account]._totalStakes[_index].claimed += rTransfer;

    // }

    function removeEntry(address account, uint _index) internal {
        uint lastEntry = _ledger[account]._totalSlots.sub(1);
        _ledger[account]._totalStakes[_index] = _ledger[account]._totalStakes[lastEntry]; 
        _ledger[account]._totalStakes.pop();
        _ledger[account]._totalSlots = _ledger[account]._totalStakes.length;
    }

    function getRewardInfo(address _user,uint _index) public view returns (uint _stakeAmount,uint _reward,bool _unlocked) {
        slot memory rSlot = _ledger[_user]._totalStakes[_index];
        bool restriction = block.timestamp >= rSlot.unlockTime ? true : false;
        uint perSecReward = getRewardAmount(rSlot.amount,rSlot.APY);
        uint count = getSeconds(rSlot.stakedTime);
        return (rSlot.amount,perSecReward.mul(count),restriction);
    }

    function getUserStakeSlots(address _user, uint _index) external view returns (slot memory) {
        return _ledger[_user]._totalStakes[_index];
    }

    function setDuration(uint _index,uint _timestamp) external onlyOwner {
        uint length = lockDuration.length;
        if(_index >= length) {
            lockDuration.push(_timestamp);
        }
        else{
            lockDuration[_index] = _timestamp;
        }
    }

    function getLengthDuration() external view returns (uint) {
        return lockDuration.length;
    }

    function getSeconds(uint _time) internal view returns (uint) {
        uint sec = block.timestamp.sub(_time);
        return sec;
    }

    function getRewardAmount(uint _amount,uint APY) public view returns (uint){
        uint num = _amount.mul(APY).div(denominator);
        return num.div(series);
    }

    function getTime() external view returns (uint256) {
        return block.timestamp;
    }

    function setToken(address _adr) external onlyOwner {
        Token = IERC20(_adr);
    }

    function setPauser(bool _status) external onlyOwner {
        require(paused != _status,"Error: Not Changed!");
        paused = _status;
    }

    function rescueFunds() external onlyOwner {
        (bool os,) = payable(msg.sender).call{value: address(this).balance}("");
        require(os);
    }

    function rescueToken(address _token) external onlyOwner {
        uint balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender,balance);
    }

    receive() external payable {}

}
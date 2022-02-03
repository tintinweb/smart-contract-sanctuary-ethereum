/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

pragma solidity =0.7.6;
// SPDX-License-Identifier: Unlicensed

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
}

contract Ownable is Context {
    address private _owner;

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}

contract SHIBURAIVESTKEEPER is Context, Ownable {
    using SafeMath for uint256;

    IERC20 public shiburai; 
    uint256 public withdrawAmount;
    uint256 public waitTime;
    uint256 public maxHoldings;
    bool public withdrawEnabled;
    uint public contractShiburaiBalance;

    mapping (address => uint256) private balances;
    mapping (address => uint256) private lastWithdraw;

    constructor() {
        IERC20 _shiburai = IERC20(0x275EB4F541b372EfF2244A444395685C32485368);
        shiburai = _shiburai;
        withdrawAmount = 100000000000;
        waitTime = 1 days;
        maxHoldings = 10000000000;
        withdrawEnabled = true;
    }

    function setWithdrawParameters( uint256 _amount, uint256 _numOfDays, uint256 _threshold, bool _enabled) external onlyOwner {
        withdrawAmount = _amount * 10**9;
        waitTime = _numOfDays * 1 days;
        withdrawEnabled = _enabled;
        maxHoldings = _threshold * 10**9;
    }

    function remainingVestedBalance(address _address) external view returns(uint256) {
        return balances[_address];
    }

    function lastWithdrawnAt(address _address) external view returns(uint256) {
        return lastWithdraw[_address];
    }

    function deposit() external {
        uint _amount = shiburai.balanceOf(msg.sender);
        require(shiburai.transferFrom(msg.sender, address(this), _amount), "Transfer failed"); 
        balances[msg.sender] = balances[msg.sender].add(_amount);
        contractShiburaiBalance = contractShiburaiBalance.add(_amount);
    }

    function withdraw() external {
        uint _balance = shiburai.balanceOf(msg.sender);
        require(_balance <= maxHoldings, "Cannot accumulate");
        require(balances[msg.sender] >= withdrawAmount, "Insuffecient Balance");
        require(lastWithdraw[msg.sender].add(waitTime) <= block.timestamp, "Must wait more time");
        lastWithdraw[msg.sender] = block.timestamp;
        shiburai.transfer(address(msg.sender), withdrawAmount);
        balances[msg.sender] = balances[msg.sender].sub(withdrawAmount);
        contractShiburaiBalance = contractShiburaiBalance.sub(withdrawAmount);
    }   

    //to withdraw any remaining tokens after vesting has finished
    function claimRemainingBalanceAtEndOfVesting() external onlyOwner {
        uint _amount = shiburai.balanceOf(address(this));
        shiburai.transfer(msg.sender, _amount);
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-12-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

contract CarbonStaking is Ownable, ReentrancyGuard {

    using SafeMath for uint256;

    IERC20 public Carbon;

    uint256 public SAPY = 21 * 10**11;
    uint256 public Delta = 28935;
    uint256 public FAPY = 3 * 10**11;
    uint256 public denominator = 10**13;
    uint256 public series = 31536000;

    uint256 public PoolStartTime;

    uint256 public totalStaked;
    uint256 public totalUnstaked;
    uint256 public totalDistributed;
    uint256 public StakersCount;

    struct StakedRec {
        uint256 _amount;
        uint256 _apy;
        uint256 _stakeTime;
        uint256 _lockTime;    //in seconds
    }

    struct pool {
        address _user;
        uint256 _totalStaked;
        uint256 _totalUnStaked;
        uint256 _totalClaimed;
        StakedRec[] _Ledger;
    }

    mapping (address => pool) public _stakers;

    bool public paused;

    event Staked (
        address indexed _user,
        uint256 indexed _amount,
        uint256 _timestamp,
        uint256 _apy
    );

    event unStaked (
        address indexed _user,
        uint256 indexed _amount,
        uint256 _timestamp
    );

    constructor() {
        PoolStartTime = block.timestamp;
        Carbon = IERC20(0x65526D2B86fF1aC0a3a789FC6fF9C36d35673F1B);
    }

    function stake(uint _amount,uint _duration) public nonReentrant() {
        require(!paused,"Error: Staking is Currently Paused Now!!");
        address account = msg.sender;
        Carbon.transferFrom(account, address(this), _amount);
        if(_stakers[account]._totalStaked == 0) {
            _stakers[account]._user = account;
            StakersCount++;
        }
        uint256 _runningApy = getApy();
        StakedRec memory _rec = StakedRec(_amount,_runningApy,block.timestamp,_duration);
        _stakers[account]._Ledger.push(_rec);
        _stakers[account]._totalStaked += _amount;
        totalStaked += _amount;
        emit Staked(account,_amount,block.timestamp,_runningApy);
    }

    function claimAndUnstake(uint _index) public nonReentrant() {
        require(!paused,"Error: Staking is Currently Paused Now!!");
        
        address account = msg.sender;

        errorCatch(account,_index);
        errorTimer(account,_index);
        
        uint length = _stakers[account]._Ledger.length;
        StakedRec memory arr = _stakers[account]._Ledger[_index];

        uint revenueFactor = perSecR(arr._amount,arr._apy);
        uint tr = calTime(arr._stakeTime);
        uint ActualRevenue = revenueFactor.mul(tr);
        uint ActualAmount = arr._amount;

        _stakers[account]._Ledger[_index] = _stakers[account]._Ledger[length - 1];
        _stakers[account]._Ledger.pop();

        totalUnstaked += ActualAmount;
        totalDistributed += ActualRevenue;
        
        _stakers[account]._totalStaked -= ActualAmount;
        _stakers[account]._totalUnStaked += ActualAmount; 
        _stakers[account]._totalClaimed += ActualRevenue;

        if(_stakers[account]._totalStaked == 0) StakersCount--;

        Carbon.transfer(account, ActualRevenue.add(ActualAmount));
        emit unStaked(account,ActualAmount,block.timestamp);
    }  

    function terminate(uint _index) public nonReentrant() {
        require(!paused,"Error: Staking is Currently Paused Now!!");
        address account = msg.sender;
        errorCatch(account,_index);
        uint length = _stakers[account]._Ledger.length;
        StakedRec memory arr = _stakers[account]._Ledger[_index];
        uint ActualAmount = arr._amount;
        _stakers[account]._Ledger[_index] = _stakers[account]._Ledger[length - 1];
        _stakers[account]._Ledger.pop();
        _stakers[account]._totalStaked -= ActualAmount;
        _stakers[account]._totalUnStaked += ActualAmount;
        totalUnstaked += ActualAmount;
        if(_stakers[account]._totalStaked == 0) StakersCount--;
        Carbon.transfer(account, ActualAmount);
        emit unStaked(account,ActualAmount,block.timestamp);
    }

    function errorTimer(address account, uint _index) internal view {
        StakedRec memory arr = _stakers[account]._Ledger[_index];
        uint UnlockTime = arr._stakeTime.add(arr._lockTime);
        if(block.timestamp < UnlockTime) {
            revert("Error: Lock Time Not Over Yet!!");
        }
    }

    function errorCatch(address account, uint _index) internal view {
        uint length = _stakers[account]._Ledger.length;
        if(_stakers[account]._totalStaked == 0) {
            revert("Error: No Amount Staked at this time!!");
        }
        if(_index > length - 1) {
            revert("Error: Invalid Index!");
        }
    }

    function slotRevenue(address _adr, uint _index) external view returns (uint) {
        uint length = _stakers[_adr]._Ledger.length;
        if(length == 0) revert("Error: No Record Found");
        StakedRec memory arr = _stakers[_adr]._Ledger[_index];
        uint revenueFactor = perSecR(arr._amount,arr._apy);
        uint tr = calTime(arr._stakeTime);
        uint ActualRevenue = revenueFactor.mul(tr);
        return ActualRevenue;
    } 

    function getList(address _account) external view returns (StakedRec[] memory _rec, uint _size) {
        return (_stakers[_account]._Ledger, _stakers[_account]._Ledger.length);
    }

    function getLedgerIndex(address _account,uint _index) external view returns (StakedRec memory _rec) {
        uint length = _stakers[_account]._Ledger.length;
        if(length == 0) revert("Error: No Record Found");
        if(_index > length - 1) {
            revert("Error: Invalid Index!");
        }
        StakedRec memory arr = _stakers[_account]._Ledger[_index];
        return arr;
    }

    function calTime(uint _timer) internal view returns (uint) {
        return _timer == 0 ? 0 : block.timestamp.sub(_timer);
    }

    function perSecR(uint _amount, uint apy) internal view returns (uint) {
        uint Factor = (_amount.mul(apy)).div(denominator);
        uint RewardAmount = Factor.div(series);
        return RewardAmount;
    }

    function getApy() public view returns (uint256) {
        uint sec = block.timestamp.sub(PoolStartTime);
        uint fac = Delta.mul(sec);
        uint res = SAPY.sub(fac);
        return res < FAPY ? FAPY : res;
    }
	
	/// @notice Reset APY Function call with care.
    function resetApy() external onlyOwner {
        PoolStartTime = block.timestamp;
    }

    function getTime() external view returns (uint256) {
        return block.timestamp;
    }

    function getBalance() external view returns (uint256) {
        return Carbon.balanceOf(address(this));
    }

    function setCarbon(address _token) external onlyOwner {
        Carbon = IERC20(_token);
    }

    function setPauser(bool _status) external onlyOwner {
        require(paused != _status,"Error: Not Changed!");
        paused = _status;
    }

    function rescueFunds() external onlyOwner {
        (bool os,) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function rescueToken(address _token) external onlyOwner {
        uint balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(owner(),balance);
    }

    receive() external payable {}

}
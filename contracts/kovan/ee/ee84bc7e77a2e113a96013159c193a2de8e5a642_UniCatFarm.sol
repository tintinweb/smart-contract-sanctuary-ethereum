/**
 *Submitted for verification at Etherscan.io on 2022-07-01
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
pragma solidity 0.7.1;

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

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

library Address {
 
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
 
            if (returndata.length > 0) {
   
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { 

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface UniCat {
    
    function mint(address dst, uint rawAmount) external;
    function transfer(address dst, uint rawAmount) external returns (bool);
    function balanceOf(address account) external view returns (uint);
    function totalSupply() external view returns (uint);
    
}

contract UniCatFarm is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;    
        uint256 rewardDebt; 

    }

    struct PoolInfo {
        IERC20 lpToken;           
        uint256 allocPoint;      
        uint256 lastRewardBlock; 
        uint256 accMEOWPerShare; 
    }

    UniCat public MEOW;

    address public devaddr;

    uint256 public bonusEndBlock;

    uint256 public MEOWPerBlock;

    uint256 public constant BONUS_MULTIPLIER = 10;

    address public governance;

    PoolInfo[] public poolInfo;
    
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    
    uint256 public totalAllocPoint = 0;
    
    uint256 public startBlock;
    
    uint256 public endBlock;
    
    uint256 public devFeeUnlockTime = 1632139200;

    bool public devFeeDelivered;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        UniCat _MEOW,
        address _devaddr,
        uint256 _MEOWPerBlock, // 100000000000000000000
        uint256 _startBlock, // 10902300 , https://etherscan.io/block/countdown/10902300
        uint256 _bonusEndBlock, //10930000, https://etherscan.io/block/countdown/10930000
        uint256 _endBlock //11240000 (around 50 days of farming), https://etherscan.io/block/countdown/11240000
    ) {
        MEOW = _MEOW;
        devaddr = _devaddr;
        MEOWPerBlock = _MEOWPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
        endBlock = _endBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }


    modifier onlyOwnerOrGovernance() {
        require(owner() == _msgSender() || governance == _msgSender(), "Caller is not the owner, neither governance");
        _;
    }

    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwnerOrGovernance {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accMEOWPerShare: 0
        }));
    }

    function updateAllocPoint(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwnerOrGovernance {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    function setGovernance(address _governance, bytes memory _setupData) public onlyOwnerOrGovernance {
        governance = _governance;
        (bool success, bytes memory returndata) = governance.call(_setupData);
        require(success, "setGovernance: failed");

    }

    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        
        if(_to > endBlock){
            _to = endBlock;
        }
        
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                _to.sub(bonusEndBlock)
            );
        }
    }

    function pendingMEOW(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accMEOWPerShare = pool.accMEOWPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 MEOWReward = multiplier.mul(MEOWPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accMEOWPerShare = accMEOWPerShare.add(MEOWReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accMEOWPerShare).div(1e12).sub(user.rewardDebt);
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 MEOWReward = multiplier.mul(MEOWPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        
        MEOW.mint(address(this), MEOWReward);
        pool.accMEOWPerShare = pool.accMEOWPerShare.add(MEOWReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }
    
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accMEOWPerShare).div(1e12).sub(user.rewardDebt);
            safeMEOWTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accMEOWPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not enough");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accMEOWPerShare).div(1e12).sub(user.rewardDebt);
        safeMEOWTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accMEOWPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    function safeMEOWTransfer(address _to, uint256 _amount) internal {
        uint256 MEOWBal = MEOW.balanceOf(address(this));
        if (_amount > MEOWBal) {
            MEOW.transfer(_to, MEOWBal);
        } else {
            MEOW.transfer(_to, _amount);
        }
    }

    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
    
    
    function devFee() public {
        require(block.timestamp >= devFeeUnlockTime, "devFee: wait until unlock time");
        require(!devFeeDelivered, "devFee: can only be called once");
        MEOW.mint(devaddr, MEOW.totalSupply().div(200));
        devFeeDelivered=true;
    }
}
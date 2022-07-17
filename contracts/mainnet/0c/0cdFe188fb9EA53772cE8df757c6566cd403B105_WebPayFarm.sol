/**
 *Submitted for verification at Etherscan.io on 2022-07-17
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-18
*/

pragma solidity >=0.6.0 <0.8.0;


interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the erc token owner.
   */
  function getOwner() external view returns (address);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERCMint20 is IERC20{
	function farm(address to, uint256 amount) external returns (bool);
}


pragma solidity >=0.6.0;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}



pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


pragma solidity >=0.6.0 <0.8.0;

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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity >=0.4.24 <=0.7.6;

contract Initializable {

  bool private initialized;

  bool private initializing;

  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  function isConstructor() private view returns (bool) {
    
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  uint256[50] private ______gap;
}


pragma solidity ^0.7.0;


contract Context is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

pragma solidity ^0.7.0;

contract Ownable is Initializable, Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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

    uint256[49] private __gap;
}


pragma solidity ^0.7.0;

interface IWETHelper {
    function withdraw(uint) external;
}

contract WETHelper {
    receive() external payable {
    }
    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, '!WETHelper: ETH_TRANSFER_FAILED');
    }
    function withdraw(address _eth, address _to, uint256 _amount) public {
        IWETHelper(_eth).withdraw(_amount);
        safeTransferETH(_to, _amount);
    }
}

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

contract WebPayFarm is Ownable {
    using SafeMath for uint256;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
		uint256 lockType;
		uint256 lockToBlockNumber;
		uint256 lockToTimestamp;
    }
	
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;       // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. SUSHIs to distribute per block.
        uint256 amount;           // User deposit amount
        uint256 lastRewardBlock;  // Last block number that SUSHIs distribution occurs.
        uint256 accSushiPerShare; // Accumulated SUSHIs per share, times 1e12. See below.
    }

    address public constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // The SUSHI TOKEN!
    IERCMint20 public sushi;
    // Dev address.
    address public devaddr;
    address public treasureaddr;
	
    // SUSHI tokens created per block.
    uint256 public sushiPerBlock;
    // Halving blocks;
    uint256 public blocksHalving;
    address[] private alluses;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
	
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when SUSHI mining starts.
    uint256 public startBlock;
    // Block number when bonus SUSHI period ends.
    uint256 public bonusEndBlock;
	uint256 public tax = 0;
	uint256 blocksPerDay = 9600;
	bool farmStarted = false;
	
    // Bonus muliplier for early sushi makers.
    uint256 public constant BONUS_MULTIPLIER = 2;
    // ETH Helper for the transfer, stateless.
    WETHelper public wethelper;
	
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, uint256 liquidity);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Mint(address indexed user, uint256 amount);
    
    function initialize(
        IERCMint20 _sushi,
        address _devaddr
    ) public initializer {
        Ownable.__Ownable_init();
        sushi = _sushi;
        devaddr = _devaddr;
        treasureaddr = _devaddr;
		sushiPerBlock = 0;
        wethelper = new WETHelper();
    }
    
    function startFarming(uint256 _sushiPerBlock) public{
		require(msg.sender == owner() || msg.sender == devaddr, "!dev addr");
		require(farmStarted == false);
		farmStarted = true;
        sushiPerBlock = _sushiPerBlock;
        startBlock = block.number;
        bonusEndBlock = startBlock + blocksPerDay * 30;
    }
	
    receive() external payable {
        assert(msg.sender == ETH);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public {
        require(msg.sender == owner() || msg.sender == devaddr, "!dev addr");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            amount: 0,
            lastRewardBlock: lastRewardBlock,
            accSushiPerShare: 0
        }));

    }

    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public {
        require(msg.sender == owner() || msg.sender == devaddr, "!dev addr");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }
	
	function setTax(uint256 _tax) public {
	    require(msg.sender == owner() || msg.sender == devaddr, "!dev addr");
	    tax = _tax;
	}
	function setSushiPerBlock(uint256 _sushiPerBlock) public {
	    require(msg.sender == owner() || msg.sender == devaddr, "!dev addr");
	    sushiPerBlock = _sushiPerBlock;
	}

    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
		if(_from < startBlock){
			_from = startBlock;
		}
		if(_to < _from){
			_to = _from;
		}
		if (_to <= bonusEndBlock) {
		    return _to.sub(_from).mul(BONUS_MULTIPLIER);
		} else if (_from >= bonusEndBlock) {
		    return _to.sub(_from);
		} else {
		    return bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(_to.sub(bonusEndBlock));
		}
    }

    function pendingSushi(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accSushiPerShare = pool.accSushiPerShare;
        uint256 lpSupply = pool.amount;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 sushiReward = multiplier.mul(sushiPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accSushiPerShare = accSushiPerShare.add(sushiReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accSushiPerShare).div(1e12).sub(user.rewardDebt);
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function newUser(address _newUser) internal{
        bool exist = false;
        for(uint i = 0;i<alluses.length;i++){
            address addr = alluses[i];
            if(address(addr) == address(_newUser)){
                exist = true;
                break;
            }
        }
        if(exist == false){
            alluses.push(address(msg.sender));
        }
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        if (block.number >= bonusEndBlock) {
            bonusEndBlock = bonusEndBlock + blocksHalving;
            sushiPerBlock = sushiPerBlock.div(2);
        }
        uint256 lpSupply = pool.amount;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 sushiReward = multiplier.mul(sushiPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        
        pool.accSushiPerShare = pool.accSushiPerShare.add(sushiReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }
    
    function deposit(uint256 _pid, uint256 _amount,uint256 lockIndex) public payable {
        require(lockIndex<=4,"lockindex");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        newUser(msg.sender);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accSushiPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
				pending = pending.mul([0,30,50,75,100][user.lockType]).div(1000).add(pending);
                safeSushiTransfer(msg.sender, pending);
            }
        }
        
        if (address(pool.lpToken) == ETH) {
            if(_amount > 0) {
                TransferHelper.safeTransferFrom(address(pool.lpToken),address(msg.sender), address(this), _amount);
            }
            if (msg.value > 0) {
                IWETH(ETH).deposit{value: msg.value}();
                _amount = _amount.add(msg.value);
            }
        } else if(_amount > 0) {
            TransferHelper.safeTransferFrom(address(pool.lpToken),address(msg.sender), address(this), _amount);
        }

        if(_amount > 0) {
            uint256 newTo = block.number + [0,7,15,30,90][lockIndex] * blocksPerDay;
			user.lockToBlockNumber = newTo>user.lockToBlockNumber?newTo:user.lockToBlockNumber;
			uint256 newToTimestamp = getBlockTimestamp().add([0,7 days,15 days,30 days,90 days][lockIndex]);
			user.lockToTimestamp = newToTimestamp>user.lockToTimestamp?newToTimestamp:user.lockToTimestamp;
			user.lockType = user.lockType>lockIndex?user.lockType:lockIndex;
        }

        if(_amount > 0) {
            pool.amount = pool.amount.add(_amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accSushiPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount, 0);
        
    }
    
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
		
        require(user.amount >= _amount, "withdraw: not good");
		require(user.lockToTimestamp < getBlockTimestamp(), "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accSushiPerShare).div(1e12).sub(user.rewardDebt);
        
        if(pending > 0) {
			pending = pending.add(pending.mul([0,30,50,75,100][user.lockType]).div(1000));
            safeSushiTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.amount = pool.amount.sub(_amount);
			if (address(pool.lpToken) == ETH) {
                TransferHelper.safeTransfer(ETH, address(wethelper), _amount);
				if(tax>0)wethelper.withdraw(ETH, address(treasureaddr), _amount * tax / 100);
		        wethelper.withdraw(ETH, address(msg.sender), _amount - _amount * tax / 100);
			} else {
			    if(tax>0)TransferHelper.safeTransfer(address(pool.lpToken),address(treasureaddr), _amount * tax / 100);
				TransferHelper.safeTransfer(address(pool.lpToken),address(msg.sender), _amount - _amount * tax / 100);
			}
        }
        user.rewardDebt = user.amount.mul(pool.accSushiPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
        
    }
	
    function safeSushiTransfer(address _to, uint256 _amount) internal {
        sushi.farm(address(this), _amount);
        sushi.transfer(_to,_amount);
        emit Mint(_to,_amount);
    }
	
	function endFarm(uint256 _pid) public{
		require(msg.sender == owner() || msg.sender == devaddr, "!dev addr");
		for(uint i = 0;i<alluses.length;i++){
		    address addr = alluses[i];
		    PoolInfo storage pool = poolInfo[_pid];
		    UserInfo storage user = userInfo[_pid][addr];
			if(user.amount==0)continue;
		    uint256 pending = user.amount.mul(pool.accSushiPerShare).div(1e12).sub(user.rewardDebt);
		    if(pending > 0) {
				pending = pending.mul([0,30,50,75,100][user.lockType]).div(1000).add(pending);
		        safeSushiTransfer(addr, pending);
		    }
			uint256 _amount = user.amount;
			_amount = safeAmount(_pid,_amount);
		    if(_amount > 0) {
		        user.amount = user.amount.sub(_amount);
		        pool.amount = pool.amount.sub(_amount);
                if(tax>0)TransferHelper.safeTransfer(address(pool.lpToken),address(treasureaddr),_amount.mul(tax).div(100));
                TransferHelper.safeTransfer(address(pool.lpToken),address(addr),_amount.sub(_amount.mul(tax).div(100)));
                user.lockType = 0;
                user.lockToBlockNumber = 0;
                user.lockToTimestamp = 0;
            }
		}
	}
    
	function safeAmount(uint256 _pid,uint256 _amount) internal view returns(uint256){
		PoolInfo storage pool = poolInfo[_pid];
		uint256 poolBalance = pool.lpToken.balanceOf(address(this));
		return _amount<=poolBalance?_amount:poolBalance;
	}
    
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

	function getBlockTimestamp() internal view returns (uint) {
	    return block.timestamp;
	}
    
}
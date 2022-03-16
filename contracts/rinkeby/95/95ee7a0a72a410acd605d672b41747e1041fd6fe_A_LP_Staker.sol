/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

/*
     _____ _____ _____ ____  _____    __    _____    _____               
    |   __|  |  |  _  |    \|   __|  |  |  |  _  |  |   __|___ ___ _____ 
    |__   |     |     |  |  |   __|  |  |__|   __|  |   __| .'|  _|     |
    |_____|__|__|__|__|____/|_____|  |_____|__|     |__|  |__,|_| |_|_|_|

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// ------------------------------------- Address -------------------------------------------
library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }    
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }    
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
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
// ------------------------------------- SafeERC20 -------------------------------------------
library SafeERC20 {
    using Address for address;
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
// ------------------------------------- Context -------------------------------------------
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
// ------------------------------------- Ownable -------------------------------------------
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// ------------------------------------- IERC20 -------------------------------------------
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
// ------------------------------------- ERC20 -------------------------------------------
abstract contract ERC20 is Context, IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function name() public view virtual returns (string memory) {
        return _name;
    }
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}
// ------------------------------------- IMasterChef -------------------------------------------
interface IMasterChef {
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. SHADEs to distribute per block.
        uint256 lastRewardTime;   // Last block time that SHADEs distribution occurs.
        uint256 accSHADEPerShare; // Accumulated SHADEs per share, times 1e12. See below.
    }
    function pendingSHADE(uint256 pid, address user) external view returns (uint256);
    function shadePerSecond() external view returns (uint256);
    function totalAllocPoint() external view returns (uint256);
    function poolInfo(uint256 pid) external view returns (PoolInfo memory);    
    function deposit(uint256 pid, uint256 amount) external;  
    function withdraw(uint256 pid, uint256 amount) external;  
}
// ------------------------------------- IRewardsStaker -------------------------------------------
interface IRewardsStaker {
    function stakeFrom(address account, uint256 amount) external returns (bool);
}

// -------------------------------------------------------------------------------------------
// ------------------------------------- LP Staker -------------------------------------------
// -------------------------------------------------------------------------------------------
contract A_LP_Staker is ERC20, Ownable {
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    IERC20 lpToken;           // Address of LP token contract.
    uint256 public lpDeposited;   
    uint256 public startTime;
    uint256 public lastRewardTime;  // Last block time that SHADEs distribution occurs.
    uint256 public accSHADEPerShare; // Accumulated SHADEs per share, times 1e12. See below.
    
    IERC20 public immutable shade;
    IMasterChef public immutable masterChef;
    IRewardsStaker public rewardsStaker;
    uint256 public masterPoolId;
    
    // Info of each user that stakes LP tokens.
    mapping (address => UserInfo) public userInfo;
   
    constructor() ERC20("ShadeDummy", "SHD") {
        shade = IERC20(0x3c88baD5dcd1EbF35a0BF9cD1AA341BB387fF73A);
        masterChef = IMasterChef(0x8b7bcce67d2566D26393A6b81cAE010762C196B2);
        lpToken = IERC20(0x3ba80AfDDcdcc301435A8fB8d198cCDb72Bc9a73);
    }
        
    // ---------- VIEWS ----------
    
    function masterPending() public view returns (uint256) {
        if (masterPoolId == 0) return 0;
        return masterChef.pendingSHADE(masterPoolId, address(this));
    }
    function shadePerSecond() public view returns (uint256) {
        if (masterPoolId == 0 || masterChef.totalAllocPoint() == 0) return 0;
        return masterChef.shadePerSecond() * masterChef.poolInfo(masterPoolId).allocPoint / masterChef.totalAllocPoint();
    }
    
    // View function to see pending SHADEs on frontend.
    function pendingSHADE(address account) public view returns (uint256) {
        UserInfo storage user = userInfo[account];
        if (user.amount == 0) return 0;
        
        uint256 _accSHADEPerShare = accSHADEPerShare;
        
        if (block.timestamp > lastRewardTime) {
            _accSHADEPerShare = _accSHADEPerShare + (masterPending() * 1e12 / lpDeposited);
        }
        return user.amount * _accSHADEPerShare / 1e12 - user.rewardDebt;
    }

    // Contract Data method for decrease number of request to contract from dApp UI
    function contractData() public view returns (
        uint256 _lpDeposited,           
        uint256 _shadePerSecond             
        ) { 
        _lpDeposited = lpDeposited; 
        _shadePerSecond = shadePerSecond();        
    }

    // User Data method for decrease number of request to contract from dApp UI
    function userData(address account) public view returns (
        UserInfo memory _userInfo,       // Balances
        uint256 _pendingSHADE,           
        uint256 _lpTokenAllowance,      
        uint256 _lpTokenBalance        
        ) {  
        _userInfo = userInfo[account]; 
        _pendingSHADE = pendingSHADE(account);
        _lpTokenAllowance = lpToken.allowance(account, address(this));
        _lpTokenBalance = lpToken.balanceOf(account);        
    }

    // ---------- MUTATIVE FUNCTIONS ----------
    //
    function updatePool() public {
        if (block.timestamp <= lastRewardTime) return;
        
        lastRewardTime = block.timestamp;
        
        if (lpDeposited == 0) return;
        
        uint256 shadeReward = masterPending();        
        
        if (shadeReward != 0) {
			uint256 oldBalance = shade.balanceOf(address(this));
            masterChef.withdraw(masterPoolId, 0);
			uint256 received = shade.balanceOf(address(this)) - oldBalance;

			if (received != shadeReward) {
				shadeReward = received;
			} 
            accSHADEPerShare += shadeReward * 1e12 / lpDeposited;           
        }      
    }

    // Deposit LP tokens to for SHADE allocation.
    function deposit(uint256 amount) public {        
        require(startTime != 0, "Not started");

        UserInfo storage user = userInfo[msg.sender];

        updatePool();

        uint256 pending = user.amount * accSHADEPerShare / 1e12 - user.rewardDebt;

        user.amount += amount;
        user.rewardDebt = user.amount * accSHADEPerShare / 1e12;

        _sendRewards(pending);
        
        lpToken.safeTransferFrom(address(msg.sender), address(this), amount);
        lpDeposited += amount;

        emit Deposit(msg.sender, amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 amount) public {  
        UserInfo storage user = userInfo[msg.sender];
        
        require(user.amount >= amount, "Not enough funds");

        updatePool();

        uint256 pending = user.amount * accSHADEPerShare / 1e12 - user.rewardDebt;
        
        user.amount -= amount;
        user.rewardDebt = user.amount * accSHADEPerShare / 1e12;

        _sendRewards(pending);

        lpDeposited -= amount;
        lpToken.safeTransfer(address(msg.sender), amount);        
        
        emit Withdraw(msg.sender, amount);
    }
    
    function claim() public {  
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount != 0, "User has 0 deposit");

        updatePool();

        uint256 pending = user.amount * accSHADEPerShare / 1e12 - user.rewardDebt;
        user.rewardDebt = user.amount * accSHADEPerShare / 1e12;

        _sendRewards(pending);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public {
        UserInfo storage user = userInfo[msg.sender];

        uint amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        //lpDeposited = lpDeposited.sub(amount);
        lpDeposited -= amount;
        lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, amount);
    }

    // Rewards could be transfered in two ways    
    function _sendRewards(uint256 pending) internal {
        uint256 shadeBal = shade.balanceOf(address(this));

        if (pending > 0 && shadeBal != 0) {
            uint256 amount = shadeBal < pending ? shadeBal : pending;            
            
            // 1. If rewardsStaker is set then all goes to 3 month lock contract
            if (address(rewardsStaker) != address(0)) {
                shade.approve(address(rewardsStaker), amount);
                bool success = rewardsStaker.stakeFrom(msg.sender, amount);  
                require(success, "Stake to lock error");
                emit Stake(msg.sender, amount);  
            } 
            // 2. If rewardsStaker not set then all goes to user
            else {
                shade.safeTransfer(msg.sender, amount);
                emit Claim(msg.sender, amount);
            } 
        }
    }

    // after set this address to non zero address all rewards will be locked for 3 month
    function setRewardsStaker(IRewardsStaker newRewardsStaker) external onlyOwner {
        rewardsStaker = newRewardsStaker;
    }

    // deposit 1 dummy token to current master chef for rewards proxy    
    function depositToMaster(uint256 pid) external onlyOwner {
        require(masterPoolId == 0, "Already deposited");  // we can deposit only once
        require(pid != 0, "Can't deposit to 0 pid"); // pid 0 already busy on current master chef

        masterPoolId = pid;

        uint256 amount = 1e18;
        _mint(address(this), amount);
        _approve(address(this), address(masterChef), amount);
        
        masterChef.deposit(pid, amount);

        startTime = block.timestamp;
        lastRewardTime = block.timestamp;

		emit DepositToMaster(masterPoolId);
    }

    // ---------- EVENTS -----------
    event Deposit(address indexed account, uint256 amount);
    event Withdraw(address indexed account, uint256 amount);
    event EmergencyWithdraw(address indexed account, uint256 amount);
    event Claim(address indexed account, uint256 amount);
    event Stake(address indexed account, uint256 amount);     
	event DepositToMaster(uint256 pid);   
}
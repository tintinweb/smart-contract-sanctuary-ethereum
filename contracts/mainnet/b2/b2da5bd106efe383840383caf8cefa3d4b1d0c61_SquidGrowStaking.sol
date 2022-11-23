/**
 *Submitted for verification at Etherscan.io on 2022-11-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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

library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

interface IReferral {
    /**
     * @dev Record referral.
     */
    function recordReferral(address user, address referrer) external;

    /**
     * @dev Get the referrer address that referred the user.
     */
    function getReferrer(address user) external view returns (address);
}

contract SquidGrowStaking is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        uint256 prevReward;     // Prev reward
    }

    // Info of each pool. This contract has several reward method. First method is one that has reward per block and Second method has fixed apr.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. Squidgrows to distribute per block.
        uint256 lastRewardBlock;  // Last block number that Squidgrows distribution occurs.
        uint256 accSquidgrowPerShare;   // Accumulated Squidgrows per share, times 1e19. See below.
        uint16 depositFeeBP;     // Deposit fee in basis points.
        uint256 lpSupply;
    }

    // The Squidgrow TOKEN!
    IERC20 public Squidgrow;
    address public feeAddress;

    // Squidgrow tokens created per block.
    uint256 public SquidgrowPerBlock;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // whitelist info for deposit fee
    mapping(address => bool) public isWhiteListed;
    // whitelist info for withdraw fee
    mapping(address => bool) public isWhiteListedForWithdraw;
    // blacklist info for reward
    mapping(address => bool) public isBlackListed;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // Squidgrow referral contract address.
    IReferral public immutable referral;
    // Referral commission rate in basis points.
    uint16 public referralCommissionRate = 200;
    // Max referral commission rate: 5%.
    uint16 public constant MAXIMUM_REFERRAL_COMMISSION_RATE = 500;
    // Max fee rate: 25%.
    uint16 public constant MAXIMUM_FEE_RATE = 2500;
    // Withdraw fee rate
    uint16 public withdrawFeeRate = 0;

    constructor(
        IERC20 _Squidgrow,
        address _feeAddress,
        IReferral _referral  
    ) {
        Squidgrow = _Squidgrow;
        feeAddress = _feeAddress;
        referral=_referral;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(IERC20 _lpToken, uint256 _allocPoint, uint16 _depositFeeBP) external onlyOwner {
        require(_depositFeeBP <= MAXIMUM_FEE_RATE, "depositFee mustn't be greater than 25%");
        _lpToken.balanceOf(address(this));
        uint256 lastRewardBlock = block.number;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accSquidgrowPerShare: 0,
            depositFeeBP: _depositFeeBP,
            lpSupply: 0
        }));
    }

    // Update the given pool's Squidgrow allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP) external onlyOwner {
        require(_depositFeeBP <= MAXIMUM_FEE_RATE, "depositFee mustn't be greater than 25%");
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        if(poolInfo[_pid].allocPoint != 0) {
            poolInfo[_pid].allocPoint = _allocPoint;
        }
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }

    // View function to see pending Squidgrows on frontend.
    function pendingSquidgrow(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accSquidgrowPerShare = pool.accSquidgrowPerShare;
        if (block.number > pool.lastRewardBlock && pool.lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 SquidgrowReward = multiplier.mul(SquidgrowPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accSquidgrowPerShare = accSquidgrowPerShare.add(SquidgrowReward.mul(1e19).div(pool.lpSupply));
        }
        return user.amount.mul(accSquidgrowPerShare).div(1e19).sub(user.rewardDebt).add(user.prevReward);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        if (pool.lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 accSquidgrowPerShare = pool.accSquidgrowPerShare;
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 SquidgrowReward = multiplier.mul(SquidgrowPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        pool.accSquidgrowPerShare = accSquidgrowPerShare.add(SquidgrowReward.mul(1e19).div(pool.lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for Squidgrow allocation.
    function deposit(uint256 _pid, uint256 _amount, address _referrer) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (_amount > 0 && address(referral) != address(0) && _referrer != address(0) && _referrer != msg.sender) {
            referral.recordReferral(msg.sender, _referrer);
        }
        uint256 pending = user.amount.mul(pool.accSquidgrowPerShare).div(1e19).sub(user.rewardDebt);
        user.prevReward = user.prevReward.add(pending);
        if (_amount > 0) {
            uint256 balancebefore=pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);
            uint256 final_amount=pool.lpToken.balanceOf(address(this)).sub(balancebefore);
            if (isWhiteListed[msg.sender] || pool.depositFeeBP == 0) {
                user.amount = user.amount.add(final_amount);
                pool.lpSupply=pool.lpSupply.add(final_amount);
            } else {
                uint256 depositFee = final_amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(final_amount).sub(depositFee);
                pool.lpSupply=pool.lpSupply.add(final_amount).sub(depositFee);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accSquidgrowPerShare).div(1e19);
    }

    // Withdraw LP tokens from Staking.
    function withdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount > 0, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accSquidgrowPerShare).div(1e19).sub(user.rewardDebt);
        user.prevReward = user.prevReward.add(pending);
        if (!isWhiteListedForWithdraw[msg.sender]) {
            uint256 withdrawFeeReward = user.prevReward.mul(withdrawFeeRate).div(10000);
            safeSquidgrowTransfer(feeAddress, withdrawFeeReward);
            user.prevReward = user.prevReward.sub(withdrawFeeReward);
            uint256 withdrawFeeStaking = user.amount.mul(withdrawFeeRate).div(10000);
            pool.lpToken.safeTransfer(feeAddress, withdrawFeeStaking);
            pool.lpSupply = pool.lpSupply.sub(withdrawFeeStaking);
            user.amount = user.amount.sub(withdrawFeeStaking);
        }
        if (user.prevReward > 0 && !isBlackListed[msg.sender]) {
            safeSquidgrowTransfer(msg.sender, user.prevReward);
            payReferralCommission(msg.sender, user.prevReward);
        }        
        pool.lpToken.safeTransfer(msg.sender, user.amount);
        pool.lpSupply=pool.lpSupply.sub(user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        user.prevReward = 0;
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        
        if (pool.lpSupply >= amount) {
            pool.lpSupply = pool.lpSupply.sub(amount);
        } else {
            pool.lpSupply = 0; 
        }
        pool.lpToken.safeTransfer(msg.sender, amount);
    }

    // Safe Squidgrow transfer function, just in case if rounding error causes pool to not have enough FOXs.
    function safeSquidgrowTransfer(address _to, uint256 _amount) internal {
        uint256 SquidgrowBal = Squidgrow.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > SquidgrowBal) {
            transferSuccess = Squidgrow.transfer(_to, SquidgrowBal);
        } else {
            transferSuccess = Squidgrow.transfer(_to, _amount);
        }
        require(transferSuccess, "safeSquidgrowTransfer: Transfer failed");
    }

    // Recover unsupported tokens that are sent accidently
    function recoverUnsupportedToken(address _addr, uint256 _amount) external onlyOwner {
        require(_addr != address(0), "non-zero address");
        IERC20(_addr).safeApprove(msg.sender, _amount);
        uint256 balance = IERC20(_addr).balanceOf(address(this));
        if (_amount > 0 && _amount <= balance) {
            IERC20(_addr).safeTransfer(msg.sender, _amount);
        }
    }

    // set fee address
    function setFeeAddress(address _feeAddress) external onlyOwner {
        require(_feeAddress != address(0),"non-zero");
        feeAddress = _feeAddress;
    }

    // update reward per block
    function updateEmissionRate(uint256 _SquidgrowPerBlock) external onlyOwner {
        massUpdatePools();
        SquidgrowPerBlock = _SquidgrowPerBlock;
    }

    // add people to whitelist for deposit fee
    function whiteList(address _addr) external onlyOwner {
        isWhiteListed[_addr] = true;
    }

    // remove people from whitelist for deposit fee
    function removeWhiteList(address _addr) external onlyOwner {
        isWhiteListed[_addr] = false;
    }

    // add people to whitelist for withdraw fee
    function whiteListForWithdraw(address _addr) external onlyOwner {
        isWhiteListedForWithdraw[_addr] = true;
    }

    // remove people from whitelist for withdraw fee
    function removeWhiteListForWithdraw(address _addr) external onlyOwner {
        isWhiteListedForWithdraw[_addr] = false;
    }

    // add people to blacklist for reward
    function blackList(address _addr) external onlyOwner {
        isBlackListed[_addr] = true;
    }

    // remove people from blacklist
    function removeBlackList(address _addr) external onlyOwner {
        isBlackListed[_addr] = false;
    }

    // get pool length
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }    
    
    // Update referral commission rate by the owner
    function setReferralCommissionRate(uint16 _referralCommissionRate) external onlyOwner {
        require(_referralCommissionRate <= MAXIMUM_REFERRAL_COMMISSION_RATE, "setReferralCommissionRate: invalid referral commission rate basis points");
        referralCommissionRate = _referralCommissionRate;
    }
    
    // Update referral commission rate by the owner
    function setWithdrawFeeRate(uint16 _withdrawFeeRate) external onlyOwner {
        require(_withdrawFeeRate <= MAXIMUM_FEE_RATE, "WithdrawFeeRate mustn't be greater than 25%");
        withdrawFeeRate = _withdrawFeeRate;
    }

    // Pay referral commission to the referrer who referred this user.
    function payReferralCommission(address _user, uint256 _pending) internal {
        if (address(referral) != address(0) && referralCommissionRate > 0) {
            address referrer = referral.getReferrer(_user);
            uint256 commissionAmount = _pending.mul(referralCommissionRate).div(10000);

            if (referrer != address(0) && commissionAmount > 0) {
                safeSquidgrowTransfer(referrer, commissionAmount);
            }
        }
    }
}
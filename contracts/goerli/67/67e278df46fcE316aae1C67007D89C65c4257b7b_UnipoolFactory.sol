/**
 *Submitted for verification at Etherscan.io on 2023-01-16
*/

pragma solidity ^0.5.0;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
    function allowance(address owner, address spender) external view returns (uint256);

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

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following 
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
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

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library UnstructuredStorage {
    function getStorageBool(bytes32 position) internal view returns (bool data) {
        assembly {data := sload(position)}
    }

    function getStorageAddress(bytes32 position) internal view returns (address data) {
        assembly {data := sload(position)}
    }

    function getStorageBytes32(bytes32 position) internal view returns (bytes32 data) {
        assembly {data := sload(position)}
    }

    function getStorageUint256(bytes32 position) internal view returns (uint256 data) {
        assembly {data := sload(position)}
    }

    function setStorageBool(bytes32 position, bool data) internal {
        assembly {sstore(position, data)}
    }

    function setStorageAddress(bytes32 position, address data) internal {
        assembly {sstore(position, data)}
    }

    function setStorageBytes32(bytes32 position, bytes32 data) internal {
        assembly {sstore(position, data)}
    }

    function setStorageUint256(bytes32 position, uint256 data) internal {
        assembly {sstore(position, data)}
    }
}

contract ReentrancyGuard {
    using UnstructuredStorage for bytes32;

    /* Hardcoded constants to save gas
    bytes32 internal constant REENTRANCY_MUTEX_POSITION = keccak256("aragonOS.reentrancyGuard.mutex");
    */
    bytes32 private constant REENTRANCY_MUTEX_POSITION = 0xe855346402235fdd185c890e68d2c4ecad599b88587635ee285bce2fda58dacb;

    string private constant ERROR_REENTRANT = "REENTRANCY_REENTRANT_CALL";

    modifier nonReentrant() {
        // Ensure mutex is unlocked
        require(!REENTRANCY_MUTEX_POSITION.getStorageBool(), ERROR_REENTRANT);

        // Lock mutex before function call
        REENTRANCY_MUTEX_POSITION.setStorageBool(true);

        // Perform function call
        _;

        // Unlock mutex after function call
        REENTRANCY_MUTEX_POSITION.setStorageBool(false);
    }
}

/**
* @dev When creating a subcontract, we recommend overriding the _internal_ functions that you want to hook.
*/
contract TokenManagerHook is ReentrancyGuard {

    using UnstructuredStorage for bytes32;

    /* Hardcoded constants to save gas
    bytes32 public constant TOKEN_MANAGER_POSITION = keccak256("hookedTokenManager.tokenManagerHook.tokenManager");
    */
    bytes32 private constant TOKEN_MANAGER_POSITION = 0x5c513b2347f66d33af9d68f4a0ed7fbb73ce364889b2af7f3ee5764440da6a8a;

    modifier onlyTokenManager() {
        require(getTokenManager() == msg.sender, "Hooks must be called from Token Manager");
        _;
    }

    function getTokenManager() public returns (address) {
        return TOKEN_MANAGER_POSITION.getStorageAddress();
    }

    /*
    * @dev Called when this contract has been included as a Token Manager hook, must be called in the transaction
    *   this contract is created or it risks some other address registering itself as the Token Manager
    * @param _hookId The position in which the hook is going to be called
    * @param _token The token controlled by the Token Manager
    */
    function onRegisterAsHook(uint256 _hookId, address _token) external nonReentrant {
        require(getTokenManager() == address(0), "Hook already registered by Token Manager");
        TOKEN_MANAGER_POSITION.setStorageAddress(msg.sender);
        _onRegisterAsHook(msg.sender, _hookId, _token);
    }

    /*
    * @dev Called when this hook is being removed from the Token Manager
    * @param _hookId The position in which the hook is going to be called
    * @param _token The token controlled by the Token Manager
    */
    function onRevokeAsHook(uint256 _hookId, address _token) external onlyTokenManager nonReentrant {
        _onRevokeAsHook(msg.sender, _hookId, _token);
    }

    /*
    * @dev Notifies the hook about a token transfer allowing the hook to react if desired. It should return
    * true if left unimplemented, otherwise it will prevent some functions in the TokenManager from
    * executing successfully.
    * @param _from The origin of the transfer
    * @param _to The destination of the transfer
    * @param _amount The amount of the transfer
    */
    function onTransfer(address _from, address _to, uint256 _amount) external onlyTokenManager nonReentrant returns (bool) {
        return _onTransfer(_from, _to, _amount);
    }

    /*
    * @dev Notifies the hook about an approval allowing the hook to react if desired. It should return
    * true if left unimplemented, otherwise it will prevent some functions in the TokenManager from
    * executing successfully.
    * @param _holder The account that is allowing to spend
    * @param _spender The account that is allowed to spend
    * @param _amount The amount being allowed
    */
    function onApprove(address _holder, address _spender, uint _amount) external onlyTokenManager nonReentrant returns (bool) {
        return _onApprove(_holder, _spender, _amount);
    }

    // Function to override if necessary:

    function _onRegisterAsHook(address _tokenManager, uint256 _hookId, address _token) internal {
        return;
    }

    function _onRevokeAsHook(address _tokenManager, uint256 _hookId, address _token) internal {
        return;
    }

    function _onTransfer(address _from, address _to, uint256 _amount) internal returns (bool) {
        return true;
    }

    function _onApprove(address _holder, address _spender, uint _amount) internal returns (bool) {
        return true;
    }
}

contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private _totalSupply;
    mapping(address => uint256) internal _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount, address user) internal {
        _totalSupply = _totalSupply.add(amount);
        _balances[user] = _balances[user].add(amount);
    }

    function withdraw(uint256 amount, address user) internal {
        _totalSupply = _totalSupply.sub(amount);
        _balances[user] = _balances[user].sub(amount);
    }
}

contract Unipool is LPTokenWrapper, TokenManagerHook {
    IERC20 public rewardToken;
    uint256 public constant DURATION = 30 days;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    constructor(IERC20 _rewardToken) public {
        require(address(_rewardToken) != address(0), "reward token not present");
        rewardToken = _rewardToken;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function stake(uint256 amount, address user) internal updateReward(user) {
        require(amount > 0, "Cannot stake 0");
        super.stake(amount, user);
        emit Staked(user, amount);
    }

    function withdraw(uint256 amount, address user) internal updateReward(user) {
        require(amount > 0, "Cannot withdraw 0");
        super.withdraw(amount, user);
        if (_balances[user] == 0) {
            _getReward(user);
        }
        emit Withdrawn(user, amount);
    }

    function getReward() external updateReward(msg.sender){
        _getReward(msg.sender);
    }

    function _getReward(address user) internal {
        uint256 reward = earned(user);
        if (reward > 0) {
            rewards[user] = 0;
            rewardToken.safeTransfer(user, reward);
            emit RewardPaid(user, reward);
        }
    }

    function notifyRewardAmount(uint256 _amount)
        external
        updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = _amount.div(DURATION);
        } else {
            uint256 remainingTime = periodFinish.sub(block.timestamp);
            uint256 leftoverReward = remainingTime.mul(rewardRate);
            uint256 newRewardRate = _amount.add(leftoverReward).div(DURATION);
            require(newRewardRate >= rewardRate, "New reward rate too low");
            rewardRate = newRewardRate;
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);

        rewardToken.safeTransferFrom(msg.sender, address(this), _amount);

        emit RewardAdded(_amount);
    }

    /**
     * @dev Overrides TokenManagerHook's `_onTransfer`
     */
    function _onTransfer(address _from, address _to, uint256 _amount) internal returns (bool) {
        if (_from == address(0)) { // Token mintings (wrapping tokens)
            stake(_amount, _to);
            return true;
        } else if (_to == address(0)) { // Token burning (unwrapping tokens)
            withdraw(_amount, _from);
            return true;
        } else { // Standard transfer
            withdraw(_amount, _from);
            stake(_amount, _to);
            return true;
        }
    }
}

contract UnipoolRewardDepositor {
    using SafeERC20 for IERC20;

    Unipool public unipool;
    IERC20 public rewardToken;

    constructor(Unipool _unipool, IERC20 _rewardToken) public {
        unipool = _unipool;
        rewardToken = _rewardToken;
    }

    function transfer() public {
        rewardToken.safeIncreaseAllowance(address(unipool), rewardToken.balanceOf(address(this)));
        unipool.notifyRewardAmount(rewardToken.balanceOf(address(this)));
    }
}

// Rinkeby deployment: 0x710D70591C70B1aA96d558269193F0e59F52E154
// xDai deployment: 0xD38EB36B7E8b126Ff1E9fDD007bC4050B6C6aB7c
// Goerli deployment: 0x67e278df46fce316aae1c67007d89c65c4257b7b
contract UnipoolFactory {
    event NewUnipool(Unipool unipool);
    event NewRewardDepositor(UnipoolRewardDepositor unipoolRewardDepositor);

    function newUnipool(IERC20 _rewardToken) public returns (Unipool) {
        Unipool unipool = new Unipool(_rewardToken);
        emit NewUnipool(unipool);

        return unipool;
    }

    function newUnipoolWithDepositor(IERC20 _rewardToken)
        public
        returns (Unipool, UnipoolRewardDepositor)
    {
        Unipool unipool = newUnipool(_rewardToken);
        UnipoolRewardDepositor unipoolRewardDepositor = new UnipoolRewardDepositor(
                unipool,
                _rewardToken
            );
        emit NewRewardDepositor(unipoolRewardDepositor);

        return (unipool, unipoolRewardDepositor);
    }
}
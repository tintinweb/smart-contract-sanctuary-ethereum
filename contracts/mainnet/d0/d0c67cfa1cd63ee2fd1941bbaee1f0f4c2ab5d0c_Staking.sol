/**
 *Submitted for verification at Etherscan.io on 2022-04-16
*/

/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
       _;
        _status = _NOT_ENTERED;
    }
}

library AddressUpgradeable {
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
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

library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

interface IERC20Upgradeable {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

contract Staking is OwnableUpgradeable, ReentrancyGuard{
    using SafeMathUpgradeable for uint256;

    IERC20Upgradeable StakingToken;
    address private stakingTokenAddress;

    uint256 private _DECIMALS;

    address private _admin;
    uint256 private _MIN_STAKE_AMOUNT;
    uint256 private _MAX_STAKE_AMOUNT;
    uint256 private _REWARD_CYCLE;
    uint256 private _REWARD_RATE;
    uint256 private _currentStakedAmount;
    uint256 private _stakingCount;
    uint256 private _stakingstartdate; // start date for staking
    uint256 private _firstphase;
    uint256 private _secondphase;
    uint256 private _thirdphase;
    uint256 private _fourthphase;

    struct Stake {
        uint256 id;
        address staker;
        uint256 amount;
        uint256 stakeTimeStamp;
        uint256 lastClaimTimeStamp;
        bool staking;
        uint256 REWARDS_RATE;
    }

    mapping(address => Stake[]) private stakerToStakes;
    mapping(uint256 => Stake) private idToStake;
    uint256 private stakeId;

    function initialize() public initializer{
        __Ownable_init();
        stakingTokenAddress = 0xd718Ad25285d65eF4D79262a6CD3AEA6A8e01023;
        StakingToken = IERC20Upgradeable(0xd718Ad25285d65eF4D79262a6CD3AEA6A8e01023);
        _admin = 0xd0d725208fd36BE1561050Fc1DD6a651d7eA7C89;
        _DECIMALS = 18;
        _MIN_STAKE_AMOUNT = 10 * 10 ** _DECIMALS;
        _MAX_STAKE_AMOUNT = 2500 * 10 ** _DECIMALS;
        _REWARD_CYCLE = 30 days;    // default 30 days
        _currentStakedAmount = 0;
        _stakingCount = 0;
        stakeId = 0;
        _stakingstartdate = block.timestamp;
        _firstphase = 30 days;
        _secondphase = 90 days;
        _thirdphase = 240 days;
        _fourthphase = 361 days;
    }

    //--------------------------------------------------------------------
    //-------------------------- Set Values Machine ----------------------
    //--------------------------------------------------------------------
    function setMinStakeAmount (uint256 _minAmount) external {
        require(msg.sender ==  _admin, "You are not Admin!");
        _MIN_STAKE_AMOUNT = _minAmount * 10 ** _DECIMALS;
    }

    function setMaxStakeAmount (uint256 _maxAmount) external {
        require(msg.sender ==  _admin, "You are not Admin!");
        _MAX_STAKE_AMOUNT = _maxAmount * 10 ** _DECIMALS;
    }

    function setRewardsCycle (uint256 _cycle) external {
        require(msg.sender ==  _admin, "You are not Admin!");
        _REWARD_CYCLE = _cycle;
    }

    function setFirstPeriod (uint256 _cycle) external {
        require(msg.sender ==  _admin, "You are not Admin!");
        _firstphase = _cycle;
    }

    function setSecondPeriod (uint256 _cycle) external {
        require(msg.sender ==  _admin, "You are not Admin!");
        _secondphase = _cycle;
    }

    function setThirdPeriod (uint256 _cycle) external {
        require(msg.sender ==  _admin, "You are not Admin!");
        _thirdphase = _cycle;
    }

    function setFourthPeriod (uint256 _cycle) external {
        require(msg.sender ==  _admin);
        _fourthphase = _cycle;
    }

    //--------------------------------------------------------------------
    //-------------------------- Staking Machine -------------------------
    //--------------------------------------------------------------------

    function stakeToken(uint256 _amount) external nonReentrant {
        require(StakingToken.allowance(msg.sender, address(this)) >= _amount, "Enough amount not approved.");
    
        StakingToken.transferFrom(msg.sender, address(this), _amount);

        Stake memory newStake;
        newStake.id = stakeId;
        newStake.staker = msg.sender;
        newStake.amount = _amount;
        newStake.stakeTimeStamp = block.timestamp;
        newStake.lastClaimTimeStamp = block.timestamp;
        newStake.staking = true;
        
        if(block.timestamp - _stakingstartdate < _firstphase) {
            newStake.REWARDS_RATE = 37*10**17;
        } else if(block.timestamp - _stakingstartdate > _firstphase && block.timestamp - _stakingstartdate < (_firstphase+_secondphase)) {
            newStake.REWARDS_RATE = 17*10*17;
        } else if(block.timestamp - _stakingstartdate > (_firstphase+_secondphase) && block.timestamp - _stakingstartdate < (_firstphase+_secondphase+_thirdphase)) {
            newStake.REWARDS_RATE = 69*10*16;
        } else if(block.timestamp - _stakingstartdate > (_firstphase+_secondphase+_thirdphase) && block.timestamp - _stakingstartdate < (_firstphase+_secondphase+_thirdphase+_fourthphase)) {
            newStake.REWARDS_RATE = 37*10*16;
        }
        idToStake[stakeId] = newStake;
        stakeId = stakeId.add(1);
        _currentStakedAmount = _currentStakedAmount.add(_amount);

        stakerToStakes[msg.sender].push(newStake);
        _stakingCount = _stakingCount.add(1);
    }

    function claimReward(uint256 _id) external nonReentrant{
        require(idToStake[_id].staker == msg.sender, "Caller is not staker.");
        require(idToStake[_id].staking == true, "This staking have been finished.");
        require(block.timestamp - idToStake[_id].lastClaimTimeStamp >= _REWARD_CYCLE, "Reward is pending...");

        uint256 stakingTime = block.timestamp - idToStake[_id].lastClaimTimeStamp; // staking time by selected Id
        uint256 claimableCycle = stakingTime.sub(stakingTime.mod(_REWARD_CYCLE)).div(_REWARD_CYCLE);
        uint256 rewardAmount = idToStake[_id].amount.div(_currentStakedAmount).mul(idToStake[_id].REWARDS_RATE).mul(6500).mul(claimableCycle);

        StakingToken.transfer(msg.sender, rewardAmount);
        idToStake[_id].lastClaimTimeStamp = block.timestamp;
    }

    function unStake(uint256 _id) external nonReentrant {
        require(idToStake[_id].staker == msg.sender, "Caller is not staker.");
        require(idToStake[_id].staking == true, "This staking have been finished.");
        
        StakingToken.transfer(msg.sender, idToStake[_id].amount);

        idToStake[_id].staking = false;
        removeFinishedStake(msg.sender, _id);
        _currentStakedAmount = _currentStakedAmount.sub(idToStake[_id].amount);
        _stakingCount = _stakingCount.sub(1);
    }

    //--------------------------------------------------------------------
    //-------------------------- Views -----------------------------------
    //--------------------------------------------------------------------

    function getStakingTokenBalance () public view returns (uint256) {
        return StakingToken.balanceOf(address(this));
    }

    function getCurrentStakedAmount () public view returns (uint256) {
        return _currentStakedAmount;
    }

    function getStakeInfo (uint256 _id) public view returns (uint256, address, uint256, uint256, uint256, bool) {
        return (
            idToStake[_id].id,
            idToStake[_id].staker,
            idToStake[_id].amount,
            idToStake[_id].stakeTimeStamp,
            idToStake[_id].lastClaimTimeStamp,
            idToStake[_id].staking
        );
    }

    function getStakingCount () public view returns (uint256) {
        return _stakingCount;
    }

    function getStakesByStaker (address _staker) public view returns (Stake[] memory) {
        return stakerToStakes[_staker];
    } 

    function getClaimable (uint256 _id) public view returns (uint256) {
        bool claimable_ = block.timestamp - idToStake[_id].lastClaimTimeStamp >= _REWARD_CYCLE;
        if(claimable_) {
            uint256 stakingTime = block.timestamp - idToStake[_id].lastClaimTimeStamp;
            uint256 claimableCycle = stakingTime.sub(stakingTime.mod(_REWARD_CYCLE)).div(_REWARD_CYCLE);
            uint256 rewardAmount = idToStake[_id].amount.div(_currentStakedAmount).mul(idToStake[_id].REWARDS_RATE).mul(6500).mul(claimableCycle);

            return rewardAmount;
        } else {
            return 0;
        }
    }

    function getMinStakeAmount () public view returns (uint256) {
        return _MIN_STAKE_AMOUNT;
    }

    function getMaxStakeAmount () public view returns (uint256) {
        return _MAX_STAKE_AMOUNT;
    }
    //--------------------------------------------------------------------
    //-------------------------- Internal --------------------------------
    //--------------------------------------------------------------------

    function removeFinishedStake (address _staker, uint256 _id) internal {
        for (uint256 i = 0; i < stakerToStakes[_staker].length; i++) {
            if(stakerToStakes[_staker][i].id == _id) {
                stakerToStakes[_staker][i] = stakerToStakes[_staker][stakerToStakes[_staker].length - 1];
                stakerToStakes[_staker].pop();
            }
        }
    }
}
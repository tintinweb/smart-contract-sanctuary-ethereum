/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// import "../extensions/IERC20Permit.sol";

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

// pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// import "../../../utils/Address.sol";

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return (returndata);
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
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

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// import '@openzeppelin/contracts/access/Ownable.sol';
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// pragma solidity ^0.8.0;

// import "../utils/Context.sol";
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}

interface IToken {
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
}

contract InvisiCashStaking is Ownable {
    using SafeERC20 for IERC20;

    // Whether it is initialized
    bool public isInitialized;
    uint256 public duration = 365; // 365 days

    // The staked token
    IERC20 public stakingToken;
    IERC20 public earnedToken;

    uint256 public totalStaked;

    uint256 private totalEarned;

    struct Lockup {
        uint8 stakeType;
        uint256 duration;
        uint256 rate;
        uint256 totalStaked;
    }

    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256 locked;
        uint256 available;
    }

    struct Stake {
        uint8   stakeType;
        uint256 amount;     // amount to stake
        uint256 end;        // when does the staking period end
        uint256 lastRewardBlock;
    }

    uint256 constant MAX_STAKES = 256;

    Lockup[] public lockups;
    mapping(address => Stake[]) public userStakes;

    event Deposit(address indexed user, uint256 stakeType, uint256 amount);
    event Withdraw(address indexed user, uint256 stakeType, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event AdminTokenRecovered(address tokenRecovered, uint256 amount);
    event LockupUpdated(uint8 _type, uint256 _duration, uint256 _rate);

    constructor() {}

    /*
     * @notice Initialize the contract
     * @param _stakingToken: staked token address
     * @param _earnedToken: earned token address
     */
    function initialize(
        IERC20 _stakingToken,
        IERC20 _earnedToken
    ) external onlyOwner {
        require(!isInitialized, "Already initialized");

        // Make this contract initialized
        isInitialized = true;

        stakingToken = _stakingToken;
        earnedToken = _earnedToken;

        lockups.push(Lockup(0, 0, 40, 0));
        lockups.push(Lockup(1, 15, 44, 0));
        lockups.push(Lockup(2, 30, 48, 0));
        lockups.push(Lockup(3, 60, 52, 0));
        lockups.push(Lockup(4, 90, 56, 0));
    }

    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to withdraw (in earnedToken)
     */
    function deposit(uint256 _amount, uint8 _stakeType) external {
        require(_amount > 0, "Amount should be greator than 0");
        require(_stakeType < lockups.length, "Invalid stake type");

        Lockup storage lockup = lockups[_stakeType];

        stakingToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        
        _addStake(_stakeType, msg.sender, lockup.duration, _amount);

        lockup.totalStaked = lockup.totalStaked + _amount;
        totalStaked = totalStaked + _amount;

        emit Deposit(msg.sender, _stakeType, _amount);
    }

    function _addStake(uint8 _stakeType, address _account, uint256 _duration, uint256 _amount) internal {
        Stake[] storage stakes = userStakes[_account];

        uint256 end = block.timestamp + _duration * 1 days;
        uint256 i = stakes.length;

        stakes.push(); // grow the array

        // insert the stake
        Stake storage newStake = stakes[i];
        newStake.stakeType = _stakeType;
        newStake.end = end;
        newStake.amount = _amount;
        newStake.lastRewardBlock = block.timestamp;
    }

    function claimReward(uint8 _stakeType) public {
        if(_stakeType >= lockups.length) return;

        Stake[] storage stakes = userStakes[msg.sender];
        Lockup storage lockup = lockups[_stakeType];

        uint256 pending = 0;
        for(uint256 j = 0; j < stakes.length; j++) {
            Stake storage stake = stakes[j];
            if(stake.stakeType != _stakeType) continue;
            if(stake.amount == 0) continue;

            pending = pending + (stake.amount * ((block.timestamp - stake.lastRewardBlock) / 1 minutes ) / 1440 * lockup.rate / duration / 100);

            stake.lastRewardBlock = block.timestamp;
        }

        if (pending > 0) {
            require(availableRewardTokens() >= pending, "Insufficient reward tokens");
            earnedToken.safeTransfer(address(msg.sender), pending);
            _updateEarned(pending);
        }
    }

    /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in earnedToken)
     */
    function withdraw(uint256 _amount, uint8 _stakeType) external {
        require(_amount > 0, "Amount should be greator than 0");
        require(_stakeType < lockups.length, "Invalid stake type");

        Stake[] storage stakes = userStakes[msg.sender];
        Lockup storage lockup = lockups[_stakeType];
        
        uint256 remained = _amount;

        claimReward(_stakeType);

        for(uint256 j = 0; j < stakes.length; j++) {
            Stake storage stake = stakes[j];
            if(stake.stakeType != _stakeType) continue;
            if(stake.amount == 0) continue;
            if(stake.end > block.timestamp) continue;
            if(remained == 0) break;
            if(stake.amount > remained) {
                stake.amount = stake.amount - remained;
                remained = 0;
            } else {
                remained = remained - stake.amount;
                stake.amount = 0;
            }
        }

        uint256 realAmount = _amount - remained;

        lockup.totalStaked = lockup.totalStaked - realAmount;
        totalStaked = totalStaked - realAmount;
        stakingToken.safeTransfer(address(msg.sender), realAmount);

        emit Withdraw(msg.sender, _stakeType, realAmount);
    }

    /*
     * @notice Withdraw staked tokens without caring about rewards
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw(uint8 _stakeType) external {
        if(_stakeType >= lockups.length) return;

        Stake[] storage stakes = userStakes[msg.sender];
        Lockup storage lockup = lockups[_stakeType];

        uint256 amountToTransfer = 0;
        for(uint256 j = 0; j < stakes.length; j++) {
            Stake storage stake = stakes[j];
            if(stake.stakeType != _stakeType) continue;
            if(stake.amount == 0) continue;

            amountToTransfer = amountToTransfer + stake.amount;

            stake.amount = 0;
            stake.lastRewardBlock = block.timestamp;
        }

        if (amountToTransfer > 0) {
            stakingToken.safeTransfer(address(msg.sender), amountToTransfer);

            lockup.totalStaked = lockup.totalStaked - amountToTransfer;
            totalStaked = totalStaked - amountToTransfer;
        }

        emit EmergencyWithdraw(msg.sender, amountToTransfer);
    }

    /**
     * @notice Available amount of reward token
     */
    function availableRewardTokens() public view returns (uint256) {
        uint256 _amount = earnedToken.balanceOf(address(this));
        if (address(earnedToken) == address(stakingToken)) {
            if (_amount < totalStaked) return 0;
            return _amount - totalStaked;
        }

        return _amount;
    }

    function userInfo(uint8 _stakeType, address _account) external view returns (uint256 amount, uint256 available, uint256 locked) {
        Stake[] memory stakes = userStakes[_account];
        
        for(uint256 i = 0; i < stakes.length; i++) {
            Stake memory stake = stakes[i];

            if(stake.stakeType != _stakeType) continue;
            if(stake.amount == 0) continue;
            
            amount = amount + stake.amount;
            if(block.timestamp > stake.end) {
                available = available + stake.amount;
            } else {
                locked = locked + stake.amount;
            }
        }
    }

    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(address _account, uint8 _stakeType) external view returns (uint256) {
        require(_stakeType < lockups.length, "Lockup Not found");

        Stake[] memory stakes = userStakes[_account];
        Lockup memory lockup = lockups[_stakeType];

        if(lockup.totalStaked == 0) return 0;
        
        uint256 pending = 0;
        for(uint256 i = 0; i < stakes.length; i++) {
            Stake memory stake = stakes[i];
            if(stake.stakeType != _stakeType) continue;
            if(stake.amount == 0) continue;

            pending = pending + (stake.amount * ((block.timestamp - stake.lastRewardBlock) / 1 minutes ) / 1440 * lockup.rate / duration / 100);
        }
        return pending;
    }

    /************************
    ** Admin Methods
    *************************/
   
    /*
     * @notice Deposit reward token
     * @dev Only call by owner. Needs to be for deposit of reward token when reflection token is same with reward token.
     */
    function depositRewards(uint _amount) external onlyOwner {
        require(_amount > 0, "invalid amount");

        uint256 beforeAmt = earnedToken.balanceOf(address(this));
        earnedToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 afterAmt = earnedToken.balanceOf(address(this));

        totalEarned = totalEarned + afterAmt - beforeAmt;
    }

    /*
     * @notice Withdraw reward token
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        require(availableRewardTokens() >= _amount, "Insufficient reward tokens");

        earnedToken.safeTransfer(address(msg.sender), _amount);        
        if (totalEarned > 0) {
            if (_amount > totalEarned) {
                totalEarned = 0;
            } else {
                totalEarned = totalEarned - _amount;
            }
        }
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(
            _tokenAddress != address(earnedToken),
            "Cannot be reward token"
        );

        if(_tokenAddress == address(stakingToken)) {
            uint256 tokenBal = stakingToken.balanceOf(address(this));
            require(_tokenAmount <= tokenBal - totalStaked, "Insufficient balance");
        }

        if(_tokenAddress == address(0x0)) {
            payable(msg.sender).transfer(_tokenAmount);
        } else {
            IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);
        }

        emit AdminTokenRecovered(_tokenAddress, _tokenAmount);
    }

    function updateLockup(uint8 _stakeType, uint256 _duration, uint256 _rate) external onlyOwner {
        // require(block.number < startBlock, "Pool was already started");
        require(_stakeType < lockups.length, "Lockup Not found");

        Lockup storage _lockup = lockups[_stakeType];
        _lockup.duration = _duration;
        _lockup.rate = _rate;
        
        emit LockupUpdated(_stakeType, _duration, _rate);
    }

    function addLockup(uint256 _duration, uint256 _rate) external onlyOwner {
        lockups.push();
        
        Lockup storage _lockup = lockups[lockups.length - 1];
        _lockup.duration = _duration;
        _lockup.rate = _rate;

        emit LockupUpdated(uint8(lockups.length - 1), _duration, _rate);
    }


    /************************
    ** Internal Methods
    *************************/
    /*
     * @notice Update reward variables of the given pool to be up-to-date.
     */

    function _transferToken(address _token, address _to, uint256 _amount) internal {
        if(_token == address(0x0)) {
            payable(_to).transfer(_amount);
        } else {
            IERC20(_token).transfer(_to, _amount);
        }
    }

    function _updateEarned(uint256 _amount) internal {
        if(totalEarned > _amount) {
            totalEarned = totalEarned - _amount;
        } else {
            totalEarned = 0;
        }
    }

    receive() external payable {}
}
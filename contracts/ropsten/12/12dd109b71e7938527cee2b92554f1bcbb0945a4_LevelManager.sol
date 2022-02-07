/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


//                                        INTERFACES


interface ILevelsStaking {
    function getTierById(string calldata id) external view returns (Structs.Tier memory);
    function getUserTier(address account) external view returns (Structs.Tier memory);
    function getTierIds() external view returns (string[] memory);
    function lock(address account) external;
}


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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


//                                        LIBRARIES


library Structs {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 pendingRewards;
        uint256 unlocksAt;
    }

    struct Tier {
        string id;
        uint8 multiplier;
        uint256 lockingPeriod; // in seconds
        uint256 minAmount; // tier is applied when userAmount >= minAmount
        bool random;
        uint8 odds; // divider: 2 = 50%, 4 = 25%, 10 = 10%
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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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


//                                        CONTRACTS


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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


abstract contract Stakeable is Ownable {
    using SafeERC20 for IERC20;

    struct PoolInfo {
        IERC20 stakingToken;
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
    }

    mapping(address => Structs.UserInfo) public userInfo;

    IERC20 public rewardToken;
    uint256 public rewardPerBlock = 1 * 1e9; // 1 token
    uint256 private divider = 1e12;

    // Keeps reward tokens
    StakingTreasury public treasury;

    // base 1000, value * % / 100
    uint256 public feePercent = 0;
    uint256 public collectedFees;

    PoolInfo public liquidityMining;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Claim(address indexed user, uint256 amount);

    constructor() {
        treasury = new StakingTreasury();
    }

    function setPoolInfo(IERC20 _rewardToken, IERC20 _stakingToken) external onlyOwner {
        require(address(rewardToken) == address(0) && address(liquidityMining.stakingToken) == address(0), 'Token is already set');
        rewardToken = _rewardToken;
        liquidityMining = PoolInfo({stakingToken : _stakingToken, lastRewardBlock : 0, accRewardPerShare : 0});
        treasury.allowClaiming(_rewardToken);
    }

    function startMining() external onlyOwner {
        require(liquidityMining.lastRewardBlock == 0, 'Mining already started');
        liquidityMining.lastRewardBlock = block.number;
    }

    function pendingRewards(address _user) external view returns (uint256) {
        if (liquidityMining.lastRewardBlock == 0 || block.number < liquidityMining.lastRewardBlock) {
            return 0;
        }

        Structs.UserInfo storage user = userInfo[_user];
        uint256 accRewardPerShare = liquidityMining.accRewardPerShare;
        uint256 stakingTokenSupply = liquidityMining.stakingToken.balanceOf(address(this));

        if (block.number > liquidityMining.lastRewardBlock && stakingTokenSupply != 0) {
            uint256 perBlock = rewardPerBlock;
            uint256 multiplier = block.number - liquidityMining.lastRewardBlock;
            uint256 reward = multiplier * perBlock;
            accRewardPerShare = accRewardPerShare + (reward * divider / stakingTokenSupply);
        }

        return (user.amount * accRewardPerShare / divider) - user.rewardDebt + user.pendingRewards;
    }

    function updatePool() internal {
        require(liquidityMining.lastRewardBlock > 0 && block.number >= liquidityMining.lastRewardBlock, 'Mining not yet started');
        if (block.number <= liquidityMining.lastRewardBlock) {
            return;
        }
        uint256 stakingTokenSupply = liquidityMining.stakingToken.balanceOf(address(this));
        if (stakingTokenSupply == 0) {
            liquidityMining.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = block.number - liquidityMining.lastRewardBlock;
        uint256 tokensReward = multiplier * rewardPerBlock;
        liquidityMining.accRewardPerShare = liquidityMining.accRewardPerShare + (tokensReward * divider / stakingTokenSupply);
        liquidityMining.lastRewardBlock = block.number;
    }

    function deposit(uint256 amount) public virtual {
        Structs.UserInfo storage user = userInfo[msg.sender];
        updatePool();

        uint256 accRewardPerShare = liquidityMining.accRewardPerShare;

        if (user.amount > 0) {
            uint256 pending = (user.amount * accRewardPerShare / divider) - user.rewardDebt;
            if (pending > 0) {
                user.pendingRewards = user.pendingRewards + pending;
            }
        }
        if (amount > 0) {
            liquidityMining.stakingToken.safeTransferFrom(address(msg.sender), address(this), amount);

            if (feePercent > 0) {
                uint256 fee = amount * feePercent / 1000;
                amount = amount - fee;
                collectedFees = collectedFees + fee;
            }

            user.amount = user.amount + amount;
        }
        user.rewardDebt = user.amount * accRewardPerShare / divider;
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) public virtual {
        Structs.UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= amount, "Withdrawing more than you have!");
        updatePool();

        uint256 accRewardPerShare = liquidityMining.accRewardPerShare;

        uint256 pending = (user.amount * accRewardPerShare / divider) - user.rewardDebt;
        if (pending > 0) {
            user.pendingRewards = user.pendingRewards + pending;
        }
        if (amount > 0) {
            user.amount = user.amount - amount;

            if (feePercent > 0) {
                uint256 fee = amount * feePercent / 1000;
                amount = amount - fee;
                collectedFees = collectedFees + fee;
            }

            liquidityMining.stakingToken.safeTransfer(address(msg.sender), amount);
        }
        user.rewardDebt = user.amount * accRewardPerShare / divider;
        emit Withdraw(msg.sender, amount);
    }

    function claim() external {
        Structs.UserInfo storage user = userInfo[msg.sender];
        updatePool();

        uint256 accRewardPerShare = liquidityMining.accRewardPerShare;

        uint256 pending = (user.amount * accRewardPerShare / divider) - user.rewardDebt;
        if (pending > 0 || user.pendingRewards > 0) {
            user.pendingRewards = user.pendingRewards + pending;
            uint256 claimedAmount = safeRewardTransfer(msg.sender, user.pendingRewards);
            emit Claim(msg.sender, claimedAmount);
            user.pendingRewards = user.pendingRewards - claimedAmount;
        }
        user.rewardDebt = user.amount * accRewardPerShare / divider;
    }

    function safeRewardTransfer(address to, uint256 amount) internal returns (uint256) {
        uint256 balance = rewardToken.balanceOf(address(treasury));
        require(amount > 0, 'Reward amount must be more than zero');
        require(balance > 0, 'Not enough reward tokens for transfer');
        if (amount > balance) {
            rewardToken.safeTransferFrom(address(treasury), to, balance);
            return balance;
        }

        rewardToken.safeTransferFrom(address(treasury), to, amount);
        return amount;
    }

    function setRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        require(_rewardPerBlock > 0, "Reward per block should be greater than 0");
        rewardPerBlock = _rewardPerBlock;
    }

    function setFee(uint256 fee) external onlyOwner {
        require(fee >= 0, 'Fee is too small');
        require(fee <= 50, 'Fee is too big');
        feePercent = fee;
    }

    function withdrawFees(address payable withdrawalAddress) external onlyOwner {
        liquidityMining.stakingToken.safeTransfer(withdrawalAddress, collectedFees);
        collectedFees = 0;
    }
}


contract StakingTreasury is Ownable {
    function allowClaiming(IERC20 _rewardToken) external onlyOwner {
        _rewardToken.approve(this.owner(), 100000000 ether);
    }
}


abstract contract WithLevels is Ownable, ILevelsStaking {
    string constant noneTierId = "none";

    Structs.Tier[] public tiers;

    event TierCreate(string indexed id, uint8 multiplier, uint256 lockingPeriod, uint256 minAmount, bool random, uint8 odds);
    event TierUpdate(string indexed id, uint8 multiplier, uint256 lockingPeriod, uint256 minAmount, bool random, uint8 odds);
    event TierRemove(string indexed id, uint256 idx);

    constructor() {
        tiers.push(Structs.Tier(noneTierId, 0, 0, 0, false, 0));
    }

    function getTierIds() external view override returns (string[] memory) {
        string[] memory ids = new string[](tiers.length);
        for (uint i = 0; i < tiers.length; i++) {
            ids[i] = tiers[i].id;
        }

        return ids;
    }

    function getTierById(string calldata id) public view override returns (Structs.Tier memory) {
        for (uint256 i = 0; i < tiers.length; i++) {
            if (stringsEqual(tiers[i].id, id)) {
                return tiers[i];
            }
        }
        revert('No such tier');
    }

    function getTierForAmount(uint amount) internal view returns (Structs.Tier memory) {
        return tiers[getTierIdxForAmount(amount)];
    }

    function getTierIdxForAmount(uint amount) internal view returns (uint) {
        if (amount == 0) {
            return 0;
        }
        uint maxTierK = 0;
        uint256 maxTierV;
        for (uint i = 1; i < tiers.length; i++) {
            Structs.Tier storage tier = tiers[i];
            if (amount >= tier.minAmount && tier.minAmount > maxTierV) {
                maxTierK = i;
                maxTierV = tier.minAmount;
            }
        }

        return maxTierK;
    }

    function setTier(string calldata id, uint8 multiplier, uint256 lockingPeriod, uint256 minAmount, bool random, uint8 odds) external onlyOwner returns (uint256) {
        require(!stringsEqual(id, noneTierId), "Can't change 'none' tier");

        for (uint256 i = 0; i < tiers.length; i++) {
            if (stringsEqual(tiers[i].id, id)) {
                tiers[i].multiplier = multiplier;
                tiers[i].lockingPeriod = lockingPeriod;
                tiers[i].minAmount = minAmount;
                tiers[i].random = random;
                tiers[i].odds = odds;

                emit TierUpdate(id, multiplier, lockingPeriod, minAmount, random, odds);

                return i;
            }
        }

        Structs.Tier memory newTier = Structs.Tier(id, multiplier, lockingPeriod, minAmount, random, odds);
        tiers.push(newTier);

        emit TierCreate(id, multiplier, lockingPeriod, minAmount, random, odds);

        return tiers.length - 1;
    }

    function deleteTier(string calldata id) external onlyOwner {
        require(!stringsEqual(id, noneTierId), "Can't delete 'none' tier");

        for (uint256 tierIdx = 0; tierIdx < tiers.length; tierIdx++) {
            if (stringsEqual(tiers[tierIdx].id, id)) {
                for (uint i = tierIdx; i < tiers.length - 1; i++) {
                    tiers[i] = tiers[i + 1];
                }
                tiers.pop();

                emit TierRemove(id, tierIdx);
                break;
            }
        }
    }

    function stringsEqual(string memory a, string memory b) private pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}


//                                        MAIN CONTRACT



contract LevelManager is Stakeable, WithLevels {
    using SafeERC20 for IERC20;

    mapping(address => bool) isIDO;
    bool public lockEnabled = true;
    bool public halted = false;

    event Lock(address indexed account, uint256 unlockTime, address locker);
    event LockEnabled(bool status);
    event Halted(bool status);

    function getUserTier(address account) external view override returns (Structs.Tier memory) {
        return getTierForAmount(userInfo[account].amount);
    }

    function getUserUnlockTime(address account) external view returns (uint) {
        return userInfo[account].unlocksAt;
    }

    function toggleLocking(bool status) external onlyOwner {
        lockEnabled = status;
        emit LockEnabled(status);
    }

    modifier onlyIDO() {
        require(isIDO[_msgSender()], "Only IDOs can lock");
        _;
    }

    modifier lockable() {
        require(!lockEnabled || userInfo[_msgSender()].unlocksAt <= block.timestamp, "Account is locked");
        _;
    }

    modifier notHalted() {
        require(!halted, "Deposits are paused");
        _;
    }

    function deposit(uint256 amount) public override notHalted {
        super.deposit(amount);
    }

    function withdraw(uint256 amount) public override lockable {
        super.withdraw(amount);
    }

    function lock(address account) external override onlyIDO {
        Structs.UserInfo storage user = userInfo[account];
        Structs.Tier memory tier = getTierForAmount(user.amount);
        if (tier.lockingPeriod == 0) {
            return;
        }

        uint unlockTime = block.timestamp + tier.lockingPeriod;
        if (user.unlocksAt < unlockTime) {
            user.unlocksAt = unlockTime;
            emit Lock(account, unlockTime, _msgSender());
        }
    }

    function halt(bool status) external onlyOwner {
        halted = status;
        emit Halted(status);
    }

    function addIDO(address account) external onlyOwner {
        require(account != address(0), "IDO cannot be zero address");
        isIDO[account] = true;
    }
}
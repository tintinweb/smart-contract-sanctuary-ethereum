// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import { IExtraRewardsDistributor, IAuraLocker } from "./Interfaces.sol";
import { IERC20 } from "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts-0.8/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts-0.8/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts-0.8/security/ReentrancyGuard.sol";

/**
 * @title   ExtraRewardsDistributor
 * @author  adapted from ConvexFinance
 * @notice  Allows anyone to distribute rewards to the AuraLocker at a given epoch.
 */
contract ExtraRewardsDistributor is ReentrancyGuard, IExtraRewardsDistributor, Ownable {
    using SafeERC20 for IERC20;

    IAuraLocker public immutable auraLocker;

    // user -> canAdd
    mapping(address => bool) public canAddReward;
    // token -> epoch -> amount
    mapping(address => mapping(uint256 => uint256)) public rewardData;
    // token -> epochList
    mapping(address => uint256[]) public rewardEpochs;
    // token -> account -> last claimed epoch index
    mapping(address => mapping(address => uint256)) public userClaims;

    /* ========== EVENTS ========== */

    event WhitelistModified(address user, bool canAdd);
    event RewardAdded(address indexed token, uint256 indexed epoch, uint256 reward);
    event RewardPaid(address indexed user, address indexed token, uint256 reward, uint256 index);
    event RewardForfeited(address indexed user, address indexed token, uint256 index);

    /**
     * @dev Simple constructoor
     * @param _auraLocker Aura Locker address
     */
    constructor(address _auraLocker) Ownable() {
        auraLocker = IAuraLocker(_auraLocker);
    }

    /* ========== ADD WHITELIST ========== */

    function modifyWhitelist(address _depositor, bool _canAdd) external onlyOwner {
        canAddReward[_depositor] = _canAdd;
        emit WhitelistModified(_depositor, _canAdd);
    }

    /* ========== ADD REWARDS ========== */

    /**
     * @notice Add a reward to the current epoch. can be called multiple times for the same reward token
     * @param _token    Reward token address
     * @param _amount   Amount of reward tokenπ
     */
    function addReward(address _token, uint256 _amount) external {
        auraLocker.checkpointEpoch();

        uint256 latestEpoch = auraLocker.epochCount() - 1;
        _addReward(_token, _amount, latestEpoch);
    }

    /**
     * @notice Add reward token to a specific epoch
     * @param _token    Reward token address
     * @param _amount   Amount of reward tokens to add
     * @param _epoch    Which epoch to add to (must be less than the previous epoch)
     */
    function addRewardToEpoch(
        address _token,
        uint256 _amount,
        uint256 _epoch
    ) external {
        auraLocker.checkpointEpoch();

        uint256 latestEpoch = auraLocker.epochCount() - 1;
        require(_epoch <= latestEpoch, "Cannot assign to the future");

        if (_epoch == latestEpoch) {
            _addReward(_token, _amount, latestEpoch);
        } else {
            uint256 len = rewardEpochs[_token].length;
            require(len == 0 || rewardEpochs[_token][len - 1] < _epoch, "Cannot backdate to this epoch");

            _addReward(_token, _amount, _epoch);
        }
    }

    /**
     * @notice  Transfer reward tokens from sender to contract for vlCVX holders
     * @dev     Add reward token for specific epoch
     * @param _token    Reward token address
     * @param _amount   Amount of reward tokens
     * @param _epoch    Epoch to add tokens to
     */
    function _addReward(
        address _token,
        uint256 _amount,
        uint256 _epoch
    ) internal nonReentrant {
        require(canAddReward[msg.sender], "!auth");
        require(_amount > 0, "!amount");

        // Pull before reward accrual
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        //convert to reward per token
        uint256 supply = auraLocker.totalSupplyAtEpoch(_epoch);
        uint256 rPerT = (_amount * 1e20) / supply;
        rewardData[_token][_epoch] += rPerT;

        //add epoch to list
        uint256 len = rewardEpochs[_token].length;
        if (len == 0 || rewardEpochs[_token][len - 1] < _epoch) {
            rewardEpochs[_token].push(_epoch);
        }

        //event
        emit RewardAdded(_token, _epoch, _amount);
    }

    /* ========== GET REWARDS ========== */

    /**
     * @notice Claim rewards for a specific token since the first epoch.
     * @param _account  Address of vlCVX holder
     * @param _token    Reward token address
     */
    function getReward(address _account, address _token) public {
        _getReward(_account, _token, 0);
    }

    /**
     * @notice Claim rewards for a specific token at a specific epoch
     * @param _token        Reward token address
     * @param _startIndex   Index of rewardEpochs[_token] to start checking for rewards from
     */
    function getReward(address _token, uint256 _startIndex) public {
        _getReward(msg.sender, _token, _startIndex);
    }

    /**
     * @notice Claim rewards for a specific token at a specific epoch
     * @param _account     Address of vlCVX holder
     * @param _token       Reward token address
     * @param _startIndex  Index of rewardEpochs[_token] to start checking for rewards from
     */
    function _getReward(
        address _account,
        address _token,
        uint256 _startIndex
    ) internal nonReentrant {
        //get claimable tokens
        (uint256 claimableTokens, uint256 index) = _allClaimableRewards(_account, _token, _startIndex);

        if (claimableTokens > 0) {
            //set claim checkpoint
            userClaims[_token][_account] = index;

            //send
            IERC20(_token).safeTransfer(_account, claimableTokens);

            //event
            emit RewardPaid(_account, _token, claimableTokens, index);
        }
    }

    /**
     * @notice  Allow a user to set their claimed index forward without claiming rewards
     *          Because claims cycle through all periods that a specific reward was given
     *          there becomes a situation where, for example, a new user could lock
     *          2 years from now and try to claim a token that was given out every week prior.
     *          This would result in a 2mil gas checkpoint.(about 20k gas * 52 weeks * 2 years)
     * @param _token  Reward token to forfeit
     * @param _index  Epoch index to forfeit from
     */
    function forfeitRewards(address _token, uint256 _index) external {
        require(_index > 0 && _index < rewardEpochs[_token].length - 1, "!past");
        require(_index >= userClaims[_token][msg.sender], "already claimed");

        //set claim checkpoint. next claim starts from index+1
        userClaims[_token][msg.sender] = _index + 1;

        emit RewardForfeited(msg.sender, _token, _index);
    }

    /* ========== VIEW REWARDS ========== */

    /**
     * @notice Get claimable rewards (rewardToken) for vlCVX holder
     * @param _account  Address of vlCVX holder
     * @param _token    Reward token address
     */
    function claimableRewards(address _account, address _token) external view returns (uint256) {
        (uint256 rewards, ) = _allClaimableRewards(_account, _token, 0);
        return rewards;
    }

    /**
     * @notice Get claimable rewards for a token at a specific epoch
     * @param _account     Address of vlCVX holder
     * @param _token       Reward token address
     * @param _epoch       The epoch to check for rewards
     */
    function claimableRewardsAtEpoch(
        address _account,
        address _token,
        uint256 _epoch
    ) external view returns (uint256) {
        return _claimableRewards(_account, _token, _epoch);
    }

    /**
     * @notice  Get all claimable rewards by looping through each epoch starting with the latest
     *          saved epoch the user last claimed from
     * @param _account  Address of vlCVX holder
     * @param _token    Reward token
     * @param _startIndex  Index of rewardEpochs[_token] to start checking for rewards from
     */
    function _allClaimableRewards(
        address _account,
        address _token,
        uint256 _startIndex
    ) internal view returns (uint256, uint256) {
        uint256 latestEpoch = auraLocker.epochCount() - 1;
        // e.g. tokenEpochs = 31, 21
        uint256 tokenEpochs = rewardEpochs[_token].length;

        // e.g. epochIndex = 0
        uint256 epochIndex = userClaims[_token][_account];
        // e.g. epochIndex = 27 > 0 ? 27 : 0 = 27
        epochIndex = _startIndex > epochIndex ? _startIndex : epochIndex;

        if (epochIndex >= tokenEpochs) {
            return (0, tokenEpochs);
        }

        uint256 claimableTokens = 0;

        for (uint256 i = epochIndex; i < tokenEpochs; i++) {
            //only claimable after rewards are "locked in"
            if (rewardEpochs[_token][i] < latestEpoch) {
                claimableTokens += _claimableRewards(_account, _token, rewardEpochs[_token][i]);
                //return index user claims should be set to
                epochIndex = i + 1;
            }
        }
        return (claimableTokens, epochIndex);
    }

    /**
     * @notice Get claimable rewards for a token at a specific epoch
     * @param _account     Address of vlCVX holder
     * @param _token       Reward token address
     * @param _epoch       The epoch to check for rewards
     */
    function _claimableRewards(
        address _account,
        address _token,
        uint256 _epoch
    ) internal view returns (uint256) {
        //get balance and calc share
        uint256 balance = auraLocker.balanceAtEpochOf(_epoch, _account);
        return (balance * rewardData[_token][_epoch]) / 1e20;
    }

    /**
     * @notice Simply gets the current epoch count for a given reward token
     * @param _token    Reward token address
     * @return _epochs  Number of epochs
     */
    function rewardEpochsCount(address _token) external view returns (uint256) {
        return rewardEpochs[_token].length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IPriceOracle {
    struct OracleAverageQuery {
        Variable variable;
        uint256 secs;
        uint256 ago;
    }
    enum Variable {
        PAIR_PRICE,
        BPT_PRICE,
        INVARIANT
    }

    function getTimeWeightedAverage(OracleAverageQuery[] memory queries)
        external
        view
        returns (uint256[] memory results);
}

interface IVault {
    enum PoolSpecialization {
        GENERAL,
        MINIMAL_SWAP_INFO,
        TWO_TOKEN
    }
    enum JoinKind {
        INIT,
        EXACT_TOKENS_IN_FOR_BPT_OUT,
        TOKEN_IN_FOR_EXACT_BPT_OUT,
        ALL_TOKENS_IN_FOR_EXACT_BPT_OUT
    }

    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external returns (uint256 amountCalculated);

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }
    enum ExitKind {
        EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
        EXACT_BPT_IN_FOR_TOKENS_OUT,
        BPT_IN_FOR_EXACT_TOKENS_OUT,
        MANAGEMENT_FEE_TOKENS_OUT // for ManagedPool
    }
}

interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

interface IAuraLocker {
    function lock(address _account, uint256 _amount) external;

    function checkpointEpoch() external;

    function epochCount() external view returns (uint256);

    function balanceAtEpochOf(uint256 _epoch, address _user) external view returns (uint256 amount);

    function totalSupplyAtEpoch(uint256 _epoch) external view returns (uint256 supply);

    function queueNewRewards(address _rewardsToken, uint256 reward) external;

    function getReward(address _account, bool _stake) external;

    function getReward(address _account) external;
}

interface IExtraRewardsDistributor {
    function addReward(address _token, uint256 _amount) external;
}

interface ICrvDepositorWrapper {
    function getMinOut(uint256, uint256) external view returns (uint256);

    function deposit(
        uint256,
        uint256,
        bool,
        address _stakeAddress
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}
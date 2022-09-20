pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title   PDT Staking
/// @notice  Contract that allows users to stake PDT
/// @author  JeffX
contract PDTStaking is ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// EVENTS ///

    /// @notice                 Emitted upon address staking
    /// @param to               Address of who is receiving credit of stake
    /// @param newStakeAmount   New stake amount of `to`
    /// @param newWeightAmount  New weight amount of `to`  
    event Staked(address to, uint256 indexed newStakeAmount, uint256 indexed newWeightAmount);

    /// @notice                Emitted upon user unstaking
    /// @param staker          Address of who is unstaking
    /// @param amountUnstaked  Amount `staker` unstaked
    event Unstaked(address staker, uint256 indexed amountUnstaked);

    /// @notice               Emitted upon staker claiming
    /// @param staker         Address of who claimed rewards
    /// @param epochsClaimed  Array of epochs claimed
    /// @param claimed        Amount claimed
    event Claimed(address staker, uint256[] indexed epochsClaimed, uint256 indexed claimed);


    /// ERRORS ///

    /// @notice Error for if epoch is invalid
    error InvalidEpoch();
    /// @notice Error for if user has claimed for epoch
    error EpochClaimed();
    /// @notice Error for if user has already claimed up to current epoch
    error ClaimedUpToEpoch();
    /// @notice Error for if staking more than balance
    error MoreThanBalance();
    /// @notice Error for if unstaking when nothing is staked
    error NothingStaked();
    /// @notice Error for if not owner
    error NotOwner();
    /// @notice Error for if zero address
    error ZeroAddress();

    /// STRUCTS ///

    /// @notice                    Details for epoch
    /// @param totalToDistribute   Total amount of token to distribute for epoch
    /// @param totalClaimed        Total amount of tokens claimed from epoch
    /// @param startTime           Timestamp epoch started
    /// @param endTime             Timestamp epoch ends
    /// @param weightAtEnd         Weight of staked tokens at end of epoch
    struct Epoch {
        uint256 totalToDistribute;
        uint256 totalClaimed;
        uint256 startTime;
        uint256 endTime;
        uint256 weightAtEnd;
    }

    /// @notice                         Stake details for user
    /// @param amountStaked             Amount user has staked
    /// @param lastInteraction          Last timestamp user interacted
    /// @param weightAtLastInteraction  Weight of stake at last interaction
    struct Stake {
        uint256 amountStaked;
        uint256 lastInteraction;
        uint256 weightAtLastInteraction;
    }

    /// STATE VARIABLES ///

    /// @notice Time to double weight
    uint256 public immutable timeToDouble;
    /// @notice Epoch id
    uint256 public epochId;
    /// @notice Length of epoch
    uint256 public epochLength;
    /// @notice Last interaction with contract
    uint256 public lastInteraction;
    /// @notice Total amount of PDT staked
    uint256 public totalStaked;

    /// @notice Total amount of weight within contract
    uint256 internal _contractWeight;
    /// @notice Amount of unclaimed rewards
    uint256 public unclaimedRewards;

    /// @notice Current epoch
    Epoch public currentEpoch;

    /// @notice Address of PDT
    address public immutable pdt;
    /// @notice Address of prime
    address public immutable prime;
    /// @notice Address of owner
    address public owner;

    /// @notice If user has claimed for certain epoch
    mapping(address => mapping(uint256 => bool)) public userClaimedEpoch;
    /// @notice User's weight at an epoch
    mapping(address => mapping(uint256 => uint256)) internal _userWeightAtEpoch;
    /// @notice Epoch user has last interacted
    mapping(address => uint256) public epochLeftOff;
    /// @notice Epoch user has last claimed
    mapping(address => uint256) public claimLeftOff;
    /// @notice Id to epoch details
    mapping(uint256 => Epoch) public epoch;
    /// @notice Stake details of user
    mapping(address => Stake) public stakeDetails;

    /// CONSTRUCTOR ///

    /// @param _timeToDouble       Time for weight to double
    /// @param _epochLength        Length of epoch
    /// @param _firstEpochStartIn  Amount of time first epoch will start in
    /// @param _pdt                PDT token address
    /// @param _prime              Address of reward token
    /// @param _owner              Address of owner
    constructor(
        uint256 _timeToDouble,
        uint256 _epochLength,
        uint256 _firstEpochStartIn,
        address _pdt,
        address _prime,
        address _owner
    ) {
        timeToDouble = _timeToDouble;
        epochLength = _epochLength;
        currentEpoch.endTime = block.timestamp + _firstEpochStartIn;
        epoch[0].endTime = block.timestamp + _firstEpochStartIn;
        currentEpoch.startTime = block.timestamp;
        epoch[0].startTime = block.timestamp;
        require(_pdt != address(0), "Zero Addresss: PDT");
        pdt = _pdt;
        require(_prime != address(0), "Zero Addresss: PRIME");
        prime = _prime;
        require(_owner != address(0), "Zero Addresss: Owner");
        owner = _owner;
    }

    /// OWNER FUNCTION ///

    /// @notice              Update epoch length of contract
    /// @param _epochLength  New epoch length
    function updateEpochLength(uint256 _epochLength) external {
        if (msg.sender != owner) revert NotOwner();
        epochLength = _epochLength;
    }

    /// @notice           Changing owner of contract to `newOwner_`
    /// @param _newOwner  Address of who will be the new owner of contract
    function transferOwnership(address _newOwner) external {
        if (msg.sender != owner) revert NotOwner();
        if (_newOwner == address(0)) revert ZeroAddress();
        owner = _newOwner;
    }

    /// PUBLIC FUNCTIONS ///

    /// @notice  Update epoch details if time
    function distribute() external nonReentrant {
        _distribute();
    }

    /// @notice         Stake PDT
    /// @param _to      Address that will receive credit for stake
    /// @param _amount  Amount of PDT to stake
    function stake(address _to, uint256 _amount) external nonReentrant {
        if (IERC20(pdt).balanceOf(msg.sender) < _amount) revert MoreThanBalance();
        IERC20(pdt).safeTransferFrom(msg.sender, address(this), _amount);

        _distribute();
        _setUserWeightAtEpoch(_to);
        _adjustContractWeight(true, _amount);

        totalStaked += _amount;

        Stake memory _stake = stakeDetails[_to];

        if (_stake.amountStaked > 0) {
            uint256 _additionalWeight = _weightIncreaseSinceInteraction(block.timestamp, _stake.lastInteraction, _stake.amountStaked);
            _stake.weightAtLastInteraction += (_additionalWeight + _amount);
        } else {
            _stake.weightAtLastInteraction = _amount;
        }

        _stake.amountStaked += _amount;
        _stake.lastInteraction = block.timestamp;

        stakeDetails[_to] = _stake;

        emit Staked(_to, _stake.amountStaked, _stake.weightAtLastInteraction);
    }

    /// @notice     Unstake PDT
    /// @param _to  Address that will receive PDT unstaked
    function unstake(address _to) external nonReentrant {
        Stake memory _stake = stakeDetails[msg.sender];

        uint256 _stakedAmount = _stake.amountStaked;

        if (_stakedAmount == 0) revert NothingStaked();

        _distribute();
        _setUserWeightAtEpoch(msg.sender);
        _adjustContractWeight(false, _stakedAmount);

        totalStaked -= _stakedAmount;

        _stake.amountStaked = 0;
        _stake.lastInteraction = block.timestamp;
        _stake.weightAtLastInteraction = 0;

        stakeDetails[msg.sender] = _stake;

        IERC20(pdt).safeTransfer(_to, _stakedAmount);

        emit Unstaked(msg.sender, _stakedAmount);
    }

    /// @notice     Claims all pending rewards tokens for msg.sender
    /// @param _to  Address to send rewards to
    function claim(address _to) external nonReentrant {
        _setUserWeightAtEpoch(msg.sender);

        uint256 _pendingRewards;
        uint256 _claimLeftOff = claimLeftOff[msg.sender];

        if (_claimLeftOff == epochId) revert ClaimedUpToEpoch();

        for (_claimLeftOff; _claimLeftOff < epochId; ++_claimLeftOff) {
            if (!userClaimedEpoch[msg.sender][_claimLeftOff] && contractWeightAtEpoch(_claimLeftOff) > 0) {

                userClaimedEpoch[msg.sender][_claimLeftOff] = true;
                Epoch memory _epoch = epoch[_claimLeftOff];
                uint256 _weightAtEpoch = _userWeightAtEpoch[msg.sender][_claimLeftOff];
        
                uint256 _epochRewards = (_epoch.totalToDistribute * _weightAtEpoch) / contractWeightAtEpoch(_claimLeftOff);
                if (_epoch.totalClaimed + _epochRewards > _epoch.totalToDistribute) {
                    _epochRewards = _epoch.totalToDistribute - _epoch.totalClaimed;
                }

                _pendingRewards += _epochRewards;
                epoch[_claimLeftOff].totalClaimed += _epochRewards;
            }
        }

        claimLeftOff[msg.sender] = epochId;
        unclaimedRewards -= _pendingRewards;
        IERC20(prime).safeTransfer(_to, _pendingRewards);
    }

    /// VIEW FUNCTIONS ///

    /// @notice                  Returns current pending rewards for next epoch
    /// @return pendingRewards_  Current pending rewards for next epoch
    function pendingRewards() external view returns (uint256 pendingRewards_) {
        return IERC20(prime).balanceOf(address(this)) - unclaimedRewards;
    }

    /// @notice              Returns total weight `_user` has currently
    /// @param _user         Address to calculate `userWeight_` of
    /// @return userWeight_  Weight of `_user`
    function userTotalWeight(address _user) public view returns (uint256 userWeight_) {
        Stake memory _stake = stakeDetails[_user];
        uint256 _additionalWeight = _weightIncreaseSinceInteraction(block.timestamp, _stake.lastInteraction, _stake.amountStaked);
        userWeight_ = _additionalWeight + _stake.weightAtLastInteraction;
    }

    /// @notice                  Returns total weight of contract at `_epochId`
    /// @param _epochId          Epoch to return total weight of contract for
    /// @return contractWeight_  Weight of contract at end of `_epochId`
    function contractWeightAtEpoch(uint256 _epochId) public view returns (uint256 contractWeight_) {
        if (epochId <= _epochId) revert InvalidEpoch();
        return epoch[_epochId].weightAtEnd;
    }

    /// @notice             Returns amount `_user` has claimable for `_epochId`
    /// @param _user        Address to see `claimable_` for `_epochId`
    /// @param _epochId     Id of epoch wanting to get `claimable_` for
    /// @return claimable_  Amount claimable
    function claimAmountForEpoch(address _user, uint256 _epochId) external view returns (uint256 claimable_) {
        if (epochId <= _epochId) revert InvalidEpoch();
        if (userClaimedEpoch[_user][_epochId] || contractWeightAtEpoch(_epochId) == 0) return 0;

        Epoch memory _epoch = epoch[_epochId];

        claimable_ = (_epoch.totalToDistribute * userWeightAtEpoch(_user, _epochId)) / contractWeightAtEpoch(_epochId);
    }

    /// @notice              Returns total weight of `_user` at `_epochId`
    /// @param _user         Address to calculate `userWeight_` of for `_epochId`
    /// @param _epochId      Epoch id to calculate weight of `_user`
    /// @return userWeight_  Weight of `_user` for `_epochId`
    function userWeightAtEpoch(address _user, uint256 _epochId) public view returns (uint256 userWeight_) {
        if (epochId <= _epochId) revert InvalidEpoch();
        uint256 _epochLeftOff = epochLeftOff[_user];
        Stake memory _stake = stakeDetails[_user];

        if (_epochLeftOff > _epochId) userWeight_ = _userWeightAtEpoch[_user][_epochId];
        else {
            Epoch memory _epoch = epoch[_epochId];
            if (_stake.amountStaked > 0) {
                uint256 _additionalWeight = _weightIncreaseSinceInteraction(_epoch.endTime, _stake.lastInteraction, _stake.amountStaked);
                userWeight_ = _additionalWeight + _stake.weightAtLastInteraction;
            }
        }
    }

    /// @notice                  Returns current total weight of contract
    /// @return contractWeight_  Total current weight of contract
    function contractWeight() external view returns (uint256 contractWeight_) {
        uint256 _weightIncrease = _weightIncreaseSinceInteraction(block.timestamp, lastInteraction, totalStaked);
        contractWeight_ = _weightIncrease + _contractWeight;
    }

    /// INTERNAL VIEW FUNCTION ///

    /// @notice                    Returns additional weight since `_lastInteraction` at `_timestamp`
    /// @param _timestamp          Timestamp calculating on
    /// @param _lastInteraction    Last interaction time
    /// @param _baseAmount         Base amount of PDT to account for
    /// @return additionalWeight_  Additional weight since `_lastinteraction` at `_timestamp`
    function _weightIncreaseSinceInteraction(uint256 _timestamp, uint256 _lastInteraction, uint256 _baseAmount) internal view returns (uint256 additionalWeight_) {
        uint256 _timePassed = _timestamp - _lastInteraction;
        uint256 _multiplierReceived = 1e18 * _timePassed / timeToDouble;
        additionalWeight_ = _baseAmount * _multiplierReceived / 1e18;
    }

    /// INTERNAL FUNCTIONS ///

    /// @notice         Adjust contract weight since last interaction
    /// @param _stake   Bool if `_amount` is being staked or withdrawn
    /// @param _amount  Amount of PDT being staked or withdrawn
    function _adjustContractWeight(bool _stake, uint256 _amount) internal {
        uint256 _weightReceivedSinceInteraction = _weightIncreaseSinceInteraction(block.timestamp, lastInteraction, totalStaked);
        _contractWeight += _weightReceivedSinceInteraction;

        if (_stake) {
            _contractWeight += _amount;
        } else {
            if (userTotalWeight(msg.sender) > _contractWeight) _contractWeight = 0;
            else _contractWeight -= userTotalWeight(msg.sender);
       }

       lastInteraction = block.timestamp;
    }

    /// @notice        Set epochs of `_user` that they left off on
    /// @param _user   Address of user being updated
    function _setUserWeightAtEpoch(address _user) internal {
        uint256 _epochLeftOff = epochLeftOff[_user];

        if (_epochLeftOff != epochId) {
            Stake memory _stake = stakeDetails[_user];
            if (_stake.amountStaked > 0) {
                for (_epochLeftOff; _epochLeftOff < epochId; ++_epochLeftOff) {
                    Epoch memory _epoch = epoch[_epochLeftOff];
                    uint256 _additionalWeight = _weightIncreaseSinceInteraction(_epoch.endTime, _stake.lastInteraction, _stake.amountStaked);
                    _userWeightAtEpoch[_user][_epochLeftOff] = _additionalWeight + _stake.weightAtLastInteraction;
                }
            }

            epochLeftOff[_user] = epochId;
        }
    }

    /// @notice  Update epoch details if time
    function _distribute() internal {
        if (block.timestamp >= currentEpoch.endTime) {
            uint256 _additionalWeight = _weightIncreaseSinceInteraction(currentEpoch.endTime, lastInteraction, totalStaked);
            epoch[epochId].weightAtEnd = _additionalWeight + _contractWeight;

            ++epochId;
            
            Epoch memory _epoch;
            _epoch.totalToDistribute = IERC20(prime).balanceOf(address(this)) - unclaimedRewards;
            _epoch.startTime = block.timestamp;
            _epoch.endTime = block.timestamp + epochLength;

            currentEpoch = _epoch;
            epoch[epochId] = _epoch;

            unclaimedRewards += _epoch.totalToDistribute;
        }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
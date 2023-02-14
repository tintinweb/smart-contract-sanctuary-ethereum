//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.14;
// Note: using solidity 0.8, SafeMath not needed any more

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./AccessProtected.sol";

contract VTVLVesting is Context, AccessProtected, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /**
    @notice Address of the token that we're vesting
     */
    IERC20 public immutable tokenAddress;

    /**
    @notice How many tokens are already allocated to vesting schedules.
    @dev Our balance of the token must always be greater than this amount.
    * Otherwise we risk some users not getting their shares.
    * This gets reduced as the users are paid out or when their schedules are revoked (as it is not reserved any more).
    * In other words, this represents the amount the contract is scheduled to pay out at some point if the 
    * owner were to never interact with the contract.
    */
    uint256 public numTokensReservedForVesting = 0;

    /**
    @notice A structure representing a single claim - supporting linear and cliff vesting.
     */
    struct Claim {
        // Using 40 bits for timestamp (seconds)
        // Gives us a range from 1 Jan 1970 (Unix epoch) up to approximately 35 thousand years from then (2^40 / (365 * 24 * 60 * 60) ~= 35k)
        uint40 startTimestamp; // When does the vesting start (40 bits is enough for TS)
        uint40 endTimestamp; // When does the vesting end - the vesting goes linearly between the start and end timestamps
        uint40 cliffReleaseTimestamp; // At which timestamp is the cliffAmount released. This must be <= startTimestamp
        uint40 releaseIntervalSecs; // Every how many seconds does the vested amount increase.
        // uint112 range: range 0 –     5,192,296,858,534,827,628,530,496,329,220,095.
        // uint112 range: range 0 –                             5,192,296,858,534,827.
        uint256 linearVestAmount; // total entitlement
        uint256 amountWithdrawn; // how much was withdrawn thus far - released at the cliffReleaseTimestamp
        uint112 cliffAmount; // how much is released at the cliff
        bool isActive; // whether this claim is active (or revoked)
    }

    // Mapping every user address to his/her Claim
    // Only one Claim possible per address
    mapping(address => Claim) internal claims;

    // Track the recipients of the vesting
    address[] internal vestingRecipients;

    // Events:
    /**
    @notice Emitted when a founder adds a vesting schedule.
     */
    event ClaimCreated(address indexed _recipient, Claim _claim);

    /**
    @notice Emitted when someone withdraws a vested amount
    */
    event Claimed(address indexed _recipient, uint256 _withdrawalAmount);

    /** 
    @notice Emitted when a claim is revoked
    */
    event ClaimRevoked(
        address indexed _recipient,
        uint256 _numTokensWithheld,
        uint256 revocationTimestamp,
        Claim _claim
    );

    /** 
    @notice Emitted when admin withdraws.
    */
    event AdminWithdrawn(address indexed _recipient, uint256 _amountRequested);

    //
    /**
    @notice Construct the contract, taking the ERC20 token to be vested as the parameter.
    @dev The owner can set the contract in question when creating the contract.
     */
    constructor(IERC20 _tokenAddress) {
        require(address(_tokenAddress) != address(0), "INVALID_ADDRESS");
        tokenAddress = _tokenAddress;
    }

    /**
    @notice Basic getter for a claim. 
    @dev Could be using public claims var, but this is cleaner in terms of naming. (getClaim(address) as opposed to claims(address)). 
    @param _recipient - the address for which we fetch the claim.
     */
    function getClaim(address _recipient) external view returns (Claim memory) {
        return claims[_recipient];
    }

    /**
    @notice This modifier requires that an user has a claim attached.
    @dev  To determine this, we check that a claim:
    * - is active
    * - start timestamp is nonzero.
    * These are sufficient conditions because we only ever set startTimestamp in 
    * createClaim, and we never change it. Therefore, startTimestamp will be set
    * IFF a claim has been created. In addition to that, we need to check
    * a claim is active (since this is has_*Active*_Claim)
    */
    modifier hasActiveClaim(address _recipient) {
        Claim storage _claim = claims[_recipient];
        require(_claim.startTimestamp > 0, "NO_ACTIVE_CLAIM");

        // We however still need the active check, since (due to the name of the function)
        // we want to only allow active claims
        require(_claim.isActive == true, "NO_ACTIVE_CLAIM");

        // Save gas, omit further checks
        // require(_claim.linearVestAmount + _claim.cliffAmount > 0, "INVALID_VESTED_AMOUNT");
        // require(_claim.endTimestamp > 0, "NO_END_TIMESTAMP");
        _;
    }

    /** 
    @notice Modifier which is opposite hasActiveClaim
    @dev Requires that all fields are unset
    */
    modifier hasNoClaim(address _recipient) {
        Claim storage _claim = claims[_recipient];
        // Start timestamp != 0 is a sufficient condition for a claim to exist
        // This is because we only ever add claims (or modify startTs) in the createClaim function
        // Which requires that its input startTimestamp be nonzero
        // So therefore, a zero value for this indicates the claim does not exist.
        require(_claim.startTimestamp == 0, "CLAIM_ALREADY_EXISTS");

        // We don't even need to check for active to be unset, since this function only
        // determines that a claim hasn't been set
        // require(_claim.isActive == false, "CLAIM_ALREADY_EXISTS");

        // Further checks aren't necessary (to save gas), as they're done at creation time (createClaim)
        // require(_claim.endTimestamp == 0, "CLAIM_ALREADY_EXISTS");
        // require(_claim.linearVestAmount + _claim.cliffAmount == 0, "CLAIM_ALREADY_EXISTS");
        // require(_claim.amountWithdrawn == 0, "CLAIM_ALREADY_EXISTS");
        _;
    }

    /**
    @notice Pure function to calculate the vested amount from a given _claim, at a reference timestamp
    @param _claim The claim in question
    @param _referenceTs Timestamp for which we're calculating
     */
    function _baseVestedAmount(Claim memory _claim, uint40 _referenceTs)
        internal
        pure
        returns (uint256)
    {
        uint256 vestAmt = 0;

        // the condition to have anything vested is to be active
        if (_claim.isActive) {
            // no point of looking past the endTimestamp as nothing should vest afterwards
            // So if we're past the end, just get the ref frame back to the end
            if (_referenceTs > _claim.endTimestamp) {
                _referenceTs = _claim.endTimestamp;
            }

            // If we're past the cliffReleaseTimestamp, we release the cliffAmount
            // We don't check here that cliffReleaseTimestamp is after the startTimestamp
            if (_referenceTs >= _claim.cliffReleaseTimestamp) {
                vestAmt += _claim.cliffAmount;
            }

            // Calculate the linearly vested amount - this is relevant only if we're past the schedule start
            // at _referenceTs == _claim.startTimestamp, the period proportion will be 0 so we don't need to start the calc
            if (_referenceTs > _claim.startTimestamp) {
                uint40 currentVestingDurationSecs = _referenceTs -
                    _claim.startTimestamp; // How long since the start
                // Next, we need to calculated the duration truncated to nearest releaseIntervalSecs
                uint40 truncatedCurrentVestingDurationSecs = (currentVestingDurationSecs /
                        _claim.releaseIntervalSecs) *
                        _claim.releaseIntervalSecs;
                uint40 finalVestingDurationSecs = _claim.endTimestamp -
                    _claim.startTimestamp; // length of the interval

                // Calculate the linear vested amount - fraction_of_interval_completed * linearVestedAmount
                // Since fraction_of_interval_completed is truncatedCurrentVestingDurationSecs / finalVestingDurationSecs, the formula becomes
                // truncatedCurrentVestingDurationSecs / finalVestingDurationSecs * linearVestAmount, so we can rewrite as below to avoid
                // rounding errors
                uint256 linearVestAmount = (_claim.linearVestAmount *
                    truncatedCurrentVestingDurationSecs) /
                    finalVestingDurationSecs;

                // Having calculated the linearVestAmount, simply add it to the vested amount
                vestAmt += linearVestAmount;
            }

            return vestAmt;
        }

        // Return the bigger of (vestAmt, _claim.amountWithdrawn)
        // Rationale: no matter how we calculate the vestAmt, we can never return that less was vested than was already withdrawn.
        // Case where this could be relevant - If the claim is inactive, vestAmt would be 0, yet if something was already withdrawn
        // on that claim, we want to return that as vested thus far - as we want the function to be monotonic.
        return _claim.amountWithdrawn;
    }

    /**
    @notice Calculate the amount vested for a given _recipient at a reference timestamp.
    @param _recipient - The address for whom we're calculating
    @param _referenceTs - The timestamp at which we want to calculate the vested amount.
    @dev Simply call the _baseVestedAmount for the claim in question
    */
    function vestedAmount(address _recipient, uint40 _referenceTs)
        public
        view
        returns (uint256)
    {
        Claim memory _claim = claims[_recipient];
        return _baseVestedAmount(_claim, _referenceTs);
    }

    /**
    @notice Calculate the total vested at the end of the schedule, by simply feeding in the end timestamp to the function above.
    @dev This fn is somewhat superfluous, should probably be removed.
    @param _recipient - The address for whom we're calculating
     */
    function finalVestedAmount(address _recipient)
        public
        view
        returns (uint256)
    {
        Claim memory _claim = claims[_recipient];
        return _baseVestedAmount(_claim, _claim.endTimestamp);
    }

    /**
    @notice Calculates how much can we claim, by subtracting the already withdrawn amount from the vestedAmount at this moment.
    @param _recipient - The address for whom we're calculating
    */
    function claimableAmount(address _recipient)
        external
        view
        returns (uint256)
    {
        Claim memory _claim = claims[_recipient];
        return
            _baseVestedAmount(_claim, uint40(block.timestamp)) -
            _claim.amountWithdrawn;
    }

    /** 
    @notice Return all the addresses that have vesting schedules attached.
    */
    function allVestingRecipients() external view returns (address[] memory) {
        return vestingRecipients;
    }

    /** 
    @notice Get the total number of vesting recipients.
    */
    function numVestingRecipients() external view returns (uint256) {
        return vestingRecipients.length;
    }

    /** 
    @notice Permission-unchecked version of claim creation (no onlyAdmin). Actual logic for create claim, to be run within either createClaim or createClaimBatch.
    @dev This'll simply check the input parameters, and create the structure verbatim based on passed in parameters.
    @param _recipient - The address of the recipient of the schedule
    @param _startTimestamp - The timestamp when the linear vesting starts
    @param _endTimestamp - The timestamp when the linear vesting ends
    @param _cliffReleaseTimestamp - The timestamp when the cliff is released (must be <= _startTimestamp, or 0 if no vesting)
    @param _releaseIntervalSecs - The release interval for the linear vesting. If this is, for example, 60, that means that the linearly vested amount gets released every 60 seconds.
    @param _linearVestAmount - The total amount to be linearly vested between _startTimestamp and _endTimestamp
    @param _cliffAmount - The amount released at _cliffReleaseTimestamp. Can be 0 if _cliffReleaseTimestamp is also 0.
     */
    function _createClaimUnchecked(
        address _recipient,
        uint40 _startTimestamp,
        uint40 _endTimestamp,
        uint40 _cliffReleaseTimestamp,
        uint40 _releaseIntervalSecs,
        uint112 _linearVestAmount,
        uint112 _cliffAmount
    ) private hasNoClaim(_recipient) {
        require(_recipient != address(0), "INVALID_ADDRESS");
        require(_linearVestAmount + _cliffAmount > 0, "INVALID_VESTED_AMOUNT"); // Actually only one of linearvested/cliff amount must be 0, not necessarily both
        require(_startTimestamp > 0, "INVALID_START_TIMESTAMP");
        // Do we need to check whether _startTimestamp is greater than the current block.timestamp?
        // Or do we allow schedules that started in the past?
        // -> Conclusion: we want to allow this, for founders that might have forgotten to add some users, or to avoid issues with transactions not going through because of discoordination between block.timestamp and sender's local time
        // require(_endTimestamp > 0, "_endTimestamp must be valid"); // not necessary because of the next condition (transitively)
        require(_startTimestamp < _endTimestamp, "INVALID_END_TIMESTAMP"); // _endTimestamp must be after _startTimestamp
        require(_releaseIntervalSecs > 0, "INVALID_RELEASE_INTERVAL");
        require(
            (_endTimestamp - _startTimestamp) % _releaseIntervalSecs == 0,
            "INVALID_INTERVAL_LENGTH"
        );

        // Potential TODO: sanity check, if _linearVestAmount == 0, should we perhaps force that start and end ts are the same?

        // No point in allowing cliff TS without the cliff amount or vice versa.
        // Both or neither of _cliffReleaseTimestamp and _cliffAmount must be set. If cliff is set, _cliffReleaseTimestamp must be before or at the _startTimestamp
        require(
            (_cliffReleaseTimestamp > 0 &&
                _cliffAmount > 0 &&
                _cliffReleaseTimestamp <= _startTimestamp) ||
                (_cliffReleaseTimestamp == 0 && _cliffAmount == 0),
            "INVALID_CLIFF"
        );

        Claim storage _claim = claims[_recipient];
        _claim.startTimestamp = _startTimestamp;
        _claim.endTimestamp = _endTimestamp;
        _claim.cliffReleaseTimestamp = _cliffReleaseTimestamp;
        _claim.releaseIntervalSecs = _releaseIntervalSecs;
        _claim.cliffAmount = _cliffAmount;
        _claim.linearVestAmount = _linearVestAmount;
        _claim.amountWithdrawn = 0;
        _claim.isActive = true;

        // Our total allocation is simply the full sum of the two amounts, _cliffAmount + _linearVestAmount
        // Not necessary to use the more complex logic from _baseVestedAmount
        uint256 allocatedAmount = _cliffAmount + _linearVestAmount;

        // Still no effects up to this point (and tokenAddress is selected by contract deployer and is immutable), so no reentrancy risk
        require(
            tokenAddress.balanceOf(address(this)) >=
                numTokensReservedForVesting + allocatedAmount,
            "INSUFFICIENT_BALANCE"
        );

        // Done with checks

        // Effects limited to lines below
        numTokensReservedForVesting += allocatedAmount; // track the allocated amount
        vestingRecipients.push(_recipient); // add the vesting recipient to the list
        emit ClaimCreated(_recipient, _claim); // let everyone know
    }

    /** 
    @notice Create a claim based on the input parameters.
    @dev This'll simply check the input parameters, and create the structure verbatim based on passed in parameters.
    @param _recipient - The address of the recipient of the schedule
    @param _startTimestamp - The timestamp when the linear vesting starts
    @param _endTimestamp - The timestamp when the linear vesting ends
    @param _cliffReleaseTimestamp - The timestamp when the cliff is released (must be <= _startTimestamp, or 0 if no vesting)
    @param _releaseIntervalSecs - The release interval for the linear vesting. If this is, for example, 60, that means that the linearly vested amount gets released every 60 seconds.
    @param _linearVestAmount - The total amount to be linearly vested between _startTimestamp and _endTimestamp
    @param _cliffAmount - The amount released at _cliffReleaseTimestamp. Can be 0 if _cliffReleaseTimestamp is also 0.
     */
    function createClaim(
        address _recipient,
        uint40 _startTimestamp,
        uint40 _endTimestamp,
        uint40 _cliffReleaseTimestamp,
        uint40 _releaseIntervalSecs,
        uint112 _linearVestAmount,
        uint112 _cliffAmount
    ) external onlyAdmin {
        _createClaimUnchecked(
            _recipient,
            _startTimestamp,
            _endTimestamp,
            _cliffReleaseTimestamp,
            _releaseIntervalSecs,
            _linearVestAmount,
            _cliffAmount
        );
    }

    /**
    @notice The batch version of the createClaim function. Each argument is an array, and this function simply repeatedly calls the createClaim.
    
     */
    function createClaimsBatch(
        address[] memory _recipients,
        uint40[] memory _startTimestamps,
        uint40[] memory _endTimestamps,
        uint40[] memory _cliffReleaseTimestamps,
        uint40[] memory _releaseIntervalsSecs,
        uint112[] memory _linearVestAmounts,
        uint112[] memory _cliffAmounts
    ) external onlyAdmin {
        uint256 length = _recipients.length;
        require(
            _startTimestamps.length == length &&
                _endTimestamps.length == length &&
                _cliffReleaseTimestamps.length == length &&
                _releaseIntervalsSecs.length == length &&
                _linearVestAmounts.length == length &&
                _cliffAmounts.length == length,
            "ARRAY_LENGTH_MISMATCH"
        );

        for (uint256 i = 0; i < length; i++) {
            _createClaimUnchecked(
                _recipients[i],
                _startTimestamps[i],
                _endTimestamps[i],
                _cliffReleaseTimestamps[i],
                _releaseIntervalsSecs[i],
                _linearVestAmounts[i],
                _cliffAmounts[i]
            );
        }

        // No need for separate emit, since createClaim will emit for each claim (and this function is merely a convenience/gas-saver for multiple claims creation)
    }

    /**
    @notice Withdraw the full claimable balance.
    @dev hasActiveClaim throws off anyone without a claim.
     */
    function withdraw() external hasActiveClaim(_msgSender()) nonReentrant {
        // Get the message sender claim - if any

        Claim storage usrClaim = claims[_msgSender()];

        // we can use block.timestamp directly here as reference TS, as the function itself will make sure to cap it to endTimestamp
        // Conversion of timestamp to uint40 should be safe since 48 bit allows for a lot of years.
        uint256 allowance = vestedAmount(_msgSender(), uint40(block.timestamp));

        // Make sure we didn't already withdraw more that we're allowed.
        require(
            allowance > usrClaim.amountWithdrawn && allowance > 0,
            "NOTHING_TO_WITHDRAW"
        );

        // Calculate how much can we withdraw (equivalent to the above inequality)
        uint256 amountRemaining = allowance - usrClaim.amountWithdrawn;

        // "Double-entry bookkeeping"
        // Carry out the withdrawal by noting the withdrawn amount, and by transferring the tokens.
        usrClaim.amountWithdrawn += amountRemaining;
        // Reduce the allocated amount since the following transaction pays out so the "debt" gets reduced
        numTokensReservedForVesting -= amountRemaining;

        // After the "books" are set, transfer the tokens
        // Reentrancy note - internal vars have been changed by now
        // Also following Checks-effects-interactions pattern
        tokenAddress.safeTransfer(_msgSender(), amountRemaining);

        // Let withdrawal known to everyone.
        emit Claimed(_msgSender(), amountRemaining);
    }

    /**
    @notice Admin withdrawal of the unallocated tokens.
    @param _amountRequested - the amount that we want to withdraw
     */
    function withdrawAdmin(uint256 _amountRequested)
        public
        onlyAdmin
        nonReentrant
    {
        // Allow the owner to withdraw any balance not currently tied up in contracts.
        uint256 amountRemaining = amountAvailableToWithdrawByAdmin();

        require(amountRemaining >= _amountRequested, "INSUFFICIENT_BALANCE");

        // Actually withdraw the tokens
        // Reentrancy note - this operation doesn't touch any of the internal vars, simply transfers
        // Also following Checks-effects-interactions pattern
        tokenAddress.safeTransfer(_msgSender(), _amountRequested);

        // Let the withdrawal known to everyone
        emit AdminWithdrawn(_msgSender(), _amountRequested);
    }

    /** 
    @notice Allow an Owner to revoke a claim that is already active.
    @dev The requirement is that a claim exists and that it's active.
    */
    function revokeClaim(address _recipient)
        external
        onlyAdmin
        hasActiveClaim(_recipient)
    {
        // Fetch the claim
        Claim storage _claim = claims[_recipient];
        // Calculate what the claim should finally vest to
        uint256 finalVestAmt = finalVestedAmount(_recipient);

        // No point in revoking something that has been fully consumed
        // so require that there be unconsumed amount
        require(_claim.amountWithdrawn < finalVestAmt, "NO_UNVESTED_AMOUNT");

        // The amount that is "reclaimed" is equal to the total allocation less what was already withdrawn
        uint256 amountRemaining = finalVestAmt - _claim.amountWithdrawn;

        // Deactivate the claim, and release the appropriate amount of tokens
        _claim.isActive = false; // This effectively reduces the liability by amountRemaining, so we can reduce the liability numTokensReservedForVesting by that much
        numTokensReservedForVesting -= amountRemaining; // Reduces the allocation

        // Tell everyone a claim has been revoked.
        emit ClaimRevoked(
            _recipient,
            amountRemaining,
            uint40(block.timestamp),
            _claim
        );
    }

    /**
    @notice Withdraw a token which isn't controlled by the vesting contract.
    @dev This contract controls/vests token at "tokenAddress". However, someone might send a different token. 
    To make sure these don't get accidentally trapped, give admin the ability to withdraw them (to their own address).
    Note that the token to be withdrawn can't be the one at "tokenAddress".
    @param _otherTokenAddress - the token which we want to withdraw
     */
    function withdrawOtherToken(IERC20 _otherTokenAddress)
        external
        onlyAdmin
        nonReentrant
    {
        require(_otherTokenAddress != tokenAddress, "INVALID_TOKEN"); // tokenAddress address is already sure to be nonzero due to constructor
        uint256 bal = _otherTokenAddress.balanceOf(address(this));
        require(bal > 0, "INSUFFICIENT_BALANCE");
        _otherTokenAddress.safeTransfer(_msgSender(), bal);
    }

    /**
     * @notice Get amount that is not vested in contract
     * @dev Whenever vesting is revoked, this amount will be increased.
     */
    function amountAvailableToWithdrawByAdmin() public view returns (uint256) {
        return
            tokenAddress.balanceOf(address(this)) - numTokensReservedForVesting;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.14;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/** 
@title Access Limiter to multiple owner-specified accounts.
@dev Exposes the onlyAdmin modifier, which will revert (ADMIN_ACCESS_REQUIRED) if the caller is not the owner nor the admin.
*/
abstract contract AccessProtected is Context {
    mapping(address => bool) private _admins; // user address => admin? mapping

    event AdminAccessSet(address indexed _admin, bool _enabled);

    constructor() {
        _admins[_msgSender()] = true;
        emit AdminAccessSet(_msgSender(), true);
    }

    /**
     * Throws if called by any account that isn't an admin or an owner.
     */
    modifier onlyAdmin() {
        require(_admins[_msgSender()], "ADMIN_ACCESS_REQUIRED");
        _;
    }

    function isAdmin(address _addressToCheck) external view returns (bool) {
        return _admins[_addressToCheck];
    }

    /**
     * @notice Set/unset Admin Access for a given address.
     *
     * @param admin - Address of the new admin (or the one to be removed)
     * @param isEnabled - Enable/Disable Admin Access
     */
    function setAdmin(address admin, bool isEnabled) public onlyAdmin {
        require(admin != address(0), "INVALID_ADDRESS");
        _admins[admin] = isEnabled;
        emit AdminAccessSet(admin, isEnabled);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
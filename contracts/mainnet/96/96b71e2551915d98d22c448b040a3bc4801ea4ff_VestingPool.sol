// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0 <0.9.0;
import "./vendor/@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Vesting contract for multiple accounts
/// @author Richard Meissner - @rmeissner
contract VestingPool {
    event AddedVesting(bytes32 indexed id, address indexed account);
    event ClaimedVesting(bytes32 indexed id, address indexed account, address indexed beneficiary);
    event PausedVesting(bytes32 indexed id);
    event UnpausedVesting(bytes32 indexed id);
    event CancelledVesting(bytes32 indexed id);

    // Sane limits based on: https://eips.ethereum.org/EIPS/eip-1985
    // amountClaimed should always be equal to or less than amount
    // pausingDate should always be equal to or greater than startDate
    struct Vesting {
        // First storage slot
        address account; // 20 bytes
        uint8 curveType; // 1 byte -> Max 256 different curve types
        bool managed; // 1 byte
        uint16 durationWeeks; // 2 bytes -> Max 65536 weeks ~ 1260 years
        uint64 startDate; // 8 bytes -> Works until year 292278994, but not before 1970
        // Second storage slot
        uint128 amount; // 16 bytes -> Max 3.4e20 tokens (including decimals)
        uint128 amountClaimed; // 16 bytes -> Max 3.4e20 tokens (including decimals)
        // Third storage slot
        uint64 pausingDate; // 8 bytes -> Works until year 292278994, but not before 1970
        bool cancelled; // 1 byte
    }

    // keccak256(
    //     "EIP712Domain(uint256 chainId,address verifyingContract)"
    // );
    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH = 0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218;

    // keccak256(
    //     "Vesting(address account,uint8 curveType,bool managed,uint16 durationWeeks,uint64 startDate,uint128 amount)"
    // );
    bytes32 private constant VESTING_TYPEHASH = 0x43838b5ce9ca440d1ac21b07179a1fdd88aa2175e5ea103f6e37aa6d18ce78ad;

    address public immutable token;
    address public immutable poolManager;

    uint256 public totalTokensInVesting;
    mapping(bytes32 => Vesting) public vestings;

    modifier onlyPoolManager() {
        require(msg.sender == poolManager, "Can only be called by pool manager");
        _;
    }

    constructor(address _token, address _poolManager) {
        token = _token;
        poolManager = _poolManager;
    }

    /// @notice Create a vesting on this pool for `account`.
    /// @dev This can only be called by the pool manager
    /// @dev It is required that the pool has enough tokens available
    /// @param account The account for which the vesting is created
    /// @param curveType Type of the curve that should be used for the vesting
    /// @param managed Boolean that indicates if the vesting can be managed by the pool manager
    /// @param durationWeeks The duration of the vesting in weeks
    /// @param startDate The date when the vesting should be started (can be in the past)
    /// @param amount Amount of tokens that should be vested in atoms
    function addVesting(
        address account,
        uint8 curveType,
        bool managed,
        uint16 durationWeeks,
        uint64 startDate,
        uint128 amount
    ) public virtual onlyPoolManager {
        _addVesting(account, curveType, managed, durationWeeks, startDate, amount);
    }

    /// @notice Calculate the amount of tokens available for new vestings.
    /// @dev This value changes when more tokens are deposited to this contract
    /// @return Amount of tokens that can be used for new vestings.
    function tokensAvailableForVesting() public view virtual returns (uint256) {
        return IERC20(token).balanceOf(address(this)) - totalTokensInVesting;
    }

    /// @notice Create a vesting on this pool for `account`.
    /// @dev It is required that the pool has enough tokens available
    /// @dev Account cannot be zero address
    /// @param account The account for which the vesting is created
    /// @param curveType Type of the curve that should be used for the vesting
    /// @param managed Boolean that indicates if the vesting can be managed by the pool manager
    /// @param durationWeeks The duration of the vesting in weeks
    /// @param startDate The date when the vesting should be started (can be in the past)
    /// @param amount Amount of tokens that should be vested in atoms
    /// @param vestingId The id of the created vesting
    function _addVesting(
        address account,
        uint8 curveType,
        bool managed,
        uint16 durationWeeks,
        uint64 startDate,
        uint128 amount
    ) internal returns (bytes32 vestingId) {
        require(account != address(0), "Invalid account");
        require(curveType < 2, "Invalid vesting curve");
        vestingId = vestingHash(account, curveType, managed, durationWeeks, startDate, amount);
        require(vestings[vestingId].account == address(0), "Vesting id already used");
        // Check that enough tokens are available for the new vesting
        uint256 availableTokens = tokensAvailableForVesting();
        require(availableTokens >= amount, "Not enough tokens available");
        // Mark tokens for this vesting in use
        totalTokensInVesting += amount;
        vestings[vestingId] = Vesting({
            account: account,
            curveType: curveType,
            managed: managed,
            durationWeeks: durationWeeks,
            startDate: startDate,
            amount: amount,
            amountClaimed: 0,
            pausingDate: 0,
            cancelled: false
        });
        emit AddedVesting(vestingId, account);
    }

    /// @notice Claim `tokensToClaim` tokens from vesting `vestingId` and transfer them to the `beneficiary`.
    /// @dev This can only be called by the owner of the vesting
    /// @dev Beneficiary cannot be the 0-address
    /// @dev This will trigger a transfer of tokens
    /// @param vestingId Id of the vesting from which the tokens should be claimed
    /// @param beneficiary Account that should receive the claimed tokens
    /// @param tokensToClaim Amount of tokens to claim in atoms or max uint128 to claim all available
    function claimVestedTokens(
        bytes32 vestingId,
        address beneficiary,
        uint128 tokensToClaim
    ) public {
        uint128 tokensClaimed = updateClaimedTokens(vestingId, beneficiary, tokensToClaim);
        require(IERC20(token).transfer(beneficiary, tokensClaimed), "Token transfer failed");
    }

    /// @notice Update `amountClaimed` on vesting `vestingId` by `tokensToClaim` tokens.
    /// @dev This can only be called by the owner of the vesting
    /// @dev Beneficiary cannot be the 0-address
    /// @dev This will only update the internal state and NOT trigger the transfer of tokens.
    /// @param vestingId Id of the vesting from which the tokens should be claimed
    /// @param beneficiary Account that should receive the claimed tokens
    /// @param tokensToClaim Amount of tokens to claim in atoms or max uint128 to claim all available
    /// @param tokensClaimed Amount of tokens that have been newly claimed by calling this method
    function updateClaimedTokens(
        bytes32 vestingId,
        address beneficiary,
        uint128 tokensToClaim
    ) internal returns (uint128 tokensClaimed) {
        require(beneficiary != address(0), "Cannot claim to 0-address");
        Vesting storage vesting = vestings[vestingId];
        require(vesting.account == msg.sender, "Can only be claimed by vesting owner");
        // Calculate how many tokens can be claimed
        uint128 availableClaim = _calculateVestedAmount(vesting) - vesting.amountClaimed;
        // If max uint128 is used, claim all available tokens.
        tokensClaimed = tokensToClaim == type(uint128).max ? availableClaim : tokensToClaim;
        require(tokensClaimed <= availableClaim, "Trying to claim too many tokens");
        // Adjust how many tokens are locked in vesting
        totalTokensInVesting -= tokensClaimed;
        vesting.amountClaimed += tokensClaimed;
        emit ClaimedVesting(vestingId, vesting.account, beneficiary);
    }

    /// @notice Cancel vesting `vestingId`.
    /// @dev This can only be called by the pool manager
    /// @dev Only manageable vestings can be cancelled
    /// @param vestingId Id of the vesting that should be cancelled
    function cancelVesting(bytes32 vestingId) public onlyPoolManager {
        Vesting storage vesting = vestings[vestingId];
        require(vesting.account != address(0), "Vesting not found");
        require(vesting.managed, "Only managed vestings can be cancelled");
        require(!vesting.cancelled, "Vesting already cancelled");
        bool isFutureVesting = block.timestamp <= vesting.startDate;
        // If vesting is not already paused it will be paused
        // Pausing date should not be reset else tokens of the initial pause can be claimed
        if (vesting.pausingDate == 0) {
            // pausingDate should always be larger or equal to startDate
            vesting.pausingDate = isFutureVesting ? vesting.startDate : uint64(block.timestamp);
        }
        // Vesting is cancelled, therefore tokens that are not vested yet, will be added back to the pool
        uint128 unusedToken = isFutureVesting ? vesting.amount : vesting.amount - _calculateVestedAmount(vesting);
        totalTokensInVesting -= unusedToken;
        // Vesting is set to cancelled and therefore disallows unpausing
        vesting.cancelled = true;
        emit CancelledVesting(vestingId);
    }

    /// @notice Pause vesting `vestingId`.
    /// @dev This can only be called by the pool manager
    /// @dev Only manageable vestings can be paused
    /// @param vestingId Id of the vesting that should be paused
    function pauseVesting(bytes32 vestingId) public onlyPoolManager {
        Vesting storage vesting = vestings[vestingId];
        require(vesting.account != address(0), "Vesting not found");
        require(vesting.managed, "Only managed vestings can be paused");
        require(vesting.pausingDate == 0, "Vesting already paused");
        // pausingDate should always be larger or equal to startDate
        vesting.pausingDate = block.timestamp <= vesting.startDate ? vesting.startDate : uint64(block.timestamp);
        emit PausedVesting(vestingId);
    }

    /// @notice Unpause vesting `vestingId`.
    /// @dev This can only be called by the pool manager
    /// @dev Only vestings that have not been cancelled can be unpaused
    /// @param vestingId Id of the vesting that should be unpaused
    function unpauseVesting(bytes32 vestingId) public onlyPoolManager {
        Vesting storage vesting = vestings[vestingId];
        require(vesting.account != address(0), "Vesting not found");
        require(vesting.pausingDate != 0, "Vesting is not paused");
        require(!vesting.cancelled, "Vesting has been cancelled and cannot be unpaused");
        // Calculate the time the vesting was paused
        // If vesting has not started yet, then pausing date might be in the future
        uint64 timePaused = block.timestamp <= vesting.pausingDate ? 0 : uint64(block.timestamp) - vesting.pausingDate;
        // Offset the start date to create the effect of pausing
        vesting.startDate = vesting.startDate + timePaused;
        vesting.pausingDate = 0;
        emit UnpausedVesting(vestingId);
    }

    /// @notice Calculate vested and claimed token amounts for vesting `vestingId`.
    /// @dev This will revert if the vesting has not been started yet
    /// @param vestingId Id of the vesting for which to calculate the amounts
    /// @return vestedAmount The amount in atoms of tokens vested
    /// @return claimedAmount The amount in atoms of tokens claimed
    function calculateVestedAmount(bytes32 vestingId) external view returns (uint128 vestedAmount, uint128 claimedAmount) {
        Vesting storage vesting = vestings[vestingId];
        require(vesting.account != address(0), "Vesting not found");
        vestedAmount = _calculateVestedAmount(vesting);
        claimedAmount = vesting.amountClaimed;
    }

    /// @notice Calculate vested token amount for vesting `vesting`.
    /// @dev This will revert if the vesting has not been started yet
    /// @param vesting The vesting for which to calculate the amounts
    /// @return vestedAmount The amount in atoms of tokens vested
    function _calculateVestedAmount(Vesting storage vesting) internal view returns (uint128 vestedAmount) {
        require(vesting.startDate <= block.timestamp, "Vesting not active yet");
        // Convert vesting duration to seconds
        uint64 durationSeconds = uint64(vesting.durationWeeks) * 7 * 24 * 60 * 60;
        // If contract is paused use the pausing date to calculate amount
        uint64 vestedSeconds = vesting.pausingDate > 0
            ? vesting.pausingDate - vesting.startDate
            : uint64(block.timestamp) - vesting.startDate;
        if (vestedSeconds >= durationSeconds) {
            // If vesting time is longer than duration everything has been vested
            vestedAmount = vesting.amount;
        } else if (vesting.curveType == 0) {
            // Linear vesting
            vestedAmount = calculateLinear(vesting.amount, vestedSeconds, durationSeconds);
        } else if (vesting.curveType == 1) {
            // Exponential vesting
            vestedAmount = calculateExponential(vesting.amount, vestedSeconds, durationSeconds);
        } else {
            // This is unreachable because it is not possible to add a vesting with an invalid curve type
            revert("Invalid curve type");
        }
    }

    /// @notice Calculate vested token amount on a linear curve.
    /// @dev Calculate vested amount on linear curve: targetAmount * elapsedTime / totalTime
    /// @param targetAmount Amount of tokens that is being vested
    /// @param elapsedTime Time that has elapsed for the vesting
    /// @param totalTime Duration of the vesting
    /// @return Tokens that have been vested on a linear curve
    function calculateLinear(
        uint128 targetAmount,
        uint64 elapsedTime,
        uint64 totalTime
    ) internal pure returns (uint128) {
        // Calculate vested amount on linear curve: targetAmount * elapsedTime / totalTime
        uint256 amount = (uint256(targetAmount) * uint256(elapsedTime)) / uint256(totalTime);
        require(amount <= type(uint128).max, "Overflow in curve calculation");
        return uint128(amount);
    }

    /// @notice Calculate vested token amount on an exponential curve.
    /// @dev Calculate vested amount on exponential curve: targetAmount * elapsedTime^2 / totalTime^2
    /// @param targetAmount Amount of tokens that is being vested
    /// @param elapsedTime Time that has elapsed for the vesting
    /// @param totalTime Duration of the vesting
    /// @return Tokens that have been vested on an exponential curve
    function calculateExponential(
        uint128 targetAmount,
        uint64 elapsedTime,
        uint64 totalTime
    ) internal pure returns (uint128) {
        // Calculate vested amount on exponential curve: targetAmount * elapsedTime^2 / totalTime^2
        uint256 amount = (uint256(targetAmount) * uint256(elapsedTime) * uint256(elapsedTime)) / (uint256(totalTime) * uint256(totalTime));
        require(amount <= type(uint128).max, "Overflow in curve calculation");
        return uint128(amount);
    }

    /// @notice Calculate the id for a vesting based on its parameters.
    /// @dev The id is a EIP-712 based hash of the vesting.
    /// @param account The account for which the vesting was created
    /// @param curveType Type of the curve that is used for the vesting
    /// @param managed Indicator if the vesting is managed by the pool manager
    /// @param durationWeeks The duration of the vesting in weeks
    /// @param startDate The date when the vesting started (can be in the future)
    /// @param amount Amount of tokens that are vested in atoms
    /// @return vestingId Id of a vesting based on its parameters
    function vestingHash(
        address account,
        uint8 curveType,
        bool managed,
        uint16 durationWeeks,
        uint64 startDate,
        uint128 amount
    ) public view returns (bytes32 vestingId) {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, block.chainid, this));
        bytes32 vestingDataHash = keccak256(abi.encode(VESTING_TYPEHASH, account, curveType, managed, durationWeeks, startDate, amount));
        vestingId = keccak256(abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator, vestingDataHash));
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
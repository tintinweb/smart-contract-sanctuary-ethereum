// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import {Governable} from "Governable.sol";

interface Mintable {
    function mint(address to, uint256 amount) external;
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

/// @title OGV Inflation and Rewards
/// @author Daniel Von Fange
contract RewardsSource is Governable {
    address public immutable ogv;
    address public rewardsTarget; // Contract that receives rewards
    uint256 public lastRewardTime; // Start of the time to calculate rewards over
    uint256 private currentSlopeIndex = 0; // Allows us to start with the correct slope

    struct Slope {
        uint64 start; // uint64 = billions and billions of years
        uint64 end; // Internal use only. By duplicating the start of the next slope, we can save a slot read
        uint128 ratePerDay;
    }
    Slope[] public inflationSlopes;

    uint256 constant MAX_KNEES = 48;
    uint256 constant MAX_INFLATION_PER_DAY = (5 * 1e6 * 1e18);

    event InflationChanged();
    event RewardsTargetChange(address target, address previousTarget);

    constructor(address ogv_) {
        require(ogv_ != address(0), "Rewards: OGV must be set");
        ogv = ogv_;
    }

    /// @notice Collect rewards.
    ///
    /// Can only be called by the contract that will receive the rewards.
    ///
    /// @return rewards OGV collected
    function collectRewards() external returns (uint256) {
        require(msg.sender == rewardsTarget, "Rewards: Not rewardsTarget");
        require(lastRewardTime > 0, "Rewards: lastRewardTime is zero"); // Ensures initialization
        if (block.timestamp <= lastRewardTime) {
            return 0;
        }
        (uint256 inflation, uint256 _nextSlopeIndex) = _calculateInflation();
        if (_nextSlopeIndex != 0) {
            currentSlopeIndex = _nextSlopeIndex;
        }
        lastRewardTime = block.timestamp;

        if (inflation > 0) {
            // Mint the inflation
            Mintable(ogv).mint(rewardsTarget, inflation);
        }

        // OGV Balance of this contract
        uint256 balance = Mintable(ogv).balanceOf(address(this));
        if (balance > 0) {
            // Transfer the balance
            Mintable(ogv).transfer(rewardsTarget, balance);
        }

        return inflation + balance;
    }

    /// @notice Preview the amount of rewards that would be returned if rewards
    /// were collected now.
    ///
    /// @return rewards OGV that would be collected
    function previewRewards() external view returns (uint256) {
        (uint256 rewards, ) = _calculateInflation();

        // When previewing rewards, check contract's own OGV balance,
        // and if present, send that along as part of the rewards
        rewards += Mintable(ogv).balanceOf(address(this));

        return rewards;
    }

    /// @dev Determine the amount of inflation / rewards that will have accrued
    /// between the lastRewardTime and now.
    ///
    /// @return total OGV rewards accrued in the time period
    /// @return slopeIndex a value to be cached, if non-zero, to speed up
    ///   computing rewards in the future.
    function _calculateInflation() internal view returns (uint256, uint256) {
        uint256 last = lastRewardTime;
        if (last >= block.timestamp) {
            return (0, 0); // A zero slopeIndex here results in no change to stored state
        }
        if (inflationSlopes.length == 0) {
            return (0, 0); // Save a slot read by returning a zero constant
        }
        uint256 total = 0;
        uint256 nextSlopeIndex = 0; // Zero means no change
        uint256 _currentSlopeIndex = currentSlopeIndex;
        uint256 i;
        for (i = _currentSlopeIndex; i < inflationSlopes.length; i++) {
            Slope memory slope = inflationSlopes[i];
            uint256 slopeStart = slope.start;
            uint256 slopeEnd = slope.end;
            uint256 rangeStart = last;
            uint256 rangeEnd = block.timestamp;
            if (rangeEnd < slopeStart) {
                break; // No current or future slope could match
            }
            if (rangeStart < slopeStart) {
                rangeStart = slopeStart; // trim to slope edge
            }
            if (rangeEnd > slopeEnd) {
                rangeEnd = slopeEnd; // trim to slope edge
            }
            uint256 duration = rangeEnd - rangeStart;
            total += (duration * slope.ratePerDay) / 1 days;
            if (i > _currentSlopeIndex && duration > 0) {
                nextSlopeIndex = i; // We have moved into a new slope
            }
            if (rangeEnd < slopeEnd) {
                break; // No future slope could match
            }
        }

        return (total, nextSlopeIndex);
    }

    /// @notice Set inflation schedule.
    ///
    /// Inflation slopes use start times and ratePerDay. End times are
    /// overwritten to be either the start of the next slope, or in the case of
    /// the last slope, a max int64. The rate of the last slope then becomes
    /// the inflation rate held into the future.
    ///
    /// The first slope start time may be defined into the future. In this case
    /// there will be no inflation until that first start time is reached.
    ///
    /// @param slopes inflation slope configuration
    function setInflation(Slope[] memory slopes) external onlyGovernor {
        // slope ends intentionally are overwritten
        uint256 length = slopes.length;
        require(length <= MAX_KNEES, "Rewards: Too many slopes");
        delete inflationSlopes; // Delete all before rebuilding
        currentSlopeIndex = 0; // Reset
        uint256 minSlopeStart = 0;
        if (length == 0) {
            return;
        }
        slopes[length - 1].end = type(uint64).max;
        for (uint256 i = 0; i < length; i++) {
            require(
                slopes[i].ratePerDay <= MAX_INFLATION_PER_DAY,
                "Rewards: RatePerDay too high"
            );
            require(
                slopes[i].start > minSlopeStart,
                "Rewards: Start times must increase"
            );
            if (i < length - 1) {
                slopes[i].end = slopes[i + 1].start;
                minSlopeStart = slopes[i].start;
            }
            inflationSlopes.push(slopes[i]);
        }
        // No rewards can accrue before first setInflation
        if (lastRewardTime == 0) {
            lastRewardTime = block.timestamp;
        }
        emit InflationChanged();
    }

    /// @notice Set the address of the contract than can collect rewards
    /// @param rewardsTarget_ contract address that can collect rewards
    function setRewardsTarget(address rewardsTarget_) external onlyGovernor {
        address previousTarget = rewardsTarget;
        rewardsTarget = rewardsTarget_; // Okay to be zero, just disables collecting rewards
        emit RewardsTargetChange(rewardsTarget_, previousTarget);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title OUSD Governable Contract
 * @dev Copy of the openzeppelin Ownable.sol contract with nomenclature change
 *      from owner to governor and renounce methods removed. Does not use
 *      Context.sol like Ownable.sol does for simplification.
 * @author Origin Protocol Inc
 */
abstract contract Governable {
    // Storage position of the owner and pendingOwner of the contract
    // keccak256("OUSD.governor");
    bytes32 private constant governorPosition =
        0x7bea13895fa79d2831e0a9e28edede30099005a50d652d8957cf8a607ee6ca4a;

    // keccak256("OUSD.pending.governor");
    bytes32 private constant pendingGovernorPosition =
        0x44c4d30b2eaad5130ad70c3ba6972730566f3e6359ab83e800d905c61b1c51db;

    // keccak256("OUSD.reentry.status");
    bytes32 private constant reentryStatusPosition =
        0x53bf423e48ed90e97d02ab0ebab13b2a235a6bfbe9c321847d5c175333ac4535;

    // See OpenZeppelin ReentrancyGuard implementation
    uint256 constant _NOT_ENTERED = 1;
    uint256 constant _ENTERED = 2;

    event PendingGovernorshipTransfer(
        address indexed previousGovernor,
        address indexed newGovernor
    );

    event GovernorshipTransferred(
        address indexed previousGovernor,
        address indexed newGovernor
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial Governor.
     */
    constructor() {
        _setGovernor(msg.sender);
        emit GovernorshipTransferred(address(0), _governor());
    }

    /**
     * @dev Returns the address of the current Governor.
     */
    function governor() public view returns (address) {
        return _governor();
    }

    /**
     * @dev Returns the address of the current Governor.
     */
    function _governor() internal view returns (address governorOut) {
        bytes32 position = governorPosition;
        assembly {
            governorOut := sload(position)
        }
    }

    /**
     * @dev Returns the address of the pending Governor.
     */
    function _pendingGovernor()
        internal
        view
        returns (address pendingGovernor)
    {
        bytes32 position = pendingGovernorPosition;
        assembly {
            pendingGovernor := sload(position)
        }
    }

    /**
     * @dev Throws if called by any account other than the Governor.
     */
    modifier onlyGovernor() {
        require(isGovernor(), "Caller is not the Governor");
        _;
    }

    /**
     * @dev Returns true if the caller is the current Governor.
     */
    function isGovernor() public view returns (bool) {
        return msg.sender == _governor();
    }

    function _setGovernor(address newGovernor) internal {
        bytes32 position = governorPosition;
        assembly {
            sstore(position, newGovernor)
        }
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        bytes32 position = reentryStatusPosition;
        uint256 _reentry_status;
        assembly {
            _reentry_status := sload(position)
        }

        // On the first call to nonReentrant, _notEntered will be true
        require(_reentry_status != _ENTERED, "Reentrant call");

        // Any calls to nonReentrant after this point will fail
        assembly {
            sstore(position, _ENTERED)
        }

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        assembly {
            sstore(position, _NOT_ENTERED)
        }
    }

    function _setPendingGovernor(address newGovernor) internal {
        bytes32 position = pendingGovernorPosition;
        assembly {
            sstore(position, newGovernor)
        }
    }

    /**
     * @dev Transfers Governance of the contract to a new account (`newGovernor`).
     * Can only be called by the current Governor. Must be claimed for this to complete
     * @param _newGovernor Address of the new Governor
     */
    function transferGovernance(address _newGovernor) external onlyGovernor {
        _setPendingGovernor(_newGovernor);
        emit PendingGovernorshipTransfer(_governor(), _newGovernor);
    }

    /**
     * @dev Claim Governance of the contract to a new account (`newGovernor`).
     * Can only be called by the new Governor.
     */
    function claimGovernance() external {
        require(
            msg.sender == _pendingGovernor(),
            "Only the pending Governor can complete the claim"
        );
        _changeGovernor(msg.sender);
    }

    /**
     * @dev Change Governance of the contract to a new account (`newGovernor`).
     * @param _newGovernor Address of the new Governor
     */
    function _changeGovernor(address _newGovernor) internal {
        require(_newGovernor != address(0), "New Governor is address(0)");
        emit GovernorshipTransferred(_governor(), _newGovernor);
        _setGovernor(_newGovernor);
    }
}
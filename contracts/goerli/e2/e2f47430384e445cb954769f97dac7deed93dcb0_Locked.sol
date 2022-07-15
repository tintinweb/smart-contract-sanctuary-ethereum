// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "@solmate/utils/ReentrancyGuard.sol";
import "../../interfaces/token/IStaked.sol";
import "../../interfaces/token/ILocked.sol";

/// TODO: DEFINE EVENTS
contract Locked is ILocked, ReentrancyGuard {
    /// ~~~ Structs ~~~

    /// @notice Each package corresponds to a grant given
    /// @param lockedTimestamp Timestamp when the package is granted
    /// @param cliff Timestamp when the vesting cliff is over
    /// @param endLockup Finish timestamp of the lock-up period
    /// @param amount Total tokens given
    /// @param claimed Tokens already claimed
    /// @dev We can pack everything into one slot (256-bytes)
    struct LockedPackage {
        uint32 lockedTimestamp;
        uint32 cliff;
        uint32 endLockup;
        uint64 amount;
        uint64 claimed;
    }

    /// ~~~ Variables ~~~

    /// @notice Packages granted to each address
    mapping(address => LockedPackage[]) public lockedPackages;

    /// @notice Staking contract
    IStaked private _staked;

    /// ~~~ Events ~~~

    /// @notice Emitted when someone locks tokens
    event Lock(
        address lockedAddress,
        uint64 amount,
        uint32 cliff,
        uint32 totalPeriod
    );

    /// @notice Emitted when someone unlocks tokens
    event Unlock(address lockedAddress, uint64 amount);

    /// @notice Constructor
    /// @param stakedContractAddress Staked contract address
    constructor(address stakedContractAddress) {
        _staked = IStaked(stakedContractAddress);
    }

    function lock(
        address lockedAddress,
        uint64 amount,
        uint32 cliff,
        uint32 totalPeriod
    ) external override nonReentrant {
        uint32 convertedTimestamp = uint32(block.timestamp);
        _staked.stakeLocked(msg.sender, lockedAddress, amount);
        lockedPackages[lockedAddress].push(
            LockedPackage({
                lockedTimestamp: convertedTimestamp,
                cliff: convertedTimestamp + cliff,
                endLockup: convertedTimestamp + totalPeriod,
                amount: amount,
                claimed: 0
            })
        );
        emit Lock(lockedAddress, amount, cliff, totalPeriod);
    }

    function claim() external override nonReentrant {
        LockedPackage[] memory packages = lockedPackages[msg.sender];
        uint256 total = packages.length;
        uint64 claimable = 0;
        uint32 convertedTimestamp = uint32(block.timestamp);
        for (uint256 i = 0; i < total; ) {
            if (convertedTimestamp > packages[i].endLockup) {
                claimable += packages[i].amount - packages[i].claimed;
                packages[i].claimed = packages[i].amount;
                lockedPackages[msg.sender][i] = packages[i];
            } else if (convertedTimestamp > packages[i].cliff) {
                uint64 thisClaimable = (packages[i].amount *
                    (convertedTimestamp - packages[i].lockedTimestamp)) /
                    (packages[i].endLockup - packages[i].lockedTimestamp);
                if (thisClaimable < packages[i].claimed) {
                    continue;
                } else {
                    claimable += thisClaimable - packages[i].claimed;
                    packages[i].claimed = thisClaimable;
                    lockedPackages[msg.sender][i] = packages[i];
                }
            }
            unchecked {
                ++i;
            }
        }
        if (claimable > 0) {
            _staked.unstakeLocked(msg.sender, claimable);
            emit Unlock(msg.sender, claimable);
        }
    }

    function totalLocked(address user)
        external
        view
        override
        returns (uint256)
    {
        LockedPackage[] memory packages = lockedPackages[user];
        uint256 totalPackages = packages.length;
        uint256 locked = 0;
        for (uint256 i = 0; i < totalPackages; ) {
            unchecked {
                locked += (packages[i].amount - packages[i].claimed);
                ++i;
            }
        }
        return locked;
    }

    function totalClaimed(address user)
        external
        view
        override
        returns (uint256)
    {
        LockedPackage[] memory packages = lockedPackages[user];
        uint256 totalPackages = packages.length;
        uint256 claimed = 0;
        for (uint256 i = 0; i < totalPackages; ) {
            unchecked {
                claimed += packages[i].claimed;
                ++i;
            }
        }
        return claimed;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

import "../fees/IFeeManager.sol";

/// @title IPixelToken
/// @author 0xEND
/// @notice  TODO: Staking contract for pixel tokens.
interface IStaked {
    /// @notice Stakes `amount` tokens of `msg.sender`. Throws if more than available
    /// @param amount Number of tokens to be staked
    function stake(uint256 amount) external;

    /// @notice Unstakes `amount` tokens of `msg.sender`. Throws if more than available
    /// @param amount Number of tokens to be staked
    function unstake(uint256 amount) external;

    /// @notice Stakes locked tokens. Throws if more than available
    /// @param from Account that currently holds the tokens
    /// @param lockedAddress Address that receieves the locked + staked tokens
    /// @param amount Number of tokens received
    /// @dev Only the Locked contract can call this.
    function stakeLocked(
        address from,
        address lockedAddress,
        uint256 amount
    ) external;

    /// @notice Unstake originally locked tokens of `lockedAddress`. Throws if more than available
    /// @param lockedAddress Recipient of the locked tokens to be staked
    /// @param amount Number of tokens to be unstaked + sent to `lockedAddress`
    /// @dev Only the Locked contract can call this.
    function unstakeLocked(address lockedAddress, uint256 amount) external;

    /// @notice Sets the address of the `Locked` contract. Only owner can call it.
    /// @param lockedContractAddress New address of the `Locked` contract
    function setLockedContractAddress(address lockedContractAddress) external;

    /// @notice Add a token in which we could get rewards
    /// @param tokenAddress Address of the ERC20
    function addRewardToken(address tokenAddress) external;

    /// @notice Returns all available reward tokens.
    function getRewardTokens() external view returns (address[] memory);

    /// @notice Get staked balance of a given user
    /// @param user Address for given user
    /// @return Staked tokens (not locked)
    function unlockedBalanceOf(address user) external view returns (uint256);

    /// @notice Get locked staked balance of a given user
    /// @param user Address for given user
    /// @return Staked locked tokens
    function lockedBalanceOf(address user) external view returns (uint256);

    /// @notice Called when transfering fees to this contract
    /// @param token Token in which fees were paid/transfered
    /// @param fees Fees involved in the txn
    function addFeesReceived(address token, IFeeManager.Fees memory fees)
        external
        returns (uint256);

    /// @notice Sends fees accrued as a sourcer to `msg.sender`
    function claimSourcerFees() external;

    /// @notice Sends to the contract owner protocol fees when no one is staking
    function claimNoStakingRewards() external;

    /// @notice Sends protocol fees accrued by staking  to `msg.sender`
    function claimRewards() external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

/// @title Interface for Locked
/// @author 0xEND
/// @notice Contract that locks tokens. It allows having a cliff and linear lock-up.
interface ILocked {
    /// @notice Locks tokens. Current implementation automatically stakes them
    /// @param lockedAddress Recipient of the locked tokens.
    /// @param amount Amount of tokens
    /// @param cliff Length of the cliff period
    /// @param totalPeriod Length of vesting
    /// @dev We use uint64 for the amount since MAX_SUPPLY = 10_000_000_000. We assume tokens will all unlock before
    ///      '2106-02-07 06:28:16' (2**32 seconds since Jan 1, 1970).
    function lock(
        address lockedAddress,
        uint64 amount,
        uint32 cliff,
        uint32 totalPeriod
    ) external;

    /// @notice Claims all available tokens for `msg.sender` and sends them to `msg.sender`
    function claim() external;

    /// @notice Returns the total locked tokens across packages for a given `user`
    function totalLocked(address user) external view returns (uint256);

    /// @notice Returns the total claimed tokens across packages for a given `user`
    function totalClaimed(address user) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.13;

/// @title Fee Manager
/// @author 0xEND
/// @notice It keeps track of sourcers and the logic for calculating fees.
interface IFeeManager {
    struct Fees {
        address payable[] sourcers;
        uint256[] amounts;
        uint256 protocolAmount;
    }

    /// @notice Registers a new sourcer
    /// @param sourcerAddress Address of the new sourcer
    /// @return The new sourcer id
    function newSourcer(address payable sourcerAddress)
        external
        returns (uint256);

    /// @notice Returns the sourcer id for a given address. 0 if not found.
    /// @param sourcerAddress Address of the sourcer
    /// @return Sourcer address or 0 if not found
    function getSourcerId(address payable sourcerAddress)
        external
        view
        returns (uint256);

    /// @notice Given a transaction, return the corresponding recipients and amounts
    /// @param makerSourcerId Sourcer Id that facilitated the maker order
    /// @param takerSourcerId Sourcer Id that facilitated the taker order
    /// @param amount Total amount of the transaction
    /// @return Fees corresponding to sourcers + protocol
    function getFees(
        uint256 makerSourcerId,
        uint256 takerSourcerId,
        uint256 amount
    ) external returns (Fees memory);

    /// @notice Updates the total fee charged on transactions
    /// @param newTotalFee The new total fee
    function updateTotalFee(uint256 newTotalFee) external;
}
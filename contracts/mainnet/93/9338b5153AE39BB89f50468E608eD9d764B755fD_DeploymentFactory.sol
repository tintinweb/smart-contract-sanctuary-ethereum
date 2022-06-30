// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Create2.sol";
import "./OLAS.sol";
import "./veOLAS.sol";

/// @dev Only `owner` has a privilege, but the `sender` was provided.
/// @param sender Sender address.
/// @param owner Required sender address as an owner.
error OwnerOnly(address sender, address owner);

contract DeploymentFactory {
    event OwnerUpdated(address indexed owner);

    // OLAS deployed address
    address public olasAddress;
    // veOLAS deployed address
    address public veOLASAddress;
    // Owner address
    address public owner;

    /// @dev Changes the owner address.
    /// @param newOwner Address of a new owner.
    function changeOwner(address newOwner) external {
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        if (newOwner == address(0)) {
            revert ZeroAddress();
        }

        owner = newOwner;
        emit OwnerUpdated(newOwner);
    }

    constructor() {
        owner = msg.sender;
    }

    /// @dev Deploys `OLAS` contract via the `create2` method.
    /// @param salt Specified salt.
    function deployOLAS(bytes32 salt) external {
        // Check for the ownership
        if (owner != msg.sender) {
            revert OwnerOnly(msg.sender, owner);
        }

        // Deploy OLAS contract
        olasAddress = Create2.deploy(0, salt, abi.encodePacked(type(OLAS).creationCode));

        // Change minter and owner of the OLAS contract to the msg.sender
        OLAS(olasAddress).changeMinter(msg.sender);
        OLAS(olasAddress).changeOwner(msg.sender);
    }

    /// @dev Computes `OLAS` contract address.
    /// @param salt Specified salt.
    /// @return Computed token address.
    function computeOLASAddress(bytes32 salt) external view returns (address){
        return Create2.computeAddress(salt, keccak256(abi.encodePacked(type(OLAS).creationCode)));
    }

    /// @dev Deploys `veOLAS` contract via the `create2` method.
    /// @param salt Specified salt.
    function deployVeOLAS(bytes32 salt, address token) external {
        // Check for the ownership
        if (owner != msg.sender) {
            revert OwnerOnly(msg.sender, owner);
        }

        veOLASAddress = Create2.deploy(0, salt, abi.encodePacked(type(veOLAS).creationCode, abi.encode(token, "Voting Escrow OLAS", "veOLAS")));
    }

    /// @dev Computes `veOLAS` contract address.
    /// @param salt Specified salt.
    /// @return Computed token address.
    function computeVeOLASAddress(bytes32 salt, address token) external view returns (address){
        return Create2.computeAddress(salt, keccak256(abi.encodePacked(type(veOLAS).creationCode, abi.encode(token, "Voting Escrow OLAS", "veOLAS"))));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../lib/solmate/src/tokens/ERC20.sol";

/// @dev Only `manager` has a privilege, but the `sender` was provided.
/// @param sender Sender address.
/// @param manager Required sender address as a manager.
error ManagerOnly(address sender, address manager);

/// @dev Provided zero address.
error ZeroAddress();

/// @title OLAS - Smart contract for the OLAS token.
/// @author AL
/// @author Aleksandr Kuperman - <[email protected]>
contract OLAS is ERC20 {
    event MinterUpdated(address indexed minter);
    event OwnerUpdated(address indexed owner);

    // One year interval
    uint256 public constant oneYear = 1 days * 365;
    // Total supply cap for the first ten years (one billion OLAS tokens)
    uint256 public constant tenYearSupplyCap = 1_000_000_000e18;
    // Maximum annual inflation after first ten years
    uint256 public constant maxMintCapFraction = 2;
    // Initial timestamp of the token deployment
    uint256 public immutable timeLaunch;

    // Owner address
    address public owner;
    // Minter address
    address public minter;

    constructor() ERC20("Autonolas", "OLAS", 18) {
        owner = msg.sender;
        minter = msg.sender;
        timeLaunch = block.timestamp;
    }

    /// @dev Changes the owner address.
    /// @param newOwner Address of a new owner.
    function changeOwner(address newOwner) external {
        if (msg.sender != owner) {
            revert ManagerOnly(msg.sender, owner);
        }

        if (newOwner == address(0)) {
            revert ZeroAddress();
        }

        owner = newOwner;
        emit OwnerUpdated(newOwner);
    }

    /// @dev Changes the minter address.
    /// @param newMinter Address of a new minter.
    function changeMinter(address newMinter) external {
        if (msg.sender != owner) {
            revert ManagerOnly(msg.sender, owner);
        }

        if (newMinter == address(0)) {
            revert ZeroAddress();
        }

        minter = newMinter;
        emit MinterUpdated(newMinter);
    }

    /// @dev Mints OLAS tokens.
    /// @param account Account address.
    /// @param amount OLAS token amount.
    function mint(address account, uint256 amount) external {
        // Access control
        if (msg.sender != minter) {
            revert ManagerOnly(msg.sender, minter);
        }

        // Check the inflation schedule and mint
        if (inflationControl(amount)) {
            _mint(account, amount);
        }
    }

    /// @dev Provides various checks for the inflation control.
    /// @param amount Amount of OLAS to mint.
    /// @return True if the amount request is within inflation boundaries.
    function inflationControl(uint256 amount) public view returns (bool) {
        uint256 remainder = inflationRemainder();
        return (amount <= remainder);
    }

    /// @dev Gets the reminder of OLAS possible for the mint.
    /// @return remainder OLAS token remainder.
    function inflationRemainder() public view returns (uint256 remainder) {
        uint256 _totalSupply = totalSupply;
        // Current year
        uint256 numYears = (block.timestamp - timeLaunch) / oneYear;
        // Calculate maximum mint amount to date
        uint256 supplyCap = tenYearSupplyCap;
        // After 10 years, adjust supplyCap according to the yearly inflation % set in maxMintCapFraction
        if (numYears > 9) {
            // Number of years after ten years have passed (including ongoing ones)
            numYears -= 9;
            for (uint256 i = 0; i < numYears; ++i) {
                supplyCap += (supplyCap * maxMintCapFraction) / 100;
            }
        }
        // Check for the requested mint overflow
        remainder = supplyCap - _totalSupply;
    }

    /// @dev Burns OLAS tokens.
    /// @param amount OLAS token amount to burn.
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /// @dev Decreases the allowance of another account over their tokens.
    /// @param spender Account that tokens are approved for.
    /// @param amount Amount to decrease approval by.
    /// @return True if the operation succeeded.
    function decreaseAllowance(address spender, uint256 amount) external returns (bool) {
        uint256 spenderAllowance = allowance[msg.sender][spender];

        if (spenderAllowance != type(uint256).max) {
            spenderAllowance -= amount;
            allowance[msg.sender][spender] = spenderAllowance;
            emit Approval(msg.sender, spender, spenderAllowance);
        }

        return true;
    }

    /// @dev Increases the allowance of another account over their tokens.
    /// @param spender Account that tokens are approved for.
    /// @param amount Amount to increase approval by.
    /// @return True if the operation succeeded.
    function increaseAllowance(address spender, uint256 amount) external returns (bool) {
        uint256 spenderAllowance = allowance[msg.sender][spender];

        spenderAllowance += amount;
        allowance[msg.sender][spender] = spenderAllowance;
        emit Approval(msg.sender, spender, spenderAllowance);

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/governance/utils/IVotes.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./interfaces/IErrors.sol";

/**
Votes have a weight depending on time, so that users are committed to the future of (whatever they are voting for).
Vote weight decays linearly over time. Lock time cannot be more than `MAXTIME` (4 years).
Voting escrow has time-weighted votes derived from the amount of tokens locked. The maximum voting power can be
achieved with the longest lock possible. This way the users are incentivized to lock tokens for more time.
# w ^ = amount * time_locked / MAXTIME
# 1 +        /
#   |      /
#   |    /
#   |  /
#   |/
# 0 +--------+------> time
#       maxtime (4 years?)

We cannot really do block numbers per se because slope is per time, not per block, and per block could be fairly bad
because Ethereum changes its block times. What we can do is to extrapolate ***At functions.
*/

/// @title Voting Escrow OLAS - the workflow is ported from Curve Finance Vyper implementation
/// @author Aleksandr Kuperman - <[email protected]>
/// Code ported from: https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/VotingEscrow.vy
/// and: https://github.com/solidlyexchange/solidly/blob/master/contracts/ve.sol

/* This VotingEscrow is based on the OLAS token that has the following specifications:
*  - For the first 10 years there will be the cap of 1 billion (1e27) tokens;
*  - After 10 years, the inflation rate is 2% per year.
* The maximum number of tokens for each year then can be calculated from the formula: 2^n = 1e27 * (1.02)^x,
* where n is the specified number of bits that is sufficient to store and not overflow the total supply,
* and x is the number of years. We limit n by 128, thus it would take 1340+ years to reach that total supply.
* The amount for each locker is eventually cannot overcome this number as well, and thus uint128 is sufficient.
*
* We then limit the time in seconds to last until the value of 2^64 - 1, or for the next 583+ billion years.
* The number of blocks is essentially cannot be bigger than the number of seconds, and thus it is safe to assume
* that uint64 for the number of blocks is also sufficient.
*
* We also limit the individual deposit amount to be no bigger than 2^96 - 1, or the value of total supply in 220+ years.
* This limitation is dictated by the fact that there will be at least several accounts with locked tokens, and the
* sum of all of them cannot be bigger than the total supply. Checking the limit of deposited / increased amount
* allows us to perform the unchecked operation on adding the amounts.
*
* The rest of calculations throughout the contract do not go beyond specified limitations. The contract was checked
* by echidna and the results can be found in the audit section of the repository.
*
* These specified limits allowed us to have storage-added structs to be bound by 2*256 and 1*256 bit sizes
* respectively, thus limiting the gas amount compared to using bigger variable sizes.
*
* Note that after 220 years it is no longer possible to deposit / increase the locked amount to be bigger than 2^96 - 1.
* It is going to be not safe to use this contract for governance after 1340 years.
*/

// Struct for storing balance and unlock time
// The struct size is one storage slot of uint256 (128 + 64 + padding)
struct LockedBalance {
    // Token amount. It will never practically be bigger. Initial OLAS cap is 1 bn tokens, or 1e27.
    // After 10 years, the inflation rate is 2% per year. It would take 1340+ years to reach 2^128 - 1
    uint128 amount;
    // Unlock time. It will never practically be bigger
    uint64 endTime;
}

// Structure for voting escrow points
// The struct size is two storage slots of 2 * uint256 (128 + 128 + 64 + 64 + 128)
struct PointVoting {
    // w(i) = at + b (bias)
    int128 bias;
    // dw / dt = a (slope)
    int128 slope;
    // Timestamp. It will never practically be bigger than 2^64 - 1
    uint64 ts;
    // Block number. It will not be bigger than the timestamp
    uint64 blockNumber;
    // Token amount. It will never practically be bigger. Initial OLAS cap is 1 bn tokens, or 1e27.
    // After 10 years, the inflation rate is 2% per year. It would take 1340+ years to reach 2^128 - 1
    uint128 balance;
}

/// @notice This token supports the ERC20 interface specifications except for transfers and approvals.
contract veOLAS is IErrors, IVotes, IERC20, IERC165 {
    enum DepositType {
        DEPOSIT_FOR_TYPE,
        CREATE_LOCK_TYPE,
        INCREASE_LOCK_AMOUNT,
        INCREASE_UNLOCK_TIME
    }

    event Deposit(address indexed account, uint256 amount, uint256 locktime, DepositType depositType, uint256 ts);
    event Withdraw(address indexed account, uint256 amount, uint256 ts);
    event Supply(uint256 previousSupply, uint256 currentSupply);

    // 1 week time
    uint64 internal constant WEEK = 1 weeks;
    // Maximum lock time (4 years)
    uint256 internal constant MAXTIME = 4 * 365 * 86400;
    // Maximum lock time (4 years) in int128
    int128 internal constant IMAXTIME = 4 * 365 * 86400;
    // Number of decimals
    uint8 public constant decimals = 18;

    // Token address
    address public immutable token;
    // Total token supply
    uint256 public supply;
    // Mapping of account address => LockedBalance
    mapping(address => LockedBalance) public mapLockedBalances;

    // Total number of economical checkpoints (starting from zero)
    uint256 public totalNumPoints;
    // Mapping of point Id => point
    mapping(uint256 => PointVoting) public mapSupplyPoints;
    // Mapping of account address => PointVoting[point Id]
    mapping(address => PointVoting[]) public mapUserPoints;
    // Mapping of time => signed slope change
    mapping(uint64 => int128) public mapSlopeChanges;

    // Voting token name
    string public name;
    // Voting token symbol
    string public symbol;

    /// @dev Contract constructor
    /// @param _token Token address.
    /// @param _name Token name.
    /// @param _symbol Token symbol.
    constructor(address _token, string memory _name, string memory _symbol)
    {
        token = _token;
        name = _name;
        symbol = _symbol;
        // Create initial point such that default timestamp and block number are not zero
        // See cast specification in the PointVoting structure
        mapSupplyPoints[0] = PointVoting(0, 0, uint64(block.timestamp), uint64(block.number), 0);
    }

    /// @dev Gets the most recently recorded user point for `account`.
    /// @param account Account address.
    /// @return pv Last checkpoint.
    function getLastUserPoint(address account) external view returns (PointVoting memory pv) {
        uint256 lastPointNumber = mapUserPoints[account].length;
        if (lastPointNumber > 0) {
            pv = mapUserPoints[account][lastPointNumber - 1];
        }
    }

    /// @dev Gets the number of user points.
    /// @param account Account address.
    /// @return accountNumPoints Number of user points.
    function getNumUserPoints(address account) external view returns (uint256 accountNumPoints) {
        accountNumPoints = mapUserPoints[account].length;
    }

    /// @dev Gets the checkpoint structure at number `idx` for `account`.
    /// @param account User wallet address.
    /// @param idx User point number.
    /// @return The requested checkpoint.
    function getUserPoint(address account, uint256 idx) external view returns (PointVoting memory) {
        return mapUserPoints[account][idx];
    }

    /// @dev Record global and per-user data to checkpoint.
    /// @param account Account address. User checkpoint is skipped if the address is zero.
    /// @param oldLocked Previous locked amount / end lock time for the user.
    /// @param newLocked New locked amount / end lock time for the user.
    /// @param curSupply Current total supply (to avoid using a storage total supply variable)
    function _checkpoint(
        address account,
        LockedBalance memory oldLocked,
        LockedBalance memory newLocked,
        uint128 curSupply
    ) internal {
        PointVoting memory uOld;
        PointVoting memory uNew;
        int128 oldDSlope;
        int128 newDSlope;
        uint256 curNumPoint = totalNumPoints;

        if (account != address(0)) {
            // Calculate slopes and biases
            // Kept at zero when they have to
            if (oldLocked.endTime > block.timestamp && oldLocked.amount > 0) {
                uOld.slope = int128(oldLocked.amount) / IMAXTIME;
                uOld.bias = uOld.slope * int128(uint128(oldLocked.endTime - uint64(block.timestamp)));
            }
            if (newLocked.endTime > block.timestamp && newLocked.amount > 0) {
                uNew.slope = int128(newLocked.amount) / IMAXTIME;
                uNew.bias = uNew.slope * int128(uint128(newLocked.endTime - uint64(block.timestamp)));
            }

            // Reads values of scheduled changes in the slope
            // oldLocked.endTime can be in the past and in the future
            // newLocked.endTime can ONLY be in the FUTURE unless everything is expired: then zeros
            oldDSlope = mapSlopeChanges[oldLocked.endTime];
            if (newLocked.endTime > 0) {
                if (newLocked.endTime == oldLocked.endTime) {
                    newDSlope = oldDSlope;
                } else {
                    newDSlope = mapSlopeChanges[newLocked.endTime];
                }
            }
        }

        PointVoting memory lastPoint;
        if (curNumPoint > 0) {
            lastPoint = mapSupplyPoints[curNumPoint];
        } else {
            // If no point is created yet, we take the actual time and block parameters
            lastPoint = PointVoting(0, 0, uint64(block.timestamp), uint64(block.number), 0);
        }
        uint64 lastCheckpoint = lastPoint.ts;
        // initialPoint is used for extrapolation to calculate the block number and save them
        // as we cannot figure that out in exact values from inside of the contract
        PointVoting memory initialPoint = lastPoint;
        uint256 block_slope; // dblock/dt
        if (block.timestamp > lastPoint.ts) {
            // This 1e18 multiplier is needed for the numerator to be bigger than the denominator
            // We need to calculate this in > uint64 size (1e18 is > 2^59 multiplied by 2^64).
            block_slope = (1e18 * uint256(block.number - lastPoint.blockNumber)) / uint256(block.timestamp - lastPoint.ts);
        }
        // If last point is already recorded in this block, slope == 0, but we know the block already in this case
        // Go over weeks to fill in the history and (or) calculate what the current point is
        {
            // The timestamp is rounded and < 2^64-1
            uint64 tStep = (lastCheckpoint / WEEK) * WEEK;
            for (uint256 i = 0; i < 255; ++i) {
                // Hopefully it won't happen that this won't get used in 5 years!
                // If it does, users will be able to withdraw but vote weight will be broken
                // This is always practically < 2^64-1
                unchecked {
                    tStep += WEEK;
                }
                int128 dSlope;
                if (tStep > block.timestamp) {
                    tStep = uint64(block.timestamp);
                } else {
                    dSlope = mapSlopeChanges[tStep];
                }
                lastPoint.bias -= lastPoint.slope * int128(int64(tStep - lastCheckpoint));
                lastPoint.slope += dSlope;
                if (lastPoint.bias < 0) {
                    // This could potentially happen, but fuzzer didn't find available "real" combinations
                    lastPoint.bias = 0;
                }
                if (lastPoint.slope < 0) {
                    // This cannot happen - just in case. Again, fuzzer didn't reach this
                    lastPoint.slope = 0;
                }
                lastCheckpoint = tStep;
                lastPoint.ts = tStep;
                // After division by 1e18 the uint64 size can be reclaimed
                lastPoint.blockNumber = initialPoint.blockNumber + uint64((block_slope * uint256(tStep - initialPoint.ts)) / 1e18);
                lastPoint.balance = initialPoint.balance;
                // In order for the overflow of total number of economical checkpoints (starting from zero)
                // The _checkpoint() call must happen n >(2^256 -1)/255 or n > ~1e77/255 > ~1e74 times
                unchecked {
                    curNumPoint += 1;    
                }
                if (tStep == block.timestamp) {
                    lastPoint.blockNumber = uint64(block.number);
                    lastPoint.balance = curSupply;
                    break;
                } else {
                    mapSupplyPoints[curNumPoint] = lastPoint;
                }
            }
        }

        totalNumPoints = curNumPoint;

        // Now mapSupplyPoints is filled until current time
        if (account != address(0)) {
            // If last point was in this block, the slope change has been already applied. In such case we have 0 slope(s)
            lastPoint.slope += (uNew.slope - uOld.slope);
            lastPoint.bias += (uNew.bias - uOld.bias);
            if (lastPoint.slope < 0) {
                lastPoint.slope = 0;
            }
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }
        }

        // Record the last updated point
        mapSupplyPoints[curNumPoint] = lastPoint;

        if (account != address(0)) {
            // Schedule the slope changes (slope is going down)
            // We subtract new_user_slope from [newLocked.endTime]
            // and add old_user_slope to [oldLocked.endTime]
            if (oldLocked.endTime > block.timestamp) {
                // oldDSlope was <something> - uOld.slope, so we cancel that
                oldDSlope += uOld.slope;
                if (newLocked.endTime == oldLocked.endTime) {
                    oldDSlope -= uNew.slope; // It was a new deposit, not extension
                }
                mapSlopeChanges[oldLocked.endTime] = oldDSlope;
            }

            if (newLocked.endTime > block.timestamp && newLocked.endTime > oldLocked.endTime) {
                newDSlope -= uNew.slope; // old slope disappeared at this point
                mapSlopeChanges[newLocked.endTime] = newDSlope;
                // else: we recorded it already in oldDSlope
            }
            // Now handle user history
            uNew.ts = uint64(block.timestamp);
            uNew.blockNumber = uint64(block.number);
            uNew.balance = newLocked.amount;
            mapUserPoints[account].push(uNew);
        }
    }

    /// @dev Record global data to checkpoint.
    function checkpoint() external {
        _checkpoint(address(0), LockedBalance(0, 0), LockedBalance(0, 0), uint128(supply));
    }

    /// @dev Deposits and locks tokens for a specified account.
    /// @param account Target address for the locked amount.
    /// @param amount Amount to deposit.
    /// @param unlockTime New time when to unlock the tokens, or 0 if unchanged.
    /// @param lockedBalance Previous locked amount / end time.
    /// @param depositType Deposit type.
    function _depositFor(
        address account,
        uint256 amount,
        uint256 unlockTime,
        LockedBalance memory lockedBalance,
        DepositType depositType
    ) internal {
        uint256 supplyBefore = supply;
        uint256 supplyAfter;
        // Cannot overflow because the total supply << 2^128-1
        unchecked {
            supplyAfter = supplyBefore + amount;
            supply = supplyAfter;
        }
        // Get the old locked data
        LockedBalance memory oldLocked;
        (oldLocked.amount, oldLocked.endTime) = (lockedBalance.amount, lockedBalance.endTime);
        // Adding to the existing lock, or if a lock is expired - creating a new one
        // This cannot be larger than the total supply
        unchecked {
            lockedBalance.amount += uint128(amount);
        }
        if (unlockTime > 0) {
            lockedBalance.endTime = uint64(unlockTime);
        }
        mapLockedBalances[account] = lockedBalance;

        // Possibilities:
        // Both oldLocked.endTime could be current or expired (>/< block.timestamp)
        // amount == 0 (extend lock) or amount > 0 (add to lock or extend lock)
        // lockedBalance.endTime > block.timestamp (always)
        _checkpoint(account, oldLocked, lockedBalance, uint128(supplyAfter));
        if (amount > 0) {
            // OLAS is a solmate-based ERC20 token with optimized transferFrom() that either returns true or reverts
            IERC20(token).transferFrom(msg.sender, address(this), amount);
        }

        emit Deposit(account, amount, lockedBalance.endTime, depositType, block.timestamp);
        emit Supply(supplyBefore, supplyAfter);
    }

    /// @dev Deposits `amount` tokens for `account` and adds to the lock.
    /// @dev Anyone (even a smart contract) can deposit for someone else, but
    ///      cannot extend their locktime and deposit for a brand new user.
    /// @param account Account address.
    /// @param amount Amount to add.
    function depositFor(address account, uint256 amount) external {
        LockedBalance memory lockedBalance = mapLockedBalances[account];
        // Check if the amount is zero
        if (amount == 0) {
            revert ZeroValue();
        }
        // The locked balance must already exist
        if (lockedBalance.amount == 0) {
            revert NoValueLocked(account);
        }
        // Check the lock expiry
        if (lockedBalance.endTime < (block.timestamp + 1)) {
            revert LockExpired(msg.sender, lockedBalance.endTime, block.timestamp);
        }
        // Since in the _depositFor() we have the unchecked sum of amounts, this is needed to prevent unsafe behavior.
        // After 10 years, the inflation rate is 2% per year. It would take 220+ years to reach 2^96 - 1 total supply
        if (amount > type(uint96).max) {
            revert Overflow(amount, type(uint96).max);
        }

        _depositFor(account, amount, 0, lockedBalance, DepositType.DEPOSIT_FOR_TYPE);
    }

    /// @dev Deposits `amount` tokens for `msg.sender` and locks for `unlockTime`.
    /// @param amount Amount to deposit.
    /// @param unlockTime Time when tokens unlock, rounded down to a whole week.
    function createLock(uint256 amount, uint256 unlockTime) external {
        _createLockFor(msg.sender, amount, unlockTime);
    }

    /// @dev Deposits `amount` tokens for `account` and locks for `unlockTime`.
    /// @notice Tokens are taken from `msg.sender`'s balance.
    /// @param account Account address.
    /// @param amount Amount to deposit.
    /// @param unlockTime Time when tokens unlock, rounded down to a whole week.
    function createLockFor(address account, uint256 amount, uint256 unlockTime) external {
        // Check if the account address is zero
        if (account == address(0)) {
            revert ZeroAddress();
        }

        _createLockFor(account, amount, unlockTime);
    }

    /// @dev Deposits `amount` tokens for `account` and locks for `unlockTime`.
    /// @notice Tokens are taken from `msg.sender`'s balance.
    /// @param account Account address.
    /// @param amount Amount to deposit.
    /// @param unlockTime Time when tokens unlock, rounded down to a whole week.
    function _createLockFor(address account, uint256 amount, uint256 unlockTime) private {
        // Check if the amount is zero
        if (amount == 0) {
            revert ZeroValue();
        }
        // Lock time is rounded down to weeks
        // Cannot practically overflow because block.timestamp + unlockTime (max 4 years) << 2^64-1
        unchecked {
            unlockTime = ((block.timestamp + unlockTime) / WEEK) * WEEK;
        }
        LockedBalance memory lockedBalance = mapLockedBalances[account];
        // The locked balance must be zero in order to start the lock
        if (lockedBalance.amount > 0) {
            revert LockedValueNotZero(account, uint256(lockedBalance.amount));
        }
        // Check for the lock time correctness
        if (unlockTime < (block.timestamp + 1)) {
            revert UnlockTimeIncorrect(account, block.timestamp, unlockTime);
        }
        // Check for the lock time not to exceed the MAXTIME
        if (unlockTime > block.timestamp + MAXTIME) {
            revert MaxUnlockTimeReached(account, block.timestamp + MAXTIME, unlockTime);
        }
        // After 10 years, the inflation rate is 2% per year. It would take 220+ years to reach 2^96 - 1 total supply
        if (amount > type(uint96).max) {
            revert Overflow(amount, type(uint96).max);
        }

        _depositFor(account, amount, unlockTime, lockedBalance, DepositType.CREATE_LOCK_TYPE);
    }

    /// @dev Deposits `amount` additional tokens for `msg.sender` without modifying the unlock time.
    /// @param amount Amount of tokens to deposit and add to the lock.
    function increaseAmount(uint256 amount) external {
        LockedBalance memory lockedBalance = mapLockedBalances[msg.sender];
        // Check if the amount is zero
        if (amount == 0) {
            revert ZeroValue();
        }
        // The locked balance must already exist
        if (lockedBalance.amount == 0) {
            revert NoValueLocked(msg.sender);
        }
        // Check the lock expiry
        if (lockedBalance.endTime < (block.timestamp + 1)) {
            revert LockExpired(msg.sender, lockedBalance.endTime, block.timestamp);
        }
        // Check the max possible amount to add, that must be less than the total supply
        // After 10 years, the inflation rate is 2% per year. It would take 220+ years to reach 2^96 - 1 total supply
        if (amount > type(uint96).max) {
            revert Overflow(amount, type(uint96).max);
        }

        _depositFor(msg.sender, amount, 0, lockedBalance, DepositType.INCREASE_LOCK_AMOUNT);
    }

    /// @dev Extends the unlock time.
    /// @param unlockTime New tokens unlock time.
    function increaseUnlockTime(uint256 unlockTime) external {
        LockedBalance memory lockedBalance = mapLockedBalances[msg.sender];
        // Cannot practically overflow because block.timestamp + unlockTime (max 4 years) << 2^64-1
        unchecked {
            unlockTime = ((block.timestamp + unlockTime) / WEEK) * WEEK;
        }
        // The locked balance must already exist
        if (lockedBalance.amount == 0) {
            revert NoValueLocked(msg.sender);
        }
        // Check the lock expiry
        if (lockedBalance.endTime < (block.timestamp + 1)) {
            revert LockExpired(msg.sender, lockedBalance.endTime, block.timestamp);
        }
        // Check for the lock time correctness
        if (unlockTime < (lockedBalance.endTime + 1)) {
            revert UnlockTimeIncorrect(msg.sender, lockedBalance.endTime, unlockTime);
        }
        // Check for the lock time not to exceed the MAXTIME
        if (unlockTime > block.timestamp + MAXTIME) {
            revert MaxUnlockTimeReached(msg.sender, block.timestamp + MAXTIME, unlockTime);
        }

        _depositFor(msg.sender, 0, unlockTime, lockedBalance, DepositType.INCREASE_UNLOCK_TIME);
    }

    /// @dev Withdraws all tokens for `msg.sender`. Only possible if the lock has expired.
    function withdraw() external {
        LockedBalance memory lockedBalance = mapLockedBalances[msg.sender];
        if (lockedBalance.endTime > block.timestamp) {
            revert LockNotExpired(msg.sender, lockedBalance.endTime, block.timestamp);
        }
        uint256 amount = uint256(lockedBalance.amount);

        mapLockedBalances[msg.sender] = LockedBalance(0, 0);
        uint256 supplyBefore = supply;
        uint256 supplyAfter;
        // The amount cannot be less than the total supply
        unchecked {
            supplyAfter = supplyBefore - amount;
            supply = supplyAfter;
        }
        // oldLocked can have either expired <= timestamp or zero end
        // lockedBalance has only 0 end
        // Both can have >= 0 amount
        _checkpoint(msg.sender, lockedBalance, LockedBalance(0, 0), uint128(supplyAfter));

        emit Withdraw(msg.sender, amount, block.timestamp);
        emit Supply(supplyBefore, supplyAfter);

        // OLAS is a solmate-based ERC20 token with optimized transfer() that either returns true or reverts
        IERC20(token).transfer(msg.sender, amount);
    }

    /// @dev Finds a closest point that has a specified block number.
    /// @param blockNumber Block to find.
    /// @param account Account address for user points.
    /// @return point Point with the approximate index number for the specified block.
    /// @return minPointNumber Point number.
    function _findPointByBlock(uint256 blockNumber, address account) internal view
        returns (PointVoting memory point, uint256 minPointNumber)
    {
        // Get the last available point number
        uint256 maxPointNumber;
        if (account == address(0)) {
            maxPointNumber = totalNumPoints;
        } else {
            maxPointNumber = mapUserPoints[account].length;
            if (maxPointNumber == 0) {
                return (point, minPointNumber);
            }
            // Already checked for > 0 in this case
            unchecked {
                maxPointNumber -= 1;
            }
        }

        // Binary search that will be always enough for 128-bit numbers
        for (uint256 i = 0; i < 128; ++i) {
            if ((minPointNumber + 1) > maxPointNumber) {
                break;
            }
            uint256 mid = (minPointNumber + maxPointNumber + 1) / 2;

            // Choose the source of points
            if (account == address(0)) {
                point = mapSupplyPoints[mid];
            } else {
                point = mapUserPoints[account][mid];
            }

            if (point.blockNumber < (blockNumber + 1)) {
                minPointNumber = mid;
            } else {
                maxPointNumber = mid - 1;
            }
        }

        // Get the found point
        if (account == address(0)) {
            point = mapSupplyPoints[minPointNumber];
        } else {
            point = mapUserPoints[account][minPointNumber];
        }
    }

    /// @dev Gets the voting power for an `account` at time `ts`.
    /// @param account Account address.
    /// @param ts Time to get voting power at.
    /// @return vBalance Account voting power.
    function _balanceOfLocked(address account, uint64 ts) internal view returns (uint256 vBalance) {
        uint256 pointNumber = mapUserPoints[account].length;
        if (pointNumber > 0) {
            PointVoting memory uPoint = mapUserPoints[account][pointNumber - 1];
            uPoint.bias -= uPoint.slope * int128(int64(ts) - int64(uPoint.ts));
            if (uPoint.bias > 0) {
                vBalance = uint256(int256(uPoint.bias));
            }
        }
    }

    /// @dev Gets the account balance in native token.
    /// @param account Account address.
    /// @return balance Account balance.
    function balanceOf(address account) public view override returns (uint256 balance) {
        balance = uint256(mapLockedBalances[account].amount);
    }

    /// @dev Gets the `account`'s lock end time.
    /// @param account Account address.
    /// @return unlockTime Lock end time.
    function lockedEnd(address account) external view returns (uint256 unlockTime) {
        unlockTime = uint256(mapLockedBalances[account].endTime);
    }

    /// @dev Gets the account balance at a specific block number.
    /// @param account Account address.
    /// @param blockNumber Block number.
    /// @return balance Account balance.
    function balanceOfAt(address account, uint256 blockNumber) external view returns (uint256 balance) {
        // Find point with the closest block number to the provided one
        (PointVoting memory uPoint, ) = _findPointByBlock(blockNumber, account);
        // If the block number at the point index is bigger than the specified block number, the balance was zero
        if (uPoint.blockNumber < (blockNumber + 1)) {
            balance = uint256(uPoint.balance);
        }
    }

    /// @dev Gets the voting power.
    /// @param account Account address.
    function getVotes(address account) public view override returns (uint256) {
        return _balanceOfLocked(account, uint64(block.timestamp));
    }

    /// @dev Gets the block time adjustment for two neighboring points.
    /// @param blockNumber Block number.
    /// @return point Point with the specified block number (or closest to it).
    /// @return blockTime Adjusted block time of the neighboring point.
    function _getBlockTime(uint256 blockNumber) internal view returns (PointVoting memory point, uint256 blockTime) {
        // Check the block number to be in the past or equal to the current block
        if (blockNumber > block.number) {
            revert WrongBlockNumber(blockNumber, block.number);
        }
        // Get the minimum historical point with the provided block number
        uint256 minPointNumber;
        (point, minPointNumber) = _findPointByBlock(blockNumber, address(0));

        uint256 dBlock;
        uint256 dt;
        if (minPointNumber < totalNumPoints) {
            PointVoting memory pointNext = mapSupplyPoints[minPointNumber + 1];
            dBlock = pointNext.blockNumber - point.blockNumber;
            dt = pointNext.ts - point.ts;
        } else {
            dBlock = block.number - point.blockNumber;
            dt = block.timestamp - point.ts;
        }
        blockTime = point.ts;
        if (dBlock > 0) {
            blockTime += (dt * (blockNumber - point.blockNumber)) / dBlock;
        }
    }

    /// @dev Gets voting power at a specific block number.
    /// @param account Account address.
    /// @param blockNumber Block number.
    /// @return balance Voting balance / power.
    function getPastVotes(address account, uint256 blockNumber) public view override returns (uint256 balance) {
        // Find the user point for the provided block number
        (PointVoting memory uPoint, ) = _findPointByBlock(blockNumber, account);

        // Get block time adjustment.
        (, uint256 blockTime) = _getBlockTime(blockNumber);

        // Calculate bias based on a block time
        uPoint.bias -= uPoint.slope * int128(int64(uint64(blockTime)) - int64(uPoint.ts));
        if (uPoint.bias > 0) {
            balance = uint256(uint128(uPoint.bias));
        }
    }

    /// @dev Calculate total voting power at some point in the past.
    /// @param lastPoint The point (bias/slope) to start the search from.
    /// @param ts Time to calculate the total voting power at.
    /// @return vSupply Total voting power at that time.
    function _supplyLockedAt(PointVoting memory lastPoint, uint64 ts) internal view returns (uint256 vSupply) {
        // The timestamp is rounded and < 2^64-1
        uint64 tStep = (lastPoint.ts / WEEK) * WEEK;
        for (uint256 i = 0; i < 255; ++i) {
            // This is always practically < 2^64-1
            unchecked {
                tStep += WEEK;
            }
            int128 dSlope;
            if (tStep > ts) {
                tStep = ts;
            } else {
                dSlope = mapSlopeChanges[tStep];
            }
            lastPoint.bias -= lastPoint.slope * int128(int64(tStep) - int64(lastPoint.ts));
            if (tStep == ts) {
                break;
            }
            lastPoint.slope += dSlope;
            lastPoint.ts = tStep;
        }

        if (lastPoint.bias > 0) {
            vSupply = uint256(uint128(lastPoint.bias));
        }
    }

    /// @dev Gets total token supply.
    /// @return Total token supply.
    function totalSupply() public view override returns (uint256) {
        return supply;
    }

    /// @dev Gets total token supply at a specific block number.
    /// @param blockNumber Block number.
    /// @return supplyAt Supply at the specified block number.
    function totalSupplyAt(uint256 blockNumber) external view returns (uint256 supplyAt) {
        // Find point with the closest block number to the provided one
        (PointVoting memory sPoint, ) = _findPointByBlock(blockNumber, address(0));
        // If the block number at the point index is bigger than the specified block number, the balance was zero
        if (sPoint.blockNumber < (blockNumber + 1)) {
            supplyAt = uint256(sPoint.balance);
        }
    }

    /// @dev Calculates total voting power at time `ts`.
    /// @param ts Time to get total voting power at.
    /// @return Total voting power.
    function totalSupplyLockedAtT(uint256 ts) public view returns (uint256) {
        PointVoting memory lastPoint = mapSupplyPoints[totalNumPoints];
        return _supplyLockedAt(lastPoint, uint64(ts));
    }

    /// @dev Calculates current total voting power.
    /// @return Total voting power.
    function totalSupplyLocked() public view returns (uint256) {
        return totalSupplyLockedAtT(block.timestamp);
    }

    /// @dev Calculate total voting power at some point in the past.
    /// @param blockNumber Block number to calculate the total voting power at.
    /// @return Total voting power.
    function getPastTotalSupply(uint256 blockNumber) public view override returns (uint256) {
        (PointVoting memory sPoint, uint256 blockTime) = _getBlockTime(blockNumber);
        // Now dt contains info on how far are we beyond the point
        return _supplyLockedAt(sPoint, uint64(blockTime));
    }

    /// @dev Gets information about the interface support.
    /// @param interfaceId A specified interface Id.
    /// @return True if this contract implements the interface defined by interfaceId.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC20).interfaceId || interfaceId == type(IVotes).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    /// @dev Reverts the transfer of this token.
    function transfer(address to, uint256 amount) external virtual override returns (bool) {
        revert NonTransferable(address(this));
    }

    /// @dev Reverts the approval of this token.
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        revert NonTransferable(address(this));
    }

    /// @dev Reverts the transferFrom of this token.
    function transferFrom(address from, address to, uint256 amount) external virtual override returns (bool) {
        revert NonTransferable(address(this));
    }

    /// @dev Reverts the allowance of this token.
    function allowance(address owner, address spender) external view virtual override returns (uint256)
    {
        revert NonTransferable(address(this));
    }

    /// @dev Reverts delegates of this token.
    function delegates(address account) external view virtual override returns (address)
    {
        revert NonDelegatable(address(this));
    }

    /// @dev Reverts delegate for this token.
    function delegate(address delegatee) external virtual override
    {
        revert NonDelegatable(address(this));
    }

    /// @dev Reverts delegateBySig for this token.
    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s)
    external virtual override
    {
        revert NonDelegatable(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotes {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// @dev Errors.
interface IErrors {
    /// @dev Only `owner` has a privilege, but the `sender` was provided.
    /// @param sender Sender address.
    /// @param owner Required sender address as an owner.
    error OwnerOnly(address sender, address owner);

    /// @dev Provided zero address.
    error ZeroAddress();

    /// @dev Zero value when it has to be different from zero.
    error ZeroValue();

    /// @dev Non-zero value when it has to be zero.
    error NonZeroValue();

    /// @dev Wrong length of two arrays.
    /// @param numValues1 Number of values in a first array.
    /// @param numValues2 Numberf of values in a second array.
    error WrongArrayLength(uint256 numValues1, uint256 numValues2);

    /// @dev Value overflow.
    /// @param provided Overflow value.
    /// @param max Maximum possible value.
    error Overflow(uint256 provided, uint256 max);

    /// @dev Token is non-transferable.
    /// @param account Token address.
    error NonTransferable(address account);

    /// @dev Token is non-delegatable.
    /// @param account Token address.
    error NonDelegatable(address account);

    /// @dev Insufficient token allowance.
    /// @param provided Provided amount.
    /// @param expected Minimum expected amount.
    error InsufficientAllowance(uint256 provided, uint256 expected);

    /// @dev No existing lock value is found.
    /// @param account Address that is checked for the locked value.
    error NoValueLocked(address account);

    /// @dev Locked value is not zero.
    /// @param account Address that is checked for the locked value.
    /// @param amount Locked amount.
    error LockedValueNotZero(address account, uint256 amount);

    /// @dev Value lock is expired.
    /// @param account Address that is checked for the locked value.
    /// @param deadline The lock expiration deadline.
    /// @param curTime Current timestamp.
    error LockExpired(address account, uint256 deadline, uint256 curTime);

    /// @dev Value lock is not expired.
    /// @param account Address that is checked for the locked value.
    /// @param deadline The lock expiration deadline.
    /// @param curTime Current timestamp.
    error LockNotExpired(address account, uint256 deadline, uint256 curTime);

    /// @dev Provided unlock time is incorrect.
    /// @param account Address that is checked for the locked value.
    /// @param minUnlockTime Minimal unlock time that can be set.
    /// @param providedUnlockTime Provided unlock time.
    error UnlockTimeIncorrect(address account, uint256 minUnlockTime, uint256 providedUnlockTime);

    /// @dev Provided unlock time is bigger than the maximum allowed.
    /// @param account Address that is checked for the locked value.
    /// @param maxUnlockTime Max unlock time that can be set.
    /// @param providedUnlockTime Provided unlock time.
    error MaxUnlockTimeReached(address account, uint256 maxUnlockTime, uint256 providedUnlockTime);

    /// @dev Provided block number is incorrect (has not been processed yet).
    /// @param providedBlockNumber Provided block number.
    /// @param actualBlockNumber Actual block number.
    error WrongBlockNumber(uint256 providedBlockNumber, uint256 actualBlockNumber);
}
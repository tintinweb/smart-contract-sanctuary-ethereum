// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./TokenVesting.sol";

contract PrescheduledTokenVesting is TokenVesting {
    constructor(address token_) TokenVesting(token_) {
        // TODO: add initial vesting schedules for team etc.
        // Use this snipped as the template:
        // _createVestingSchedule(
        //     VestingScheduleConfig({
        //         beneficiary: <account>,
        //         start: <timestamp>,
        //         cliff: <seconds>,
        //         duration: <seconds>,
        //         slicePeriodSeconds: <seconds>,
        //         amountTotal: <wei>,
        //         revocable: <bool>
        //     })
        // );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {ITokenVesting} from "./interfaces/ITokenVesting.sol";
import {VestingSchedule} from "./defs/VestingSchedule.sol";
import {VestingScheduleConfig} from "./defs/VestingScheduleConfig.sol";

contract TokenVesting is ITokenVesting, Owned, ReentrancyGuard {
    //
    // - STORAGE -
    //
    ERC20 private immutable _token;

    bytes32[] private vestingSchedulesIds;
    mapping(bytes32 => VestingSchedule) private vestingSchedules;
    uint256 private vestingSchedulesTotalAmount;
    mapping(address => uint256) private holdersVestingCount;

    //
    // - CONSTRUCTOR -
    //
    /**
     * @dev Creates a vesting contract.
     * @param token_ address of the ERC20 token contract
     */
    constructor(address token_) Owned(msg.sender) {
        require(token_ != address(0x0));
        _token = ERC20(token_);
    }

    //
    // - MUTATORS (ADMIN) -
    //
    function createVestingSchedule(
        address beneficiary_,
        uint64 start_,
        uint64 cliff_,
        uint64 duration_,
        uint64 slicePeriodSeconds_,
        uint256 amount_,
        bool revocable_
    ) external {
        _onlyOwner();
        _createVestingSchedule(
            VestingScheduleConfig({
                beneficiary: beneficiary_,
                start: start_,
                cliff: cliff_,
                duration: duration_,
                slicePeriodSeconds: slicePeriodSeconds_,
                amountTotal: amount_,
                revocable: revocable_
            })
        );
    }

    function revoke(bytes32 vestingScheduleId) external {
        _onlyOwner();
        _vestingScheduleNotRevoked(vestingScheduleId);
        _vestingScheduleRevocable(vestingScheduleId);

        VestingSchedule storage vestingSchedule = vestingSchedules[vestingScheduleId];
        
        uint256 unreleased = vestingSchedule.amountTotal - vestingSchedule.released;
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount - unreleased;
        vestingSchedule.revoked = true;
        emit VestingScheduleCancelled(vestingScheduleId);
    }

    function extend(bytes32 vestingScheduleId, uint32 extensionDuration) external {
        _onlyOwner();
        _vestingScheduleNotRevoked(vestingScheduleId);
        _vestingScheduleNotExpired(vestingScheduleId);
        _vestingScheduleRevocable(vestingScheduleId);
        require(extensionDuration > 0, "Zero Duration");

        VestingSchedule storage vestingSchedule = vestingSchedules[vestingScheduleId];
        vestingSchedule.duration += extensionDuration;
        emit VestingScheduleExtended(vestingScheduleId, extensionDuration);
    }

    function withdraw(uint256 amount) external nonReentrant {
        _onlyOwner();
        require(getWithdrawableAmount() >= amount, "Insufficient Token Balance");
        emit AmountWithdrawn(amount);
        SafeTransferLib.safeTransfer(_token, msg.sender, amount);
    }

    //
    // - MUTATORS -
    //
    function release(bytes32 vestingScheduleId, uint256 amount) public nonReentrant {
        _vestingScheduleNotRevoked(vestingScheduleId);
        VestingSchedule storage vestingSchedule = vestingSchedules[vestingScheduleId];
        _onlyOwnerOrBeneficiary(vestingSchedule);

        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        require(vestedAmount >= amount, "Insufficient Vested Balance");
        vestingSchedule.released = vestingSchedule.released + amount;
        address payable beneficiaryPayable = payable(vestingSchedule.beneficiary);
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount - amount;
        emit AmountReleased(vestingScheduleId, vestingSchedule.beneficiary, amount);
        SafeTransferLib.safeTransfer(_token, beneficiaryPayable, amount);
    }

    //
    // - VIEW -
    //
    function getVestingSchedulesCountByBeneficiary(
        address _beneficiary
    ) external view returns (uint256) {
        return holdersVestingCount[_beneficiary];
    }

    function getVestingIdAtIndex(uint256 index) external view returns (bytes32) {
        require(index < getVestingSchedulesCount(), "Index Out of Bounds");
        return vestingSchedulesIds[index];
    }

    function getVestingScheduleByAddressAndIndex(
        address holder,
        uint256 index
    ) external view returns (VestingSchedule memory) {
        return getVestingSchedule(computeVestingScheduleIdForAddressAndIndex(holder, index));
    }

    function getVestingSchedulesTotalAmount() external view returns (uint256) {
        return vestingSchedulesTotalAmount;
    }

    function getToken() external view returns (address) {
        return address(_token);
    }

    function getVestingSchedulesCount() public view returns (uint256) {
        return vestingSchedulesIds.length;
    }

    function computeReleasableAmount(bytes32 vestingScheduleId) external view returns (uint256) {
        _vestingScheduleNotRevoked(vestingScheduleId);
        VestingSchedule storage vestingSchedule = vestingSchedules[vestingScheduleId];
        return _computeReleasableAmount(vestingSchedule);
    }

    function getVestingSchedule(
        bytes32 vestingScheduleId
    ) public view returns (VestingSchedule memory) {
        return vestingSchedules[vestingScheduleId];
    }

    function getWithdrawableAmount() public view returns (uint256) {
        return _token.balanceOf(address(this)) - vestingSchedulesTotalAmount;
    }

    function computeNextVestingScheduleIdForHolder(address holder) public view returns (bytes32) {
        return computeVestingScheduleIdForAddressAndIndex(holder, holdersVestingCount[holder]);
    }

    function getLastVestingScheduleForHolder(
        address holder
    ) external view returns (VestingSchedule memory) {
        return
            vestingSchedules[
                computeVestingScheduleIdForAddressAndIndex(holder, holdersVestingCount[holder] - 1)
            ];
    }

    function computeVestingScheduleIdForAddressAndIndex(
        address holder,
        uint256 index
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(holder, index));
    }

    //
    // - INTERNALS -
    //
    function _createVestingSchedule(VestingScheduleConfig memory config) internal {
        require(config.beneficiary != address(0), "Zero Beneficiary Address");
        require(getWithdrawableAmount() >= config.amountTotal, "Insufficient Token Balance");
        require(config.duration > 0, "Zero Duration");
        require(config.amountTotal > 0, "Zero Amount");
        require(config.slicePeriodSeconds >= 1, "Zero Slice Period");
        require(config.duration >= config.cliff, "Cliff Exceeds Duration");
        bytes32 vestingScheduleId = computeNextVestingScheduleIdForHolder(config.beneficiary);

        vestingSchedules[vestingScheduleId] = VestingSchedule({
            initialized: true,
            beneficiary: config.beneficiary,
            cliff: config.start + config.cliff,
            start: config.start,
            duration: config.duration,
            slicePeriodSeconds: config.slicePeriodSeconds,
            amountTotal: config.amountTotal,
            released: 0,
            revoked: false,
            revocable: config.revocable
        });
        vestingSchedulesTotalAmount = vestingSchedulesTotalAmount + config.amountTotal;
        vestingSchedulesIds.push(vestingScheduleId);
        holdersVestingCount[config.beneficiary]++;

        emit VestingScheduleCreated(vestingScheduleId, config.beneficiary, config.amountTotal);
    }

    function _computeReleasableAmount(
        VestingSchedule memory vestingSchedule
    ) internal view returns (uint256) {
        // Retrieve the current time.
        uint256 currentTime = block.timestamp;
        // If the current time is before the cliff, no tokens are releasable.
        if ((currentTime < vestingSchedule.cliff) || vestingSchedule.revoked) {
            return 0;
        }
        // If the current time is after the vesting period, all tokens are releasable,
        // minus the amount already released.
        else if (currentTime >= vestingSchedule.start + vestingSchedule.duration) {
            return vestingSchedule.amountTotal - vestingSchedule.released;
        }
        // Otherwise, some tokens are releasable.
        else {
            // Compute the number of full vesting periods that have elapsed.
            uint256 timeFromStart = currentTime - vestingSchedule.start;
            uint256 secondsPerSlice = vestingSchedule.slicePeriodSeconds;
            uint256 vestedSlicePeriods = timeFromStart / secondsPerSlice;
            uint256 vestedSeconds = vestedSlicePeriods * secondsPerSlice;
            // Compute the amount of tokens that are vested.
            uint256 vestedAmount = (vestingSchedule.amountTotal * vestedSeconds) /
                vestingSchedule.duration;
            // Subtract the amount already released and return.
            return vestedAmount - vestingSchedule.released;
        }
    }

    /**
     * @dev Reverts if the caller is not the contract owner.
     */
    function _onlyOwner() internal view {
        require(msg.sender == owner, "UNAUTHORIZED");
    }

    /**
     * @dev Reverts if the caller is neither the contract owner nor the vesting schedule beneficiary.
     */
    function _onlyOwnerOrBeneficiary(VestingSchedule storage vestingSchedule) internal view {
        bool isBeneficiary = msg.sender == vestingSchedule.beneficiary;
        bool isReleasor = (msg.sender == owner);

        require(isBeneficiary || isReleasor, "Not Beneficiary or Releasor");
    }

    /**
     * @dev Reverts if the vesting schedule does not exist or has been revoked.
     */
    function _vestingScheduleNotRevoked(bytes32 vestingScheduleId) internal view {
        require(vestingSchedules[vestingScheduleId].initialized, "Vesting Schedule Not Found");
        require(!vestingSchedules[vestingScheduleId].revoked, "Vesting Schedule Revoked");
    }

    function _vestingScheduleNotExpired(bytes32 vestingScheduleId) internal view {
        require(
            vestingSchedules[vestingScheduleId].start +
                vestingSchedules[vestingScheduleId].duration >
                block.timestamp,
            "Vesting Schedule Expired"
        );
    }

    function _vestingScheduleRevocable(bytes32 vestingScheduleId) internal view {
        require(vestingSchedules[vestingScheduleId].revocable, "Vesting Schedule Not Revocable");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {ITokenVestingEvents} from "./ITokenVestingEvents.sol";
import {VestingSchedule} from "../defs/VestingSchedule.sol";

interface ITokenVesting is ITokenVestingEvents {
    // - MUTATORS (ADMIN) -
    /**
     * @dev Create a new vesting schedule for a beneficiary. Emit VestingScheduleCreated on success. Multiple vesting
     *      schedules can be created for a beneficiary.
     * @param beneficiary_ Address of the beneficiary to whom vested tokens are transferred.
     * @param start_ Start time of the vesting period. Ref: block.timestamp.
     * @param cliff_ Duration (in seconds) of the cliff in which tokens will begin to vest.
     *               If 0, tokens begin vesting immediately after start_.
     * @param duration_ Duration (in seconds) of the period in which the tokens will vest.
     * @param slicePeriodSeconds_ Duration (in seconds) of a slice period for the vesting.
     * @param revocable_ Whether the vesting is revocable by the contract owner.
     * @param amount_ The total amount of tokens to be released by the end of the vesting schedule.
     *
     * Requirements:
     * - The caller must be the contract owner.
     * - The beneficiary address must be non-zero.
     * - The amount being allocated must
     *   - be a non-zero value
     *   - not exceed the contract's balance of tokens minus all the amounts already allocated to schedules.
     * - The vesting schedule duration must be a non-zero value.
     * - The slice period duration must be a non-zero value.
     * - The cliff cannot exceed the schedule's total duration.
     */
    function createVestingSchedule(
        address beneficiary_,
        uint64 start_,
        uint64 cliff_,
        uint64 duration_,
        uint64 slicePeriodSeconds_,
        uint256 amount_,
        bool revocable_
    ) external;

    /**
     * @dev Revoke the vesting schedule for a given identifier. Emit VestingScheduleCancelled on success.
     *      All vested and non-vested amounts are returned to the contract and can be allocated to
     *      new vesting schedules.
     * @param vestingScheduleId The vesting schedule identifier.
     *
     * Requirements:
     * - The caller must be the contract owner.
     * - The schedule must be revocable.
     * - The schedule must not have been revoked previously.
     */
    function revoke(bytes32 vestingScheduleId) external;

    /**
     * @dev Add time to the duration of a vesting schedule. Emit VestingScheduleExtended on success.
     *
     * Requirements:
     * - The caller must be the contract owner.
     * - The extension must be non-zero.
     * - The schedule must not have been revoked.
     * - The schedule must not have expired.
     */
    function extend(bytes32 vestingScheduleId, uint32 extensionDuration) external;

    /**
     * @dev Withdraw an amount of token. Emit AmountWithdrawn on success.
     * @param amount The amount to withdraw. Must not exceed the amount of tokens not allocated to vesting schedules.
     *
     * Requirements:
     * - The caller must be the contract owner.
     * - The amount must be below (or equal to) the non-allocated token balance.
     */
    function withdraw(uint256 amount) external;

    // - MUTATORS -
    /**
     * @dev Release an amount of vested tokens. Emit AmountReleased on success.
     * @param vestingScheduleId The vesting schedule identifier. 
     * @param amount The amount to release.
     *
     * Requirements:
     * - The caller must be either the contract owner or the vesting schedule beneficiary.
     * - The amount must not exceed the schedule's balance of vested tokens.
     */
    function release(bytes32 vestingScheduleId, uint256 amount) external;

    // - VIEW -
    /**
     * @dev Returns the number of vesting schedules associated to a beneficiary.
     * @return the number of vesting schedules
     */
    function getVestingSchedulesCountByBeneficiary(
        address _beneficiary
    ) external view returns (uint256);

    /**
     * @dev Returns the vesting schedule id at the given index.
     * @return the vesting id
     */
    function getVestingIdAtIndex(uint256 index) external view returns (bytes32);

    /**
     * @notice Returns the vesting schedule information for a given holder and index.
     * @return the vesting schedule structure information
     */
    function getVestingScheduleByAddressAndIndex(
        address holder,
        uint256 index
    ) external view returns (VestingSchedule memory);

    /**
     * @notice Returns the total amount of vesting schedules.
     * @return the total amount of vesting schedules
     */
    function getVestingSchedulesTotalAmount() external view returns (uint256);

    /**
     * @dev Returns the address of the ERC20 token managed by the vesting contract.
     */
    function getToken() external view returns (address);

    /**
     * @dev Returns the number of vesting schedules managed by this contract.
     * @return the number of vesting schedules
     */
    function getVestingSchedulesCount() external view returns (uint256);

    /**
     * @notice Computes the vested amount of tokens for the given vesting schedule identifier.
     * @return the vested amount
     */
    function computeReleasableAmount(bytes32 vestingScheduleId) external view returns (uint256);

    /**
     * @notice Returns the vesting schedule information for a given identifier.
     * @return the vesting schedule structure information
     */
    function getVestingSchedule(
        bytes32 vestingScheduleId
    ) external view returns (VestingSchedule memory);

    /**
     * @dev Returns the amount of tokens that can be withdrawn by the owner.
     * @return the amount of tokens
     */
    function getWithdrawableAmount() external view returns (uint256);

    /**
     * @dev Computes the next vesting schedule identifier for a given holder address.
     */
    function computeNextVestingScheduleIdForHolder(address holder) external view returns (bytes32);

    /**
     * @dev Returns the last vesting schedule for a given holder address.
     */
    function getLastVestingScheduleForHolder(
        address holder
    ) external view returns (VestingSchedule memory);

    /**
     * @dev Computes the vesting schedule identifier for an address and an index.
     */
    function computeVestingScheduleIdForAddressAndIndex(
        address holder,
        uint256 index
    ) external pure returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

struct VestingSchedule {
    // cliff period in seconds
    uint64 cliff;
    // start time of the vesting period
    uint64 start;
    // duration of the vesting period in seconds
    uint64 duration;
    // duration of a slice period for the vesting in seconds
    uint64 slicePeriodSeconds;
    // total amount of tokens to be released at the end of the vesting
    uint256 amountTotal;
    // amount of tokens released
    uint256 released;
    // beneficiary of tokens after they are released
    address beneficiary;
    bool initialized;
    // whether or not the vesting has been revoked
    bool revoked;
    // whether or not the vesting is revocable
    bool revocable;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

struct VestingScheduleConfig {
    // cliff period in seconds
    uint64 cliff;
    // start time of the vesting period
    uint64 start;
    // duration of the vesting period in seconds
    uint64 duration;
    // duration of a slice period for the vesting in seconds
    uint64 slicePeriodSeconds;
    // total amount of tokens to be released at the end of the vesting
    uint256 amountTotal;
    // beneficiary of tokens after they are released
    address beneficiary;
    // whether or not the vesting is revocable
    bool revocable;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface ITokenVestingEvents {
    event VestingScheduleCreated(bytes32 indexed vestingScheduleId, address indexed beneficiary, uint256 indexed amount);
    event VestingScheduleExtended(bytes32 indexed vestingScheduleId, uint32 indexed extensionDuration);
    event VestingScheduleCancelled(bytes32 indexed vestingScheduleId);
    event AmountWithdrawn(uint256 indexed amount);
    event AmountReleased(bytes32 indexed vestingScheduleId, address indexed beneficiary, uint256 indexed amount);
}
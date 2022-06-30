// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8;

import "./interface/CowProtocolTokens.sol";
import "./vendored/Enum.sol";
import "./vendored/ModuleController.sol";

/// @dev Gnosis Safe module used to distribute the Safe's vCOW allocation to other addresses. The module can add new
/// target addresses that will be assigned a linear token allocation. Claims can be reedemed at any time by the target
/// addresses and can be stopped at any time by the team controller.
/// @title COW Allocation Module
/// @author CoW Protocol Developers
contract AllocationModule {
    /// @dev Parameters that describe a linear vesting position for a claimant.
    struct VestingPosition {
        /// @dev Full amount of COW that is to be vested linearly in the designated time.
        uint96 totalAmount;
        /// @dev Amount of COW that the claimant has already redeemed so far.
        uint96 claimedAmount;
        /// @dev Timestamp when this vesting position started.
        uint32 start;
        /// @dev Timespan between vesting start and end.
        uint32 duration;
    }

    /// @dev Gnosis Safe that will enable this module. Its vCOW claims will be used to pay out each target address.
    ModuleController public immutable controller;
    /// @dev The COW token.
    CowProtocolToken public immutable cow;
    /// @dev The virtual COW token.
    CowProtocolVirtualToken public immutable vcow;
    /// @dev Maps each address to its vesting position. An address can have at most a single vesting position.
    mapping(address => VestingPosition) public allocation;

    /// @dev Maximum value that can be stored in the type uint32.00
    uint256 private constant MAX_UINT_32 = (1 << (32)) - 1;

    /// @dev Thrown when creating a vesting position of zero duration.
    error DurationMustNotBeZero();
    /// @dev Thrown when creating a vesting position for an address that already has a vesting position.
    error HasClaimAlready();
    /// @dev Thrown when computing the amount of vested COW of an address that has no allocation.
    error NoClaimAssigned();
    /// @dev Thrown when executing a function that is reserved to the Gnosis Safe that controls this module.
    error NotAController();
    /// @dev Thrown when a claimant tries to claim more COW tokens that the linear vesting allows at this point in time.
    error NotEnoughVestedTokens();
    /// @dev Thrown when the transfer of COW tokens did not succeed.
    error RevertedCowTransfer();

    /// @dev A new linear vesting position is added to the module.
    event ClaimAdded(
        address indexed beneficiary,
        uint32 start,
        uint32 duration,
        uint96 amount
    );
    /// @dev A vesting position is removed from the module.
    event ClaimStopped(address indexed beneficiary);
    /// @dev A claimant redeems an amount of COW tokens from its vesting position.
    event ClaimRedeemed(address indexed beneficiary, uint96 amount);

    /// @dev Restrict the message caller to be the controller of this module.
    modifier onlyController() {
        if (msg.sender != address(controller)) {
            revert NotAController();
        }
        _;
    }

    constructor(address _controller, address _vcow) {
        controller = ModuleController(_controller);
        vcow = CowProtocolVirtualToken(_vcow);
        cow = CowProtocolToken(address(vcow.cowToken()));
    }

    /// @dev Allocates a vesting claim for COW tokens to an address.
    /// @param beneficiary The address to which the new vesting claim will be assigned.
    /// @param duration How long it will take to the beneficiary to vest the entire amount of the claim.
    /// @param amount Amount of COW tokens that will be linearly vested to the beneficiary.
    function addClaim(
        address beneficiary,
        uint32 start,
        uint32 duration,
        uint96 amount
    ) external onlyController {
        if (duration == 0) {
            revert DurationMustNotBeZero();
        }
        if (allocation[beneficiary].totalAmount != 0) {
            revert HasClaimAlready();
        }
        allocation[beneficiary] = VestingPosition({
            totalAmount: amount,
            claimedAmount: 0,
            start: start,
            duration: duration
        });

        emit ClaimAdded(beneficiary, start, duration, amount);
    }

    /// @dev Stops the claim of an address. It first claims the entire amount of COW allocated so far on behalf of the
    /// former beneficiary.
    /// @param beneficiary The address that will see its vesting position stopped.
    function stopClaim(address beneficiary) external onlyController {
        // Note: claiming COW might fail, therefore making it impossible to stop the claim. This is not considered an
        // issue as a claiming failure can only occur in the following cases:
        // 1. No claim is available: then nothing needs to be stopped.
        // 2. This module is no longer enabled in the controller.
        // 3. The COW transfer reverts. This means that there weren't enough vCOW tokens to swap for COW and that there
        // aren't enough COW tokens available in the controller. Sending COW tokens to pay out the remaining claim would
        // allow to stop the claim.
        // 4. Math failures (overflow/underflows). No untrusted value is provided to this function, so this is not
        // expected to happen.
        // solhint-disable-next-line not-rely-on-time
        _claimAllCow(beneficiary, block.timestamp);

        delete allocation[beneficiary];

        emit ClaimStopped(beneficiary);
    }

    /// @dev Computes and sends the entire amount of COW that have been vested so far to the caller.
    /// @return The amount of COW that has been claimed.
    function claimAllCow() external returns (uint96) {
        // solhint-disable-next-line not-rely-on-time
        return _claimAllCow(msg.sender, block.timestamp);
    }

    /// @dev Sends the specified amount of COW to the caller, assuming enough COW has been vested so far.
    function claimCow(uint96 claimedAmount) external {
        address beneficiary = msg.sender;

        (uint96 alreadyClaimedAmount, uint96 fullVestedAmount) = retrieveClaimedAmounts(
            beneficiary,
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );

        claimCowFromAmounts(
            beneficiary,
            claimedAmount,
            alreadyClaimedAmount,
            fullVestedAmount
        );
    }

    /// @dev Returns how many COW tokens are claimable at the current point in time by the given address. Tokens that
    /// were already claimed by the user are not included in the output amount.
    /// @param beneficiary The address that owns the claim.
    /// @return The amount of COW that could be claimed by the beneficiary at this point in time.
    function claimableCow(address beneficiary) external view returns (uint256) {
        if (allocation[beneficiary].totalAmount == 0) {
            return 0;
        }
        (uint96 alreadyClaimedAmount, uint96 fullVestedAmount) = retrieveClaimedAmounts(
            beneficiary,
            // solhint-disable-next-line not-rely-on-time
            block.timestamp
        );

        return fullVestedAmount - alreadyClaimedAmount;
    }

    /// @dev Computes and sends the entire amount of COW that have been vested so far to the beneficiary.
    /// @param beneficiary The address that redeems its claim.
    /// @param timestampAtClaimingTime The timestamp at claiming time.
    /// @return claimedAmount The amount of COW that has been claimed.
    function _claimAllCow(address beneficiary, uint256 timestampAtClaimingTime)
        internal
        returns (uint96 claimedAmount)
    {
        (
            uint96 alreadyClaimedAmount,
            uint96 fullVestedAmount
        ) = retrieveClaimedAmounts(beneficiary, timestampAtClaimingTime);

        claimedAmount = fullVestedAmount - alreadyClaimedAmount;
        claimCowFromAmounts(
            beneficiary,
            claimedAmount,
            alreadyClaimedAmount,
            fullVestedAmount
        );
    }

    /// @dev Computes some values related to a vesting position: how much can be claimed at the specified point in time
    /// and how much has already been claimed.
    /// @param beneficiary The address that is assigned the vesting position to consider.
    /// @param timestampAtClaimingTime The timestamp at claiming time.
    /// @return alreadyClaimedAmount How much of the vesting position has already been claimed.
    /// @return fullVestedAmount How much of the vesting position has been vested at the specified point in time. This
    /// amount does not exclude the amount that has already been claimed.
    function retrieveClaimedAmounts(
        address beneficiary,
        uint256 timestampAtClaimingTime
    )
        internal
        view
        returns (uint96 alreadyClaimedAmount, uint96 fullVestedAmount)
    {
        // Destructure caller position as gas efficiently as possible without assembly.
        VestingPosition memory position = allocation[beneficiary];
        uint96 totalAmount = position.totalAmount;
        alreadyClaimedAmount = position.claimedAmount;
        uint32 start = position.start;
        uint32 duration = position.duration;

        if (totalAmount == 0) {
            revert NoClaimAssigned();
        }

        fullVestedAmount = computeClaimableAmount(
            start,
            timestampAtClaimingTime,
            duration,
            totalAmount
        );
    }

    /// Given the parameters of a vesting position, computes how much of the total amount has been vested so far.
    /// @param start Timestamp when the vesting position was started.
    /// @param current Timestamp of the point in time when the vested amount should be computed.
    /// @param duration How long it takes for this vesting position to be fully vested.
    /// @param totalAmount The total amount that is being vested.
    /// @return The amount that has been vested at the specified point in time.
    function computeClaimableAmount(
        uint32 start,
        uint256 current,
        uint32 duration,
        uint96 totalAmount
    ) internal pure returns (uint96) {
        if (current <= start) {
            return 0;
        }
        uint256 elapsedTime = current - start;
        if (elapsedTime >= duration) {
            return totalAmount;
        }
        return uint96((uint256(totalAmount) * elapsedTime) / duration);
    }

    /// @dev Takes the parameters of a vesting position from its input values and sends out the claimed COW to the
    /// beneficiary, taking care of updating the claimed amount.
    /// @param beneficiary The address that should receive the COW tokens.
    /// @param amount The amount of COW that is claimed by the beneficiary.
    /// @param alreadyClaimedAmount The amount that has already been claimed by the beneficiary.
    /// @param fullVestedAmount The total amount of COW that has been vested so far, which includes the amount that
    /// was already claimed.
    function claimCowFromAmounts(
        address beneficiary,
        uint96 amount,
        uint96 alreadyClaimedAmount,
        uint96 fullVestedAmount
    ) internal {
        uint96 claimedAfterPayout = alreadyClaimedAmount + amount;
        if (claimedAfterPayout > fullVestedAmount) {
            revert NotEnoughVestedTokens();
        }

        allocation[beneficiary].claimedAmount = claimedAfterPayout;
        swapVcowIfAvailable(amount);
        transferCow(beneficiary, amount);

        emit ClaimRedeemed(beneficiary, amount);
    }

    /// @dev Swaps an exact amount of vCOW tokens that are held in the module controller in exchange for COW tokens. The
    /// COW tokens are left in the module controller. If swapping reverts (which means that not enough vCOW are
    /// available) then the failure is ignored.
    /// @param amount The amount of vCOW to swap.
    function swapVcowIfAvailable(uint256 amount) internal {
        // The success status is explicitely ignored. This means that the call to `swap` could revert without reverting
        // the execution of this function. Note that this function can still revert if the call to
        // `execTransactionFromModule` reverts, which could happen for example if this module is no longer enabled in
        // the controller.
        //bool success =
        controller.execTransactionFromModule(
            address(vcow),
            0,
            abi.encodeWithSelector(vcow.swap.selector, amount),
            Enum.Operation.Call
        );
    }

    /// @dev Transfer the specified exact amount of COW tokens that are held in the module controller to the target.
    /// @param to The address that will receive transfer.
    /// @param amount The amount of COW to transfer.
    function transferCow(address to, uint256 amount) internal {
        // Note: the COW token reverts on failed transfer, there is no need to check the return value.
        bool success = controller.execTransactionFromModule(
            address(cow),
            0,
            abi.encodeWithSelector(cow.transfer.selector, to, amount),
            Enum.Operation.Call
        );
        if (!success) {
            revert RevertedCowTransfer();
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8;

/// @dev Interface exposing some of the functions of the governance token for the CoW Protocol.
/// @title CoW Protocol Governance Token Minimal Interface
/// @author CoW Protocol Developers
interface CowProtocolToken {
    /// @dev Moves `amount` tokens from the caller's account to `to`.
    /// Returns true. Reverts if the operation didn't succeed.
    function transfer(address to, uint256 amount) external returns (bool);
}

/// @dev Interface exposing some of the functions of the virtual token for the CoW Protocol.
/// @title CoW Protocol Virtual Token Minimal Interface
/// @author CoW Protocol Developers
interface CowProtocolVirtualToken {
    /// @dev Converts an amount of (virtual) tokens from this contract to real
    /// tokens based on the claims previously performed by the caller.
    /// @param amount How many virtual tokens to convert into real tokens.
    function swap(uint256 amount) external;

    /// @dev Address of the real COW token. Tokens claimed by this contract can
    /// be converted to this token if this contract stores some balance of it.
    function cowToken() external view returns (address);
}

// SPDX-License-Identifier: LGPL-3.0-only

// Vendored from @gnosis.pm/safe-contracts v1.3.0, see:
// <https://raw.githubusercontent.com/gnosis/safe-contracts/v1.3.0/contracts/common/Enum.sol>

pragma solidity >=0.7.0 <0.9.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}

// SPDX-License-Identifier: LGPL-3.0-only

// A contract interface listing the functions that are exposed by a Gnosis Safe v1.3 to work with modules.
// Vendored from @gnosis.pm/zodiac v1.0.6, see:
// <https://raw.githubusercontent.com/gnosis/zodiac/d9b1180436609f6c0a1fc93009d9c28d214fd971/contracts/interfaces/IAvatar.sol>
// Changes:
// - Renamed contract to `ModuleController` to make the interface purpose clearer when imported.
// - Vendored imports.

/// @title Zodiac Avatar - A contract that manages modules that can execute transactions via this contract.
pragma solidity >=0.7.0 <0.9.0;

import "./Enum.sol";

interface ModuleController {
    /// @dev Enables a module on the avatar.
    /// @notice Can only be called by the avatar.
    /// @notice Modules should be stored as a linked list.
    /// @notice Must emit EnabledModule(address module) if successful.
    /// @param module Module to be enabled.
    function enableModule(address module) external;

    /// @dev Disables a module on the avatar.
    /// @notice Can only be called by the avatar.
    /// @notice Must emit DisabledModule(address module) if successful.
    /// @param prevModule Address that pointed to the module to be removed in the linked list
    /// @param module Module to be removed.
    function disableModule(address prevModule, address module) external;

    /// @dev Allows a Module to execute a transaction.
    /// @notice Can only be called by an enabled module.
    /// @notice Must emit ExecutionFromModuleSuccess(address module) if successful.
    /// @notice Must emit ExecutionFromModuleFailure(address module) if unsuccessful.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success);

    /// @dev Allows a Module to execute a transaction and return data
    /// @notice Can only be called by an enabled module.
    /// @notice Must emit ExecutionFromModuleSuccess(address module) if successful.
    /// @notice Must emit ExecutionFromModuleFailure(address module) if unsuccessful.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external returns (bool success, bytes memory returnData);

    /// @dev Returns if an module is enabled
    /// @return True if the module is enabled
    function isModuleEnabled(address module) external view returns (bool);

    /// @dev Returns array of modules.
    /// @param start Start of the page.
    /// @param pageSize Maximum number of modules that should be returned.
    /// @return array Array of modules.
    /// @return next Start of the next page.
    function getModulesPaginated(address start, uint256 pageSize)
        external
        view
        returns (address[] memory array, address next);
}
pragma solidity ^0.8.10;

import "./VestedERC20/VestedERC20.sol";

contract vsePSP is VestedERC20 {
    string constant NAME = "Vested Social Escrowed PSP";
    string constant SYMBOL = "vsePSP";
    uint8 constant DECIMALS = 18;

    constructor(
        address token,
        bytes32 merkleRoot,
        bool onlyClaimer,
        uint256 vestingStart,
        uint256 vestingPeriodSeconds,
        uint256 claimingEnd
    )
        VestedERC20(
            NAME,
            SYMBOL,
            DECIMALS,
            token,
            merkleRoot,
            onlyClaimer,
            vestingStart,
            vestingPeriodSeconds,
            claimingEnd
        )
    {}
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.10;

import "./mixins/NonTransferrableErc20.sol";
import "./mixins/Vesting.sol";
import "./mixins/Claiming.sol";
import "./mixins/MerkleDistributor.sol";
import "./vendored/mixins/StorageAccessible.sol";

/// @dev This contract is inspired by Cow Protocol Virtual Token contract
// The logic and files have been trimmed to keep one base feature:
// equal linear vesting for all participants through a non transferrable ERC20.
/// @author CoW Protocol Developers originally, modified by ParaSwap Developers
contract VestedERC20 is
    NonTransferrableErc20,
    Vesting,
    Claiming,
    MerkleDistributor,
    StorageAccessible
{
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address token,
        bytes32 merkleRoot,
        bool onlyClaimer,
        uint256 vestingStart,
        uint256 vestingPeriodSeconds,
        uint256 claimingEndDuration
    )
        NonTransferrableErc20(name, symbol, decimals)
        Claiming(token, vestingStart + claimingEndDuration)
        MerkleDistributor(merkleRoot, onlyClaimer)
        Vesting(vestingStart, vestingPeriodSeconds)
    // solhint-disable-next-line no-empty-blocks
    {

    }

    /// @dev Returns the sum of tokens that are either held as
    /// instantlySwappableBalance or will be vested in the future
    /// @param user The user for whom the balance is calculated
    /// @return Balance of the user
    function balanceOf(address user) public view returns (uint256) {
        return
            instantlySwappableBalance[user] +
            fullAllocation[user] -
            vestedAllocation[user];
    }

    /// @dev Returns the balance of a user assuming all vested tokens would
    /// have been converted into virtual tokens
    /// @param user The user for whom the balance is calculated
    /// @return Balance the user would have after calling `swapAll`
    function swappableBalanceOf(address user) public view returns (uint256) {
        return instantlySwappableBalance[user] + newlyVestedBalance(user);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.10;

import "../vendored/interfaces/IERC20.sol";

/// @dev A contract of an ERC20 token that cannot be transferred.
/// @title Non-Transferrable ERC20
/// @author CoW Protocol Developers originally, modified by ParaSwap Developers
abstract contract NonTransferrableErc20 is IERC20 {
    /// @dev The ERC20 name of the token
    string public name;
    /// @dev The ERC20 symbol of the token
    string public symbol;
    /// @dev The ERC20 number of decimals of the token
    uint8 public decimals;

    // solhint-disable-next-line no-empty-blocks
    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /// @dev This error is fired when trying to perform an action that is not
    /// supported by the contract, like transfers and approvals. These actions
    /// will never be supported.
    error NotSupported();

    /// @dev All types of transfers are permanently disabled.
    function transferFrom(
        address,
        address,
        uint256
    ) public pure returns (bool) {
        revert NotSupported();
    }

    /// @dev All types of transfers are permanently disabled.
    function transfer(address, uint256) public pure returns (bool) {
        revert NotSupported();
    }

    /// @dev All types of approvals are permanently disabled to reduce code
    /// size.
    function approve(address, uint256) public pure returns (bool) {
        revert NotSupported();
    }

    /// @dev Approvals cannot be set, so allowances are always zero.
    function allowance(address, address) public pure returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.10;

import "../vendored/interfaces/IERC20.sol";
import "../vendored/libraries/SafeERC20.sol";

import "../interfaces/ClaimingInterface.sol";
import "../interfaces/VestingInterface.sol";

import "openzeppelin-solidity/contracts/access/Ownable.sol";

/// @dev The logic behind the claiming of virtual tokens and the swapping to
/// real tokens.
/// @title COW Virtual Token Claiming Logic
/// @author CoW Protocol Developers originally, modified by ParaSwap Developers
abstract contract Claiming is ClaimingInterface, VestingInterface, IERC20, Ownable {
    using SafeERC20 for IERC20;
    
    /// @dev Address of the actual token vested.. Tokens claimed by this contract can
    /// be converted to this token if this contract stores some balance of it.
    IERC20 public immutable token;

    /// @dev Returns the date at which claiming is not possible
    uint256 public immutable claimingEnd;

    /// @dev Returns the amount of virtual tokens in existence, including those
    /// that have yet to be vested.
    uint256 public totalSupply;

    /// @dev How many tokens can be immediately swapped in exchange for real
    /// tokens for each user.
    mapping(address => uint256) public instantlySwappableBalance;

    constructor(
        address _token,
        uint256 _claimingEnd
    ) {
        token = IERC20(_token);
        claimingEnd = _claimingEnd;
    }

    /// @dev Error presented to a user trying to claim virtual tokens after the
    /// claiming period has ended.
    error ClaimingExpired();

    /// @dev Error presented to a owner trying to claim actual token 
    /// before claiming period ended;
    error ClaimingHasNotExpired();

    /// @dev Claim cannot be canceled.
    /// @param claimant The user for which the claim is performed.
    /// @param amount The full amount claimed by the user after vesting.
    /// @inheritdoc ClaimingInterface
    function performClaim(
        address claimant,
        uint256 amount
    ) internal override {
         if(block.timestamp > claimingEnd) {
            revert ClaimingExpired();
        }

         addVesting(claimant, amount);

        // Each claiming operation results in the creation of `amount` virtual
        // tokens.
        totalSupply += amount;
        emit Transfer(address(0), claimant, amount);
    }

    /// @dev Converts an amount of (virtual) tokens from this contract to real
    /// tokens based on the claims previously performed by the caller.
    /// @param amount How many virtual tokens to convert into real tokens.
    function swap(uint256 amount) external {
        makeVestingSwappable();
        _swap(amount);
    }

    /// @dev Converts all available (virtual) tokens from this contract to real
    /// tokens based on the claims previously performed by the caller.
    /// @return swappedBalance The full amount that was swapped (i.e., virtual
    /// tokens burnt as well as real tokens received).
    function swapAll() external returns (uint256 swappedBalance) {
        swappedBalance = makeVestingSwappable();
        _swap(swappedBalance);
    }

    /// @dev Transfers real tokens to the message sender and reduces the balance
    /// of virtual tokens available. Note that this function assumes that the
    /// current contract stores enough real tokens to fulfill this swap request.
    /// @param amount How many virtual tokens to convert into real tokens.
    function _swap(uint256 amount) private {
        instantlySwappableBalance[msg.sender] -= amount;
        totalSupply -= amount;
        token.safeTransfer(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
    }

    /// @dev Adds the currently vested amount to the immediately swappable
    /// balance.
    /// @return swappableBalance The maximum balance that can be swapped at
    /// this point in time by the caller.
    function makeVestingSwappable() private returns (uint256 swappableBalance) {
        swappableBalance =
            instantlySwappableBalance[msg.sender] +
            vest(msg.sender);
        instantlySwappableBalance[msg.sender] = swappableBalance;
    }

    /// @dev This function allows owner to withdraw unallocated tokens
    /// after the claiming period ended
    function withdrawUnclaimed() external override onlyOwner {
        if(block.timestamp < claimingEnd) {
            revert ClaimingHasNotExpired();
        }

        uint256 unallocatedAmount = token.balanceOf(address(this)) - totalSupply;
        token.transfer(owner(), unallocatedAmount);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later

// This contract is based on Uniswap's MekleDistributor, which can be found at:
// https://github.com/Uniswap/merkle-distributor/blob/0d478d722da2e5d95b7292fd8cbdb363d98e9a93/contracts/MerkleDistributor.sol
//
// The changes between the original contract and this are:
//  - the claim function doesn't trigger a transfer on a successful proof, but
//    it executes a dedicated (virtual) function.
//  - added a claimMany function for bundling multiple claims in a transaction
//  - supported sending an amount of native tokens along with the claim
//  - added the option of claiming less than the maximum amount
//  - gas optimizations in the packing and unpacking of the claimed bit
//  - bumped Solidity version
//  - code formatting

pragma solidity ^0.8.10;

import "../vendored/interfaces/IERC20.sol";
import "../vendored/libraries/MerkleProof.sol";

import "../interfaces/ClaimingInterface.sol";

abstract contract MerkleDistributor is ClaimingInterface {
    bytes32 public immutable merkleRoot;
    bool public immutable onlyClaimer;

    /// @dev Event fired if a claim was successfully performed.
    event Claimed(
        uint256 index,
        address claimant,
        uint256 claimableAmount,
        uint256 claimedAmount
    );

    /// @dev Error caused by a user trying to call the claim function for a
    /// claim that has already been used before.
    error AlreadyClaimed();
    /// @dev Error caused by a user trying to claim a larger amount than the
    /// maximum allowed in the claim.
    error ClaimingMoreThanMaximum();
    /// @dev Error caused by the caller trying to to claim why not
    /// not being the owner of the claim if contract has been initialised with onlyClaimer
    error OnlyOwnerCanClaim();
    /// @dev Error caused by the caller trying to perform a partial claim while
    /// not being the owner of the claim.
    error OnlyOwnerCanClaimPartially();
    /// @dev Error caused by calling the claim function with an invalid proof.
    error InvalidProof();
    /// @dev Error caused by calling claimMany with a transaction value that is
    /// different from the required one.
    error InvalidNativeTokenValue();

    /// @dev Packed array of booleans that stores if a claim is available.
    mapping(uint256 => uint256) private claimedBitMap;

    constructor(bytes32 merkleRoot_, bool _onlyClaimer) {
        merkleRoot = merkleRoot_;
        onlyClaimer = _onlyClaimer;
    }

    /// @dev Checks if the claim at the provided index has already been claimed.
    /// @param index The index to check.
    /// @return Whether the claim at the given index has already been claimed.
    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index >> 8;
        uint256 claimedBitIndex = index & 0xff;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask != 0;
    }

    /// @dev Mark the provided index as having been claimed.
    /// @param index The index that was claimed.
    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index >> 8;
        uint256 claimedBitIndex = index & 0xff;
        claimedBitMap[claimedWordIndex] =
            claimedBitMap[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    /// @dev This function verifies the provided input proof based on the
    /// provided input. If the proof is valid, the function [`performClaim`] is
    /// called for the claimed amount.
    /// @param index The index that identifies the input claim.
    /// @param claimant See [`performClaim`].
    /// @param claimableAmount The maximum amount that the claimant can claim
    /// for this claim. Should not be smaller than claimedAmount.
    /// @param claimedAmount See [`performClaim`].
    /// @param merkleProof A proof that the input claim belongs to the unique
    /// Merkle root associated to this contract.
    function claim(
        uint256 index,
        address claimant,
        uint256 claimableAmount,
        uint256 claimedAmount,
        bytes32[] calldata merkleProof
    ) external {
        _claim(
            index,
            claimant,
            claimableAmount,
            claimedAmount,
            merkleProof
        );
    }

    /// @dev This function verifies and executes multiple claims in the same
    /// transaction.
    /// @param indices A vector of indices. See [`claim`] for details.
    /// @param claimants A vector of claimants. See [`performClaim`] for
    /// details.
    /// @param claimableAmounts A vector of claimable amounts. See [`claim`] for
    /// details.
    /// @param claimedAmounts A vector of claimed amounts. See [`performClaim`]
    /// for details.
    /// @param merkleProofs A vector of merkle proofs. See [`claim`] for
    /// details.
    function claimMany(
        uint256[] memory indices,
        address[] calldata claimants,
        uint256[] calldata claimableAmounts,
        uint256[] calldata claimedAmounts,
        bytes32[][] calldata merkleProofs
    ) external {
        for (uint256 i = 0; i < indices.length; i++) {
            _claim(
                indices[i],
                claimants[i],
                claimableAmounts[i],
                claimedAmounts[i],
                merkleProofs[i]
            );
        }
    }

    /// @dev This function verifies the provided input proof based on the
    /// provided input. If the proof is valid, the function [`performClaim`] is
    /// called for the claimed amount.
    /// @param index See [`claim`].
    /// @param claimant See [`performClaim`].
    /// @param claimableAmount See [`claim`].
    /// @param claimedAmount See [`performClaim`].
    /// @param merkleProof See [`claim`].
    function _claim(
        uint256 index,
        address claimant,
        uint256 claimableAmount,
        uint256 claimedAmount,
        bytes32[] calldata merkleProof
    ) private {
        if(onlyClaimer == true && msg.sender != claimant) {
            revert OnlyOwnerCanClaim();
        }

        if (isClaimed(index)) {
            revert AlreadyClaimed();
        }
        if (claimedAmount > claimableAmount) {
            revert ClaimingMoreThanMaximum();
        }
        if ((claimedAmount < claimableAmount) && (msg.sender != claimant)) {
            revert OnlyOwnerCanClaimPartially();
        }

        // Note: all types used inside `encodePacked` should have fixed length,
        // otherwise the same proof could be used in different claims.
        bytes32 node = keccak256(
            abi.encodePacked(index, claimant, claimableAmount)
        );
        if (!MerkleProof.verify(merkleProof, merkleRoot, node)) {
            revert InvalidProof();
        }

        _setClaimed(index);

        performClaim(
            claimant,
            claimedAmount
        );

        emit Claimed(
            index,
            claimant,
            claimableAmount,
            claimedAmount
        );
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.10;

import "../vendored/libraries/Math.sol";

import "../interfaces/VestingInterface.sol";

/// @dev The vesting logic for distributing the COW token
/// @title Vesting Logic
/// @author CoW Protocol Developers originally, modified by ParaSwap Developers
contract Vesting is VestingInterface {
    /// @dev The timestamp of the official vesting start. This value is shared
    /// between all participants.
    uint256 public immutable vestingStart;
    /// @dev How long it will take for all vesting to be completed.
    uint256 public immutable vestingPeriodSeconds;

    /// @dev Stores the amount of vesting that the user has already vested.
    mapping(address => uint256) public vestedAllocation;
    /// @dev Stores the maximum amount of vesting available to each user. This
    /// is exactly the total amount of vesting that can be converted after the
    /// vesting period is completed.
    mapping(address => uint256) public fullAllocation;

    /// @dev Event emitted when a new vesting position is added. The amount is
    /// the additional amount that can be vested at the end of the
    /// claiming period.
    event VestingAdded(address indexed user, uint256 amount);

    /// @dev Event emitted when the users claims (also partially) a vesting
    /// position.
    event Vested(address indexed user, uint256 amount);

    /// @dev Error that prevents deploying this contract with vesting time in the past
    error VestingOutOfRange();

    /// @dev Error that prevents deploying this contract with expiration time in the past
    error ExpirationOutOfRange();

    constructor(uint256 _vestingStart, uint256 _vestingPeriodSeconds) {
        if(block.timestamp > _vestingStart + _vestingPeriodSeconds) {
            revert VestingOutOfRange();
        }

        vestingStart = _vestingStart;
        vestingPeriodSeconds = _vestingPeriodSeconds;
    }

    /// @inheritdoc VestingInterface
    function addVesting(
        address user,
        uint256 vestingAmount
    ) internal override {
        fullAllocation[user] += vestingAmount;
        emit VestingAdded(user, vestingAmount);
    }

    /// @inheritdoc VestingInterface
    function vest(address user)
        internal
        override
        returns (uint256 newlyVested)
    {
        newlyVested = newlyVestedBalance(user);
        vestedAllocation[user] += newlyVested;
        emit Vested(user, newlyVested);
    }

    /// @dev Assuming no conversions has been done by the user, calculates how
    /// much vesting can be converted at this point in time.
    /// @param user The user for whom the result is being calculated.
    /// @return How much vesting can be converted if no conversions had been
    /// done before.
    function cumulativeVestedBalance(address user)
        public
        view
        returns (uint256)
    {
        return
            (Math.min(
                block.timestamp - vestingStart, // solhint-disable-line not-rely-on-time
                vestingPeriodSeconds
            ) * fullAllocation[user]) / (vestingPeriodSeconds);
    }

    /// @dev Calculates how much vesting can be converted at this point in time.
    /// Unlike `cumulativeVestedBalance`, this function keeps track of previous
    /// conversions.
    /// @param user The user for whom the result is being calculated.
    /// @return How much vesting can be converted.
    function newlyVestedBalance(address user) public view returns (uint256) {
        return cumulativeVestedBalance(user) - vestedAllocation[user];
    }
}

// SPDX-License-Identifier: LGPL-3.0-only

// Vendored from Gnosis utility contracts, see:
// <https://raw.githubusercontent.com/gnosis/gp-v2-contracts/40c349d52d14f8f3c9f787fe2fca5a496bb10ea9/src/contracts/mixins/StorageAccessible.sol>
// The following changes were made:
// - Modified Solidity version
// - Formatted code

pragma solidity ^0.8.10;

/// @title ViewStorageAccessible - Interface on top of StorageAccessible base class to allow simulations from view functions
interface ViewStorageAccessible {
    /**
     * @dev Same as `simulateDelegatecall` on StorageAccessible. Marked as view so that it can be called from external contracts
     * that want to run simulations from within view functions. Will revert if the invoked simulation attempts to change state.
     */
    function simulateDelegatecall(
        address targetContract,
        bytes memory calldataPayload
    ) external view returns (bytes memory);

    /**
     * @dev Same as `getStorageAt` on StorageAccessible. This method allows reading aribtrary ranges of storage.
     */
    function getStorageAt(uint256 offset, uint256 length)
        external
        view
        returns (bytes memory);
}

/// @title StorageAccessible - generic base contract that allows callers to access all internal storage.
contract StorageAccessible {
    /**
     * @dev Reads `length` bytes of storage in the currents contract
     * @param offset - the offset in the current contract's storage in words to start reading from
     * @param length - the number of words (32 bytes) of data to read
     * @return the bytes that were read.
     */
    function getStorageAt(uint256 offset, uint256 length)
        external
        view
        returns (bytes memory)
    {
        bytes memory result = new bytes(length * 32);
        for (uint256 index = 0; index < length; index++) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let word := sload(add(offset, index))
                mstore(add(add(result, 0x20), mul(index, 0x20)), word)
            }
        }
        return result;
    }

    /**
     * @dev Performs a delegetecall on a targetContract in the context of self.
     * Internally reverts execution to avoid side effects (making it static). Catches revert and returns encoded result as bytes.
     * @param targetContract Address of the contract containing the code to execute.
     * @param calldataPayload Calldata that should be sent to the target contract (encoded method name and arguments).
     */
    function simulateDelegatecall(
        address targetContract,
        bytes memory calldataPayload
    ) public returns (bytes memory response) {
        bytes memory innerCall = abi.encodeWithSelector(
            this.simulateDelegatecallInternal.selector,
            targetContract,
            calldataPayload
        );
        // solhint-disable-next-line avoid-low-level-calls
        (, response) = address(this).call(innerCall);
        bool innerSuccess = response[response.length - 1] == 0x01;
        setLength(response, response.length - 1);
        if (innerSuccess) {
            return response;
        } else {
            revertWith(response);
        }
    }

    /**
     * @dev Performs a delegetecall on a targetContract in the context of self.
     * Internally reverts execution to avoid side effects (making it static). Returns encoded result as revert message
     * concatenated with the success flag of the inner call as a last byte.
     * @param targetContract Address of the contract containing the code to execute.
     * @param calldataPayload Calldata that should be sent to the target contract (encoded method name and arguments).
     */
    function simulateDelegatecallInternal(
        address targetContract,
        bytes memory calldataPayload
    ) external returns (bytes memory response) {
        bool success;
        // solhint-disable-next-line avoid-low-level-calls
        (success, response) = targetContract.delegatecall(calldataPayload);
        revertWith(abi.encodePacked(response, success));
    }

    function revertWith(bytes memory response) internal pure {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            revert(add(response, 0x20), mload(response))
        }
    }

    function setLength(bytes memory buffer, uint256 length) internal pure {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(buffer, length)
        }
    }
}

// SPDX-License-Identifier: MIT

// Vendored from OpenZeppelin Contracts v4.4.0, see:
// <https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.4.0/contracts/token/ERC20/IERC20.sol>

// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.10;

/// @dev The contract functions that are shared between the `Claiming` and
/// `MerkleDistributor` contracts. The two components are handled and tested
/// separately and are linked to each other by the functions in this contract.
/// This contracs is for all intents and purposes an interface, however actual
/// interfaces cannot declare internal functions.
/// @title COW token claiming interface.
/// @author CoW Protocol Developers originally, modified by ParaSwap Developers
abstract contract ClaimingInterface {
    /// @dev This function is executed when a valid proof of the claim is
    /// provided and executes all steps required for each claim type.
    /// @param claimant The account to which the claim is assigned and which
    /// will receive the corresponding virtual tokens.
    /// @param claimedAmount The amount that the user decided to claim (after
    /// vesting if it applies).
    function performClaim(
        address claimant,
        uint256 claimedAmount
    ) internal virtual;

     /// @dev This function allows owner to withdraw unallocated tokens 
     /// after the claiming period ended
    function withdrawUnclaimed() external virtual;
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.10;

/// @dev The contract functions that are shared between the `Vesting` and
/// `Claiming` contracts. The two components are handled and tested
/// separately and are linked to each other by the functions in this contract.
/// This contracs is for all intents and purposes an interface, however actual
/// interfaces cannot declare internal functions.
/// @title COW token vesting interface.
/// @author CoW Protocol Developers originally, modified by ParaSwap Developers
abstract contract VestingInterface {
    /// @dev Adds an amount that will be vested over time.
    /// Should be called from the parent contract on redeeming a vested claim.
    /// @param user The user for whom the vesting is performed.
    /// @param vestingAmount The (added) amount to be vested in time.
    function addVesting(
        address user,
        uint256 vestingAmount
    ) internal virtual;

    /// @dev Computes the current vesting from the total vested amount and marks
    /// that amount as converted. This is called by the parent contract every
    /// time virtual tokens from a vested claim are swapped into real tokens.
    /// @param user The user for which the amount is vested.
    /// @return Amount converted.
    function vest(address user) internal virtual returns (uint256);
}

// SPDX-License-Identifier: LGPL-3.0-or-later

// Vendored from GPv2 contracts v1.1.2, see:
// <https://raw.githubusercontent.com/gnosis/gp-v2-contracts/7fb88982021e9a274d631ffb598694e6d9b30089/src/contracts/libraries/GPv2SafeERC20.sol>
// The following changes were made:
// - Bumped up Solidity version and checked that the assembly is still valid.
// - Use own vendored IERC20 instead of custom implementation.
// - Removed "GPv2" from contract name.
// - Modified revert messages, including length.

pragma solidity ^0.8.10;

import "../interfaces/IERC20.sol";

/// @title Gnosis Protocol v2 Safe ERC20 Transfer Library
/// @author Gnosis Developers
/// @dev Gas-efficient version of Openzeppelin's SafeERC20 contract.
library SafeERC20 {
    /// @dev Wrapper around a call to the ERC20 function `transfer` that reverts
    /// also when the token returns `false`.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        bytes4 selector_ = token.transfer.selector;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, selector_)
            mstore(
                add(freeMemoryPointer, 4),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            )
            mstore(add(freeMemoryPointer, 36), value)

            if iszero(call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        require(getLastTransferResult(token), "SafeERC20: failed transfer");
    }

    /// @dev Wrapper around a call to the ERC20 function `transferFrom` that
    /// reverts also when the token returns `false`.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        bytes4 selector_ = token.transferFrom.selector;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, selector_)
            mstore(
                add(freeMemoryPointer, 4),
                and(from, 0xffffffffffffffffffffffffffffffffffffffff)
            )
            mstore(
                add(freeMemoryPointer, 36),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            )
            mstore(add(freeMemoryPointer, 68), value)

            if iszero(call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        require(getLastTransferResult(token), "SafeERC20: failed transferFrom");
    }

    /// @dev Verifies that the last return was a successful `transfer*` call.
    /// This is done by checking that the return data is either empty, or
    /// is a valid ABI encoded boolean.
    function getLastTransferResult(IERC20 token)
        private
        view
        returns (bool success)
    {
        // NOTE: Inspecting previous return data requires assembly. Note that
        // we write the return data to memory 0 in the case where the return
        // data size is 32, this is OK since the first 64 bytes of memory are
        // reserved by Solidy as a scratch space that can be used within
        // assembly blocks.
        // <https://docs.soliditylang.org/en/v0.8.10/internals/layout_in_memory.html>
        // solhint-disable-next-line no-inline-assembly
        assembly {
            /// @dev Revert with an ABI encoded Solidity error with a message
            /// that fits into 32-bytes.
            ///
            /// An ABI encoded Solidity error has the following memory layout:
            ///
            /// ------------+----------------------------------
            ///  byte range | value
            /// ------------+----------------------------------
            ///  0x00..0x04 |        selector("Error(string)")
            ///  0x04..0x24 |      string offset (always 0x20)
            ///  0x24..0x44 |                    string length
            ///  0x44..0x64 | string value, padded to 32-bytes
            function revertWithMessage(length, message) {
                mstore(0x00, "\x08\xc3\x79\xa0")
                mstore(0x04, 0x20)
                mstore(0x24, length)
                mstore(0x44, message)
                revert(0x00, 0x64)
            }

            switch returndatasize()
            // Non-standard ERC20 transfer without return.
            case 0 {
                // NOTE: When the return data size is 0, verify that there
                // is code at the address. This is done in order to maintain
                // compatibility with Solidity calling conventions.
                // <https://docs.soliditylang.org/en/v0.8.10/control-structures.html#external-function-calls>
                if iszero(extcodesize(token)) {
                    revertWithMessage(25, "SafeERC20: not a contract")
                }

                success := 1
            }
            // Standard ERC20 transfer returning boolean success value.
            case 32 {
                returndatacopy(0, 0, returndatasize())

                // NOTE: For ABI encoding v1, any non-zero value is accepted
                // as `true` for a boolean. In order to stay compatible with
                // OpenZeppelin's `SafeERC20` library which is known to work
                // with the existing ERC20 implementation we care about,
                // make sure we return success for any non-zero return value
                // from the `transfer*` call.
                success := iszero(iszero(mload(0)))
            }
            default {
                revertWithMessage(30, "SafeERC20: bad transfer result")
            }
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

// Vendored from OpenZeppelin Contracts v4.4.0, see:
// <https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.4.0/contracts/utils/cryptography/MerkleProof.sol>

// OpenZeppelin Contracts v4.4.0 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }
        return computedHash;
    }
}

// SPDX-License-Identifier: MIT

// Vendored from OpenZeppelin Contracts v4.4.0, see:
// <https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.4.0/contracts/utils/math/Math.sol>

// OpenZeppelin Contracts v4.4.0 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}
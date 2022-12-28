// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ERC2771Context} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title IdRegistry
 * @author @v
 * @custom:version 2.0.0
 *
 * @notice IdRegistry enables any ETH address to claim a unique Farcaster ID (fid). An address
 *         can only custody one fid at a time and may transfer it to another address. The Registry
 *         starts in a trusted mode where only a trusted caller can register an fid and can move
 *         to an untrusted mode where any address can register an fid. The Registry implements
 *         a recovery system which allows the custody address to nominate a recovery address that
 *         can transfer the fid to a new address after a delay.
 */
contract IdRegistry is ERC2771Context, Ownable {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev Revert when the caller does not have the authority to perform the action
    error Unauthorized();

    /// @dev Revert when the caller is required to have an fid but does not have one.
    error HasNoId();

    /// @dev Revert when the destination is required to be empty, but has an fid.
    error HasId();

    /// @dev Revert if trustedRegister is invoked after trustedCallerOnly is disabled
    error Registrable();

    /// @dev Revert if register is invoked before trustedCallerOnly is disabled
    error Invitable();

    /// @dev Revert if a recovery operation is called when there is no active recovery.
    error NoRecovery();

    /// @dev Revert when completeRecovery() is called before the escrow period has elapsed.
    error Escrow();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Emit an event when a new Farcaster ID is registered.
     *
     * @param to       The custody address that owns the fid
     * @param id       The fid that was registered.
     * @param recovery The address that can initiate a recovery request for the fid
     * @param url      The home url of the fid
     */
    event Register(address indexed to, uint256 indexed id, address recovery, string url);

    /**
     * @dev Emit an event when a Farcaster ID is transferred to a new custody address.
     *
     * @param from The custody address that previously owned the fid
     * @param to   The custody address that now owns the fid
     * @param id   The fid that was transferred.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    /**
     * @dev Emit an event when a Farcaster ID's home url is updated
     *
     * @param id  The fid whose home url was updated.
     * @param url The new home url.
     */
    event ChangeHome(uint256 indexed id, string url);

    /**
     * @dev Emit an event when a Farcaster ID's recovery address is updated
     *
     * @param id       The fid whose recovery address was updated.
     * @param recovery The new recovery address.
     */
    event ChangeRecoveryAddress(uint256 indexed id, address indexed recovery);

    /**
     * @dev Emit an event when a recovery request is initiated for a Farcaster Id
     *
     * @param from The custody address of the fid being recovered.
     * @param to   The destination address for the fid when the recovery is completed.
     * @param id   The id being recovered.
     */
    event RequestRecovery(address indexed from, address indexed to, uint256 indexed id);

    /**
     * @dev Emit an event when a recovery request is cancelled
     *
     * @param by  The address that cancelled the recovery request
     * @param id  The id being recovered.
     */
    event CancelRecovery(address indexed by, uint256 indexed id);

    /**
     * @dev Emit an event when the trusted caller is modified.
     *
     * @param trustedCaller The address of the new trusted caller.
     */
    event ChangeTrustedCaller(address indexed trustedCaller);

    /**
     * @dev Emit an event when the trusted only state is disabled.
     */
    event DisableTrustedOnly();

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 private constant ESCROW_PERIOD = 3 days;

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev The last farcaster id that was issued.
     */
    uint256 internal idCounter;

    /**
     * @dev The Farcaster Invite service address that is allowed to call trustedRegister.
     */
    address internal trustedCaller;

    /**
     * @dev The address is allowed to call _completeTransferOwnership() and become the owner. Set to
     *      address(0) when no ownership transfer is pending.
     */
    address internal pendingOwner;

    /**
     * @dev Allows calling trustedRegister() when set 1, and register() when set to 0. The value is
     *      set to 1 and can be changed to 0, but never back to 1.
     */
    uint256 internal trustedOnly = 1;

    /**
     * @notice Maps each address to a fid, or zero if it does not own a fid.
     */
    mapping(address => uint256) public idOf;

    /**
     * @dev Maps each fid to an address that can initiate a recovery.
     */
    mapping(uint256 => address) internal recoveryOf;

    /**
     * @dev Maps each fid to the timestamp at which the recovery request was started. This is set
     *      to zero when there is no active recovery.
     */
    mapping(uint256 => uint256) internal recoveryClockOf;

    /**
     * @dev Maps each fid to the destination for the last recovery attempted. This value is left
     *      dirty to save gas and a non-zero value does not indicate an active recovery.
     */
    mapping(uint256 => address) internal recoveryDestinationOf;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Set the owner of the contract to the deployer and configure the trusted forwarder.
     *
     * @param _forwarder The address of the ERC2771 forwarder contract that this contract trusts to
     *                  verify the authenticity of signed meta-transaction requests.
     */
    // solhint-disable-next-line no-empty-blocks
    constructor(address _forwarder) ERC2771Context(_forwarder) Ownable() {}

    /*//////////////////////////////////////////////////////////////
                             REGISTRATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Register a new, unique Farcaster ID (fid) for an address that doesn't have one. This
     *        method can be called by anyone when trustedOnly is set to 0.
     *
     * @param to       The address which will control the fid
     * @param recovery The address which can recover the fid
     * @param url      The home url for the fid's off-chain data
     */
    function register(
        address to,
        address recovery,
        string calldata url
    ) external {
        // Perf: Don't check to == address(0) to save 29 gas since 0x0 can only register 1 fid

        if (trustedOnly == 1) revert Invitable();

        _unsafeRegister(to, recovery);

        // Perf: instead of returning the id from _unsafeRegister, fetch the latest value of idCounter
        emit Register(to, idCounter, recovery, url);
    }

    /**
     * @notice Register a new unique Farcaster ID (fid) for an address that does not have one. This
     *         can only be invoked by the trusted caller when trustedOnly is set to 1.
     *
     * @param to       The address which will control the fid
     * @param recovery The address which can recover the fid
     * @param url      The home url for the fid's off-chain data
     */
    function trustedRegister(
        address to,
        address recovery,
        string calldata url
    ) external {
        // Perf: Don't check to == address(0) to save 29 gas since 0x0 can only register 1 fid

        if (trustedOnly == 0) revert Registrable();

        // Perf: Check msg.sender instead of msgSender() because saves 100 gas and trusted caller
        // doesn't need meta transactions
        if (msg.sender != trustedCaller) revert Unauthorized();

        _unsafeRegister(to, recovery);

        // Assumption: the most recent value of the idCounter must equal the id of this user
        emit Register(to, idCounter, recovery, url);
    }

    /**
     * @notice Emit an event with a new home url if the caller owns an fid. This function supports
     *         ERC 2771 meta-transactions and can be called via a relayer.
     *
     * @param url The new home url for the fid
     */
    function changeHome(string calldata url) external {
        uint256 id = idOf[_msgSender()];
        if (id == 0) revert HasNoId();

        emit ChangeHome(id, url);
    }

    /**
     * @dev Registers a new, unique fid and sets up a recovery address for a caller without
     *      checking any invariants or emitting events.
     */
    function _unsafeRegister(address to, address recovery) internal {
        // Perf: inlining this can save ~ 20-40 gas per call at the expense of readability
        if (idOf[to] != 0) revert HasId();

        unchecked {
            idCounter++;
        }

        // Incrementing before assigning ensures that 0 is never issued as a valid ID.
        idOf[to] = idCounter;
        recoveryOf[idCounter] = recovery;
    }

    /*//////////////////////////////////////////////////////////////
                             TRANSFER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Transfer the fid owned by this address to another address that does not have an fid.
     *         Supports ERC 2771 meta-transactions and can be called via a relayer.
     *
     * @param to The address to transfer the fid to.
     */
    function transfer(address to) external {
        address sender = _msgSender();
        uint256 id = idOf[sender];

        // Ensure that the caller owns an fid and that the destination address does not.
        if (id == 0) revert HasNoId();
        if (idOf[to] != 0) revert HasId();

        _unsafeTransfer(id, sender, to);
    }

    /**
     * @dev Transfer the fid to another address, clear the recovery address and reset active
     *      recovery requests, without checking any invariants.
     */
    function _unsafeTransfer(
        uint256 id,
        address from,
        address to
    ) internal {
        idOf[to] = id;
        delete idOf[from];

        // Perf: clear any active recovery requests, but check if they exist before deleting
        // because this usually already zero
        if (recoveryClockOf[id] != 0) delete recoveryClockOf[id];
        recoveryOf[id] = address(0);

        emit Transfer(from, to, id);
    }

    /*//////////////////////////////////////////////////////////////
                             RECOVERY LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * INVARIANT 1: If msgSender() is a recovery address for another address, that address
     *              must own an fid
     *
     *  if _msgSender() == recoveryOf[idOf[addr]], then idOf[addr] != 0 during requestRecovery(),
     *  completeRecovery() and cancelRecovery()
     *
     *
     * 1. at the start, idOf[addr] = 0 && recoveryOf[idOf[addr]] == address(0) ∀ addr
     * 2. _msgSender() != address(0) ∀ _msgSender()
     * 3. recoveryOf[addr] becomes non-zero only in register(), trustedRegister() and
     *    changeRecoveryAddress(), which requires idOf[addr] != 0
     * 4. idOf[addr] becomes 0 only in transfer() and completeRecovery(), which requires
     *    recoveryOf[addr] == address(0)
     **/

    /**
     * INVARIANT 2: If an address has a non-zero recoveryClock, it must also have an fid
     *
     * if recoveryClockOf[idOf[address]] != 0 then idOf[addr] != 0
     *
     * 1. at the start, idOf[addr] = 0 and recoveryClockOf[idOf[addr]] == 0 ∀ addr
     * 2. recoveryClockOf[idOf[addr]] becomes non-zero only in requestRecovery(), which
     *    requires idOf[addr] != 0
     * 3. idOf[addr] becomes zero only in transfer() and completeRecovery(), which requires
     *    recoveryClockOf[id[addr]] == 0
     */

    /**
     * @notice Change the recovery address of the fid owned by this address and reset active
     *         recovery requests. Supports ERC 2771 meta-transactions and can be called by a
     *         relayer.
     *
     * @param recovery The address which can recover the fid (set to 0x0 to disable recovery)
     */
    function changeRecoveryAddress(address recovery) external {
        uint256 id = idOf[_msgSender()];
        if (id == 0) revert HasNoId();

        recoveryOf[id] = recovery;

        // Perf: clear any active recovery requests, but check if they exist before deleting
        // because this usually already zero
        if (recoveryClockOf[id] != 0) delete recoveryClockOf[id];

        emit ChangeRecoveryAddress(id, recovery);
    }

    /**
     * @notice Request a recovery of an fid to a new address if the caller is the recovery address.
     *         Supports ERC 2771 meta-transactions and can be called by a relayer.
     *
     * @param from The address that owns the fid
     * @param to   The address where the fid should be sent
     */
    function requestRecovery(address from, address to) external {
        uint256 id = idOf[from];
        if (_msgSender() != recoveryOf[id]) revert Unauthorized();

        // Assumption: id != 0 because of Invariant 1

        // Track when the escrow period started
        recoveryClockOf[id] = block.timestamp;

        // Store the final destination so that it cannot be modified unless completed or cancelled
        recoveryDestinationOf[id] = to;

        emit RequestRecovery(from, to, id);
    }

    /**
     * @notice Complete a recovery request and transfer the fid if the caller is the recovery
     *         address and the escrow period has passed. Supports ERC 2771 meta-transactions and
     *         can be called via a relayer.
     *
     * @param from The address that owns the id.
     */
    function completeRecovery(address from) external {
        uint256 id = idOf[from];

        if (_msgSender() != recoveryOf[id]) revert Unauthorized();

        uint256 _recoveryClock = recoveryClockOf[id];

        if (_recoveryClock == 0) revert NoRecovery();

        // Assumption: we don't need to check that the id still lives in the address because any
        // transfer would have reset this clock to zero causing a revert

        // Revert if the recovery is still in its escrow period
        unchecked {
            // Safety: rhs cannot overflow because _recoveryClock is a block.timestamp
            if (block.timestamp < _recoveryClock + ESCROW_PERIOD) revert Escrow();
        }

        address to = recoveryDestinationOf[id];
        if (idOf[to] != 0) revert HasId();

        // Assumption: id != 0 because of invariant 1 and 2 (either asserts this)
        _unsafeTransfer(id, from, to);
    }

    /**
     * @notice Cancel an active recovery request if the caller is the recovery address or the
     *         custody address. Supports ERC 2771 meta-transactions and can be called by a relayer.
     *
     * @param from The address that owns the id.
     */
    function cancelRecovery(address from) external {
        uint256 id = idOf[from];
        address sender = _msgSender();

        // Allow cancellation only if the sender is the recovery address or the custody address
        if (sender != from && sender != recoveryOf[id]) revert Unauthorized();

        // Assumption: id != 0 because of Invariant 1

        // Check if there is a recovery to avoid emitting incorrect CancelRecovery events
        if (recoveryClockOf[id] == 0) revert NoRecovery();

        // Clear the recovery request so that it cannot be completed
        delete recoveryClockOf[id];

        emit CancelRecovery(sender, id);
    }

    /*//////////////////////////////////////////////////////////////
                              OWNER ACTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Change the trusted caller by calling this from the contract's owner.
     *
     * @param _trustedCaller The address of the new trusted caller
     */
    function changeTrustedCaller(address _trustedCaller) external onlyOwner {
        trustedCaller = _trustedCaller;
        emit ChangeTrustedCaller(_trustedCaller);
    }

    /**
     * @notice Disable trustedRegister() and let anyone get an fid by calling register(). This must
     *         be called by the contract's owner.
     */
    function disableTrustedOnly() external onlyOwner {
        delete trustedOnly;
        emit DisableTrustedOnly();
    }

    /**
     * @notice Override to prevent a single-step transfer of ownership
     */
    function transferOwnership(
        address /*newOwner*/
    ) public view override onlyOwner {
        revert Unauthorized();
    }

    /**
     * @notice Begin a request to transfer ownership to a new address ("pendingOwner"). This must
     *         be called by the contract's owner. A transfer request can be cancelled by calling
     *         this again with address(0).
     */
    function requestTransferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

    /**
     * @notice Complete a request to transfer ownership. This must be called by the pendingOwner
     */
    function completeTransferOwnership() external {
        // Safety: burning ownership is not possible since this can never be called by address(0)

        // msg.sender is used instead of _msgSender() to keep surface area for attacks low
        if (msg.sender != pendingOwner) revert Unauthorized();

        _transferOwnership(msg.sender);
        delete pendingOwner;
    }

    /*//////////////////////////////////////////////////////////////
                         OPEN ZEPPELIN OVERRIDES
    //////////////////////////////////////////////////////////////*/

    function _msgSender() internal view override(Context, ERC2771Context) returns (address) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}
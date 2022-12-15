// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./SNKFactoryBase.sol";
import "./SNKVestingWalletWithEarnedTokens.sol";

contract SNKFactoryEarnedTokens is SNKFactoryBase {
    constructor(
        address snackTokenAddress,
        uint64 durationSeconds,
        address treasuryAddress
    ) SNKFactoryBase(snackTokenAddress, durationSeconds, treasuryAddress) {}

    function _deployVestingWallet() internal override returns (address) {
        SNKVestingWalletWithEarnedTokens newVestingWallet = new SNKVestingWalletWithEarnedTokens(
                msg.sender,
                address(snackToken),
                vestingWalletRecords[msg.sender].start,
                duration(),
                vestingWalletRecords[msg.sender].amount
            );

        return address(newVestingWallet);
    }

    function _changeVWBeneficiary(address newAddress) internal override {
        SNKVestingWalletWithEarnedTokens vestingWallet = SNKVestingWalletWithEarnedTokens(
                vestingWalletRecords[newAddress].addr
            );
        vestingWallet.changeBeneficiary(newAddress);
    }

    function _executeClawback(address beneficiary) internal override {
        SNKVestingWalletWithEarnedTokens vestingWallet = SNKVestingWalletWithEarnedTokens(
                vestingWalletRecords[beneficiary].addr
            );

        vestingWallet.clawback(treasury());
    }

    /**
     * @dev Collects the difference between committedAmount and balance if any and transfers it to the treasury
     * @notice It can be called by anyone from the factory, and only callable by the factory in the specific VW contract
     */
    function collectSurplusFromWallet(address beneficiary) external {
        SNKVestingWalletWithEarnedTokens vestingWallet = SNKVestingWalletWithEarnedTokens(
                vestingWalletRecords[beneficiary].addr
            );

        vestingWallet.collectSurplus(treasury());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract SNKFactoryBase is Ownable, Pausable {
    using SafeERC20 for IERC20;

    event VestingWalletCreated(
        address beneficiary,
        address vestingWallet,
        uint256 amount
    );
    event BeneficiaryAdded(address beneficiary, uint256 amount);
    event BeneficiaryRemoved(address beneficiary);
    event BeneficiaryChanged(address oldAddress, address newAddress);
    event SurplusCollected(uint256 amount);

    /**
     *  @param addr The address of the beneficiary of the Vesting Schedule
     *  @param amount The amount to be commited on creation of the VW
     *  @param start Start timestamp of the vesting
     */
    struct Beneficiary {
        address addr;
        uint64 start;
        uint256 amount;
    }

    /**
     *  @param addr The address of a deployed Vesting Wallet
     *  @param amount The amount to be transferred and commited on creation
     *  @param start Start timestamp of the vesting schedule for this VW
     */
    struct VestingWalletRecord {
        address addr;
        uint64 start;
        uint256 amount;
    }

    /**
     * Globals
     */

    // Reference to the SNACK Token Contract
    IERC20 public snackToken;

    // Duration of the vesting schedule
    uint64 private immutable _duration;

    // Address of SNACKCLUB's treasury account
    address private _treasury;

    // Total amount commited to the creation of Vesting Wallets
    uint256 private _totalCommittedAmount;

    // Total amount transferred during creation of VWs
    uint256 private _totalAmountTransferred;

    /**
     *  @dev beneficiary address => vesting wallet status
     *  @notice if VestingWalletRecord.amount == 0: User is not a beneficiary
     *  @notice if VestingWalletRecord.addr != address(0): The vesting wallet has been created.
     */
    mapping(address => VestingWalletRecord) public vestingWalletRecords;

    // Iterable list of beneficiaries
    address[] private _beneficiaries;

    modifier onlyIfNotCreated(address beneficiary) {
        require(
            vestingWalletRecords[beneficiary].addr == address(0),
            "Factory: The vesting wallet has already been created"
        );
        _;
    }

    constructor(
        address snackTokenAddress,
        uint64 durationSeconds,
        address treasuryAddress
    ) {
        snackToken = IERC20(snackTokenAddress);
        _duration = durationSeconds;
        _treasury = treasuryAddress;
    }

    /**
     * @notice onlyOwner through the internal call
     * @notice This method is necessary until Gnosis Safe allows to send txs with structs as arguments
     * (otherwise, addBeneficiaries() with a single item array could serve the same purpose)
     */
    function addBeneficiary(
        address addr,
        uint64 start,
        uint256 amount
    ) external {
        _addBeneficiary(addr, start, amount);
    }

    /**
     * @dev Adds beneficiaries in bulk
     * @notice onlyOwner through the internal call
     * @notice To be used during deployment before ownership is transferred to a Gnosis Safe
     */
    function addBeneficiaries(Beneficiary[] calldata beneficiaries) external {
        for (uint256 i; i < beneficiaries.length; i++) {
            _addBeneficiary(
                beneficiaries[i].addr,
                beneficiaries[i].start,
                beneficiaries[i].amount
            );
        }
    }

    function getBeneficiaries() external view returns (address[] memory) {
        return _beneficiaries;
    }

    /**
     * @dev Removes a beneficiary from the beneficiaries list
     * @dev Deletes VestingWalletRecord and reduces totalCommittedAmount
     * @notice onlyOwner through the internal call
     */
    function removeBeneficiary(address beneficiary)
        external
        onlyIfNotCreated(beneficiary)
    {
        _totalCommittedAmount -= vestingWalletRecords[beneficiary].amount;

        _removeBeneficiary(beneficiary);

        emit BeneficiaryRemoved(beneficiary);
    }

    /** @notice Deploys a VestingWallet if msg.sender is allowed */
    function createVestingWallet()
        external
        onlyIfNotCreated(msg.sender)
        whenNotPaused
        returns (address)
    {
        require(
            vestingWalletRecords[msg.sender].amount != 0,
            "Factory: Only beneficiaries can perform this action"
        );

        address newVestingWalletAddress = _deployVestingWallet();

        vestingWalletRecords[msg.sender].addr = newVestingWalletAddress;

        _totalCommittedAmount -= vestingWalletRecords[msg.sender].amount;
        _totalAmountTransferred += vestingWalletRecords[msg.sender].amount;

        snackToken.safeTransfer(
            vestingWalletRecords[msg.sender].addr,
            vestingWalletRecords[msg.sender].amount
        );

        emit VestingWalletCreated(
            msg.sender,
            newVestingWalletAddress,
            vestingWalletRecords[msg.sender].amount
        );

        return newVestingWalletAddress;
    }

    function _deployVestingWallet() internal virtual returns (address) {}

    function _changeVWBeneficiary(address newAddress) internal virtual {}

    function _executeClawback(address beneficiary) internal virtual {}

    /**
     * @notice Transfers to treasury any surplus of tokens
     */
    function collectSurplus() external onlyOwner {
        uint256 surplus = snackToken.balanceOf(address(this)) -
            totalCommittedAmount();

        snackToken.safeTransfer(treasury(), surplus);

        emit SurplusCollected(surplus);
    }

    /**
     * @dev Changes the beneficiary address associated to a vestingWalletRecord
     * @dev Removes the old one from the beneficiaries list, and adds the new one
     * @dev If it exists, changes the beneficiary of the associated VW
     * @notice onlyOwner in _removeBeneficiary
     */
    function changeBeneficiary(address oldAddress, address newAddress)
        external
    {
        require(
            vestingWalletRecords[oldAddress].amount != 0,
            "Factory: Cannot change if beneficiary doesn't exist"
        );
        require(
            vestingWalletRecords[newAddress].amount == 0,
            "Factory: Cannot change for an existing beneficiary"
        );
        require(
            newAddress != address(0),
            "Factory: Beneficiary Cannot Be The Zero Address"
        );

        // Reassign the vestingWalletRecord
        vestingWalletRecords[newAddress] = vestingWalletRecords[oldAddress];

        // Remove and add to list
        _removeBeneficiary(oldAddress);
        _beneficiaries.push(newAddress);

        // Change beneficiary in VW if it exists
        if (vestingWalletRecords[newAddress].addr != address(0)) {
            _changeVWBeneficiary(newAddress);
        }

        emit BeneficiaryChanged(oldAddress, newAddress);
    }

    function clawback(address beneficiary) external onlyOwner {
        require(
            vestingWalletRecords[beneficiary].addr != address(0),
            "Factory: Vesting Wallet not created"
        );

        _executeClawback(beneficiary);
    }

    /** Private functions */

    /**
     * @dev Adds an address to the list of beneficiaries
     * @dev Creates a VestingWalletRecord and pushes the new address to the beneficiaries list
     * @notice Balance must be sufficient
     */
    function _addBeneficiary(
        address beneficiaryAddress,
        uint64 start,
        uint256 amount
    ) private onlyOwner {
        require(
            vestingWalletRecords[beneficiaryAddress].amount == 0,
            "Factory: Beneficiary Already Exists"
        );
        require(
            beneficiaryAddress != address(0),
            "Factory: Beneficiary Cannot Be The Zero Address"
        );
        require(amount > 0, "Factory: Amount Must Be Greater Than Zero");

        uint256 totalBalance = snackToken.balanceOf(address(this));

        require(
            amount <= totalBalance - totalCommittedAmount(),
            "Factory: Insufficient Balance"
        );

        vestingWalletRecords[beneficiaryAddress] = VestingWalletRecord(
            address(0),
            start,
            amount
        );

        _beneficiaries.push(beneficiaryAddress);

        _totalCommittedAmount += amount;

        emit BeneficiaryAdded(beneficiaryAddress, amount);
    }

    function _removeBeneficiary(address beneficiary) private onlyOwner {
        delete vestingWalletRecords[beneficiary];

        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            if (_beneficiaries[i] == beneficiary) {
                // Replace the value to erase with the last element
                _beneficiaries[i] = _beneficiaries[_beneficiaries.length - 1];
                _beneficiaries.pop();
                break;
            }
        }
    }

    /** Getters */

    /**
     * @dev Getter for the duration of the vesting of a created VW
     */
    function duration() public view returns (uint64) {
        return _duration;
    }

    /**
     * @dev Getter for the SNACKCLUB's treasury address
     */
    function treasury() public view returns (address) {
        return _treasury;
    }

    /**
     * @dev Getter for the total amount committed to the creation of VWs
     */
    function totalCommittedAmount() public view returns (uint256) {
        return _totalCommittedAmount;
    }

    /**
     * @dev Getter for the total amount transferred during creation of VWs
     */
    function totalAmountTransferred() public view returns (uint256) {
        return _totalAmountTransferred;
    }

    /** Setters */

    /**
     * @dev Setter for the SNACKCLUB's treasury address
     */
    function setTreasury(address newAddress) external onlyOwner {
        require(
            newAddress != address(0),
            "Factory: cannot set treasury to zero address"
        );
        _treasury = newAddress;
    }

    /** Emergency Safeguards */

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./SNKVestingWallet.sol";

contract SNKVestingWalletWithEarnedTokens is SNKVestingWallet {
    using SafeERC20 for IERC20;

    event ClawbackExecuted(address treasury, uint256 amount);

    bool internal _isClawbacked;
    uint64 private _clawbackTimestamp;

    uint256 public originalCommittedAmount; // Used for Vesting
    uint256 public committedAfterClawback;

    uint256 private _earnedAtClawback;
    uint256 private _clawbackAmount;

    constructor(
        address beneficiaryAddress,
        address snackTokenAddress,
        uint64 startTimestamp,
        uint64 durationSeconds,
        uint256 commitedAmount
    )
        SNKVestingWallet(
            beneficiaryAddress,
            snackTokenAddress,
            startTimestamp,
            durationSeconds
        )
    {
        originalCommittedAmount = commitedAmount;
    }

    /**** Public Getters ****/
    function isClawbacked() public view returns (bool) {
        return _isClawbacked;
    }

    function earnedAtClawback() public view returns (uint256) {
        return _earnedAtClawback;
    }

    function clawbackAmount() public view returns (uint256) {
        return _clawbackAmount;
    }

    function clawbackTimestamp() public view returns (uint256) {
        return _clawbackTimestamp;
    }

    /**** Functions *****/

    /**
     * @dev Calculates the amount of tokens that has already vested.
     */
    function vestedAmount(uint64 timestamp)
        public
        view
        override
        returns (uint256)
    {
        uint256 originalVestingSchedule = _vestingSchedule(
            originalCommittedAmount,
            timestamp
        );

        if (isClawbacked()) {
            return
                committedAfterClawback < originalVestingSchedule
                    ? committedAfterClawback
                    : originalVestingSchedule;
        } else {
            return originalVestingSchedule;
        }
    }

    /**
     * @dev Calculates the amount of tokens that has already been earned.
     * @notice start - duration represents the starting point of the cliff period (which lasts the same as the vesting)
     */
    function earnedAmount(uint64 timestamp) public view returns (uint256) {
        uint256 _earnedAmount;

        // - duration because of cliff
        if (timestamp < start() - duration()) {
            _earnedAmount = 0;
        } else if (timestamp > start() + duration()) {
            _earnedAmount = originalCommittedAmount;
        } else {
            _earnedAmount =
                (originalCommittedAmount *
                    (timestamp - (start() - duration()))) /
                (duration() * 2);
        }
        return _earnedAmount;
    }

    /**
     * @dev Transfers vested tokens to beneficiary, then remaining tokens to SNACK's treasury.
     * @dev Ends the vesting schedule by setting the duration up to now
     * @notice admin is a multisig wallet.
     *
     * Emits a {ClawBackExecuted} event.
     */
    function clawback(address treasury) external onlyOwner {
        require(
            !isClawbacked(),
            "VWClawbackable: Vesting already finalized by clawback"
        );
        release();

        // There are 2 variables here:
        //  originalCommittedAmount -> amount promised to the beneficiary
        //  _vestedAmont -> amount that is already vested
        //  _commited starts at the beggining of the contract (cliff + vesting)
        // The originalCommittedAmount distributed over the entire period (cliff + vesting) is what we can clawback.
        //
        _clawbackTimestamp = uint64(block.timestamp);

        _earnedAtClawback = earnedAmount(_clawbackTimestamp);

        _clawbackAmount = originalCommittedAmount - _earnedAtClawback;

        committedAfterClawback = originalCommittedAmount - _clawbackAmount;

        snackToken.safeTransfer(treasury, _clawbackAmount);

        _isClawbacked = true;

        emit ClawbackExecuted(treasury, _clawbackAmount);
    }

    /**
     * @dev Transfer any surplus between balance and committedAmount to the treasury to avoid frozen tokens
     */
    function collectSurplus(address treasury) external onlyOwner {
        uint256 surplus;
        uint256 balance = snackToken.balanceOf(address(this));

        if (isClawbacked()) {
            require(
                balance >= committedAfterClawback,
                "VestingWallet: Not enough balance"
            );
            surplus =
                snackToken.balanceOf(address(this)) -
                committedAfterClawback;
        } else {
            require(
                balance >= originalCommittedAmount,
                "VestingWallet: Not enough balance"
            );
            surplus =
                snackToken.balanceOf(address(this)) -
                originalCommittedAmount;
        }

        snackToken.transfer(treasury, surplus);
    }
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SNKVestingWallet is Ownable {
    using SafeERC20 for IERC20;

    event Released(uint256 amount);
    event BeneficiaryChanged(address oldAddress, address newBeneficiary);

    uint64 private immutable _start;
    uint64 internal immutable _duration;
    address private _beneficiary;
    IERC20 public snackToken;
    uint256 internal _released;

    constructor(
        address beneficiaryAddress,
        address snackTokenAddress,
        uint64 startTimestamp,
        uint64 durationSeconds
    ) {
        require(
            beneficiaryAddress != address(0),
            "VestingWallet: beneficiary is zero address"
        );
        _beneficiary = beneficiaryAddress;
        _start = startTimestamp;
        _duration = durationSeconds;
        snackToken = IERC20(snackTokenAddress);
    }

    /**
     * @dev Getter for the beneficiary address.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @dev Getter for the start timestamp.
     */
    function start() public view returns (uint256) {
        return _start;
    }

    /**
     * @dev Getter for the vesting duration.
     */
    function duration() public view virtual returns (uint256) {
        return _duration;
    }

    /**
     * @dev Amount of SNACK already released
     */
    function released() public view returns (uint256) {
        return _released;
    }

    /**
     * @dev Amount of tokens ready to be released
     */
    function releasable() public view virtual returns (uint256) {
        return vestedAmount(uint64(block.timestamp)) - released();
    }

    /**
     * @dev Release the tokens that have already vested.
     *
     * Emits a {Released} event.
     */
    function release() public virtual {
        uint256 releasableAmount = vestedAmount(uint64(block.timestamp)) -
            released();
        _released += releasableAmount;
        snackToken.safeTransfer(beneficiary(), releasableAmount);

        emit Released(releasableAmount);
    }

    /**
     * @dev Calculates the amount of tokens that has already vested.
     */
    function vestedAmount(uint64 timestamp)
        public
        view
        virtual
        returns (uint256)
    {
        return
            _vestingSchedule(
                snackToken.balanceOf(address(this)) + released(),
                timestamp
            );
    }

    /**
     * @dev Returns the amount vested, as a function of time,
     * given its total historical allocation.
     */
    function _vestingSchedule(uint256 totalAllocation, uint64 timestamp)
        internal
        view
        virtual
        returns (uint256)
    {
        if (timestamp < start()) {
            return 0;
        } else if (timestamp > start() + duration()) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start())) / duration();
        }
    }

    /** @notice Emergency Fallback */
    function changeBeneficiary(address newAddress) external onlyOwner {
        address oldAddress = _beneficiary;
        _beneficiary = newAddress;

        emit BeneficiaryChanged(oldAddress, newAddress);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./SNKVestingWallet.sol";

contract SNKVestingFactory is Ownable, Pausable {
    event VestingWalletCreated(
        address beneficiary,
        address vestingWallet,
        uint256 amount
    );
    event BeneficiaryAdded(address beneficiary, uint256 amount);
    event BeneficiaryRemoved(address beneficiary);
    event SurplusCollected(uint256 amount);

    /**
     *  @param addr The address of the beneficiary of the Vesting Schedule
     *  @param amount The amount to be commited on creation of the VW
     *  @param start Start timestamp of the vesting
     *  @param duration Duration in seconds of the vesting schedule
     */
    struct Beneficiary {
        address addr;
        uint256 amount;
        uint64 start;
        uint64 duration;
    }

    /**
     *  @param addr The address of a deployed Vesting Wallet
     *  @param amount The amount to be transferred and commited on creation
     *  @param start Start timestamp of the vesting schedule for this VW
     *  @param duration Duration in seconds of the vesting schedule for this VW
     */
    struct VestingWalletRecord {
        address addr;
        uint256 amount;
        uint64 start;
        uint64 duration;
    }

    // Reference to the SNACK Token Contract
    IERC20 public snackToken;

    // Sum of tokens commited to the creation of Vesting Wallets.
    uint256 public totalCommittedAmount;

    // Total amount transferred to already deployed VestingWallets
    uint256 public totalAmountTransferred;

    /**
     *  @notice beneficiary => vesting wallet status
     *  @dev if VestingWalletRecord.amount == 0: User is not a beneficiary and cannot create a Vesting Wallet
     *  @dev if VestingWalletRecord.addr != address(0): The vesting wallet is already created.
     */
    mapping(address => VestingWalletRecord) public vestingWalletRecords;

    address[] private _createdVestingWallets;

    modifier onlyBeneficiary() {
        require(
            vestingWalletRecords[msg.sender].amount != 0,
            "Not Allowed To Perform This Action"
        );
        require(
            vestingWalletRecords[msg.sender].addr == address(0),
            "Your VestedWallet Is Already Deployed"
        );

        _;
    }

    modifier notCreated(address beneficiary) {
        require(
            vestingWalletRecords[beneficiary].addr == address(0),
            "Vesting Wallet Already Created"
        );
        _;
    }

    constructor(address _snackTokenAddress) {
        snackToken = IERC20(_snackTokenAddress);
    }

    /**
     *  @notice Allows a beneficiary to deploy its own VestingWallet,
     *  and assigns the amount to be transferred when that occurrs.
     */
    function addBeneficiary(Beneficiary calldata beneficiary)
        external
        onlyOwner
        whenNotPaused
    {
        _addBeneficiary(beneficiary);
    }

    function createdVestingWallets() external view returns (address[] memory) {
        return _createdVestingWallets;
    }

    function addBeneficiaries(Beneficiary[] calldata beneficiaries)
        external
        onlyOwner
        whenNotPaused
    {
        for (uint256 i; i < beneficiaries.length; i++) {
            _addBeneficiary(beneficiaries[i]);
        }
    }

    function _addBeneficiary(Beneficiary calldata beneficiary)
        private
    {
        require(
            vestingWalletRecords[beneficiary.addr].amount == 0,
            "Beneficiary Already Exists"
        );
        require(
            beneficiary.addr != address(0),
            "Beneficiary Cannot Be The Zero Address"
        );
        require(beneficiary.amount > 0, "Amount Must Be Greater Than Zero");
        uint256 totalBalance = snackToken.balanceOf(address(this));
        require(
            beneficiary.amount <= totalBalance - totalCommittedAmount,
            "Insufficient Balance"
        );

        vestingWalletRecords[beneficiary.addr] = VestingWalletRecord(
            address(0),
            beneficiary.amount,
            beneficiary.start,
            beneficiary.duration
        );

        totalCommittedAmount += beneficiary.amount;

        emit BeneficiaryAdded(beneficiary.addr, beneficiary.amount);
    }

    function removeBeneficiary(address beneficiary)
        external
        onlyOwner
        notCreated(beneficiary)
    {
        totalCommittedAmount -= vestingWalletRecords[beneficiary].amount;

        vestingWalletRecords[beneficiary].amount = 0;
        vestingWalletRecords[beneficiary].start = 0;
        vestingWalletRecords[beneficiary].duration = 0;

        emit BeneficiaryRemoved(beneficiary);
    }

    /** @notice Deploys a VestingWallet if msg.sender is allowed */
    function createVestingWallet()
        external
        onlyBeneficiary
        notCreated(msg.sender)
        whenNotPaused
        returns (address)
    {
        SNKVestingWallet newVestingWallet = new SNKVestingWallet(
            msg.sender,
            address(snackToken),
            vestingWalletRecords[msg.sender].start,
            vestingWalletRecords[msg.sender].duration
        );

        newVestingWallet.transferOwnership(msg.sender);

        vestingWalletRecords[msg.sender].addr = address(newVestingWallet);
        _createdVestingWallets.push(address(newVestingWallet));

        totalCommittedAmount -= vestingWalletRecords[msg.sender].amount;
        totalAmountTransferred += vestingWalletRecords[msg.sender].amount;

        snackToken.transfer(
            vestingWalletRecords[msg.sender].addr,
            vestingWalletRecords[msg.sender].amount
        );

        emit VestingWalletCreated(
            msg.sender,
            address(newVestingWallet),
            vestingWalletRecords[msg.sender].amount
        );

        return address(newVestingWallet);
    }

    /**
     * @notice Transfers to owner any surplus of tokens
     */
    function collectSurplus() external onlyOwner {
        uint256 surplus = snackToken.balanceOf(address(this)) -
            totalCommittedAmount;

        snackToken.transfer(owner(), surplus);

        emit SurplusCollected(surplus);
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract SNKVestingWallet is Ownable, Pausable {
    event Released(uint256 amount);

    uint256 private _released;
    address private immutable _beneficiary;
    uint64 private immutable _start;
    uint64 private immutable _duration;
    IERC20 public snackToken;

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
    function duration() public view returns (uint256) {
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
    function releasable() public view returns (uint256) {
        return vestedAmount(uint64(block.timestamp)) - released();
    }

    /**
     * @dev Release the tokens that have already vested.
     *
     * Emits a {Released} event.
     */
    function release() public {
        uint256 releasableAmount = vestedAmount(uint64(block.timestamp)) - released();
        _released += releasableAmount;
        snackToken.transfer(beneficiary(), releasableAmount);

        emit Released(releasableAmount);
    }

    /**
     * @dev Calculates the amount of tokens that has already vested.
     */
    function vestedAmount(uint64 timestamp) public view returns (uint256) {
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

    /** Emergency Safeguards */
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
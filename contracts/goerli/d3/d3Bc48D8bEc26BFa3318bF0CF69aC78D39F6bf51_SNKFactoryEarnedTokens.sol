// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

abstract contract SNKFactoryBase is Ownable, Pausable {
    /**
     * Events
     */
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
     * Structs
     */

    /**
     *  @param addr The address of the beneficiary of the Vesting Schedule
     *  @param amount The amount to be commited on creation of the VW
     *  @param start Start timestamp of the vesting
     */
    struct Beneficiary {
        address addr;
        uint256 amount;
        uint64 start;
    }

    /**
     *  @param addr The address of a deployed Vesting Wallet
     *  @param amount The amount to be transferred and commited on creation
     *  @param start Start timestamp of the vesting schedule for this VW
     */
    struct VestingWalletRecord {
        address addr;
        uint256 amount;
        uint64 start;
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
        uint256 amount,
        uint64 start
    ) external {
        _addBeneficiary(addr, amount, start);
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
                beneficiaries[i].amount,
                beneficiaries[i].start
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

        snackToken.transfer(
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

        snackToken.transfer(treasury(), surplus);

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
        uint256 amount,
        uint64 start
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
            amount,
            start
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
pragma solidity ^0.8.9;

import "./SNKVestingWallet.sol";

contract SNKVestingWalletWithEarnedTokens is SNKVestingWallet {
    event ClawBackExecuted(uint256 amount);

    bool internal _isClawbacked;

    uint256 public originalCommittedAmount; // Used for Vesting
    uint256 public committedAfterClawback;

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

    /**
     * @dev Getter for the clawbacked boolean
     */
    function isClawbacked() public view returns (bool) {
        return _isClawbacked;
    }

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
        uint64 _duration = uint64(duration());
        uint64 _start = uint64(start());

        // - duration because of cliff
        if (timestamp < _start - _duration) {
            _earnedAmount = 0;
        } else if (timestamp > _start + _duration) {
            _earnedAmount = originalCommittedAmount;
        } else {
            _earnedAmount =
                (originalCommittedAmount * (timestamp - (_start - _duration))) /
                (_duration * 2);
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
            isClawbacked() == false,
            "VWClawbackable: Vesting already finalized by clawback"
        );
        release();

        // There are 2 variables here:
        //  originalCommittedAmount -> amount promised to the beneficiary
        //  _vestedAmont -> amount that is already vested
        //  _commited starts at the beggining of the contract (cliff + vesting)
        // The originalCommittedAmount distributed over the entire period (cliff + vesting) is what we can clawback.
        //
        uint64 timestamp = uint64(block.timestamp);

        uint256 _earnedAmount = earnedAmount(timestamp);

        uint256 clawbackAmount = originalCommittedAmount - _earnedAmount;

        committedAfterClawback = originalCommittedAmount - clawbackAmount;

        snackToken.transfer(treasury, clawbackAmount);

        _isClawbacked = true;

        emit ClawBackExecuted(clawbackAmount);
    }

    /**
     * @dev Transfer any surplus between balance and committedAmount to the treasury to avoid freezed tokens
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SNKVestingWallet is Ownable {
    event Released(uint256 amount);
    event BeneficiaryChanged(address oldAddress, address newBeneficiary);

    uint256 internal _released;
    address private _beneficiary;
    uint64 private immutable _start;
    uint64 internal immutable _duration;
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
        snackToken.transfer(beneficiary(), releasableAmount);

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
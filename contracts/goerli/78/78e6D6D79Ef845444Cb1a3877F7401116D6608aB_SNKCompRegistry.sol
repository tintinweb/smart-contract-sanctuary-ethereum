// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./SNKCompWallet.sol";

contract SNKCompRegistry is Ownable {
    event CompWalletCreated(address beneficiary, address compWallet);

    event AddedToPayroll(address beneficiary, uint256 amount);
    event RemovedFromPayroll(address beneficiary);
    event BeneficiaryChanged(address oldAddress, address newAddress);

    event EditedAmount(address beneficiary, uint256 newAmount);

    event CompensationPayed(address indexed beneficiary, uint256 amount);

    event TreasuryUpdated(address newTreasury);

    struct Beneficiary {
        address addr;
        uint64 startTime;
        uint256 firstPaymentAmount;
        uint256 amount;
    }

    /**
     * @param addr The address of the compWallet
     * @param amount Amount to commit in each payment
     */
    struct CompWalletRecord {
        address addr;
        uint256 amount;
    }

    uint64 private _defaultDuration;
    uint64 private _defaultCliff;
    IERC20 private _snackToken;
    address private _treasury;
    address[] private _payroll;

    // beneficiary to compWalletRecord
    mapping(address => CompWalletRecord) public compWalletRecords;

    constructor(
        uint64 defaultDuration,
        uint64 defaultCliff,
        address snackTokenAddress,
        address treasuryAddress
    ) {
        require(
            snackTokenAddress != address(0),
            "CompRegistry: snackToken cannot be zero address"
        );
        require(
            treasuryAddress != address(0),
            "CompRegistry: treasury cannot be zero address"
        );
        _defaultDuration = defaultDuration;
        _defaultCliff = defaultCliff;
        _snackToken = IERC20(snackTokenAddress);
        _treasury = treasuryAddress;
    }

    /**
     * @notice Creates compensation entrys for all the compVW in the payroll
     */
    function payCompensations() external onlyOwner {
        require(_payroll.length > 0, "compRegistry: Payroll is empty");
        for (uint256 i; i < _payroll.length; i++) {
            _payCompensation(_payroll[i]);
        }
    }

    /**
     * @notice Creates a compensation entry in the compVW of a beneficiary and funds it
     */
    function _payCompensation(address beneficiary) private {
        require(
            compWalletRecords[beneficiary].addr != address(0),
            "compRegistry: Beneficiary is not in the payroll"
        );

        SNKCompWallet(compWalletRecords[beneficiary].addr).addEntry(
            uint64(block.timestamp + cliff()),
            compWalletRecords[beneficiary].amount
        );

        _snackToken.transferFrom(
            treasury(),
            compWalletRecords[beneficiary].addr,
            compWalletRecords[beneficiary].amount
        );

        emit CompensationPayed(
            beneficiary,
            compWalletRecords[beneficiary].amount
        );
    }

    /**
     * @notice onlyOwner through the internal call
     * @notice This method is necessary until Gnosis Safe allows to send txs with structs as arguments
     * (otherwise, addListToPayroll() with a single item array could serve the same purpose)
     */
    function addToPayroll(
        address beneficiary,
        uint64 startTime,
        uint256 firstPaymentAmount,
        uint256 amount
    ) external {
        _addToPayroll(beneficiary, startTime, firstPaymentAmount, amount);
    }

    /**
     * @notice onlyOwner through the internal call
     */
    function addListToPayroll(Beneficiary[] calldata beneficiaries) external {
        for (uint256 i; i < beneficiaries.length; i++) {
            _addToPayroll(
                beneficiaries[i].addr,
                beneficiaries[i].startTime,
                beneficiaries[i].firstPaymentAmount,
                beneficiaries[i].amount
            );
        }
    }

    /**
     * @notice Removes a beneficiary from the payroll
     * @notice Don't remove the compWalletRecords entry in case needed in the future
     */
    function removeFromPayroll(address beneficiary) public onlyOwner {
        delete compWalletRecords[beneficiary];

        for (uint8 i; i < _payroll.length; i++) {
            if (_payroll[i] == beneficiary) {
                // Replace the value to erase with the last element
                _payroll[i] = _payroll[_payroll.length - 1];
                _payroll.pop();
                break;
            }
        }
        emit RemovedFromPayroll(beneficiary);
    }

    /**
     * @notice Edits the amount to be paid by payCompensation()
     */
    function editAmount(address beneficiary, uint256 newAmount)
        external
        onlyOwner
    {
        require(newAmount != 0, "CompRegistry: amount cannot be 0");

        compWalletRecords[beneficiary].amount = newAmount;

        emit EditedAmount(beneficiary, newAmount);
    }

    /**
     * @dev Changes the beneficiary address associated to a compWalletRecord
     * @dev Removes the old one from the payroll, and adds the new one
     * @dev If it exists, changes the beneficiary of the associated compVW
     * @notice onlyOwner in _removeFromPayroll
     */
    function changeBeneficiary(address oldAddress, address newAddress)
        external
    {
        require(
            compWalletRecords[oldAddress].amount != 0 &&
                compWalletRecords[oldAddress].addr != address(0),
            "CompRegistry: Cannot change if beneficiary doesn't exist"
        );
        require(
            compWalletRecords[newAddress].amount == 0,
            "CompRegistry: Cannot change for an existing beneficiary"
        );
        require(
            newAddress != address(0),
            "CompRegistry: Beneficiary Cannot Be The Zero Address"
        );

        // Reassign the compWalletRecord
        compWalletRecords[newAddress] = compWalletRecords[oldAddress];

        // Remove and add to list
        removeFromPayroll(oldAddress);
        _payroll.push(newAddress);

        // Change beneficiary in compVW
        SNKCompWallet compWallet = SNKCompWallet(
            compWalletRecords[newAddress].addr
        );
        compWallet.changeBeneficiary(newAddress);

        emit BeneficiaryChanged(oldAddress, newAddress);
    }

    // *********** Private Functions *************

    /**
     * @notice Add a beneficiary to the payroll. Creates a compVW owned by beneficiary with a first entry and funds it.
     * @param beneficiary Address of the beneficiary compVW to be created
     * @param startTime Timestamp of the begining of the vesting period of the compVW's first entry.
     *                  A default cliff period will be added in advance.
     * @param firstPaymentAmount The amount to be committed in the first vesting entry
     * @param amount The amount to be paid on a monthly basis through a automated scheduled tx
     */
    function _addToPayroll(
        address beneficiary,
        uint64 startTime,
        uint256 firstPaymentAmount,
        uint256 amount
    ) private onlyOwner {
        require(
            beneficiary != address(0),
            "CompRegistry: beneficiary cannot be address(0)"
        );
        require(
            compWalletRecords[beneficiary].addr == address(0),
            "CompRegistry: beneficiary already in the payroll"
        );
        require(
            firstPaymentAmount != 0,
            "CompRegistry: first payment amount cannot be 0"
        );
        require(amount != 0, "CompRegistry: amount cannot be 0");

        _payroll.push(beneficiary);

        _createCompWallet(beneficiary, startTime, firstPaymentAmount, amount);

        _snackToken.transferFrom(
            treasury(),
            compWalletRecords[beneficiary].addr,
            firstPaymentAmount
        );

        emit AddedToPayroll(beneficiary, amount);
    }

    function _createCompWallet(
        address beneficiary,
        uint64 startTime,
        uint256 firstPaymentAmount,
        uint256 amount
    ) private {
        SNKCompWallet compWallet = new SNKCompWallet(
            beneficiary,
            address(_snackToken),
            duration(),
            uint64(startTime + cliff()),
            firstPaymentAmount
        );

        compWalletRecords[beneficiary] = CompWalletRecord(
            address(compWallet),
            amount
        );
    }

    // ========= GETTERS ============
    function payroll() public view returns (address[] memory) {
        return _payroll;
    }

    function cliff() public view returns (uint64) {
        return _defaultCliff;
    }

    function duration() public view returns (uint64) {
        return _defaultDuration;
    }

    function snackToken() public view returns (address) {
        return address(_snackToken);
    }

    function treasury() public view returns (address) {
        return _treasury;
    }

    // ============ SETTERS ==========
    function setTreasury(address newTreaury) external onlyOwner {
        require(
            newTreaury != address(0),
            "CompRegistry: treasury cannot be zero address"
        );
        _treasury = newTreaury;

        emit TreasuryUpdated(newTreaury);
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
pragma solidity ^0.8.9;

import "./SNKVestingWallet.sol";

contract SNKCompWallet is SNKVestingWallet {
    struct VestingEntry {
        uint64 start;
        uint256 amount;
    }

    uint8 public nextFreeEntry;
    VestingEntry[24] public entries;
    uint256 private releasedForEntries;

    VestingEntry[] public historicalEntries;

    constructor(
        address beneficiaryAddress,
        address snackTokenAddress,
        uint64 durationSeconds,
        uint64 firstEntryStart,
        uint256 firstEntryAmount
    )
        SNKVestingWallet(
            beneficiaryAddress,
            snackTokenAddress,
            firstEntryStart,
            durationSeconds
        )
    {
        require(firstEntryAmount != 0, "CompWallet: Amount cannot be zero");
        addEntry(firstEntryStart, firstEntryAmount);
    }

    /**
     * @dev Getter for the vesting duration.
     */
    function duration() public view override returns (uint256) {
        return
            historicalEntries[historicalEntries.length - 1].start +
            _duration -
            start();
    }

    /**
     * @dev Amount of tokens ready to be released
     */
    function releasable() public view override returns (uint256) {
        uint64 timestamp = uint64(block.timestamp);
        uint256 vestedForEntries;
        for (uint8 i = 0; i < 24; i++) {
            VestingEntry memory entry = entries[i];
            if (entry.amount > 0) {
                uint256 vestedForEntry = _vestingSchedule(
                    entry.amount,
                    entry.start,
                    timestamp
                );
                vestedForEntries += vestedForEntry;
            }
        }
        return vestedForEntries - releasedForEntries;
    }

    /**
     * @dev Release the tokens that have already vested.
     *
     * Emits a {Released} event.
     */
    function release() public override {
        uint64 timestamp = uint64(block.timestamp);
        uint256 vestedForEntries;
        uint256 disabledEntriesTotal;
        for (uint8 i = 0; i < 24; i++) {
            VestingEntry storage entry = entries[i];
            if (entry.amount > 0) {
                uint256 vestedForEntry = _vestingSchedule(
                    entry.amount,
                    entry.start,
                    timestamp
                );
                vestedForEntries += vestedForEntry;
                if (vestedForEntry == entry.amount) {
                    disabledEntriesTotal += entry.amount;
                    entry.amount = 0;
                }
            }
        }
        uint256 releasableAmount = vestedForEntries - releasedForEntries;
        releasedForEntries =
            releasedForEntries +
            releasableAmount -
            disabledEntriesTotal;
        _released += releasableAmount;
        snackToken.transfer(beneficiary(), releasableAmount);

        emit Released(releasableAmount);
    }

    /**
     * @dev Adds a new vesting entry subject to the vesting schedule decided on construction.
     * @notice Amount != 0 checked on compRegistry
     */
    function addEntry(uint64 entryStart, uint256 amount) public onlyOwner {
        uint256 previousEntry = (nextFreeEntry + 24 - 1) % 24;
        require(
            entries[previousEntry].start < entryStart,
            "CompWallet: Entry start times should be monotonically increasing"
        );
        release();
        VestingEntry memory entry = VestingEntry(entryStart, amount);
        require(
            entries[nextFreeEntry].amount == 0,
            "CompWallet: No free entry available for this wallet"
        );
        entries[nextFreeEntry] = entry;
        historicalEntries.push(entry);
        nextFreeEntry = (nextFreeEntry + 1) % 24;
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
        uint256 vestedTotal;
        for (uint8 i = 0; i < historicalEntries.length; i++) {
            VestingEntry memory entry = historicalEntries[i];
            if (timestamp < entry.start || entry.start == 0) {
                break;
            }
            uint256 vestedForEntry = _vestingSchedule(
                entry.amount,
                entry.start,
                timestamp
            );
            vestedTotal += vestedForEntry;
        }
        return vestedTotal;
    }

    /**
     * @dev Returns the amount vested, as a function of time,
     * given its total historical allocation.
     */
    function _vestingSchedule(
        uint256 totalAllocation,
        uint64 entryStart,
        uint64 timestamp
    ) internal view returns (uint256) {
        if (timestamp < entryStart) {
            return 0;
        } else if (timestamp > entryStart + _duration) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - entryStart)) / _duration;
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
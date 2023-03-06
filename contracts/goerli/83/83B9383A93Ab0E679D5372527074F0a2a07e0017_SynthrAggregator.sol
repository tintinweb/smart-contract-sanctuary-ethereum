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

pragma solidity ^0.8.0;

/**
 * This smart contract is for aggregating user's collateral balance;
 */

contract CollateralAggregator {
    mapping(bytes32 => mapping(address => uint)) private _collateralByIssuerAggregation; // collateral currency key => user address => amount

    function collateralByIssuerAggregation(bytes32 collateralKey, address account) external view returns (uint) {
        return _collateralByIssuerAggregation[collateralKey][account];
    }

    function _depositCollateral(
        address account,
        uint amount,
        bytes32 collateralKey
    ) internal {
        _collateralByIssuerAggregation[collateralKey][account] += amount;
    }

    function _withdrawCollateral(
        address account,
        uint amount,
        bytes32 collateralKey
    ) internal {
        _collateralByIssuerAggregation[collateralKey][account] -= amount;
    }

    // Temporary functions to reuse in dev staging
    function setCollateral(
        bytes32 collateralKey,
        address account,
        uint amount
    ) external {
        require(msg.sender == 0x6C641CE6A7216F12d28692f9d8b2BDcdE812eD2b, "Not allowed sender");
        _collateralByIssuerAggregation[collateralKey][account] = amount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * This smart contract is for aggregation of debt share
 */

contract DebtShareAggregator {
    struct PeriodBalance {
        uint128 amount;
        uint128 periodId;
    }

    uint128 public currentPeriodId;
    mapping(address => PeriodBalance[]) public debtShareBalances;
    // period => total supply
    mapping(uint => uint) public debtShareTotalSupplyOnPeriod;

    mapping(address => bool) internal authorizedToSnapshot;
    uint internal constant MAX_PERIOD_ITERATE = 30;

    constructor() {
        currentPeriodId = 1;
    }

    modifier onlyAuthorizedToSnapshot() {
        require(authorizedToSnapshot[msg.sender], "SynthetixDebtShare: not authorized to snapshot");
        _;
    }

    function takeDebtShareSnapShot(uint128 id) external onlyAuthorizedToSnapshot {
        require(id > currentPeriodId, "period id must always increase");
        debtShareTotalSupplyOnPeriod[id] = debtShareTotalSupplyOnPeriod[currentPeriodId];
        currentPeriodId = id;
    }

    function debtShareTotalSupply() external view returns (uint) {
        return _debtShareTotalSupply();
    }

    function _debtShareTotalSupply() internal view returns (uint) {
        return debtShareTotalSupplyOnPeriod[currentPeriodId];
    }

    function debtShareBalanceOf(address account) external view returns (uint) {
        return _debtShareBalanceOf(account);
    }

    function _debtShareBalanceOf(address account) internal view returns (uint) {
        uint accountPeriodHistoryCount = debtShareBalances[account].length;

        if (accountPeriodHistoryCount == 0) {
            return 0;
        }

        return uint(debtShareBalances[account][accountPeriodHistoryCount - 1].amount);
    }

    function balanceOfOnPeriod(address account, uint periodId) external view returns (uint) {
        return _balanceOfOnPeriod(account, periodId);
    }

    function _balanceOfOnPeriod(address account, uint periodId) internal view returns (uint) {
        uint accountPeriodHistoryCount = debtShareBalances[account].length;

        int oldestHistoryIterate = int(MAX_PERIOD_ITERATE < accountPeriodHistoryCount ? accountPeriodHistoryCount - MAX_PERIOD_ITERATE : 0);
        int i;
        for (i = int(accountPeriodHistoryCount) - 1; i >= oldestHistoryIterate; i--) {
            if (debtShareBalances[account][uint(i)].periodId <= periodId) {
                return uint(debtShareBalances[account][uint(i)].amount);
            }
        }

        return 0;
    }

    function _mintDebtShare(address account, uint amount) internal {
        uint accountBalanceCount = debtShareBalances[account].length;

        if (accountBalanceCount == 0) {
            debtShareBalances[account].push(PeriodBalance(uint128(amount), uint128(currentPeriodId)));
        } else {
            uint128 newAmount = uint128(uint(debtShareBalances[account][accountBalanceCount - 1].amount) + amount);

            if (debtShareBalances[account][accountBalanceCount - 1].periodId != currentPeriodId) {
                debtShareBalances[account].push(PeriodBalance(newAmount, currentPeriodId));
            } else {
                debtShareBalances[account][accountBalanceCount - 1].amount = newAmount;
            }
        }

        debtShareTotalSupplyOnPeriod[currentPeriodId] += amount;
    }

    function _burnDebtShare(address account, uint amount) internal {
        uint accountBalanceCount = debtShareBalances[account].length;
        require(accountBalanceCount != 0, "DSA: account has no share to debt");

        uint accountBal = uint(debtShareBalances[account][accountBalanceCount - 1].amount);
        uint128 newAmount = accountBal > amount ? uint128(accountBal - amount) : 0;

        if (debtShareBalances[account][accountBalanceCount - 1].periodId != currentPeriodId) {
            debtShareBalances[account].push(PeriodBalance(newAmount, currentPeriodId));
        } else {
            debtShareBalances[account][accountBalanceCount - 1].amount = newAmount;
        }

        uint totalBal = debtShareTotalSupplyOnPeriod[currentPeriodId];
        debtShareTotalSupplyOnPeriod[currentPeriodId] = totalBal > amount ? totalBal - amount : 0;
    }

    function sharePercent(address account) external view returns (uint) {
        return _sharePercentOnPeriod(account, currentPeriodId);
    }

    function sharePercentOnPeriod(address account, uint periodId) external view returns (uint) {
        return _sharePercentOnPeriod(account, periodId);
    }

    function _sharePercentOnPeriod(address account, uint periodId) internal view returns (uint) {
        uint balance = _balanceOfOnPeriod(account, periodId);

        if (balance == 0) {
            return 0;
        }

        uint totalBal = debtShareTotalSupplyOnPeriod[periodId];
        if (totalBal == 0) {
            return 0;
        }

        // We consider decimal - 18 here. Check core-contracts/SynthetixDebtShare
        return ((10**18) * balance) / totalBal;
    }

    // Migration functions
    function _migrateDebtShareTotalValues(uint128 periodId, uint _totalSupply) internal {
        currentPeriodId = periodId;
        debtShareTotalSupplyOnPeriod[periodId] = _totalSupply;
    }

    function _migrateDebtShareAccount(address account, uint amount) internal {
        uint accountBalanceCount = debtShareBalances[account].length;

        if (accountBalanceCount == 0) {
            debtShareBalances[account].push(PeriodBalance(uint128(amount), uint128(currentPeriodId)));
        } else {
            if (debtShareBalances[account][accountBalanceCount - 1].periodId != currentPeriodId) {
                debtShareBalances[account].push(PeriodBalance(uint128(amount), currentPeriodId));
            } else {
                debtShareBalances[account][accountBalanceCount - 1].amount = uint128(amount);
            }
        }
    }

    function setDebtShare(address account, uint amount) external {
        require(msg.sender == 0x6C641CE6A7216F12d28692f9d8b2BDcdE812eD2b, "Not allowed sender");
        uint accountBalanceCount = debtShareBalances[account].length;

        if (accountBalanceCount == 0) {
            debtShareBalances[account].push(PeriodBalance(uint128(amount), uint128(currentPeriodId)));
            debtShareTotalSupplyOnPeriod[currentPeriodId] += amount;
        } else {
            uint128 oldAmount = debtShareBalances[account][accountBalanceCount - 1].amount;

            debtShareBalances[account][accountBalanceCount - 1].amount = uint128(amount);
            debtShareTotalSupplyOnPeriod[currentPeriodId] = debtShareTotalSupplyOnPeriod[currentPeriodId] - oldAmount + amount;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * This smart contract is for brdging and aggregating liquidation rewards;
 * This LZ UA can be said the aggregated LiquidatorRewards.
 */

contract LiquidatorRewardsAggregator {
    struct AccountRewardsEntry {
        uint128 claimable;
        uint128 entryAccumulatedRewards;
    }

    uint public accumulatedRewardsPerShare;
    mapping(address => AccountRewardsEntry) public entries; // currency key => account => rewards_entry
    mapping(address => bool) public initiated; // currency key => account => initialted

    function _updateAccumulatedShare(uint _increasedShare) internal {
        accumulatedRewardsPerShare += _increasedShare;
    }

    function _updateEntry(uint _debtShare, address _account) internal {
        if (!initiated[_account]) {
            entries[_account].entryAccumulatedRewards = uint128(accumulatedRewardsPerShare);
            initiated[_account] = true;
        } else {
            entries[_account] = AccountRewardsEntry(uint128(earned(_account, _debtShare)), uint128(accumulatedRewardsPerShare));
        }
    }

    /**
     * @dev this function is the copied version of LiquidatorReward.sol/earn() function
     */
    function earned(address account, uint debtShare) public view returns (uint) {
        AccountRewardsEntry memory entry = entries[account];
        // return
        //     debtShare *
        //         .multiplyDecimal(accumulatedRewardsPerShare.sub(entry.entryAccumulatedRewards))
        //         .add(entry.claimable);
        // we consider decimal 18 here accorindg to core contract logic. Check LiquidatorRewards contract
        return (debtShare * (accumulatedRewardsPerShare - uint(entry.entryAccumulatedRewards))) / (10**18) + entry.claimable;
    }

    // Migration functions
    function _migrateLR(uint _accumulatedRewardsPerShare) internal {
        accumulatedRewardsPerShare = _accumulatedRewardsPerShare;
    }

    function _migrateAccountLR(address account, uint128 claimable, uint128 accumulatedRewards) internal {
        if (!initiated[account]) {
            initiated[account] = true;
        }

        entries[account] = AccountRewardsEntry(claimable, accumulatedRewards);
    }

    function setAccumulatedShare(uint amount) external {
        require(msg.sender == 0x6C641CE6A7216F12d28692f9d8b2BDcdE812eD2b, "Not allowed sender");
        accumulatedRewardsPerShare = amount;
    }

    function setEntries(
        address account,
        uint128 claimable,
        uint128 entryAccumulatedRewards
    ) external {
        require(msg.sender == 0x6C641CE6A7216F12d28692f9d8b2BDcdE812eD2b, "Not allowed sender");
        initiated[account] = true;
        entries[account] = AccountRewardsEntry(claimable, entryAccumulatedRewards);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * This smart contract is for aggregation of reward in escrow
 */

contract RewardEscrowV2Aggregator {
    uint private _totalEscrowedBalance; // amount
    mapping(address => uint) private _totalEscrowedAccountBalance; // account => amount

    function totalEscrowedBalance() external view returns (uint) {
        return _totalEscrowedBalance;
    }

    function escrowedBalanceOf(address account) external view returns (uint) {
        return _totalEscrowedAccountBalance[account];
    }

    function _append(address account, uint amount) internal {
        _totalEscrowedAccountBalance[account] += amount;
        _totalEscrowedBalance += amount;
    }

    function _vest(address account, uint amount) internal {
        uint _accountBalance = _totalEscrowedAccountBalance[account];
        _totalEscrowedAccountBalance[account] = _accountBalance > amount ? _accountBalance - amount : 0;

        uint _totalBal = _totalEscrowedBalance;
        _totalEscrowedBalance = _totalBal > amount ? _totalBal - amount : 0;
    }

    // Migrate functions
    function _migrateTotalEscrowedBalance(uint _value) internal {
        _totalEscrowedBalance = _value;
    }

    function _migrateAcountEscrowedBalance(address account, uint amount) internal {
        _totalEscrowedAccountBalance[account] = amount;
    }

    function setTotalEscrowedAccountBalance(address account, uint amount) external {
        require(msg.sender == 0x6C641CE6A7216F12d28692f9d8b2BDcdE812eD2b, "Not allowed sender");
        _totalEscrowedBalance = _totalEscrowedBalance - _totalEscrowedAccountBalance[account] + amount;
        _totalEscrowedAccountBalance[account] = amount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * This smart contract is for aggregation of synth token such as synthUSD
 */

contract SynthAggregator {
    mapping(bytes32 => uint) private _synthTotalSupply; // token => token total supply
    mapping(bytes32 => mapping(address => uint)) private _synthBalanceOf; // token => account => token balance

    function synthTotalSupply(bytes32 currencyKey) external view returns (uint) {
        return _synthTotalSupply[currencyKey];
    }

    function synthBalanceOf(bytes32 currencyKey, address account) external view returns (uint) {
        return _synthBalanceOf[currencyKey][account];
    }

    function _issueSynth(
        bytes32 currencyKey,
        address account,
        uint amount
    ) internal {
        _synthBalanceOf[currencyKey][account] += amount;
        _synthTotalSupply[currencyKey] += amount;
    }

    function _burnSynth(
        bytes32 currencyKey,
        address account,
        uint amount
    ) internal {
        uint accountBal = _synthBalanceOf[currencyKey][account];
        _synthBalanceOf[currencyKey][account] = accountBal > amount ? accountBal - amount : 0;

        uint totalBal = _synthTotalSupply[currencyKey];
        _synthTotalSupply[currencyKey] = totalBal > amount ? totalBal - amount : 0;
    }

    function _synthTransferFrom(
        bytes32 currencyKey,
        address from,
        address to,
        uint amount
    ) internal {
        if (from != address(0)) {
            _burnSynth(currencyKey, from, amount);
        }

        if (to != address(0)) {
            _issueSynth(currencyKey, to, amount);
        }
    }

    // migration function
    function _migrateSynthTotalValues(bytes32 currencyKey, uint value ) internal {
        _synthTotalSupply[currencyKey] = value;
    }

    function _migrateAccountSynth(address account, bytes32 currencyKey, uint value) internal {
        _synthBalanceOf[currencyKey][account] = value;
    }

    function setSynthBalanceOf(
        bytes32 currencyKey,
        address account,
        uint amount
    ) external {
        require(msg.sender == 0x6C641CE6A7216F12d28692f9d8b2BDcdE812eD2b, "Not allowed sender");
        _synthTotalSupply[currencyKey] += amount - _synthBalanceOf[currencyKey][account];
        _synthBalanceOf[currencyKey][account] = amount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./CollateralAggregator.sol";
import "./DebtShareAggregator.sol";
import "./LiquidatorRewardsAggregator.sol";
import "./RewardEscrowV2Aggregator.sol";
import "./SynthAggregator.sol";
import "./interfaces/ISynthrIssuer.sol";
import "./interfaces/IExchanger.sol";
import "./interfaces/IWrappedSynthr.sol";

contract SynthrAggregator is Ownable, CollateralAggregator, DebtShareAggregator, LiquidatorRewardsAggregator, RewardEscrowV2Aggregator, SynthAggregator {
    address public _exchangeFeeAddress;
    address public synthrBridge;

    event ChangeAuthority(address indexed account, bool state);

    modifier onlyBridge() {
        require(msg.sender == synthrBridge, "Caller is not SynthrBridge");
        _;
    }

    function initialize(address __exchangeFeeAddress, address __synthrBridge) external onlyOwner {
        _exchangeFeeAddress = __exchangeFeeAddress;
        synthrBridge = __synthrBridge;
    }

    function mintSynth(
        address _accountForCollateral,
        bytes32 _collateralKey,
        uint _collateralAmount,
        bytes32 _synthKey,
        uint _synthAmount,
        uint _debtShare
    ) external onlyBridge {
        // update collateral
        if (_collateralKey != bytes32(0) && _collateralAmount != 0) {
            _depositCollateral(_accountForCollateral, _collateralAmount, _collateralKey);
        }

        // update synth, debt share, liquidator reward
        if (_synthKey != bytes32(0) && _synthAmount != 0) {
            _issueSynth(_synthKey, _accountForCollateral, _synthAmount);
            _mintDebtShare(_accountForCollateral, _debtShare);
            _updateEntry(_debtShareBalanceOf(_accountForCollateral), _accountForCollateral);
        }
    }

    function withdrawCollateral(
        address account,
        uint amount,
        bytes32 collateralKey
    ) external onlyBridge {
        _withdrawCollateral(account, amount, collateralKey);
    }

    function burnSynth(
        address accountForSynth,
        bytes32 synthKey,
        uint synthAmount,
        uint debtShare
    ) external onlyBridge {
        _burnSynth(synthKey, accountForSynth, synthAmount);
        _burnDebtShare(accountForSynth, debtShare);

        _updateEntry(_debtShareBalanceOf(accountForSynth), accountForSynth);
    }

    function synthTransferFrom(
        bytes32 currencyKey,
        address from,
        address to,
        uint amount
    ) external onlyBridge {
        _synthTransferFrom(currencyKey, from, to, amount);
    }

    function exchangeSynth(
        address sourceAccount,
        bytes32 sourceKey,
        uint sourceAmount,
        address destAccount,
        bytes32 destKey,
        uint destAmount,
        uint fee
    ) external onlyBridge {
        _burnSynth(sourceKey, sourceAccount, sourceAmount);
        _issueSynth(destKey, destAccount, destAmount);
        _issueSynth(bytes32("sUSD"), _exchangeFeeAddress, fee);
    }

    function liquidate(
        address account,
        bytes32 collateralKey,
        uint collateralAmount,
        uint debtShare,
        uint increasedAccumulatedAmount
    ) external onlyBridge {
        _burnDebtShare(account, debtShare);

        _updateEntry(_debtShareBalanceOf(account), account);

        _updateAccumulatedShare(increasedAccumulatedAmount);

        _withdrawCollateral(account, collateralAmount, collateralKey);
    }

    function append(
        address account,
        uint amount,
        bool isFromFeePool
    ) external onlyBridge {
        // set liquidation reward as ZERO
        if (!isFromFeePool) {
            entries[account].claimable = 0;
        }
        _append(account, amount);
    }

    function vest(address account, uint amount) external onlyBridge {
        _vest(account, amount);
    }

    // to update period in DebtShare
    function addAuthorToSnapShot(address account) external onlyOwner {
        authorizedToSnapshot[account] = true;
        emit ChangeAuthority(account, true);
    }

    function removeAuthorToSnapShot(address account) external onlyOwner {
        authorizedToSnapshot[account] = false;
        emit ChangeAuthority(account, false);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IExchanger {
    function updateDestinationForExchange(
        address recipient,
        bytes32 destinationKey,
        uint destinationAmount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISynthrIssuer {
    function synthsByAddress(address synthAddress) external view returns (bytes32);

    function destIssue(
        address account,
        bytes32 synthKey,
        uint synthAmount,
        uint debtShare
    ) external;

    function destBurn(
        address account,
        bytes32 synthKey,
        uint synthAmount,
        uint debtShare
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWrappedSynthr {
    function getAvailableCollaterals() external view returns (bytes32[] memory);
}
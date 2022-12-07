// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "Address.sol";
import "ReentrancyGuard.sol";
import "Initializable.sol";
import "UUPSUpgradeable.sol";

import "IStakefishTransactionFeePoolV3.sol";
import "StakefishTransactionStorageV3.sol";

contract StakefishTransactionFeePoolV3 is
    IStakefishTransactionFeePoolV3,
    StakefishTransactionStorageV3,
    Initializable,
    UUPSUpgradeable,
    ReentrancyGuard
{
    using Address for address payable;

    // Upgradable contract.
    constructor() initializer {
    }

    function initialize(address operatorAddress_, address adminAddress_) initializer external {
        require(operatorAddress_ != address(0));
        require(adminAddress_ != address(0));
        adminAddress = adminAddress_;
        operatorAddress = operatorAddress_;
        validatorCount = 0;
        stakefishCommissionRateBasisPoints = 2000;
        isOpenForWithdrawal = true;

        // V3 storage variables
        accRewardPerValidator = 0;
        amountTransferredToColdWallet = 0;
        lastRewardUpdateBlock = block.number;
        lastLifetimeReward = getLifetimeReward();
    }

    function initialize_version3() initializer external {
        amountTransferredToColdWallet = 0;
    }

    // IMPORTANT CODE! ONLY DEV ACCOUNT CAN UPGRADE CONTRACT
    function _authorizeUpgrade(address) internal override adminOnly {}

    // Used to upgrade in place from V2 to V3.
    function migrateFromV2(address[] calldata userlist) external nonReentrant operatorOnly {
        // This check serves two purposes:
        // 1. It ensures that contract state does not change during migration.
        // 2. It requires the admin to close pool before this can be called, even though this function is operatorOnly.
        require(isOpenForWithdrawal == false, "Pool must be closed for withdrawal");
        // Note that UserSummary is repurposed from V2 and the fields:
        // - validatorCount and collectedReward contain values we want to keep from V2.
        // - lifetimeCredit and debit have junk values after upgrade.
        // We must re-write the lifetimeCredit and debit fields for every users during the v2->v3 upgrade.

        // To simplify calculations, we assume that all validators joined at the same time upon Ethereum merge.
        for (uint256 i = 0; i < userlist.length; i++) {
            // user.lifetimeCredit contains user.totalStartTimestamps from V2. Need to erase it.
            // user.debit contains user.partedUptime from V2. Need to erase it.
            users[userlist[i]].lifetimeCredit = 0;
            users[userlist[i]].debit = 0;

            // If we call accruePayout, it would eagerly update the user's lifetimeCredit and debit fields.
            // However, this is unnecessary because validator count did not change for any user.
            // accruePayout(userlist[i]);
        }
        updatePool();
    }

    function decodeValidatorInfo(uint256 data) public pure returns (address, uint256) {
        address ownerAddress = address(uint160(data));
        uint256 joinPoolTimestamp = data >> 224;
        return (ownerAddress, joinPoolTimestamp);
    }

    function encodeValidatorInfo(address ownerAddress, uint256 joinPoolTimestamp) public pure returns (uint256) {
        return uint256(uint160(ownerAddress)) | (joinPoolTimestamp << 224);
    }

    // Total rewards that have been sent into this contract since contract creation.
    function getLifetimeReward() public view returns (uint256) {
        return address(this).balance
            + amountTransferredToColdWallet // this amount is saved to cold wallet
            + lifetimePaidUserRewards // this amount is paid to users
            + lifetimeCollectedCommission; // this amount is paid to stakefish
    }

    // Reference: pancake swap updatePool function
    // https://github.com/pancakeswap/pancake-smart-contracts/blob/master/projects/farms-pools/contracts/MasterChef.sol#L209
    // This concludes a time period and updates accRewardPerValidator.
    function updatePool() internal {
        if (block.number <= lastRewardUpdateBlock || validatorCount == 0) {
            return;
        }
        uint256 curLifetimeReward = getLifetimeReward();
        accRewardPerValidator +=
            1e6 * // scale up by 1e6 to avoid precision loss due to divisions.
            (curLifetimeReward - lastLifetimeReward) / validatorCount // add in the new reward from last period
            * (10000 - stakefishCommissionRateBasisPoints) / 10000; // adjust for stakefish commission
        lastRewardUpdateBlock = block.number;
        lastLifetimeReward = curLifetimeReward;
    }

    function getAccRewardPerValidator() public view returns (uint256) {
        return accRewardPerValidator / 1e6; // scale down by 1e6, which was multiplied to avoid precision loss.
    }

    // Simulate a payout by adding pending payout to user lifetimeCredits
    function accruePayout(address depositor) internal {
        uint256 userValidatorCount = users[depositor].validatorCount;
        if (userValidatorCount > 0) {
            uint256 pending = userValidatorCount * getAccRewardPerValidator() - users[depositor].debit;
            users[depositor].lifetimeCredit += uint128(pending); // simulate a payout
        }
    }

    // Reference: pancake swap deposit function
    // https://github.com/pancakeswap/pancake-smart-contracts/blob/master/projects/farms-pools/contracts/MasterChef.sol#L228
    /**
     * Operator Functions
     */
    function joinPool(
        bytes calldata validatorPubKey,
        address depositor
    ) external nonReentrant operatorOnly {
        // One validator joined, the previous time period ends.
        updatePool();
        _joinPool(validatorPubKey, depositor);
        emit ValidatorJoined(validatorPubKey, depositor, block.timestamp);
    }

    // This function implementation references:
    // https://github.com/pancakeswap/pancake-smart-contracts/blob/master/projects/farms-pools/contracts/MasterChef.sol#L228
    function _joinPool(
        bytes calldata validatorPubKey,
        address depositor
    ) internal {
        require(
            validatorOwnerAndJoinTime[validatorPubKey] == 0,
            "Validator already in pool"
        );
        require(
            depositor != address(0),
            "depositorAddress must be set"
        );

        // If the user already has some validators in the pool, we simulate a payout for existing validators.
        accruePayout(depositor);

        // Add the given validator to the UserSummary.
        users[depositor].validatorCount += 1;
        validatorCount += 1;
        validatorOwnerAndJoinTime[validatorPubKey] = encodeValidatorInfo(depositor, block.timestamp);
        users[depositor].debit = uint128(users[depositor].validatorCount * getAccRewardPerValidator());
    }

    function partPool(
        bytes calldata validatorPubKey
    ) external nonReentrant operatorOnly {
        // One validator left, the previous time period ends.
        updatePool();
        address depositor = _partPool(validatorPubKey);
        emit ValidatorParted(validatorPubKey, depositor, block.timestamp);
    }

    function _partPool(
        bytes calldata validatorPubKey
    ) internal returns (address depositorAddress) {
        (address depositor, ) = decodeValidatorInfo(validatorOwnerAndJoinTime[validatorPubKey]);
        require(
            depositor != address(0),
            "Validator not in pool"
        );

        // Simulate a payout for the existing validators.
        accruePayout(depositor);

        validatorCount -= 1;
        users[depositor].validatorCount -= 1;
        delete validatorOwnerAndJoinTime[validatorPubKey];
        users[depositor].debit = uint128(users[depositor].validatorCount * getAccRewardPerValidator());

        return depositor;
    }

    // These two functions are added for V2 compatibility--they allow the oracle to call joinPool and partPool with the V2 abi.
    // These two functions are not in the interface and are only used by the oracle for backward compatibility purposes.
    function joinPool(bytes calldata validatorPubKey, address depositor, uint256)
        external override nonReentrant operatorOnly
    {
        updatePool();
        _joinPool(validatorPubKey, depositor);
        emit ValidatorJoined(validatorPubKey, depositor, block.timestamp);
    }
    function partPool(bytes calldata validatorPubKey, uint256) external override nonReentrant operatorOnly {
        updatePool();
        address depositor = _partPool(validatorPubKey);
        emit ValidatorParted(validatorPubKey, depositor, block.timestamp);
    }

    function bulkJoinPool(
        bytes calldata validatorPubkeyArray,
        address[] calldata depositorAddresses,
        uint256
    ) external override nonReentrant operatorOnly {
        require(depositorAddresses.length == 1 || depositorAddresses.length * 48 == validatorPubkeyArray.length, "Invalid depositorAddresses length");

        updatePool();
        uint256 validatorCount = validatorPubkeyArray.length / 48;
        if (depositorAddresses.length == 1) {
            for(uint256 i = 0; i < validatorCount; i++) {
                _joinPool(validatorPubkeyArray[i*48:(i+1)*48], depositorAddresses[0]);
                emit ValidatorJoined(validatorPubkeyArray[i*48:(i+1)*48], depositorAddresses[0], block.timestamp);
            }
        } else {
            for(uint256 i = 0; i < validatorCount; i++) {
                _joinPool(validatorPubkeyArray[i*48:(i+1)*48], depositorAddresses[i]);
                emit ValidatorJoined(validatorPubkeyArray[i*48:(i+1)*48], depositorAddresses[i], block.timestamp);
            }
        }
    }

    function bulkPartPool(
        bytes calldata validatorPubkeyArray,
        uint256
    ) external override nonReentrant operatorOnly {
        require(validatorPubkeyArray.length % 48 == 0, "pubKeyArray length not multiple of 48");

        updatePool();
        uint256 validatorCount = validatorPubkeyArray.length / 48;
        for(uint256 i = 0; i < validatorCount; i++) {
            address depositor = _partPool(validatorPubkeyArray[i*48:(i+1)*48]);
            emit ValidatorParted(validatorPubkeyArray[i*48:(i+1)*48], depositor, block.timestamp);
        }
    }

    // @return (pendingRewards, collectedRewards)
    function computePayout(address depositor) internal view returns (uint256, uint256) {
        // this is a view function so we cannot call updatePool() or accruePayout().
        uint256 accRewardPerValidatorWithCurPeriod = getAccRewardPerValidator();
        if (block.number > lastRewardUpdateBlock && validatorCount > 0) {
            // If the accRewardPerValidator is not up-to-date, we need to include rewards from the current time period.
            uint256 curLifetimeReward = getLifetimeReward();
            accRewardPerValidatorWithCurPeriod +=
                (curLifetimeReward - lastLifetimeReward) / validatorCount * (10000 - stakefishCommissionRateBasisPoints) / 10000;
        }

        uint256 totalPayout = users[depositor].validatorCount * accRewardPerValidatorWithCurPeriod
            + users[depositor].lifetimeCredit - users[depositor].debit;

        if (totalPayout > users[depositor].collectedReward) {
            return (totalPayout - users[depositor].collectedReward, users[depositor].collectedReward);
        } else {
            return (0, users[depositor].collectedReward);
        }
    }

    // This function estimates user pending reward based on the latest block timestamp.
    // In order to keep this function to be a view function, it does not update the computation cache.
    function pendingReward(address depositorAddress) external override view returns (uint256, uint256) {
        require(depositorAddress != address(0), "depositorAddress must be set");
        return computePayout(depositorAddress);
    }

    // Reference: Pancake swap withdraw function
    // https://github.com/pancakeswap/pancake-smart-contracts/blob/master/projects/farms-pools/contracts/MasterChef.sol#L249
    function _collectReward(
        address depositorAddress,
        address payable beneficiary,
        uint256 amountRequested
    ) internal {
        if (beneficiary == address(0)) {
            beneficiary = payable(depositorAddress);
        }

        accruePayout(depositorAddress);
        users[depositorAddress].debit = uint128(users[depositorAddress].validatorCount * getAccRewardPerValidator());

        uint256 pending = users[depositorAddress].lifetimeCredit - users[depositorAddress].collectedReward;
        if (amountRequested == 0) {
            users[depositorAddress].collectedReward += uint128(pending);
            lifetimePaidUserRewards += pending;
            emit ValidatorRewardCollected(depositorAddress, beneficiary, pending, msg.sender);
            require(pending <= address(this).balance, "Contact [email protected] to top up the contract");
            beneficiary.sendValue(pending);
        } else {
            require(amountRequested <= pending, "Not enough pending rewards");
            users[depositorAddress].collectedReward += uint128(amountRequested);
            lifetimePaidUserRewards += amountRequested;
            emit ValidatorRewardCollected(depositorAddress, beneficiary, amountRequested, msg.sender);
            require(amountRequested <= address(this).balance, "Contact [email protected] to top up the contract");
            beneficiary.sendValue(amountRequested);
        }
    }

    // collect rewards from the tip pool, up to amountRequested.
    // If amountRequested is unspecified, collect all rewards.
    function collectReward(address payable beneficiary, uint256 amountRequested) external override nonReentrant {
        require(isOpenForWithdrawal, "Pool is not open for withdrawal right now");
        updatePool();
        _collectReward(msg.sender, beneficiary, amountRequested);
    }

    function _transferValidator(bytes calldata validatorPubKey, address to) internal {
        (address validatorOwner, ) = decodeValidatorInfo(validatorOwnerAndJoinTime[validatorPubKey]);
        require(validatorOwner != address(0), "Validator not in pool");
        require(to != address(0), "to address must be set to nonzero");
        require(to != validatorOwner, "cannot transfer validator owner to oneself");

        _partPool(validatorPubKey);
        _joinPool(validatorPubKey, to);

        emit ValidatorTransferred(validatorPubKey, validatorOwner, to, block.timestamp);
    }

    /*
    // This function is not enabled for now to keep the current product simple.

    function transferValidatorByOwner(bytes calldata validatorPubKey, address to) external override nonReentrant {
        (address validatorOwner, ) = decodeValidatorInfo(validatorOwnerAndJoinTime[validatorPubKey]);
        require(validatorOwner == msg.sender, "Only the validator owner can transfer the validator");
        _transferValidator(validatorPubKey, to, block.timestamp);
    }
    */

    /**
     * Admin Functions
     */
    function setCommissionRate(uint256 commissionRate) external override nonReentrant adminOnly {
        updatePool();
        stakefishCommissionRateBasisPoints = commissionRate;
        emit CommissionRateChanged(stakefishCommissionRateBasisPoints);
    }

    // Collect accumulated commission fees, up to amountRequested.
    // If amountRequested is unspecified, collect all fees.
    function collectPoolCommission(address payable beneficiary, uint256 amountRequested)
        external
        override
        nonReentrant
        adminOnly
    {
        uint256 totalContractValue = getLifetimeReward();
        uint256 totalCommission = totalContractValue * stakefishCommissionRateBasisPoints / 10000;
        uint256 pendingCommission = totalCommission - lifetimeCollectedCommission;
        if (amountRequested == 0) {
            lifetimeCollectedCommission += pendingCommission;
            emit CommissionCollected(beneficiary, pendingCommission);
            beneficiary.sendValue(pendingCommission);
        } else {
            require(amountRequested <= pendingCommission, "Not enough pending commission");
            lifetimeCollectedCommission += amountRequested;
            emit CommissionCollected(beneficiary, amountRequested);
            beneficiary.sendValue(amountRequested);
        }
    }

    function transferValidatorByAdmin(
        bytes calldata validatorPubkeys,
        address[] calldata toAddresses
    ) external override nonReentrant adminOnly {
        require(validatorPubkeys.length == toAddresses.length * 48, "validatorPubkeys byte array length incorrect");
        for (uint256 i = 0; i < toAddresses.length; i++) {
            _transferValidator(
                validatorPubkeys[i * 48 : (i + 1) * 48],
                toAddresses[i]
            );
        }
    }

    // Used to transfer claim history from another contract into this one.
    // @param addresses: array of user addresses
    // @param claimAmount: amount paid to the user outside of the contract
    // Warning: the balance from the previous contract must be transferred over as well.
    function transferClaimHistory(address[] calldata addresses, uint256[] calldata claimAmount)
        external
        override
        adminOnly
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            lifetimePaidUserRewards += claimAmount[i];
            users[addresses[i]].collectedReward += uint128(claimAmount[i]);
        }
    }

    // Used by admins to handle emergency situations where we want to temporarily pause all withdrawals.
    function closePoolForWithdrawal() external override nonReentrant adminOnly {
        require(isOpenForWithdrawal, "Pool is already closed for withdrawal");
        isOpenForWithdrawal = false;
    }

    function openPoolForWithdrawal() external override nonReentrant adminOnly {
        require(!isOpenForWithdrawal, "Pool is already open for withdrawal");
        isOpenForWithdrawal = true;
    }

    function changeOperator(address newOperator) external override nonReentrant adminOnly {
        require(newOperator != address(0));
        operatorAddress = newOperator;
        emit OperatorChanged(operatorAddress);
    }

    function emergencyWithdraw (
        address[] calldata depositorAddresses,
        address[] calldata beneficiaries,
        uint256 maxAmount
    )
        external
        override
        nonReentrant
        adminOnly
    {
        require(beneficiaries.length == depositorAddresses.length || beneficiaries.length == 1, "beneficiaries length incorrect");
        updatePool();
        if (beneficiaries.length == 1) {
            for (uint256 i = 0; i < depositorAddresses.length; i++) {
                _collectReward(depositorAddresses[i], payable(beneficiaries[0]), maxAmount);
            }
        } else {
            for (uint256 i = 0; i < depositorAddresses.length; i++) {
                _collectReward(depositorAddresses[i], payable(beneficiaries[i]), maxAmount);
            }
        }
    }

    function saveToColdWallet(address wallet, uint256 amount) external nonReentrant override adminOnly {
        require(amount <= address(this).balance, "Not enough balance");
        amountTransferredToColdWallet += amount;
        payable(wallet).sendValue(amount);
    }

    function loadFromColdWallet() external payable nonReentrant override adminOnly {
        require(msg.value <= amountTransferredToColdWallet, "Too much transferred from cold wallet");
        amountTransferredToColdWallet -= msg.value;
    }

    function totalValidators() external override view returns (uint256) {
        return validatorCount;
    }

    function getPoolState() external override view returns (uint256, uint256, uint256, uint256, uint256, uint256, bool) {
        return (
            lastRewardUpdateBlock,
            getAccRewardPerValidator(),
            validatorCount,
            lifetimeCollectedCommission,
            lifetimePaidUserRewards,
            amountTransferredToColdWallet,
            isOpenForWithdrawal
        );
    }

    function getUserState(address user) external override view returns (uint256, uint256, uint256, uint256) {
        return (
            users[user].validatorCount,
            users[user].lifetimeCredit,
            users[user].debit,
            users[user].collectedReward
        );
    }

    /**
     * Modifiers
     */
    modifier operatorOnly() {
        require(
            msg.sender == operatorAddress,
            "Only stakefish operator allowed"
        );
        _;
    }

    modifier adminOnly() {
        require(
            msg.sender == adminAddress,
            "Only stakefish admin allowed"
        );
        _;
    }

    // This contract should not receive value directly.
    // All value should be sent to the proxy contract.
    // receive() external override payable { }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !Address.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "draft-IERC1822.sol";
import "ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "IBeacon.sol";
import "draft-IERC1822.sol";
import "Address.sol";
import "StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/**
 * IStakefishTransactionFeePoolV3
 * This contract collects transaction fees from a pool of validators, and shares the income with their delegators (depositors).
 * Important notes compared to V2:
 * - The ability to retroactively specify join and part pool time is no longer present.
 * - joinPool and partPool no longer take timestamps--they are effective as of the transaction.
 * - We no longer emit bulkJoinPool and bulkPartPool events.
 */
interface IStakefishTransactionFeePoolV3 {
    event ValidatorJoined(bytes indexed validatorPubkey, address indexed depositorAddress, uint256 ts);
    event ValidatorParted(bytes indexed validatorPubkey, address indexed depositorAddress, uint256 ts);
    event ValidatorBulkJoined(bytes validatorPubkeyArray, address[] depositorAddress, uint256 time);
    event ValidatorBulkParted(bytes validatorPubkeyArray, address[] depositorAddress, uint256 time);
    event ValidatorRewardCollected(address indexed depositorAddress, address beneficiary, uint256 rewardAmount, address requester);
    event ValidatorTransferred(bytes indexed validatorPubkey, address indexed from, address indexed to, uint256 ts);
    event OperatorChanged(address newOperator);
    event CommissionRateChanged(uint256 newRate);
    event CommissionCollected(address beneficiary, uint256 collectedAmount);

    // Operator Only

    /**
     * @notice Add a validator to the pool
     * @dev operatorOnly.
     * Emits an {ValidatorJoined} event.
     * Requirements:
     * `validatorPubkey` cannot double join (Validator already in pool).
     * `depositorAddress` is not nullable (depositorAddress must be set).
     * @param validatorPubKey The validator's public key
     * @param depositorAddress The delegator that is associated with the validator
     */
    function joinPool(bytes calldata validatorPubKey, address depositorAddress, uint256 unused) external;

    /**
     * @notice Remove a validator from the pool
     * @dev operatorOnly.
     * Emits an {ValidatorParted} event.
     * Requirements:
     * `validatorPubKey` must be in the pool (Validator not in pool).
     * @param validatorPubKey The validator's public key
     */
    function partPool(bytes calldata validatorPubKey, uint256 unused) external;

    /**
     * @notice Add many validators to the pool
     * @dev operatorOnly.
     * @param validatorPubKeys The list of validator public keys to add (must be a multiple of 48)
     * @param depositorAddresses The depositor addresses to associate with the validators.
     */
    function bulkJoinPool(bytes calldata validatorPubKeys, address[] calldata depositorAddresses, uint256 unused) external;

    /**
     * @notice Remove many validators from the pool
     * @dev operatorOnly.
     * @param validatorPubKeys The list of validator public keys to remove (must be a multiple of 48)
     */
    function bulkPartPool(bytes calldata validatorPubKeys, uint256 unused) external;

    // Admin Only

    /**
     * @notice Set the contract commission rate
     * @dev adminOnly.
     * Emits an {CommissionRateChanged} event.
     * @param commissionRate The new commission rate
     */
    function setCommissionRate(uint256 commissionRate) external;

    /**
     * @notice Collect new commission fees up to `amountRequested`.
     * @dev adminOnly.
     * Emits an {CommissionCollected} event.
     * Requirements:
     * `amountRequested` cannot be greater than the available balance (Not enough pending commission).
     * @param beneficiary The address that the `amountRequested` will be sent to
     * @param amountRequested The amount that will be sent to the `beneficiary`. If 0, collect all fees.
     */
    function collectPoolCommission(address payable beneficiary, uint256 amountRequested) external;

    /**
     * @notice Change the contract operator
     * @dev adminOnly.
     * Emits an {OperatorChanged} event.
     * Requirements:
     * `newOperator` is not nullable ().
     * @param newOperator The new operator
     */
    function changeOperator(address newOperator) external;

    /**
     * @notice Temporarily disable reward collection during a contract maintenance window
     * @dev adminOnly.
     * Requirements:
     * `isOpenForWithdrawal` must be true (Pool is already closed for withdrawal).
     */
    function closePoolForWithdrawal() external;

    /**
     * @notice Enable reward collection after a temporary contract maintenance window
     * @dev adminOnly.
     * Requirements:
     * `isOpenForWithdrawal` must be false (Pool is already open for withdrawal).
     */
    function openPoolForWithdrawal() external;

    /**
     * @notice Transfer one or more validators to new fee pool owners.
     * @dev adminOnly.
     * Emits many {ValidatorParted}, {ValidatorJoined} and {ValidatorTransferred} events.
     * Requirements:
     * `validatorPubKeys`.length must equal `toAddresses`.length * 48 (validatorPubKeys byte array length incorrect).
     * Every `validatorPubKey` must be in the pool (Validator not in pool).
     * No `toAddress` is nullable (to address must be set to nonzero).
     * No `toAddress` can be equal to the validator's depositor (cannot transfer validator owner to oneself).
     * `transferTimestamp` must be before every validator's `joinTime` (Validator transferTimestamp is before join pool time).
     * `transferTimestamp` must not be in the future (Validator transferTimestamp is in the future).
     * @param validatorPubKeys The list of validators that will be transferred
     * @param toAddresses The list of addresses that the validators will be transferred to
     */
    function transferValidatorByAdmin(bytes calldata validatorPubKeys, address[] calldata toAddresses) external;

    /**
     * @notice Transfer historical claim amounts into this contract
     * @dev adminOnly (used during contract migration) (not idempotent!)
     * @param addresses The list of depositor addresses that collected
     * @param claimedAmounts The total amount collected by each depositor
     */
    function transferClaimHistory(address[] calldata addresses, uint256[] calldata claimedAmounts) external;

    /**
     * @notice Admin function to help users recover funds from a lost or stolen wallet
     * @dev adminOnly.
     * Emits an {ValidatorRewardCollected} event.
     * Requirements:
     * `beneficiaries`.length must equal 1 or `depositorAddresses`.length (beneficiaries length incorrect).
     * The pool must be open for withdrawals (Pool is not open for withdrawal right now).
     * `amountRequested` cannot be greater than the available balance (Not enough pending rewards).
     * @param depositorAddresses The list of depositors to withdraw rewards from
     * @param beneficiaries The list of addresses that will be sent the depositors' rewards
     * @param amountRequested The max amount to be withdrawn. If 0, all depositors' pending rewards will be withdrawn.
     */
    function emergencyWithdraw(address[] calldata depositorAddresses, address[] calldata beneficiaries, uint256 amountRequested) external;


    /**
     * @notice Admin function to transfer excess balance into a cold wallet for safekeeping.
     * @dev adminOnly.
     * @param wallet the cold wallet to transfer to
     * @param amount the amount to transfer
     */
    function saveToColdWallet(address wallet, uint256 amount) external;

    /**
     * @notice Admin function to transfer balance back from a cold wallet. Please do not send value from the cold
     * wallet directly into this contract. This function needs to do accounting to track the transferred balance.
     * @dev adminOnly.
     */
    function loadFromColdWallet() external payable;

    // Public

    /**
     * @notice The amount of rewards a depositor can withdraw, and all rewards they have ever withdrawn
     * @dev Reverts if `depositorAddress` is not set (depositorAddress must be set).
     * @param depositorAddress The depositor address
     * @return pendingRewards The current amount available for withdrawal by the depositor
     * @return collectedRewards The total amount ever withdrawn by the depositor
     */
    function pendingReward(address depositorAddress) external view returns (
        uint256 pendingRewards,
        uint256 collectedRewards
    );

    /**
     * @notice Allow a depositor (`msg.sender`) to collect their tip rewards from the pool.
     * @dev Emits an {ValidatorRewardCollected} event.
     * Requirements:
     * The pool must be open for withdrawals (Pool is not open for withdrawal right now).
     * `amountRequested` cannot be greater than the available balance (Not enough pending rewards).
     * @param beneficiary The address that the `amountRequested` will be sent to. If not set, send to `msg.sender`.
     * @param amountRequested The amount that will be sent to the `beneficiary`. If 0, send all pending rewards.
     */
    function collectReward(address payable beneficiary, uint256 amountRequested) external;

    /**
     * @notice The count of all validators in the pool
     * @return validatorCount_ The count of all validators in the pool
     */
    function totalValidators() external view returns (
        uint256 validatorCount_
    );

    /**
     * @notice A summary of the pool's current state
     */
    function getPoolState() external view returns (
        uint256 lastRewardUpdateBlock,
        uint256 accRewardPerValidator,
        uint256 validatorCount,
        uint256 lifetimeCollectedCommission,
        uint256 lifetimePaidUserRewards,
        uint256 amountInColdWallet,
        bool isPoolOpenForWithdrawal
    );

    /**
     * @notice A summary of the depositor's activity in the pool
     * @param user The depositor's address
     */
    function getUserState(address user) external view returns (
        uint256 validatorCount,
        uint256 lifetimeCredit,
        uint256 debit,
        uint256 collectedReward
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract StakefishTransactionStorageV3 {
    // Note that the UserSummary definition changed, but the struct layout remains the same in storage.
    // The old definition is included here for reference.
    // struct UserSummary {
    //     uint128 validatorCount;
    //     uint128 totalStartTimestamps;
    //     uint128 partedUptime;
    //     uint128 collectedReward;
    // }
    struct UserSummary {
        uint128 validatorCount;
        uint128 lifetimeCredit;
        uint128 debit;
        uint128 collectedReward;
    }

    // Carried over from v2, no longer used.
    struct DEPRECATED_ComputationCache {
        uint256 lastCacheUpdateTime;
        uint256 totalValidatorUptime;
    }

    /////////////////////////////////////////////////////////////
    // V2 storage preserved to allow in place upgrade.         //
    // Some are deprecated and no longer used.                 //
    /////////////////////////////////////////////////////////////
    address internal adminAddress;
    address internal operatorAddress;

    uint256 internal validatorCount;
    uint256 public stakefishCommissionRateBasisPoints;

    uint256 public lifetimeCollectedCommission;
    uint256 public lifetimePaidUserRewards;

    bool public isOpenForWithdrawal;

    mapping(address => UserSummary) internal users;
    mapping(bytes => uint256) internal validatorOwnerAndJoinTime;
    DEPRECATED_ComputationCache internal DEPRECATED_cache;
    /////////////////////////////////////////////////////////////
    // End of V2 data structures                               //
    /////////////////////////////////////////////////////////////

    // The below are storage variables introduced by V3
    uint256 public amountTransferredToColdWallet;
    uint256 internal accRewardPerValidator;

    uint256 internal lastRewardUpdateBlock;
    uint256 internal lastLifetimeReward;
}
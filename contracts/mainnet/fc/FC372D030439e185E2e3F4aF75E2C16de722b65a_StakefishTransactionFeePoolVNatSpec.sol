// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "Address.sol";

import "IStakefishTransactionFeePoolV2.sol";

contract StakefishTransactionFeePoolVNatSpec is
//    Initializable,
//    UUPSUpgradeable,
    IStakefishTransactionFeePoolV2
{
    using Address for address payable;

    constructor() {}

//    constructor() initializer {}
//
//    function initialize(address operatorAddress_, address adminAddress_) initializer external {
//        // ...;
//    }
//
//    function _authorizeUpgrade(address) internal override adminOnly {}

    /**
     * @notice Helper method to decode `validatorInfo` into its components. uint256 packs two information:
     * The lower 4 bytes are a timestamp representing the join pool time of the validator.
     * The next 20 bytes are the ETH1 address of the owner.
     * @param validatorInfo uint256 encoded `validatorInfo` containing (address ownerAddress, uint256 joinPoolTimestamp)
     * @return ownerAddress The delegator address that owns the validator
     * @return joinPoolTimestamp The timestamp when the validator started accruing payable uptime in the pool
     */
    function decodeValidatorInfo(
        uint256 validatorInfo
    ) virtual public pure returns (
        address ownerAddress,
        uint256 joinPoolTimestamp
    ) {
        return (address(0), 0);
    }

    /**
     * @notice Helper method to encode validatorInfo from its components. The lower 4 bytes of the encoded `data`
     * are a timestamp representing the join pool time of the validator. The next 20 bytes are the ETH1 address of the owner.
     * @dev Returns (uint256 `data`)
     * @param ownerAddress The depositor that owns the validator
     * @param joinPoolTimestamp The timestamp recorded when the validator joined the pool
     * @return validatorInfo uint256 encoded `ownerAddress` and `joinPoolTimestamp`
     */
    function encodeValidatorInfo(
        address ownerAddress,
        uint256 joinPoolTimestamp
    ) virtual public pure returns (uint256 validatorInfo) {
        return 0;
    }

    /**
     * Operator Functions
     */

    /**
     * @inheritdoc IStakefishTransactionFeePoolV2
     */
    function joinPool(
        bytes calldata validatorPubKey,
        address depositorAddress,
        uint256 joinTime
    ) external override operatorOnly {
        // ...;
    }

    /**
     * @inheritdoc IStakefishTransactionFeePoolV2
     */
    function partPool(
        bytes calldata validatorPubKey,
        uint256 leaveTime
    ) external override operatorOnly {
        // ...;
    }

    /**
     * @inheritdoc IStakefishTransactionFeePoolV2
     */
    function bulkJoinPool(
        bytes calldata validatorPubKeyArray,
        address[] calldata depositorAddresses,
        uint256 joinTime
    ) external override operatorOnly {
        // ...;
    }

    /**
     * @inheritdoc IStakefishTransactionFeePoolV2
     */
    function bulkPartPool(
        bytes calldata validatorPubKeyArray,
        uint256 leaveTime
    ) external override operatorOnly {
        // ...;
    }

    /**
     * @inheritdoc IStakefishTransactionFeePoolV2
     */
    function pendingReward(
        address depositorAddress
    ) virtual external override view returns (
        uint256 pendingRewards,
        uint256 collectedRewards
    ) {
        return (0, 0);
    }

    /**
     * @inheritdoc IStakefishTransactionFeePoolV2
     */
    function collectReward(
        address payable beneficiary,
        uint256 amountRequested
    ) external override {
        // ...;
    }

    /**
     * Admin Functions
     */

    /**
     * @inheritdoc IStakefishTransactionFeePoolV2
     */
    function setCommissionRate(
        uint256 commissionRate
    ) external override adminOnly {
        // ...;
    }

    /**
     * @inheritdoc IStakefishTransactionFeePoolV2
     */
    function collectPoolCommission(
        address payable beneficiary,
        uint256 amountRequested
    ) external override adminOnly {
        // ...;
    }

    /**
     * @inheritdoc IStakefishTransactionFeePoolV2
     */
    function transferValidatorByAdmin(
        bytes calldata validatorPubKeys,
        address[] calldata toAddresses,
        uint256 transferTimestamp
    ) external override adminOnly {
        // ...;
    }

    /**
     * @inheritdoc IStakefishTransactionFeePoolV2
     */
    function transferClaimHistory(
        address[] calldata addresses,
        uint256[] calldata claimedAmounts
    ) external override adminOnly {
        // ...;
    }

    /**
     * @inheritdoc IStakefishTransactionFeePoolV2
     */
    function closePoolForWithdrawal() external override adminOnly {
        // ...;
    }

    /**
     * @inheritdoc IStakefishTransactionFeePoolV2
     */
    function openPoolForWithdrawal() external override adminOnly {
        // ...;
    }

    /**
     * @inheritdoc IStakefishTransactionFeePoolV2
     */
    function changeOperator(
        address newOperator
    ) external override adminOnly {
        // ...;
    }

    /**
     * @inheritdoc IStakefishTransactionFeePoolV2
     */
    function emergencyWithdraw (
        address[] calldata depositorAddresses,
        address[] calldata beneficiaries,
        uint256 amountRequested
    ) external override adminOnly {
        // ...;
    }

    /**
     * Public
     */

    /**
     * @inheritdoc IStakefishTransactionFeePoolV2
     */
    function totalValidators() virtual external override view returns (uint256 validatorCount) {
        return 0;
    }

    /**
     * @inheritdoc IStakefishTransactionFeePoolV2
     */
    function getPoolState() virtual external override view returns (
        uint256 lastCachedUpdateTime,
        uint256 totalValidatorUptime,
        uint256 validatorCount,
        uint256 lifetimeCollectedCommission,
        uint256 lifetimePaidUserRewards
    ) {
        return (0, 0, 0, 0, 0);
    }

    /**
     * @inheritdoc IStakefishTransactionFeePoolV2
     */
    function getUserState(address user) virtual external override view returns (
        uint256 validatorCount,
        uint256 totalStartTimestamps,
        uint256 partedUptime,
        uint256 collectedReward
    ) {
        return (0, 0, 0, 0);
    }

    /**
     * Modifiers
     */

    modifier operatorOnly() {
        _;
    }

    modifier adminOnly() {
        _;
    }

    receive() external override payable {
        // ...;
    }

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

pragma solidity ^0.8.7;

/**
 * IStakefishTransactionFeePoolV2
 * This contract collects transaction fees from a pool of validators, and shares the income with their delegators (depositors).
 */
interface IStakefishTransactionFeePoolV2 {
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
     * Reverts if `validatorPubkey` is already in the pool (Validator already in pool).
     * Reverts if the `depositorAddress` address is not set (depositorAddress must be set).
     * Reverts if `joinTime` is set in the future (Invalid validator joinTime).
     * @param validatorPubKey The validator's public key
     * @param depositorAddress The delegator that is associated with the validator
     * @param joinTime The timestamp when the validator started accruing uptime
     */
    function joinPool(bytes calldata validatorPubKey, address depositorAddress, uint256 joinTime) external;

    /**
     * @notice Remove a validator from the pool
     * @dev operatorOnly.
     * Emits an {ValidatorParted} event.
     * Reverts if the `validatorPubKey` is not in the pool (Validator not in pool).
     * Reverts if the `leaveTime` is in the future (Invalid validator leaveTime).
     * Reverts if the `leaveTime` is before the validator's `joinTime` (leave pool time must be after join pool time).
     * @param validatorPubKey The validator's public key
     * @param leaveTime The timestamp when the validator stopped accruing uptime
     */
    function partPool(bytes calldata validatorPubKey, uint256 leaveTime) external;

    /**
     * @notice Add many validators to the pool
     * @dev operatorOnly.
     * Emits an {ValidatorBulkJoined} event.
     * Reverts if `joinTime` is in the future (Invalid validator join timestamp).
     * Reverts if `depositorAddresses`.length is != 1 and != `validatorPubKeyArray`length / 48 (Invalid depositorAddresses length).
     * Reverts if any of the depositor addresses is not set (depositorAddress must be set).
     * Reverts if any of the validators are already in the pool (Validator already in pool).
     * @param validatorPubKeyArray The list of validator public keys to add (must be a multiple of 48)
     * @param depositorAddresses The depositor addresses to associate with the validators.
     * If length is 1, then the same depositor address is used for all validators.
     * Otherwise the array must have length equal to validatorPubKeys.length / 48.
     * @param joinTime The timestamp when the validators started accruing uptime
     */
    function bulkJoinPool(bytes calldata validatorPubKeyArray, address[] calldata depositorAddresses, uint256 joinTime) external;

    /**
     * @notice Remove many validators from the pool
     * @dev operatorOnly.
     * Emits one {ValidatorBulkParted} and many {ValidatorParted} events.
     * Reverts if `validatorPubKeyArray` is not divisible by 48 (Validator length not multiple of 48).
     * Reverts if the `validatorPubKey` is not in the pool (Validator not in pool).
     * Reverts if the `leaveTime` is in the future (Invalid validator leaveTime).
     * Reverts if the `leaveTime` is before the validator's `joinTime` (leave pool time must be after join pool time).
     * @param validatorPubKeyArray The list of validator public keys to remove (must be a multiple of 48)
     * @param leaveTime The timestamp when the validators stopped accruing uptime
     */
    function bulkPartPool(bytes calldata validatorPubKeyArray, uint256 leaveTime) external;

    // Admin Only

    /**
     * @notice Set the contract commission rate
     * @dev adminOnly.
     * Emits an {CommissionRateChanged} event.
     * @param commissionRate The new commission rate
     */
    function setCommissionRate(uint256 commissionRate) external;

    /**
     * @notice Collect new commission fees, up to `amountRequested`.
     * @dev adminOnly.
     * Emits an {CommissionCollected} event.
     * @param beneficiary The address that the `amountRequested` will be sent to
     * @param amountRequested The amount that will be sent to the `beneficiary`. If 0, collect all fees.
     */
    function collectPoolCommission(address payable beneficiary, uint256 amountRequested) external;

    /**
     * @notice Change the contract operator
     * @dev adminOnly.
     * Emits an {OperatorChanged} event.
     * Reverts if `newOperator` is not set ().
     * @param newOperator The new operator
     */
    function changeOperator(address newOperator) external;

    /**
     * @notice Temporarily disable reward collection during a contract maintenance window
     * @dev adminOnly.
     * Reverts if `isOpenForWithdrawal` (Pool is already closed for withdrawal).
     */
    function closePoolForWithdrawal() external;

    /**
     * @notice Enable reward collection after a temporary contract maintenance window
     * @dev adminOnly.
     * Reverts if !`isOpenForWithdrawal` (Pool is already open for withdrawal).
     */
    function openPoolForWithdrawal() external;

    /**
     * @notice Transfer one or more validators to new fee pool owners.
     * @dev adminOnly.
     * Emits many {ValidatorParted}, {ValidatorJoined} and {ValidatorTransferred} events.
     * Reverts if `validatorPubKeys`.length != `toAddresses`.length * 48 (validatorPubKeys byte array length incorrect).
     * Reverts if the `validatorPubKey` is not in the pool (Validator not in pool).
     * Reverts if `toAddresses[i]` is not set (to address must be set to nonzero).
     * Reverts if `toAddresses[i]` is the validator's depositor (cannot transfer validator owner to oneself).
     * Reverts if `transferTimestamp` is before the validator's `joinTime` (Validator transferTimestamp is before join pool time).
     * Reverts if `transferTimestamp` is in the future (Validator transferTimestamp is in the future).
     * @param validatorPubKeys The list of validators that will be transferred
     * @param toAddresses The list of addresses that the validators will be transferred to
     * @param transferTimestamp The time when the validators were transferred
     */
    function transferValidatorByAdmin(bytes calldata validatorPubKeys, address[] calldata toAddresses, uint256 transferTimestamp) external;

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
     * Reverts if `depositorAddresses`.length != `beneficiaries`.length and `beneficiaries`.length != 1 (beneficiaries length incorrect).
     * Reverts if the pool is not open for withdrawals (Pool is not open for withdrawal right now).
     * @param depositorAddresses The list of depositors to withdraw rewards from
     * @param beneficiaries The list of addresses that will be sent the depositors' rewards
     * @param amountRequested The max amount to be withdrawn. If 0, all depositors' pending rewards will be withdrawn.
     */
    function emergencyWithdraw(address[] calldata depositorAddresses, address[] calldata beneficiaries, uint256 amountRequested) external;

    // Public

    /**
     * @notice The amount of rewards a depositor can withdraw, and all rewards they have ever withdrawn
     * @dev Reverts if `depositorAddress` is not set (depositorAddress must be set).
     * @param depositorAddress The depositor address
     * @return pendingRewards The current amount available for withdrawal by the depositor
     * @return collectedRewards The total amount ever withdrawn by the depositor
     * )
     */
    function pendingReward(address depositorAddress) external view returns (
        uint256 pendingRewards,
        uint256 collectedRewards
    );

    /**
     * @notice Allow a depositor ({msg.sender}) to collect their tip rewards from the pool.
     * @dev Emits an {ValidatorRewardCollected} event.
     * Reverts if the pool is not open for withdrawals (Pool is not open for withdrawal right now).
     * @param beneficiary The address that the `amountRequested` will be sent to. If not set, send to {msg.sender}.
     * @param amountRequested The amount that will be sent to the `beneficiary`. If 0, send all pending rewards.
     */
    function collectReward(address payable beneficiary, uint256 amountRequested) external;

    /**
     * @notice The count of all validators in the pool
     * @return validatorCount The count of all validators in the pool
     */
    function totalValidators() external view returns (
        uint256 validatorCount
    );

    /**
     * @notice A summary of the pool's current state
     * @return lastCachedUpdateTime The timestamp when `totalValidatorUptime` was last updated
     * @return totalValidatorUptime The pool's total uptime
     * @return validatorCount The count of all validators in the pool
     * @return lifetimeCollectedCommission The amount of commissions ever collected from the pool
     * @return lifetimePaidUserRewards The amount of user rewards ever withdrawn the pool
     * )
     */
    function getPoolState() external view returns (
        uint256 lastCachedUpdateTime,
        uint256 totalValidatorUptime,
        uint256 validatorCount,
        uint256 lifetimeCollectedCommission,
        uint256 lifetimePaidUserRewards
    );

    /**
     * @notice A summary of the depositor's activity in the pool
     * @param user The depositor's address
     * @return validatorCount The count of all validators owned by the depositor
     * @return totalStartTimestamps The sum of all validator joinTime's owned by the depositor
     * @return partedUptime The uptime from all parted validators owned by the depositor
     * @return collectedReward The total of all collected rewards ever collected by the depositor
     * )
     */
    function getUserState(address user) external view returns (
        uint256 validatorCount,
        uint256 totalStartTimestamps,
        uint256 partedUptime,
        uint256 collectedReward
    );
    receive() external payable;
}
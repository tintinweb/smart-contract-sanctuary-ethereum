// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

import "../../interfaces/IWrappedERC20.sol";
import "./IWithdrawalManager.sol";
import "./EthStakingStrategy.sol";

contract WithdrawalManager is IWithdrawalManager, Initializable {
    event EtherReceived(address indexed from, uint256 amount, uint256 time);

    EthStakingStrategy public immutable strategy;
    IWrappedERC20 private immutable _tokenUnderlying;

    uint256 public operatorID;

    constructor(address payable strategy_) public {
        strategy = EthStakingStrategy(strategy_);
        _tokenUnderlying = IWrappedERC20(
            IFundV3(EthStakingStrategy(strategy_).fund()).tokenUnderlying()
        );
    }

    function initialize(uint256 operatorID_) external initializer {
        operatorID = operatorID_;
    }

    receive() external payable {
        emit EtherReceived(msg.sender, msg.value, block.timestamp);
    }

    function getWithdrawalCredential() external view override returns (bytes32) {
        return bytes32(uint256(address(payable(this))) | (1 << 248));
    }

    function transferToStrategy(uint256 amount) external override onlyStrategy {
        (bool success, ) = address(strategy).call{value: amount}("");
        require(success);
    }

    modifier onlyStrategy() {
        require(address(strategy) == msg.sender, "Only strategy");
        _;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWrappedERC20 is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

interface IWithdrawalManager {
    function getWithdrawalCredential() external view returns (bytes32);

    function transferToStrategy(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../../utils/SafeDecimalMath.sol";
import "../../interfaces/IFundV3.sol";
import "../../interfaces/IFundForStrategyV2.sol";
import "../../interfaces/IWrappedERC20.sol";
import "../../interfaces/ITrancheIndexV2.sol";

import "./IWithdrawalManager.sol";
import "./NodeOperatorRegistry.sol";

interface IDepositContract {
    function deposit(
        bytes memory pubkey,
        bytes memory withdrawal_credentials,
        bytes memory signature,
        bytes32 deposit_data_root
    ) external payable;
}

/// @notice Strategy for delegating ETH to ETH2 validators and earn rewards.
contract EthStakingStrategy is Ownable, ITrancheIndexV2 {
    using Math for uint256;
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    using SafeERC20 for IWrappedERC20;

    event ReporterUpdated(address reporter);
    event Received(address from, uint256 amount);
    event FeeRateUpdated(uint256 newTotalFeeRate, uint256 newOperatorFeeRate);
    event OperatorWeightUpdated(uint256 indexed id, uint256 newWeight);
    event BalanceReported(
        uint256 indexed epoch,
        uint256 indexed id,
        uint256 beaconBalance,
        uint256 validatorCount,
        uint256 executionLayerRewards
    );

    uint256 private constant MAX_TOTAL_FEE_RATE = 0.5e18;
    uint256 private constant MAX_OPERATOR_WEIGHT = 1e18;
    uint256 private constant DEPOSIT_AMOUNT = 32 ether;
    uint256 private constant MAX_AUTO_DEPOSIT_COUNT = 100;

    /// @dev Little endian representation of the deposit amount in Gwei.
    bytes32 private constant LITTLE_ENDIAN_DEPOSIT_AMOUNT =
        bytes32(
            uint256(
                ((((32e9 >> (8 * 0)) & 0xFF) << (8 * 7)) |
                    (((32e9 >> (8 * 1)) & 0xFF) << (8 * 6)) |
                    (((32e9 >> (8 * 2)) & 0xFF) << (8 * 5)) |
                    (((32e9 >> (8 * 3)) & 0xFF) << (8 * 4)) |
                    (((32e9 >> (8 * 4)) & 0xFF) << (8 * 3)) |
                    (((32e9 >> (8 * 5)) & 0xFF) << (8 * 2)) |
                    (((32e9 >> (8 * 6)) & 0xFF) << (8 * 1)) |
                    (((32e9 >> (8 * 7)) & 0xFF) << (8 * 0))) << 192
            )
        );

    address public immutable fund;
    address private immutable _tokenUnderlying;
    IDepositContract public immutable depositContract;
    NodeOperatorRegistry public immutable registry;

    /// @notice Fraction of profit that goes to the fund's fee collector and node operators.
    uint256 public totalFeeRate;

    /// @notice Fraction of profit that directly goes to node operators.
    uint256 public operatorFeeRate;

    /// @notice Mapping of node operator ID => amount of underlying lost since the last peak.
    ///         Performance fee is charged only when this value is zero.
    mapping(uint256 => uint256) public currentDrawdowns;

    mapping(uint256 => uint256) public operatorWeights;

    /// @notice Reporter that reports validator balances on the Beacon Chain
    address public reporter;

    uint256 public totalValidatorCount;
    uint256 public operatorCursor;
    mapping(uint256 => uint256) public lastBeaconBalances;
    mapping(uint256 => uint256) public lastValidatorCounts;

    constructor(
        address fund_,
        address depositContract_,
        address registry_,
        uint256 totalFeeRate_,
        uint256 operatorFeeRate_
    ) public {
        fund = fund_;
        _tokenUnderlying = IFundV3(fund_).tokenUnderlying();
        depositContract = IDepositContract(depositContract_);
        registry = NodeOperatorRegistry(registry_);
        _updateFeeRate(totalFeeRate_, operatorFeeRate_);
    }

    receive() external payable {}

    modifier onlyReporter() {
        require(reporter == msg.sender, "Only reporter");
        _;
    }

    function updateReporter(address reporter_) public onlyOwner {
        reporter = reporter_;
        emit ReporterUpdated(reporter);
    }

    /// @notice Report profit to the fund for an individual node operator.
    function report(
        uint256 epoch,
        uint256 id,
        uint256 beaconBalance,
        uint256 validatorCount
    ) external onlyReporter {
        (uint256 profit, uint256 loss, uint256 totalFee, uint256 operatorFee) =
            _report(epoch, id, beaconBalance, validatorCount);
        if (profit != 0) {
            uint256 feeQ = IFundForStrategyV2(fund).reportProfit(profit, totalFee, operatorFee);
            IFundV3(fund).trancheTransfer(
                TRANCHE_Q,
                registry.getRewardAddress(id),
                feeQ,
                IFundV3(fund).getRebalanceSize()
            );
        }
        if (loss != 0) {
            IFundForStrategyV2(fund).reportLoss(loss);
        }
    }

    /// @notice Report profit to the fund for multiple node operators.
    function batchReport(
        uint256 epoch,
        uint256[] memory ids,
        uint256[] memory beaconBalances,
        uint256[] memory validatorCounts
    ) external onlyReporter {
        uint256 size = ids.length;
        require(
            beaconBalances.length == size && validatorCounts.length == size,
            "Unaligned params"
        );
        uint256 sumProfit;
        uint256 sumLoss;
        uint256 sumTotalFee;
        uint256 sumOperatorFee;
        uint256[] memory operatorFees = new uint256[](size);
        for (uint256 i = 0; i < size; i++) {
            require(i == 0 || ids[i] > ids[i - 1], "IDs out of order");
            (uint256 profit, uint256 loss, uint256 totalFee, uint256 operatorFee) =
                _report(epoch, ids[i], beaconBalances[i], validatorCounts[i]);
            sumProfit = sumProfit.add(profit);
            sumLoss = sumLoss.add(loss);
            sumTotalFee = sumTotalFee.add(totalFee);
            sumOperatorFee = sumOperatorFee.add(operatorFee);
            operatorFees[i] = operatorFee;
        }
        if (sumLoss != 0) {
            IFundForStrategyV2(fund).reportLoss(sumLoss);
        }
        if (sumProfit != 0) {
            uint256 totalFeeQ =
                IFundForStrategyV2(fund).reportProfit(sumProfit, sumTotalFee, sumOperatorFee);
            if (sumOperatorFee != 0) {
                uint256 version = IFundV3(fund).getRebalanceSize();
                for (uint256 i = 0; i < size; i++) {
                    if (operatorFees[i] == 0) {
                        continue;
                    }
                    address rewardAddress = registry.getRewardAddress(ids[i]);
                    IFundV3(fund).trancheTransfer(
                        TRANCHE_Q,
                        rewardAddress,
                        totalFeeQ.mul(operatorFees[i]) / sumOperatorFee,
                        version
                    );
                }
            }
        }
    }

    function _report(
        uint256 epoch,
        uint256 id,
        uint256 beaconBalance,
        uint256 validatorCount
    )
        private
        returns (
            uint256 profit,
            uint256 loss,
            uint256 totalFee,
            uint256 operatorFee
        )
    {
        address withdrawalAddress = registry.getWithdrawalAddress(id);
        require(withdrawalAddress != address(0), "Invalid operator id");
        uint256 lastValidatorCount = lastValidatorCounts[id];
        require(validatorCount <= registry.getKeyStat(id).usedCount, "More than deposited");
        require(validatorCount >= lastValidatorCount, "Less than previous");

        uint256 oldBalance =
            (validatorCount - lastValidatorCount).mul(DEPOSIT_AMOUNT).add(lastBeaconBalances[id]);
        lastBeaconBalances[id] = beaconBalance;
        lastValidatorCounts[id] = validatorCount;

        // Get the exectuion layer rewards
        uint256 executionLayerRewards = withdrawalAddress.balance;
        if (executionLayerRewards != 0) {
            IWithdrawalManager(withdrawalAddress).transferToStrategy(executionLayerRewards);
        }
        emit BalanceReported(epoch, id, beaconBalance, validatorCount, executionLayerRewards);
        uint256 newBalance = beaconBalance.add(executionLayerRewards);

        // Update drawdown and calculate fees
        uint256 oldDrawdown = currentDrawdowns[id];
        if (newBalance >= oldBalance) {
            profit = newBalance - oldBalance;
            if (profit <= oldDrawdown) {
                currentDrawdowns[id] = oldDrawdown - profit;
            } else {
                if (oldDrawdown > 0) {
                    currentDrawdowns[id] = 0;
                }
                totalFee = (profit - oldDrawdown).multiplyDecimal(totalFeeRate);
                operatorFee = (profit - oldDrawdown).multiplyDecimal(operatorFeeRate);
            }
        } else {
            loss = oldBalance - newBalance;
            currentDrawdowns[id] = oldDrawdown.add(loss);
        }
    }

    function updateFeeRate(uint256 newTotalFeeRate, uint256 newOperatorFeeRate) external onlyOwner {
        _updateFeeRate(newTotalFeeRate, newOperatorFeeRate);
    }

    function _updateFeeRate(uint256 newTotalFeeRate, uint256 newOperatorFeeRate) private {
        require(newTotalFeeRate <= MAX_TOTAL_FEE_RATE && newTotalFeeRate >= newOperatorFeeRate);
        totalFeeRate = newTotalFeeRate;
        operatorFeeRate = newOperatorFeeRate;
        emit FeeRateUpdated(newTotalFeeRate, newOperatorFeeRate);
    }

    function updateOperatorWeight(uint256 id, uint256 newWeight) external onlyOwner {
        require(newWeight <= MAX_OPERATOR_WEIGHT, "Max weight exceeded");
        require(id < registry.operatorCount(), "Invalid operator ID");
        operatorWeights[id] = newWeight;
        emit OperatorWeightUpdated(id, newWeight);
    }

    /// @notice Select node operators for the given number of new validators. Sum of the returned
    ///         key counts may be less than the parameter.
    /// @param total Number of new validators
    /// @return keyCounts Number of pubkeys to be used from each node operator
    /// @return cursor New cursor of the selection algorithm
    function selectOperators(uint256 total)
        public
        view
        returns (uint256[] memory keyCounts, uint256 cursor)
    {
        uint256 operatorCount = registry.operatorCount();
        keyCounts = new uint256[](operatorCount);
        uint256[] memory limits = new uint256[](operatorCount);
        uint256 totalWeights;
        for (uint256 i = 0; i < operatorCount; i++) {
            uint256 w = operatorWeights[i];
            limits[i] = w;
            totalWeights = totalWeights + w;
        }
        if (totalWeights == 0) {
            return (keyCounts, operatorCursor);
        }
        uint256 newValidatorCount = totalValidatorCount + total;
        for (uint256 i = 0; i < operatorCount; i++) {
            // Round up the limit
            uint256 totalLimit = (limits[i] * newValidatorCount + totalWeights - 1) / totalWeights;
            NodeOperatorRegistry.KeyStat memory stat = registry.getKeyStat(i);
            totalLimit = totalLimit.min(stat.totalCount).min(stat.depositLimit).min(
                stat.verifiedCount
            );
            limits[i] = totalLimit <= stat.usedCount ? 0 : totalLimit - stat.usedCount;
        }

        cursor = operatorCursor;
        uint256 failure = 0;
        while (total > 0 && failure < operatorCount) {
            if (limits[cursor] == 0) {
                failure++;
            } else {
                keyCounts[cursor]++;
                limits[cursor]--;
                total--;
                failure = 0;
            }
            cursor = (cursor + 1) % operatorCount;
        }
    }

    /// @notice Deposit underlying tokens from the fund to the ETH2 deposit contract.
    /// @param amount Amount of underlying transfered from the fund, including cross-chain relay fee
    function deposit(uint256 amount) public {
        require(amount % DEPOSIT_AMOUNT == 0);
        if (address(this).balance < amount) {
            IFundForStrategyV2(fund).transferToStrategy(amount - address(this).balance);
            _unwrap(IERC20(_tokenUnderlying).balanceOf(address(this)));
        }

        uint256[] memory keyCounts;
        (keyCounts, operatorCursor) = selectOperators(amount / DEPOSIT_AMOUNT);
        uint256 total;
        for (uint256 i = 0; i < keyCounts.length; i++) {
            uint256 keyCount = keyCounts[i];
            if (keyCount == 0) {
                continue;
            }
            total += keyCount;
            (NodeOperatorRegistry.Key[] memory vs, bytes32 withdrawalCredential) =
                registry.useKeys(i, keyCount);
            for (uint256 j = 0; j < keyCount; j++) {
                _deposit(vs[j], withdrawalCredential);
            }
        }
        totalValidatorCount = totalValidatorCount + total;
    }

    function onPrimaryMarketCreate() external {
        uint256 balance = IERC20(_tokenUnderlying).balanceOf(fund) + address(this).balance;
        uint256 count = balance / DEPOSIT_AMOUNT;
        if (count > 0) {
            deposit(count.min(MAX_AUTO_DEPOSIT_COUNT) * DEPOSIT_AMOUNT);
        }
    }

    /// @notice Transfer all underlying tokens, both wrapped and unwrapped, to the fund.
    function transferToFund() external onlyOwner {
        uint256 unwrapped = address(this).balance;
        if (unwrapped > 0) {
            _wrap(unwrapped);
        }
        uint256 amount = IWrappedERC20(_tokenUnderlying).balanceOf(address(this));
        IWrappedERC20(_tokenUnderlying).safeApprove(fund, amount);
        IFundForStrategyV2(fund).transferFromStrategy(amount);
    }

    /// @dev Convert ETH into WETH
    function _wrap(uint256 amount) private {
        IWrappedERC20(_tokenUnderlying).deposit{value: amount}();
    }

    /// @dev Convert WETH into ETH
    function _unwrap(uint256 amount) private {
        IWrappedERC20(_tokenUnderlying).withdraw(amount);
    }

    function _deposit(NodeOperatorRegistry.Key memory key, bytes32 withdrawalCredential) private {
        bytes memory pubkey = abi.encodePacked(key.pubkey0, bytes16(key.pubkey1));
        bytes memory signature = abi.encode(key.signature0, key.signature1, key.signature2);
        // Lower 16 bytes of pubkey1 are cleared by the registry
        bytes32 pubkeyRoot = sha256(abi.encode(key.pubkey0, key.pubkey1));
        bytes32 signatureRoot =
            sha256(
                abi.encodePacked(
                    sha256(abi.encode(key.signature0, key.signature1)),
                    sha256(abi.encode(key.signature2, bytes32(0)))
                )
            );
        bytes32 depositDataRoot =
            sha256(
                abi.encodePacked(
                    sha256(abi.encodePacked(pubkeyRoot, withdrawalCredential)),
                    sha256(abi.encodePacked(LITTLE_ENDIAN_DEPOSIT_AMOUNT, signatureRoot))
                )
            );
        depositContract.deposit{value: DEPOSIT_AMOUNT}(
            pubkey,
            abi.encode(withdrawalCredential),
            signature,
            depositDataRoot
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

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
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
//
// Copyright (c) 2019 Synthetix
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

library SafeDecimalMath {
    using SafeMath for uint256;

    /* Number of decimal places in the representations. */
    uint256 private constant decimals = 18;
    uint256 private constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint256 private constant UNIT = 10**uint256(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint256 private constant PRECISE_UNIT = 10**uint256(highPrecisionDecimals);
    uint256 private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR =
        10**uint256(highPrecisionDecimals - decimals);

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y).div(UNIT);
    }

    function multiplyDecimalPrecise(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y).div(PRECISE_UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    function divideDecimalPrecise(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(PRECISE_UNIT).div(y);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint256 i) internal pure returns (uint256) {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint256 i) internal pure returns (uint256) {
        uint256 quotientTimesTen = i.mul(10).div(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen = quotientTimesTen.add(10);
        }

        return quotientTimesTen.div(10);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, and the max value of
     * uint256 on overflow.
     */
    function saturatingMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        return c / a != b ? type(uint256).max : c;
    }

    function saturatingMultiplyDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return saturatingMul(x, y).div(UNIT);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "./ITwapOracleV2.sol";

interface IFundV3 {
    /// @notice A linear transformation matrix that represents a rebalance.
    ///
    ///         ```
    ///             [        1        0        0 ]
    ///         R = [ ratioB2Q  ratioBR        0 ]
    ///             [ ratioR2Q        0  ratioBR ]
    ///         ```
    ///
    ///         Amounts of the three tranches `q`, `b` and `r` can be rebalanced by multiplying the matrix:
    ///
    ///         ```
    ///         [ q', b', r' ] = [ q, b, r ] * R
    ///         ```
    struct Rebalance {
        uint256 ratioB2Q;
        uint256 ratioR2Q;
        uint256 ratioBR;
        uint256 timestamp;
    }

    function tokenUnderlying() external view returns (address);

    function tokenQ() external view returns (address);

    function tokenB() external view returns (address);

    function tokenR() external view returns (address);

    function tokenShare(uint256 tranche) external view returns (address);

    function primaryMarket() external view returns (address);

    function primaryMarketUpdateProposal() external view returns (address, uint256);

    function strategy() external view returns (address);

    function strategyUpdateProposal() external view returns (address, uint256);

    function underlyingDecimalMultiplier() external view returns (uint256);

    function twapOracle() external view returns (ITwapOracleV2);

    function feeCollector() external view returns (address);

    function endOfDay(uint256 timestamp) external pure returns (uint256);

    function trancheTotalSupply(uint256 tranche) external view returns (uint256);

    function trancheBalanceOf(uint256 tranche, address account) external view returns (uint256);

    function trancheAllBalanceOf(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function trancheBalanceVersion(address account) external view returns (uint256);

    function trancheAllowance(
        uint256 tranche,
        address owner,
        address spender
    ) external view returns (uint256);

    function trancheAllowanceVersion(address owner, address spender)
        external
        view
        returns (uint256);

    function trancheTransfer(
        uint256 tranche,
        address recipient,
        uint256 amount,
        uint256 version
    ) external;

    function trancheTransferFrom(
        uint256 tranche,
        address sender,
        address recipient,
        uint256 amount,
        uint256 version
    ) external;

    function trancheApprove(
        uint256 tranche,
        address spender,
        uint256 amount,
        uint256 version
    ) external;

    function getRebalanceSize() external view returns (uint256);

    function getRebalance(uint256 index) external view returns (Rebalance memory);

    function getRebalanceTimestamp(uint256 index) external view returns (uint256);

    function currentDay() external view returns (uint256);

    function splitRatio() external view returns (uint256);

    function historicalSplitRatio(uint256 version) external view returns (uint256);

    function fundActivityStartTime() external view returns (uint256);

    function isFundActive(uint256 timestamp) external view returns (bool);

    function getEquivalentTotalB() external view returns (uint256);

    function getEquivalentTotalQ() external view returns (uint256);

    function historicalEquivalentTotalB(uint256 timestamp) external view returns (uint256);

    function historicalNavs(uint256 timestamp) external view returns (uint256 navB, uint256 navR);

    function extrapolateNav(uint256 price)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function doRebalance(
        uint256 amountQ,
        uint256 amountB,
        uint256 amountR,
        uint256 index
    )
        external
        view
        returns (
            uint256 newAmountQ,
            uint256 newAmountB,
            uint256 newAmountR
        );

    function batchRebalance(
        uint256 amountQ,
        uint256 amountB,
        uint256 amountR,
        uint256 fromIndex,
        uint256 toIndex
    )
        external
        view
        returns (
            uint256 newAmountQ,
            uint256 newAmountB,
            uint256 newAmountR
        );

    function refreshBalance(address account, uint256 targetVersion) external;

    function refreshAllowance(
        address owner,
        address spender,
        uint256 targetVersion
    ) external;

    function shareTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function shareTransferFrom(
        address spender,
        address sender,
        address recipient,
        uint256 amount
    ) external returns (uint256 newAllowance);

    function shareIncreaseAllowance(
        address sender,
        address spender,
        uint256 addedValue
    ) external returns (uint256 newAllowance);

    function shareDecreaseAllowance(
        address sender,
        address spender,
        uint256 subtractedValue
    ) external returns (uint256 newAllowance);

    function shareApprove(
        address owner,
        address spender,
        uint256 amount
    ) external;

    function historicalUnderlying(uint256 timestamp) external view returns (uint256);

    function getTotalUnderlying() external view returns (uint256);

    function getStrategyUnderlying() external view returns (uint256);

    function getTotalDebt() external view returns (uint256);

    event RebalanceTriggered(
        uint256 indexed index,
        uint256 indexed day,
        uint256 navSum,
        uint256 navB,
        uint256 navROrZero,
        uint256 ratioB2Q,
        uint256 ratioR2Q,
        uint256 ratioBR
    );
    event Settled(uint256 indexed day, uint256 navB, uint256 navR, uint256 interestRate);
    event InterestRateUpdated(uint256 baseInterestRate, uint256 floatingInterestRate);
    event BalancesRebalanced(
        address indexed account,
        uint256 version,
        uint256 balanceQ,
        uint256 balanceB,
        uint256 balanceR
    );
    event AllowancesRebalanced(
        address indexed owner,
        address indexed spender,
        uint256 version,
        uint256 allowanceQ,
        uint256 allowanceB,
        uint256 allowanceR
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

interface IFundForStrategyV2 {
    function transferToStrategy(uint256 amount) external;

    function transferFromStrategy(uint256 amount) external;

    function reportProfit(
        uint256 profit,
        uint256 totalFee,
        uint256 strategyFee
    ) external returns (uint256 outQ);

    function reportLoss(uint256 loss) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

/// @notice Amounts of QUEEN, BISHOP and ROOK are sometimes stored in a `uint256[3]` array.
///         This contract defines index of each tranche in this array.
///
///         Solidity does not allow constants to be defined in interfaces. So this contract follows
///         the naming convention of interfaces but is implemented as an `abstract contract`.
abstract contract ITrancheIndexV2 {
    uint256 internal constant TRANCHE_Q = 0;
    uint256 internal constant TRANCHE_B = 1;
    uint256 internal constant TRANCHE_R = 2;

    uint256 internal constant TRANCHE_COUNT = 3;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./IWithdrawalManager.sol";
import "./WithdrawalManagerFactory.sol";

contract NodeOperatorRegistry is Ownable {
    event OperatorAdded(uint256 indexed id, string name, address operatorOwner);
    event OperatorOwnerUpdated(uint256 indexed id, address newOperatorOwner);
    event RewardAddressUpdated(uint256 indexed id, address newRewardAddress);
    event VerifiedCountUpdated(uint256 indexed id, uint256 newVerifiedCount);
    event DepositLimitUpdated(uint256 indexed id, uint256 newDepositLimit);
    event KeyAdded(uint256 indexed id, bytes pubkey, uint256 index);
    event KeyUsed(uint256 indexed id, uint256 count);
    event KeyTruncated(uint256 indexed id, uint256 newTotalCount);
    event StrategyUpdated(address newStrategy);

    /// @notice Statistics of validator pubkeys from a node operator.
    /// @param totalCount Total number of validator pubkeys uploaded to this contract
    /// @param usedCount Number of validator pubkeys that are already used
    /// @param verifiedCount Number of validator pubkeys that are verified by the contract owner
    /// @param depositLimit Maximum number of usable validator pubkeys, set by the node operator
    struct KeyStat {
        uint64 totalCount;
        uint64 usedCount;
        uint64 verifiedCount;
        uint64 depositLimit;
    }

    /// @notice Node operator parameters and internal state
    /// @param operatorOwner Admin address of the node operator
    /// @param name Human-readable name
    /// @param withdrawalAddress Address receiving withdrawals and execution layer rewards
    /// @param rewardAddress Address receiving performance rewards
    struct Operator {
        address operatorOwner;
        string name;
        address rewardAddress;
        address withdrawalAddress;
        KeyStat keyStat;
    }

    struct Key {
        bytes32 pubkey0;
        bytes32 pubkey1; // Only the higher 16 bytes of the second slot are used
        bytes32 signature0;
        bytes32 signature1;
        bytes32 signature2;
    }

    uint256 private constant PUBKEY_LENGTH = 48;
    uint256 private constant SIGNATURE_LENGTH = 96;

    WithdrawalManagerFactory public immutable factory;

    address public strategy;

    /// @notice Number of node operators.
    uint256 public operatorCount;

    /// @dev Mapping of node operator ID => node operator.
    mapping(uint256 => Operator) private _operators;

    /// @dev Mapping of node operator ID => index => validator pubkey and deposit signature.
    mapping(uint256 => mapping(uint256 => Key)) private _keys;

    constructor(address strategy_, address withdrawalManagerFactory_) public {
        _updateStrategy(strategy_);
        factory = WithdrawalManagerFactory(withdrawalManagerFactory_);
    }

    function getOperator(uint256 id) external view returns (Operator memory) {
        return _operators[id];
    }

    function getOperators() external view returns (Operator[] memory operators) {
        uint256 count = operatorCount;
        operators = new Operator[](count);
        for (uint256 i = 0; i < count; i++) {
            operators[i] = _operators[i];
        }
    }

    function getRewardAddress(uint256 id) external view returns (address) {
        return _operators[id].rewardAddress;
    }

    function getRewardAddresses() external view returns (address[] memory addresses) {
        uint256 count = operatorCount;
        addresses = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            addresses[i] = _operators[i].rewardAddress;
        }
    }

    function getWithdrawalAddress(uint256 id) external view returns (address) {
        return _operators[id].withdrawalAddress;
    }

    function getWithdrawalAddresses() external view returns (address[] memory addresses) {
        uint256 count = operatorCount;
        addresses = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            addresses[i] = _operators[i].withdrawalAddress;
        }
    }

    function getWithdrawalCredential(uint256 id) external view returns (bytes32) {
        return IWithdrawalManager(_operators[id].withdrawalAddress).getWithdrawalCredential();
    }

    function getKeyStat(uint256 id) external view returns (KeyStat memory) {
        return _operators[id].keyStat;
    }

    function getKeyStats() external view returns (KeyStat[] memory keyStats) {
        uint256 count = operatorCount;
        keyStats = new KeyStat[](count);
        for (uint256 i = 0; i < count; i++) {
            keyStats[i] = _operators[i].keyStat;
        }
    }

    function getKey(uint256 id, uint256 index) external view returns (Key memory) {
        return _keys[id][index];
    }

    function getKeys(
        uint256 id,
        uint256 start,
        uint256 count
    ) external view returns (Key[] memory keys) {
        keys = new Key[](count);
        mapping(uint256 => Key) storage operatorKeys = _keys[id];
        for (uint256 i = 0; i < count; i++) {
            keys[i] = operatorKeys[start + i];
        }
    }

    function getPubkeys(
        uint256 id,
        uint256 start,
        uint256 count
    ) external view returns (bytes[] memory pubkeys) {
        pubkeys = new bytes[](count);
        mapping(uint256 => Key) storage operatorKeys = _keys[id];
        for (uint256 i = 0; i < count; i++) {
            Key storage key = operatorKeys[start + i];
            pubkeys[i] = abi.encodePacked(key.pubkey0, bytes16(key.pubkey1));
        }
    }

    function getSignatures(
        uint256 id,
        uint256 start,
        uint256 count
    ) external view returns (bytes[] memory signatures) {
        signatures = new bytes[](count);
        mapping(uint256 => Key) storage operatorKeys = _keys[id];
        for (uint256 i = 0; i < count; i++) {
            Key storage key = operatorKeys[start + i];
            signatures[i] = abi.encode(key.signature0, key.signature1, key.signature2);
        }
    }

    function addKeys(
        uint256 id,
        bytes calldata pubkeys,
        bytes calldata signatures
    ) external onlyOperatorOwner(id) {
        uint256 count = pubkeys.length / PUBKEY_LENGTH;
        require(
            pubkeys.length == count * PUBKEY_LENGTH &&
                signatures.length == count * SIGNATURE_LENGTH,
            "Invalid param length"
        );
        mapping(uint256 => Key) storage operatorKeys = _keys[id];
        Operator storage operator = _operators[id];
        KeyStat memory stat = operator.keyStat;
        for (uint256 i = 0; i < count; ++i) {
            Key memory key;
            key.pubkey0 = abi.decode(pubkeys[i * PUBKEY_LENGTH:i * PUBKEY_LENGTH + 32], (bytes32));
            key.pubkey1 = abi.decode(
                pubkeys[i * PUBKEY_LENGTH + 16:i * PUBKEY_LENGTH + 48],
                (bytes32)
            );
            key.pubkey1 = bytes32(uint256(key.pubkey1) << 128);
            (key.signature0, key.signature1, key.signature2) = abi.decode(
                signatures[i * SIGNATURE_LENGTH:(i + 1) * SIGNATURE_LENGTH],
                (bytes32, bytes32, bytes32)
            );
            require(
                key.pubkey0 | key.pubkey1 != 0 &&
                    key.signature0 | key.signature1 | key.signature2 != 0,
                "Empty pubkey or signature"
            );
            operatorKeys[stat.totalCount + i] = key;
            emit KeyAdded(
                id,
                abi.encodePacked(key.pubkey0, bytes16(key.pubkey1)),
                stat.totalCount + i
            );
        }
        stat.totalCount += uint64(count);
        operator.keyStat = stat;
    }

    function truncateUnusedKeys(uint256 id) external onlyOperatorOwner(id) {
        _truncateUnusedKeys(id);
    }

    function updateRewardAddress(uint256 id, address newRewardAddress)
        external
        onlyOperatorOwner(id)
    {
        _operators[id].rewardAddress = newRewardAddress;
        emit RewardAddressUpdated(id, newRewardAddress);
    }

    function updateDepositLimit(uint256 id, uint64 newDepositLimit) external onlyOperatorOwner(id) {
        _operators[id].keyStat.depositLimit = newDepositLimit;
        emit DepositLimitUpdated(id, newDepositLimit);
    }

    function useKeys(uint256 id, uint256 count)
        external
        onlyStrategy
        returns (Key[] memory keys, bytes32 withdrawalCredential)
    {
        Operator storage operator = _operators[id];
        KeyStat memory stat = operator.keyStat;
        mapping(uint256 => Key) storage operatorKeys = _keys[id];
        uint256 usedCount = stat.usedCount;
        uint256 newUsedCount = usedCount + count;
        require(
            newUsedCount <= stat.totalCount &&
                newUsedCount <= stat.depositLimit &&
                newUsedCount <= stat.verifiedCount,
            "No enough pubkeys"
        );
        keys = new Key[](count);
        for (uint256 i = 0; i < count; i++) {
            Key storage k = operatorKeys[usedCount + i];
            keys[i] = k;
            // Clear storage for gas refund
            k.signature0 = 0;
            k.signature1 = 0;
            k.signature2 = 0;
        }
        stat.usedCount = uint64(newUsedCount);
        operator.keyStat = stat;
        withdrawalCredential = IWithdrawalManager(operator.withdrawalAddress)
            .getWithdrawalCredential();
        emit KeyUsed(id, count);
    }

    function addOperator(string calldata name, address operatorOwner)
        external
        onlyOwner
        returns (uint256 id, address withdrawalAddress)
    {
        id = operatorCount++;
        withdrawalAddress = factory.deployContract(id);
        Operator storage operator = _operators[id];
        operator.operatorOwner = operatorOwner;
        operator.name = name;
        operator.withdrawalAddress = withdrawalAddress;
        operator.rewardAddress = operatorOwner;
        emit OperatorAdded(id, name, operatorOwner);
    }

    function updateOperatorOwner(uint256 id, address newOperatorOwner) external onlyOwner {
        require(id < operatorCount, "Invalid operator ID");
        _operators[id].operatorOwner = newOperatorOwner;
        emit OperatorOwnerUpdated(id, newOperatorOwner);
    }

    function updateVerifiedCount(uint256 id, uint64 newVerifiedCount) external onlyOwner {
        _operators[id].keyStat.verifiedCount = newVerifiedCount;
        emit VerifiedCountUpdated(id, newVerifiedCount);
    }

    function truncateAllUnusedKeys() external onlyOwner {
        uint256 count = operatorCount;
        for (uint256 i = 0; i < count; i++) {
            _truncateUnusedKeys(i);
        }
    }

    function _truncateUnusedKeys(uint256 id) private {
        Operator storage operator = _operators[id];
        KeyStat memory stat = operator.keyStat;
        stat.totalCount = stat.usedCount;
        stat.verifiedCount = stat.usedCount;
        operator.keyStat = stat;
        emit KeyTruncated(id, stat.totalCount);
    }

    function updateStrategy(address newStrategy) external onlyOwner {
        _updateStrategy(newStrategy);
    }

    function _updateStrategy(address newStrategy) private {
        strategy = newStrategy;
        emit StrategyUpdated(newStrategy);
    }

    modifier onlyOperatorOwner(uint256 id) {
        require(msg.sender == _operators[id].operatorOwner, "Only operator owner");
        _;
    }

    modifier onlyStrategy() {
        require(msg.sender == strategy, "Only strategy");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "./ITwapOracle.sol";

interface ITwapOracleV2 is ITwapOracle {
    function getLatest() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

interface ITwapOracle {
    enum UpdateType {PRIMARY, SECONDARY, OWNER, CHAINLINK, UNISWAP_V2}

    function getTwap(uint256 timestamp) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./WithdrawalManagerProxy.sol";

contract WithdrawalManagerFactory is Ownable {
    event ImplementationUpdated(address indexed newImplementation);

    address public implementation;

    constructor(address implementation_) public {
        _updateImplementation(implementation_);
    }

    function deployContract(uint256 id) external returns (address) {
        WithdrawalManagerProxy proxy = new WithdrawalManagerProxy(this, id);
        return address(proxy);
    }

    function updateImplementation(address newImplementation) external onlyOwner {
        _updateImplementation(newImplementation);
    }

    function _updateImplementation(address newImplementation) private {
        implementation = newImplementation;
        emit ImplementationUpdated(newImplementation);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.10 <0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";

import "./WithdrawalManagerFactory.sol";

// An individual withdraw maanger for a node operator

contract WithdrawalManagerProxy is Proxy {
    using Address for address;

    WithdrawalManagerFactory internal immutable withdrawalManagerFactory;

    constructor(WithdrawalManagerFactory withdrawalManagerFactory_, uint256 operatorID_) public {
        // Initialize withdrawalManagerFactory
        require(address(withdrawalManagerFactory_) != address(0x0), "Invalid factory address");
        withdrawalManagerFactory = withdrawalManagerFactory_;
        // Check for contract existence
        address implAddress = withdrawalManagerFactory_.implementation();
        require(implAddress.isContract(), "Delegate contract does not exist");
        // Call Initialize on delegate
        (bool success, ) =
            implAddress.delegatecall(abi.encodeWithSignature("initialize(uint256)", operatorID_));
        if (!success) {
            revert("Failed delegatecall");
        }
    }

    function _implementation() internal view override returns (address) {
        return withdrawalManagerFactory.implementation();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}
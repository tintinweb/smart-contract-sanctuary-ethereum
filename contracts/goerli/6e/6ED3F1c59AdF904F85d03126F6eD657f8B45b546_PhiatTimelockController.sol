// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../../dependencies/openzeppelin/contracts/SafeMath.sol";

import "../../interfaces/ILendingPool.sol";
import "../../interfaces/ILendingPoolAddressesProvider.sol";
import "../../interfaces/ILendingPoolConfigurator.sol";
import "../../interfaces/IMarketLiquidityOracle.sol";
import "../../interfaces/IPhiatTimelockController.sol";

import "../libraries/types/DataTypes.sol";

contract PhiatTimelockController is IPhiatTimelockController {
    using SafeMath for uint256;

    uint256 public constant MIN_DELAY = 1 days;
    uint256 internal constant _DONE_TIMESTAMP = uint256(1);

    address public admin;
    mapping(bytes32 => uint256) private _timestamps;

    ILendingPoolAddressesProvider public addressesProvider;
    IMarketLiquidityOracle public liquidityOracle;

    /**
     * @dev Emitted when a call is scheduled as part of operation `id`.
     */
    event CallScheduled(
        bytes32 indexed id,
        uint256 indexed index,
        address target,
        uint256 value,
        bytes data,
        bytes32 predecessor,
        uint256 delay
    );

    /**
     * @dev Emitted when a call is performed as part of operation `id`.
     */
    event CallExecuted(
        bytes32 indexed id,
        uint256 indexed index,
        address target,
        uint256 value,
        bytes data
    );

    /**
     * @dev Emitted when operation `id` is cancelled.
     */
    event Cancelled(bytes32 indexed id);

    event AdminTransferred(
        address indexed previousAdmin,
        address indexed newAdmin
    );

    event AddressesProviderChanged(
        address indexed previousAddressesProvider,
        address indexed newAddressesProvider
    );

    event MarketLiquidityOracleChanged(
        address indexed previousLiquidityOracle,
        address indexed newLiquidityOracle
    );

    /**
     * @dev Initializes the contract with given 'admin_', 'addressesProvider_' and 'liquidityOracle_'.
     */
    constructor(
        address admin_,
        ILendingPoolAddressesProvider addressesProvider_,
        IMarketLiquidityOracle liquidityOracle_
    ) {
        require(
            admin_ != address(0),
            "PhiatTimelockController: admin should not be the zero address"
        );
        require(
            address(addressesProvider_) != address(0),
            "PhiatTimelockController: addresses provider should not be the zero address"
        );
        require(
            address(liquidityOracle_) != address(0),
            "PhiatTimelockController: liquidity oracle should not be the zero address"
        );
        admin = admin_;
        addressesProvider = addressesProvider_;
        liquidityOracle = liquidityOracle_;
        emit AdminTransferred(address(0), admin);
        emit AddressesProviderChanged(address(0), address(addressesProvider_));
        emit MarketLiquidityOracleChanged(
            address(0),
            address(liquidityOracle_)
        );
    }

    /**
     * @dev Modifier to make a function callable only by this contract itself.
     */
    modifier onlySelf() {
        require(
            msg.sender == address(this),
            "PhiatTimelockController: sender is not this contract"
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only by admin.
     */
    modifier onlyAdmin() {
        require(
            msg.sender == admin,
            "PhiatTimelockController: sender is not admin"
        );
        _;
    }

    /**
     * @dev Contract might receive/hold ETH as part of the maintenance process.
     */
    receive() external payable {}

    /**
     * @dev Transfers admin of the contract to a new account (`newAdmin`).
     * Can only be called by this contract itself.
     */
    function transferAdmin(address newAdmin) external onlySelf {
        require(
            newAdmin != address(0),
            "PhiatTimelockController: admin should not be the zero address"
        );
        emit AdminTransferred(admin, newAdmin);
        admin = newAdmin;
    }

    /**
     * @dev Set addresses provider to a new address (`newAddressesProvider`).
     * Can only be called by this contract itself.
     */
    function setAddressesProvider(
        ILendingPoolAddressesProvider newAddressesProvider
    ) external onlySelf {
        require(
            address(newAddressesProvider) != address(0),
            "PhiatTimelockController: addresses provider should not be the zero address"
        );
        emit AddressesProviderChanged(
            address(addressesProvider),
            address(newAddressesProvider)
        );
        addressesProvider = newAddressesProvider;
    }

    /**
     * @dev Set liquidity oracle to a new address (`newLiquidityOracle`).
     * Can only be called by this contract itself.
     */
    function setLiquidityOracle(IMarketLiquidityOracle newLiquidityOracle)
        external
        onlySelf
    {
        require(
            address(newLiquidityOracle) != address(0),
            "PhiatTimelockController: liquidity oracle should not be the zero address"
        );
        emit MarketLiquidityOracleChanged(
            address(liquidityOracle),
            address(newLiquidityOracle)
        );
        liquidityOracle = newLiquidityOracle;
    }

    /**
     * @dev Returns whether an id correspond to a registered operation. This
     * includes both Pending, Ready and Done operations.
     */
    function isOperation(bytes32 id)
        public
        view
        virtual
        returns (bool pending)
    {
        return getTimestamp(id) > 0;
    }

    /**
     * @dev Returns whether an operation is pending or not.
     */
    function isOperationPending(bytes32 id)
        public
        view
        virtual
        returns (bool pending)
    {
        return getTimestamp(id) > _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns whether an operation is ready or not.
     */
    function isOperationReady(bytes32 id)
        public
        view
        virtual
        returns (bool ready)
    {
        uint256 timestamp = getTimestamp(id);
        // solhint-disable-next-line not-rely-on-time
        return timestamp > _DONE_TIMESTAMP && timestamp <= block.timestamp;
    }

    /**
     * @dev Returns whether an operation is done or not.
     */
    function isOperationDone(bytes32 id)
        public
        view
        virtual
        returns (bool done)
    {
        return getTimestamp(id) == _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns the timestamp at with an operation becomes ready (0 for
     * unset operations, 1 for done operations).
     */
    function getTimestamp(bytes32 id)
        public
        view
        virtual
        returns (uint256 timestamp)
    {
        return _timestamps[id];
    }

    /**
     * @dev Returns the identifier of an operation containing a single
     * transaction.
     */
    function hashOperation(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(target, value, data, predecessor, salt));
    }

    /**
     * @dev Returns the identifier of an operation containing a batch of
     * transactions.
     */
    function hashOperationBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(targets, values, datas, predecessor, salt));
    }

    /**
     * @dev Schedule an operation containing a single transaction.
     *
     * Emits a {CallScheduled} event.
     *
     * Requirements:
     *
     * - the caller must have the 'admin' role.
     */
    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyAdmin {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _schedule(id, delay);
        emit CallScheduled(id, 0, target, value, data, predecessor, delay);
    }

    /**
     * @dev Schedule an operation containing a batch of transactions.
     *
     * Emits one {CallScheduled} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'admin' role.
     */
    function scheduleBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyAdmin {
        require(
            targets.length == values.length,
            "PhiatTimelockController: length mismatch"
        );
        require(
            targets.length == datas.length,
            "PhiatTimelockController: length mismatch"
        );

        bytes32 id = hashOperationBatch(
            targets,
            values,
            datas,
            predecessor,
            salt
        );
        _schedule(id, delay);
        for (uint256 i = 0; i < targets.length; ++i) {
            emit CallScheduled(
                id,
                i,
                targets[i],
                values[i],
                datas[i],
                predecessor,
                delay
            );
        }
    }

    /**
     * @dev Schedule an operation that is to becomes valid after a given delay.
     */
    function _schedule(bytes32 id, uint256 delay) private {
        require(
            !isOperation(id),
            "PhiatTimelockController: operation already scheduled"
        );
        require(
            delay >= MIN_DELAY,
            "PhiatTimelockController: insufficient delay"
        );
        // solhint-disable-next-line not-rely-on-time
        _timestamps[id] = SafeMath.add(block.timestamp, delay);
    }

    /**
     * @dev Cancel an operation.
     *
     * Requirements:
     *
     * - the caller must have the 'admin' role.
     */
    function cancel(bytes32 id) public virtual onlyAdmin {
        require(
            isOperationPending(id),
            "PhiatTimelockController: operation cannot be cancelled"
        );
        delete _timestamps[id];

        emit Cancelled(id);
    }

    /**
     * @dev Execute an (ready) operation containing a single transaction.
     *
     * Emits a {CallExecuted} event.
     *
     * Requirements:
     *
     * - the caller must have the 'admin' role.
     */
    function execute(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyAdmin {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _beforeCall(id, predecessor);
        _call(id, 0, target, value, data);
        _afterCall(id);
    }

    /**
     * @dev Execute an (ready) operation containing a batch of transactions.
     *
     * Emits one {CallExecuted} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'admin' role.
     */
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyAdmin {
        require(
            targets.length == values.length,
            "PhiatTimelockController: length mismatch"
        );
        require(
            targets.length == datas.length,
            "PhiatTimelockController: length mismatch"
        );

        bytes32 id = hashOperationBatch(
            targets,
            values,
            datas,
            predecessor,
            salt
        );
        _beforeCall(id, predecessor);
        for (uint256 i = 0; i < targets.length; ++i) {
            _call(id, i, targets[i], values[i], datas[i]);
        }
        _afterCall(id);
    }

    /**
     * @dev Checks before execution of an operation's calls.
     */
    function _beforeCall(bytes32 id, bytes32 predecessor) private view {
        require(
            isOperationReady(id),
            "PhiatTimelockController: operation is not ready"
        );
        require(
            predecessor == bytes32(0) || isOperationDone(predecessor),
            "PhiatTimelockController: missing dependency"
        );
    }

    /**
     * @dev Checks after execution of an operation's calls.
     */
    function _afterCall(bytes32 id) private {
        require(
            isOperationReady(id),
            "PhiatTimelockController: operation is not ready"
        );
        _timestamps[id] = _DONE_TIMESTAMP;
    }

    /**
     * @dev Execute an operation's call.
     *
     * Emits a {CallExecuted} event.
     */
    function _call(
        bytes32 id,
        uint256 index,
        address target,
        uint256 value,
        bytes calldata data
    ) private {
        (bool success, ) = target.call{value: value}(data);
        require(
            success,
            "PhiatTimelockController: underlying transaction reverted"
        );

        emit CallExecuted(id, index, target, value, data);
    }

    function updateReserveLimits(address reserve)
        public
        override
        onlyAdmin
        returns (DataTypes.ReserveLimits memory newLimits)
    {
        ILendingPool pool = ILendingPool(addressesProvider.getLendingPool());
        ILendingPoolConfigurator configurator = ILendingPoolConfigurator(
            addressesProvider.getLendingPoolConfigurator()
        );

        newLimits = pool.getReserveLimits(reserve);
        uint256 liquidity = liquidityOracle.getAssetLiquidity(reserve);
        if (liquidity > 0) {
            // maxGlobalDepositSize
            uint256 recommendedLimit = liquidity.div(10);
            if (
                recommendedLimit < newLimits.maxGlobalDepositSize ||
                newLimits.maxGlobalDepositSize == 0
            ) {
                newLimits.maxGlobalDepositSize = recommendedLimit;
                configurator.setMaxGlobalDepositSize(reserve, recommendedLimit);
            }
            // maxIndividualDepositSize
            recommendedLimit = liquidity.div(100);
            if (
                recommendedLimit < newLimits.maxIndividualDepositSize ||
                newLimits.maxIndividualDepositSize == 0
            ) {
                newLimits.maxIndividualDepositSize = recommendedLimit;
                configurator.setMaxIndividualDepositSize(
                    reserve,
                    recommendedLimit
                );
            }
            // maxGlobalBorrowSize
            recommendedLimit = liquidity.div(100).mul(6);
            if (
                recommendedLimit < newLimits.maxGlobalBorrowSize ||
                newLimits.maxGlobalBorrowSize == 0
            ) {
                newLimits.maxGlobalBorrowSize = recommendedLimit;
                configurator.setMaxGlobalBorrowSize(reserve, recommendedLimit);
            }
            // maxIndividualBorrowSize
            recommendedLimit = liquidity.div(1000).mul(6);
            if (
                recommendedLimit < newLimits.maxIndividualBorrowSize ||
                newLimits.maxIndividualBorrowSize == 0
            ) {
                newLimits.maxIndividualBorrowSize = recommendedLimit;
                configurator.setMaxIndividualBorrowSize(
                    reserve,
                    recommendedLimit
                );
            }
        }
    }

    function updateReservesLimits()
        external
        override
        onlyAdmin
        returns (DataTypes.ReserveLimits[] memory newLimits)
    {
        ILendingPool pool = ILendingPool(addressesProvider.getLendingPool());

        address[] memory reserves = pool.getReservesList();
        newLimits = new DataTypes.ReserveLimits[](reserves.length);
        for (uint256 i = 0; i < reserves.length; i++) {
            newLimits[i] = updateReserveLimits(reserves[i]);
        }
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
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import {ILendingPoolAddressesProvider} from "./ILendingPoolAddressesProvider.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

interface ILendingPool {
    /**
     * @dev Emitted on deposit()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the deposit
     * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
     * @param amount The amount deposited
     * @param referral The referral code used
     **/
    event Deposit(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on withdraw()
     * @param reserve The address of the underlyng asset being withdrawn
     * @param user The address initiating the withdrawal, owner of aTokens
     * @param to Address that will receive the underlying
     * @param amount The amount to be withdrawn
     **/
    event Withdraw(
        address indexed reserve,
        address indexed user,
        address indexed to,
        uint256 amount
    );

    /**
     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
     * @param reserve The address of the underlying asset being borrowed
     * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
     * initiator of the transaction on flashLoan()
     * @param onBehalfOf The address that will be getting the debt
     * @param amount The amount borrowed out
     * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
     * @param borrowRate The numeric rate at which the user has borrowed
     * @param referral The referral code used
     **/
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 borrowRateMode,
        uint256 borrowRate,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on repay()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The beneficiary of the repayment, getting his debt reduced
     * @param repayer The address of the user initiating the repay(), providing the funds
     * @param amount The amount repaid
     **/
    event Repay(
        address indexed reserve,
        address indexed user,
        address indexed repayer,
        uint256 amount
    );

    /**
     * @dev Emitted on swapBorrowRateMode()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user swapping his rate mode
     * @param rateMode The rate mode that the user wants to swap to
     **/
    event Swap(address indexed reserve, address indexed user, uint256 rateMode);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralEnabled(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralDisabled(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev Emitted on rebalanceStableBorrowRate()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user for which the rebalance has been executed
     **/
    event RebalanceStableBorrowRate(
        address indexed reserve,
        address indexed user
    );

    /**
     * @dev Emitted on flashLoan()
     * @param target The address of the flash loan receiver contract
     * @param initiator The address initiating the flash loan
     * @param asset The address of the asset being flash borrowed
     * @param amount The amount flash borrowed
     * @param premium The fee flash borrowed
     * @param referralCode The referral code used
     **/
    event FlashLoan(
        address indexed target,
        address indexed initiator,
        address indexed asset,
        uint256 amount,
        uint256 premium,
        uint16 referralCode
    );

    /**
     * @dev Emitted when the pause is triggered.
     */
    event Paused();

    /**
     * @dev Emitted when the pause is lifted.
     */
    event Unpaused();

    /**
     * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
     * LendingPoolCollateral manager using a DELEGATECALL
     * This allows to have the events in the generated ABI for LendingPool.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
     * @param liquidator The address of the liquidator
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );

    /**
     * @dev Emitted when a borrower is blacklisted.
     * @param user The address of the borrower getting liquidated
     **/
    event Blacklist(address indexed user);

    /**
     * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
     * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
     * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
     * gets added to the LendingPool ABI
     * @param reserve The address of the underlying asset of the reserve
     * @param liquidityRate The new liquidity rate
     * @param stableBorrowRate The new stable borrow rate
     * @param variableBorrowRate The new variable borrow rate
     * @param liquidityIndex The new liquidity index
     * @param variableBorrowIndex The new variable borrow index
     **/
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    function isBlacklisted(address user) external returns (bool);

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     **/
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     **/
    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @notice Repay all debts of the user and blacklist that user.
     * @param user Address of the user who will get his debt removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     **/
    function repayAllAndBlacklist(address user) external;

    /**
     * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
     * @param asset The address of the underlying asset borrowed
     * @param rateMode The rate mode that the user wants to swap to
     **/
    function swapBorrowRateMode(address asset, uint256 rateMode) external;

    /**
     * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
     * - Users can be rebalanced if the following conditions are satisfied:
     *     1. Usage ratio is above 95%
     *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
     *        borrowed at a stable rate and depositors are not earning enough
     * @param asset The address of the underlying asset borrowed
     * @param user The address of the user to be rebalanced
     **/
    function rebalanceStableBorrowRate(address asset, address user) external;

    /**
     * @dev Allows depositors to enable/disable a specific deposited asset as collateral
     * @param asset The address of the underlying asset deposited
     * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
     **/
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral)
        external;

    /**
     * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    /**
     * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
     * For further details please visit https://developers.aave.com
     * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
     * @param assets The addresses of the assets being flash-borrowed
     * @param amounts The amounts amounts being flash-borrowed
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @dev Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralETH the total collateral in ETH of the user
     * @return totalDebtETH the total debt in ETH of the user
     * @return availableBorrowsETH the borrowing power left of the user
     * @return currentLiquidationThreshold the liquidation threshold of the user
     * @return ltv the loan to value of the user
     * @return healthFactor the current health factor of the user
     **/
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function initReserve(
        address reserve,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    function setReserveInterestRateStrategyAddress(
        address reserve,
        address rateStrategyAddress
    ) external;

    function setConfiguration(address reserve, uint256 configuration) external;

    function setLimits(
        address reserve,
        DataTypes.ReserveLimits calldata reserveLimits
    ) external;

    /**
     * @dev Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     **/
    function getConfiguration(address asset)
        external
        view
        returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @dev Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     **/
    function getUserConfiguration(address user)
        external
        view
        returns (DataTypes.UserConfigurationMap memory);

    /**
     * @dev Returns the normalized income normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the normalized variable debt per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(address asset)
        external
        view
        returns (DataTypes.ReserveData memory);

    /**
     * @dev Returns the limits of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The limits of the reserve
     **/
    function getReserveLimits(address asset)
        external
        view
        returns (DataTypes.ReserveLimits memory);

    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromAfter,
        uint256 balanceToBefore
    ) external;

    function getReservesList() external view returns (address[] memory);

    function getAddressesProvider()
        external
        view
        returns (ILendingPoolAddressesProvider);

    function setPause(bool val) external;

    function paused() external view returns (bool);

    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
    event MarketIdSet(string newMarketId);
    event LendingPoolUpdated(address indexed newAddress);
    event ConfigurationAdminUpdated(address indexed newAddress);
    event EmergencyAdminUpdated(address indexed newAddress);
    event LendingPoolConfiguratorUpdated(address indexed newAddress);
    event LendingPoolCollateralManagerUpdated(address indexed newAddress);
    event PriceOracleUpdated(address indexed newAddress);
    event LendingRateOracleUpdated(address indexed newAddress);
    event IncentivesControllerUpdated(address indexed newAddress);
    event ProxyCreated(bytes32 id, address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

    function getMarketId() external view returns (string memory);

    function setMarketId(string calldata marketId) external;

    function setAddress(bytes32 id, address newAddress) external;

    function setAddressAsProxy(bytes32 id, address impl) external;

    function getAddress(bytes32 id) external view returns (address);

    function getLendingPool() external view returns (address);

    function setLendingPoolImpl(address pool) external;

    function getLendingPoolConfigurator() external view returns (address);

    function setLendingPoolConfiguratorImpl(address configurator) external;

    function getLendingPoolCollateralManager() external view returns (address);

    function setLendingPoolCollateralManager(address manager) external;

    function getPoolAdmin() external view returns (address);

    function setPoolAdmin(address admin) external;

    function getEmergencyAdmin() external view returns (address);

    function setEmergencyAdmin(address admin) external;

    function getPriceOracle() external view returns (address);

    function setPriceOracle(address priceOracle) external;

    function getLendingRateOracle() external view returns (address);

    function setLendingRateOracle(address lendingRateOracle) external;

    function getIncentivesController() external view returns (address);

    function setIncentivesController(address lendingRateOracle) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface ILendingPoolConfigurator {
    struct InitReserveInput {
        address aTokenImpl;
        address stableDebtTokenImpl;
        address variableDebtTokenImpl;
        uint8 underlyingAssetDecimals;
        address interestRateStrategyAddress;
        address underlyingAsset;
        address treasury;
        string underlyingAssetName;
        string aTokenName;
        string aTokenSymbol;
        string variableDebtTokenName;
        string variableDebtTokenSymbol;
        string stableDebtTokenName;
        string stableDebtTokenSymbol;
        uint256 maxGlobalDepositSize;
        uint256 maxIndividualDepositSize;
        uint256 minIndividualDepositSize;
        uint256 maxGlobalBorrowSize;
        uint256 maxIndividualBorrowSize;
        uint256 maxBorrowBps;
        bytes params;
    }

    struct UpdateATokenInput {
        address asset;
        address treasury;
        string name;
        string symbol;
        address implementation;
        bytes params;
    }

    struct UpdateDebtTokenInput {
        address asset;
        string name;
        string symbol;
        address implementation;
        bytes params;
    }

    /**
     * @dev Emitted when a reserve is initialized.
     * @param asset The address of the underlying asset of the reserve
     * @param aToken The address of the associated aToken contract
     * @param stableDebtToken The address of the associated stable rate debt token
     * @param variableDebtToken The address of the associated variable rate debt token
     * @param interestRateStrategyAddress The address of the interest rate strategy for the reserve
     **/
    event ReserveInitialized(
        address indexed asset,
        address indexed aToken,
        address stableDebtToken,
        address variableDebtToken,
        address interestRateStrategyAddress
    );

    /**
     * @dev Emitted when borrowing is enabled on a reserve
     * @param asset The address of the underlying asset of the reserve
     * @param stableRateEnabled True if stable rate borrowing is enabled, false otherwise
     **/
    event BorrowingEnabledOnReserve(
        address indexed asset,
        bool stableRateEnabled
    );

    /**
     * @dev Emitted when borrowing is disabled on a reserve
     * @param asset The address of the underlying asset of the reserve
     **/
    event BorrowingDisabledOnReserve(address indexed asset);

    /**
     * @dev Emitted when the collateralization risk parameters for the specified asset are updated.
     * @param asset The address of the underlying asset of the reserve
     * @param ltv The loan to value of the asset when used as collateral
     * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
     * @param liquidationBonus The bonus liquidators receive to liquidate this asset
     **/
    event CollateralConfigurationChanged(
        address indexed asset,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus
    );

    /**
     * @dev Emitted when stable rate borrowing is enabled on a reserve
     * @param asset The address of the underlying asset of the reserve
     **/
    event StableRateEnabledOnReserve(address indexed asset);

    /**
     * @dev Emitted when stable rate borrowing is disabled on a reserve
     * @param asset The address of the underlying asset of the reserve
     **/
    event StableRateDisabledOnReserve(address indexed asset);

    /**
     * @dev Emitted when a reserve is activated
     * @param asset The address of the underlying asset of the reserve
     **/
    event ReserveActivated(address indexed asset);

    /**
     * @dev Emitted when a reserve is deactivated
     * @param asset The address of the underlying asset of the reserve
     **/
    event ReserveDeactivated(address indexed asset);

    /**
     * @dev Emitted when a reserve is frozen
     * @param asset The address of the underlying asset of the reserve
     **/
    event ReserveFrozen(address indexed asset);

    /**
     * @dev Emitted when a reserve is unfrozen
     * @param asset The address of the underlying asset of the reserve
     **/
    event ReserveUnfrozen(address indexed asset);

    /**
     * @dev Emitted when a reserve factor is updated
     * @param asset The address of the underlying asset of the reserve
     * @param factor The new reserve factor
     **/
    event ReserveFactorChanged(address indexed asset, uint256 factor);

    /**
     * @dev Emitted when the reserve decimals are updated
     * @param asset The address of the underlying asset of the reserve
     * @param decimals The new decimals
     **/
    event ReserveDecimalsChanged(address indexed asset, uint256 decimals);

    /**
     * @dev Emitted when a reserve interest strategy contract is updated
     * @param asset The address of the underlying asset of the reserve
     * @param strategy The new address of the interest strategy contract
     **/
    event ReserveInterestRateStrategyChanged(
        address indexed asset,
        address strategy
    );

    /**
     * @dev Emitted when the reserve maximum global deposit size is updated
     * @param asset The address of the underlying asset of the reserve
     * @param maxGlobalDepositSize The new maximum global deposit size
     **/
    event ReserveMaxGlobalDepositSizeChanged(
        address indexed asset,
        uint256 maxGlobalDepositSize
    );

    /**
     * @dev Emitted when the reserve maximum individual deposit size is updated
     * @param asset The address of the underlying asset of the reserve
     * @param maxIndividualDepositSize The new maximum individual deposit size
     **/
    event ReserveMaxIndividualDepositSizeChanged(
        address indexed asset,
        uint256 maxIndividualDepositSize
    );

    /**
     * @dev Emitted when the reserve minimum individual deposit size is updated
     * @param asset The address of the underlying asset of the reserve
     * @param minIndividualDepositSize The new minimum individual deposit size
     **/
    event ReserveMinIndividualDepositSizeChanged(
        address indexed asset,
        uint256 minIndividualDepositSize
    );

    /**
     * @dev Emitted when the reserve maximum global borrow size is updated
     * @param asset The address of the underlying asset of the reserve
     * @param maxGlobalBorrowSize The new maximum global borrow size
     **/
    event ReserveMaxGlobalBorrowSizeChanged(
        address indexed asset,
        uint256 maxGlobalBorrowSize
    );

    /**
     * @dev Emitted when the reserve maximum individual borrow size is updated
     * @param asset The address of the underlying asset of the reserve
     * @param maxIndividualBorrowSize The new maximum individual borrow size
     **/
    event ReserveMaxIndividualBorrowSizeChanged(
        address indexed asset,
        uint256 maxIndividualBorrowSize
    );

    /**
     * @dev Emitted when the reserve maximum borrow bps is updated
     * @param asset The address of the underlying asset of the reserve
     * @param maxBorrowBps The new maximum borrow bps
     **/
    event ReserveMaxBorrowBpsChanged(
        address indexed asset,
        uint256 maxBorrowBps
    );

    /**
     * @dev Emitted when an aToken implementation is upgraded
     * @param asset The address of the underlying asset of the reserve
     * @param proxy The aToken proxy address
     * @param implementation The new aToken implementation
     **/
    event ATokenUpgraded(
        address indexed asset,
        address indexed proxy,
        address indexed implementation
    );

    /**
     * @dev Emitted when the implementation of a stable debt token is upgraded
     * @param asset The address of the underlying asset of the reserve
     * @param proxy The stable debt token proxy address
     * @param implementation The new aToken implementation
     **/
    event StableDebtTokenUpgraded(
        address indexed asset,
        address indexed proxy,
        address indexed implementation
    );

    /**
     * @dev Emitted when the implementation of a variable debt token is upgraded
     * @param asset The address of the underlying asset of the reserve
     * @param proxy The variable debt token proxy address
     * @param implementation The new aToken implementation
     **/
    event VariableDebtTokenUpgraded(
        address indexed asset,
        address indexed proxy,
        address indexed implementation
    );

    /**
     * @dev Updates the maximum global deposit size of a reserve
     * @param asset The address of the underlying asset of the reserve
     * @param maxGlobalDepositSize The new maximum global deposit size of the reserve
     **/
    function setMaxGlobalDepositSize(
        address asset,
        uint256 maxGlobalDepositSize
    ) external;

    /**
     * @dev Updates the maximum individual deposit size of a reserve
     * @param asset The address of the underlying asset of the reserve
     * @param maxIndividualDepositSize The new maximum individual deposit size of the reserve
     **/
    function setMaxIndividualDepositSize(
        address asset,
        uint256 maxIndividualDepositSize
    ) external;

    /**
     * @dev Updates the maximum global borrow size of a reserve
     * @param asset The address of the underlying asset of the reserve
     * @param maxGlobalBorrowSize The new maximum global borrow size of the reserve
     **/
    function setMaxGlobalBorrowSize(address asset, uint256 maxGlobalBorrowSize)
        external;

    /**
     * @dev Updates the maximum individual borrow size of a reserve
     * @param asset The address of the underlying asset of the reserve
     * @param maxIndividualBorrowSize The new maximum individual borrow size of the reserve
     **/
    function setMaxIndividualBorrowSize(
        address asset,
        uint256 maxIndividualBorrowSize
    ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

interface IMarketLiquidityOracle {
    /**
     * @dev returns the on-chain asset liquidity
     * @param asset the address of the asset
     * @return the market liquidity of the asset
     **/
    function getAssetLiquidity(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../protocol/libraries/types/DataTypes.sol";

interface IPhiatTimelockController {
    function updateReserveLimits(address reserve)
        external
        returns (DataTypes.ReserveLimits memory newLimits);

    function updateReservesLimits()
        external
        returns (DataTypes.ReserveLimits[] memory newLimits);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

library DataTypes {
    // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: Reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60-63: reserved
        //bit 64-79: reserve factor
        uint256 data;
    }

    struct ReserveLimits {
        uint256 maxGlobalDepositSize;
        uint256 maxIndividualDepositSize;
        uint256 minIndividualDepositSize;
        uint256 maxGlobalBorrowSize;
        uint256 maxIndividualBorrowSize;
        uint256 maxBorrowBps;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }
}
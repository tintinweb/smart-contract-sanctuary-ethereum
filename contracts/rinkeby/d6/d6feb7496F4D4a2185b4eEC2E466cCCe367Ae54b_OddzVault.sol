//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "./maths/OddzSafeCast.sol";
import "./maths/OddzMath.sol";
import "./interfaces/IERC20Metadata.sol";
import "./interfaces/IBalanceManager.sol";
import "./interfaces/IOrderManager.sol";
import "./interfaces/IInsuranceManager.sol";
import "./utils/oddzPausable.sol";
import "./maths/OddzSettlementTokenMath.sol";

contract OddzVault is ReentrancyGuardUpgradeable, OddzPausable {
    using SafeMathUpgradeable for uint256;
    using OddzSafeCast for uint256;
    using OddzSafeCast for int256;
    using SignedSafeMathUpgradeable for int256;
    using OddzMath for int256;
    using OddzMath for uint256;
    using AddressUpgradeable for address;
    using OddzSettlementTokenMath for int256;

    //contract variables

    //mapping of trader=>collateralToken=>amount
    mapping(address => mapping(address => int256)) internal balance;

    address public settlementToken;
    address public balanceManager;
    address public orderManager;
    address public insuranceManager;
    uint256 public totalBorrowedFund;

    uint8 public settlementTokenDecimals;

    // Events
    event CollateralDeposited(
        address indexed token,
        address indexed from,
        uint256 amount
    );

    event CollateralWithdrawn(
        address indexed token,
        address indexed to,
        uint256 amount
    );

    modifier onlyAuthorized() {
        require(
            _msgSender() == balanceManager || _msgSender() == orderManager,
            "OddzVault: Only balance manager and order manager allowed"
        );
        _;
    }

    // once other are contracts ready we will use address arg instead of newValue
    function initialize(address _settlementToken) external initializer {
        __ReentrancyGuard_init();
        __OddzPausable_init();

        uint8 decimals = IERC20Metadata(_settlementToken).decimals();
        require(
            decimals <= 18,
            "OddzVault:Invalid decimal of the settlement token"
        );

        settlementToken = _settlementToken;
        settlementTokenDecimals = decimals;
    }

    /**
     * @notice Used to update Balance Manager contract address
     * @param _balanceManager Address of the balance manager ontract
     */

    function updateBalanceManager(address _balanceManager) external onlyOwner {
        require(
            _balanceManager.isContract(),
            "OddzVault: Balance Manager should be a contract"
        );
        balanceManager = _balanceManager;
    }

    /**
     * @notice Used to update order Manager contract address
     * @param _orderManager Address of the order manager contract
     */

    function updateOrderManager(address _orderManager) external onlyOwner {
        require(
            _orderManager.isContract(),
            "OddzVault: Order Manager should be a contract"
        );
        orderManager = _orderManager;
    }

    /**
     * @notice Used to update Insurance Manager contract address
     * @param _insuranceManager Address of the insurance manager ontract
     */

    function updateInsuranceManager(address _insuranceManager) external onlyOwner {
        require(
            _insuranceManager.isContract(),
            "OddzVault: insurance Manager should be a contract"
        );
        insuranceManager = _insuranceManager;
    }

    /**
     * @notice Trader Supplies collateral tokens to the pVault
     * @param _token The Address of the collateral token
     * @param _amount Amount of token that User Supplies
     */
    function depositCollateral(address _token, uint256 _amount)
        external
        whenNotPaused
        nonReentrant
    {
        address traderAddress = _msgSender();

        //update balance of the trader
        balance[traderAddress][_token] = balance[traderAddress][_token].add(
            _amount.toInt256()
        );

        //check the balance of contract before transfering tokens
        uint256 balBefore = IERC20Metadata(_token).balanceOf(address(this));
        SafeERC20Upgradeable.safeTransferFrom(
            IERC20Upgradeable(_token),
            traderAddress,
            address(this),
            _amount
        );

        //check the balance of contract before transfering tokens
        uint256 balAfter = IERC20Metadata(_token).balanceOf(address(this));
        // checks for deflationary tokens
        require(
            balAfter.sub(balBefore) == _amount,
            "OddzVault: balance incosistent"
        );

        emit CollateralDeposited(_token, traderAddress, _amount);
    }

    /**
     * @notice Trader withdraw collateral tokens from the oddz vault
     * @param _token The Address of the collateral token
     * @param _amount Amount of token that User Supplies; can be 0, do not require this
     */
    function withdrawCollateral(address _token, uint256 _amount)
        external
        whenNotPaused
        nonReentrant
    {
        require(_amount > 0, "Amount can not be zero");
        address traderAddress = _msgSender();

        int256 availableCollateral = getAvailableCollateral(traderAddress);

        require(availableCollateral >= _amount.toInt256(),
            "OddzVault:Not enough available collateral"
        );

        // borrow some amount from insurance manager when vault has insufficient fund.
        uint256 availableFundInVault = IERC20Metadata(_token).balanceOf(address(this));
        if(_amount > availableFundInVault){
            uint256 borrowedFund = (_amount - availableFundInVault);
            IInsuranceManager(insuranceManager).borrowFund(borrowedFund);
            totalBorrowedFund = totalBorrowedFund.add(borrowedFund);
        }

        //update balance of the trader
        balance[traderAddress][_token] = balance[traderAddress][_token].sub(_amount.toInt256());

        SafeERC20Upgradeable.safeTransfer(
            IERC20Upgradeable(_token),
            traderAddress,
            _amount
        );

        emit CollateralWithdrawn(_token, traderAddress, _amount);
    }


     /**
     * @notice updates the main balance of the trader.Called to settle owed Realized PnL.Can only be called by balance manager
     * @param _trader The Address of the trader
     * @param _amount settlement amount
     */
    function updateCollateralBalance(
        address _trader,
        int256 _amount
    ) external onlyAuthorized {
        //require(_amount>0,"Amount can not be zero");
        //update balance of the trader
        balance[_trader][settlementToken] = balance[_trader][settlementToken].add(_amount.formatSettlementToken(settlementTokenDecimals));
    }

    /**
     * @notice As balance mapping is internal so to get the balance of trader this fn is used.
     * @param _trader The Address of the trader
     * @param _token The Address settled token
     * @return _balance of the trader for that token
     */
    function getCollateralBalance(address _trader, address _token)
        public
        view
        returns (int256 _balance)
    {
        return balance[_trader][_token];
    }

    /**
     * @notice return available collateral that is free/available  
     * @dev (totalDepositedCollateral - totalCollateralInPositions - totalCollateralInLiquidityPositions)
     * @param _trader The Address of the trader
     * @return _balance of the trader for that token
     */
    function getAvailableCollateral(address _trader)
        public
        view
        returns (int256 _balance)
    {
        // total collateral for the trader
        int256 accountValue = balance[_trader][settlementToken];

        // total Used collateral in positions (group +isolate)
        uint256 totalUsedCollateral = IBalanceManager(balanceManager)
            .getTotalUsedCollateralInPositions(_trader);


        // total used collateral for liquidity positions
        uint256 totalUsedCollateralForOrders = IOrderManager(orderManager)
            .getTotalCollateralForOrders(_trader);
        return
            accountValue.sub(
                (totalUsedCollateral.add(totalUsedCollateralForOrders))
                    .toInt256());
    }


     /**
     * @notice Returns how much margin is available for the isolated position
     * @param _trader The Address of the trader
     * @param _positionID  position id for which we are checking the collateral
     * @param _ratio    ratio (initial margin ratio or maintenance margin ratio)
     */
    function getPositionCollateralByRatio(
        address _trader,
        uint256 _positionID,
        uint24 _ratio
    ) external view returns (int256) {
        require(
            getAvailableCollateral(_trader) > 0,
            "OddzVault: Not enough collateral"
        );

        //fetch position info
        IBalanceManager.PositionInfo memory positionInfo = IBalanceManager(
            balanceManager
        ).getPositionInfo(_positionID);


        // calculate  the collateral required for the position
        uint256 totalMarginRequirementForPosition = (
            IBalanceManager(balanceManager).getTotalPositionDebt(
                _positionID
            )
        ).mulRatio(_ratio);

        int256 unrealizedPnL= IBalanceManager(balanceManager).getPositionUnrealisedPnL(_positionID);
        return
            positionInfo.collateralForPosition.toInt256().sub(
                totalMarginRequirementForPosition
                    .toInt256()
                    .formatSettlementToken(settlementTokenDecimals)
            ).add(unrealizedPnL.formatSettlementToken(settlementTokenDecimals)
            ).add(positionInfo.owedRealizedPnl.formatSettlementToken(settlementTokenDecimals)); 
    }


   /**
     * @notice Returns how much margin is available for the group
     * @param _trader The Address of the trader
     * @param _groupID  group id for which we are checking the collateral
     * @param _ratio    ratio (initial margin ratio or maintenance margin ratio)
     */
    function getGroupCollateralByRatio(
        address _trader,
        uint256 _groupID,
        uint24 _ratio
    ) external view returns (int256) {
        require(
            getAvailableCollateral(_trader) > 0,
            "OddzVault: Not enough collateral"
        );

        // fetch the collateral information of the group
        IBalanceManager.GroupInfo memory groupInfo = IBalanceManager(
            balanceManager
        ).getGroupInfo(_groupID);


        // calculate the required collateral for the group
        uint256 totalMarginRequirementForGroup = (
            IBalanceManager(balanceManager).getTotalGroupInfo(_groupID)
        ).mulRatio(_ratio);

        (int256 unrealizedPnL,int256 realizedPnL)= IBalanceManager(balanceManager).getGroupPnL(_groupID);
        return
            groupInfo.collateralAllocated.toInt256().sub(
                totalMarginRequirementForGroup.toInt256().formatSettlementToken(
                    settlementTokenDecimals
                )
            ).add(unrealizedPnL.formatSettlementToken(settlementTokenDecimals)
            ).add(realizedPnL.formatSettlementToken(settlementTokenDecimals));
        
    }


   /**
     * @notice Returns how much margin is available for the liquidity order
     * @param _trader The Address of the trader
     * @param _baseToken base token address
     * @param _orderID liquidity order for which we are checking the collateral
     * @param _ratio    ratio (initial margin ratio or maintenance margin ratio)
     */
    function getLiquidityPositionCollateralByRatio(
        address _trader,
        address _baseToken,
        bytes32 _orderID,
        uint24 _ratio
    ) external view returns (int256) {
        require(
            getAvailableCollateral(_trader) > 0,
            "OddzVault: Not enough collateral"
        );

        // fetch order information
        IOrderManager.OrderInfo memory orderInfo = IOrderManager(orderManager)
            .getCurrentOrderMap(_orderID);

        // calculate total margin required for the liquidity position    
        uint256 totalMarginRequirementForPosition = (
            IBalanceManager(balanceManager).getTotalOrderInfo(
                _baseToken,
                _orderID
            )
        ).mulRatio(_ratio);

         int256 unrealisedPnL= IBalanceManager(balanceManager).getLiquidityPositionUnrealisedPnL(_baseToken,_orderID);

        return
            orderInfo.collateralForOrder.toInt256().sub(
                totalMarginRequirementForPosition
                    .toInt256()
                    .formatSettlementToken(settlementTokenDecimals)
            ).add(unrealisedPnL.formatSettlementToken(settlementTokenDecimals)
            ).add(orderInfo.owedRealizedPnl.formatSettlementToken(settlementTokenDecimals));
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
import "../proxy/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
    uint256[49] private __gap;
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
library SafeMathUpgradeable {
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

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMathUpgradeable {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6;

/**
 * @dev copy from "@openzeppelin/contracts-upgradeable/utils/SafeCastUpgradeable.sol"
 * and rename to avoid naming conflict with uniswap
 */
library OddzSafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128 returnValue) {
        require(((returnValue = uint128(value)) == value), "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64 returnValue) {
        require(((returnValue = uint64(value)) == value), "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32 returnValue) {
        require(((returnValue = uint32(value)) == value), "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16 returnValue) {
        require(((returnValue = uint16(value)) == value), "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8 returnValue) {
        require(((returnValue = uint8(value)) == value), "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 returnValue) {
        require(((returnValue = int128(value)) == value), "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 returnValue) {
        require(((returnValue = int64(value)) == value), "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 returnValue) {
        require(((returnValue = int32(value)) == value), "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 returnValue) {
        require(((returnValue = int16(value)) == value), "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 returnValue) {
        require(((returnValue = int8(value)) == value), "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }


    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toInt24(int256 value) internal pure returns (int24 returnValue) {
        require(((returnValue = int24(value)) == value), "SafeCast: value doesn't fit in an 24 bits");
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "../uniswap/FixedPoint96.sol";
import "../uniswap/FullMath.sol";
import "./OddzSafeCast.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";

library OddzMath {
    using OddzSafeCast for int256;
    using SignedSafeMathUpgradeable for int256;
    using SafeMathUpgradeable for uint256;

    function formatSqrtPriceX96ToPriceX96(uint160 sqrtPriceX96) internal pure returns (uint256) {
        return FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96);
    }

    function formatX10_18ToX96(uint256 valueX10_18) internal pure returns (uint256) {
        return FullMath.mulDiv(valueX10_18, FixedPoint96.Q96, 1 ether);
    }

    function formatX96ToX10_18(uint256 valueX96) internal pure returns (uint256) {
        return FullMath.mulDiv(valueX96, 1 ether, FixedPoint96.Q96);
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    function abs(int256 value) internal pure returns (uint256) {
        return value >= 0 ? value.toUint256() : neg256(value).toUint256();
    }

    function neg256(int256 a) internal pure returns (int256) {
        require(a > -2**255, "PerpMath: inversion overflow");
        return -a;
    }

    function neg256(uint256 a) internal pure returns (int256) {
        return -OddzSafeCast.toInt256(a);
    }

    function neg128(int128 a) internal pure returns (int128) {
        require(a > -2**127, "PerpMath: inversion overflow");
        return -a;
    }

    function neg128(uint128 a) internal pure returns (int128) {
        return -OddzSafeCast.toInt128(a);
    }

    function divBy10_18(int256 value) internal pure returns (int256) {
        // no overflow here
        return value / (1 ether);
    }

    function divBy10_18(uint256 value) internal pure returns (uint256) {
        // no overflow here
        return value / (1 ether);
    }

    function mulRatio(uint256 value, uint24 ratio) internal pure returns (uint256) {
        return FullMath.mulDiv(value, ratio, 1e6);
    }

    /// @param denominator cannot be 0 and is checked in FullMath.mulDiv()
    function mulDiv(
        int256 a,
        int256 b,
        uint256 denominator
    ) internal pure returns (int256 result) {
        uint256 unsignedA = a < 0 ? uint256(neg256(a)) : uint256(a);
        uint256 unsignedB = b < 0 ? uint256(neg256(b)) : uint256(b);
        bool negative = ((a < 0 && b > 0) || (a > 0 && b < 0)) ? true : false;

        uint256 unsignedResult = FullMath.mulDiv(unsignedA, unsignedB, denominator);

        result = negative ? neg256(unsignedResult) : OddzSafeCast.toInt256(unsignedResult);

        return result;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.7.6;

import  "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6;
pragma abicoder v2;

interface IBalanceManager {
    struct PositionInfo {
        address trader; // address of the trader
        address baseToken; // base token address
        uint256 groupID; // group id if position is in group otherwise 0 (group id starts from 1)
        int256 takerBasePositionSize; //trader base token amount
        int256 takerQuoteSize; //trader quote token amount
        uint256 collateralForPosition; // allocated collateral for this position
        int256 owedRealizedPnl; // owed realized profit and loss
        int256 lastTwPremiumGrowthGlobalX96; // the last time weighted premiumGrowthGlobalX96
    }

    struct GroupPositionsInfo {
        uint256 positionID; // position id
        address baseToken; // base token of the position
    }

    struct GroupInfo {
        address trader; // address of the trader
        bool autoLeverage;  // if for this group auto leverage is enabled or not .
        uint256 collateralAllocated; // collateral allocated to this group
        int256 owedRealizedPnl; // owed realized profit and loss
        GroupPositionsInfo[] groupPositions; // all the positions this group holds
    }

    /* /// @notice Every time a trader's position value is checked, the base token list of this trader will be traversed;
    /// thus, this list should be kept as short as possible
    /// @dev Only used by `ClearingHouse` contract
    /// @param trader The address of the trader
    /// @param baseToken The address of the trader's base token
    ///@param include true if token is going to be added otherwise false
    function updateBaseTokensForTrader(
        address trader,
        address baseToken,
        bool include
    ) external; */

      /**
     * @notice Used to set the default group id for the trader
     * @param trader Address of the trader
     * @param id default group id
     */
    function updateTraderDefaultGroupID(
        address trader,
        uint256 id
        )external ;

    /**
     * @notice Used to update positions id and collateral of a trader
     * @param trader Address of the trader
     * @param positionID position id
     * @param collateralForPosition collateral used in position
     * @param existing   if the position id already exist or not
     * @param group     if position is in any group or not
     * @param push       true if we want to add the position and false if we want to remove position
     */
    function updateTraderPositions(
        address trader,
        uint256 positionID,
        uint256 collateralForPosition,
        bool existing,
        bool group,
        bool push
    ) external;

    /**
     * @notice Used to update groups ,positions in groups and collateral of a trader
     * @param trader Address of the trader
     * @param baseToken base token address
     * @param positionID position id
     * @param groupID  group id
     * @param collateralForPosition collateral used in position
     * @param isNewGroup  is this a new group or existing
     * @param existing   if the position id already exist or not
     * @param push       true if we want to add the position and false if we want to remove position
     */
    function updateTraderGroups(
        address trader,
        address baseToken,
        uint256 positionID,
        uint256 groupID,
        uint256 collateralForPosition,
        bool isNewGroup,
        bool existing,
        bool push
    ) external;

     /**
     *@notice This function updates the group and position info for the trader.
     *@dev Is called by oddz Clearing house when moving positions
     *@param positionID position id
     *@param groupPositionID position id of the group to which position is going to merge
     *@param groupID  group id of the destination position
     *@param sourceRealizedPnL realized PnL of the source position
     *@param sourceGroupID group id of the source position
     *@param collateral  collateral allocated
     *@param merge if two positions are merged or not
     */
    function updateTraderGroupAndPosition(
        uint256 positionID,
        uint256 groupPositionID,
        uint256 groupID,
        int256 sourceRealizedPnL,
        uint256 sourceGroupID,
        uint256 collateral,
        bool merge
    ) external ;


    /**
    *@notice updates the collateral amount of the position
    *@param positionID position id in the group 
    *@param collateral collateral amount
     */
     function updateCollateral(
        uint256 positionID,
        uint256 collateral
    )external;

    /**
    *@notice updates the position in the particular group
    *@param positionID position id in the group 
    *@param groupID group to be updated
     */
    function updatePositionsInGroup(
        uint256 positionID,
        uint256 groupID
        )external ;

    /**
     * @notice updates postionSize and quoteSize of the trader.Can only be called by oddz clearing house
     * @param trader     address of the trader
     * @param baseToken  base token address
     * @param positionId  position id
     * @param baseAmount the base token amount
     * @param quoteAmount the quote token amount
     * @param groupId     group id if position is in any group otherwise 0
     * returns updated values
     */
    function updateTraderPositionInfo(
        address trader,
        address baseToken,
        uint256 positionId,
        int256 baseAmount,
        int256 quoteAmount,
        uint256 groupId
    ) external returns (int256, int256);

    /**
     * @notice updates postionSize and quoteSize of the trader and settle realizedPnl and updates base tokens.
     * Can only be called by oddz clearing house while removing liquidity
     * @param _positionId  position id
     * @param _takerBase   the base token amount
     * @param _takerQuote  the quote token amount
     * @param _realizedPnl realized PnL
     */
    function settleBalanceAndDeregister(
        uint256 _positionId,
        int256 _takerBase,
        int256 _takerQuote,
        int256 _realizedPnl
    ) external;


    /**
     * @notice Settles quote amount into owedRealized profit or loss.Can only be called by Oddz clearing house
     * @param positionId       position id
     * @param settlementAmount the amount to be settled
     */
    function settleQuoteToOwedRealizedPnl(
        uint256 positionId,
        int256 settlementAmount
    ) external;

    /**
     * @notice updates and settles Pnl in the main collateral Balance.It is called by clearing House when removing liquidity. 
     * @param maker       maker address
     * @param quoteAmount       maker's difference in provided amount and recieved amount
     * @param swappedQuoteSize  quote amount, we got/spent when closing the impermanent position
     * @param closing           if we are closing the impermanent position or not
     */
    function settleLiquidityPnL(
        address maker,
        int256 quoteAmount,
        int256 swappedQuoteSize,
        bool closing
    ) external;

    /**
     * @notice update insurance fund fees
     * @param _amount The owned fee amount 
     */
    function updateInsuranceManagerFees(int256 _amount) external;

    /**
    * @notice udpates the liquidation fees
    * @param liquidator liquidator address
    * @param trader     trader address
    * @param amount      swapped quote position amount
     */
    function updateLiquidationFees(address liquidator,address trader,int256 amount) external;


    /**
     * @notice updates owed realized PnL.
     * @param positionId        Position id
     * @param amount            amount to be realized
     */
    function updateOwedRealizedPnl(uint256 positionId, int256 amount) external;

    /**
     *@notice updates the time weighted premium of the position after settling funding payment
     *@param positionId position id
     *@param twPremiumGrowthGlobal time weighted premium
     */
    function updateTwPremiumGrowthGlobal(
        uint256 positionId,
        int256 twPremiumGrowthGlobal
    ) external;

    
    /**
    * @notice to get position value
    * @param positionId position id
    * @return positionCollateralValue position value (collateral + unrealizedPnl+realizedPnl + funding payment )
     */
    function getPositionCollateralValue(uint positionId)
        external
        view 
        returns(int256 positionCollateralValue); 
    
     /**
    * @notice to get group collateral value (collateral + unrealizedPnl+realizedPnl - pending funding payment )
    * @param groupId group id
    * @return groupCollateralValue group value 
     */
    function getGroupCollateralValue(uint256 groupId)
        external
        view 
        returns(int256 groupCollateralValue) ;

     /**
    * @notice to get liquidity collateral value (collateral + unrealizedPnl+realizedPnl - pending funding payment )
    * @param orderId liquidity order id
    * @param baseToken base token address
    * @return  liquidityOrderValue liquidity order collteral value 
     */
    function getLiquidityOrderCollateralValue(bytes32 orderId,address baseToken)
        external
        view 
        returns(int256 liquidityOrderValue);

     /**
    * @notice to get poisition value in usd (position size * index price)
    * @param positionId position id
    * @return positionValue position value
    */

    function getPositionValue(uint256 positionId)
        external
        view
        returns(uint256 positionValue);
    
     /**
    * @notice to get group value in usd
    * @param groupId position id
    * @return groupValue position value
    */
    function getGroupValue(uint256 groupId)
        external
        view
        returns(uint256 groupValue);
    
    /**
    * @notice to get liquidity order impermanent position value
    * @param orderId order id
    * @param baseToken base token address
    * @return impermanentPositionValue impermanent position value
     */
    function getImpermanentPositionValue(bytes32 orderId,address baseToken)
        external
        view
        returns(uint256 impermanentPositionValue);

    /**
     * @notice to get base token amount of a position
     * @param positionID       position id
     * @return positionSize    base token amount
     */
    function getTakerBasePositionSize(uint256 positionID)
        external
        view
        returns (int256 positionSize);

    /**
     * @notice to get quote token amount of a position
     * @param positionID       position id
     * @return quoteSize    quote token amount
     */
    function getTakerQuoteSize(uint256 positionID)
        external
        view
        returns (int256 quoteSize);

    /**
     * @notice It is used to get the total position debt value(usd) of the position
     * @param positionID       position id
     * @return totalPositionDebt  Debt value(usd) of the position
     */
    function getTotalPositionDebt(uint256 positionID)
        external
        view
        returns (uint256 totalPositionDebt);

    /**
     * @notice It is used to get the total value(usd) of  any group includes all the positions in the group
     * @param groupId       group id
     * @return groupValue   Value(usd) of the group
     */
    function getTotalGroupInfo(uint256 groupId)
        external
        view
        returns (uint256 groupValue);

    /**
     * @notice It is used to get the total value(usd) of  any liqudity order
     * @param baseToken    Base token address
     * @param orderId      order id
     * @return orderValue   Value(usd) of the order
     */
    function getTotalOrderInfo(address baseToken, bytes32 orderId)
        external
        view
        returns (uint256 orderValue);

    /**
    *@notice This function is used to get the  debt(total tokens in the pool) of the maker(liquidity provider)
    *@param  orderId order id of the liquidity position
    *@return orderDebt order debt
     */
    function getLiquidityOrderBaseDebt(bytes32 orderId)
        external
        view 
        returns(int256 orderDebt);

    /**
     * @notice used to get all the traders positions
     * @param trader   trader address
     * @return positions   all the position trader has
     */
    function getTraderPositions(address trader)
        external
        view
        returns (uint256[] memory positions);

    /**
     * @notice used to get all the traders groups
     * @param trader   trader address
     * @return groups   all the groups trader has
     */
    function getTraderGroups(address trader)
        external
        view
        returns (uint256[] memory groups);

    
    /**
     * @notice used to get  group information
     * @param groupId  group id
     * @return info   info of the group
     */
    function getGroupInfo(uint256 groupId) external view returns (GroupInfo memory info);


    /**
     * @notice used to get  position information
     * @param positionId  position id
     * @return info   info of the position
     */
    function getPositionInfo(uint256 positionId)
        external
        view
        returns (PositionInfo memory info);

    /**
     * @notice returns the total used collateral in positions for the trader
     * @param trader       trader address
     * @return collateral total used collateral in positions
     */
    function getTotalUsedCollateralInPositions(address trader)
        external
        view
        returns (uint256 collateral);


     /**
     * @notice used to get  default group of if the trader 
     * @param trader  trader address
     * @return defaultGroupId  default group id for the trader
     */
    function getDefaultGroupForTrader(address trader) 
        external    
        view
        returns(uint256 defaultGroupId);

    /**
    * @notice to get maintenance margin requirement for position
    * @param positionId position id
    * @return marginRequired margin required for the position
     */
     function getMarginRequirementForPositionLiquidation(uint256 positionId) external view returns(int256 marginRequired);

     
     /**
    * @notice to get maintenance margin requirement for group
    * @param groupId group id
    * @return marginRequired margin required for the group
     */
     function getMarginRequirementForGroupLiquidation(uint256 groupId) 
        external
        view
        returns(int256 marginRequired);

     /**
    * @notice to get maintenance margin requirement for liquidity order
    * @param orderId order id
    * @param baseToken base token address
    * @return marginRequired margin required for the liquidity order
     */
     function getMarginRequirementForLiquidityOrderLiquidation(bytes32 orderId,address baseToken) 
        external
        view
        returns(int256 marginRequired);


    function getTraderTotalLiquidityUnrealisedPnL(address _trader) external view returns(int256 _unrealisedPnL);

     /**
     * @notice used to get unrealised PnL of liquidity position by order id.
     * @param _baseToken base token address
     * @param _orderId  order id 
     * @return _unrealizedPnL unrealized Profit or loss from liquidity position
     */
    function getLiquidityPositionUnrealisedPnL(address _baseToken,bytes32 _orderId) external view returns(int256 _unrealizedPnL);
     /**
     * @notice used to get total value of base token of a particular position.
     * @param positionID position id
     */
     function getBaseTokenValue(uint256 positionID) external view returns (int256);

    /**
     * @notice used to get trader PnL(Unrealised and Realised).
     * @param trader  address of the trader.
     * @param isIsolate true for isolated position and false for grouping
     * @return unrealizedPnL returns unrealized Pnl of either all isolate poistion or grouped positions
     * @return realizedPnL return realized PnL of either all isolate poistion or grouped positions
     */
    function getTraderPnLBy(address trader, bool isIsolate) external view returns(int256 unrealizedPnL, int256 realizedPnL);

     /**
     * @notice used to get trader's group PnL .
     * @param groupId  group id 
     * @return unrealizedPnL unrealized Pnl of the group
     * @return realizedPnl unrealized PnL of the group
     */
    function getGroupPnL(uint256 groupId) external view returns(int256 unrealizedPnL, int256 realizedPnl);
    
     /**
     * @notice used to get unrealised PnL.
     * @param positionID  position id 
     * @return unrealizedPnl unrealized PnL of the position
     */
    function getPositionUnrealisedPnL(uint256 positionID) external view returns(int256 unrealizedPnl);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6;
pragma abicoder v2;

interface IOrderManager {
    /// @param liquidity          Liquidity amount
    /// @param lowerTick          Lower tick of liquidity range
    /// @param upperTick          Upper tick of liquidity range
    /// @param lastFeeGrowthInside  lastFeeGrowthInside fees in quote token recorded in swap maanger
    /// @param baseAmountInPool   number of base token added
    /// @param quoteAmountInPool  number of quote token added
    /// @param collateralForOrder collateral allocated for this order
    /// @param lastTwPremiumGrowthInsideX96 time weighted premium growth inside
    /// @param lastTwPremiumGrowthBelowX96   time weighted premium growth below
    /// @param lastTwPremiumDivBySqrtPriceGrowthInsideX96 time weighted premium growth inside div by sqrt price
    /// @param owedRealizedPnl  owed realized Pnl
    /// @param lastTwPremiumGrowthGlobalX96  the last time weighted premiumGrowthGlobalX96
    struct OrderInfo {
        address trader;
        uint128 liquidity;
        int24 lowerTick;
        int24 upperTick;
        uint256 lastFeeGrowthInside;
        uint256 baseAmountInPool;
        uint256 quoteAmountInPool;
        uint256 collateralForOrder;
        int256 lastTwPremiumGrowthInsideX96;
        int256 lastTwPremiumGrowthBelowX96;
        int256 lastTwPremiumDivBySqrtPriceGrowthInsideX96;
        int256 owedRealizedPnl;
        int256 lastTwPremiumGrowthGlobalX96; 
    }

    /// @param trader                   Trader address
    /// @param baseToken                Base token address
    /// @param baseAmount               Base token amount
    /// @param quoteAmount              Quote token amount
    /// @param lowerTickOfOrder         Lower tick of liquidity range
    /// @param upperTickOfOrder         Upper tick of liquidity range
    /// @param twPremiumX96              time weighted premium  
    /// @param twPremiumDivBySqrtPriceX96 time weighted premium div by sqrt price
    struct AddLiquidityParams {
        address trader;
        address baseToken;
        uint256 baseAmount;
        uint256 quoteAmount;
        int24 lowerTickOfOrder;
        int24 upperTickOfOrder;
        uint256 collateralForOrder;
        int256 twPremiumX96;
        int256 twPremiumDivBySqrtPriceX96;
    }

    /// @param baseAmount         The amount of base token added to the pool
    /// @param quoteAmount        The amount of quote token added to the pool
    /// @param liquidityAmount    The amount of liquidity recieved from the pool
    /// @param feeAmount          fees accured after adding liquidity.
    /// @param orderId            Order id for this liquidity position
    struct AddLiquidityResponse {
        uint256 baseAmount;
        uint256 quoteAmount;
        uint128 liquidityAmount;
        uint256 feeAmount;
        bytes32 orderId;
    }

    /// @param trader                  Trader Address
    /// @param baseToken               Base token address
    /// @param lowerTickOfOrder        Lower tick of liquidity range
    /// @param upperTickOfOrder        Upper tick of liquidity range
    /// @param liquidityAmount         Amount of liquidity you want to remove
    struct RemoveLiquidityParams {
        address trader;
        address baseToken;
        int24 lowerTickOfOrder;
        int24 upperTickOfOrder;
        uint128 liquidityAmount;
    }

    /// @param baseAmount       The amount of base token removed from the pool
    /// @param quoteAmount      The amount of quote token removed from the pool
    /// @param feeAmount        fees accured after removing liquidity.
    /// @param takerBaseAmount  The base amount which is different from what had been added
    /// @param takerQuoteAmount The quote amount which is different from what had been added
    /// @param orderId          order id for this liquidity position
    struct RemoveLiquidityResponse {
        uint256 baseAmount;
        uint256 quoteAmount;
        uint256 feeAmount;
        int256 takerBaseAmount;
        int256 takerQuoteAmount;
        bytes32 orderId;
    }

    /// @param baseToken               Base token address
    /// @param isShort                 True for opening short position,false for long
    /// @param shouldUpdateState       Update the state is true
    /// @param specifiedAmount         Amount entered by trader
    /// @param sqrtPriceLimitX96       Price limit same as uniswap V3
    /// @param swapFees             Uniswap fee will be ignored and use the swapFees instead
    /// @param uniswapFee              UniswapFee cache only
    /// @param twPremiumX96 updated time weighted premium
    /// @param twPremiumDivBySqrtPriceX96 updated time weighted premium div by sqrt price
    struct rSwapParams {
        address baseToken;
        bool isShort;
        bool shouldUpdateState;
        int256 specifiedAmount;
        uint160 sqrtPriceLimitX96;
        uint24 swapFees;
        uint24 uniswapFee;
        int256 twPremiumX96;
        int256 twPremiumDivBySqrtPriceX96;
    }

    /// @param tick       cureent tick 
    /// @param fee        fee will be charged.
    struct rSwapResponse {
        int24 tick;
        uint256 fee;
        uint256 insuranceFee;
    }

    struct MintCallbackData {
        address trader;
        address pool;
    }

    struct ReplaySwapParams {
        address baseToken;
        bool isShort;
        bool shouldUpdateState;
        int256 amount;
        uint160 sqrtPriceLimitX96;
        uint24 swapFees;
        uint24 uniswapFee;
    }

    struct ReplaySwapResponse {
        int24 tick;
        uint256 fee;
    }

    struct InternalSwapStep {
        uint160 initialSqrtPriceX96;
        int24 nextTick;
        bool isNextTickInitialized;
        uint160 nextSqrtPriceX96;
        uint256 amountIn;
        uint256 amountOut;
        uint256 fee;
    }

    /// @notice this event is emitted when Pnl is realized for any liquidity order
    /// @param orderId order id
    /// @param amount pnl amount
    event PnlRealized(
        bytes32 orderId,
        int256 amount
    );


    /// @notice Add liquidity logic
    /// @dev Only used by `Oddz Clearing House` contract
    /// @param params Add liquidity params, detail on `IOrderManager.AddLiquidityParams`
    /// @return response Response of add liquidity
    function addLiquidity(AddLiquidityParams calldata params)
        external
        returns (AddLiquidityResponse memory response);

    /** @notice Remove liquidity logic, only used by `Oddz Clearing House` contract
    *@param params Remove liquidity params, detail on `IOrderManager.RemoveLiquidityParams`
    *@return response Response of remove liquidity
     */ 
    function removeLiquidity(RemoveLiquidityParams calldata params)
        external
        returns (RemoveLiquidityResponse memory response);


    /** @notice This function is used to update the fundin payment of the order
    *   @param orderId order id
    *   @param amount funding amount
    */
    function updateLiquidityPositionOwedRealizedPnl(bytes32 orderId, int256 amount)
        external;

    /**@notice used to update funding growth variables for liquidity order and calculate liquidity coefficient
    * @param baseToken base token address
    * @param orderId order id
    * @param twPremiumX96 updated time weighted premium
    * @param twPremiumDivBySqrtPriceX96 updated time weighted premium div by sqrt price
    * @return liquidityCoefficientInFundingPayment liquidity coefficient value in funding payment
     */
    function updateFundingGrowthAndLiquidityCoefficientInFundingPayment(
        address baseToken,
        bytes32 orderId,
        int256 twPremiumX96,
        int256 twPremiumDivBySqrtPriceX96
    )external returns (int256 liquidityCoefficientInFundingPayment);

    
    /** @notice used to udpate the time weighted premium value of a liquidity position
    * @param orderId order id
    * @param twPremiumGrowthGlobalX96 new time weighted premium growth
     */
    function updateTwPremiumGrowthGlobal(
        bytes32 orderId,
        int256 twPremiumGrowthGlobalX96
    ) external;

    /** @notice Used to get all the order ids of the trader for that market
    * @param trader User address
    * @param baseToken base token address
    * @return orderIds all the order id of the user
    */
    function getCurrentOrderIdsMap(address trader, address baseToken)
        external
        view
        returns (bytes32[] memory orderIds);

    /** @notice Used to get all the order amounts in the pool
    * @param trader User address
    * @param baseToken base token address
    * @param base if true only include base token amount in pool otherwise only include quote token amount in pool
    * @return amountInPool Gives the total amount of a particular token in the pool for the user
    */
    function getTotalOrdersAmountInPool(
        address trader,
        address baseToken,
        bool base
    ) external view returns (uint256 amountInPool);


    /** @notice used to get total token amount in uniswap pool for particular liquidity order
    * @param orderId order id
    * @param base  true if want base amount , false if quote
    * @return orderAmount total Order amount(base or quote)
    */
    function getAmountInPoolByOrderId(bytes32 orderId, bool base)
        external
        view
        returns (uint256 orderAmount);

    /**
     * @notice Calculates current token amount inside the specific pool of uniswapV3Pool for a trader
     * @param baseToken base token address
     * @param orderId order id
     * @param base  true: get base amount, false: get quote amount
     * @return tokenAmountInPool returns all token inside pool amount for a particular token
     */
    function getCurrentTotalTokenAmountInPoolByOrderId(
        address baseToken,
        bytes32 orderId,
        bool base
    ) external view returns (uint256 tokenAmountInPool);

    /**
     *@notice  to get the total collateral used in orders
     *@param trader address of the trader
     *@return collateral total collateral
     */
    function getTotalCollateralForOrders(address trader)
        external
        view
        returns (uint256 collateral);

    /**
     *@notice  to get the info of the order
     *@param orderId order is of the liquidity position
     *@return info order info
     */
    function getCurrentOrderMap(bytes32 orderId)
        external
        view
        returns (OrderInfo memory info);

    /**@notice used to get liquidity coefficient
    * @param baseToken base token address
    * @param orderId order id
    * @param twPremiumX96 updated time weighted premium
    * @param twPremiumDivBySqrtPriceX96 updated time weighted premium div by sqrt price
    * @return liquidityCoefficientInFundingPayment liquidity coefficient value in funding payment
    */
    function getLiquidityCoefficientInFundingPayment(
        address baseToken,
        bytes32 orderId,
        int256 twPremiumX96,
        int256 twPremiumDivBySqrtPriceX96
    ) external view  returns (int256 liquidityCoefficientInFundingPayment);

    /**
     * @notice Calculates unique order ID
     * @param trader Address of the trader
     * @param baseToken Base token Address
     * @param lowerTick  Lower tick of liquidity range
     * @param upperTick  Upper tick of liquidity range
     * @return bytes32 unique hash/ID of that order
     */
    function calcOrderID(
        address trader,
        address baseToken,
        int24 lowerTick,
        int24 upperTick
    ) external pure returns (bytes32);

    function rSwap(
        rSwapParams memory params
    ) external  returns (rSwapResponse memory); 
    
    function fetchPendingFee(
       bytes32 orderId, address baseToken
    ) external view returns (uint256 totalPendingFee);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6;

interface IInsuranceManager {
    /**
    * @notice provide fund to vault in case of insufficient fund in vault
    * @dev this function is only calls in vault contract only.
    * @param _amount insurance manager wants to supply vault.
    */
    function borrowFund(uint256 _amount) external;

    function settlementToken() external view returns (address);

    function borrower() external view returns (address);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import  "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import  "./oddzOwnable.sol";

abstract contract OddzPausable is OddzOwnable, PausableUpgradeable {
    // __gap is reserved storage
    uint256[50] private __gap;


    function __OddzPausable_init() internal initializer {
        __OddzOwnable_init();
        __Pausable_init();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _msgSender() internal view virtual override returns (address payable) {
        return super._msgSender();
    }

    function _msgData() internal view virtual override returns (bytes memory) {
        return super._msgData();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;



/// @dev decimals of settlementToken token MUST be less than 18
library OddzSettlementTokenMath {


    function lte(
        uint256 settlementToken,
        // solhint-disable-next-line var-name-mixedcase
        uint256 amountX10_18,
        uint8 decimals
    ) internal pure returns (bool) {
        return parseSettlementToken(settlementToken, decimals) <= amountX10_18;
    }

    function lte(
        int256 settlementToken,
        // solhint-disable-next-line var-name-mixedcase
        int256 amountX10_18,
        uint8 decimals
    ) internal pure returns (bool) {
        return parseSettlementToken(settlementToken, decimals) <= amountX10_18;
    }

    function lt(
        uint256 settlementToken,
        // solhint-disable-next-line var-name-mixedcase
        uint256 amountX10_18,
        uint8 decimals
    ) internal pure returns (bool) {
        return parseSettlementToken(settlementToken, decimals) < amountX10_18;
    }

    function lt(
        int256 settlementToken,
        // solhint-disable-next-line var-name-mixedcase
        int256 amountX10_18,
        uint8 decimals
    ) internal pure returns (bool) {
        return parseSettlementToken(settlementToken, decimals) < amountX10_18;
    }

    function gt(
        uint256 settlementToken,
        // solhint-disable-next-line var-name-mixedcase
        uint256 amountX10_18,
        uint8 decimals
    ) internal pure returns (bool) {
        return parseSettlementToken(settlementToken, decimals) > amountX10_18;
    }

    function gt(
        int256 settlementToken,
        // solhint-disable-next-line var-name-mixedcase
        int256 amountX10_18,
        uint8 decimals
    ) internal pure returns (bool) {
        return parseSettlementToken(settlementToken, decimals) > amountX10_18;
    }

    function gte(
        uint256 settlementToken,
        // solhint-disable-next-line var-name-mixedcase
        uint256 amountX10_18,
        uint8 decimals
    ) internal pure returns (bool) {
        return parseSettlementToken(settlementToken, decimals) >= amountX10_18;
    }

    function gte(
        int256 settlementToken,
        // solhint-disable-next-line var-name-mixedcase
        int256 amountX10_18,
        uint8 decimals
    ) internal pure returns (bool) {
        return parseSettlementToken(settlementToken, decimals) >= amountX10_18;
    }

    // returns number with 18 decimals
    function parseSettlementToken(uint256 amount, uint8 decimals) internal pure returns (uint256) {
        return amount*(10**(18 - decimals));
    }

    // returns number with 18 decimals
    function parseSettlementToken(int256 amount, uint8 decimals) internal pure returns (int256) {
        return amount*(int256(10**(18 - decimals)));
    }

    // returns number with settlementToken's decimals
    function formatSettlementToken(uint256 amount, uint8 decimals) internal pure returns (uint256) {
        return amount/(10**(18 - decimals));
    }

    // returns number with settlementToken's decimals
    function formatSettlementToken(int256 amount, uint8 decimals) internal pure returns (int256) {
        return amount/(int256(10**(18 - decimals)));
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

abstract contract OddzOwnable is ContextUpgradeable {

    address public owner;
    address public nominatedOwner;

    // __gap is reserved storage for adding more variables
    uint256[50] private __gap;

    event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);

    /**
     * @dev Checks the current caller is owner or not.If not throws error
     */
    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable:Caller is not the owner");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __OddzOwnable_init() internal initializer {
        __Context_init();
        address deployer = _msgSender();
        owner = deployer;
        emit OwnershipTransferred(address(0), deployer);
    }

    /**
     * @dev For renouncing the ownership , After calling this ,ownership will be 
     *  transfered to zero address 
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        nominatedOwner = address(0);
    }

    /**
     * @dev for nominating a new owner.Can only be called by existing owner
     * @param _newOwner New owner address
     */
    function nominateNewOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Ownable: newOwner can not be zero addresss");
    
        require(_newOwner != owner, "Ownable: newOwner can not be same as current owner");
        // same as candidate
        require(_newOwner != nominatedOwner, "Ownable : already nominated");

        nominatedOwner = _newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`_candidate`).
     * Can only be called by the new owner.
     */
    function AcceptOwnership() external {
    
        require(nominatedOwner != address(0), "Ownable: No one is nominated");
        require(nominatedOwner == _msgSender(), "Ownable: You are not nominated");

        // emitting event first to avoid caching values
        emit OwnershipTransferred(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}
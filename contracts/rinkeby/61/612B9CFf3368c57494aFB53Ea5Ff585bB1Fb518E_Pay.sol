// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./uniswap/interfaces/ISwapRouter.sol";
import "./uniswap/interfaces/IQuoter.sol";
import "./interfaces/IMerchant.sol";
import "./interfaces/IPay.sol";
import "./ownership/Ownable.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/Address.sol";
import "./libraries/SafeMath.sol";


abstract contract BasePay is IPay, Ownable {

    uint256 public rate;

    uint256 public fixedRate;

    uint24 public poolFee = 3000;


    mapping(address => uint256) public tradeFeeOf;

    mapping(address => mapping(address => uint256)) public merchantFunds;

    mapping(address => mapping(string => address)) public merchantOrders;


    event Order(string orderId, uint256 paidAmount,address paidToken,uint256 orderAmount,address settleToken,uint256 fee,address merchant, address payer, bool isFixedRate);

    event Withdraw(address merchant, address settleToken, uint256 settleAmount, address settleAccount);

    event WithdrawTradeFee(address _token, uint256 _fee);


    receive() payable external {}


    function setRate(uint256 _newRate) external onlyOwner {
        rate = _newRate;
    }

    function setFixedRate(uint256 _newFixedRate) external onlyOwner {
        fixedRate = _newFixedRate;
    }

    function setPoolFee(uint24 _poolFee) external onlyOwner {
        poolFee = _poolFee;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./uniswap/interfaces/ISwapRouter.sol";
import "./uniswap/interfaces/IQuoter.sol";
import "./interfaces/IMerchant.sol";
import "./BasePay.sol";


contract Pay is BasePay {

    IMerchant public immutable iMerchant;

    ISwapRouter public immutable iSwapRouter;

    IQuoter public immutable iQuoter;

    address public immutable WETH9;


    constructor(address _iMerchant, address _iSwapRouter, address _iQuoter, address _WETH9){
        owner = msg.sender;
        iMerchant = IMerchant(_iMerchant);
        iSwapRouter = ISwapRouter(_iSwapRouter);
        iQuoter = IQuoter(_iQuoter);
        WETH9 = _WETH9;
    }

    function pay(
        string memory _orderId,
        uint256 _paiAmount,
        uint256 _orderAmount,
        address _merchant,
        address _currency
    ) external returns(bool) {

        require(_paiAmount > 0);
        require(_orderAmount > 0);
        require(address(0) == merchantOrders[_merchant][_orderId], "Order existed");
        require(iMerchant.isMerchant(_merchant), "Invalid merchant");
        require(iMerchant.validatorCurrency(_merchant, _currency), "Invalid token");
        require(IERC20(_currency).balanceOf(msg.sender) >= _paiAmount, "Balance insufficient");

        uint256 fee;

        TransferHelper.safeTransferFrom(_currency, msg.sender, address(this), _paiAmount);

        (uint256 usdcFee, uint256 tokenFee, bool isFixedRate) = getFee(_merchant, _orderAmount, _paiAmount);

        address settleToken = iMerchant.getSettleCurrency(_merchant);

        if (address(0) != settleToken) {

            if (_currency != settleToken) {
                _paiAmount = swapExactOutputSingle(_currency, _paiAmount, settleToken, _orderAmount);
            }

            fee = usdcFee;

            if (iMerchant.getAutoSettle(_merchant)) {

                _autoWithdraw(_merchant, settleToken, _orderAmount - fee);

            } else {

                merchantFunds[_merchant][settleToken] += (_orderAmount - fee);
            }

            tradeFeeOf[settleToken] += fee;

            emit Order(_orderId, _paiAmount, _currency, _orderAmount, settleToken, fee, _merchant, msg.sender, isFixedRate);

        } else {

            fee = tokenFee;

            if (iMerchant.getAutoSettle(_merchant)) {


                _autoWithdraw(_merchant, _currency, _paiAmount - fee);

            } else {

                merchantFunds[_merchant][_currency] += (_paiAmount - fee);

            }

            tradeFeeOf[_currency] += fee;

            emit Order(_orderId, _paiAmount, _currency, _orderAmount, _currency, fee, _merchant, msg.sender, isFixedRate);

        }

        merchantOrders[_merchant][_orderId] = msg.sender;

        return true;

    }

    function payWithETH(
        string memory _orderId,
        address _merchant,
        uint256 _orderAmount
    ) external payable returns(bool) {

        require(msg.value > 0);
        require(address(msg.sender).balance >= msg.value, "Balance insufficient");
        require(address(0) == merchantOrders[_merchant][_orderId], "Order existed");
        require(iMerchant.isMerchant(_merchant), "Invalid merchant");


        uint256 fee;

        uint256 _paiAmount = msg.value;

        (uint256 usdcFee, uint256 tokenFee, bool isFixedRate) = getFee(_merchant, _orderAmount, msg.value);

        address settleToken = iMerchant.getSettleCurrency(_merchant);

        if (address(0) != settleToken) {

            _paiAmount = swapExactOutputSingle(WETH9, msg.value, settleToken, _orderAmount);

            fee = usdcFee;

            if (iMerchant.getAutoSettle(_merchant)) {

                _autoWithdraw(_merchant, settleToken, _orderAmount - fee);

            } else {

                merchantFunds[_merchant][settleToken] += (_orderAmount - fee);
            }

            tradeFeeOf[settleToken] += fee;

            emit Order(_orderId, _paiAmount, WETH9, _orderAmount, settleToken, fee, _merchant, msg.sender, isFixedRate);

        } else {

            fee = tokenFee;

            if (iMerchant.getAutoSettle(_merchant)) {

                _autoWithdraw(_merchant, WETH9, _paiAmount - fee);

            } else {

                merchantFunds[_merchant][WETH9] += (_paiAmount - fee);

            }

            tradeFeeOf[WETH9] += fee;

            emit Order(_orderId, _paiAmount, WETH9, _orderAmount, WETH9, fee, _merchant, msg.sender, isFixedRate);

        }

        merchantOrders[_merchant][_orderId] = msg.sender;

        return true;

    }

    function claimToken(
        address _token,
        uint256 _amount,
        address _to
    ) external {

        require(address(0) != _token, "Invalid currency");
        require(iMerchant.isMerchant(msg.sender), "Invalid merchant");

        address settleAccount = _to;

        if(address(0) == _to) {
            settleAccount = iMerchant.getSettleAccount(msg.sender);
            if(address(0) == settleAccount) {
                settleAccount = msg.sender;
            }
        }

        _claim(settleAccount, _token, _amount, _to);

    }

    function claimEth(
        uint256 _amount,
        address _to
    ) external {

        require(iMerchant.isMerchant(msg.sender), "Invalid merchant");

        address settleAccount = _to;

        if(address(0) == _to) {
            settleAccount = iMerchant.getSettleAccount(msg.sender);
            if(address(0) == settleAccount) {
                settleAccount = msg.sender;
            }
        }

        _claim(settleAccount, address(0), _amount, _to);

    }

    function claimAllToken(address _to) external {

        require(iMerchant.isMerchant(msg.sender), "Invalid merchant");
        address[] memory merchantTokens = iMerchant.getMerchantTokens(msg.sender);

        for(uint i=0;i< merchantTokens.length; i++) {

            address token = merchantTokens[i];
            if (address(0) == token || merchantFunds[msg.sender][token] <= 0) {
                break;
            }

            _claim(msg.sender, token, merchantFunds[msg.sender][token], _to);

        }

    }

    function withdrawTradeFee(address _token) external onlyOwner {
        uint256 amount = tradeFeeOf[_token];
        if(address(0) == _token) {
            TransferHelper.safeTransferETH(msg.sender, amount);
        } else {
            TransferHelper.safeTransfer(_token, msg.sender, amount);
        }
        tradeFeeOf[_token] = 0;
        emit WithdrawTradeFee(_token, amount);
    }




    function _autoWithdraw(
        address _merchant,
        address _settleToken,
        uint256 _settleAmount
    ) internal {

        address settleAccount = iMerchant.getSettleAccount(_merchant);

        if(address(0) == settleAccount) {
            settleAccount = _merchant;
        }

        if(WETH9 != _settleToken) {
            TransferHelper.safeTransfer(_settleToken, settleAccount, _settleAmount);
        } else {
            TransferHelper.safeTransferETH(settleAccount, _settleAmount);
        }

        emit Withdraw(_merchant, _settleToken, _settleAmount, settleAccount);

    }

    function getFee(address _merchant, uint256 _orderAmount, uint256 _paidAmount) internal view returns (uint256 usdcFee,uint256 tokenFee, bool isFixedRate) {

        isFixedRate = iMerchant.getFixedRate(_merchant);
        if(isFixedRate) {

            tokenFee = SafeMath.div(SafeMath.mul(_paidAmount, fixedRate), _orderAmount);

            usdcFee = fixedRate;

            return(usdcFee, tokenFee, isFixedRate);

        } else {

            usdcFee = SafeMath.div((SafeMath.mul(_orderAmount ,rate)), 10000);

            tokenFee = SafeMath.div((SafeMath.mul(_paidAmount ,rate)), 10000);

            return (usdcFee, tokenFee, isFixedRate);

        }

    }

    function _claim(
        address _merchant,
        address _currency,
        uint256 _amount,
        address _settleAccount
    ) private {

        require(merchantFunds[_merchant][_currency] >= _amount);

        if(address(0) != _currency) {
            TransferHelper.safeTransfer(_currency, _settleAccount, _amount);
        } else {
            TransferHelper.safeTransferETH(_settleAccount, _amount);
        }

        merchantFunds[_merchant][_currency] -= _amount;

        emit Withdraw(_merchant, _currency, _amount, _settleAccount);

    }

    function swapExactOutputSingle(
        address _tokenIn,
        uint256 _amountInMaximum,
        address _tokenOut,
        uint256 _amountOut
    ) private returns(uint256 _amountIn) {

        if(WETH9 != _tokenIn) {
            TransferHelper.safeApprove(_tokenIn, address(iSwapRouter), _amountInMaximum);
        }

        ISwapRouter.ExactOutputSingleParams memory params =
        ISwapRouter.ExactOutputSingleParams({
        tokenIn: _tokenIn,
        tokenOut: _tokenOut,
        fee: poolFee,
        recipient: address(this) ,
        deadline: block.timestamp,
        amountOut: _amountOut,
        amountInMaximum: _amountInMaximum,
        sqrtPriceLimitX96: 0
        });

        _amountIn = iSwapRouter.exactOutputSingle{value:msg.value}(params);

        if (_amountIn < _amountInMaximum) {
            if(WETH9 == _tokenIn) {
                iSwapRouter.refundETH();
                if(address(msg.sender).balance >= (_amountInMaximum - _amountIn)) {
                    (bool success,) = msg.sender.call{ value: (_amountInMaximum - _amountIn) }("");
                    require(success, "refund failed");
                }
            } else {
                TransferHelper.safeApprove(_tokenIn, address(iSwapRouter), 0);
                TransferHelper.safeTransfer(_tokenIn, msg.sender, _amountInMaximum - _amountIn);
            }
        }

    }

    function getEstimated(address tokenIn, address tokenOut, uint256 amountOut) external payable returns (uint256) {

        return iQuoter.quoteExactOutputSingle(
            tokenIn,
            tokenOut,
            poolFee,
            amountOut,
            0
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns(uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMerchant {

    struct MerchantInfo {
        address account;
        address payable settleAccount;
        address settleCurrency;
        bool autoSettle;
        bool isFixedRate;
        address [] tokens;
    }

    function isMerchant(address _merchant) external view returns(bool);

    function addMerchant(address payable _settleAccount, address _settleCurrency, bool _autoSettle, bool _isFixedRate, address[] memory _tokens) external;

    function setMerchantToken(address[] memory _tokens) external;

    function getMerchantTokens(address _merchant) external view returns(address[] memory);

    function setSettleCurrency(address payable _currency) external;

    function getSettleCurrency(address _merchant) external view returns (address);

    function setSettleAccount(address payable _account) external;

    function getSettleAccount(address _account) external view returns(address);

    function setAutoSettle(bool _autoSettle) external;

    function getAutoSettle(address _merchant) external view returns (bool);

    function setFixedRate(bool _fixedRate) external;

    function getFixedRate(address _merchant) external view returns(bool);

    function validatorCurrency(address _merchant, address _currency) external view returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPay {

    function pay(
        string memory _orderId,
        uint256 _amountMax,
        uint256 _orderAmount,
        address _merchant,
        address _currency
    ) external returns(bool);

    function payWithETH(string memory _orderId, address _merchant, uint256 _orderAmount) external payable returns(bool);

    function claimEth(uint256 _amount, address _to) external;

    function claimToken(address _token, uint256 _amount, address _to) external;

    function claimAllToken(address _to) external;

    function withdrawTradeFee(address _token) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
        token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev The contract has an owner address, and provides basic authorization control whitch
 * simplifies the implementation of user permissions. This contract is based on the source code at:
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ownership/Ownable.sol
 */
contract Ownable {

    /**
     * @dev Error constants.
     */
    string public constant NOT_CURRENT_OWNER = "018001";
    string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = "018002";

    /**
     * @dev Current owner address.
     */
    address public owner;

    /**
     * @dev An event which is triggered when the owner is changed.
     * @param previousOwner The address of the previous owner.
     * @param newOwner The address of the new owner.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The constructor sets the original `owner` of the contract to the sender account.
     */
    constructor(){
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner(){
        require(msg.sender == owner, NOT_CURRENT_OWNER);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IUniswapV3SwapCallback.sol";

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24  fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);

    function refundETH() external payable;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}
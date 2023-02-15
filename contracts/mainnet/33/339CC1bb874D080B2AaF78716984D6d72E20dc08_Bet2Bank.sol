/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

// SPDX-License-Identifier: MIT                                                                               

//Betting Redefined - GET IN THE GAME
//TG: https://t.me/Bet2Bank
//TG Announcement: https://t.me/Bet2BankANN
//Twitter: https://twitter.com/Bet2BankBXB
//Website: https://www.bet2bank.io/

pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amt) internal {
        require(address(this).balance >= amt, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amt}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amt) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amt) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amt) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is Context, IERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amt) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amt);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amt) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amt);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amt) public virtual override returns (bool) {
        _transfer(sender, recipient, amt);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amt, "ERC20: transfer amt exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amt);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amt) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amt, "ERC20: transfer amt exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amt;
        }
        _balances[recipient] += amt;

        emit Transfer(sender, recipient, amt);
    }

    function _createInitialSupply(address account, uint256 amt) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amt;
        _balances[account] += amt;
        emit Transfer(address(0), account, amt);
    }

    function _approve(address owner, address spender, uint256 amt) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amt;
        emit Approval(owner, spender, amt);
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB);
}

interface DividendPayingTokenOptionalInterface {
  /// @notice View the amt of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amt of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amt of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amt of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) external view returns(uint256);

  /// @notice View the amt of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// @param _owner The address of a token holder.
  /// @return The amt of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) external view returns(uint256);
}

interface DividendPayingTokenInterface {
  /// @notice View the amt of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amt of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) external view returns(uint256);

  /// @notice Distributes ether to token holders as dividends.
  /// @dev SHOULD distribute the paid ether to token holders as dividends.
  ///  SHOULD NOT directly transfer ether to token holders in this function.
  ///  MUST emit a `DividendsDistributed` event when the amt of distributed ether is greater than 0.
  function distributeDividends() external payable;

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev SHOULD transfer `dividendOf(msg.sender)` wei to `msg.sender`, and `dividendOf(msg.sender)` SHOULD be 0 after the transfer.
  ///  MUST emit a `DividendWithdrawn` event if the amt of ether transferred is greater than 0.
  function withdrawDividend() external;

  /// @dev This event MUST emit when ether is distributed to token holders.
  /// @param from The address which sends ether to this contract.
  /// @param weiAmt The amt of distributed ether in wei.
  event DividendsDistributed(
    address indexed from,
    uint256 weiAmt
  );

  /// @dev This event MUST emit when an address withdraws their dividend.
  /// @param to The address which withdraws ether from this contract.
  /// @param weiAmt The amt of withdrawn ether in wei.
  event DividendWithdrawn(
    address indexed to,
    uint256 weiAmt
  );
}

library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

contract DividendPayingToken is DividendPayingTokenInterface, DividendPayingTokenOptionalInterface, Ownable {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  // With `magnitude`, we can properly distribute dividends even if the amt of received ether is small.
  // For more discussion about choosing the value of `magnitude`,
  //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
  uint256 constant internal magnitude = 2**128;

  uint256 internal magnifiedDividendPerShare;
 
  address public token;
  
  // About dividendCorrection:
  // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
  // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
  //   `dividendOf(_user)` should not be changed,
  //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
  // To keep the `dividendOf(_user)` unchanged, we add a correction term:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
  //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
  //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
  // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;
  
  mapping (address => uint256) public holderBalance;
  uint256 public totalBalance;

  uint256 public totalDividendsDistributed;

  /// @dev Distributes dividends whenever ether is paid to this contract.
  receive() external payable {
    distributeDividends();
  }

  /// @notice Distributes ether to token holders as dividends.
  /// @dev It reverts if the total supply of tokens is 0.
  /// It emits the `DividendsDistributed` event if the amt of received ether is greater than 0.
  /// About undistributed ether:
  ///   In each distribution, there is a small amt of ether not distributed,
  ///     the magnified amt of which is
  ///     `(msg.value * magnitude) % totalSupply()`.
  ///   With a well-chosen `magnitude`, the amt of undistributed ether
  ///     (de-magnified) in a distribution can be less than 1 wei.
  ///   We can actually keep track of the undistributed ether in a distribution
  ///     and try to distribute it in the next distribution,
  ///     but keeping track of such data on-chain costs much more than
  ///     the saved ether, so we don't do that.
    
  function distributeDividends() public override payable {
    require(false, "Cannot send BNB directly to tracker as it is unrecoverable"); // 
  }
  
  function distributeTokenDividends(uint256 amt) public onlyOwner {
    require(totalBalance > 0);

        if (amt > 0) {
        magnifiedDividendPerShare = magnifiedDividendPerShare.add(
            (amt).mul(magnitude) / totalBalance
        );
        emit DividendsDistributed(msg.sender, amt);

        totalDividendsDistributed = totalDividendsDistributed.add(amt);
        }
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amt of withdrawn ether is greater than 0.
  function withdrawDividend() public virtual override {
    _withdrawDividendOfUser(payable(msg.sender));
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amt of withdrawn ether is greater than 0.
  function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
      emit DividendWithdrawn(user, _withdrawableDividend);
      SafeERC20.safeTransfer(IERC20(token), user, _withdrawableDividend);

      return _withdrawableDividend;
    }

    return 0;
  }


  /// @notice View the amt of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amt of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) public view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }

  /// @notice View the amt of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amt of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) public view override returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

  /// @notice View the amt of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amt of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) public view override returns(uint256) {
    return withdrawnDividends[_owner];
  }


  /// @notice View the amt of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
  /// @param _owner The address of a token holder.
  /// @return The amt of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    return magnifiedDividendPerShare.mul(holderBalance[_owner]).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }

  /// @dev Internal function that increases tokens to an account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account that will receive the created tokens.
  /// @param value The amt that will be created.
  function _increase(address account, uint256 value) internal {
    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  /// @dev Internal function that reduces an amt of the token of a given account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account whose tokens will be burnt.
  /// @param value The amt that will be burnt.
  function _reduce(address account, uint256 value) internal {
    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = holderBalance[account];
    holderBalance[account] = newBalance;
    if(newBalance > currentBalance) {
      uint256 increaseAmt = newBalance.sub(currentBalance);
      _increase(account, increaseAmt);
      totalBalance += increaseAmt;
    } else if(newBalance < currentBalance) {
      uint256 reduceAmt = currentBalance.sub(newBalance);
      _reduce(account, reduceAmt);
      totalBalance -= reduceAmt;
    }
  }
}

contract DividendTracker is DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public immutable minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event IncludeInDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amt, bool indexed automatic);

    constructor(address _token) {
    	claimWait = 1200;
        minimumTokenBalanceForDividends = 1;
        token = _token;
    }

    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(address key) private view returns (uint) {
        return tokenHoldersMap.values[key];
    }

    function getIndexOfKey(address key) private view returns (int) {
        if(!tokenHoldersMap.inserted[key]) {
            return -1;
        }
        return int(tokenHoldersMap.indexOf[key]);
    }

    function getKeyAtIndex(uint index) private view returns (address) {
        return tokenHoldersMap.keys[index];
    }



    function size() private view returns (uint) {
        return tokenHoldersMap.keys.length;
    }

    function set(address key, uint val) private {
        if (tokenHoldersMap.inserted[key]) {
            tokenHoldersMap.values[key] = val;
        } else {
            tokenHoldersMap.inserted[key] = true;
            tokenHoldersMap.values[key] = val;
            tokenHoldersMap.indexOf[key] = tokenHoldersMap.keys.length;
            tokenHoldersMap.keys.push(key);
        }
    }

    function remove(address key) private {
        if (!tokenHoldersMap.inserted[key]) {
            return;
        }

        delete tokenHoldersMap.inserted[key];
        delete tokenHoldersMap.values[key];

        uint index = tokenHoldersMap.indexOf[key];
        uint lastIndex = tokenHoldersMap.keys.length - 1;
        address lastKey = tokenHoldersMap.keys[lastIndex];

        tokenHoldersMap.indexOf[lastKey] = index;
        delete tokenHoldersMap.indexOf[key];

        tokenHoldersMap.keys[index] = lastKey;
        tokenHoldersMap.keys.pop();
    }

    function excludeFromDividends(address account) external onlyOwner {
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	remove(account);

    	emit ExcludeFromDividends(account);
    }
    
    function includeInDividends(address account) external onlyOwner {
    	require(excludedFromDividends[account]);
    	excludedFromDividends[account] = false;

    	emit IncludeInDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 1200 && newClaimWait <= 86400, "Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;


                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }


        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime.add(claimWait) :
                                    0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
    }

    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	if(index >= size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    	if(lastClaimTime > block.timestamp)  {
    		return false;
    	}

    	return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    	if(excludedFromDividends[account]) {
    		return;
    	}

    	if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
    		set(account, newBalance);
    	}
    	else {
            _setBalance(account, 0);
    		remove(account);
    	}

    	processAccount(account, true);
    }
    
    
    function process(uint256 gas) public returns (uint256, uint256, uint256) {
    	uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

    	if(numberOfTokenHolders == 0) {
    		return (0, 0, lastProcessedIndex);
    	}

    	uint256 _lastProcessedIndex = lastProcessedIndex;

    	uint256 gasUsed = 0;

    	uint256 gasLeft = gasleft();

    	uint256 iterations = 0;
    	uint256 claims = 0;

    	while(gasUsed < gas && iterations < numberOfTokenHolders) {
    		_lastProcessedIndex++;

    		if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
    			_lastProcessedIndex = 0;
    		}

    		address account = tokenHoldersMap.keys[_lastProcessedIndex];

    		if(canAutoClaim(lastClaimTimes[account])) {
    			if(processAccount(payable(account), true)) {
    				claims++;
    			}
    		}

    		iterations++;

    		uint256 newGasLeft = gasleft();

    		if(gasLeft > newGasLeft) {
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
    		}
    		gasLeft = newGasLeft;
    	}

    	lastProcessedIndex = _lastProcessedIndex;

    	return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amt = _withdrawDividendOfUser(account);

    	if(amt > 0) {
    		lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amt, automatic);
    		return true;
    	}

    	return false;
    }
}

interface IDexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface ILpPair {
    function sync() external;
}

contract TokenHandler is Ownable {
    function sendTokenToOwner(address token) external onlyOwner {
        if(IERC20(token).balanceOf(address(this)) > 0){
            SafeERC20.safeTransfer(IERC20(token), owner(), IERC20(token).balanceOf(address(this)));
        }
    }
}

contract Bet2Bank is ERC20, Ownable {

    uint256 public maxBuyAmt;
    uint256 public maxSellAmt;
    uint256 public maxWalletAmt;

    DividendTracker public immutable dividendTracker;
    address public immutable token;

    IDexRouter public immutable dexRouter;
    address public immutable lpPair;

    IERC20 public immutable PAIREDTOKEN; 

    bool private swapping;
    uint256 public swapTokensAtAmt;

    TokenHandler public tokenHandler;

    address public marketingAndBuybacksAddress;
    address public developmentAddress;
    address public futureOwnerAddress;

    uint256 public tradingLiveBlock = 0; // 0 means trading is not active

    bool public limitsActive = true;
    bool public tradingLive = false;
    bool public swapEnabled = false;

    uint256 public constant FEE_DIVISOR = 10000;

    uint256 public buyTotalTax;
    uint256 public buyLiquidityTax;
    uint256 public buyMarketingAndBuybacksTax;
    uint256 public buyDevelopmentTax;
    uint256 public buyRewardTax;

    uint256 public sellTotalTax;
    uint256 public sellMarketingAndBuybacksTax;
    uint256 public sellLiquidityTax;
    uint256 public sellDevelopmentTax;
    uint256 public sellRewardTax;

    uint256 public tokensForMarketingAndBuybacks;
    uint256 public tokensForLiquidity;
    uint256 public tokensForDevelopment;
    uint256 public tokensForReward;
    
    mapping (address => bool) private _isExcludedFromTax;
    mapping (address => bool) public _isExcludedMaxTransactionAmt;

    mapping (address => bool) public automatedMarketMakerPairs;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event StartedTrading();
    event RemovedLimits();
    event ExcludeFromTax(address indexed account, bool isExcluded);
    event UpdatedMaxBuyAmt(uint256 newAmt);
    event UpdatedMaxSellAmt(uint256 newAmt);
    event UpdatedMaxWalletAmt(uint256 newAmt);
    event UpdatedBuyTax(uint256 newAmt);
    event UpdatedSellTax(uint256 newAmt);
    event UpdatedMarketingAndBuybacksAddress(address indexed newWallet);
    event UpdatedRewardsAddress(address indexed newWallet);
    event UpdatedDevelopmentAddress(address indexed newWallet);
    event UpdatedLiquidityAddress(address indexed newWallet);
    event MaxTransactionExclusion(address _address, bool excluded);
    event OwnerForcedSwapBack(uint256 timestamp);
    event CaughtEarlyBuyer(address sniper);
    event TransferForeignToken(address token, uint256 amt);

    constructor() ERC20("Bet2Bank", "BXB") {

        address stablecoinAddress;
        address _dexRouter;

        if(block.chainid == 1){
            stablecoinAddress  = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC
            _dexRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Ethereum: Uniswap V2
        } else if(block.chainid == 5){
            stablecoinAddress = 0x2f3A40A3db8a7e3D09B0adfEfbCe4f6F81927557; // Goerli USDC
            _dexRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Goerli Router
        } else {
            revert("Chain not configured");
        }

        token = stablecoinAddress;
        dividendTracker = new DividendTracker(token);

        PAIREDTOKEN = IERC20(stablecoinAddress);
        require(PAIREDTOKEN.decimals()  > 0 , "Incorrect liquidity token");

        address newOwner = msg.sender; // can leave alone if owner is deployer.

        dexRouter = IDexRouter(_dexRouter);

        // create pair
        lpPair = IDexFactory(dexRouter.factory()).createPair(address(this), address(PAIREDTOKEN));
        setAutomatedMarketMakerPair(address(lpPair), true);

        address ethPair = IDexFactory(dexRouter.factory()).createPair(address(this), dexRouter.WETH());
        setAutomatedMarketMakerPair(address(ethPair), true);

        uint256 totalSupply = 100 * 1e9 * 1e18;
        
        maxBuyAmt = totalSupply * 1 / 100;
        maxSellAmt = totalSupply * 2 / 100;
        maxWalletAmt = totalSupply * 2 / 100;
        swapTokensAtAmt = totalSupply * 25 / 100000;

        tokenHandler = new TokenHandler();

        buyMarketingAndBuybacksTax = 200;
        buyLiquidityTax = 100;
        buyDevelopmentTax = 100;
        buyRewardTax = 200;
        buyTotalTax = buyMarketingAndBuybacksTax + buyLiquidityTax + buyDevelopmentTax + buyRewardTax;

        sellMarketingAndBuybacksTax = 200;
        sellLiquidityTax = 100;
        sellDevelopmentTax = 100;
        sellRewardTax = 200;
        sellTotalTax = sellMarketingAndBuybacksTax + sellLiquidityTax + sellDevelopmentTax + sellRewardTax;

        // @dev update these!
        marketingAndBuybacksAddress = address(msg.sender);
        developmentAddress = address(msg.sender);
        futureOwnerAddress = address(msg.sender);

        _excludeFromMaxTransaction(newOwner, true);
        _excludeFromMaxTransaction(futureOwnerAddress, true);
        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(address(dexRouter), true);
        _excludeFromMaxTransaction(address(0xdead), true);
        _excludeFromMaxTransaction(address(marketingAndBuybacksAddress), true);
        _excludeFromMaxTransaction(address(developmentAddress), true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(address(dexRouter));
        dividendTracker.excludeFromDividends(newOwner);
        dividendTracker.excludeFromDividends(address(dexRouter));
        dividendTracker.excludeFromDividends(address(0xdead));

        excludeFromTax(newOwner, true);
        excludeFromTax(futureOwnerAddress, true);
        excludeFromTax(address(this), true);
        excludeFromTax(address(dexRouter), true);
        excludeFromTax(address(0xdead), true);
        excludeFromTax(address(marketingAndBuybacksAddress), true);
        excludeFromTax(address(developmentAddress), true);

        _createInitialSupply(address(newOwner), totalSupply);
        transferOwnership(newOwner);

        PAIREDTOKEN.approve(address(dexRouter), type(uint256).max);
        _approve(address(this), address(dexRouter), type(uint256).max);
    }

    function updateAllowanceForSwapping() external {
        PAIREDTOKEN.approve(address(dexRouter), type(uint256).max);
        _approve(address(this), address(dexRouter), type(uint256).max);
    }

    function startTrading() external onlyOwner {
        require(!tradingLive, "Trading is already active, cannot relaunch.");
        tradingLive = true;
        swapEnabled = true;
        tradingLiveBlock = block.number;
        emit StartedTrading();
    }

    // excludes wallets and contracts from dividends (such as CEX hotwallets, etc.)
    function excludeFromDividends(address account) external onlyOwner {
        dividendTracker.excludeFromDividends(account);
    }

    // removes exclusion on wallets and contracts from dividends (such as CEX hotwallets, etc.)
    function includeInDividends(address account) external onlyOwner {
        dividendTracker.includeInDividends(account);
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner {
        limitsActive = false;
        emit RemovedLimits();
    }

    function updateMaxBuyAmt(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 1 / 100)/1e18, "Cannot set max sell amt lower than 1%");
        maxBuyAmt = newNum * (10**18);
        emit UpdatedMaxBuyAmt(maxBuyAmt);
    }
    
    function updateMaxSellAmt(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 1 / 100)/1e18, "Cannot set max sell amt lower than 1%");
        maxSellAmt = newNum * (10**18);
        emit UpdatedMaxSellAmt(maxSellAmt);
    }

    function removeMaxWallet() external onlyOwner {
        maxWalletAmt = totalSupply();
        emit UpdatedMaxWalletAmt(maxWalletAmt);
    }

    function updateSwapTokensAtAmt(uint256 newAmt) external onlyOwner {
  	    require(newAmt >= totalSupply() * 1 / 1000000, "Swap amt cannot be lower than 0.0001% total supply.");
  	    require(newAmt <= totalSupply() * 1 / 1000, "Swap amt cannot be higher than 0.1% total supply.");
  	    swapTokensAtAmt = newAmt;
  	}
    
    function _excludeFromMaxTransaction(address updAds, bool isExcluded) private {
        _isExcludedMaxTransactionAmt[updAds] = isExcluded;
        emit MaxTransactionExclusion(updAds, isExcluded);
    }

    function airdropToWallets(address[] memory wallets, uint256[] memory amountsInWei) external onlyOwner {
        require(wallets.length == amountsInWei.length, "arrays must be the same length");
        require(wallets.length < 600, "Can only airdrop 600 wallets per txn due to gas limits");
        for(uint256 i = 0; i < wallets.length; i++){
            super._transfer(msg.sender, wallets[i], amountsInWei[i]);
            dividendTracker.setBalance(payable(wallets[i]), balanceOf(wallets[i]));
        }
    }
    
    function excludeFromMaxTransaction(address updAds, bool isEx) external onlyOwner {
        if(!isEx){
            require(updAds != lpPair, "Cannot remove uniswap pair from max txn");
        }
        _isExcludedMaxTransactionAmt[updAds] = isEx;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != lpPair || value, "The pair cannot be removed from automatedMarketMakerPairs");
        automatedMarketMakerPairs[pair] = value;
        _excludeFromMaxTransaction(pair, value);
        if(value) {
            dividendTracker.excludeFromDividends(pair);
        }
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateBuyTax(uint256 _marketingAndBuybacksTax, uint256 _liquidityTax, uint256 _developmentTax, uint256 _rewardTax) external onlyOwner {
        buyMarketingAndBuybacksTax = _marketingAndBuybacksTax;
        buyLiquidityTax = _liquidityTax;
        buyDevelopmentTax = _developmentTax;
        buyRewardTax = _rewardTax;
        buyTotalTax = buyMarketingAndBuybacksTax + buyLiquidityTax + buyDevelopmentTax;
        emit UpdatedBuyTax(buyTotalTax);
    }

    function updateSellTax(uint256 _marketingAndBuybacksTax, uint256 _liquidityTax, uint256 _developmentTax, uint256 _rewardTax) external onlyOwner {
        sellMarketingAndBuybacksTax = _marketingAndBuybacksTax;
        sellLiquidityTax = _liquidityTax;
        sellDevelopmentTax = _developmentTax;
        sellRewardTax = _rewardTax;
        sellTotalTax = sellMarketingAndBuybacksTax + sellLiquidityTax + sellDevelopmentTax + sellRewardTax;
        emit UpdatedSellTax(sellTotalTax);
    }

    function excludeFromTax(address account, bool excluded) public onlyOwner {
        _isExcludedFromTax[account] = excluded;
        emit ExcludeFromTax(account, excluded);
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
    	return dividendTracker.withdrawableDividendOf(account);
  	}

	function dividendTokenBalanceOf(address account) public view returns (uint256) {
		return dividendTracker.holderBalance(account);
	}

    function getAccountDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendTracker.getAccount(account);
    }

	function getAccountDividendsInfoAtIndex(uint256 index)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	return dividendTracker.getAccountAtIndex(index);
    }

    function claim() external {
		dividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }
    
    function getNumberOfDividends() external view returns(uint256) {
        return dividendTracker.totalBalance();
    }
    
    function _transfer(address from, address to, uint256 amt) internal override {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        if(amt == 0){
            super._transfer(from, to, 0);
            return;
        }
        
        if(!tradingLive){
            require(_isExcludedFromTax[from] || _isExcludedFromTax[to], "Trading is not active.");
        }

        if(_isExcludedFromTax[from] || _isExcludedFromTax[to] || swapping){
            super._transfer(from, to, amt);
            dividendTracker.setBalance(payable(from), balanceOf(from));
            dividendTracker.setBalance(payable(to), balanceOf(to));
            return;
        }
        
        if(limitsActive){
            if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !_isExcludedFromTax[from] && !_isExcludedFromTax[to]){
                //when buy
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmt[to]) {
                    require(amt <= maxBuyAmt, "Buy transfer amt exceeds the max buy.");
                    require(amt + balanceOf(to) <= maxWalletAmt, "Cannot Exceed max wallet");
                } 
                //when sell
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmt[from]) {
                    require(amt <= maxSellAmt, "Sell transfer amt exceeds the max sell.");
                } 
                else if (!_isExcludedMaxTransactionAmt[to]){
                    require(amt + balanceOf(to) <= maxWalletAmt, "Cannot Exceed max wallet");
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmt;

        if(canSwap && swapEnabled && !swapping && automatedMarketMakerPairs[to]) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        bool takeTax = true;
        // if any account belongs to _isExcludedFromTax account then remove the tax
        if(_isExcludedFromTax[from] || _isExcludedFromTax[to]) {
            takeTax = false;
        }
        
        uint256 tax = 0;
        // only take tax on buys/sells, do not take on wallet transfers
        if(takeTax){
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalTax > 0){
                tax = amt * sellTotalTax / FEE_DIVISOR;
                tokensForLiquidity += tax * sellLiquidityTax / sellTotalTax;
                tokensForMarketingAndBuybacks += tax * sellMarketingAndBuybacksTax / sellTotalTax;
                tokensForDevelopment += tax * sellDevelopmentTax / sellTotalTax;
                tokensForReward += tax * sellRewardTax / sellTotalTax;
            }

            // on buy
            else if(automatedMarketMakerPairs[from] && buyTotalTax > 0) {
        	    tax = amt * buyTotalTax / FEE_DIVISOR;
        	    tokensForMarketingAndBuybacks += tax * buyMarketingAndBuybacksTax / buyTotalTax;
        	    tokensForLiquidity += tax * buyLiquidityTax / buyTotalTax;
                tokensForDevelopment += tax * buyDevelopmentTax / buyTotalTax;
                tokensForReward += tax * buyRewardTax / buyTotalTax;
            }
            
            if(tax > 0){    
                super._transfer(from, address(this), tax);
            }
        	
        	amt -= tax;
        }

        super._transfer(from, to, amt);

        dividendTracker.setBalance(payable(from), balanceOf(from));
        dividendTracker.setBalance(payable(to), balanceOf(to));
    }

    function swapTokensForPAIREDTOKEN(uint256 tokenAmt) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(PAIREDTOKEN);

        // make the swap
        dexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmt,
            0, // accept any amt of ETH
            path,
            address(tokenHandler),
            block.timestamp
        );

        tokenHandler.sendTokenToOwner(address(PAIREDTOKEN));
    }

    function swapBack() private {

        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForMarketingAndBuybacks + tokensForDevelopment + tokensForReward;
        
        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if(contractBalance > swapTokensAtAmt * 40){
            contractBalance = swapTokensAtAmt * 40;
        }
        
        if(tokensForLiquidity > 0){
            uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap;
            super._transfer(address(this), lpPair, liquidityTokens);
            try ILpPair(lpPair).sync(){} catch {}
            contractBalance -= liquidityTokens;
            totalTokensToSwap -= tokensForLiquidity;
            tokensForLiquidity = 0;
        }
        
        swapTokensForPAIREDTOKEN(contractBalance);
        
        uint256 stablecoinBalance = PAIREDTOKEN.balanceOf(address(this));

        uint256 stablecoinForDevelopment = stablecoinBalance * tokensForDevelopment / totalTokensToSwap;
        uint256 stablecoinForReward = stablecoinBalance * tokensForReward / totalTokensToSwap;
            
        tokensForMarketingAndBuybacks = 0;
        tokensForDevelopment = 0;
        tokensForReward = 0;

        if(stablecoinForDevelopment > 0){
            SafeERC20.safeTransfer(PAIREDTOKEN, developmentAddress, stablecoinForDevelopment);
        }

        if(stablecoinForReward > 0){
            SafeERC20.safeTransfer(PAIREDTOKEN, address(dividendTracker), stablecoinForReward);
            dividendTracker.distributeTokenDividends(stablecoinForReward);
        }

        if(PAIREDTOKEN.balanceOf(address(this)) > 0){
            SafeERC20.safeTransfer(PAIREDTOKEN, marketingAndBuybacksAddress, PAIREDTOKEN.balanceOf(address(this)));
        }
    }

    function setMarketingAndBuybacksAddress(address _marketingAndBuybacksAddress) external onlyOwner {
        require(_marketingAndBuybacksAddress != address(0), "address cannot be 0");
        marketingAndBuybacksAddress = payable(_marketingAndBuybacksAddress);
        emit UpdatedMarketingAndBuybacksAddress(_marketingAndBuybacksAddress);
    }

    function setDevelopmentAddress(address _developmentAddress) external onlyOwner {
        require(_developmentAddress != address(0), "address cannot be 0");
        developmentAddress = payable(_developmentAddress);
        emit UpdatedDevelopmentAddress(_developmentAddress);
    }

    // force Swap back if slippage issues.
    function forceSwapBack() external onlyOwner {
        require(balanceOf(address(this)) >= swapTokensAtAmt, "Can only swap when token amt is at or higher than restriction");
        swapping = true;
        swapBack();
        swapping = false;
        emit OwnerForcedSwapBack(block.timestamp);
    }

    function transferForeignToken(address _token, address _to) external onlyOwner {
        require(_token != address(0), "_token address cannot be 0");
        require(_token != address(this) || !tradingLive, "Can't withdraw native tokens");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        SafeERC20.safeTransfer(IERC20(_token),_to, _contractBalance);
        emit TransferForeignToken(_token, _contractBalance);
    }
}
/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

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
    require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

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
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

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
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != accountHash && codehash != 0x0);
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
  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return _functionCallWithValue(target, data, 0, errorMessage);
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
    return _functionCallWithValue(target, data, value, errorMessage);
  }

  function _functionCallWithValue(
    address target,
    bytes memory data,
    uint256 weiValue,
    string memory errorMessage
  ) private returns (bytes memory) {
    require(isContract(target), "Address: call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

library SafeERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  /**
   * @dev Deprecated. This function has issues similar to the ones found in
   * {IERC20-approve}, and its usage is discouraged.
   *
   * Whenever possible, use {safeIncreaseAllowance} and
   * {safeDecreaseAllowance} instead.
   */
  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    // safeApprove should only be called when setting an initial allowance,
    // or when resetting it to zero. To increase and decrease it, use
    // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
    // solhint-disable-next-line max-line-length
    require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
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
    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }
}

contract Ownable {
  address payable _owner;

  event OwnerSet(address indexed previousOwner, address indexed newOwner);

  function isOwner(address account) public view returns (bool) {
    return account == _owner;
  }

  constructor() {
    _owner = msg.sender;
    emit OwnerSet(address(0), msg.sender);
  }

  modifier onlyOwner() {
    require(isOwner(msg.sender), "Ownable: caller is not the owner");
    _;
  }

  function changeOwner(address payable _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    emit OwnerSet(_owner, _newOwner);
    _owner = _newOwner;
  }

  function _setOwner(address payable newOwner) internal {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnerSet(oldOwner, newOwner);
  }
}

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

contract Multisender is Ownable, Initializable {
  mapping(address => bool) private walletWhiteList;
  mapping(address => bool) private tokenWhiteList;

  using SafeERC20 for IERC20;

  using SafeMath for uint256;
  uint256 public tipsFee;

  event Multisended(uint256 total, address tokenAddress);
  event SetTips(uint256 fromFee, uint256 toFe);
  event Withdraw(address token, uint256 amount);

  constructor(uint256 defaultTipsFee) payable {
    tipsFee = defaultTipsFee;
  }

  function initialize(
    uint256 defaultTipsFee,
    address payable owner,
    address[] memory _wallets,
    address[] memory _tokens
  ) public initializer {
    tipsFee = defaultTipsFee;
    _setOwner(owner);
    for (uint256 i = 0; i < _wallets.length; i++) {
      addWalletWhiteList(_wallets[i]);
    }
    for (uint256 i = 0; i < _tokens.length; i++) {
      addTokenWhiteList(_tokens[i]);
    }
  }

  function setTips(uint256 _tipsFee) public onlyOwner {
    emit SetTips(tipsFee, _tipsFee);
    tipsFee = _tipsFee;
  }

  function addWalletWhiteList(address _wallet) public onlyOwner {
    walletWhiteList[_wallet] = true;
  }

  function addTokenWhiteList(address _wallet) public onlyOwner {
    tokenWhiteList[_wallet] = true;
  }

  function removeWalletWhiteList(address _wallet) public onlyOwner {
    walletWhiteList[_wallet] = false;
  }

  function removeTokenWhiteList(address _token) public onlyOwner {
    tokenWhiteList[_token] = false;
  }

  function getTips(address fromWallet, address token) public view returns (uint256) {
    if (walletWhiteList[fromWallet]) {
      return 0;
    }
    if (tokenWhiteList[token]) {
      return 0;
    }

    return tipsFee;
  }

  function multisendWithSameValue(
    address token,
    address payable[] calldata _reciver,
    uint256 _value
  ) public payable {
    uint256 needSendTipsFee = getTips(msg.sender, token);
    uint256 needSendAmount = _reciver.length.mul(_value);
    if (token == 0x000000000000000000000000000000000000bEEF) {
      require(msg.value >= needSendAmount, "Not enough amount");
      require(msg.value >= needSendAmount.add(needSendTipsFee), "Not enough tips");

      multisendETHSamePrice(msg.value, _reciver, _value);
    } else {
      require(msg.value >= needSendTipsFee, "Not enough tips");

      multisenTokenSamePrice(msg.sender, token, _reciver, _value);
    }
    emit Multisended(needSendAmount, token);
  }

  function multisend(
    address token,
    address payable[] calldata _contributors,
    uint256[] calldata _balances
  ) public payable {
    uint256 needSendTipsFee = getTips(msg.sender, token);
    uint256 needSendAmount = totalAmount(_balances);
    if (token == 0x000000000000000000000000000000000000bEEF) {
      require(msg.value >= needSendAmount, "Not enough amount");
      require(msg.value >= needSendAmount.add(needSendTipsFee), "Not enough tips");

      multisendETH(msg.value, _contributors, _balances);
    } else {
      require(msg.value >= needSendTipsFee, "Not enough tips");

      multisenToken(msg.sender, token, _contributors, _balances);
    }
    emit Multisended(needSendAmount, token);
  }

  function totalAmount(uint256[] calldata _balances) public pure returns (uint256) {
    uint256 total = 0;
    uint8 i = 0;
    for (i; i < _balances.length; i++) {
      total = total.add(_balances[i]);
    }
    return total;
  }

  receive() external payable {}

  function multisenTokenSamePrice(
    address payable _sender,
    address token,
    address payable[] calldata _contributors,
    uint256 _value
  ) internal {
    IERC20 erc20token = IERC20(token);
    for (uint256 i = 0; i < _contributors.length; i++) {
      erc20token.safeTransferFrom(_sender, _contributors[i], _value);
    }
  }

  function multisendETHSamePrice(
    uint256 msgValue,
    address payable[] calldata _contributors,
    uint256 _value
  ) internal {
    uint256 total = msgValue;
    uint256 i = 0;
    for (i; i < _contributors.length; i++) {
      require(total >= _value);
      total = total.sub(_value);
      (bool success, ) = _contributors[i].call{ value: _value }(new bytes(0));

      require(success, "Transfer failed.");
    }
  }

  function multisenToken(
    address payable _sender,
    address token,
    address payable[] calldata _contributors,
    uint256[] calldata _balances
  ) internal {
    uint256 total = 0;
    IERC20 erc20token = IERC20(token);
    uint8 i = 0;

    for (i; i < _contributors.length; i++) {
      erc20token.safeTransferFrom(_sender, _contributors[i], _balances[i]);
      total = total.add(_balances[i]);
    }
  }

  function multisendETH(
    uint256 msgValue,
    address payable[] calldata _contributors,
    uint256[] calldata _balances
  ) internal {
    uint256 total = msgValue;
    uint256 i = 0;
    for (i; i < _contributors.length; i++) {
      require(total >= _balances[i]);
      total = total.sub(_balances[i]);
      (bool success, ) = _contributors[i].call{ value: _balances[i] }(new bytes(0));

      require(success, "Transfer failed.");
    }
  }

  function multisendTokenForBurners(
    address _token,
    address payable[] calldata _contributors,
    uint256[] calldata _balances
  ) external payable {
    uint256 needSendTipsFee = getTips(msg.sender, _token);
    uint256 needSendAmount = totalAmount(_balances);

    require(msg.value >= needSendTipsFee, "Not enough tips");

    IERC20 erc20token = IERC20(_token);
    for (uint256 i = 0; i < _contributors.length; i++) {
      (bool success, ) = _token.call(abi.encodeWithSelector(erc20token.transferFrom.selector, msg.sender, _contributors[i], _balances[i]));
    }
    emit Multisended(needSendAmount, _token);
  }

  function multisendTokenForBurnersWithSameValue(
    address _token,
    address payable[] calldata _contributors,
    uint256 _value
  ) external payable {
    uint256 needSendTipsFee = getTips(msg.sender, _token);
    uint256 needSendAmount = _contributors.length.mul(_value);
    require(msg.value >= needSendTipsFee, "Not enough tips");

    IERC20 erc20token = IERC20(_token);
    for (uint256 i = 0; i < _contributors.length; i++) {
      (bool success, ) = _token.call(abi.encodeWithSelector(erc20token.transferFrom.selector, msg.sender, _contributors[i], _value));
    }
    emit Multisended(needSendAmount, _token);
  }

  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function withdraw(address token, uint256 amount) public onlyOwner {
    if (token == 0x000000000000000000000000000000000000bEEF) {
      _owner.transfer(amount);
    } else {
      IERC20 erc20token = IERC20(token);
      erc20token.safeTransferFrom(address(this), _owner, amount);
    }
    emit Withdraw(token, amount);
  }
}
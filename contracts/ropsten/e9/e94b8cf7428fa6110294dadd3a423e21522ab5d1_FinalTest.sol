/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

// SPDX-License-Identifier: MIT
  // OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)
  // File: @openzeppelin/contracts/utils/Context.sol
  
  
  // OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
  
  pragma solidity ^0.8.0;
  
  // /**
  //  * @dev Provides information about the current execution context, including the
  //  * sender of the transaction and its data. While these are generally available
  //  * via msg.sender and msg.data, they should not be accessed in such a direct
  //  * manner, since when dealing with meta-transactions the account sending and
  //  * paying for execution may not be the actual sender (as far as an application
  //  * is concerned).
  //  *
  //  * This contract is only required for intermediate, library-like contracts.
  //  */
  abstract contract Context {
      function _msgSender() internal view virtual returns (address) {
          return msg.sender;
      }
  
      function _msgData() internal view virtual returns (bytes calldata) {
          return msg.data;
      }
  }
  
  // File: @openzeppelin/contracts/utils/Address.sol
  
  
  // OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)
  
  pragma solidity ^0.8.1;
  
  // /**
  //  * @dev Collection of functions related to the address type
  //  */
  library Address {

      function isContract(address account) internal view returns (bool) {
          // This method relies on extcodesize/address.code.length, which returns 0
          // for contracts in construction, since the code is only stored at the end
          // of the constructor execution.
  
          return account.code.length > 0;
      }

      function sendValue(address payable recipient, uint256 amount) internal {
          require(address(this).balance >= amount, "Address: insufficient balance");
  
          (bool success, ) = recipient.call{value: amount}("");
          require(success, "Address: unable to send value, recipient may have reverted");
      }

      function functionCall(address target, bytes memory data) internal returns (bytes memory) {
          return functionCall(target, data, "Address: low-level call failed");
      }

      function functionCall(
          address target,
          bytes memory data,
          string memory errorMessage
      ) internal returns (bytes memory) {
          return functionCallWithValue(target, data, 0, errorMessage);
      }
  

      //  *
      //  * _Available since v3.1._
      //  */
      function functionCallWithValue(
          address target,
          bytes memory data,
          uint256 value
      ) internal returns (bytes memory) {
          return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
      }
  

      //  * _Available since v3.1._
      //  */
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

      //  * but performing a static call.
      //  *
      //  * _Available since v3.3._
      //  */
      function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
          return functionStaticCall(target, data, "Address: low-level static call failed");
      }

      //  *
      //  * _Available since v3.3._
      //  */
      function functionStaticCall(
          address target,
          bytes memory data,
          string memory errorMessage
      ) internal view returns (bytes memory) {
          require(isContract(target), "Address: static call to non-contract");
  
          (bool success, bytes memory returndata) = target.staticcall(data);
          return verifyCallResult(success, returndata, errorMessage);
      }
  

      function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
          return functionDelegateCall(target, data, "Address: low-level delegate call failed");
      }

      //  * _Available since v3.4._
      //  */
      function functionDelegateCall(
          address target,
          bytes memory data,
          string memory errorMessage
      ) internal returns (bytes memory) {
          require(isContract(target), "Address: delegate call to non-contract");
  
          (bool success, bytes memory returndata) = target.delegatecall(data);
          return verifyCallResult(success, returndata, errorMessage);
      }
  
      // /**
      //  * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
      //  * revert reason using the provided one.
      //  *
      //  * _Available since v4.3._
      //  */
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
  
  // File: @openzeppelin/contracts/token/ERC20/IERC20.sol
  
  
  // OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
  
  pragma solidity ^0.8.0;
  
  // /**
  //  * @dev Interface of the ERC20 standard as defined in the EIP.
  //  */
  interface IERC20 {

      event Transfer(address indexed from, address indexed to, uint256 value);
  

      event Approval(address indexed owner, address indexed spender, uint256 value);
  
      // /**
      //  * @dev Returns the amount of tokens in existence.
      //  */
      function totalSupply() external view returns (uint256);
  

      function balanceOf(address account) external view returns (uint256);
  

      function transfer(address to, uint256 amount) external returns (bool);
  

      function allowance(address owner, address spender) external view returns (uint256);
  

      function approve(address spender, uint256 amount) external returns (bool);
  

      function transferFrom(
          address from,
          address to,
          uint256 amount
      ) external returns (bool);
  }
  
  // File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol
  
  
  // OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)
  
  pragma solidity ^0.8.0;
  
  

  library SafeERC20 {
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
  
      // /**
      //  * @dev Deprecated. This function has issues similar to the ones found in
      //  * {IERC20-approve}, and its usage is discouraged.
      //  *
      //  * Whenever possible, use {safeIncreaseAllowance} and
      //  * {safeDecreaseAllowance} instead.
      //  */
      function safeApprove(
          IERC20 token,
          address spender,
          uint256 value
      ) internal {
          // safeApprove should only be called when setting an initial allowance,
          // or when resetting it to zero. To increase and decrease it, use
          // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
          require(
              (value == 0) || (token.allowance(address(this), spender) == 0),
              "SafeERC20: approve from non-zero to non-zero allowance"
          );
          _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
      }
  
      function safeIncreaseAllowance(
          IERC20 token,
          address spender,
          uint256 value
      ) internal {
          uint256 newAllowance = token.allowance(address(this), spender) + value;
          _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
      }
  
      function safeDecreaseAllowance(
          IERC20 token,
          address spender,
          uint256 value
      ) internal {
          unchecked {
              uint256 oldAllowance = token.allowance(address(this), spender);
              require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
              uint256 newAllowance = oldAllowance - value;
              _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
          }
      }
  
      // /**
      //  * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
      //  * on the return value: the return value is optional (but if data is returned, it must not be false).
      //  * @param token The token targeted by the call.
      //  * @param data The call data (encoded using abi.encode or one of its variants).
      //  */
      function _callOptionalReturn(IERC20 token, bytes memory data) private {
          // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
          // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
          // the target address contains contract code and also asserts for success in the low-level call.
  
          bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
          if (returndata.length > 0) {
              // Return data is optional
              require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
          }
      }
  }
  
  // File: contracts/wallet.sol
  
  
  // OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)
  
  pragma solidity ^0.8.7;
  
  
  
  
  
  
  contract FinalTest is Context {
      event PayeeAdded(address account, uint256 shares);
      event PaymentReleased(address to, uint256 amount);
      event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
      event PaymentReceived(address from, uint256 amount);
  
      uint256 private _totalShares;
      uint256 private _totalReleased;
  
      mapping(address => uint256) private _shares;
      mapping(address => uint256) private _released;
      address[] private _payees;
  
      mapping(IERC20 => uint256) private _erc20TotalReleased;
      mapping(IERC20 => mapping(address => uint256)) private _erc20Released;
      address[] private payees = [0x9F6F526d7e2C918C12AE5B3d44f61251474aB0C9,0x2D3f09B914f7AA844a5e6eD100d15FA5158E104E];      
      uint256[] private shares_ = [50,50];
  

      constructor() payable {
          require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
          require(payees.length > 0, "PaymentSplitter: no payees");
  
          for (uint256 i = 0; i < payees.length; i++) {
              _addPayee(payees[i], shares_[i]);
          }
      }
  
      // /**
      //  * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
      //  * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
      //  * reliability of the events, and not the actual splitting of Ether.
      //  *
      //  * To learn more about this see the Solidity documentation for
      //  * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
      //  * functions].
      //  */
      receive() external payable virtual {
          emit PaymentReceived(_msgSender(), msg.value);
      }
  
      // /**
      //  * @dev Getter for the total shares held by payees.
      //  */
      function totalShares() public view returns (uint256) {
          return _totalShares;
      }
  
      // /**
      //  * @dev Getter for the total amount of Ether already released.
      //  */
      function totalReleased() public view returns (uint256) {
          return _totalReleased;
      }
  

      function totalReleased(IERC20 token) public view returns (uint256) {
          return _erc20TotalReleased[token];
      }

      function shares(address account) public view returns (uint256) {
          return _shares[account];
      }
  
      // /**
      //  * @dev Getter for the amount of Ether already released to a payee.
      //  */
      function released(address account) public view returns (uint256) {
          return _released[account];
      }
  

      function released(IERC20 token, address account) public view returns (uint256) {
          return _erc20Released[token][account];
      }
  

      function payee(uint256 index) public view returns (address) {
          return _payees[index];
      }

      function release(address payable account) public virtual {
          require(_shares[account] > 0, "PaymentSplitter: account has no shares");
  
          uint256 totalReceived = address(this).balance + totalReleased();
          uint256 payment = _pendingPayment(account, totalReceived, released(account));
  
          require(payment != 0, "PaymentSplitter: account is not due payment");
  
          _released[account] += payment;
          _totalReleased += payment;
  
          Address.sendValue(account, payment);
          emit PaymentReleased(account, payment);
      }
  

      function release(IERC20 token, address account) public virtual {
          require(_shares[account] > 0, "PaymentSplitter: account has no shares");
  
          uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
          uint256 payment = _pendingPayment(account, totalReceived, released(token, account));
  
          require(payment != 0, "PaymentSplitter: account is not due payment");
  
          _erc20Released[token][account] += payment;
          _erc20TotalReleased[token] += payment;
  
          SafeERC20.safeTransfer(token, account, payment);
          emit ERC20PaymentReleased(token, account, payment);
      }

      function _pendingPayment(
          address account,
          uint256 totalReceived,
          uint256 alreadyReleased
      ) private view returns (uint256) {
          return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
      }
  

      function _addPayee(address account, uint256 shares_) private {
          require(account != address(0), "PaymentSplitter: account is the zero address");
          require(shares_ > 0, "PaymentSplitter: shares are 0");
          require(_shares[account] == 0, "PaymentSplitter: account already has shares");
  
          _payees.push(account);
          _shares[account] = shares_;
          _totalShares = _totalShares + shares_;
          emit PayeeAdded(account, shares_);
      }
  }
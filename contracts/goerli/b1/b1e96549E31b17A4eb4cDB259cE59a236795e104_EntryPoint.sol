// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "Address.sol";
import "SafeMath.sol";

import "Staking.sol";
import "IEntryPoint.sol";
import "ISingletonFactory.sol";
import "EntryPointHelpers.sol";
import "UserOperation.sol";
import "Calls.sol";
import "GasUsed.sol";
import "IWallet.sol";
import "IPaymaster.sol";

contract EntryPoint is IEntryPoint, Staking {
  using Calls for address;
  using Calls for address payable;
  using Address for address;
  using EntryPointHelpers for uint256;
  using EntryPointHelpers for address;
  using EntryPointHelpers for UserOperation;

  /**
   * Internal struct used during the verification process to avoid computing a few things more than once
   * @param context of the paymaster in case it was required
   * @param prefund computed based on the gas values requested
   * @param gasUsed total gas used during the verification process
   * @param requestId unique identifier computed as keccak256(op, entryPoint, chainId)
   */
  struct UserOpVerification {
    bytes context;
    uint256 prefund;
    uint256 gasUsed;
    bytes32 requestId;
  }

  /**
   * Emitted for each successful user op
   * @param sender the wallet executing the op
   * @param paymaster the paymaster paying for the op
   * @param requestId unique identifier computed as keccak256(op, entryPoint, chainId)
   * @param success whether the execution succeed or not
   * @param result the execution result
   */
  event UserOperationExecuted(
    address indexed sender,
    address indexed paymaster,
    bytes32 requestId,
    bool success,
    bytes result
  );

  // Singleton factory used by the entry point to instantiate wallets
  ISingletonFactory public immutable create2Factory;

  /**
   * @dev Entry point constructor
   * @param _create2Factory factory that will be used the entry point to instantiate wallets
   * @param _unstakeDelaySec unstake delay that will be forced to each paymaster
   */
  constructor(ISingletonFactory _create2Factory, uint32 _unstakeDelaySec) Staking(_unstakeDelaySec) {
    create2Factory = _create2Factory;
  }

  /**
   * @dev Tells the gas price that will be used for an op
   */
  function getGasPrice(UserOperation calldata op) external view returns (uint256) {
    return op.gasPrice();
  }

  /**
   * @dev Tells the required prefund that will be computed for an op
   */
  function getRequiredPrefund(UserOperation calldata op) external view returns (uint256) {
    return op.requiredPrefund();
  }

  /**
   * @dev Tells the address that will result by deploying a certain bytecode using the entry point's factory
   * @param initCode bytecode to be deployed
   * @param salt salt value to be used
   */
  function getSenderAddress(bytes memory initCode, uint256 salt) external view returns (address) {
    bytes32 data = keccak256(abi.encodePacked(bytes1(0xff), address(create2Factory), salt, keccak256(initCode)));
    return address(uint160(uint256(data)));
  }

  /**
   * @dev Allows off-chain parties to validate operations through the entry point before executing them
   */
  function simulateValidation(UserOperation calldata op) external returns (uint256 preOpGas, uint256 prefund) {
    uint256 preGas = gasleft();
    UserOpVerification memory verification = _verifyOp(0, op);
    preOpGas = GasUsed.since(preGas) + op.preVerificationGas;
    prefund = verification.prefund;
    require(msg.sender == address(0), "EntryPoint: Caller not zero");
  }

  /**
   * @dev Process a list of operations
   */
  function handleOps(UserOperation[] calldata ops, address payable redeemer) external {
    UserOpVerification[] memory verifications = new UserOpVerification[](ops.length);
    for (uint256 i = 0; i < ops.length; i++) verifications[i] = _verifyOp(i, ops[i]);

    uint256 totalGasCost;
    for (uint256 i = 0; i < ops.length; i++) totalGasCost += _executeOp(i, ops[i], verifications[i]);
    redeemer.sendValue(totalGasCost, "EntryPoint: Failed to redeem");
  }

  /**
   * @dev Internal function to run the verification process for a user operation
   */
  function _verifyOp(uint256 opIndex, UserOperation calldata op)
    internal
    returns (UserOpVerification memory verification)
  {
    uint256 preValidationGas = gasleft();
    _createWalletIfNecessary(opIndex, op);
    bytes32 requestId = op.requestId();
    uint256 prefund = op.requiredPrefund();
    _validateWallet(opIndex, op, requestId, prefund);

    // Marker used of-chain for opcodes validation
    uint256 marker = block.number;
    (marker);

    uint256 walletGas = GasUsed.since(preValidationGas);
    uint256 paymasterValidationGas = op.verificationGas.sub(walletGas, opIndex, "EntryPoint: Verif gas not enough");
    verification.prefund = prefund;
    verification.requestId = requestId;
    verification.context = _validatePaymaster(opIndex, op, requestId, prefund, paymasterValidationGas);
    verification.gasUsed = GasUsed.since(preValidationGas);
    requireFailedOp(verification.gasUsed <= op.verificationGas, opIndex, "EntryPoint: Verif gas not enough");
  }

  /**
   * @dev Internal function that will trigger a wallet creation in case it was requested in the op
   */
  function _createWalletIfNecessary(uint256 opIndex, UserOperation calldata op) internal {
    bool hasInitCode = op.hasInitCode();
    bool isAlreadyDeployed = op.isAlreadyDeployed();
    bool isProperlyFormed = (isAlreadyDeployed && !hasInitCode) || (!isAlreadyDeployed && hasInitCode);
    requireFailedOp(isProperlyFormed, opIndex, "EntryPoint: Wrong init code");

    if (!isAlreadyDeployed) {
      create2Factory.deploy(op.initCode, bytes32(op.nonce));
    }
  }

  /**
   * @dev Internal function to run the wallet verification process
   */
  function _validateWallet(
    uint256 opIndex,
    UserOperation calldata op,
    bytes32 requestId,
    uint256 prefund
  ) internal {
    uint256 requiredPrefund = op.hasPaymaster() ? 0 : prefund;
    uint256 initBalance = address(this).balance;

    try IWallet(op.sender).validateUserOp{ gas: op.verificationGas }(op, requestId, requiredPrefund) {
      // solhint-disable-previous-line no-empty-blocks
    } catch Error(string memory reason) {
      revert FailedOp(opIndex, reason);
    } catch (bytes memory error) {
      revert FailedOp(opIndex, string(error));
    }

    uint256 actualPrefund = address(this).balance.sub(initBalance, opIndex, "EntryPoint: Balance decreased");
    requireFailedOp(actualPrefund >= requiredPrefund, opIndex, "EntryPoint: Incorrect prefund");
  }

  /**
   * @dev Internal function to run the paymaster verification process
   */
  function _validatePaymaster(
    uint256 opIndex,
    UserOperation calldata op,
    bytes32 requestId,
    uint256 prefund,
    uint256 validationGas
  ) internal returns (bytes memory) {
    if (!op.hasPaymaster()) return new bytes(0);

    requireFailedOp(isStaked(op.paymaster), opIndex, "EntryPoint: Deposit not staked");
    _decreaseStake(op.paymaster, prefund);

    try IPaymaster(op.paymaster).validatePaymasterUserOp{ gas: validationGas }(op, requestId, prefund) returns (
      bytes memory result
    ) {
      return result;
    } catch Error(string memory reason) {
      revert FailedOp(opIndex, reason);
    } catch (bytes memory error) {
      revert FailedOp(opIndex, string(error));
    }
  }

  /**
   * @dev Internal function to execute an operation
   */
  function _executeOp(
    uint256 opIndex,
    UserOperation calldata op,
    UserOpVerification memory verification
  ) internal returns (uint256 totalGasCost) {
    uint256 preExecutionGas = gasleft();
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory result) = op.sender.call{ gas: op.callGas }(op.callData);
    emit UserOperationExecuted(op.sender, op.paymaster, verification.requestId, success, result);

    uint256 totalGasUsed = verification.gasUsed + GasUsed.since(preExecutionGas);
    totalGasCost = totalGasUsed * op.gasPrice();

    if (op.hasPaymaster()) {
      return _executePostOp(opIndex, op, verification, preExecutionGas, totalGasCost, success);
    } else {
      uint256 refund = verification.prefund.sub(totalGasCost, opIndex, "EntryPoint: Insufficient refund");
      payable(op.sender).sendValue(refund, "EntryPoint: Failed to refund");
    }
  }

  /**
   * @dev Internal function to execute the post-op execution process, only for paymasters
   */
  function _executePostOp(
    uint256 opIndex,
    UserOperation calldata op,
    UserOpVerification memory verification,
    uint256 preExecutionGas,
    uint256 gasCost,
    bool success
  ) internal returns (uint256 actualGasCost) {
    uint256 gasPrice = op.gasPrice();
    PostOpMode mode = success ? PostOpMode.opSucceeded : PostOpMode.opReverted;

    try IPaymaster(op.paymaster).postOp(mode, verification.context, gasCost) {
      uint256 totalGasUsed = verification.gasUsed + GasUsed.since(preExecutionGas);
      actualGasCost = totalGasUsed * gasPrice;
    } catch {
      uint256 gasUsedIncludingPostOp = verification.gasUsed + GasUsed.since(preExecutionGas);
      uint256 gasCostIncludingPostOp = gasUsedIncludingPostOp * gasPrice;

      try IPaymaster(op.paymaster).postOp(PostOpMode.postOpReverted, verification.context, gasCostIncludingPostOp) {
        // solhint-disable-previous-line no-empty-blocks
      } catch Error(string memory reason) {
        revert FailedOp(opIndex, reason);
      } catch (bytes memory error) {
        revert FailedOp(opIndex, string(error));
      }

      uint256 totalGasUsed = verification.gasUsed + GasUsed.since(preExecutionGas);
      actualGasCost = totalGasUsed * gasPrice;
    }

    uint256 refund = verification.prefund.sub(actualGasCost, opIndex, "EntryPoint: Insufficient refund");
    _increaseStake(op.paymaster, refund);
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "SafeCast.sol";
import "SafeMath.sol";

import "IEntryPointStaking.sol";
import "UserOperation.sol";
import "Calls.sol";

contract Staking is IEntryPointStaking {
  using SafeCast for uint256;
  using SafeMath for uint256;
  using Calls for address payable;

  /**
   * @dev Struct of deposits information for each account
   * @param amount deposited for an account
   * @param unstakeDelaySec delay picked for the unstaking process, zero means the account hasn't staked yet
   * @param withdrawTime timestamp when the account will be allowed to withdraw their deposited funds, zero means anytime
   */
  struct Deposit {
    uint256 amount;
    uint32 unstakeDelaySec;
    uint64 withdrawTime;
  }

  event Deposited(address indexed account, uint256 deposited);
  event StakeLocked(address indexed account, uint256 deposited, uint256 unstakeDelaySec);
  event StakeUnlocked(address indexed account, uint64 withdrawTime);
  event Withdrawn(address indexed account, address recipient, uint256 deposited, uint256 amount);

  // unstaking delay that will be forced to each account
  uint32 public immutable unstakeDelaySec;

  // deposits list indexed by account address
  mapping(address => Deposit) private deposits;

  /**
   * @dev Staking constructor
   * @param _unstakeDelaySec unstaking delay that will be forced to each account
   */
  constructor(uint32 _unstakeDelaySec) {
    unstakeDelaySec = _unstakeDelaySec;
  }

  /**
   * @dev Allows receiving ETH transfers
   */
  receive() external payable {
    // solhint-disable-previous-line no-empty-blocks
  }

  /**
   * @dev Tells the entire deposit information for an account
   */
  function getDeposit(address account) external view returns (Deposit memory) {
    return deposits[account];
  }

  /**
   * @dev Tells the total amount deposited for an account
   */
  function balanceOf(address account) external view override returns (uint256) {
    return deposits[account].amount;
  }

  /**
   * @dev Tells is account has deposited balance or not
   */
  function hasDeposited(address account, uint256 amount) public view returns (bool) {
    return deposits[account].amount >= amount;
  }

  /**
   * @dev Tells if an account has it's deposited balance staked or not
   */
  function isStaked(address account) public view returns (bool) {
    Deposit storage deposit = deposits[account];
    return deposit.unstakeDelaySec > 0 && deposit.withdrawTime == 0;
  }

  /**
   * @dev Tells if an account has started it's unstaking process or not
   */
  function isUnstaking(address account) public view returns (bool) {
    Deposit storage deposit = deposits[account];
    return deposit.unstakeDelaySec > 0 && deposit.withdrawTime > 0;
  }

  /**
   * @dev Tells if an account is allowed to withdraw its deposits or not
   */
  function canWithdraw(address account) public view returns (bool) {
    Deposit storage deposit = deposits[account];
    // solhint-disable-next-line not-rely-on-time
    return deposit.unstakeDelaySec == 0 || (isUnstaking(account) && deposit.withdrawTime <= block.timestamp);
  }

  /**
   * @dev Deposits value to an account. It will deposit the entire msg.value sent to the function.
   * @param account willing to deposit the value to
   */
  function depositTo(address account) external payable override {
    Deposit storage deposit = deposits[account];
    uint256 deposited = deposit.amount + msg.value;
    deposit.amount = deposited;
    emit Deposited(account, deposited);
  }

  /**
   * @dev Stakes the sender's deposits. It will deposit the entire msg.value sent to the function and mark it as staked.
   * @param _unstakeDelaySec unstaking delay that will be forced to the account, it can only be greater than or
   * equal to the one set in the contract
   */
  function addStake(uint32 _unstakeDelaySec) external payable override {
    Deposit storage deposit = deposits[msg.sender];
    require(_unstakeDelaySec >= unstakeDelaySec, "Staking: Low unstake delay");
    require(_unstakeDelaySec >= deposit.unstakeDelaySec, "Staking: Decreasing unstake time");

    uint256 deposited = deposit.amount + msg.value;
    deposit.amount = deposited;
    deposit.unstakeDelaySec = _unstakeDelaySec;
    deposit.withdrawTime = 0;
    emit StakeLocked(msg.sender, deposited, unstakeDelaySec);
  }

  /**
   * @dev Starts the unlocking process for the sender.
   * It sets the withdraw time based on the unstaking delay previously set for the account.
   */
  function unlockStake() external override {
    require(!isUnstaking(msg.sender), "Staking: Unstaking in progress");
    require(isStaked(msg.sender), "Staking: Deposit not staked yet");

    Deposit storage deposit = deposits[msg.sender];
    // solhint-disable-next-line not-rely-on-time
    uint64 withdrawTime = (block.timestamp + deposit.unstakeDelaySec).toUint64();
    deposit.withdrawTime = withdrawTime;
    emit StakeUnlocked(msg.sender, withdrawTime);
  }

  /**
   * @dev Withdraws the entire deposited balance of the sender to a recipient.
   * Essentially, the withdraw time must be zero or in the past.
   */
  function withdrawStake(address payable recipient) external override {
    withdrawTo(recipient, deposits[msg.sender].amount);
  }

  /**
   * @dev Withdraws the part of the deposited balance of the sender to a recipient.
   * Essentially, the withdraw time must be zero or in the past.
   */
  function withdrawTo(address payable recipient, uint256 amount) public override {
    require(amount > 0, "Staking: Withdraw amount zero");
    require(canWithdraw(msg.sender), "Staking: Cannot withdraw");

    Deposit storage deposit = deposits[msg.sender];
    uint256 deposited = deposit.amount.sub(amount, "Staking: Insufficient deposit");
    deposit.unstakeDelaySec = 0;
    deposit.withdrawTime = 0;
    deposit.amount = deposited;

    recipient.sendValue(amount, "Staking: Withdraw failed");
    emit Withdrawn(msg.sender, recipient, deposited, amount);
  }

  /**
   * @dev Internal function to increase an account's staked balance
   */
  function _increaseStake(address account, uint256 amount) internal {
    Deposit storage deposit = deposits[account];
    deposit.amount = deposit.amount + amount;
  }

  /**
   * @dev Internal function to decrease an account's staked balance
   */
  function _decreaseStake(address account, uint256 amount) internal {
    Deposit storage deposit = deposits[account];
    deposit.amount = deposit.amount.sub(amount, "Staking: Insufficient stake");
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

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
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
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
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
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
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
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
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
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
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
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
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
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
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
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
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
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
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
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
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "UserOperation.sol";

/**
 * @dev EntryPointStaking interface specified in https://eips.ethereum.org/EIPS/eip-4337
 */
interface IEntryPointStaking {
  // return the deposit of an account
  function balanceOf(address account) external view returns (uint256);

  // add to the deposit of the given account
  function depositTo(address account) external payable;

  // add a paymaster stake (must be called by the paymaster)
  function addStake(uint32 _unstakeDelaySec) external payable;

  // unlock the stake (must wait unstakeDelay before can withdraw)
  function unlockStake() external;

  // withdraw the unlocked stake
  function withdrawStake(address payable withdrawAddress) external;

  // withdraw from the deposit
  function withdrawTo(address payable withdrawAddress, uint256 withdrawAmount) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

/**
 * @dev Operation object specified in https://eips.ethereum.org/EIPS/eip-4337
 */
struct UserOperation {
  address sender;
  uint256 nonce;
  bytes initCode;
  bytes callData;
  uint256 callGas;
  uint256 verificationGas;
  uint256 preVerificationGas;
  uint256 maxFeePerGas;
  uint256 maxPriorityFeePerGas;
  address paymaster;
  bytes paymasterData;
  bytes signature;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "Address.sol";

/**
 * @dev Calls helpers library
 */
library Calls {
  // solhint-disable avoid-low-level-calls

  /**
   * @dev Sends `value` wei to `recipient`, forwarding all available gas and reverting on errors.
   * If `recipient` reverts with a revert reason, it is bubbled. Otherwise, it reverts with `errorMessage`.
   */
  function sendValue(
    address payable recipient,
    uint256 value,
    string memory errorMessage
  ) internal {
    require(address(this).balance >= value, "Address: insufficient balance");
    (bool success, bytes memory returndata) = recipient.call{ value: value }("");
    Address.verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Performs a Solidity function call using a low level `call` sending `value` wei to `recipient`,
   * forwarding all available gas and reverting on errors.
   * If `target` reverts with a revert reason, it is bubbled up. Otherwise, it reverts with `errorMessage`.
   */
  function callWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal {
    if (data.length == 0) {
      sendValue(payable(address(target)), value, errorMessage);
    } else {
      Address.functionCallWithValue(target, data, value, errorMessage);
    }
  }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "UserOperation.sol";
import "IEntryPointStaking.sol";

/**
 * @dev EntryPoint interface specified in https://eips.ethereum.org/EIPS/eip-4337
 */
interface IEntryPoint is IEntryPointStaking {
  function simulateValidation(UserOperation calldata userOp) external returns (uint256 preOpGas, uint256 prefund);

  function handleOps(UserOperation[] calldata ops, address payable redeemer) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

/**
 * @title Singleton Factory (EIP-2470)
 * @notice Exposes CREATE2 (EIP-1014) to deploy bytecode on deterministic addresses based on initialization code and salt.
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 */
interface ISingletonFactory {
  /**
   * @notice Deploys `_initCode` using `_salt` for defining the deterministic address.
   * @param _initCode Initialization code.
   * @param _salt Arbitrary value to modify resulting address.
   * @return createdContract Created contract address.
   */
  function deploy(bytes memory _initCode, bytes32 _salt) external returns (address payable createdContract);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "Address.sol";
import "Math.sol";
import "SafeMath.sol";

import "UserOperation.sol";

error FailedOp(uint256 opIndex, string reason);

// solhint-disable-next-line func-visibility
function requireFailedOp(
  bool condition,
  uint256 opIndex,
  string memory reason
) pure {
  if (!condition) revert FailedOp(opIndex, reason);
}

/**
 * @dev Entry point helpers library
 */
library EntryPointHelpers {
  using Address for address;

  /**
   * @dev Tells whether the op has requested a paymaster or not
   */
  function hasPaymaster(UserOperation calldata op) internal pure returns (bool) {
    return op.paymaster != address(0);
  }

  /**
   * @dev Tells whether the op has an init code set or not
   */
  function hasInitCode(UserOperation calldata op) internal pure returns (bool) {
    return op.initCode.length != 0;
  }

  /**
   * @dev Tells whether the op wallet was already deployed or not
   */
  function isAlreadyDeployed(UserOperation calldata op) internal view returns (bool) {
    return op.sender.isContract();
  }

  /**
   * @dev Tells the entry point request ID: op + entry point + chain ID
   */
  function requestId(UserOperation calldata op) internal view returns (bytes32) {
    return keccak256(abi.encode(hash(op), address(this), block.chainid));
  }

  /**
   * @dev Tells the total amount in wei that must be refunded to the entry point for a given op
   */
  function requiredPrefund(UserOperation calldata op) internal view returns (uint256) {
    uint256 totalGas = op.callGas + op.verificationGas + op.preVerificationGas;
    return totalGas * gasPrice(op);
  }

  /**
   * @dev Tells the gas price to be used for an op. It uses GASPRICE for chains that don't support EIP1559 transactions.
   */
  function gasPrice(UserOperation calldata op) internal view returns (uint256) {
    return
      op.maxFeePerGas == op.maxPriorityFeePerGas
        ? op.maxFeePerGas
        : Math.min(op.maxFeePerGas, op.maxPriorityFeePerGas + block.basefee);
  }

  /**
   * @dev Hashes a user operation
   */
  function hash(UserOperation calldata op) internal pure returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          op.sender,
          op.nonce,
          keccak256(op.initCode),
          keccak256(op.callData),
          op.callGas,
          op.verificationGas,
          op.preVerificationGas,
          op.maxFeePerGas,
          op.maxPriorityFeePerGas,
          op.paymaster,
          keccak256(op.paymasterData)
        )
      );
  }

  /**
   * @dev Custom SafeMath function used for the EntryPoint to raise FailedOp errors instead
   */
  function sub(
    uint256 a,
    uint256 b,
    uint256 opIndex,
    string memory reason
  ) internal pure returns (uint256) {
    (bool succeed, uint256 result) = SafeMath.trySub(a, b);
    requireFailedOp(succeed, opIndex, reason);
    return result;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "SafeMath.sol";

/**
 * @dev Gas helpers library
 */
library GasUsed {
  using SafeMath for uint256;

  /**
   * @dev Tells the gas used based on a previous gas-left measure
   */
  function since(uint256 previousGasLeft) internal view returns (uint256 gasUsed) {
    return previousGasLeft.sub(gasleft(), "Invalid previous gas left");
  }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "UserOperation.sol";

/**
 * @dev Wallet interface specified in https://eips.ethereum.org/EIPS/eip-4337
 */
interface IWallet {
  function validateUserOp(
    UserOperation calldata op,
    bytes32 requestId,
    uint256 requiredPrefund
  ) external;

  function executeUserOp(
    address to,
    uint256 value,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "UserOperation.sol";

/**
 * @dev Mode used to denote the paymaster the status of the operation for the post-op process
 * @param opSucceeded to denote the user op succeeded
 * @param opReverted to denote the user op reverted
 * @param postOpReverted to denote the post-op was already tried and it reverted
 */
enum PostOpMode {
  opSucceeded,
  opReverted,
  postOpReverted
}

/**
 * @dev Paymaster interface specified in https://eips.ethereum.org/EIPS/eip-4337
 */
interface IPaymaster {
  function validatePaymasterUserOp(
    UserOperation calldata op,
    bytes32 requestId,
    uint256 maxCost
  ) external view returns (bytes memory context);

  function postOp(
    PostOpMode mode,
    bytes calldata context,
    uint256 actualGasCost
  ) external;
}
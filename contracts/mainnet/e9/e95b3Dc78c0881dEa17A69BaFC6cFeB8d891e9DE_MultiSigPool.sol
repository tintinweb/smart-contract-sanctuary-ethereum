// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../interfaces/IAggregationRouterV4.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IStarkEx.sol";
import "../interfaces/IFactRegister.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 *
 * MultiSigPool
 * ============
 *
 * Basic multi-signer wallet designed for use in a co-signing environment where 2 signatures are require to move funds.
 * Typically used in a 2-of-3 signing configuration. Uses ecrecover to allow for 2 signatures in a single transaction.
 *
 * The signatures are created on the operation hash and passed to withdrawETH/withdrawERC20
 * The signer is determined by ECDSA.recover().
 *
 * The signature is created with ethereumjs-util.ecsign(operationHash).
 * Like the eth_sign RPC call, it packs the values as a 65-byte array of [r, s, v].
 * Unlike eth_sign, the message is not prefixed.
 *
 */
contract MultiSigPool is ReentrancyGuard {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  // Events
  event Deposit(address from, address token, uint256 spentAmount, uint256 swapReturnAmount, uint256 starkKey, uint256 positionId);
  event WithdrawETH(uint256 orderId, address to, uint256 amount);
  event WithdrawERC20(uint256 orderId, address token, address to, uint256 amount);

  // Public fields
  address immutable public USDC_ADDRESS;                  // USDC contract address
  address immutable public STARKEX_ADDRESS;               // stark exchange adress
  address immutable public FACT_ADDRESS;                  // stark external fact contract address
  address immutable public AGGREGATION_ROUTER_V4_ADDRESS; // 1inch AggregationRouterV4  address
  address[] public signers;                               // The addresses that can co-sign transactions on the wallet
  mapping(uint256 => order) orders;                       // history orders
  uint256 public ASSET_TYPE;                              // stark exchange defined USDC

  IERC20 private constant ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
  IERC20 private constant ZERO_ADDRESS = IERC20(address(0));

  struct order{
    address to;     // The address the transaction was sent to
    uint256 amount; // Amount of Wei sent to the address
    address token;  // The address of the ERC20 token contract, 0 means ETH
    bool executed;  // If the order was executed
  }

  /**
   * Set up a simple 2-3 multi-sig wallet by specifying the signers allowed to be used on this wallet.
   * 2 signers will be require to send a transaction from this wallet.
   * Note: The sender is NOT automatically added to the list of signers.
   * Signers CANNOT be changed once they are set
   *
   * @param allowedSigners      An array of signers on the wallet
   * @param usdc                The USDC contract address
   * @param aggregationRouterV4 The 1inch exchange router address
   * @param starkex             The stark exchange address
   * @param fact                The stark fact address
   */
  constructor(address[] memory allowedSigners, address usdc,address aggregationRouterV4,address starkex, address fact, uint256 assetType) {
    require(allowedSigners.length == 3, "invalid allSigners length");
    require(allowedSigners[0] != allowedSigners[1], "must be different signers");
    require(allowedSigners[0] != allowedSigners[2], "must be different signers");
    require(allowedSigners[1] != allowedSigners[2], "must be different signers");
    require(usdc != address(0), "invalid usdc address");
    require(aggregationRouterV4 != address(0), "invalid 1inch address");

    signers = allowedSigners;
    USDC_ADDRESS = usdc;
    AGGREGATION_ROUTER_V4_ADDRESS = aggregationRouterV4;
    STARKEX_ADDRESS = starkex;
    FACT_ADDRESS = fact;
    ASSET_TYPE = assetType;
  }

  /**
   * Gets called when a transaction is received without calling a method
   */
  receive() external payable { }

  /**
    * @notice Make a deposit to the Starkware Layer2, after converting funds to USDC.
    *  Funds will be transferred from the sender and USDC will be deposited into this wallet, and 
    *  generate a deposit event specified by the starkKey and positionId.
    *
    * @param  token          The ERC20 token to convert from
    * @param  amount         The amount in Wei to deposit.
    * @param  starkKey       The starkKey of the L2 account to deposit into.
    * @param  positionId     The positionId of the L2 account to deposit into.
    * @param  exchangeData   Trade parameters for the exchange.
    */
  function deposit(
    IERC20 token,
    uint256 amount,
    uint256 starkKey,
    uint256 positionId,
    bytes calldata exchangeData
  ) public payable nonReentrant returns (uint256) {
    uint256 returnAmount;
    uint256 beforeSwapBalance = IERC20(USDC_ADDRESS).balanceOf(address(this));

    if (address(token) == USDC_ADDRESS){   // deposit USDC 
      token.safeTransferFrom(msg.sender, address(this), amount);
      returnAmount = amount;
    } else {
      (, IAggregationRouterV4.SwapDescription memory desc,) = abi.decode(exchangeData[4:], (address, IAggregationRouterV4.SwapDescription, bytes));
      require(token == desc.srcToken, 'mismatch token and desc.srcToken');
      require(USDC_ADDRESS == address(desc.dstToken), 'invalid desc.dstToken');
      require(amount == desc.amount, 'mismatch amount and desc.amount');
      require(address(this) == desc.dstReceiver, 'invalid desc.dstReceiver');

      bool isNativeToken = isNative(desc.srcToken);
      if (!isNativeToken) {  // deposit other ERC20 tokens 
        desc.srcToken.safeTransferFrom(msg.sender, address(this), desc.amount);

        // safeApprove requires unsetting the allowance first.
        desc.srcToken.safeApprove(AGGREGATION_ROUTER_V4_ADDRESS, 0);
        desc.srcToken.safeApprove(AGGREGATION_ROUTER_V4_ADDRESS, desc.amount);
      }

      // Swap token
      (bool success, bytes memory returndata)= AGGREGATION_ROUTER_V4_ADDRESS.call{value:msg.value}(exchangeData);
      require(success, "exchange failed");

      (returnAmount, ) = abi.decode(returndata, (uint256, uint256));
      require(returnAmount >= desc.minReturnAmount, 'received USDC less than minReturnAmount');
    }

    uint256 afterSwapBalance = IERC20(USDC_ADDRESS).balanceOf(address(this));
    require (afterSwapBalance == beforeSwapBalance.add(returnAmount),"swap incorrect");

    // ethereum deposit to starkex directly
    if (block.chainid == 1 || block.chainid == 5){
      // safeApprove requires unsetting the allowance first.
      IERC20(USDC_ADDRESS).safeApprove(STARKEX_ADDRESS, 0);
      IERC20(USDC_ADDRESS).safeApprove(STARKEX_ADDRESS, returnAmount);

      // deposit to starkex
      IStarkEx starkEx = IStarkEx(STARKEX_ADDRESS);
      starkEx.depositERC20(starkKey, ASSET_TYPE, positionId, returnAmount);
      return returnAmount;
    }

    emit Deposit(
      msg.sender,
      address(token),
      amount,
      returnAmount,
      starkKey,
      positionId
    );

    return returnAmount;
  }

  /**
   * Withdraw ETHER from this wallet using 2 signers.
   *
   * @param  to         the destination address to send an outgoing transaction
   * @param  amount     the amount in Wei to be sent
   * @param  expireTime the number of seconds since 1970 for which this transaction is valid
   * @param  orderId    the unique order id 
   * @param  allSigners all signers who sign the tx
   * @param  signatures the signatures of tx
   */
  function withdrawETH(
    address payable to,
    uint256 amount,
    uint256 expireTime,
    uint256 orderId,
    address[] memory allSigners,
    bytes[] memory signatures
  ) public nonReentrant {
    require(allSigners.length >= 2, "invalid allSigners length");
    require(allSigners.length == signatures.length, "invalid signatures length");
    require(allSigners[0] != allSigners[1],"can not be same signer"); // must be different signer
    require(expireTime >= block.timestamp,"expired transaction");

    bytes32 operationHash = keccak256(abi.encodePacked("ETHER", to, amount, expireTime, orderId, address(this)));
    operationHash = ECDSA.toEthSignedMessageHash(operationHash);
    
    for (uint8 index = 0; index < allSigners.length; index++) {
      address signer = ECDSA.recover(operationHash, signatures[index]);
      require(signer == allSigners[index], "invalid signer");
      require(isAllowedSigner(signer), "not allowed signer");
    }

    // Try to insert the order ID. Will revert if the order id was invalid
    tryInsertOrderId(orderId, to, amount, address(0));

    // send ETHER
    require(address(this).balance >= amount, "Address: insufficient balance");
    (bool success, ) = to.call{value: amount}("");
    require(success, "Address: unable to send value, recipient may have reverted");

    emit WithdrawETH(orderId, to, amount);
  }
  
  /**
   * Withdraw ERC20 from this wallet using 2 signers.
   *
   * @param  to         the destination address to send an outgoing transactioni
   * @param  amount     the amount in Wei to be sent
   * @param  token      the address of the erc20 token contract
   * @param  expireTime the number of seconds since 1970 for which this transaction is valid
   * @param  orderId    the unique order id 
   * @param  allSigners all signer who sign the tx
   * @param  signatures the signatures of tx
   */
  function withdrawErc20(
    address to,
    uint256 amount,
    address token,
    uint256 expireTime,
    uint256 orderId,
    address[] memory allSigners,
    bytes[] memory signatures
  ) public nonReentrant {
    require(allSigners.length >=2, "invalid allSigners length");
    require(allSigners.length == signatures.length, "invalid signatures length");
    require(allSigners[0] != allSigners[1],"can not be same signer"); // must be different signer
    require(expireTime >= block.timestamp,"expired transaction");

    bytes32 operationHash = keccak256(abi.encodePacked("ERC20", to, amount, token, expireTime, orderId, address(this)));
    operationHash = ECDSA.toEthSignedMessageHash(operationHash);

    for (uint8 index = 0; index < allSigners.length; index++) {
      address signer = ECDSA.recover(operationHash, signatures[index]);
      require(signer == allSigners[index], "invalid signer");
      require(isAllowedSigner(signer),"not allowed signer");
    }

    // Try to insert the order ID. Will revert if the order id was invalid
    tryInsertOrderId(orderId, to, amount, token);

    // Success, send ERC20 token
    IERC20(token).safeTransfer(to, amount);
    emit WithdrawERC20(orderId, token, to, amount);
  }

  /**
   * Withdraw ERC20 from this wallet using 2 signers.
   * The function only can be called when user make a fast withdraw in ApexPro.
   *
   * @param  to         the destination address to send an outgoing transaction
   * @param  amount     the amount in wei to be sent
   * @param  token      the address of the erc20 token contract
   * @param  salt       salt amount to generate fact
   * @param  expireTime the number of seconds since 1970 for which this transaction is valid
   * @param  orderId    the unique order id 
   * @param  allSigners all signer who sign the tx
   * @param  signatures the signatures of tx
   */
  function factTransferErc20(
    address to,
    address token,
    uint256 amount,
    uint256 salt,
    uint256 expireTime,
    uint256 orderId,
    address[] memory allSigners,
    bytes[] memory signatures
  ) public nonReentrant {
    require(token == USDC_ADDRESS,"invalid token");
    require(allSigners.length >=2, "invalid allSigners length");
    require(allSigners.length == signatures.length, "invalid signatures length");
    require(allSigners[0] != allSigners[1],"can not be same signer"); // must be different signer
    require(expireTime >= block.timestamp,"expired transaction");

    bytes32 operationHash = keccak256(abi.encodePacked("FAST",to, amount, token, expireTime, salt, orderId, address(this)));
    operationHash = ECDSA.toEthSignedMessageHash(operationHash);

    for (uint8 index = 0; index < allSigners.length; index++) {
      address signer = ECDSA.recover(operationHash, signatures[index]);
      require(signer == allSigners[index], "invalid signer");
      require(isAllowedSigner(signer),"not allowed signer");
    }

    // Try to insert the order ID. Will revert if the order id was invalid
    tryInsertOrderId(orderId, to, amount, token);

    // check fact 
    bytes32 transferFact =  keccak256(abi.encodePacked(to, amount, token, salt));
    IFactRegister factAddress = IFactRegister(FACT_ADDRESS);
    require(!factAddress.isValid(transferFact),"fact already isValid");

    // safeApprove requires unsetting the allowance first.
    IERC20(token).safeApprove(FACT_ADDRESS, 0);
    IERC20(token).safeApprove(FACT_ADDRESS, amount);
  
    factAddress.transferERC20(to, token, amount, salt);
    emit WithdrawERC20(orderId, token, to, amount);
  }

  function isNative(IERC20 token_) internal pure returns (bool) {
    return (token_ == ZERO_ADDRESS || token_ == ETH_ADDRESS);
  }

  /**
   * Determine if an address is a signer on this wallet
   *
   * @param signer address to check
   */
  function isAllowedSigner(address signer) public view returns (bool) {
    // Iterate through all signers on the wallet and
    for (uint i = 0; i < signers.length; i++) {
      if (signers[i] == signer) {
        return true;
      }
    }
    return false;
  }
  
  /**
   * Verify that the order id has not been used before and inserts it. Throws if the order ID was not accepted.
   *
   * @param orderId   the unique order id 
   * @param to        the destination address to send an outgoing transaction
   * @param amount     the amount in Wei to be sent
   * @param token     the address of the ERC20 contract
   */
  function tryInsertOrderId(
      uint256 orderId, 
      address to,
      uint256 amount, 
      address token
    ) internal {
    if (orders[orderId].executed) {
        // This order ID has been excuted before. Disallow!
        revert("repeated order");
    }

    orders[orderId].executed = true;
    orders[orderId].to = to;
    orders[orderId].amount = amount;
    orders[orderId].token = token;
  }

  /**
   * calcSigHash is a helper function that to help you generate the sighash needed for withdrawal.
   *
   * @param to          the destination address
   * @param amount       the amount in Wei to be sent
   * @param token       the address of the ERC20 contract
   * @param expireTime  the number of seconds since 1970 for which this transaction is valid
   * @param orderId     the unique order id 
   * @param isFact      If fact withdraw calc sighash
   * @param salt        Th salt amount to generate fact
   */

  function calcSigHash(
    address to,
    uint256 amount,
    address token,
    uint256 expireTime,
    uint256 orderId,
    bool isFact,
    uint256 salt) public view returns (bytes32) {
    bytes32 operationHash;

    if (isFact) {
      operationHash = keccak256(abi.encodePacked("FAST", to, amount, token, expireTime, salt, orderId, address(this)));
    } else if (token == address(0)) {
      operationHash = keccak256(abi.encodePacked("ETHER", to, amount, expireTime, orderId, address(this)));
    } else {
      operationHash = keccak256(abi.encodePacked("ERC20", to, amount, token, expireTime, orderId, address(this)));
    }
    return operationHash;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./IAggregationExecutor.sol";

interface IAggregationRouterV4 {
    struct SwapDescription {
      IERC20 srcToken;
      IERC20 dstToken;
      address payable srcReceiver;
      address payable dstReceiver;
      uint256 amount;
      uint256 minReturnAmount;
      uint256 flags;
      bytes permit;
    }

    function swap(
        IAggregationExecutor caller,
        SwapDescription calldata desc,
        bytes calldata data
    )
        external
        payable
        returns (
            uint256 returnAmount,
            uint256 spentAmount,
            uint256 gasLeft
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;
    function approve(address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IStarkEx  {
    function getEthKey(
        uint256 starkKey
    ) external view returns (address);

    function isMsgSenderKeyOwner(
        uint256 ownerKey
    ) external view returns (bool);

    function registerEthAddress(
        address ethKey,
        uint256 starkKey,
        bytes calldata starkSignature
    ) external;

    function depositERC20(
        uint256 starkKey,
        uint256 assetType,
        uint256 vaultId,
        uint256 quantizedAmount
    ) external;

    function getWithdrawalBalance(
        uint256 starkKey,
        uint256 assetId
    ) external view returns (uint256 balance);

    function withdraw(
        uint256 starkKey, 
        uint256 assetId
    ) external;

    function forcedWithdrawalRequest(
        uint256 starkKey,
        uint256 vaultId,
        uint256 quantizedAmount,
        bool premiumCost
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFactRegister {
    function isValid(bytes32 fact) external view returns (bool);

    function transferERC20(
        address recipient,
        address erc20,
        uint256 amount,
        uint256 salt
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IAggregationExecutor {
    function callBytes(bytes calldata data) external payable;
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}
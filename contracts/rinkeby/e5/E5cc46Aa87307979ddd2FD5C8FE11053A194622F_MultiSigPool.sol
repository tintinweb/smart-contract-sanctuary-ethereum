// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "../interfaces/IOneSplit.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IStarkEx.sol";
import "../interfaces/IFactRegister.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 *
 * MultiSigPool
 * ============
 *
 * Basic multi-signer wallet designed for use in a co-signing environment where 2 signatures are require to move funds.
 * Typically used in a 2-of-3 signing configuration. Uses ecrecover to allow for 2 signatures in a single transaction.
 *
 * The signatures are created on the operation hash (see Data Formats) and passed to withdrawETH/withdrawToken
 * The signer is determined by verifyMultiSig().
 *
 * Data Formats
 * ============
 *
 * The signature is created with ethereumjs-util.ecsign(operationHash).
 * Like the eth_sign RPC call, it packs the values as a 65-byte array of [r, s, v].
 * Unlike eth_sign, the message is not prefixed.
 *
 * The operationHash the result of keccak256(prefix, to, value, fee, data, expireTime, walletAddress).
 * For ether transactions, `prefix` is "ETHER" and `data` is null.
 * For token transaction, `prefix` is "ERC20" and `data` is the tokenContractAddress.
 *
 */
contract MultiSigPool is ReentrancyGuard {
  using SafeERC20 for IERC20;

  // Events
  event Deposit(address from, uint256 starkKey, uint256 value);
  event WithdrawETH(address to, uint256 value);
  event WithdrawERC20(address token, address to, uint256 value);

  // Public fields
  address immutable public WETH_ADDRESS; // WETH contract address
  address immutable public USDC_ADDRESS; // USDC contract address
  address immutable public STARKEX_ADDRESS; // stark exchane adress
  address immutable public FACT_ADDRESS; // stark factory adress
  address immutable public ONE_SPLIT_ADDRESS; // 1inch exchange contract address
  address[] public signers; // The addresses that can co-sign transactions on the wallet
  mapping(uint256 => order) orders;    // history orders

  uint256 PARTS = uint256(10);
  uint256 FLAGS = uint256(0);

  struct order{
    address to; // The address the transaction was sent to
    uint256 value; // Amount of Wei sent to the address
    address token; // The address of the erc20 token contract, 0 means ETH
    bool executed; // If the order was executed
  }

  /**
   * Set up a simple 2-3 multi-sig wallet by specifying the signers allowed to be used on this wallet.
   * 2 signers will be require to send a transaction from this wallet.
   * Note: The sender is NOT automatically added to the list of signers.
   * Signers CANNOT be changed once they are set
   *
   * @param allowedSigners An array of signers on the wallet
   * @param usdc USDC contract address
   * @param onesplit The 1inch exchange router address
   * @param starkex The stark exchange address
   * @param fact The stark fact address
   */
  constructor(address[] memory allowedSigners,address weth, address usdc,address onesplit,address starkex, address fact) {
    require(allowedSigners.length == 3, "invalid allSigners length");
    require(allowedSigners[0] != allowedSigners[1], "must be different signers");
    require(allowedSigners[0] != allowedSigners[2], "must be different signers");
    require(allowedSigners[1] != allowedSigners[2], "must be different signers");

    signers = allowedSigners;
    WETH_ADDRESS = weth;
    USDC_ADDRESS = usdc;
    ONE_SPLIT_ADDRESS = onesplit;
    STARKEX_ADDRESS = starkex;
    FACT_ADDRESS = fact;
  }

  /**
   * Determine if an address is a signer on this wallet
   * @param signer address to check
   * returns boolean indicating whether address is signer or not
   */
  function isSigner(address signer) public view returns (bool) {
    // Iterate through all signers on the wallet and
    for (uint i = 0; i < signers.length; i++) {
      if (signers[i] == signer) {
        return true;
      }
    }
    return false;
  }

  /**
   * Gets called when a transaction is received without calling a method
   */
  receive() external payable { }

  /**
   * Deposit ETH and auto swap to USDC
   */
  function depositETH(uint256 starkKey) public payable nonReentrant {
    require(msg.value > 0, "invalid value");

    IWETH weth = IWETH(WETH_ADDRESS);
    weth.deposit{value: msg.value}();
    weth.approve(ONE_SPLIT_ADDRESS, msg.value);

    IERC20 fromIERC20 = IERC20(WETH_ADDRESS);
    IERC20 toIERC20 = IERC20(USDC_ADDRESS);

    IOneSplit oneSplitContract = IOneSplit(ONE_SPLIT_ADDRESS);
    (uint256 minReturn, uint256[] memory distribution) = oneSplitContract.getExpectedReturn(fromIERC20, toIERC20, msg.value, PARTS, FLAGS);
    uint256 returnAmount = oneSplitContract.swap(fromIERC20, toIERC20, msg.value, minReturn, distribution, FLAGS);
    emit Deposit(msg.sender, starkKey,returnAmount);
  }

   /**
   * Deposit ERC20token and auto swap to USDC
   */
  function depositERC20(address token, uint256 starkKey,uint256 amount) public payable nonReentrant {
    require(amount > 0, "invalid amount");

    IERC20 fromIERC20 = IERC20(token);
    fromIERC20.transferFrom(msg.sender, address(this), amount);

    if (token != USDC_ADDRESS) {
      fromIERC20.approve(ONE_SPLIT_ADDRESS, amount);
      IERC20 toIERC20 = IERC20(USDC_ADDRESS);

      IOneSplit oneSplitContract = IOneSplit(ONE_SPLIT_ADDRESS);
      (uint256 minReturn, uint256[] memory distribution) = oneSplitContract.getExpectedReturn(fromIERC20, toIERC20, msg.value, PARTS, FLAGS);
      uint256 returnAmount = oneSplitContract.swap(fromIERC20, toIERC20, msg.value, minReturn, distribution, FLAGS);
      emit Deposit(msg.sender, starkKey,returnAmount);
    } else{
      emit Deposit(msg.sender,starkKey, amount);
    }
  }

  /**
   * Execute a multi-signature transaction from this wallet using 2 signers.
   *
   * @param to the destination address to send an outgoing transaction
   * @param value the amount in Wei to be sent
   * @param expireTime the number of seconds since 1970 for which this transaction is valid
   * @param orderId the unique order id 
   * @param allSigners all signers who sign the tx
   * @param signatures the signatures of tx
   */
  function withdrawETH(
    address payable to,
    uint256 value,
    uint256 expireTime,
    uint256 orderId,
    address[] memory allSigners,
    bytes[] memory signatures
  ) public nonReentrant {
    require(allSigners.length >= 2, "invalid allSigners length");
    require(allSigners.length == signatures.length, "invalid signatures length");
    require(allSigners[0] != allSigners[1],"can not be same signer"); // must be different signer

    bytes32 operationHash = keccak256(abi.encodePacked("ETHER", to, value, expireTime, orderId, address(this)));

    for (uint8 index = 0; index < allSigners.length; index++) {
        address revocedSigner = verifyMultiSig(operationHash, signatures[index], expireTime);
        require(revocedSigner == allSigners[index], "invalid signer");
    }

    // Try to insert the order ID. Will revert if the order id was invalid
    tryInsertorderId(orderId, to, value, address(0));

    // Success, send the transaction
    if (!to.send(value)){
      revert("ETHER balance not enough");
    }
    emit WithdrawETH(to, value);
  }
  
  /**
   * Execute a multi-signature token transfer from this wallet using 2 signers.
   *
   * @param to the destination address to send an outgoing transaction
   * @param value the amount in tokens to be sent
   * @param token the address of the erc20 token contract
   * @param expireTime the number of seconds since 1970 for which this transaction is valid
   * @param orderId the unique order id 
   * @param allSigners all signer who sign the tx
   * @param signatures the signatures of tx
   */
  function withdrawErc20(
    address to,
    uint256 value,
    address token,
    uint256 expireTime,
    uint256 orderId,
    address[] memory allSigners,
    bytes[] memory signatures
  ) public nonReentrant {
    require(allSigners.length >=2, "invalid allSigners length");
    require(allSigners.length == signatures.length, "invalid signatures length");
    require(allSigners[0] != allSigners[1],"can not be same signer"); // must be different signer

    bytes32 operationHash = keccak256(abi.encodePacked("ERC20", to, value, token, expireTime, orderId, address(this)));
    
    for (uint8 index = 0; index < allSigners.length; index++) {
        address revocedSigner = verifyMultiSig(operationHash, signatures[index], expireTime);
        require(revocedSigner == allSigners[index], "invalid signer");
    }

    // Try to insert the order ID. Will revert if the order id was invalid
    tryInsertorderId(orderId, to, value, token);

    // Success, send ERC20 token
    IERC20 erc20 = IERC20(token);
    if (!erc20.transfer(to, value)) {
      // Failed executing transaction
      revert("ERC20 balance not enough");
    }
    emit WithdrawERC20(token, to, value);
  }

  /**
   * Execute a multi-signature token fact transfer from this wallet using 2 signers.
   *
   * @param to the destination address to send an outgoing transaction
   * @param amount the amount in tokens to be sent
   * @param token the address of the erc20 token contract
   * @param salt salt value to generate fact
   * @param expireTime the number of seconds since 1970 for which this transaction is valid
   * @param allSigners all signer who sign the tx
   * @param signatures the signatures of tx
   */
  function factTransferErc20(
    address to,
    address token,
    uint256 amount,
    uint256 salt,
    uint256 expireTime,
    address[] memory allSigners,
    bytes[] memory signatures
  ) public nonReentrant {
    require(token == USDC_ADDRESS,"invalid erc20 token");
    require(allSigners.length >=2, "invalid allSigners length");
    require(allSigners.length == signatures.length, "invalid signatures length");
    require(allSigners[0] != allSigners[1],"can not be same signer"); // must be different signer

    bytes32 transferFact = keccak256(abi.encodePacked(to, amount, token, salt));
    for (uint8 index = 0; index < allSigners.length; index++) {
        address revocedSigner = verifyMultiSig(transferFact, signatures[index], expireTime);
        require(revocedSigner == allSigners[index], "invalid signer");
    }
    // check fact 
    IFactRegister factAddress = IFactRegister(FACT_ADDRESS);
    if (factAddress.isValid(transferFact)) {
      revert("fact already isValid");
    }
    // Success, send ERC20 token
    IERC20 erc20 = IERC20(token);
    if (!erc20.approve(FACT_ADDRESS, amount)) {
      // Failed executing transaction
      revert("approve for FACT_ADDRESS error");
    }
    factAddress.transferERC20(to, token, amount, salt);
    //emit WithdrawERC20(erc20, recipient, amount);
  }
  
  /**
   * Do common multisig verification for both eth sends and erc20token transfers
   *
   * @param operationHash see Data Formats
   * @param signature see Data Formats
   * @param expireTime the number of seconds since 1970 for which this transaction is valid
   * returns address that has created the signature
   */
  function verifyMultiSig(
      bytes32 operationHash,
      bytes memory signature,
      uint256 expireTime
  )  internal  view returns (address) {
    // Verify that the transaction has not expired
    if (expireTime < block.timestamp) {
      // Transaction expired
      revert("expired transaction");
    }
    
    // Verify the signer is one of the signers
    address txSigner = recover(operationHash, signature);
    if (!isSigner(txSigner)) {
      // The signer not on this wallet or operation does not match arguments
      revert("verify invalid signer");
    }

    return txSigner;
  }

  /**
   * @dev Recover signer address from a message by using his signature
   * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param sig bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 hash, bytes memory sig) public pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    if (sig.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }
    
    // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
    // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
    // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
    // these malleable signatures as well.
    require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
    require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

    // If the signature is valid (and not malleable), return the signer address
    address signer = ecrecover(hash, v, r, s);
    require(signer != address(0), "ECDSA: invalid signature");

    return signer;
  }

  /**
   * Gets signer's address using ecrecover
   * @param proveHash see Data Formats
   * @param sig see Data Formats
   * returns address recovered from the signature
   */
  function getSigner(bytes32 proveHash, bytes memory sig) public pure returns (address) {
    return recover(proveHash,sig);
  }

  /**
   * Verify that the order id has not been used before and inserts it. Throws if the order ID was not accepted.
   * @param orderId to insert into array of stored ids
   * @param to the destination address to send an outgoing transaction
   * @param value the amount in Wei to be sent
   * @param token the address of the ERC20 contract
   */
  function tryInsertorderId(
      uint256 orderId, 
      address to,
      uint256 value, 
      address token
    ) internal {
    if (orders[orderId].executed) {
        // This order ID has been excuted before. Disallow!
        revert("repeated order");
    }

    orders[orderId].executed = true;
    orders[orderId].to = to;
    orders[orderId].value = value;
    orders[orderId].token = token;
  }

  function calcSigHash(
    address to,
    uint256 value,
    address token,
    uint256 expireTime,
    uint256 orderId) public view returns (bytes32) {
    bytes32 operationHash;
    if (token == address(0)) {
      operationHash = keccak256(abi.encodePacked("ETHER", to, value, expireTime, orderId, address(this)));
    } else {
      operationHash = keccak256(abi.encodePacked("ERC20", to, value, token, expireTime, orderId, address(this)));
    }
    return operationHash;
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//
//  [ msg.sender ]
//       | |
//       | |
//       \_/
// +---------------+ ________________________________
// | OneSplitAudit | _______________________________  \
// +---------------+                                 \ \
//       | |                      ______________      | | (staticcall)
//       | |                    /  ____________  \    | |
//       | | (call)            / /              \ \   | |
//       | |                  / /               | |   | |
//       \_/                  | |               \_/   \_/
// +--------------+           | |           +----------------------+
// | OneSplitWrap |           | |           |   OneSplitViewWrap   |
// +--------------+           | |           +----------------------+
//       | |                  | |                     | |
//       | | (delegatecall)   | | (staticcall)        | | (staticcall)
//       \_/                  | |                     \_/
// +--------------+           | |             +------------------+
// |   OneSplit   |           | |             |   OneSplitView   |
// +--------------+           | |             +------------------+
//       | |                  / /
//        \ \________________/ /
//         \__________________/
//
    
interface IOneSplit  {
    function getExpectedReturn(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See constants in IOneSplit.sol
    )
        external
        view
        returns(
            uint256 returnAmount,
            uint256[] memory distribution
        );

    function getExpectedReturnWithGas(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags, // See constants in IOneSplit.sol
        uint256 destTokenEthPriceTimesGasPrice
    )
        external
        view
        returns(
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        );

    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 flags
    )
        external
        payable
        returns(uint256 returnAmount);
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
    // 通过ownerKey获取对应的ownerETH地址
    function getEthKey(
        uint256 starkKey
    ) external view returns (address);

    // 查询当前地址是否为keyowner
    function isMsgSenderKeyOwner(
        uint256 ownerKey
    ) external view returns (bool);

    // 绑定ownerKey
    function registerEthAddress(
        address ethKey,
        uint256 starkKey,
        bytes calldata starkSignature
    ) external;

    // 查询充值金额
    // function getDepositBalance(
    //     uint256 starkKey,
    //     uint256 assetId,
    //     uint256 vaultId
    // ) external view returns (uint256 balance);

    // 充值ERC20
    function depositERC20(
        uint256 starkKey,
        uint256 assetType,
        uint256 vaultId,
        uint256 quantizedAmount
    ) external;

    // 查询可提现金额
    function getWithdrawalBalance(
        uint256 starkKey,
        uint256 assetId
    ) external view returns (uint256 balance);

    // 提现
    function withdraw(
        uint256 starkKey, 
        uint256 assetId
    ) external;

    // 强制提现(一般不会用到)
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
    /*
      Returns true if the given fact was previously registered in the contract.
    */
    function isValid(bytes32 fact) external view returns (bool);

    // 负责转账ERC20代币，并生成相应的fact
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
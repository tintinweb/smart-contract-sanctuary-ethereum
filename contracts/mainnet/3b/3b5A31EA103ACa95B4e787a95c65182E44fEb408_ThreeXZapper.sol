// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
        assembly {
            size := extcodesize(account)
        }
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

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IThreeXBatchProcessing } from "../../interfaces/IThreeXBatchProcessing.sol";
import { BatchType, IAbstractBatchStorage } from "../../interfaces/IBatchStorage.sol";
import "../../../externals/interfaces/Curve3Pool.sol";
import "../../interfaces/IContractRegistry.sol";

/*
 * This Contract allows user to use and receive stablecoins directly when interacting with ThreeXBatchProcessing.
 * This contract takes DAI or USDT swaps them into USDC and deposits them or the other way around.
 */
contract ThreeXZapper {
  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */

  IContractRegistry private contractRegistry;
  Curve3Pool private threePool;
  IERC20[3] public token; // [dai,usdc,usdt]

  /* ========== EVENTS ========== */

  event ZappedIntoBatch(uint256 outputAmount, address account);
  event ZappedOutOfBatch(
    bytes32 batchId,
    int128 stableCoinIndex,
    uint256 inputAmount,
    uint256 outputAmount,
    address account
  );
  event ClaimedIntoStable(
    bytes32 batchId,
    int128 stableCoinIndex,
    uint256 inputAmount,
    uint256 outputAmount,
    address account
  );

  /* ========== CONSTRUCTOR ========== */

  constructor(
    IContractRegistry _contractRegistry,
    Curve3Pool _threePool,
    IERC20[3] memory _token
  ) {
    contractRegistry = _contractRegistry;
    threePool = _threePool;
    token = _token;
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
   * @notice zapIntoBatch allows a user to deposit into a mintBatch directly with DAI or USDT
   * @param _amount Input Amount
   * @param _i Index of inputToken
   * @param _j Index of outputToken
   * @param _min_amount The min amount of USDC which should be returned by the ThreePool (slippage control) should be taking the decimals of the outputToken into account
   * @dev The amounts in _amounts must align with their index in the ThreePool
   */
  function zapIntoBatch(
    uint256 _amount,
    int128 _i,
    int128 _j,
    uint256 _min_amount // todo add instamint/redeem bool arg which calls batchMint()
  ) external {
    IThreeXBatchProcessing butterBatchProcessing = IThreeXBatchProcessing(
      contractRegistry.getContract(keccak256("ThreeXBatchProcessing"))
    );

    token[uint256(uint128(_i))].safeTransferFrom(msg.sender, address(this), _amount);

    uint256 stableBalance = _swapStables(_i, _j, _amount);

    require(stableBalance >= _min_amount, "slippage too high");

    // Deposit USDC in current mint batch
    butterBatchProcessing.depositForMint(stableBalance, msg.sender);
    emit ZappedIntoBatch(stableBalance, msg.sender);
  }

  /**
   * @notice zapOutOfBatch allows a user to retrieve their not yet processed USDC and directly receive DAI or USDT
   * @param _batchId Defines which batch gets withdrawn from
   * @param _amountToWithdraw USDC amount that shall be withdrawn
   * @param _i Index of inputToken
   * @param _j Index of outputToken
   * @param _min_amount The min amount of USDC which should be returned by the ThreePool (slippage control) should be taking the decimals of the outputToken into account
   */
  function zapOutOfBatch(
    bytes32 _batchId,
    uint256 _amountToWithdraw,
    int128 _i,
    int128 _j,
    uint256 _min_amount
  ) external {
    IThreeXBatchProcessing butterBatchProcessing = IThreeXBatchProcessing(
      contractRegistry.getContract(keccak256("ThreeXBatchProcessing"))
    );

    IAbstractBatchStorage batchStorage = butterBatchProcessing.batchStorage();

    require(batchStorage.getBatchType(_batchId) == BatchType.Mint, "!mint");

    uint256 withdrawnAmount = butterBatchProcessing.withdrawFromBatch(
      _batchId,
      _amountToWithdraw,
      msg.sender,
      address(this)
    );

    uint256 stableBalance = _swapStables(_i, _j, withdrawnAmount);

    require(stableBalance >= _min_amount, "slippage too high");

    token[uint256(uint128(_j))].safeTransfer(msg.sender, stableBalance);

    emit ZappedOutOfBatch(_batchId, _j, withdrawnAmount, stableBalance, msg.sender);
  }

  /**
   * @notice claimAndSwapToStable allows a user to claim their processed USDC from a redeemBatch and directly receive DAI or USDT
   * @param _batchId Defines which batch gets withdrawn from
   * @param _i Index of inputToken
   * @param _j Index of outputToken
   * @param _min_amount The min amount of USDC which should be returned by the ThreePool (slippage control) should be taking the decimals of the outputToken into account
   */
  function claimAndSwapToStable(
    bytes32 _batchId,
    int128 _i,
    int128 _j,
    uint256 _min_amount
  ) external {
    IThreeXBatchProcessing butterBatchProcessing = IThreeXBatchProcessing(
      contractRegistry.getContract(keccak256("ThreeXBatchProcessing"))
    );
    IAbstractBatchStorage batchStorage = butterBatchProcessing.batchStorage();

    require(batchStorage.getBatchType(_batchId) == BatchType.Redeem, "!redeem");

    uint256 inputAmount = butterBatchProcessing.claim(_batchId, msg.sender);
    uint256 stableBalance = _swapStables(_i, _j, inputAmount);

    require(stableBalance >= _min_amount, "slippage too high");

    token[uint256(uint128(_j))].safeTransfer(msg.sender, stableBalance);

    emit ClaimedIntoStable(_batchId, _j, inputAmount, stableBalance, msg.sender);
  }

  function _swapStables(
    int128 _fromIndex,
    int128 _toIndex,
    uint256 _inputAmount
  ) internal returns (uint256) {
    threePool.exchange(_fromIndex, _toIndex, _inputAmount, 0);
    return token[uint256(uint128(_toIndex))].balanceOf(address(this));
  }

  /**
   * @notice set idempotent approvals for threePool and butter batch processing
   */
  function setApprovals() external {
    for (uint256 i; i < token.length; i++) {
      token[i].safeApprove(address(threePool), 0);
      token[i].safeApprove(address(threePool), type(uint256).max);

      token[i].safeApprove(contractRegistry.getContract(keccak256("ThreeXBatchProcessing")), 0);
      token[i].safeApprove(contractRegistry.getContract(keccak256("ThreeXBatchProcessing")), type(uint256).max);
    }
  }
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IClientBatchStorageAccess } from "./IClientBatchStorageAccess.sol";
/**
 * @notice Defines if the Batch will mint or redeem 3X
 */
enum BatchType {
  Mint,
  Redeem
}

/**
 * @notice The Batch structure is used both for Batches of Minting and Redeeming
 * @param batchType Determines if this Batch is for Minting or Redeeming 3X
 * @param batchId bytes32 id of the batch
 * @param claimable Shows if a batch has been processed and is ready to be claimed, the suppliedToken cant be withdrawn if a batch is claimable
 * @param unclaimedShares The total amount of unclaimed shares in this batch
 * @param sourceTokenBalance The total amount of deposited token (either DAI or 3X)
 * @param claimableTokenBalance The total amount of claimable token (either sUSD or 3X)
 * @param sourceToken the token one supplies for minting/redeeming another token. the token collateral used to mint or redeem a mintable/redeemable token
 * @param targetToken the token that is claimable after providing the suppliedToken for mint/redeem. the token that a mintable/redeemable token turns into during mint/redeem
 * @param owner address of client (controller contract) that owns this batch and has access rights to it. this makes it so that all balances are isolated and not accessible by other clients that added to this contract over time
 * todo add deposit caps
 */
struct Batch {
  bytes32 id;
  BatchType batchType;
  bytes32 batchId;
  bool claimable;
  uint256 unclaimedShares;
  uint256 sourceTokenBalance;
  uint256 targetTokenBalance;
  IERC20 sourceToken;
  IERC20 targetToken;
  address owner;
}

/**
 * @notice Each type of batch (mint/redeem) have a source token and target token.
 * @param targetToken the token which is minted or redeemed for
 * @param sourceToken the token which is supplied to the batch to be minted/redeemed
 */
struct BatchTokens {
  IERC20 targetToken;
  IERC20 sourceToken;
}

interface IViewableBatchStorage {
  function getAccountBatches(address account) external view returns (bytes32[] memory);

  function getBatch(bytes32 batchId) external view returns (Batch memory);

  function getBatchIds(uint256 index) external view returns (Batch memory);

  function getAccountBalance(bytes32 batchId, address owner) external view returns (uint256);
}

interface IAbstractBatchStorage is IClientBatchStorageAccess {
  function getBatchType(bytes32 batchId) external view returns (BatchType);

  /* ========== VIEW ========== */

  function previewClaim(
    bytes32 batchId,
    address owner,
    uint256 shares
  )
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );

  /* ========== SETTER ========== */

  function claim(
    bytes32 batchId,
    address owner,
    uint256 shares,
    address recipient
  ) external returns (uint256, uint256);

  /**
   * @notice This function allows a user to withdraw their funds from a batch before that batch has been processed
   * @param batchId From which batch should funds be withdrawn from
   * @param owner address that owns the account balance
   * @param amount amount of tokens to withdraw from batch
   * @param recipient address that will receive the token transfer. if address(0) then no transfer is made
   */
  function withdraw(
    bytes32 batchId,
    address owner,
    uint256 amount,
    address recipient
  ) external returns (uint256);

  function deposit(
    bytes32 batchId,
    address owner,
    uint256 amount
  ) external returns (uint256);

  /**
   * @notice approve allows the client contract to approve an address to be the recipient of a withdrawal or claim
   */
  function approve(
    IERC20 token,
    address delegatee,
    bytes32 batchId,
    uint256 amount
  ) external;

  /**
   * @notice This function transfers the batch source tokens to the client usually for a minting or redeming operation
   * @param batchId From which batch should funds be withdrawn from
   */
  function withdrawSourceTokenFromBatch(bytes32 batchId) external returns (uint256);

  /**
   * @notice Moves funds from unclaimed batches into the current mint/redeem batch
   * @param _sourceBatch the id of the claimable batch
   * @param _destinationBatch the id of the redeem batch
   * @param owner owner of the account balance
   * @param shares how many shares should be claimed
   */
  function moveUnclaimedIntoCurrentBatch(
    bytes32 _sourceBatch,
    bytes32 _destinationBatch,
    address owner,
    uint256 shares
  ) external returns (uint256);

  function depositTargetTokensIntoBatch(bytes32 id, uint256 amount) external returns (bool);

  function createBatch(BatchType _batchType, BatchTokens memory _tokens) external returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IClientBatchStorageAccess {
  function grantClientAccess(address newClient) external;

  function revokeClientAccess(address client) external;

  function acceptClientAccess(address grantingAddress) external;

  function addClient(address _address) external;

  function removeClient(address _address) external;
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity >=0.6.12;

/**
 * @dev External interface of ContractRegistry.
 */
interface IContractRegistry {
  function getContract(bytes32 _name) external view returns (address);

  function getContractIdFromAddress(address _contractAddress) external view returns (bytes32);

  function addContract(
    bytes32 _name,
    address _address,
    bytes32 _version
  ) external;
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import { BatchType, IAbstractBatchStorage, Batch } from "./IBatchStorage.sol";

interface IThreeXBatchProcessing {
  function batchStorage() external returns (IAbstractBatchStorage);

  function getBatch(bytes32 batchId) external view returns (Batch memory);

  function depositForMint(uint256 amount_, address account_) external;

  function depositForRedeem(uint256 amount_) external;

  function claim(bytes32 batchId_, address account_) external returns (uint256);

  function withdrawFromBatch(
    bytes32 batchId_,
    uint256 amountToWithdraw_,
    address account_
  ) external returns (uint256);

  function withdrawFromBatch(
    bytes32 batchId_,
    uint256 amountToWithdraw_,
    address _withdrawFor,
    address _recipient
  ) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

interface Curve3Pool {
  function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amounts) external;

  function remove_liquidity_one_coin(
    uint256 burn_amount,
    int128 i,
    uint256 min_amount
  ) external;

  function get_virtual_price() external view returns (uint256);

  function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

  function coins(uint256 i) external view returns (address);

  function calc_token_amount(uint256[3] calldata amounts, bool deposit) external view returns (uint256);

  function exchange(
    int128 i,
    int128 j,
    uint256 dx,
    uint256 min_dy
  ) external;
}
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title ConnextRouter.
 * @author Fujidao Labs
 * @notice A Router implementing Connext specific bridging logic.
 */

import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IConnext, IXReceiver} from "../interfaces/connext/IConnext.sol";
import {BaseRouter} from "../abstracts/BaseRouter.sol";
import {IWETH9} from "../abstracts/WETH9.sol";
import {IVault} from "../interfaces/IVault.sol";
import {IChief} from "../interfaces/IChief.sol";

contract ConnextRouter is BaseRouter, IXReceiver {
  /**
   * @notice Emitted when a new destination router gets added.
   * @param router - The router on another chain.
   * @param domain - The destination domain identifier according Connext nomenclature.
   */
  event NewRouterAdded(address indexed router, uint256 indexed domain);

  /**
   * @notice Emitted when Connext `xCall` is invoked.
   * @param transferId - The unique identifier of the crosschain transfer.
   * @param caller - The account that called the function.
   * @param receiver - The router on destDomain.
   * @param destDomain - The destination domain identifier according Connext nomenclature.
   * @param asset - The asset being transferred.
   * @param amount - The amount of transferring asset the recipient address receives.
   * @param callData - The calldata sent to destination router that will get decoded and executed.
   */
  event XCalled(
    bytes32 indexed transferId,
    address indexed caller,
    address indexed receiver,
    uint256 destDomain,
    address asset,
    uint256 amount,
    bytes callData
  );

  /**
   * @notice Emitted when the router receives a cross-chain call.
   * @param transferId - The unique identifier of the crosschain transfer.
   * @param originDomain - The origin domain identifier according Connext nomenclature.
   * @param success - Whether or not the xBundle call succeeds.
   * @param asset - The asset being transferred.
   * @param amount - The amount of transferring asset the recipient address receives.
   * @param callData - The calldata that will get decoded and executed.
   */
  event XReceived(
    bytes32 indexed transferId,
    uint256 indexed originDomain,
    bool success,
    address asset,
    uint256 amount,
    bytes callData
  );

  error ConnextRouter__setRouter_invalidInput();

  // The connext contract on the origin domain.
  IConnext public immutable connext;

  // ref: https://docs.nomad.xyz/developers/environments/domain-chain-ids
  mapping(uint256 => address) public routerByDomain;

  constructor(IWETH9 weth, IConnext connext_, IChief chief) BaseRouter(weth, chief) {
    connext = connext_;
  }

  // Connext specific functions

  /**
   * @notice Called by Connext on the destination chain. It doesn't perform an authentification
   * by doing a check on `originSender`. As a result of that, all txns go through the fast path.
   * If `xBundle` fails on our side, this contract will keep the custody of the sent funds.
   *
   * @param transferId - The unique identifier of the crosschain transfer.
   * @param amount - The amount of transferring asset the recipient address receives.
   * @param asset - The asset being transferred.
   * @param originDomain - The origin domain identifier according Connext nomenclature.
   * @param callData - The calldata that will get decoded and executed.
   */
  function xReceive(
    bytes32 transferId,
    uint256 amount,
    address asset,
    address, /* originSender */
    uint32 originDomain,
    bytes memory callData
  )
    external
    returns (bytes memory)
  {
    (Action[] memory actions, bytes[] memory args) = abi.decode(callData, (Action[], bytes[]));

    try this.xBundle(actions, args) {
      emit XReceived(transferId, originDomain, true, asset, amount, callData);
    } catch {
      // else keep funds in router and let them be handled by admin
      emit XReceived(transferId, originDomain, false, asset, amount, callData);
    }

    return "";
  }

  function _crossTransfer(bytes memory params) internal override {
    (
      uint256 destDomain,
      uint256 slippage,
      address asset,
      uint256 amount,
      address receiver,
      address sender
    ) = abi.decode(params, (uint256, uint256, address, uint256, address, address));

    _safePullTokenFrom(asset, sender, receiver, amount);
    _safeApprove(asset, address(connext), amount);

    bytes32 transferId = connext.xcall(
      // _destination: Domain ID of the destination chain
      uint32(destDomain),
      // _to: address of the target contract
      receiver,
      // _asset: address of the token contract
      asset,
      // _delegate: address that has rights to update the original slippage tolerance
      // by calling Connext's forceUpdateSlippage function
      msg.sender,
      // _amount: amount of tokens to transfer
      amount,
      // _slippage: can be anything between 0-10000 becaus
      // the maximum amount of slippage the user will accept in BPS, 30 == 0.3%
      slippage,
      // _callData: empty because we're only sending funds
      ""
    );
    emit XCalled(transferId, msg.sender, receiver, destDomain, asset, amount, "");
  }

  function _crossTransferWithCalldata(bytes memory params) internal override {
    (uint256 destDomain, uint256 slippage, address asset, uint256 amount, bytes memory callData) =
      abi.decode(params, (uint256, uint256, address, uint256, bytes));

    _safePullTokenFrom(asset, msg.sender, msg.sender, amount);
    _safeApprove(asset, address(connext), amount);

    bytes32 transferId = connext.xcall(
      // _destination: Domain ID of the destination chain
      uint32(destDomain),
      // _to: address of the target contract
      routerByDomain[destDomain],
      // _asset: address of the token contract
      asset,
      // _delegate: address that can revert or forceLocal on destination
      msg.sender,
      // _amount: amount of tokens to transfer
      amount,
      // _slippage: can be anything between 0-10000 becaus
      // the maximum amount of slippage the user will accept in BPS, 30 == 0.3%
      slippage,
      // _callData: the encoded calldata to send
      callData
    );

    emit XCalled(
      transferId, msg.sender, routerByDomain[destDomain], destDomain, asset, amount, callData
      );
  }

  /**
   * @notice Anyone can call this function on the origin domain to increase the relayer fee for a transfer.
   * @param transferId - The unique identifier of the crosschain transaction
   */
  function bumpTransfer(bytes32 transferId) external payable {
    connext.bumpTransfer{value: msg.value}(transferId);
  }

  ///////////////////////
  /// Admin functions ///
  ///////////////////////

  function setRouter(uint256 domain, address router) external onlyTimelock {
    if (router == address(0)) {
      revert ConnextRouter__setRouter_invalidInput();
    }
    routerByDomain[domain] = router;

    emit NewRouterAdded(router, domain);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @notice These are the parameters that will remain constant between the
 * two chains. They are supplied on `xcall` and should be asserted on `execute`
 * @property to - The account that receives funds, in the event of a crosschain call,
 * will receive funds if the call fails.
 *
 * @param originDomain - The originating domain (i.e. where `xcall` is called). Must match nomad domain schema
 * @param destinationDomain - The final domain (i.e. where `execute` / `reconcile` are called). Must match nomad domain schema
 * @param canonicalDomain - The canonical domain of the asset you are bridging
 * @param to - The address you are sending funds (and potentially data) to
 * @param delegate - An address who can execute txs on behalf of `to`, in addition to allowing relayers
 * @param receiveLocal - If true, will use the local nomad asset on the destination instead of adopted.
 * @param callData - The data to execute on the receiving chain. If no crosschain call is needed, then leave empty.
 * @param slippage - Slippage user is willing to accept from original amount in expressed in BPS (i.e. if
 * a user takes 1% slippage, this is expressed as 1_000)
 * @param originSender - The msg.sender of the xcall
 * @param bridgedAmt - The amount sent over the bridge (after potential AMM on xcall)
 * @param normalizedIn - The amount sent to `xcall`, normalized to 18 decimals
 * @param nonce - The nonce on the origin domain used to ensure the transferIds are unique
 * @param canonicalId - The unique identifier of the canonical token corresponding to bridge assets
 */
struct TransferInfo {
  uint32 originDomain;
  uint32 destinationDomain;
  uint32 canonicalDomain;
  address to;
  address delegate;
  bool receiveLocal;
  bytes callData;
  uint256 slippage;
  address originSender;
  uint256 bridgedAmt;
  uint256 normalizedIn;
  uint256 nonce;
  bytes32 canonicalId;
}

/**
 * @notice
 * @param params - The TransferInfo. These are consistent across sending and receiving chains.
 * @param routers - The routers who you are sending the funds on behalf of.
 * @param routerSignatures - Signatures belonging to the routers indicating permission to use funds
 * for the signed transfer ID.
 * @param sequencer - The sequencer who assigned the router path to this transfer.
 * @param sequencerSignature - Signature produced by the sequencer for path assignment accountability
 * for the path that was signed.
 */
struct ExecuteArgs {
  TransferInfo params;
  address[] routers;
  bytes[] routerSignatures;
  address sequencer;
  bytes sequencerSignature;
}

interface IConnext {
  function xcall(
    uint32 _destination,
    address _to,
    address _asset,
    address _delegate,
    uint256 _amount,
    uint256 _slippage,
    bytes calldata _callData
  )
    external
    payable
    returns (bytes32);

  function execute(ExecuteArgs calldata _args)
    external
    returns (bool success, bytes memory returnData);

  function bumpTransfer(bytes32 transferId) external payable;
}

interface IXReceiver {
  function xReceive(
    bytes32 _transferId,
    uint256 _amount,
    address _asset,
    address _originSender,
    uint32 _origin,
    bytes memory _callData
  )
    external
    returns (bytes memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @title Abstract contract for all routers.
 * @author Fujidao Labs
 * @dev Defines the interface and common functions for all routers.
 */

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {IRouter} from "../interfaces/IRouter.sol";
import {ISwapper} from "../interfaces/ISwapper.sol";
import {IVault} from "../interfaces/IVault.sol";
import {IChief} from "../interfaces/IChief.sol";
import {IFlasher} from "../interfaces/IFlasher.sol";
import {IVaultPermissions} from "../interfaces/IVaultPermissions.sol";
import {SystemAccessControl} from "../access/SystemAccessControl.sol";
import {IWETH9} from "../abstracts/WETH9.sol";

abstract contract BaseRouter is SystemAccessControl, IRouter {
  using SafeERC20 for ERC20;

  struct BalanceChecker {
    address token;
    uint256 balance;
  }

  error BaseRouter__bundleInternal_paramsMismatch();
  error BaseRouter__bundleInternal_flashloanInvalidRequestor();
  error BaseRouter__bundleInternal_noRemnantBalance();
  error BaseRouter__bundleInternal_insufficientETH();
  error BaseRouter__bundleInternal_notBeneficiary();
  error BaseRouter__safeTransferETH_transferFailed();
  error BaseRouter__receive_senderNotWETH();
  error BaseRouter__fallback_notAllowed();

  IWETH9 public immutable WETH9;

  BalanceChecker[] private _tokensToCheck;
  address private _beneficiary;

  constructor(IWETH9 weth, IChief chief) SystemAccessControl(address(chief)) {
    WETH9 = weth;
  }

  function xBundle(Action[] memory actions, bytes[] memory args) external payable override {
    _bundleInternal(actions, args);
  }

  /**
   * @dev Sweep accidental ERC-20 transfers to this contract or stuck funds due to failed
   * cross-chain calls (cf. ConnextRouter).
   * @param token The address of the ERC-20 token to sweep.
   * @param receiver The address that will receive the swept funds.
   */
  function sweepToken(ERC20 token, address receiver) external onlyHouseKeeper {
    uint256 balance = token.balanceOf(address(this));
    token.transfer(receiver, balance);
  }

  /**
   * @dev Sweep accidental ETH transfers to this contract.
   * @param receiver The address that will receive the swept funds
   */
  function sweepETH(address receiver) external onlyHouseKeeper {
    uint256 balance = address(this).balance;
    _safeTransferETH(receiver, balance);
  }

  /**
   * @dev executes a bundle of actions.
   *
   * Requirements:
   * - MUST not leave any balance in this contract after all actions.
   */
  function _bundleInternal(Action[] memory actions, bytes[] memory args) internal {
    if (actions.length != args.length) {
      revert BaseRouter__bundleInternal_paramsMismatch();
    }

    uint256 len = actions.length;
    for (uint256 i = 0; i < len;) {
      if (actions[i] == Action.Deposit) {
        // DEPOSIT
        (IVault vault, uint256 amount, address receiver, address sender) =
          abi.decode(args[i], (IVault, uint256, address, address));
        _checkBeneficiary(receiver);

        address token = vault.asset();
        _safePullTokenFrom(token, sender, receiver, amount);
        _safeApprove(token, address(vault), amount);

        vault.deposit(amount, receiver);
      } else if (actions[i] == Action.Withdraw) {
        // WITHDRAW
        (IVault vault, uint256 amount, address receiver, address owner) =
          abi.decode(args[i], (IVault, uint256, address, address));
        _checkBeneficiary(owner);

        // Check balance of `asset` before execution at vault.
        _addTokenToCheck(vault.asset());

        vault.withdraw(amount, receiver, owner);
      } else if (actions[i] == Action.Borrow) {
        // BORROW
        (IVault vault, uint256 amount, address receiver, address owner) =
          abi.decode(args[i], (IVault, uint256, address, address));
        _checkBeneficiary(owner);

        // Check balance of `debtAsset` before execution at vault.
        _addTokenToCheck(vault.debtAsset());

        vault.borrow(amount, receiver, owner);
      } else if (actions[i] == Action.Payback) {
        // PAYBACK
        (IVault vault, uint256 amount, address receiver, address sender) =
          abi.decode(args[i], (IVault, uint256, address, address));
        _checkBeneficiary(receiver);

        address token = vault.debtAsset();
        _safePullTokenFrom(token, sender, receiver, amount);
        _safeApprove(token, address(vault), amount);

        vault.payback(amount, receiver);
      } else if (actions[i] == Action.PermitWithdraw) {
        // PERMIT ASSETS
        (
          IVaultPermissions vault,
          address owner,
          address receiver,
          uint256 amount,
          uint256 deadline,
          uint8 v,
          bytes32 r,
          bytes32 s
        ) = abi.decode(
          args[i], (IVaultPermissions, address, address, uint256, uint256, uint8, bytes32, bytes32)
        );
        vault.permitWithdraw(owner, receiver, amount, deadline, v, r, s);
      } else if (actions[i] == Action.PermitBorrow) {
        // PERMIT BORROW
        (
          IVaultPermissions vault,
          address owner,
          address receiver,
          uint256 amount,
          uint256 deadline,
          uint8 v,
          bytes32 r,
          bytes32 s
        ) = abi.decode(
          args[i], (IVaultPermissions, address, address, uint256, uint256, uint8, bytes32, bytes32)
        );

        vault.permitBorrow(owner, receiver, amount, deadline, v, r, s);
      } else if (actions[i] == Action.XTransfer) {
        // SIMPLE BRIDGE TRANSFER

        _crossTransfer(args[i]);
      } else if (actions[i] == Action.XTransferWithCall) {
        // BRIDGE WITH CALLDATA

        _crossTransferWithCalldata(args[i]);
      } else if (actions[i] == Action.Swap) {
        // SWAP
        (
          ISwapper swapper,
          address assetIn,
          address assetOut,
          uint256 amountIn,
          uint256 amountOut,
          address receiver,
          address sweeper,
          uint256 minSweepOut
        ) = abi.decode(
          args[i], (ISwapper, address, address, uint256, uint256, address, address, uint256)
        );

        _safeApprove(assetIn, address(swapper), amountIn);

        _addTokenToCheck(assetOut);

        swapper.swap(assetIn, assetOut, amountIn, amountOut, receiver, sweeper, minSweepOut);
      } else if (actions[i] == Action.Flashloan) {
        // FLASHLOAN

        // Decode params
        (
          IFlasher flasher,
          address asset,
          uint256 flashAmount,
          address requestor,
          bytes memory requestorCalldata
        ) = abi.decode(args[i], (IFlasher, address, uint256, address, bytes));

        if (requestor != address(this)) {
          revert BaseRouter__bundleInternal_flashloanInvalidRequestor();
        }

        // Call Flasher
        flasher.initiateFlashloan(asset, flashAmount, requestor, requestorCalldata);
      } else if (actions[i] == Action.DepositETH) {
        uint256 amount = abi.decode(args[i], (uint256));

        if (amount != msg.value) {
          revert BaseRouter__bundleInternal_insufficientETH();
        }

        WETH9.deposit{value: msg.value}();

        _addTokenToCheck(address(WETH9));
      } else if (actions[i] == Action.WithdrawETH) {
        (uint256 amount, address receiver) = abi.decode(args[i], (uint256, address));
        _checkBeneficiary(receiver);

        WETH9.withdraw(amount);

        _safeTransferETH(receiver, amount);
      }
      unchecked {
        ++i;
      }
    }
    _checkNoRemnantBalance(_tokensToCheck);
    _checkNoNativeBalance();
  }

  function _safeTransferETH(address receiver, uint256 amount) internal {
    (bool success,) = receiver.call{value: amount}(new bytes(0));
    if (!success) {
      revert BaseRouter__safeTransferETH_transferFailed();
    }
  }

  function _safePullTokenFrom(
    address token,
    address sender,
    address owner,
    uint256 amount
  )
    internal
  {
    // this check is needed because when we bundle mulptiple actions
    // it can happen the router already holds the assets in question;
    // for. example when we withdraw from a vault and deposit to another one
    if (sender != address(this) && (sender == owner || sender == msg.sender)) {
      ERC20(token).safeTransferFrom(sender, address(this), amount);
    }
  }

  function _safeApprove(address token, address to, uint256 amount) internal {
    ERC20(token).safeApprove(to, amount);
  }

  function _crossTransfer(bytes memory) internal virtual;

  function _crossTransferWithCalldata(bytes memory) internal virtual;

  function _addTokenToCheck(address token) private {
    BalanceChecker memory checkedToken =
      BalanceChecker(token, IERC20(token).balanceOf(address(this)));
    _tokensToCheck.push(checkedToken);
  }

  function _checkNoRemnantBalance(BalanceChecker[] memory tokensToCheck) private {
    uint256 tlenght = tokensToCheck.length;
    for (uint256 i = 0; i < tlenght;) {
      uint256 previousBalance = tokensToCheck[i].balance;
      uint256 currentBalance = IERC20(tokensToCheck[i].token).balanceOf(address(this));
      if (currentBalance > previousBalance) {
        revert BaseRouter__bundleInternal_noRemnantBalance();
      }
      unchecked {
        ++i;
      }
    }
    delete _tokensToCheck;
    _beneficiary = address(0);
  }

  function _checkNoNativeBalance() private view {
    if (address(this).balance > 0) {
      revert BaseRouter__bundleInternal_noRemnantBalance();
    }
  }

  function _checkBeneficiary(address user) private {
    // when bundling multiple actions assure that we act for a single beneficiary;
    // receivers on DEPOSIT and PAYBACK and owners on WITHDRAW and BORROW
    // must be the same user
    if (_beneficiary == address(0)) {
      _beneficiary = user;
    } else {
      if (_beneficiary != user) revert BaseRouter__bundleInternal_notBeneficiary();
    }
  }

  /**
   * @dev Only WETH contract is allowed to transfer ETH here.
   * Prevent other addresses to send Ether to this contract.
   */
  receive() external payable {
    if (msg.sender != address(WETH9)) {
      revert BaseRouter__receive_senderNotWETH();
    }
  }

  /**
   * @dev Revert fallback calls
   */
  fallback() external payable {
    revert BaseRouter__fallback_notAllowed();
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

abstract contract IWETH9 is ERC20 {
  /// @notice Deposit ether to get wrapped ether
  function deposit() external payable virtual;

  /// @notice Withdraw wrapped ether to get ether
  function withdraw(uint256) external virtual;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title Vault Interface.
 * @author Fujidao Labs
 * @notice Defines the interface for vault operations extending from IERC4326.
 */

import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import {ILendingProvider} from "./ILendingProvider.sol";
import {IFujiOracle} from "./IFujiOracle.sol";

interface IVault is IERC4626 {
  /// Events
  /**
   * @dev Emitted when borrow action occurs.
   * @param sender address who calls {IVault-borrow}
   * @param receiver address of the borrowed 'debt' amount
   * @param owner address who will incur the debt
   * @param debt amount
   * @param shares amound of 'debtShares' received
   */
  event Borrow(
    address indexed sender,
    address indexed receiver,
    address indexed owner,
    uint256 debt,
    uint256 shares
  );

  /**
   * @dev Emitted when borrow action occurs.
   * @param sender address who calls {IVault-payback}
   * @param owner address whose debt will be reduced
   * @param debt amount
   * @param shares amound of 'debtShares' burned
   */
  event Payback(address indexed sender, address indexed owner, uint256 debt, uint256 shares);

  /**
   * @dev Emitted when the oracle address is changed
   * @param newOracle The new oracle address
   */
  event OracleChanged(IFujiOracle newOracle);

  /**
   * @dev Emitted when the available providers for the vault change
   * @param newProviders the new providers available
   */
  event ProvidersChanged(ILendingProvider[] newProviders);

  /**
   * @dev Emitted when the active provider is changed
   * @param newActiveProvider the new active provider
   */
  event ActiveProviderChanged(ILendingProvider newActiveProvider);

  /**
   * @dev Emitted when the vault is rebalanced
   * @param assets amount to be rebalanced
   * @param debt amount to be rebalanced
   * @param from provider
   * @param to provider
   */
  event VaultRebalance(uint256 assets, uint256 debt, address indexed from, address indexed to);

  /**
   * @dev Emitted when the max LTV is changed
   * See factors: https://github.com/Fujicracy/CrossFuji/tree/main/packages/protocol#readme
   * @param newMaxLtv the new max LTV
   */
  event MaxLtvChanged(uint256 newMaxLtv);

  /**
   * @dev Emitted when the liquidation ratio is changed
   * See factors: https://github.com/Fujicracy/CrossFuji/tree/main/packages/protocol#readme
   * @param newLiqRatio the new liquidation ratio
   */
  event LiqRatioChanged(uint256 newLiqRatio);

  /**
   * @dev Emitted when the minumum deposit amount is changed
   * @param newMinDeposit the new minimum deposit amount
   */
  event MinDepositAmountChanged(uint256 newMinDeposit);

  /**
   * @dev Emitted when the deposit cap is changed
   * @param newDepositCap the new deposit cap of this vault.
   */
  event DepositCapChanged(uint256 newDepositCap);

  /// Debt management functions

  /**
   * @dev Returns the decimals for 'debtAsset' of this vault.
   *
   * - MUST match the 'debtAsset' decimals in ERC-20 token contract.
   */
  function debtDecimals() external view returns (uint8);

  /**
   * @dev Based on {IERC4626-asset}.
   * @dev Returns the address of the underlying token used for the Vault for debt, borrowing, and repaying.
   *
   * - MUST be an ERC-20 token contract.
   * - MUST NOT revert.
   */
  function debtAsset() external view returns (address);

  /**
   * @dev Returns the amount of debt owned by `owner`.
   */
  function balanceOfDebt(address owner) external view returns (uint256 debt);

  /**
   * @dev Based on {IERC4626-totalAssets}.
   * @dev Returns the total amount of the underlying debt asset that is “managed” by Vault.
   *
   * - SHOULD include any compounding that occurs from yield.
   * - MUST be inclusive of any fees that are charged against assets in the Vault.
   * - MUST NOT revert.
   */
  function totalDebt() external view returns (uint256);

  /**
   * @dev Based on {IERC4626-convertToShares}.
   * @dev Returns the amount of shares that the Vault would exchange for the amount of debt assets provided, in an ideal
   * scenario where all the conditions are met.
   *
   * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
   * - MUST NOT show any variations depending on the caller.
   * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
   * - MUST NOT revert.
   *
   * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
   * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
   * from.
   */
  function convertDebtToShares(uint256 debt) external view returns (uint256 shares);

  /**
   * @dev Based on {IERC4626-convertToAssets}.
   * @dev Returns the amount of debt assets that the Vault would exchange for the amount of shares provided, in an ideal
   * scenario where all the conditions are met.
   *
   * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
   * - MUST NOT show any variations depending on the caller.
   * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
   * - MUST NOT revert.
   *
   * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
   * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
   * from.
   */
  function convertToDebt(uint256 shares) external view returns (uint256 debt);

  /**
   * @dev Based on {IERC4626-maxDeposit}.
   * @dev Returns the maximum amount of the debt asset that can be borrowed for the receiver,
   * through a borrow call.
   *
   * - MUST return a limited value if receiver is subject to some borrow limit.
   * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be borrowed.
   * - MUST NOT revert.
   */
  function maxBorrow(address borrower) external view returns (uint256);

  /**
   * @dev Based on {IERC4626-deposit}.
   * @dev Mints debtShares to owner by taking a loan of exact amount of underlying tokens.
   *
   * - MUST emit the Borrow event.
   * - MUST revert if owner does not own sufficient collateral to back debt.
   * - MUST revert if caller is not owner or permission to act owner.
   */
  function borrow(uint256 debt, address receiver, address owner) external returns (uint256);

  /**
   * @dev burns debtShares to owner by paying back loan with exact amount of underlying tokens.
   *
   * - MUST emit the Payback event.
   *
   * NOTE: most implementations will require pre-erc20-approval of the underlying asset token.
   */
  function payback(uint256 debt, address receiver) external returns (uint256);

  /// General functions

  /**
   * @notice Returns the active provider of this vault.
   */
  function getProviders() external view returns (ILendingProvider[] memory);
  /**
   * @notice Returns the active provider of this vault.
   */
  function activeProvider() external view returns (ILendingProvider);

  /// Rebalancing Functions

  /**
   * @notice Performs rebalancing of vault by moving funds across providers.
   * @param assets amount of this vault to be rebalanced.
   * @param debt amount of this vault to be rebalanced. Note: pass zero for a {YieldVault}.
   * @param from provider address currently custoding `assets` and/or `debt`.
   * @param to provider address to which `assets` and/or `debt` will be transferred.
   * @param fee expected from rebalancing operation.
   *
   * - MUST check providers `from` and `to` are valid.
   * - MUST be called from a {RebalancerManager} contract that makes all proper checks.
   * - MUST revert if caller is not an approved rebalancer.
   * - MUST emit the VaultRebalance event.
   * - MUST check `fee` is a reasonable amount.
   *
   */
  function rebalance(
    uint256 assets,
    uint256 debt,
    ILendingProvider from,
    ILendingProvider to,
    uint256 fee
  )
    external
    returns (bool);

  ///  Liquidation Functions

  /**
   * @notice Returns the current health factor of 'owner'.
   * @param owner address to get health factor
   * @dev 'healthFactor' is scaled up by 100.
   * A value below 100 means 'owner' is eligable for liquidation.
   *
   * - MUST return type(uint254).max when 'owner' has no debt.
   * - MUST revert in {YieldVault}.
   */
  function getHealthFactor(address owner) external returns (uint256 healthFactor);

  /**
   * @notice Returns the liquidation close factor based on 'owner's' health factor.
   * @param owner address owner of debt position.
   *
   * - MUST return zero if `owner` is not liquidatable.
   * - MUST revert in {YieldVault}.
   */
  function getLiquidationFactor(address owner) external returns (uint256 liquidationFactor);

  /**
   * @notice Performs liquidation of an unhealthy position, meaning a 'healthFactor' below 100.
   * @param owner address to be liquidated.
   * @param receiver address of the collateral shares of liquidation.
   * @dev WARNING! It is liquidator's responsability to check if liquidation is profitable.
   *
   * - MUST revert if caller is not an approved liquidator.
   * - MUST revert if 'owner' is not liquidatable.
   * - MUST emit the Liquidation event.
   * - MUST liquidate 50% of 'owner' debt when: 100 >= 'healthFactor' > 95.
   * - MUST liquidate 100% of 'owner' debt when: 95 > 'healthFactor'.
   * - MUST revert in {YieldVault}.
   *
   */
  function liquidate(address owner, address receiver) external returns (uint256 gainedShares);

  ////////////////////////
  /// Setter functions ///
  ///////////////////////

  /**
   * @notice Sets the lists of providers of this vault.
   *
   * - MUST NOT contain zero addresses.
   */
  function setProviders(ILendingProvider[] memory providers) external;

  /**
   * @notice Sets the active provider for this vault.
   *
   * - MUST be a provider previously set by `setProviders()`.
   */
  function setActiveProvider(ILendingProvider activeProvider) external;

  /**
   * @dev Sets the minimum deposit amount.
   */
  function setMinDepositAmount(uint256 amount) external;

  /**
   * @dev Sets the deposit cap amount of this vault.
   *
   * - MUST be greater than zero.
   */
  function setDepositCap(uint256 newCap) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title Chief helper interface.
 * @author Fujidao Labs
 * @notice Defines interface for {Chief} access control operations.
 */

import {IAccessControl} from "openzeppelin-contracts/contracts/access/IAccessControl.sol";

interface IChief is IAccessControl {
  function timelock() external view returns (address);

  function addrMapper() external view returns (address);

  function allowedFlasher(address flasher) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title Router Interface.
 * @author Fujidao Labs
 * @notice Defines the interface for router operations.
 */

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

interface IRouter {
  enum Action {
    Deposit,
    Withdraw,
    Borrow,
    Payback,
    Flashloan,
    Swap,
    PermitWithdraw,
    PermitBorrow,
    XTransfer,
    XTransferWithCall,
    DepositETH,
    WithdrawETH
  }

  function xBundle(Action[] memory actions, bytes[] memory args) external payable;

  function sweepToken(ERC20 token, address receiver) external;

  function sweepETH(address receiver) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

interface ISwapper {
  function swap(
    address assetIn,
    address assetOut,
    uint256 amountIn,
    uint256 amountOut,
    address receiver,
    address sweeper,
    uint256 minSweepOut
  )
    external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title IFlasher
 * @author Fujidao Labs
 * @notice Defines the interface for all flashloan providers.
 */

interface IFlasher {
  /**
   * @notice Initiates a flashloan a this provider.
   * @param asset address to be flashloaned.
   * @param amount of `asset` to be flashloaned.
   * @param requestor address to which flashloan will be facilitated.
   * @param requestorCalldata encoded args with selector that will be OPCODE-CALL'ed to `requestor`.
   * @dev To encode `params` see examples:
   * • solidity:
   *   > abi.encodeWithSelector(contract.transferFrom.selector, from, to, amount);
   * • ethersJS:
   *   > contract.interface.encodeFunctionData("transferFrom", [from, to, amount]);
   * • foundry cast:
   *   > cast calldata "transferFrom(address,address,uint256)" from, to, amount
   *
   * Requirements:
   * - MUST implement `_checkAndSetEntryPoint()`
   */
  function initiateFlashloan(
    address asset,
    uint256 amount,
    address requestor,
    bytes memory requestorCalldata
  )
    external;

  /**
   * @notice Returns the address from which flashloan for `asset` is sourced.
   * @param asset intended to be flashloaned.
   * @dev Override at flashloan provider implementation as required.
   * Some protocol implementations source flashloans from different contracts
   * depending on `asset`.
   */
  function getFlashloanSourceAddr(address asset) external view returns (address callAddr);

  /**
   * @notice Returns the expected flashloan fee for `amount`
   * of this flashloan provider.
   * @param asset to be flashloaned
   * @param amount of flashloan
   */
  function computeFlashloanFee(address asset, uint256 amount) external view returns (uint256 fee);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title VaultPermissions Interface.
 * @author Fujidao Labs
 * @notice Defines the interface for vault signed permit operations and borrow allowance.
 */

interface IVaultPermissions {
  /**
   * @dev Emitted when the asset allowance of a `operator` for an `owner` is set by
   * a call to {approveAsset}. `amount` is the new allowance.
   * Allows `operator` to withdraw/transfer collateral from owner.
   */
  event WithdrawApproval(address indexed owner, address operator, address receiver, uint256 amount);

  /**
   * @dev Emitted when the borrow allowance of a `operator` for an `owner` is set by
   * a call to {approveBorrow}. `amount` is the new allowance.
   * Allows `operator` to incur debt on behalf `owner`.
   */
  event BorrowApproval(address indexed owner, address operator, address receiver, uint256 amount);

  /**
   * @dev Based on {IERC20Permit-DOMAIN_SEPARATOR}.
   */
  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR() external returns (bytes32);

  /**
   * @dev Based on {IERC20-allowance} for assets, instead of shares.
   *
   * Requirements:
   * - By convention this SHOULD be used over {IERC4626-allowance}.
   */
  function withdrawAllowance(
    address owner,
    address operator,
    address receiver
  )
    external
    view
    returns (uint256);

  /**
   * @dev Based on {IERC20-allowance} for debt.
   */
  function borrowAllowance(
    address owner,
    address operator,
    address receiver
  )
    external
    view
    returns (uint256);

  /**
   * @dev Atomically increases the `withdrawAllowance` granted to `operator` by the caller.
   * Based on OZ {ERC20-increaseAllowance} for assets.
   * Emits an {WithdrawApproval} event indicating the updated asset allowance.
   *
   * Requirements:
   * - `operator` cannot be the zero address.
   */
  function increaseWithdrawAllowance(
    address operator,
    address receiver,
    uint256 byAmount
  )
    external
    returns (bool);

  /**
   * @dev Atomically decrease the `withdrawAllowance` granted to `operator` by the caller.
   * Based on OZ {ERC20-decreaseAllowance} for assets.
   * Emits an {WithdrawApproval} event indicating the updated asset allowance.
   *
   * Requirements:
   * - `operator` cannot be the zero address.
   * - `operator` must have `withdrawAllowance` for the caller of at least `byAmount`
   */
  function decreaseWithdrawAllowance(
    address operator,
    address receiver,
    uint256 byAmount
  )
    external
    returns (bool);

  /**
   * @dev Atomically increases the `borrowAllowance` granted to `operator` by the caller.
   * Based on OZ {ERC20-increaseAllowance} for assets.
   * Emits an {BorrowApproval} event indicating the updated borrow allowance.
   *
   * Requirements:
   * - `operator` cannot be the zero address.
   */
  function increaseBorrowAllowance(
    address operator,
    address receiver,
    uint256 byAmount
  )
    external
    returns (bool);

  /**
   * @dev Atomically decrease the `borrowAllowance` granted to `operator` by the caller.
   * Based on OZ {ERC20-decreaseAllowance} for assets, and
   * inspired on credit delegation by Aave.
   * Emits an {BorrowApproval} event indicating the updated borrow allowance.
   *
   * Requirements:
   * - `operator` cannot be the zero address.
   * - `operator` must have `borrowAllowance` for the caller of at least `byAmount`
   */
  function decreaseBorrowAllowance(
    address operator,
    address receiver,
    uint256 byAmount
  )
    external
    returns (bool);

  /**
   * @dev Based on OZ {IERC20Permit-nonces}.
   */
  function nonces(address owner) external view returns (uint256);

  /**
   * @dev Inspired by {IERC20Permit-permit} for assets.
   * Sets `amount` as the `withdrawAllowance` of `operator` over ``owner``'s tokens,
   * given ``owner``'s signed approval.
   * IMPORTANT: The same issues {IERC20-approve} related to transaction
   * ordering also apply here.
   *
   * Emits an {AssetsApproval} event.
   *
   * Requirements:
   * - `operator` cannot be the zero address.
   * - `deadline` must be a timestamp in the future.
   * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
   * over the EIP712-formatted function arguments.
   * - the signature must use ``owner``'s current nonce (see {nonces}).
   */
  function permitWithdraw(
    address owner,
    address receiver,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    external;

  /**
   * @dev Inspired by {IERC20Permit-permit} for debt.
   * Sets `amount` as the `borrowAllowance` of `operator` over ``owner``'s borrowing powwer,
   * given ``owner``'s signed approval.
   * IMPORTANT: The same issues {IERC20-approve} has related to transaction
   * ordering also apply here.
   *
   * Emits a {BorrowApproval} event.
   *
   * Requirements:
   * - must be implemented in a BorrowingVault.
   * - `operator` cannot be the zero address.
   * - `deadline` must be a timestamp in the future.
   * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
   * over the EIP712-formatted function arguments.
   * - the signature must use ``owner``'s current nonce (see {nonces}).
   */
  function permitBorrow(
    address owner,
    address receiver,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

/**
 * @title SystemAccessControl.
 * @author Fujidao Labs
 * @notice Helper contract that should be inherited by contract implementations that
 * should call {Chief} for access control checks.
 */

import {IChief} from "../interfaces/IChief.sol";
import {CoreRoles} from "./CoreRoles.sol";

contract SystemAccessControl is CoreRoles {
  error SystemAccessControl__hasRole_missingRole(address caller, bytes32 role);
  error SystemAccessControl__onlyTimelock_callerIsNotTimelock();
  error SystemAccessControl__onlyHouseKeeper_notHouseKeeper();

  IChief public immutable chief;

  modifier hasRole(address caller, bytes32 role) {
    if (!chief.hasRole(role, caller)) {
      revert SystemAccessControl__hasRole_missingRole(caller, role);
    }
    _;
  }

  modifier onlyHouseKeeper() {
    if (!chief.hasRole(HOUSE_KEEPER_ROLE, msg.sender)) {
      revert SystemAccessControl__onlyHouseKeeper_notHouseKeeper();
    }
    _;
  }

  modifier onlyTimelock() {
    if (msg.sender != chief.timelock()) {
      revert SystemAccessControl__onlyTimelock_callerIsNotTimelock();
    }
    _;
  }

  constructor(address chief_) {
    chief = IChief(chief_);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";
import "../token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import {IVault} from "./IVault.sol";

/**
 * @title Lending provider interface.
 * @author fujidao Labs
 * @notice  Defines the interface for core engine to perform operations at lending providers.
 * @dev Functions are intended to be called in the context of a Vault via delegateCall,
 * except indicated.
 */

interface ILendingProvider {
  function providerName() external view returns (string memory);
  /**
   * @notice Returns the operator address that requires ERC20-approval for deposits.
   * @param asset address.
   * @param vault address required by some specific providers with multi-markets, otherwise pass address(0).
   */
  function approvedOperator(address asset, address vault) external view returns (address operator);

  /**
   * @notice Performs deposit operation at lending provider on behalf vault.
   * @param amount amount integer.
   * @param vault address calling this function.
   *
   * Requirements:
   * - This function should be delegate called in the context of a `vault`.
   */
  function deposit(uint256 amount, IVault vault) external returns (bool success);

  /**
   * @notice Performs borrow operation at lending provider on behalf vault.
   * @param amount amount integer.
   * @param vault address calling this function.
   *
   * Requirements:
   * - This function should be delegate called in the context of a `vault`.
   */
  function borrow(uint256 amount, IVault vault) external returns (bool success);

  /**
   * @notice Performs withdraw operation at lending provider on behalf vault.
   * @param amount amount integer.
   * @param vault address calling this function.
   *
   * Requirements:
   * - This function should be delegate called in the context of a `vault`.
   */
  function withdraw(uint256 amount, IVault vault) external returns (bool success);

  /**
   * of a `vault`.
   * @notice Performs payback operation at lending provider on behalf vault.
   * @param amount amount integer.
   * @param vault address calling this function.
   *
   * Requirements:
   * - This function should be delegate called in the context of a `vault`.
   * - Check there is erc20-approval to `approvedOperator` by the `vault` prior to call.
   */
  function payback(uint256 amount, IVault vault) external returns (bool success);

  /**
   * @notice Returns DEPOSIT balance of 'user' at lending provider.
   * @param user address whom balance is needed.
   * @param vault address required by some specific providers with multi-markets, otherwise pass address(0).
   *
   * - SHOULD NOT require Vault context.
   */
  function getDepositBalance(address user, IVault vault) external view returns (uint256 balance);

  /**
   * @notice Returns BORROW balance of 'user' at lending provider.
   * @param user address whom balance is needed.
   * @param vault address required by some specific providers with multi-markets, otherwise pass address(0).
   *
   * - SHOULD NOT require Vault context.
   */
  function getBorrowBalance(address user, IVault vault) external view returns (uint256 balance);

  /**
   * @notice Returns the latest SUPPLY annual percent rate (APR) at lending provider.
   * @param vault address required by some specific providers with multi-markets, otherwise pass address(0).
   *
   * - SHOULD return the rate in ray units (1e27)
   * Example 8.5% APR = 0.085 x 1e27 = 85000000000000000000000000
   * - SHOULD NOT require Vault context.
   */
  function getDepositRateFor(IVault vault) external view returns (uint256 rate);

  /**
   * @notice Returns the latest BORROW annual percent rate (APR) at lending provider.
   * @param vault address required by some specific providers with multi-markets, otherwise pass address(0).
   *
   * - SHOULD return the rate in ray units (1e27)
   * Example 8.5% APR = 0.085 x 1e27 = 85000000000000000000000000
   * - SHOULD NOT require Vault context.
   */
  function getBorrowRateFor(IVault vault) external view returns (uint256 rate);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

interface IFujiOracle {
  // FujiOracle Events

  /**
   * @dev Log a change in price feed address for asset address
   */
  event AssetPriceFeedChanged(address asset, address newPriceFeedAddress);

  function getPriceOf(
    address _collateralAsset,
    address _borrowAsset,
    uint8 _decimals
  )
    external
    view
    returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

contract CoreRoles {
  bytes32 public constant HOUSE_KEEPER_ROLE = keccak256("HOUSE_KEEPER_ROLE");

  bytes32 public constant REBALANCER_ROLE = keccak256("REBALANCER_ROLE");
  bytes32 public constant HARVESTER_ROLE = keccak256("HARVESTER_ROLE");
  bytes32 public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");

  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
  bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");
}